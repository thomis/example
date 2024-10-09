class Member < ApplicationRecord
  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :group
  belongs_to :person
end
