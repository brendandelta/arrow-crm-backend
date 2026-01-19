# ARROW CRM - DATABASE SCHEMA (FINAL)
## Optimized for Rails + PostgreSQL

---

## SUMMARY

| Before | After |
|--------|-------|
| 24 Airtable Tables | 10 PostgreSQL Tables |

---

## TABLES (10)

### 1. USERS (internal team)

```
users
├── id                  bigint PK
├── email               string, unique, required
├── first_name          string, required
├── last_name           string, required
├── phone               string
├── avatar_url          string
├── calendar_id         string (gcal)
├── timezone            string, default: 'America/New_York'
├── role                string (admin/member)
├── is_active           boolean, default: true
├── last_seen_at        datetime
├── created_at
└── updated_at
```

---

### 2. PEOPLE (external contacts)

```
people
├── id                  bigint PK
│
│   -- NAME
├── first_name          string, required
├── last_name           string, required
├── nickname            string (what they go by)
├── prefix              string (Mr/Ms/Dr)
├── suffix              string (Jr/III/PhD)
│
│   -- CONTACT INFO
├── emails              jsonb, default: []
│                       └── [{value, label, primary, verified}]
├── phones              jsonb, default: []
│                       └── [{value, label, primary}]
├── preferred_contact   string (email/phone/whatsapp/linkedin)
│
│   -- LOCATION
├── address_line1       string
├── address_line2       string
├── city                string
├── state               string
├── postal_code         string
├── country             string
├── timezone            string
│
│   -- PROFESSIONAL
├── title               string
├── department          string
├── linkedin_url        string
├── twitter_url         string
├── bio                 text
│
│   -- PERSONAL
├── birthday            date
├── avatar_url          string
├── pronouns            string
│
│   -- CRM FIELDS
├── source              string (referral/linkedin/conference/inbound/cold/website)
├── source_detail       string (which conference, who referred, etc)
├── warmth              integer, default: 0 (0=cold, 1=warm, 2=hot, 3=champion)
├── owner_id            FK → users
├── tags                string[], default: []
├── custom_fields       jsonb, default: {}
│
│   -- TRACKING
├── notes               text
├── last_contacted_at   datetime
├── next_follow_up_at   datetime
├── contact_count       integer, default: 0
├── created_at
└── updated_at

INDEXES:
  - owner_id
  - warmth
  - tags (GIN)
  - last_contacted_at
  - (lower(last_name), lower(first_name))
  - country, state, city
```

**emails/phones jsonb:**
```json
{
  "emails": [
    {"value": "john@acme.com", "label": "work", "primary": true, "verified": true},
    {"value": "john@gmail.com", "label": "personal", "primary": false, "verified": false}
  ],
  "phones": [
    {"value": "+1-555-123-4567", "label": "mobile", "primary": true},
    {"value": "+1-555-987-6543", "label": "work", "primary": false}
  ]
}
```

---

### 3. ORGANIZATIONS (funds, companies, SPVs)

```
organizations
├── id                  bigint PK
│
│   -- BASIC INFO
├── name                string, required
├── legal_name          string (full legal name if different)
├── kind                string, required (fund/company/spv/broker/law_firm/other)
├── description         text
├── logo_url            string
│
│   -- CONTACT INFO
├── website             string
├── linkedin_url        string
├── twitter_url         string
├── crunchbase_url      string
├── pitchbook_url       string
├── phone               string
├── email               string (general contact)
│
│   -- LOCATION (HQ)
├── address_line1       string
├── address_line2       string
├── city                string
├── state               string
├── postal_code         string
├── country             string
├── timezone            string
│
│   -- CLASSIFICATION
├── sector              string (fintech/healthcare/saas/consumer/enterprise/etc)
├── sub_sector          string
├── stage               string (seed/early/growth/late/public)
├── employee_range      string (1-10/11-50/51-200/201-500/500+)
│
│   -- HIERARCHY
├── parent_org_id       FK → organizations (for subsidiaries)
│
│   -- TYPE-SPECIFIC DATA
├── meta                jsonb, default: {}
│
│   -- CRM FIELDS
├── warmth              integer, default: 0
├── owner_id            FK → users
├── tags                string[], default: []
├── custom_fields       jsonb, default: {}
│
│   -- TRACKING
├── notes               text
├── last_contacted_at   datetime
├── next_follow_up_at   datetime
├── created_at
└── updated_at

INDEXES:
  - kind
  - sector
  - owner_id
  - warmth
  - tags (GIN)
  - parent_org_id
  - country, state, city
```

