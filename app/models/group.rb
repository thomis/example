class Group < ApplicationRecord
  validates :name, presence: true
  validates :name, uniqueness: true

  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  has_many :members
  has_many :people, through: :members
  has_many :events

  accepts_nested_attributes_for :members, allow_destroy: true

  def has_error?(attribute)
    " has-error" if errors.include?(attribute)
  end

  def people_ids
    people.map { |person| person.id }
  end

  def create_members_attributes(members, creator_id = 0)
    actual_person_ids = Set.new(people.map { |person| person.id.to_s })
    new_person_ids = Set.new(members)
    new_person_ids.delete("")

    # add the missing once
    attributes = []
    attributes += (new_person_ids - actual_person_ids).to_a.map { |id| { person_id: id, creator_id: creator_id } }
    # add the once to delete
    attributes += (actual_person_ids - new_person_ids).to_a.map { |id| { id: self.members.where(person_id: id).first.id, _destroy: true } }

    attributes
  end

  def self.create_members_attributes(members, creator_id = 0)
    attributes = []
    members.each do |m|
      next if m.blank?
      attributes << { person_id: m, creator_id: creator_id }
    end
    attributes
  end
end
