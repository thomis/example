class Status < ApplicationRecord
  normalizes :name, with: ->(name) { name.strip.upcase }

  validates :name, :type_id, presence: true
  validates :name, uniqueness: { scope: :type }

  belongs_to :type

  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  def has_error?(attribute)
    " has-error" if errors.include?(attribute)
  end
end