#### META JSONB BY KIND

**Fund** (kind = "fund"):
```json
{
  "fund_type": "venture",
  "aum_cents": 50000000000,
  "fund_size_cents": 25000000000,
  "vintage_year": 2023,
  "strategies": ["growth_equity", "venture", "pe", "family_office", "hedge_fund"],
  "stages": ["pre_seed", "seed", "series_a", "series_b", "growth", "late"],
  "geo_focus": ["us", "europe", "asia", "latam", "global"],
  "sector_focus": ["fintech", "saas", "healthcare", "consumer"],
  "check_min_cents": 10000000,
  "check_max_cents": 500000000,
  "sweet_spot_cents": 100000000,
  "thesis": "B2B software in North America",
  "portfolio_count": 45,
  "team_size": 12,
  "decision_maker": "Investment Committee",
  "typical_timeline_days": 45,
  "co_invest_friendly": true,
  "spv_friendly": true
}
```

**Company** (kind = "company"):
```json
{
  "founded_year": 2015,
  "incorporated_state": "DE",
  "incorporated_country": "US",
  "employee_count": 2500,
  "total_raised_cents": 50000000000,
  "valuation_cents": 100000000000,
  "valuation_date": "2024-06-15",
  "last_round": "Series D",
  "last_round_cents": 15000000000,
  "last_round_date": "2024-06",
  "lead_investors": ["Sequoia", "a]6z"],
  "cap_table_url": "https://carta.com/...",
  "has_rofr": true,
  "rofr_days": 30,
  "rofr_details": "Company has 30 days to match any offer",
  "transfer_restrictions": "Board approval required, 60 day notice",
  "blackout_periods": "Q4 annually",
  "min_transfer_size_cents": 10000000,
  "trading_status": "active",
  "next_round_expected": "2025-Q2",
  "ipo_timeline": "18-24 months",
  "revenue_cents": 10000000000,
  "arr_cents": 8000000000,
  "burn_rate_cents": 500000000
}
```

**SPV** (kind = "spv"):
```json
{
  "ein": "12-3456789",
  "formed_at": "2024-01-15",
  "dissolved_at": null,
  "platform": "carta",
  "managing_member": "Arrow GP LLC",
  "management_fee_bps": 200,
  "carry_bps": 2000,
  "admin_fee_cents": 1500000,
  "target_size_cents": 500000000,
  "min_investment_cents": 2500000,
  "target_company_id": 123,
  "wire_deadline": "2024-02-15",
  "investor_count": 25
}
```

**Broker** (kind = "broker"):
```json
{
  "broker_type": "secondary",
  "typical_fee_bps": 200,
  "min_deal_size_cents": 100000000,
  "specialty": ["late-stage", "pre-ipo"],
  "coverage_regions": ["us", "europe"],
  "active_mandates": 15
}
```

**Law Firm** (kind = "law_firm"):
```json
{
  "practice_areas": ["venture", "m&a", "securities"],
  "typical_rate_cents": 75000,
  "preferred_for": ["spv_formation", "transfer_docs"]
}
```

---

### 4. EMPLOYMENTS (who works where)

