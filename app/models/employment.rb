class Employment < ApplicationRecord
  belongs_to :person
  belongs_to :organization

  validates :person_id, presence: true
  validates :organization_id, presence: true

  scope :current, -> { where(is_current: true) }
  scope :primary, -> { where(is_primary: true) }
  scope :with_title, ->(title) { where(title: title) }

  def display_title
    [title, department].compact.join(", ")
  end

  def date_range
    return "#{started_at.year} - Present" if is_current && started_at
    return started_at.year.to_s if started_at && ended_at.nil?
    return nil if started_at.nil?
    "#{started_at.year} - #{ended_at.year}"
  end
end
