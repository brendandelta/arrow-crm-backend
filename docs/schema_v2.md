# Arrow CRM - Optimized Schema v2

## Goals
- Fewer tables (17 instead of 21)
- Rails conventions (polymorphic, simple FKs)
- No awkward CHECK constraints
- Easy to query
- Every table has `created_at` and `updated_at`

---

## TABLES: 17 Total

### CORE (4 tables)

```
users
├── id
├── email              unique, required
├── name               required
├── calendar_id        for gcal sync
├── is_active          default true
└── timestamps

sectors
├── id
├── name               required
├── parent_id          FK → sectors (null = top-level)
├── description
├── is_active          default true
└── timestamps

people
├── id
├── name               required (full name, simpler than first/last)
├── title
├── city
├── country
├── headshot_url
├── linkedin_url
├── owner_id           FK → users
├── warmth             enum: cold/warm/hot/champion
├── notes              text
├── last_contacted_at  datetime
└── timestamps

organizations
├── id
├── name               required
├── org_type           enum: fund/company/entity/other
├── website
├── linkedin_url
├── city
├── country
├── sector_id          FK → sectors
├── owner_id           FK → users
├── warmth             enum: cold/warm/hot/champion
├── notes              text
├── last_contacted_at  datetime
└── timestamps
```

### PROFILES (3 tables) - Only type-specific fields

```
fund_profiles
├── id
├── organization_id    FK → organizations, unique
├── aum                money (assets under management)
├── investor_types     text[] (growth_equity, venture, pe, family_office)
├── stages             text[] (seed, series_a, series_b, growth)
├── min_check          money
├── max_check          money
├── thesis             text
└── timestamps

company_profiles
├── id
├── organization_id    FK → organizations, unique
├── last_valuation     money
├── last_round         text (Series B, etc)
├── last_round_date    date
├── has_rofr           boolean
├── transfer_notes     text
└── timestamps

entity_profiles
├── id
├── organization_id    FK → organizations, unique
├── ein                text
├── formed_at          date
├── platform           text (carta/sydecar/angellist)
├── spv_url
└── timestamps
```

### CONNECTIONS (3 tables)

```
contacts
├── id
├── person_id          FK → people, required
├── channel            enum: email/phone/whatsapp/linkedin/twitter
├── value              required (the actual email/phone/url)
├── is_primary         default false
├── verified           default false
└── timestamps
UNIQUE(person_id, channel, value)

affiliations
├── id
├── person_id          FK → people, required
├── organization_id    FK → organizations, required
├── role               text (Partner, Analyst, CEO, etc)
├── is_current         default true
├── started_at         date
├── ended_at           date
└── timestamps
UNIQUE(person_id, organization_id) -- one role per org

introductions
├── id
├── introducer_id      FK → people, required
├── introduced_id      FK → people, required
├── context            text (how/why)
├── introduced_at      date
└── timestamps
```

### DEALS (4 tables)

```
deals
├── id
├── name               required
├── deal_type          enum: spv/direct/lp_transfer/tender/primary
├── company_id         FK → organizations
├── status             enum: sourcing/active/closing/closed/dead
├── priority           enum: urgent/high/medium/low
├── score              integer (1-100)
├── target_raise       money
├── drive_url
├── owner_id           FK → users
├── notes              text
└── timestamps

blocks
├── id
├── deal_id            FK → deals, required
├── seller_id          FK → organizations
├── share_class        enum: common/preferred/mixed
├── shares             integer
├── price_per_share    money
├── total_value        money
├── status             enum: available/reserved/sold/dead
├── expires_at         date
├── notes              text
└── timestamps

interests
├── id
├── deal_id            FK → deals, required
├── investor_id        FK → organizations, required
├── contact_id         FK → people
├── amount             money (soft circle)
├── status             enum: interested/committed/wired/passed
├── wired_at           date
├── notes              text
└── timestamps

matches
├── id
├── interest_id        FK → interests, required
├── block_id           FK → blocks, required
├── status             enum: pending/matched/closed/cancelled
├── notes              text
└── timestamps
UNIQUE(interest_id, block_id)
```

### MEETINGS (1 table)

```
meetings
├── id
├── title              required
├── starts_at          datetime
├── ends_at            datetime
├── location           text
├── deal_id            FK → deals (nullable)
├── gcal_id            text (external calendar id)
├── gcal_url
├── owner_id           FK → users (whose calendar)
├── summary            text
├── transcript_url
├── follow_up_at       date
├── attendee_ids       integer[] (people ids)
├── external_emails    text[] (non-matched attendees)
└── timestamps
```

