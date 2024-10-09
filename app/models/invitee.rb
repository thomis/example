class Invitee < ApplicationRecord
  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"
  belongs_to :event
  belongs_to :person
  belongs_to :status

  scope :accepted, -> { where(status_id: STATUS_ACCEPTED) }
  scope :tentative, -> { where(status_id: STATUS_TENTATIVE) }
  scope :declined, -> { where(status_id: STATUS_DECLINED) }
  scope :no_response, -> { where(status_id: STATUS_NO_RESPONSE) }
  scope :accepted_and_tentative, -> { where(status_id: [STATUS_ACCEPTED, STATUS_TENTATIVE]) }
  scope :failed_delivery, -> { where("invitation_sent is null and invitation_sent_retry <= 2 and status_id = #{STATUS_NO_RESPONSE}") }

  def comments?
    Comment.where(reference_id: event_id, creator_id: person_id).count > 0
  end

  def invite
    generate_token(:invitation_key)
    self.updator_id = 0
    save!
    begin
      PersonMailer.invite(self).deliver
      self.invitation_sent = Time.now
    rescue => e
      self.invitation_sent = nil
      self.invitation_sent_error = e.to_s
      self.invitation_sent_retry = invitation_sent_retry.nil? ? 1 : invitation_sent_retry + 1
    end
    self.updator_id = 0
    save!
  end

  def cancel
    PersonMailer.cancel(self).deliver
  rescue => e
    AppLogger.info("Unable to deliver cancellation email to #{person.email} due to #{e}.")
  end

  def generate_token(column)
    loop do
      self[column] = SecureRandom.urlsafe_base64
      break unless Invitee.exists?(column => self[column])
    end
  end

  def self.find_via_key(key)
    invitee = Invitee.where(invitation_key: key).first

    # is person disabled?
    if invitee.blank? || invitee.person.status_id == STATUS_INACTIVE
      raise ActiveRecord::RecordNotFound
    end

    invitee
  end

  def self.never_invited
    data = []
    Invitee.connection.select_all("select id from people p where id <> 0 and status_id = 4 and id not in (select person_id from invitees where person_id = p.id) order by last_name, first_name").rows.each do |row|
      data << [Person.find(row[0]).full_name, 0, row[0]]
    end
    data
  end
end
