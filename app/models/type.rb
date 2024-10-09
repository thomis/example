class Type < ApplicationRecord
  normalizes :name, with: ->(name) { name.strip.upcase }
  normalizes :type_type, with: ->(type_type) { type_type.strip.upcase }

  validates :name, :type_type, presence: true
  validates :name, uniqueness: {scope: :type_type}

  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  def has_error?(attribute)
    " has-error" if errors.include?(attribute)
  end

  def self.get_by_type_type(type_type)
    all.collect { |t| [t.name, t.id] if t.type_type == type_type }.compact
  end
end
