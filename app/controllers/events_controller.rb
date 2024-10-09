class EventsController < ApplicationController
  # before_action :authorize
  # authorize_resource :class => false
  before_action :set_event, only: [:show, :edit, :update, :destroy, :release, :cancel, :change_person_status, :resync_invitees, :send_invitations, :email]
  before_action :validate_and_set_filter, only: [:show]

  def index
    # if current_person.administrator?
      @events = Event.drafted.sorted
      @events += Event.released.sorted
      @events += Event.archived.recent.reverse_sorted
    # else
      # @events = Event.released.recent.sorted
    # end
  end

  def show
    @invitees = @event.get_invitees(params[:filter] || "accepted")

    # build helper strcuture to show comments in useful sequence
    @comments = {}
    @event.comments.order("id").each do |comment|
      if comment.comment_id.nil?
        comment.children = []
        @comments[comment.id] = comment
      elsif @comments[comment.comment_id]
        @comments[comment.comment_id].children << comment
      end
    end
  end

  def new
    # initial when is next full hour + plus one hour
    w = Time.at(Time.now.to_i / 3600 * 3600 + 7200)
    @event = Event.new(when: w, until: w + 1.hour, allow_tentative_selection: false)
  end

  def edit
  end

  def create
    @event = Event.new(event_params)
    @event.creator_id = @event.updator_id = current_person.id
    @event.status_id = 1

    @event.group.people.active.each do |person|
      @event.invitees.build({creator_id: 0, updator_id: 0, status_id: STATUS_NO_RESPONSE, person_id: person.id})
    end

    if @event.save
      msg = "Event [#{@event.name}] was successfully created"
      AppLogger.info("#{msg} by [#{current_person.full_name}]")
      redirect_to events_url, notice: "#{msg}."
    else
      render action: "new"
    end
  end

  def update
    # need to adapt the invitees list?
    if event_params[:group_id].present? && @event.group_id != event_params[:group_id]
      # remove all invitees previously assigned
      @event.invitees.destroy_all

      # # add persons from new group
      Group.find(event_params[:group_id]).people.active.each do |person|
        @event.invitees.create({creator_id: 0, updator_id: 0, status_id: STATUS_NO_RESPONSE, person_id: person.id})
      end
    end

    @event.updator_id = current_person.id

    if @event.update(event_params)
      msg = "Event [#{@event.name}] was successfully updated"
      AppLogger.info("#{msg} by [#{current_person.full_name}]")
      redirect_to (params["return_to"] == "index") ? events_path : event_path(@event), notice: "#{msg}."
    else
      render action: "edit"
    end
  end

  def destroy
    @event.destroy
    name = @event.name
    msg = "Event [#{name}] was successfully deleted"
    AppLogger.info("#{msg} by [#{current_person.full_name}]")
    redirect_to events_url, notice: "#{msg}."
  end

  def email
    @invitees = @event.get_invitees(params[:filter] || "accepted")
    send_data @invitees.map { |invitee| invitee.person.email }.join("\n"), filename: "#{@event.name}_#{params[:filter] || "accepted"}.csv"
  end

  def change_person_status
    if @event.cancelled? || @event.completed?
      msg = "Event has been \"#{@event.status.name}\" and no further changes are allowed"
      redirect_to event_url(@event, filter: params[:filter]), notice: "#{msg}."
      return
    end

    invitee = @event.invitees.find_by_person_id(params[:person_id])

    if params[:status_id] == "9"
      invitee.invitation_sent = nil
      invitee.invitation_sent_error = nil
      invitee.invitation_sent_retry = nil
    end

    msg = if invitee.update(status_id: params[:status_id], updator_id: current_person.id)
      "Person [#{invitee.person.full_name}] has been set to status [#{invitee.status.name}] for event [#{@event.name}]"
    else
      "New status could not be set for person [#{invitee.person.full_name}]"
    end

    AppLogger.info("#{msg} by [#{current_person.full_name}]")
    redirect_to event_url(@event, filter: params[:filter]), notice: "#{msg}."
  end

  def release
    ActiveRecord::Base.transaction do
      if @event.draft?
        @event.status_id = STATUS_RELEASED
        @event.updator_id = current_person.id

        if @event.save
          msg = "Event [#{@event.name}] was successfully released"

          SendInvitation.enqueue(@event.id, job_options: {run_at: @event.send_invitation_at}) if @event.send_invitation_at.present?
          SendCancellation.enqueue(@event.id, false, job_options: {run_at: @event.send_cancellation_at}) if @event.send_cancellation_at.present?
          SendComplete.enqueue(@event.id, job_options: {run_at: @event.until})
          SendNextEvent.enqueue(@event.id, job_options: {run_at: @event.until}) if @event.next_event.present?

        else
          msg = "Event [#{@event.name}] could not be released: #{@event.errors.full_messages.join(", ")}"
        end
      else
        msg = "Event [#{@event.name}] is not in draft status"
      end
      AppLogger.info("#{msg} by [#{current_person.full_name}]")
      redirect_to (params["return_to"] == "index") ? events_path : event_path(@event), notice: "#{msg}."
    end
  end

  def cancel
    ActiveRecord::Base.transaction do
      @event.delete_jobs
      SendCancellation.enqueue(@event.id, true, job_options: {priority: 80})
    end

    msg = "Event [#{@event.name}] cancel request has been enqueued"
    AppLogger.info("#{msg} by [#{current_person.full_name}]")
    redirect_to (params["return_to"] == "index") ? events_path : event_path(@event), notice: "#{msg}."
  end

  def resync_invitees
    to_add = @event.missing_people.size
    to_remove = @event.removed_people.size

    # adding missing people
    @event.missing_people.each do |person|
      @event.invitees.create({creator_id: 0, updator_id: 0, status_id: STATUS_NO_RESPONSE, person_id: person.id})
    end

    # removing removed people
    @event.removed_people.each do |person|
      @event.invitees.find_by_person_id(person.id).destroy
    end

    msg = if @event.save
      "The following change have been made to event [#{@event.name}]: People added [#{to_add}], removed [#{to_remove}]"
    else
      "Invitees list could not be updated for event [#{@event.name}]"
    end
    AppLogger.info("#{msg} by [#{current_person.full_name}]")

    redirect_to event_url(@event), notice: "#{msg}."
  end

  def send_invitations
    msg = nil
    ActiveRecord::Base.transaction do
      SendInvitation.enqueue(@event.id)

      msg = "Sending missing invitations has been initiated"
      AppLogger.info("#{msg} by [#{current_person.full_name}]")
    end

    redirect_to event_url(@event), notice: "#{msg}."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    if @event.present? && @event.released?
      params.require(:event).permit(:name, :content, :location)
    else
      params.require(:event).permit(:name, :content, :location, :when, :until, :team_id, :group_id, :status_id, :required_people, :send_invitation_at, :send_cancellation_at, :next_event, :allow_tentative_selection)
    end
  end

  def validate_and_set_filter
    valid_filters = [nil, "declined", "no_response", "all", "comments"]
    valid_filters << "tentative" if @event.allow_tentative_selection

    unless valid_filters.include?(params[:filter])
      params.delete(:filter)
    end
  end
end
