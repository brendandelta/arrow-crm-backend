# Arrow CRM - Schema v3 (Production Ready)

## The Business
Arrow is a secondary market firm that:
1. **Sources deals** - companies with shares available
2. **Finds blocks** - sellers with shares to sell
3. **Matches investors** - buyers who want in
4. **Closes allocations** - who gets what shares

---

## 19 Tables

### TEAM (1)

```
users
├── id                  bigint PK
├── email               string, unique, required
├── first_name          string, required
├── last_name           string, required
├── calendar_id         string (gcal)
├── is_active           boolean, default: true
├── created_at
└── updated_at
```

### TAXONOMY (1)

```
sectors
├── id                  bigint PK
├── name                string, required
├── parent_id           FK → sectors (null = top-level)
├── created_at
└── updated_at

INDEX: parent_id
```

### CONTACTS (2)

```
people
├── id                  bigint PK
├── first_name          string, required
├── last_name           string, required
├── email               string (primary email for quick access)
├── phone               string (primary phone)
├── title               string
├── linkedin_url        string
├── city                string
├── country             string
├── headshot_url        string
├── source              enum: referral/conference/inbound/linkedin/cold_outreach
├── owner_id            FK → users
├── warmth              enum: cold/warm/hot/champion
├── notes               text
├── last_contacted_at   datetime
├── created_at
└── updated_at

INDEX: owner_id, warmth, last_contacted_at
INDEX: (lower(last_name), lower(first_name)) -- for sorting

organizations
├── id                  bigint PK
├── name                string, required
├── org_type            enum: fund/company/entity/other
├── website             string
├── linkedin_url        string
├── city                string
├── country             string
├── sector_id           FK → sectors
├── owner_id            FK → users
├── warmth              enum: cold/warm/hot/champion
├── notes               text
├── last_contacted_at   datetime
├── created_at
└── updated_at

INDEX: org_type, sector_id, owner_id, warmth
```

### PROFILES (3) - Type-specific fields, 1:1 with organizations

```
fund_profiles
├── id                  bigint PK
├── organization_id     FK → organizations, unique, required
├── aum_cents           bigint (assets under management)
├── strategies          string[] (growth_equity, venture, pe, family_office, hedge_fund)
├── stages              string[] (pre_seed, seed, series_a, series_b, growth, late)
├── geo_focus           string[] (us, europe, asia, latam, global)
├── check_min_cents     bigint
├── check_max_cents     bigint
├── sweet_spot_cents    bigint (typical check)
├── thesis              text
├── created_at
└── updated_at

company_profiles
├── id                  bigint PK
├── organization_id     FK → organizations, unique, required
├── founded_year        integer
├── employee_count      integer
├── total_raised_cents  bigint
├── last_valuation_cents bigint
├── last_round          string (Series B, etc)
├── last_round_date     date
├── has_rofr            boolean, default: false
├── rofr_details        text
├── transfer_restrictions text
├── created_at
└── updated_at

entity_profiles
├── id                  bigint PK
├── organization_id     FK → organizations, unique, required
├── ein                 string
├── formed_at           date
├── platform            enum: carta/sydecar/angellist/other
├── managing_member     string
├── created_at
└── updated_at
```

### RELATIONSHIPS (2)

```
contacts (additional contact methods beyond primary)
├── id                  bigint PK
├── person_id           FK → people, required
├── channel             enum: email/phone/whatsapp/linkedin/twitter/telegram/signal
├── value               string, required
├── label               enum: work/personal/assistant/other
├── is_primary          boolean, default: false
├── verified_at         datetime
├── created_at
└── updated_at

UNIQUE(person_id, channel, value)
INDEX: person_id

affiliations (who works where)
├── id                  bigint PK
├── person_id           FK → people, required
├── organization_id     FK → organizations, required
├── title               string
├── department          string
├── seniority           enum: c_level/vp/director/manager/individual/other
├── is_primary          boolean, default: false (their main job)
├── is_current          boolean, default: true
├── started_at          date
├── ended_at            date
├── created_at
└── updated_at

UNIQUE(person_id, organization_id, title)
INDEX: person_id, organization_id, is_current
```

### DEALS (4)