```
employments
├── id                  bigint PK
├── person_id           FK → people, required
├── organization_id     FK → organizations, required
├── title               string
├── department          string
├── seniority           string (c_suite/vp/director/manager/ic/intern)
├── email               string (work email at this org)
├── phone               string (work phone)
├── is_primary          boolean, default: false (main job)
├── is_current          boolean, default: true
├── started_at          date
├── ended_at            date
├── notes               text
├── created_at
└── updated_at

UNIQUE: (person_id, organization_id, title)
INDEXES: person_id, organization_id, is_current, is_primary
```

---

### 5. DEALS (transactions)

```
deals
├── id                  bigint PK
│
│   -- BASIC INFO
├── name                string, required
├── kind                string, required (spv/secondary/lp_transfer/tender/primary)
├── company_id          FK → organizations, required
│
│   -- PIPELINE
├── status              string, default: 'sourcing'
│                       └── sourcing/qualifying/active/diligence/negotiating/closing/closed/dead
├── stage               string, default: 's1'
│                       └── s1_lead/s2_qualified/s3_loi/s4_diligence/s5_docs/s6_signing/s7_wiring/s8_closed
├── priority            integer, default: 2 (0=urgent, 1=high, 2=medium, 3=low)
├── confidence          integer (0-100 probability %)
│
│   -- FINANCIALS
├── target_cents        bigint (total raise target)
├── min_raise_cents     bigint
├── max_raise_cents     bigint
├── committed_cents     bigint, default: 0 (denormalized)
├── closed_cents        bigint, default: 0 (denormalized)
│
│   -- TERMS
├── valuation_cents     bigint
├── share_price_cents   bigint
├── share_class         string
├── structure_notes     text
│
│   -- DATES
├── sourced_at          date
├── qualified_at        date
├── expected_close      date
├── deadline            date (hard deadline if any)
├── closed_at           date
│
│   -- SOURCE & TRACKING
├── source              string (inbound/outbound/referral/broker)
├── source_detail       string
├── referred_by_id      FK → people
├── broker_id           FK → organizations
├── competitors         string[] (other firms on this deal)
│
│   -- LINKS
├── drive_url           string
├── data_room_url       string
├── notion_url          string
├── deck_url            string
│
│   -- OWNERSHIP
├── owner_id            FK → users, required
├── team_member_ids     bigint[] (other team members)
│
│   -- META
├── tags                string[], default: []
├── custom_fields       jsonb, default: {}
├── notes               text
├── created_at
└── updated_at

INDEXES:
  - company_id
  - status
  - stage
  - priority
  - owner_id
  - expected_close
  - tags (GIN)
```

---

### 6. BLOCKS (sell-side inventory)

```
blocks
├── id                  bigint PK
├── deal_id             FK → deals, required
│
│   -- SELLER
├── seller_id           FK → organizations
├── contact_id          FK → people (who we talk to)
├── seller_type         string (employee/ex_employee/investor/founder/institution)
│
│   -- SHARES
├── share_class         string (common/preferred/series_a/series_b/mixed)
├── shares              bigint
├── price_cents         bigint (per share)
├── total_cents         bigint
├── min_size_cents      bigint (minimum they'll sell)
│
│   -- VALUATION
├── implied_valuation_cents  bigint
├── discount_pct        decimal (discount to last round)
├── valuation_date      date
│
│   -- STATUS
├── status              string, default: 'available'
│                       └── available/in_discussion/soft_circled/reserved/sold/expired/dead
├── status_changed_at   datetime
├── expires_at          date
│
│   -- SOURCE
├── source              string (direct/broker/referral/inbound)
├── source_detail       string
├── broker_id           FK → organizations
├── broker_contact_id   FK → people
├── broker_fee_bps      integer (basis points, 200 = 2%)
├── exclusivity         boolean, default: false
├── exclusivity_until   date
│
│   -- VERIFICATION
├── verified            boolean, default: false
├── verified_at         datetime
├── verification_notes  text
│
│   -- META
├── notes               text
├── created_at
└── updated_at

INDEXES: deal_id, status, seller_id, source
```

