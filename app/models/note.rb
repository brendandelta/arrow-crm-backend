class Note < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true
  validates :author_id, presence: true

  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where(pinned: false) }
  scope :private_notes, -> { where(is_private: true) }
  scope :public_notes, -> { where(is_private: false) }
  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :notes_only, -> { where(kind: "note") }
  scope :calls, -> { where(kind: "call") }
  scope :emails, -> { where(kind: "email") }
  scope :meetings, -> { where(kind: "meeting") }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_activity, -> { where.not(activity_at: nil) }

  def note? = kind == "note"
  def call? = kind == "call"
  def email? = kind == "email"
  def meeting? = kind == "meeting"

  def mentioned_users
    return [] if mentioned_user_ids.blank?
    User.where(id: mentioned_user_ids)
  end

  def mentioned_deals
    return [] if mentioned_deal_ids.blank?
    Deal.where(id: mentioned_deal_ids)
  end

  def mentioned_organizations
    return [] if mentioned_org_ids.blank?
    Organization.where(id: mentioned_org_ids)
  end

  def mentioned_people
    return [] if mentioned_person_ids.blank?
    Person.where(id: mentioned_person_ids)
  end

  def has_mentions?
    mentioned_user_ids.present? ||
      mentioned_deal_ids.present? ||
      mentioned_org_ids.present? ||
      mentioned_person_ids.present?
  end

  def truncated_body(length = 100)
    return body if body.length <= length
    "#{body[0...length]}..."
  end
end
