# Sample Data Seed for Arrow CRM
# Run with: bundle exec rails runner db/seeds/sample_data.rb

puts "Starting sample data seed..."

# Get references
users = User.all.to_a
gabe = users.find { |u| u.first_name == "Gabriel" }
chris = users.find { |u| u.first_name == "Chris" }
brendan = users.find { |u| u.first_name == "Brendan" }

# Get some organizations
funds = Organization.where(kind: "fund").limit(30).to_a
companies = Organization.where(kind: "company").limit(30).to_a
brokers = Organization.where(kind: "broker").limit(10).to_a

# Get some people
people = Person.where("warmth >= 1").limit(50).to_a
champions = Person.where(warmth: 3).to_a

# Get deals
deals = Deal.all.to_a

puts "Found #{users.count} users, #{funds.count} funds, #{companies.count} companies, #{people.count} people, #{deals.count} deals"

# ============================================
# 1. Update Deals with better data
# ============================================
puts "\n1. Updating deals with stages and priorities..."

deal_stages = ["initial_review", "due_diligence", "term_sheet", "legal_review", "closing"]
deal_priorities = [0, 1, 2, 3] # now, high, medium, low
deal_owners = ["arrow", "liberator"]

deals.each_with_index do |deal, i|
  updates = {}

  # Set stage based on status
  if deal.status == "live"
    updates[:stage] = deal_stages.sample(1).first
    updates[:priority] = [0, 1].sample # now or high for live deals
    updates[:confidence] = rand(60..95)
    updates[:expected_close] = Date.today + rand(14..90).days
  elsif deal.status == "sourcing"
    updates[:stage] = "initial_review"
    updates[:priority] = [1, 2, 3].sample
    updates[:confidence] = rand(20..50)
  end

  # Set some financial data
  if deal.target_cents.nil? || deal.target_cents == 0
    updates[:target_cents] = [500_000_00, 1_000_000_00, 2_500_000_00, 5_000_000_00, 10_000_000_00].sample
  end

  if deal.valuation_cents.nil? || deal.valuation_cents == 0
    updates[:valuation_cents] = [100_000_000_00, 500_000_000_00, 1_000_000_000_00, 5_000_000_000_00, 10_000_000_000_00, 50_000_000_000_00].sample
  end

  # Set deal owner entity (arrow vs liberator)
  updates[:deal_owner] = deal_owners.sample

  # Set owner user
  updates[:owner_id] = users.sample.id if deal.owner_id.nil?

  # Set source
  if deal.source.nil?
    updates[:source] = ["referral", "network", "inbound", "conference", "direct_outreach"].sample
  end

  deal.update!(updates) if updates.any?
end

puts "   Updated #{deals.count} deals"

# ============================================
# 2. Create Deal Targets (Outreach)
# ============================================
puts "\n2. Creating deal targets..."

deal_target_statuses = ["not_started", "contacted", "engaged", "negotiating", "committed", "passed"]
deal_target_roles = ["lead_investor", "co_investor", "advisor", "strategic_partner"]

target_count = 0
deals.select { |d| d.status == "live" }.each do |deal|
  # Add 5-15 targets per live deal
  target_orgs = funds.sample(rand(5..10))
  target_people = champions.sample(rand(3..5))

  target_orgs.each do |org|
    next if DealTarget.exists?(deal_id: deal.id, target_type: "Organization", target_id: org.id)

    status = deal_target_statuses.sample
    DealTarget.create!(
      deal_id: deal.id,
      target_type: "Organization",
      target_id: org.id,
      status: status,
      role: deal_target_roles.sample,
      priority: rand(0..3),
      owner_id: users.sample.id,
      first_contacted_at: status != "not_started" ? rand(30).days.ago : nil,
      last_contacted_at: status != "not_started" ? rand(7).days.ago : nil,
      last_activity_at: status != "not_started" ? rand(3).days.ago : nil,
      activity_count: status != "not_started" ? rand(1..10) : 0,
      next_step: ["Follow up call", "Send deck", "Schedule meeting", "Waiting on IC", "Send term sheet", nil].sample,
      next_step_at: rand(1..14).days.from_now,
      notes: ["Very interested, need to send more info", "Spoke with partner, positive feedback", "Waiting on committee decision", nil].sample
    )
    target_count += 1
  end

  target_people.each do |person|
    next if DealTarget.exists?(deal_id: deal.id, target_type: "Person", target_id: person.id)

    status = deal_target_statuses.sample
    DealTarget.create!(
      deal_id: deal.id,
      target_type: "Person",
      target_id: person.id,
      status: status,
      role: ["advisor", "strategic_partner", "other"].sample,
      priority: rand(0..3),
      owner_id: users.sample.id,
      first_contacted_at: status != "not_started" ? rand(30).days.ago : nil,
      last_contacted_at: status != "not_started" ? rand(7).days.ago : nil,
      last_activity_at: status != "not_started" ? rand(3).days.ago : nil,
      activity_count: status != "not_started" ? rand(1..5) : 0,
      next_step: ["Intro call", "Get their take", "Ask for intros", nil].sample,
      next_step_at: rand(1..14).days.from_now
    )
    target_count += 1
  end