### ATTACHMENTS (2 tables)

```
documents
├── id
├── name               required
├── doc_type           enum: deck/terms/legal/memo/cap_table/other
├── url                required
├── owner_id           FK → users
├── documentable_type  string (Organization/Person/Deal)
├── documentable_id    integer
└── timestamps
INDEX(documentable_type, documentable_id)

tags
├── id
├── name               unique, required
├── color              text (#hex)
└── timestamps

taggings
├── id
├── tag_id             FK → tags, required
├── taggable_type      string (Organization/Person/Deal)
├── taggable_id        integer
└── timestamps
UNIQUE(tag_id, taggable_type, taggable_id)
```

---

## WHAT CHANGED

| Before (21) | After (17) | Change |
|-------------|------------|--------|
| people (first_name + last_name) | people (name) | Simpler |
| relationships (person OR org) | introductions (person only) | Cleaner - org relationships tracked via deals |
| deal_participants | REMOVED | Use interests.contact_id instead |
| block_participants | REMOVED | Redundant - blocks belong to deals |
| meeting_attendees | attendee_ids array | Simpler |
| meeting_deals | deal_id on meetings | Simpler |
| document_links | polymorphic on documents | Rails convention |
| tagged_items | taggings (polymorphic) | Rails convention |

---

## ENUMS

```ruby
# In Rails
class ApplicationRecord < ActiveRecord::Base
  # Warmth (people & orgs)
  enum :warmth, { cold: 0, warm: 1, hot: 2, champion: 3 }

  # Org types
  enum :org_type, { fund: 0, company: 1, entity: 2, other: 3 }

  # Contact channels
  enum :channel, { email: 0, phone: 1, whatsapp: 2, linkedin: 3, twitter: 4 }

  # Deal types
  enum :deal_type, { spv: 0, direct: 1, lp_transfer: 2, tender: 3, primary: 4 }

  # Deal status
  enum :status, { sourcing: 0, active: 1, closing: 2, closed: 3, dead: 4 }

  # Priority
  enum :priority, { urgent: 0, high: 1, medium: 2, low: 3 }

  # Block status
  enum :block_status, { available: 0, reserved: 1, sold: 2, dead: 3 }

  # Interest status
  enum :interest_status, { interested: 0, committed: 1, wired: 2, passed: 3 }

  # Match status
  enum :match_status, { pending: 0, matched: 1, closed: 2, cancelled: 3 }

  # Share class
  enum :share_class, { common: 0, preferred: 1, mixed: 2 }

  # Doc types
  enum :doc_type, { deck: 0, terms: 1, legal: 2, memo: 3, cap_table: 4, other: 5 }
end
```

---

## KEY QUERIES THIS SUPPORTS

```ruby
# Find all hot leads at funds
Person.joins(:affiliations => :organization)
      .where(warmth: :hot, organizations: { org_type: :fund })

# Find deals with soft circles over $1M
Deal.joins(:interests).where("interests.amount > ?", 1_000_000)

# Find all documents for a deal
Document.where(documentable: deal)

# Find people tagged "priority"
Person.joins(:taggings => :tag).where(tags: { name: "priority" })

# Find available blocks for a company
company.deals.joins(:blocks).where(blocks: { status: :available })

# Meeting history with a person
Meeting.where("? = ANY(attendee_ids)", person.id).order(starts_at: :desc)
```

---

## INDEXES (auto-created by Rails + extras)

```ruby
# Foreign keys (Rails does these)
add_index :people, :owner_id
add_index :organizations, :sector_id
add_index :organizations, :owner_id
add_index :affiliations, [:person_id, :organization_id], unique: true
add_index :contacts, [:person_id, :channel, :value], unique: true
add_index :deals, :company_id
add_index :deals, :owner_id
add_index :blocks, :deal_id
add_index :interests, [:deal_id, :investor_id]
add_index :matches, [:interest_id, :block_id], unique: true

# Query performance
add_index :people, :warmth
add_index :organizations, :org_type
add_index :deals, :status
add_index :deals, :priority
add_index :blocks, :status
add_index :interests, :status
add_index :documents, [:documentable_type, :documentable_id]
add_index :taggings, [:taggable_type, :taggable_id]
add_index :meetings, :deal_id
add_index :meetings, :starts_at
```
