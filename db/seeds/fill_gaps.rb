# Fill gaps in existing data
# Run with: bundle exec rails runner db/seeds/fill_gaps.rb

puts "=" * 60
puts "FILLING DATA GAPS"
puts "=" * 60

# Helper data
CITIES = [
  { city: "New York", state: "NY", country: "United States" },
  { city: "San Francisco", state: "CA", country: "United States" },
  { city: "Los Angeles", state: "CA", country: "United States" },
  { city: "Boston", state: "MA", country: "United States" },
  { city: "Chicago", state: "IL", country: "United States" },
  { city: "Austin", state: "TX", country: "United States" },
  { city: "Seattle", state: "WA", country: "United States" },
  { city: "Miami", state: "FL", country: "United States" },
  { city: "Denver", state: "CO", country: "United States" },
  { city: "Atlanta", state: "GA", country: "United States" },
  { city: "London", state: nil, country: "United Kingdom" },
  { city: "Singapore", state: nil, country: "Singapore" },
  { city: "Hong Kong", state: nil, country: "Hong Kong" },
  { city: "Dubai", state: nil, country: "United Arab Emirates" },
  { city: "Zurich", state: nil, country: "Switzerland" },
]

FUND_DESCRIPTIONS = [
  "A leading venture capital firm focused on early-stage technology investments across enterprise software, fintech, and consumer internet.",
  "Growth equity fund specializing in Series B-D investments in high-growth technology companies.",
  "Multi-stage investment firm backing exceptional founders building category-defining companies.",
  "Premier venture fund with a focus on AI/ML, developer tools, and infrastructure software.",
  "Global private equity firm investing in technology, healthcare, and financial services.",
  "Seed and early-stage fund focused on B2B SaaS and marketplace businesses.",
  "Crossover fund investing in late-stage private and public technology companies.",
  "Sector-focused fund specializing in fintech, insurtech, and embedded finance.",
  "Family office making direct investments in growth-stage technology companies.",
  "Hedge fund with a dedicated private investments arm focused on pre-IPO opportunities.",
]

COMPANY_DESCRIPTIONS = [
  "Leading provider of enterprise software solutions for digital transformation.",
  "Fast-growing SaaS platform revolutionizing workflow automation.",
  "AI-powered analytics company serving Fortune 500 enterprises.",
  "Next-generation fintech platform disrupting traditional financial services.",
  "Cloud infrastructure company enabling developer productivity at scale.",
  "Consumer technology company with millions of active users globally.",
  "B2B marketplace connecting buyers and sellers in a fragmented industry.",
  "Cybersecurity company protecting enterprises from evolving threats.",
  "Healthcare technology company improving patient outcomes through data.",
  "E-commerce platform enabling direct-to-consumer brands to scale.",
]

TITLES_BY_ORG_KIND = {
  "fund" => [
    "Managing Partner", "General Partner", "Partner", "Principal", "Vice President",
    "Associate", "Analyst", "Operating Partner", "Venture Partner", "CFO",
    "Head of Investor Relations", "Director of Research", "Investment Director"
  ],
  "company" => [
    "CEO", "CTO", "CFO", "COO", "VP Engineering", "VP Product", "VP Sales",
    "VP Marketing", "VP Finance", "Director of Engineering", "Product Manager",
    "Head of Growth", "General Counsel", "Chief Revenue Officer", "Chief People Officer"
  ],
  "broker" => [
    "Managing Director", "Director", "Vice President", "Associate", "Analyst",
    "Head of Secondary Trading", "Senior Trader"
  ]
}

DEPARTMENTS = ["Investment Team", "Operations", "Finance", "Legal", "Investor Relations", "Research", "Portfolio Support"]

PHONE_AREA_CODES = ["212", "415", "310", "617", "312", "512", "206", "305", "720", "404"]

BIOS = [
  "Experienced investment professional with over 15 years in venture capital and private equity.",
  "Former founder with two successful exits, now focused on backing the next generation of entrepreneurs.",
  "Deep expertise in enterprise software, having led investments in multiple unicorn companies.",
  "Background in investment banking and strategy consulting before transitioning to venture.",
  "Technical background with experience as an engineer at leading technology companies.",
  "Seasoned operator who has scaled multiple companies from Series A to IPO.",
  "Expert in fintech with a background in traditional financial services.",
  "Healthcare investor with domain expertise from prior roles in biotech and pharma.",
  "Consumer investor with a track record of identifying breakout consumer brands.",
  "Infrastructure specialist focused on developer tools and cloud platforms.",
]

