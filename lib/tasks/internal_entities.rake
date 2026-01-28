namespace :internal_entities do
  desc "Migrate internal organizations to internal_entities table"
  task migrate_from_organizations: :environment do
    # Allowlist of organization names/patterns that are considered internal
    INTERNAL_ORG_PATTERNS = [
      /^Arrow/i,
      /^Delta Meridian/i,
      /^Liberator/i,
      /SPV/i,
      /Holdings/i,
      /Management/i,
      /GP\s*$/i,  # Ends with GP
      /\bGP\b/i,  # Contains GP as word
      /\bLP\b/i,  # Contains LP as word
      /Trust$/i,  # Ends with Trust
    ].freeze

    # Also check for specific kinds that are typically internal
    INTERNAL_KINDS = %w[spv].freeze

    # Also check for metadata flags
    def internal_by_metadata?(org)
      org.meta&.dig('is_internal') == true
    end

    puts "=" * 60
    puts "Starting Internal Entity Migration"
    puts "=" * 60
    puts

    # Find candidate organizations
    candidates = Organization.all.select do |org|
      # Check if matches any internal pattern
      matches_pattern = INTERNAL_ORG_PATTERNS.any? { |pattern| org.name =~ pattern }

      # Check if is internal kind
      is_internal_kind = INTERNAL_KINDS.include?(org.kind)

      # Check metadata flag
      has_metadata_flag = internal_by_metadata?(org)

      matches_pattern || is_internal_kind || has_metadata_flag
    end

    puts "Found #{candidates.count} candidate organizations for migration:"
    candidates.each do |org|
      puts "  - [#{org.id}] #{org.name} (#{org.kind})"
    end
    puts

    # Require confirmation in production
    if Rails.env.production?
      print "Proceed with migration? (yes/no): "
      confirmation = STDIN.gets.chomp
      unless confirmation.downcase == 'yes'
        puts "Migration cancelled."
        exit
      end
    end

    migrated_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      candidates.each do |org|
        puts "Migrating: #{org.name}..."

        begin
          # Map entity type from organization kind
          entity_type = case org.kind
                        when 'spv' then 'llc'
                        when 'fund' then 'lp'
                        when 'company' then 'llc'
                        else 'other'
                        end

          # Create internal entity
          internal_entity = InternalEntity.create!(
            name_legal: org.legal_name.presence || org.name,
            name_short: org.name,
            entity_type: entity_type,
            jurisdiction_country: org.country || 'US',
            jurisdiction_state: org.state,
            status: 'active',
            primary_address: org.full_address,
            notes: org.internal_notes,
            metadata: {
              migrated_from_organization_id: org.id,
              migrated_at: Time.current.iso8601,
              original_kind: org.kind,
              original_meta: org.meta
            }
          )

          # Set EIN if available in meta
          if org.meta&.dig('ein').present?
            internal_entity.set_ein(org.meta['ein'])
            internal_entity.save!
          end

          # Update organization with bridge
          org.update!(
            internal_entity_id: internal_entity.id,
            is_internal: true
          )

          # Migrate documents
          doc_count = 0
          org.documents.find_each do |doc|
            DocumentLink.create!(
              document: doc,
              linkable: internal_entity,
              relationship: 'entity_governing',
              visibility: doc.is_confidential? ? 'confidential' : 'default'
            )
            doc_count += 1
          end

          puts "  ✓ Created InternalEntity ##{internal_entity.id}, linked #{doc_count} documents"
          migrated_count += 1

        rescue => e
          puts "  ✗ Error: #{e.message}"
          errors << { org: org, error: e.message }
          error_count += 1
        end
      end
    end

    puts
    puts "=" * 60
    puts "Migration Complete"
    puts "=" * 60
    puts "Migrated: #{migrated_count}"
    puts "Errors: #{error_count}"

    if errors.any?
      puts
      puts "Errors:"
      errors.each do |err|
        puts "  - [#{err[:org].id}] #{err[:org].name}: #{err[:error]}"
      end
    end
  end

  desc "List organizations that would be migrated (dry run)"
  task dry_run: :environment do
    INTERNAL_ORG_PATTERNS = [
      /^Arrow/i,
      /^Delta Meridian/i,
      /^Liberator/i,
      /SPV/i,
      /Holdings/i,
      /Management/i,
      /GP\s*$/i,
      /\bGP\b/i,
      /\bLP\b/i,
      /Trust$/i,
    ].freeze

    INTERNAL_KINDS = %w[spv].freeze

    candidates = Organization.all.select do |org|
      matches_pattern = INTERNAL_ORG_PATTERNS.any? { |pattern| org.name =~ pattern }
      is_internal_kind = INTERNAL_KINDS.include?(org.kind)
      has_metadata_flag = org.meta&.dig('is_internal') == true
      matches_pattern || is_internal_kind || has_metadata_flag
    end

    puts "Organizations that would be migrated:"
    puts
    candidates.each do |org|
      reason = []
      reason << "pattern match" if INTERNAL_ORG_PATTERNS.any? { |p| org.name =~ p }
      reason << "kind=#{org.kind}" if INTERNAL_KINDS.include?(org.kind)
      reason << "metadata flag" if org.meta&.dig('is_internal') == true

      puts "  [#{org.id}] #{org.name}"
      puts "       Kind: #{org.kind}, Reason: #{reason.join(', ')}"
      puts "       Documents: #{org.documents.count}"
      puts
    end

    puts "Total: #{candidates.count} organizations"
  end

  desc "Rollback internal entity migration"
  task rollback: :environment do
    puts "Rolling back internal entity migration..."

    ActiveRecord::Base.transaction do
      # Find migrated internal entities
      InternalEntity.where("metadata->>'migrated_from_organization_id' IS NOT NULL").find_each do |entity|
        org_id = entity.metadata['migrated_from_organization_id']
        org = Organization.find_by(id: org_id)

        if org
          # Remove bridge
          org.update!(internal_entity_id: nil, is_internal: false)
          puts "  ✓ Reset Organization ##{org_id}"
        end

        # Remove document links
        entity.document_links.destroy_all

        # Remove entity
        entity.destroy!
        puts "  ✓ Deleted InternalEntity ##{entity.id}"
      end
    end

    puts "Rollback complete."
  end
end