end

puts "   Created #{target_count} deal targets"

# ============================================
# 3. Create Activities (Events/Interactions)
# ============================================
puts "\n3. Creating activities..."

activity_kinds = ["call", "email", "meeting", "video_call", "in_person_meeting", "whatsapp", "linkedin_message", "note"]
call_outcomes = ["connected", "voicemail", "no_answer", "left_message"]
meeting_outcomes = ["completed", "cancelled", "no_show", "scheduled"]
email_outcomes = ["replied", "opened", "bounced"]

activity_count = 0

# Create activities for deal targets
DealTarget.includes(:deal, :target).find_each do |dt|
  next if dt.status == "not_started"

  # Create 2-8 activities per engaged deal target
  num_activities = rand(2..8)
  num_activities.times do |i|
    kind = activity_kinds.sample
    occurred_at = rand(60).days.ago + rand(86400).seconds

    outcome = case kind
    when "call" then call_outcomes.sample
    when "email" then email_outcomes.sample
    when "meeting", "video_call", "in_person_meeting" then meeting_outcomes.sample
    else nil
    end

    subject = case kind
    when "call" then ["Intro call", "Follow up", "Check in", "Deal discussion", "Q&A call"].sample
    when "email" then ["Deck shared", "Follow up", "Meeting request", "Thank you", "Introduction"].sample
    when "meeting", "video_call" then ["Initial meeting", "Due diligence call", "Partner meeting", "IC presentation"].sample
    when "in_person_meeting" then ["Coffee meeting", "Office visit", "Dinner meeting", "Conference catch-up"].sample
    when "linkedin_message" then ["Connection request", "Deal introduction", "Quick question"].sample
    when "note" then ["Internal note", "Research notes", "IC notes"].sample
    else "Activity"
    end

    activity = Activity.create!(
      kind: kind,
      subject: "#{subject} - #{dt.target_name}",
      body: ["Great conversation, they seem very interested.", "Left message, will try again.", "Shared deck and financials.", "Need to follow up next week.", nil].sample,
      direction: ["inbound", "outbound"].sample,
      outcome: outcome,
      occurred_at: occurred_at,
      duration_minutes: kind.include?("meeting") || kind == "call" ? [15, 30, 45, 60].sample : nil,
      regarding_type: dt.target_type,
      regarding_id: dt.target_id,
      deal_target_id: dt.id,
      deal_id: dt.deal_id,
      performed_by_id: users.sample.id,
      starts_at: kind.include?("meeting") ? occurred_at : nil,
      ends_at: kind.include?("meeting") ? occurred_at + [30, 60, 90].sample.minutes : nil,
      location: kind == "in_person_meeting" ? ["Arrow Office", "Their office", "Coffee shop", "Restaurant"].sample : nil,
      location_type: case kind
                     when "video_call" then "virtual"
                     when "in_person_meeting" then "in_person"
                     when "call" then "phone"
                     else nil
                     end,
      meeting_url: kind == "video_call" ? "https://zoom.us/j/#{rand(1000000000..9999999999)}" : nil
    )
    activity_count += 1
  end
end