DEAL_NOTES = [
  "Strong management team with prior exit experience. Competitive dynamics in the space but company has clear differentiation.",
  "High conviction opportunity. Founder has deep domain expertise and product-market fit is evident from customer conversations.",
  "Interesting secondary opportunity. Current holders looking to provide liquidity to early employees.",
  "Valuation is rich but growth metrics justify premium. Key risk is execution on international expansion.",
  "Compelling unit economics and clear path to profitability. Management team is executing well.",
  "Market timing is favorable. Company is well-positioned to capitalize on secular trends.",
  "Due diligence ongoing. Need to complete customer reference calls and financial model review.",
  "Competitive process with multiple funds involved. Need to move quickly on term sheet.",
  "Strategic value beyond financial returns. Could be a platform for follow-on investments.",
  "Watching closely. Want to see Q4 results before making final decision.",
]

# ============================================
# 1. Create Employments for Orphaned People
# ============================================
puts "\n1. Creating employments for orphaned people..."

orphaned_people = Person.left_joins(:employments).where(employments: { id: nil })
organizations = Organization.where(kind: ["fund", "company", "broker"]).to_a
employment_count = 0

orphaned_people.each do |person|
  org = organizations.sample
  org_kind = org.kind || "company"
  titles = TITLES_BY_ORG_KIND[org_kind] || TITLES_BY_ORG_KIND["company"]

  Employment.create!(
    person_id: person.id,
    organization_id: org.id,
    title: titles.sample,
    department: DEPARTMENTS.sample,
    is_current: true,
    is_primary: true,
    started_at: rand(1..8).years.ago
  )
  employment_count += 1
end

puts "   Created #{employment_count} employments"

# ============================================
# 2. Fill Organization Details
# ============================================
puts "\n2. Filling organization details..."

org_updates = 0
Organization.find_each do |org|
  updates = {}

  # Description
  if org.description.blank?
    updates[:description] = org.kind == "fund" ? FUND_DESCRIPTIONS.sample : COMPANY_DESCRIPTIONS.sample
  end

  # Location
  if org.city.blank? || org.country.blank?
    location = CITIES.sample
    updates[:city] = location[:city] if org.city.blank?
    updates[:state] = location[:state] if org.state.blank? && location[:state]
    updates[:country] = location[:country] if org.country.blank?
  end

  # LinkedIn
  if org.linkedin_url.blank?
    slug = org.name.downcase.gsub(/[^a-z0-9]/, "-").gsub(/-+/, "-").gsub(/^-|-$/, "")
    updates[:linkedin_url] = "https://linkedin.com/company/#{slug}"
  end

  if updates.any?
    org.update!(updates)
    org_updates += 1
  end
end

puts "   Updated #{org_updates} organizations"

# ============================================
# 3. Fill People Details
# ============================================
puts "\n3. Filling people details..."

people_updates = 0
Person.find_each do |person|
  updates = {}

  # Phone
  current_phones = person.phones || []
  if current_phones.empty?
    area_code = PHONE_AREA_CODES.sample
    number = "#{rand(100..999)}-#{rand(1000..9999)}"
    updates[:phones] = [{ "number" => "+1 (#{area_code}) #{number}", "label" => "mobile" }]
  end

  # Bio
  if person.bio.blank? && rand < 0.7  # 70% get bios
    updates[:bio] = BIOS.sample
  end

  # Location
  if person.city.blank?
    location = CITIES.sample
    updates[:city] = location[:city]
    updates[:state] = location[:state] if location[:state]
    updates[:country] = location[:country]
  end

  # LinkedIn
  if person.linkedin_url.blank?
    slug = "#{person.first_name}-#{person.last_name}".downcase.gsub(/[^a-z0-9]/, "-")
    updates[:linkedin_url] = "https://linkedin.com/in/#{slug}-#{rand(10000..99999)}"
  end

  if updates.any?
    person.update!(updates)
    people_updates += 1
  end
end

puts "   Updated #{people_updates} people"

# ============================================
# 4. Create Activity Attendees
# ============================================
puts "\n4. Creating activity attendees..."

attendee_count = 0
meeting_kinds = ["meeting", "video_call", "in_person_meeting", "call"]
people = Person.all.to_a
users = User.all.to_a

