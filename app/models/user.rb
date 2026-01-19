class User < ApplicationRecord
  has_many :owned_people, class_name: "Person", foreign_key: :owner_id, dependent: :nullify
  has_many :owned_organizations, class_name: "Organization", foreign_key: :owner_id, dependent: :nullify
  has_many :owned_deals, class_name: "Deal", foreign_key: :owner_id, dependent: :nullify
  has_many :owned_interests, class_name: "Interest", foreign_key: :owner_id, dependent: :nullify
  has_many :meetings, foreign_key: :owner_id, dependent: :nullify
  has_many :notes, foreign_key: :author_id, dependent: :nullify
  has_many :documents, foreign_key: :uploaded_by_id, dependent: :nullify

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  scope :active, -> { where(is_active: true) }

  def full_name
    "#{first_name} #{last_name}"
  end
end