# Create some standalone activities (not tied to deal targets)
20.times do
  person = people.sample
  kind = activity_kinds.sample
  occurred_at = rand(30).days.ago

  Activity.create!(
    kind: kind,
    subject: ["Catch up call", "Quick sync", "Intro meeting", "Networking", "Follow up"].sample,
    direction: ["inbound", "outbound"].sample,
    outcome: kind == "call" ? call_outcomes.sample : nil,
    occurred_at: occurred_at,
    duration_minutes: [15, 30, 45].sample,
    regarding_type: "Person",
    regarding_id: person.id,
    performed_by_id: users.sample.id,
    starts_at: kind.include?("meeting") ? occurred_at : nil,
    ends_at: kind.include?("meeting") ? occurred_at + 30.minutes : nil
  )
  activity_count += 1
end

# Create some upcoming scheduled meetings
10.times do
  person = people.sample
  deal = deals.sample
  starts_at = rand(1..14).days.from_now + rand(8..18).hours

  Activity.create!(
    kind: ["meeting", "video_call", "in_person_meeting"].sample,
    subject: ["Due diligence call", "Partner meeting", "IC presentation", "Deal review", "Intro meeting"].sample,
    occurred_at: starts_at,
    starts_at: starts_at,
    ends_at: starts_at + [30, 60].sample.minutes,
    regarding_type: "Person",
    regarding_id: person.id,
    deal_id: deal.id,
    performed_by_id: users.sample.id,
    location_type: "virtual",
    meeting_url: "https://zoom.us/j/#{rand(1000000000..9999999999)}"
  )
  activity_count += 1
end

# Create some tasks
15.times do
  deal = deals.sample
  due_date = rand(-5..14).days.from_now

  Activity.create!(
    kind: "task",
    subject: ["Send deck to investors", "Follow up with LP", "Prepare IC memo", "Update CRM", "Schedule call with founder", "Review term sheet", "Send wire instructions"].sample,
    occurred_at: Time.current,
    is_task: true,
    task_completed: due_date < Time.current ? [true, false].sample : false,
    task_due_at: due_date,
    assigned_to_id: users.sample.id,
    performed_by_id: users.sample.id,
    regarding_type: "Deal",
    regarding_id: deal.id,
    deal_id: deal.id
  )
  activity_count += 1
end

puts "   Created #{activity_count} activities"

# ============================================
# 4. Create More Relationships
# ============================================
puts "\n4. Creating relationships..."

# Get relationship types
knows_type = RelationshipType.find_by(slug: "knows") || RelationshipType.find_by(category: "professional")
invested_type = RelationshipType.find_by(slug: "invested_in") || RelationshipType.find_by(category: "investment")
colleague_type = RelationshipType.find_by(slug: "colleague") || RelationshipType.find_by(category: "professional")

relationship_count = 0

if knows_type
  # Create "knows" relationships between people
  30.times do
    person1 = people.sample
    person2 = (people - [person1]).sample

    next if Relationship.exists?(
      source_type: "Person", source_id: person1.id,
      target_type: "Person", target_id: person2.id
    )

    Relationship.create!(
      relationship_type_id: knows_type.id,
      source_type: "Person",
      source_id: person1.id,
      target_type: "Person",
      target_id: person2.id,
      strength: rand(1..5),
      status: "active",
      started_at: rand(365..1825).days.ago,
      notes: ["Met at conference", "Introduced by mutual friend", "Former colleagues", "Industry connection", nil].sample
    )
    relationship_count += 1
  end
end

if invested_type
  # Create investment relationships (org invested in org)
  15.times do
    fund = funds.sample
    company = companies.sample

    next if Relationship.exists?(
      source_type: "Organization", source_id: fund.id,
      target_type: "Organization", target_id: company.id,
      relationship_type_id: invested_type.id
    )

    Relationship.create!(
      relationship_type_id: invested_type.id,
      source_type: "Organization",
      source_id: fund.id,
      target_type: "Organization",
      target_id: company.id,
      status: "active",
      started_at: rand(365..1095).days.ago,
      notes: ["Series A investor", "Led Series B", "Follow-on investment", nil].sample
    )
    relationship_count += 1
  end
end

puts "   Created #{relationship_count} relationships"

# ============================================
# 5. Add More Blocks to Deals
# ============================================
puts "\n5. Creating blocks..."

block_statuses = ["available", "reserved", "sold", "withdrawn"]
block_share_classes = ["Common", "Series A Preferred", "Series B Preferred", "Series C Preferred", "Class A"]

