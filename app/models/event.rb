require "icalendar/tzinfo"

class Event < ApplicationRecord
  include ActionView::Helpers::DateHelper

  validates :name, :when, :until, :group_id, :status_id, :creator_id, :updator_id, presence: true
  validates :next_event, :required_people,
    numericality: {only_integer: true, greater_than: 0, allow_blank: true}
  validate :invitation_and_cancellation

  belongs_to :team
  belongs_to :group
  belongs_to :status

  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  has_many :invitees
  has_many :people, through: :invitees

  has_many :comments, foreign_key: "reference_id"

  scope :drafted, -> { where(status_id: STATUS_DRAFT) }
  scope :released, -> { where(status_id: STATUS_RELEASED) }
  scope :archived, -> { where(status_id: [STATUS_CANCELLED, STATUS_COMPLETED]) }

  scope :recent, -> { where([' "when" > ?', 1.day.ago]) }

  scope :sorted, -> { order(Arel.sql(' "when" asc, name, id desc')) }
  scope :reverse_sorted, -> { order(Arel.sql(' "when" desc, name, id desc')) }

  def send_invitation_at=(value)
    self[:send_invitation_at] = Time.zone.parse(value) if value.instance_of?(String)
    self[:send_invitation_at] = value if value.instance_of?(Time) || value.instance_of?(ActiveSupport::TimeWithZone)
  end

  def send_invitation_at
    self[:send_invitation_at]&.in_time_zone
  end

  def send_cancellation_at=(value)
    self[:send_cancellation_at] = Time.zone.parse(value) if value.instance_of?(String)
    self[:send_cancellation_at] = value if value.instance_of?(Time) || value.instance_of?(ActiveSupport::TimeWithZone)
  end

  def send_cancellation_at
    self[:send_cancellation_at]&.in_time_zone
  end

  def when=(value)
    self[:when] = Time.zone.parse(value) if value.instance_of?(String)
    self[:when] = value if value.instance_of?(Time) || value.instance_of?(ActiveSupport::TimeWithZone)
  end

  def when
    self[:when]&.in_time_zone
  end

  def until=(value)
    self[:until] = Time.zone.parse(value) if value.instance_of?(String)
    self[:until] = value if value.instance_of?(Time) || value.instance_of?(ActiveSupport::TimeWithZone)
  end

  def until
    self[:until]&.in_time_zone
  end

  def released?
    status_id == STATUS_RELEASED
  end

  def draft?
    status_id == STATUS_DRAFT
  end

  def cancelled?
    status_id == STATUS_CANCELLED
  end

  def completed?
    status_id == STATUS_COMPLETED
  end

  def invite
    invitees.each do |invitee|
      # no need to send email again or if person disabled
      next if invitee.invitation_sent.present? || invitee.status_id != STATUS_NO_RESPONSE || invitee.person.inactive?

      invitee.invite
    end

    # if some emails where not sent trigger it again
    if invitees.failed_delivery.size > 0
      AppLogger.info("Event [#{name}]: some invitations could not be delivered. we try again in 5 minutes")
      SendInvitation.enqueue(id, job_options: {run_at: Time.now + 5.minutes})
    end
  end

  def get_invitees(filter = "accepted")
    return invitees.send(filter.to_sym) if ["accepted", "tentative", "declined", "no_response"].include?(filter)
    invitees
  end

  def complete
    if status_id == STATUS_RELEASED
      self.status_id = STATUS_COMPLETED
      self.updator_id = 0

      if save!(validate: false)
        AppLogger.info("Event [#{name}] has been completed")
      else
        AppLogger.info("Event [#{name}] could not be set to status [#{Status.find(STATUS_COMPLETED).name}]")
      end
    else
      AppLogger.info("Event [#{name}] has status [#{status.name}]. Change to status [#{Status.find(STATUS_COMPLETED).name}] is not possible.")
    end
  end

  def cancel(force = true)
    if released?
      # catch none released once
      unless released?
        AppLogger.info("Event [#{name}] has status [#{status.name}]. Change to status [#{Status.find(STATUS_CANCELLED).name}] is not possible.")
        return
      end

      # was cancellation forced or min people condition not met
      AppLogger.info("Event [#{name}] forced=#{force}, required_people=#{required_people}, accepted+guest=#{invitees.accepted.size + guests}")

      if force || required_people > (invitees.accepted.size + guests)
        self.status_id = STATUS_CANCELLED
        self.updator_id = 0

        invitees.accepted_and_tentative.each do |invitee|
          invitee.cancel
        end

        if save!(validate: false)
          if force
            AppLogger.info("Event [#{name}] has been cancelled manually")
          else
            AppLogger.info("Event [#{name}] has been cancelled due to not enough people (#{required_people} required vs #{invitees.accepted.size} accepted)")
          end
        else
          # this is an update issue
          AppLogger.info("Event [#{name}] could not be set to status [#{Status.find(STATUS_CANCELLED).name}]")
        end
      else
        AppLogger.info("Looks like this event [#{name}] can take place")
      end
    end
  end

  def next
    if next_event.present?
      # skip holidays
      days_to_add = 0
      loop do
        days_to_add += next_event
        break unless Holiday.holiday?(self[:when] + days_to_add.days)
      end

      new_event = Event.new(attributes.symbolize_keys.merge(id: nil, when: self[:when] + days_to_add.days, until: self[:until] + days_to_add.days, status_id: STATUS_RELEASED, created_at: Time.now, updated_at: Time.now))
      new_event.send_invitation_at = self[:send_invitation_at] + days_to_add.days if self[:send_invitation_at].present?
      new_event.send_cancellation_at = self[:send_cancellation_at] + days_to_add.days if self[:send_cancellation_at].present?

      # add users from group
      new_event.group.people.active.each do |person|
        new_event.invitees.build({creator_id: 0, updator_id: 0, status_id: STATUS_NO_RESPONSE, person_id: person.id})
      end

      if new_event.save!
        AppLogger.info("New event [#{new_event.name}] has been created")

        SendInvitation.enqueue(new_event.id, job_options: {run_at: new_event.send_invitation_at}) if new_event.send_invitation_at.present?
        SendCancellation.enqueue(new_event.id, false, job_options: {run_at: new_event.send_cancellation_at}) if new_event.send_cancellation_at.present?
        SendComplete.enqueue(new_event.id, job_options: {run_at: new_event.until})
        SendNextEvent.enqueue(new_event.id, job_options: {run_at: new_event.until}) if new_event.next_event.present?

      else
        AppLogger.info("New event [#{new_event.name}] could not be created")
      end
    end
  end

  def guests(status = STATUS_ACCEPTED)
    invitees.where(status_id: status).sum(:guest)
  end

  def missing_people
    group.people.active.where.not(id: people.ids)
  end

  def removed_people
    people.where.not(id: group.people.active.ids)
  end

  def is_disabled?(column)
    return true if cancelled? || completed?
    return true if released? && [:group_id, :when, :until, :send_invitation_at, :required_people, :send_cancellation_at, :next_event, :allow_tentative_selection].include?(column)
    false
  end

  def delete_jobs
    jobs = []
    Job.all.each do |job|
      jobs << job if job.args.is_a?(Array) && job.args.include?(id)
    end
    jobs.each do |job|
      job.destroy
    end
  end

  def get_ical(path)
    tzid = "Europe/Zurich"
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new self.when, "tzid" => tzid
      e.dtend = Icalendar::Values::DateTime.new self.until, "tzid" => tzid
      e.summary = self[:name]
      e.description = path
      e.location = self[:location]
    end
    cal.to_ical
  end

  private

  def invitation_and_cancellation
    # start should be before end of event
    if self[:when].present? && self[:until].present? && self[:when] > self[:until]
      errors.add(:when, "should be before 'until'")
    end

    # give at least 5 minutes before event take place without invitation
    if self[:when].present? && ((self[:when] - Time.now) < 5.minutes)
      errors.add(:when, "should give at least 5 minutes before event takes place")
    elsif self[:when].present? && self[:send_invitation_at].present? && ((self[:when] - self[:send_invitation_at]) < TIME_INVITATION_TO_EVENT.minutes)
      # give 60 minutes before event takes place with invitation
      left = (self[:when] - self[:send_invitation_at]).to_i / 60
      errors.add(:when, "should give at least #{TIME_INVITATION_TO_EVENT} minutes before sending invitations, but there #{"is".pluralize(left)} only #{left} #{"minute".pluralize(left)} left")
    end

    # need both values to send cancellation
    if self[:send_cancellation_at].present? && self[:required_people].blank?
      errors.add(:required_people, "must be defined to use automatic cancellation")
    end

    # sending cancellation only makes sence when sending invitations
    if self[:send_cancellation_at].present? && self[:send_invitation_at].blank?
      errors.add(:send_invitation_at, "must be present when cancellation is defined")
    end

    # give 30 minutes to send cancellation
    if self[:when].present? && self[:send_cancellation_at].present? && ((self[:when] - self[:send_cancellation_at]) < TIME_CANCEL_TO_EVENT.minutes)
      left = (self[:when] - self[:send_cancellation_at]).to_i / 60
      errors.add(:send_cancellation_at, "should be defined at least #{TIME_CANCEL_TO_EVENT} minutes before event, but there #{"is".pluralize(left.abs)} only #{left} #{"minute".pluralize(left)} left")
    end

    # send_invitation must be in the future
    if self[:send_invitation_at].present? && draft? && self[:when].present? && (self[:send_invitation_at] < Time.now)
      errors.add(:send_invitation_at,
        "must be defined in the future")
    end

    # give min 30 min between invitation and cancellation
    if self[:send_cancellation_at].present? && self[:send_invitation_at].present? && (self[:send_cancellation_at] - self[:send_invitation_at]) < TIME_INVITATION_TO_CANCEL.minutes
      difference = (self[:send_cancellation_at] - self[:send_invitation_at]).to_i / 60
      errors.add(:send_invitation_at, "should be minimum #{TIME_INVITATION_TO_CANCEL} minutes before cancellation, but there #{"is".pluralize(difference)} only #{difference} #{"minute".pluralize(difference)} left")
    end

    # required person should not be bigger that number of people from group
    if self[:required_people].present? && self[:required_people] > Group.find(group_id).people.size
      errors.add(:required_people, "should not be bigger than #{Group.find(group_id).people.size} (number of people in group \"#{group.name}\")")
    end
  end
end