Activity.where(kind: meeting_kinds).find_each do |activity|
  next if activity.activity_attendees.any?  # Skip if already has attendees

  # Add 1-4 attendees
  num_attendees = rand(1..4)
  attendee_people = people.sample(num_attendees)

  attendee_people.each do |person|
    ActivityAttendee.create!(
      activity_id: activity.id,
      attendee_type: "Person",
      attendee_id: person.id,
      response_status: ["accepted", "tentative", "declined", "needs_action"].sample,
      is_organizer: false
    )
    attendee_count += 1
  end

  # Sometimes add a user as organizer
  if users.any? && rand < 0.5
    ActivityAttendee.create!(
      activity_id: activity.id,
      attendee_type: "User",
      attendee_id: users.sample.id,
      response_status: "accepted",
      is_organizer: true
    )
    attendee_count += 1
  end
end

puts "   Created #{attendee_count} activity attendees"

# ============================================
# 5. Fill Deal Details
# ============================================
puts "\n5. Filling deal details..."

deal_updates = 0
Deal.find_each do |deal|
  updates = {}

  # Internal notes
  if deal.internal_notes.blank?
    updates[:internal_notes] = DEAL_NOTES.sample
  end

  # Expected close
  if deal.expected_close.blank? && deal.status == "live"
    updates[:expected_close] = rand(30..120).days.from_now.to_date
  end

  # Deadline
  if deal.deadline.blank? && deal.status == "live" && rand < 0.6
    updates[:deadline] = rand(14..60).days.from_now.to_date
  end

  if updates.any?
    deal.update!(updates)
    deal_updates += 1
  end
end

puts "   Updated #{deal_updates} deals"

# ============================================
# 6. Fill Block Details
# ============================================
puts "\n6. Filling block details..."

block_updates = 0
people = Person.all.to_a

Block.find_each do |block|
  updates = {}

  # Contact
  if block.contact_id.blank?
    updates[:contact_id] = people.sample.id
  end

  # Shares and price if missing
  if block.shares.blank?
    shares = [10000, 25000, 50000, 100000, 250000].sample
    updates[:shares] = shares

    if block.price_cents.blank?
      price = rand(20_00..200_00)
      updates[:price_cents] = price
      updates[:total_cents] = shares * price if block.total_cents.blank?
    end
  end

  # Min size
  if block.min_size_cents.blank?
    updates[:min_size_cents] = [100_000_00, 250_000_00, 500_000_00, 1_000_000_00].sample
  end

  if updates.any?
    block.update!(updates)
    block_updates += 1
  end
end

puts "   Updated #{block_updates} blocks"

# ============================================
# 7. Create Some Closed Deals
# ============================================
puts "\n7. Creating closed deals..."

# Update 2-3 sourcing deals to closed
sourcing_deals = Deal.where(status: "sourcing").limit(3)
closed_count = 0

sourcing_deals.each do |deal|
  committed = deal.target_cents || rand(5_000_000_00..50_000_000_00)
  deal.update!(
    status: "closed",
    closed_at: rand(30..180).days.ago,
    committed_cents: committed,
    closed_cents: committed,
    confidence: 100
  )
  closed_count += 1
end

puts "   Converted #{closed_count} deals to closed"

# ============================================
# 8. Fill Interest Details
# ============================================
puts "\n8. Filling interest details..."

interest_updates = 0
people = Person.all.to_a

Interest.find_each do |interest|
  updates = {}

  # Contact
  if interest.contact_id.blank?
    updates[:contact_id] = people.sample.id
  end

  # Target cents
  if interest.target_cents.blank?
    target = [500_000_00, 1_000_000_00, 2_500_000_00, 5_000_000_00, 10_000_000_00].sample
    updates[:target_cents] = target
    updates[:min_cents] = (target * 0.5).to_i
    updates[:max_cents] = (target * 1.5).to_i
  end

  if updates.any?
    interest.update!(updates)
    interest_updates += 1
  end
end

puts "   Updated #{interest_updates} interests"

# ============================================
# Final Summary
# ============================================
puts "\n" + "=" * 60
puts "GAP FILLING COMPLETE!"
puts "=" * 60

puts "\nNew totals:"
puts "  Organizations with description: #{Organization.where.not(description: [nil, '']).count}/#{Organization.count}"
puts "  People with employments: #{Person.joins(:employments).distinct.count}/#{Person.count}"
puts "  People with phones: #{Person.where("phones IS NOT NULL AND phones != '[]' AND phones != '{}'").count}/#{Person.count}"
puts "  Activity attendees: #{ActivityAttendee.count}"
puts "  Deals with internal_notes: #{Deal.where.not(internal_notes: [nil, '']).count}/#{Deal.count}"
puts "  Closed deals: #{Deal.where(status: 'closed').count}"
puts "  Blocks with contact: #{Block.where.not(contact_id: nil).count}/#{Block.count}"
puts "  Interests with contact: #{Interest.where.not(contact_id: nil).count}/#{Interest.count}"
