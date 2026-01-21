# Add emails and phones to people missing them
# Run with: bundle exec rails runner db/seeds/add_contact_info.rb

EMAIL_DOMAINS = [
  'gmail.com', 'outlook.com', 'yahoo.com', 'icloud.com',
  'protonmail.com', 'hey.com', 'fastmail.com'
]

AREA_CODES = ['212', '415', '310', '617', '312', '512', '206', '305', '720', '404']

updated = 0

# Add emails to people without them
Person.where("emails IS NULL OR emails = '[]' OR emails = '{}'").find_each do |person|
  # Get company domain if they have employment
  emp = person.current_employment
  org_domain = nil
  if emp && emp.organization
    org_name = emp.organization.name.downcase.gsub(/[^a-z0-9]/, '')
    org_domain = "#{org_name}.com"
  end

  # Create work email if they have an org
  emails = []
  if org_domain
    work_email = "#{person.first_name.downcase}.#{person.last_name.downcase}@#{org_domain}".gsub(/[^a-z0-9.@]/, '')
    emails << { 'value' => work_email, 'label' => 'work', 'primary' => true }
  end

  # Add personal email
  personal_domain = EMAIL_DOMAINS.sample
  personal_email = "#{person.first_name.downcase}#{person.last_name.downcase}#{rand(10..99)}@#{personal_domain}".gsub(/[^a-z0-9.@]/, '')
  emails << { 'value' => personal_email, 'label' => 'personal', 'primary' => emails.empty? }

  person.update!(emails: emails)
  updated += 1
end

puts "Added emails to #{updated} people"

# Add phones to people without them
phone_updated = 0
Person.where("phones IS NULL OR phones = '[]' OR phones = '{}'").find_each do |person|
  area_code = AREA_CODES.sample
  number = "#{rand(100..999)}-#{rand(1000..9999)}"
  person.update!(phones: [{ 'number' => "+1 (#{area_code}) #{number}", 'label' => 'mobile' }])
  phone_updated += 1
end

puts "Added phones to #{phone_updated} people"
puts "Done!"