block_count = 0
deals.select { |d| d.status == "live" }.each do |deal|
  existing_blocks = Block.where(deal_id: deal.id).count
  next if existing_blocks >= 3

  # Add 1-3 blocks per deal
  rand(1..3).times do
    seller = (companies + funds).sample
    contact = people.sample
    broker = brokers.sample if rand < 0.3

    shares = [10000, 25000, 50000, 100000, 250000].sample
    price = deal.valuation_cents.present? ? (deal.valuation_cents / 1_000_000 / shares.to_f * 100).to_i : rand(50_00..500_00)

    Block.create!(
      deal_id: deal.id,
      seller_type: "Organization",
      seller_id: seller.id,
      contact_id: contact.id,
      broker_id: broker&.id,
      share_class: block_share_classes.sample,
      shares: shares,
      price_cents: price,
      total_cents: shares * price,
      min_size_cents: [100_000_00, 250_000_00, 500_000_00].sample,
      status: block_statuses.sample,
      heat: rand(0..3),
      terms: ["Standard", "ROFR", "Lock-up 6mo", "Lock-up 12mo", nil].sample,
      expires_at: rand < 0.5 ? rand(7..60).days.from_now : nil,
      source: ["Direct", "Broker", "Network", "Inbound"].sample,
      verified: [true, false].sample,
      internal_notes: ["Strong seller, motivated to close", "Price negotiable", "Multiple interested parties", nil].sample
    )
    block_count += 1
  end
end

puts "   Created #{block_count} blocks"

# ============================================
# 6. Add More Interests to Deals
# ============================================
puts "\n6. Creating interests..."

interest_statuses = ["prospecting", "contacted", "soft_circled", "committed", "allocated", "funded", "declined"]

interest_count = 0
deals.select { |d| d.status == "live" }.each do |deal|
  existing_interests = Interest.where(deal_id: deal.id).count
  next if existing_interests >= 5

  # Add 2-5 interests per deal
  rand(2..5).times do
    investor = funds.sample
    contact = people.sample

    target = [500_000_00, 1_000_000_00, 2_500_000_00, 5_000_000_00].sample
    status = interest_statuses.sample
    committed = status.in?(["soft_circled", "committed", "allocated", "funded"]) ? (target * rand(0.5..1.0)).to_i : 0

    next if Interest.exists?(deal_id: deal.id, investor_id: investor.id)

    Interest.create!(
      deal_id: deal.id,
      investor_id: investor.id,
      contact_id: contact.id,
      owner_id: users.sample.id,
      target_cents: target,
      min_cents: (target * 0.5).to_i,
      max_cents: (target * 1.5).to_i,
      committed_cents: committed,
      status: status,
      source: ["Inbound", "Outbound", "Referral", "Conference"].sample,
      next_step: ["Schedule IC call", "Send docs", "Wait for committee", "Finalize allocation", nil].sample,
      next_step_at: rand(1..14).days.from_now,
      internal_notes: ["Very interested", "Need more time", "Waiting on final approval", nil].sample
    )
    interest_count += 1
  end
end

puts "   Created #{interest_count} interests"

# ============================================
# 7. Update People with more data
# ============================================
puts "\n7. Updating people with additional data..."

people_updated = 0
Person.where(source: nil).limit(50).each do |person|
  person.update!(
    source: ["referral", "linkedin", "conference", "cold_outreach", "inbound"].sample,
    last_contacted_at: rand < 0.7 ? rand(30).days.ago : nil,
    next_follow_up_at: rand < 0.3 ? rand(1..30).days.from_now : nil,
    contact_count: rand(0..15),
    internal_notes: rand < 0.4 ? ["Great contact, very responsive", "Key decision maker", "Good for intros", "Met at conference"].sample : nil
  )
  people_updated += 1
end

puts "   Updated #{people_updated} people"

# ============================================
# Final Summary
# ============================================
puts "\n" + "="*50
puts "SEED COMPLETE!"
puts "="*50
puts "Deals: #{Deal.count}"
puts "Deal Targets: #{DealTarget.count}"
puts "Activities: #{Activity.count}"
puts "Blocks: #{Block.count}"
puts "Interests: #{Interest.count}"
puts "Relationships: #{Relationship.count}"
puts "="*50