---

### 7. INTERESTS (buy-side demand)

```
interests
├── id                  bigint PK
├── deal_id             FK → deals, required
│
│   -- INVESTOR
├── investor_id         FK → organizations, required
├── contact_id          FK → people
├── decision_maker_id   FK → people
│
│   -- AMOUNTS
├── target_cents        bigint (how much they want)
├── min_cents           bigint
├── max_cents           bigint
├── committed_cents     bigint (soft circle)
├── allocated_cents     bigint (final allocation)
│
│   -- STATUS
├── status              string, default: 'prospecting'
│                       └── prospecting/contacted/pitched/reviewing/interested/
│                           committed/allocated/docs_sent/docs_signed/wired/passed
├── status_changed_at   datetime
├── pass_reason         string
├── pass_notes          text
│
│   -- ALLOCATION
├── allocated_block_id  FK → blocks (null until matched)
├── wired_at            date
├── wire_amount_cents   bigint
│
│   -- SOURCE
├── source              string (existing_relationship/outbound/inbound/referral)
├── source_detail       string
├── introduced_by_id    FK → people
│
│   -- TRACKING
├── first_contacted_at  datetime
├── last_contacted_at   datetime
├── meetings_count      integer, default: 0
├── response_time_days  integer
│
│   -- OWNERSHIP
├── owner_id            FK → users
│
│   -- META
├── notes               text
├── next_step           string
├── next_step_at        datetime
├── created_at
└── updated_at

INDEXES: deal_id, investor_id, status, owner_id
```

---

### 8. MEETINGS (calendar + interactions)

```
meetings
├── id                  bigint PK
│
│   -- BASIC INFO
├── title               string, required
├── description         text
├── kind                string (intro/pitch/diligence/negotiation/closing/check_in/internal/other)
│
│   -- TIMING
├── starts_at           datetime, required
├── ends_at             datetime
├── timezone            string
├── all_day             boolean, default: false
├── is_recurring        boolean, default: false
├── recurrence_rule     string (ical format)
│
│   -- LOCATION
├── location            string
├── location_type       string (in_person/video/phone)
├── meeting_url         string (zoom/meet/teams link)
├── dial_in             string
├── address             string (if in-person)
│
│   -- RELATIONSHIPS
├── deal_id             FK → deals (nullable)
├── organization_id     FK → organizations (nullable)
├── owner_id            FK → users, required
│
│   -- ATTENDEES
├── attendee_ids        bigint[], default: [] (people ids)
├── internal_attendee_ids bigint[], default: [] (user ids)
├── external_attendees  jsonb, default: []
│                       └── [{email, name, rsvp}]
│
│   -- CALENDAR SYNC
├── gcal_id             string
├── gcal_url            string
├── outlook_id          string
├── synced_at           datetime
│
│   -- CONTENT
├── agenda              text
├── summary             text
├── action_items        text
├── transcript_url      string
├── recording_url       string
│
│   -- FOLLOW-UP
├── outcome             string (completed/cancelled/rescheduled/no_show)
├── follow_up_needed    boolean, default: false
├── follow_up_at        date
├── follow_up_notes     text
│
│   -- META
├── tags                string[], default: []
├── created_at
└── updated_at

INDEXES:
  - deal_id
  - organization_id
  - owner_id
  - starts_at
  - attendee_ids (GIN)
  - kind
```

**external_attendees jsonb:**
```json
[
  {"email": "external@company.com", "name": "John External", "rsvp": "accepted"},
  {"email": "other@firm.com", "name": null, "rsvp": "pending"}
]
```

---

### 9. DOCUMENTS (attachments)