```
deals
├── id                  bigint PK
├── name                string, required
├── deal_type           enum: spv/direct_secondary/lp_transfer/tender/primary
├── company_id          FK → organizations, required
├── status              enum: sourcing/diligence/active/closing/closed/dead
├── stage               enum: s1_prospect/s2_loi/s3_diligence/s4_docs/s5_signing/s6_wiring
├── priority            enum: p0_urgent/p1_high/p2_medium/p3_low
├── target_cents        bigint (total raise target)
├── committed_cents     bigint (soft circles) - denormalized for speed
├── closed_cents        bigint (wired) - denormalized for speed
├── expected_close_date date
├── actual_close_date   date
├── drive_url           string
├── data_room_url       string
├── owner_id            FK → users, required
├── notes               text
├── created_at
└── updated_at

INDEX: company_id, status, stage, priority, owner_id
INDEX: expected_close_date

blocks (sell-side inventory)
├── id                  bigint PK
├── deal_id             FK → deals, required
├── name                string
├── seller_id           FK → organizations (who owns the shares)
├── seller_contact_id   FK → people (who we talk to)
├── share_class         enum: common/preferred/series_a/series_b/mixed
├── shares              bigint
├── price_per_share_cents bigint
├── total_cents         bigint
├── min_size_cents      bigint (minimum they'll sell)
├── valuation_cents     bigint
├── valuation_date      date
├── status              enum: available/soft_circled/reserved/sold/expired/dead
├── source              enum: direct/broker/referral/inbound
├── broker_id           FK → organizations
├── broker_contact_id   FK → people
├── broker_fee_bps      integer (basis points, e.g., 200 = 2%)
├── expires_at          date
├── notes               text
├── created_at
└── updated_at

INDEX: deal_id, status, seller_id

interests (buy-side demand)
├── id                  bigint PK
├── deal_id             FK → deals, required
├── investor_id         FK → organizations, required
├── contact_id          FK → people
├── target_cents        bigint (how much they want)
├── committed_cents     bigint (soft circle)
├── status              enum: prospecting/pitched/reviewing/interested/committed/allocated/wired/passed
├── pass_reason         text
├── source              enum: outbound/inbound/referral/existing_relationship
├── owner_id            FK → users
├── notes               text
├── created_at
└── updated_at

INDEX: deal_id, investor_id, status, owner_id

allocations (matches - who gets what)
├── id                  bigint PK
├── interest_id         FK → interests, required
├── block_id            FK → blocks, required
├── shares              bigint
├── amount_cents        bigint
├── status              enum: pending/confirmed/docs_out/docs_signed/wired/cancelled
├── confirmed_at        datetime
├── wired_at            datetime
├── notes               text
├── created_at
└── updated_at

UNIQUE(interest_id, block_id)
INDEX: interest_id, block_id, status
```

### PARTICIPANTS (1)

```
deal_participants (people involved beyond just investors)
├── id                  bigint PK
├── deal_id             FK → deals, required
├── person_id           FK → people, required
├── role                enum: buyer_contact/seller_contact/broker/lawyer/advisor/board_member/founder/source
├── notes               text
├── created_at
└── updated_at

UNIQUE(deal_id, person_id, role)
INDEX: deal_id, person_id
```

### MEETINGS (2)

```
meetings
├── id                  bigint PK
├── title               string, required
├── starts_at           datetime, required
├── ends_at             datetime
├── location            string
├── meeting_url         string (zoom/meet link)
├── meeting_type        enum: intro/pitch/diligence/negotiation/closing/check_in/other
├── deal_id             FK → deals (nullable)
├── owner_id            FK → users, required
├── gcal_id             string
├── gcal_url            string
├── summary             text
├── transcript_url      string
├── action_items        text
├── follow_up_at        date
├── created_at
└── updated_at

INDEX: deal_id, owner_id, starts_at

meeting_attendees
├── id                  bigint PK
├── meeting_id          FK → meetings, required
├── person_id           FK → people (null if not yet matched)
├── email               string (for unmatched/external attendees)
├── rsvp                enum: pending/accepted/declined/tentative
├── is_organizer        boolean, default: false
├── attended            boolean (did they actually show up)
├── created_at
└── updated_at

INDEX: meeting_id, person_id
```

### ATTACHMENTS (3)

```
documents
├── id                  bigint PK
├── name                string, required
├── doc_type            enum: deck/data_room/terms/loi/legal/memo/cap_table/financials/other
├── url                 string, required
├── storage             enum: google_drive/dropbox/notion/box/local
├── documentable_type   string (Deal/Organization/Person)
├── documentable_id     bigint
├── uploaded_by_id      FK → users
├── created_at
└── updated_at

INDEX: (documentable_type, documentable_id)
INDEX: doc_type

tags
├── id                  bigint PK
├── name                string, unique, required
├── color               string (#hex)
├── created_at
└── updated_at

taggings
├── id                  bigint PK
├── tag_id              FK → tags, required
├── taggable_type       string (Deal/Organization/Person)
├── taggable_id         bigint
├── created_at
└── updated_at

UNIQUE(tag_id, taggable_type, taggable_id)
INDEX: (taggable_type, taggable_id)
```

---

## ENUMS SUMMARY

