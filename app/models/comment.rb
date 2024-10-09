class Comment < ApplicationRecord
  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"
  belongs_to :event, class_name: "Event", foreign_key: "reference_id"

  attr_accessor :children

  validates :type_id, :reference_id, :content, :creator_id, :updator_id, presence: true

  def invitee
    Invitee.where(event_id: reference_id, person_id: creator_id).first
  end
end