```
documents
├── id                  bigint PK
├── name                string, required
├── kind                string (deck/terms/loi/legal/memo/data_room/cap_table/financials/diligence/other)
├── url                 string, required
├── file_type           string (pdf/doc/xls/ppt/etc)
├── file_size_bytes     bigint
├── storage             string (google_drive/dropbox/notion/s3/box)
├── version             integer, default: 1
├── parent_type         string, required (Deal/Organization/Person)
├── parent_id           bigint, required
├── uploaded_by_id      FK → users
├── description         text
├── is_confidential     boolean, default: false
├── expires_at          date
├── created_at
└── updated_at

INDEXES: (parent_type, parent_id), kind, uploaded_by_id
```

---

### 10. NOTES (activity log / comments)

```
notes
├── id                  bigint PK
├── body                text, required
├── kind                string, default: 'note'
│                       └── note/call/email/meeting_note/task/status_change/system
├── parent_type         string, required (Deal/Organization/Person/Meeting/Block/Interest)
├── parent_id           bigint, required
├── author_id           FK → users, required
├── pinned              boolean, default: false
├── is_private          boolean, default: false
│
│   -- FOR ACTIVITY TRACKING
├── activity_at         datetime (when the activity happened, if different from created_at)
├── duration_minutes    integer (for calls)
├── outcome             string (for calls: connected/voicemail/no_answer)
│
│   -- MENTIONS
├── mentioned_user_ids  bigint[], default: []
├── mentioned_deal_ids  bigint[], default: []
├── mentioned_org_ids   bigint[], default: []
├── mentioned_person_ids bigint[], default: []
│
├── created_at
└── updated_at

INDEXES:
  - (parent_type, parent_id)
  - author_id
  - pinned
  - kind
  - activity_at
```

---

## WHAT GOT CONSOLIDATED

| Original Airtable (24) | Final PostgreSQL (10) |
|------------------------|----------------------|
| People | people |
| Contact Identifiers | people.emails (jsonb) |
| Contact Methods | people.phones (jsonb) |
| Organizations | organizations |
| Fund Profiles | organizations.meta (jsonb) |
| Company Profiles | organizations.meta (jsonb) |
| Internal Entity Profiles | organizations.meta (jsonb) |
| Sectors + Subsectors | organizations.sector + sub_sector |
| Location | Full address fields on people & orgs |
| Affiliations | employments |
| Personal Relationships | REMOVED (use notes/meetings) |
| Organization Relationships | REMOVED (use deals) |
| Deals | deals |
| Blocks | blocks |
| LP/GP Interests | interests |
| Block Interests | interests.allocated_block_id |
| Meetings | meetings |
| GCAL Sync (x3) | meetings.owner_id |
| Meeting Attendees | meetings.attendee_ids + external_attendees |
| Meeting Deals | meetings.deal_id |
| Documents | documents (polymorphic) |
| Document Links | documents.parent_type/id |
| Tags | tags[] array on each model |
| Tagged Items | tags[] array on each model |
| Relationship Events | notes (activity log) |

---

## LOCATION FIELDS SUMMARY

| Model | Fields |
|-------|--------|
| users | timezone |
| people | address_line1, address_line2, city, state, postal_code, country, timezone |
| organizations | address_line1, address_line2, city, state, postal_code, country, timezone |
| meetings | location, location_type, address, timezone |

---

## STATUS FLOWS

**Deal Status:**
```
sourcing → qualifying → active → diligence → negotiating → closing → closed
                                                                  ↘ dead
```

**Deal Stage:**
```
s1_lead → s2_qualified → s3_loi → s4_diligence → s5_docs → s6_signing → s7_wiring → s8_closed
```

**Block Status:**
```
available → in_discussion → soft_circled → reserved → sold
                                                   ↘ expired/dead
```

**Interest Status:**
```
prospecting → contacted → pitched → reviewing → interested → committed → allocated → docs_sent → docs_signed → wired
                                                                                                            ↘ passed
```

---

## MONEY HANDLING

All money stored as **CENTS** (bigint):
- `1000000` = $10,000.00
- `100000000` = $1,000,000.00

---

## RAILS MODELS

