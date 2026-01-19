require 'csv'

namespace :db do
  desc "Export all database tables to CSV files"
  task export_csv: :environment do
    export_dir = Rails.root.join('db', 'exports')
    FileUtils.mkdir_p(export_dir)

    tables = %w[users organizations people employments deals blocks interests meetings notes documents]

    tables.each do |table_name|
      model = table_name.classify.constantize
      file_path = export_dir.join("#{table_name}.csv")

      records = model.all

      if records.empty?
        puts "⏭️  #{table_name}: No records to export"
        next
      end

      CSV.open(file_path, 'w') do |csv|
        # Header row
        csv << model.column_names

        # Data rows
        records.find_each do |record|
          csv << model.column_names.map { |col| record.send(col) }
        end
      end

      puts "✅ #{table_name}: Exported #{records.count} records to #{file_path}"
    end

    puts "\n📁 All exports saved to: #{export_dir}"
    puts "📦 You can copy the entire 'exports' folder to your other laptop"
  end

  desc "Import all CSV files into database"
  task import_csv: :environment do
    export_dir = Rails.root.join('db', 'exports')

    unless Dir.exist?(export_dir)
      puts "❌ Export directory not found: #{export_dir}"
      exit 1
    end

    # Import order matters due to foreign keys
    tables = %w[users organizations people employments deals blocks interests meetings notes documents]

    tables.each do |table_name|
      file_path = export_dir.join("#{table_name}.csv")

      unless File.exist?(file_path)
        puts "⏭️  #{table_name}: No CSV file found"
        next
      end

      model = table_name.classify.constantize

      imported = 0
      CSV.foreach(file_path, headers: true) do |row|
        attrs = row.to_h
        # Handle array columns (stored as strings in CSV)
        attrs.each do |key, value|
          if value.is_a?(String) && value.start_with?('{') && value.end_with?('}')
            attrs[key] = value[1..-2].split(',').map(&:strip).reject(&:empty?)
          elsif value.is_a?(String) && value.start_with?('[') && value.end_with?(']')
            attrs[key] = JSON.parse(value) rescue value
          end
        end

        model.create!(attrs)
        imported += 1
      end

      puts "✅ #{table_name}: Imported #{imported} records"
    rescue => e
      puts "❌ #{table_name}: Error - #{e.message}"
    end

    puts "\n📁 Import complete!"
  end
end