```ruby
# Shared
enum :warmth, [:cold, :warm, :hot, :champion]
enum :source, [:referral, :conference, :inbound, :linkedin, :cold_outreach, :direct, :broker, :existing_relationship, :outbound]

# Organizations
enum :org_type, [:fund, :company, :entity, :other]

# Entity profiles
enum :platform, [:carta, :sydecar, :angellist, :other]

# Contacts
enum :channel, [:email, :phone, :whatsapp, :linkedin, :twitter, :telegram, :signal]
enum :label, [:work, :personal, :assistant, :other]

# Affiliations
enum :seniority, [:c_level, :vp, :director, :manager, :individual, :other]

# Deals
enum :deal_type, [:spv, :direct_secondary, :lp_transfer, :tender, :primary]
enum :deal_status, [:sourcing, :diligence, :active, :closing, :closed, :dead]
enum :stage, [:s1_prospect, :s2_loi, :s3_diligence, :s4_docs, :s5_signing, :s6_wiring]
enum :priority, [:p0_urgent, :p1_high, :p2_medium, :p3_low]

# Blocks
enum :share_class, [:common, :preferred, :series_a, :series_b, :mixed]
enum :block_status, [:available, :soft_circled, :reserved, :sold, :expired, :dead]

# Interests
enum :interest_status, [:prospecting, :pitched, :reviewing, :interested, :committed, :allocated, :wired, :passed]

# Allocations
enum :allocation_status, [:pending, :confirmed, :docs_out, :docs_signed, :wired, :cancelled]

# Deal participants
enum :participant_role, [:buyer_contact, :seller_contact, :broker, :lawyer, :advisor, :board_member, :founder, :source]

# Meetings
enum :meeting_type, [:intro, :pitch, :diligence, :negotiation, :closing, :check_in, :other]
enum :rsvp, [:pending, :accepted, :declined, :tentative]

# Documents
enum :doc_type, [:deck, :data_room, :terms, :loi, :legal, :memo, :cap_table, :financials, :other]
enum :storage, [:google_drive, :dropbox, :notion, :box, :local]
```

---

## MONEY: Use Cents

All money fields are `bigint` storing **cents** (or smallest currency unit):
- `1000000` = $10,000.00
- `100000000` = $1,000,000.00

Rails helper:
```ruby
class Deal < ApplicationRecord
  def target
    Money.new(target_cents, "USD")
  end
end
```

Or use the `money-rails` gem for automatic handling.

---

## KEY QUERIES

```ruby
# Pipeline: active deals by priority
Deal.where(status: [:sourcing, :diligence, :active])
    .order(priority: :asc, expected_close_date: :asc)

# Find investors interested in a company
company = Organization.find(id)
Interest.joins(:deal).where(deals: { company_id: company.id })

# Total soft circles for a deal
deal.interests.committed.sum(:committed_cents)

# Available inventory (blocks) for a deal
deal.blocks.where(status: :available)

# Investor's history across all deals
org.interests.includes(:deal).order(created_at: :desc)

# Meetings with a person
Meeting.joins(:meeting_attendees)
       .where(meeting_attendees: { person_id: person.id })
       .order(starts_at: :desc)

# Hot leads at funds who we haven't contacted in 30 days
Person.joins(affiliations: :organization)
      .where(warmth: :hot,
             organizations: { org_type: :fund },
             affiliations: { is_current: true })
      .where("last_contacted_at < ?", 30.days.ago)

# Documents for a deal
Document.where(documentable: deal)

# All entities tagged "priority"
Person.joins(taggings: :tag).where(tags: { name: "priority" })
```

---

## RAILS MODELS PREVIEW

```ruby
class Person < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true

  has_many :contacts, dependent: :destroy
  has_many :affiliations, dependent: :destroy
  has_many :organizations, through: :affiliations
  has_many :meeting_attendees, dependent: :destroy
  has_many :meetings, through: :meeting_attendees
  has_many :deal_participants, dependent: :destroy
  has_many :deals, through: :deal_participants
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :documents, as: :documentable, dependent: :destroy

  enum :warmth, { cold: 0, warm: 1, hot: 2, champion: 3 }
  enum :source, { referral: 0, conference: 1, inbound: 2, linkedin: 3, cold_outreach: 4 }

  def full_name
    "#{first_name} #{last_name}"
  end

  def current_organization
    affiliations.current.primary.first&.organization
  end
end

class Deal < ApplicationRecord
  belongs_to :company, class_name: "Organization"
  belongs_to :owner, class_name: "User"

  has_many :blocks, dependent: :destroy
  has_many :interests, dependent: :destroy
  has_many :allocations, through: :interests
  has_many :deal_participants, dependent: :destroy
  has_many :participants, through: :deal_participants, source: :person
  has_many :meetings, dependent: :nullify
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :documents, as: :documentable, dependent: :destroy

  enum :deal_type, { spv: 0, direct_secondary: 1, lp_transfer: 2, tender: 3, primary: 4 }
  enum :status, { sourcing: 0, diligence: 1, active: 2, closing: 3, closed: 4, dead: 5 }
  enum :priority, { p0_urgent: 0, p1_high: 1, p2_medium: 2, p3_low: 3 }

  scope :pipeline, -> { where(status: [:sourcing, :diligence, :active, :closing]) }
  scope :by_priority, -> { order(priority: :asc) }
end
```

---

## TABLE COUNT: 19

| Category | Tables | Count |
|----------|--------|-------|
| Team | users | 1 |
| Taxonomy | sectors | 1 |
| Contacts | people, organizations | 2 |
| Profiles | fund_profiles, company_profiles, entity_profiles | 3 |
| Relationships | contacts, affiliations | 2 |
| Deals | deals, blocks, interests, allocations | 4 |
| Participants | deal_participants | 1 |
| Meetings | meetings, meeting_attendees | 2 |
| Attachments | documents, tags, taggings | 3 |
| **Total** | | **19** |