```ruby
class User < ApplicationRecord
  has_many :owned_people, class_name: "Person", foreign_key: :owner_id
  has_many :owned_organizations, class_name: "Organization", foreign_key: :owner_id
  has_many :owned_deals, class_name: "Deal", foreign_key: :owner_id
  has_many :owned_interests, class_name: "Interest", foreign_key: :owner_id
  has_many :meetings, foreign_key: :owner_id
  has_many :notes, foreign_key: :author_id
  has_many :documents, foreign_key: :uploaded_by_id

  scope :active, -> { where(is_active: true) }

  def full_name = "#{first_name} #{last_name}"
end

class Person < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :employments, dependent: :destroy
  has_many :organizations, through: :employments
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy

  scope :warm, -> { where(warmth: 1..) }
  scope :hot, -> { where(warmth: 2..) }
  scope :champions, -> { where(warmth: 3) }
  scope :tagged, ->(t) { where("? = ANY(tags)", t) }
  scope :in_country, ->(c) { where(country: c) }
  scope :in_state, ->(s) { where(state: s) }
  scope :in_city, ->(c) { where(city: c) }
  scope :needs_follow_up, -> { where("next_follow_up_at <= ?", Date.current) }

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def formal_name
    [prefix, first_name, last_name, suffix].compact.join(" ")
  end

  def display_name
    nickname.presence || first_name
  end

  def primary_email
    emails.find { |e| e["primary"] }&.dig("value")
  end

  def primary_phone
    phones.find { |p| p["primary"] }&.dig("value")
  end

  def current_employment
    employments.find_by(is_current: true, is_primary: true)
  end

  def current_org
    current_employment&.organization
  end

  def current_title
    current_employment&.title
  end

  def location
    [city, state, country].compact.join(", ")
  end
end

class Organization < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :parent_org, class_name: "Organization", optional: true
  has_many :subsidiaries, class_name: "Organization", foreign_key: :parent_org_id
  has_many :employments, dependent: :destroy
  has_many :people, through: :employments
  has_many :deals, foreign_key: :company_id
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy

  scope :funds, -> { where(kind: "fund") }
  scope :companies, -> { where(kind: "company") }
  scope :spvs, -> { where(kind: "spv") }
  scope :brokers, -> { where(kind: "broker") }
  scope :tagged, ->(t) { where("? = ANY(tags)", t) }
  scope :in_sector, ->(s) { where(sector: s) }
  scope :in_country, ->(c) { where(country: c) }

  def fund? = kind == "fund"
  def company? = kind == "company"
  def spv? = kind == "spv"
  def broker? = kind == "broker"

  def location
    [city, state, country].compact.join(", ")
  end

  def full_address
    [address_line1, address_line2, city, state, postal_code, country].compact.join(", ")
  end

  # Delegate meta accessors
  %w[aum_cents strategies stages geo_focus sector_focus check_min_cents check_max_cents
     sweet_spot_cents thesis fund_size_cents vintage_year].each do |attr|
    define_method(attr) { meta[attr] }
  end

  %w[founded_year employee_count total_raised_cents valuation_cents last_round
     last_round_date has_rofr rofr_days transfer_restrictions].each do |attr|
    define_method(attr) { meta[attr] }
  end

  def has_rofr? = meta["has_rofr"] == true
end

class Employment < ApplicationRecord
  belongs_to :person
  belongs_to :organization

  scope :current, -> { where(is_current: true) }
  scope :primary, -> { where(is_primary: true) }

  def current_and_primary?
    is_current && is_primary
  end
end

class Deal < ApplicationRecord
  belongs_to :company, class_name: "Organization"
  belongs_to :owner, class_name: "User"
  belongs_to :referred_by, class_name: "Person", optional: true
  belongs_to :broker, class_name: "Organization", optional: true
  has_many :blocks, dependent: :destroy
  has_many :interests, dependent: :destroy
  has_many :meetings, dependent: :nullify
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy

  scope :pipeline, -> { where(status: %w[sourcing qualifying active diligence negotiating closing]) }
  scope :active, -> { where(status: %w[active diligence negotiating closing]) }
  scope :closed, -> { where(status: "closed") }
  scope :dead, -> { where(status: "dead") }
  scope :by_priority, -> { order(:priority) }
  scope :by_stage, -> { order(:stage) }
  scope :tagged, ->(t) { where("? = ANY(tags)", t) }
  scope :closing_soon, -> { where("expected_close <= ?", 30.days.from_now) }

  def investors
    Organization.where(id: interests.select(:investor_id))
  end

  def sellers
    Organization.where(id: blocks.select(:seller_id))
  end

  def committed_total
    interests.committed.sum(:committed_cents)
  end

  def closed_total
    interests.wired.sum(:wire_amount_cents)
  end

  def progress_pct
    return 0 if target_cents.nil? || target_cents.zero?
    ((committed_cents || 0) * 100.0 / target_cents).round
  end
end

class Block < ApplicationRecord
  belongs_to :deal
  belongs_to :seller, class_name: "Organization", optional: true
  belongs_to :contact, class_name: "Person", optional: true
  belongs_to :broker, class_name: "Organization", optional: true
  belongs_to :broker_contact, class_name: "Person", optional: true
  has_many :interests, foreign_key: :allocated_block_id

  scope :available, -> { where(status: "available") }
  scope :sold, -> { where(status: "sold") }
  scope :expiring_soon, -> { where("expires_at <= ?", 14.days.from_now) }
  scope :verified, -> { where(verified: true) }
end

class Interest < ApplicationRecord
  belongs_to :deal
  belongs_to :investor, class_name: "Organization"
  belongs_to :contact, class_name: "Person", optional: true
  belongs_to :decision_maker, class_name: "Person", optional: true
  belongs_to :allocated_block, class_name: "Block", optional: true
  belongs_to :introduced_by, class_name: "Person", optional: true
  belongs_to :owner, class_name: "User", optional: true

  scope :active, -> { where(status: %w[prospecting contacted pitched reviewing interested committed]) }
  scope :committed, -> { where(status: "committed") }
  scope :wired, -> { where(status: "wired") }
  scope :passed, -> { where(status: "passed") }
  scope :needs_follow_up, -> { where("next_step_at <= ?", Date.current) }

  def allocated? = allocated_block_id.present?
  def wired? = status == "wired"
end

class Meeting < ApplicationRecord
  belongs_to :deal, optional: true
  belongs_to :organization, optional: true
  belongs_to :owner, class_name: "User"
  has_many :notes, as: :parent, dependent: :destroy

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past, -> { where("starts_at < ?", Time.current).order(starts_at: :desc) }
  scope :today, -> { where(starts_at: Date.current.all_day) }
  scope :this_week, -> { where(starts_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :needs_follow_up, -> { where(follow_up_needed: true, outcome: "completed") }

  def attendees
    Person.where(id: attendee_ids)
  end

  def internal_attendees
    User.where(id: internal_attendee_ids)
  end

  def duration_minutes
    return nil unless starts_at && ends_at
    ((ends_at - starts_at) / 60).to_i
  end
end

class Document < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :uploaded_by, class_name: "User", optional: true

  scope :by_kind, ->(k) { where(kind: k) }
  scope :confidential, -> { where(is_confidential: true) }
  scope :expiring_soon, -> { where("expires_at <= ?", 30.days.from_now) }
end

class Note < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :author, class_name: "User"

  scope :pinned, -> { where(pinned: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :calls, -> { where(kind: "call") }
  scope :emails, -> { where(kind: "email") }
  scope :by_kind, ->(k) { where(kind: k) }
  scope :visible, -> { where(is_private: false) }

  def mentioned_users
    User.where(id: mentioned_user_ids)
  end

  def mentioned_deals
    Deal.where(id: mentioned_deal_ids)
  end
end
```
