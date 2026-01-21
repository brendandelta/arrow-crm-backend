# Seed file for relationship types
# Run with: rails runner db/seeds/relationship_types.rb

relationship_types = [
  # ==========================================
  # PERSON ↔ PERSON (Bidirectional)
  # ==========================================
  {
    name: "Friends",
    slug: "friends",
    source_type: "Person",
    target_type: "Person",
    category: "personal",
    bidirectional: true,
    description: "Personal friendship",
    color: "#10B981",
    icon: "users",
    sort_order: 1
  },
  {
    name: "Family",
    slug: "family",
    source_type: "Person",
    target_type: "Person",
    category: "personal",
    bidirectional: true,
    description: "Family relationship",
    color: "#EC4899",
    icon: "heart",
    sort_order: 2
  },
  {
    name: "Spouse/Partner",
    slug: "spouse_partner",
    source_type: "Person",
    target_type: "Person",
    category: "personal",
    bidirectional: true,
    description: "Married or domestic partnership",
    color: "#F43F5E",
    icon: "heart",
    sort_order: 3
  },
  {
    name: "Acquaintance",
    slug: "acquaintance",
    source_type: "Person",
    target_type: "Person",
    category: "personal",
    bidirectional: true,
    description: "Casual or infrequent contact",
    color: "#94A3B8",
    icon: "user",
    sort_order: 4
  },
  {
    name: "Former Colleagues",
    slug: "former_colleagues",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: true,
    description: "Previously worked together",
    color: "#6366F1",
    icon: "briefcase",
    sort_order: 5
  },
  {
    name: "Co-founders",
    slug: "cofounders",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: true,
    description: "Founded a company together",
    color: "#8B5CF6",
    icon: "rocket",
    sort_order: 6
  },
  {
    name: "Business Partners",
    slug: "business_partners",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: true,
    description: "Joint business interest or partnership",
    color: "#0EA5E9",
    icon: "handshake",
    sort_order: 7
  },
  {
    name: "Classmates",
    slug: "classmates",
    source_type: "Person",
    target_type: "Person",
    category: "personal",
    bidirectional: true,
    description: "Attended school together",
    color: "#F59E0B",
    icon: "graduation-cap",
    sort_order: 8
  },

  # ==========================================
  # PERSON → PERSON (Directional)
  # ==========================================
  {
    name: "Introduced",
    slug: "introduced",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: false,
    inverse_name: "Introduced By",
    inverse_slug: "introduced_by",
    description: "Made an introduction to this person",
    color: "#14B8A6",
    icon: "arrow-right",
    sort_order: 10
  },
  {
    name: "Referred",
    slug: "referred",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: false,
    inverse_name: "Referred By",
    inverse_slug: "referred_by",
    description: "Referred this person for an opportunity",
    color: "#22C55E",
    icon: "share",
    sort_order: 11
  },
  {
    name: "Mentor To",
    slug: "mentor_to",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: false,
    inverse_name: "Mentored By",
    inverse_slug: "mentored_by",
    description: "Provides mentorship",
    color: "#A855F7",
    icon: "star",
    sort_order: 12
  },
  {
    name: "Reports To",
    slug: "reports_to",
    source_type: "Person",
    target_type: "Person",
    category: "professional",
    bidirectional: false,
    inverse_name: "Manages",
    inverse_slug: "manages",
    description: "Direct reporting relationship",
    color: "#3B82F6",
    icon: "users",
    sort_order: 13
  },
  {
    name: "Invested In",
    slug: "person_invested_in_person",
    source_type: "Person",
    target_type: "Person",
    category: "financial",
    bidirectional: false,
    inverse_name: "Funded By",
    inverse_slug: "person_funded_by_person",
    description: "Personal investment (angel, etc.)",
    color: "#EAB308",
    icon: "dollar-sign",
    sort_order: 14
  },

  # ==========================================
  # ORGANIZATION ↔ ORGANIZATION (Bidirectional)
  # ==========================================
  {
    name: "Strategic Partners",
    slug: "strategic_partners",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: true,
    description: "Formal strategic partnership",
    color: "#0EA5E9",
    icon: "handshake",
    sort_order: 20
  },
  {
    name: "Competitors",
    slug: "competitors",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: true,
    description: "Competing in the same market",
    color: "#EF4444",
    icon: "swords",
    sort_order: 21
  },
  {
    name: "Joint Venture",
    slug: "joint_venture",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: true,
    description: "Joint venture partnership",
    color: "#8B5CF6",
    icon: "link",
    sort_order: 22
  },
  {
    name: "Affiliates",
    slug: "affiliates",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: true,
    description: "Affiliated organizations",
    color: "#64748B",
    icon: "link",
    sort_order: 23
  },
  {
    name: "Co-investors",
    slug: "coinvestors",
    source_type: "Organization",
    target_type: "Organization",
    category: "financial",
    bidirectional: true,
    description: "Frequently co-invest together",
    color: "#10B981",
    icon: "dollar-sign",
    sort_order: 24
  },

  # ==========================================
  # ORGANIZATION → ORGANIZATION (Directional)
  # ==========================================
  {
    name: "Parent Of",
    slug: "parent_of",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: false,
    inverse_name: "Subsidiary Of",
    inverse_slug: "subsidiary_of",
    description: "Parent company relationship",
    color: "#6366F1",
    icon: "building",
    sort_order: 30
  },
  {
    name: "Invested In",
    slug: "org_invested_in_org",
    source_type: "Organization",
    target_type: "Organization",
    category: "financial",
    bidirectional: false,
    inverse_name: "Funded By",
    inverse_slug: "org_funded_by_org",
    description: "Made an investment in this organization",
    color: "#22C55E",
    icon: "trending-up",
    sort_order: 31
  },
  {
    name: "Acquired",
    slug: "acquired",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: false,
    inverse_name: "Acquired By",
    inverse_slug: "acquired_by",
    description: "Acquisition relationship",
    color: "#F59E0B",
    icon: "merge",
    sort_order: 32
  },
  {
    name: "LP In",
    slug: "lp_in",
    source_type: "Organization",
    target_type: "Organization",
    category: "financial",
    bidirectional: false,
    inverse_name: "Has LP",
    inverse_slug: "has_lp",
    description: "Limited partner investment",
    color: "#14B8A6",
    icon: "wallet",
    sort_order: 33
  },
  {
    name: "GP Of",
    slug: "gp_of",
    source_type: "Organization",
    target_type: "Organization",
    category: "financial",
    bidirectional: false,
    inverse_name: "Managed By GP",
    inverse_slug: "managed_by_gp",
    description: "General partner relationship",
    color: "#8B5CF6",
    icon: "shield",
    sort_order: 34
  },
  {
    name: "Supplier To",
    slug: "supplier_to",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: false,
    inverse_name: "Customer Of",
    inverse_slug: "customer_of",
    description: "Supplier/vendor relationship",
    color: "#64748B",
    icon: "truck",
    sort_order: 35
  },
  {
    name: "Service Provider To",
    slug: "service_provider_to",
    source_type: "Organization",
    target_type: "Organization",
    category: "organizational",
    bidirectional: false,
    inverse_name: "Client Of",
    inverse_slug: "client_of",
    description: "Professional services relationship",
    color: "#0EA5E9",
    icon: "briefcase",
    sort_order: 36
  },

  # ==========================================
  # PERSON → ORGANIZATION (Directional)
  # ==========================================
  {
    name: "Founder Of",
    slug: "founder_of",
    source_type: "Person",
    target_type: "Organization",
    category: "professional",
    bidirectional: false,
    inverse_name: "Founded By",
    inverse_slug: "founded_by",
    description: "Founded this organization",
    color: "#8B5CF6",
    icon: "rocket",
    sort_order: 40
  },
  {
    name: "Board Member Of",
    slug: "board_member_of",
    source_type: "Person",
    target_type: "Organization",
    category: "professional",
    bidirectional: false,
    inverse_name: "Has Board Member",
    inverse_slug: "has_board_member",
    description: "Serves on the board",
    color: "#6366F1",
    icon: "users",
    sort_order: 41
  },
  {
    name: "Advisor To",
    slug: "advisor_to",
    source_type: "Person",
    target_type: "Organization",
    category: "professional",
    bidirectional: false,
    inverse_name: "Advised By",
    inverse_slug: "advised_by",
    description: "Formal advisory role",
    color: "#14B8A6",
    icon: "lightbulb",
    sort_order: 42
  },
  {
    name: "Angel Investor In",
    slug: "angel_investor_in",
    source_type: "Person",
    target_type: "Organization",
    category: "financial",
    bidirectional: false,
    inverse_name: "Has Angel Investor",
    inverse_slug: "has_angel_investor",
    description: "Personal angel investment",
    color: "#EAB308",
    icon: "dollar-sign",
    sort_order: 43
  },
  {
    name: "LP In",
    slug: "person_lp_in",
    source_type: "Person",
    target_type: "Organization",
    category: "financial",
    bidirectional: false,
    inverse_name: "Has Individual LP",
    inverse_slug: "has_individual_lp",
    description: "Individual LP commitment",
    color: "#22C55E",
    icon: "wallet",
    sort_order: 44
  },
  {
    name: "Consultant To",
    slug: "consultant_to",
    source_type: "Person",
    target_type: "Organization",
    category: "professional",
    bidirectional: false,
    inverse_name: "Has Consultant",
    inverse_slug: "has_consultant",
    description: "Consulting engagement",
    color: "#0EA5E9",
    icon: "briefcase",
    sort_order: 45
  },
  {
    name: "Key Contact At",
    slug: "key_contact_at",
    source_type: "Person",
    target_type: "Organization",
    category: "professional",
    bidirectional: false,
    inverse_name: "Has Key Contact",
    inverse_slug: "has_key_contact",
    description: "Important relationship at this org (outside of employment)",
    color: "#F59E0B",
    icon: "star",
    sort_order: 46
  },
  {
    name: "Former Employee Of",
    slug: "former_employee_of",
    source_type: "Person",
    target_type: "Organization",
    category: "professional",
    bidirectional: false,
    inverse_name: "Former Employer Of",
    inverse_slug: "former_employer_of",
    description: "Previously employed (if not tracked in employments)",
    color: "#64748B",
    icon: "clock",
    sort_order: 47
  },

  # ==========================================
  # PERSON → DEAL (Directional)
  # ==========================================
  {
    name: "Sourced",
    slug: "sourced_deal",
    source_type: "Person",
    target_type: "Deal",
    category: "professional",
    bidirectional: false,
    inverse_name: "Sourced By",
    inverse_slug: "deal_sourced_by",
    description: "Brought this deal to the team",
    color: "#22C55E",
    icon: "search",
    sort_order: 50
  },
  {
    name: "Championed",
    slug: "championed_deal",
    source_type: "Person",
    target_type: "Deal",
    category: "professional",
    bidirectional: false,
    inverse_name: "Championed By",
    inverse_slug: "deal_championed_by",
    description: "Internal champion for this deal",
    color: "#F59E0B",
    icon: "flag",
    sort_order: 51
  },
  {
    name: "Expert Reference For",
    slug: "expert_reference_for",
    source_type: "Person",
    target_type: "Deal",
    category: "professional",
    bidirectional: false,
    inverse_name: "Has Expert Reference",
    inverse_slug: "deal_has_expert_reference",
    description: "Domain expert consulted on this deal",
    color: "#8B5CF6",
    icon: "award",
    sort_order: 52
  },

  # ==========================================
  # ORGANIZATION → DEAL (Directional)
  # ==========================================
  {
    name: "Co-investor On",
    slug: "coinvestor_on_deal",
    source_type: "Organization",
    target_type: "Deal",
    category: "financial",
    bidirectional: false,
    inverse_name: "Has Co-investor",
    inverse_slug: "deal_has_coinvestor",
    description: "Investing alongside us",
    color: "#10B981",
    icon: "users",
    sort_order: 60
  },
  {
    name: "Passed On",
    slug: "passed_on_deal",
    source_type: "Organization",
    target_type: "Deal",
    category: "financial",
    bidirectional: false,
    inverse_name: "Passed By",
    inverse_slug: "deal_passed_by",
    description: "Reviewed and passed on this deal",
    color: "#EF4444",
    icon: "x",
    sort_order: 61
  },

  # ==========================================
  # GENERIC / ANY → ANY
  # ==========================================
  {
    name: "Related To",
    slug: "related_to",
    source_type: nil,
    target_type: nil,
    category: "general",
    bidirectional: true,
    description: "General relationship (use when no specific type fits)",
    color: "#94A3B8",
    icon: "link",
    sort_order: 100
  }
]

# Create or update relationship types
relationship_types.each do |attrs|
  rt = RelationshipType.find_or_initialize_by(slug: attrs[:slug])
  rt.assign_attributes(attrs)
  rt.save!
  puts "#{rt.persisted? ? 'Updated' : 'Created'}: #{rt.name} (#{rt.slug})"
end

puts "\nTotal relationship types: #{RelationshipType.count}"
