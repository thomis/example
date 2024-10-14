require_relative "seeds_helper"

puts "=========== Seeding [#{Rails.env}]..."

# drop FK to status to insert system person
begin
  ActiveRecord::Base.connection.execute("alter table people drop constraint people_status_id_fkey")
rescue ActiveRecord::StatementInvalid
  puts " => Foreign key constraint on people does not exist"
end

# need to create this person first to be able to create all other entries
Person.create_or_update(
  {
    id: USER_SYSTEM, first_name: "Soccer", last_name: "System",
    nick_name: "Soccer System", email: "soccer@ikey.ch",
    roles: "administrator,user", status_id: STATUS_PERSON_ACTIVE,
    creator_id: USER_SYSTEM, updator_id: USER_SYSTEM,
    auth_token: "LtGC_fV_f5CTpi7UV5Vp8A",
    password_digest: "$2a$12$dhsILOcdhbb86QIUEV6/xeicBo0imQ8YMcYTQwNIYM2eMIIOT5UJm"
  }, false)

# Types
Type.create_or_update(id: TYPE_STATUS_EVENT, name: "Status Event", type_type: "Statuses", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Type.create_or_update(id: TYPE_STATUS_PERSON, name: "Status Person", type_type: "Statuses", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Type.create_or_update(id: TYPE_STATUS_INVITATION, name: "Status Invitation", type_type: "Statuses", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

Type.create_or_update(id: TYPE_COMMENT_EVENT, name: "Event", type_type: "Comment", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

Type.create_or_update(id: TYPE_TEAM_DEFAULT, name: "Default", type_type: "Team", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

# Event Statuses
Status.create_or_update(id: STATUS_EVENT_DRAFT, name: "Draft", type_id: TYPE_STATUS_EVENT, note: "Event is being defined", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_EVENT_RELEASED, name: "Released", type_id: TYPE_STATUS_EVENT, note: "Event has been released", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_EVENT_COMPLETED, name: "Completed", type_id: TYPE_STATUS_EVENT, note: "Event has been completed", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_EVENT_CANCELLED, name: "Cancelled", type_id: TYPE_STATUS_EVENT, note: "Event has been cancelled", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

# Person Statuses
Status.create_or_update(id: STATUS_PERSON_ACTIVE, name: "Active", type_id: TYPE_STATUS_PERSON, note: "Person is active", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_PERSON_INACTIVE, name: "Inactive", type_id: TYPE_STATUS_PERSON, note: "Person is inactive", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

# Invitation Statuses
Status.create_or_update(id: STATUS_INVITATION_ACCEPTED, name: "Accepted", type_id: TYPE_STATUS_INVITATION, note: "Sure I can join", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_INVITATION_TENTATIVE, name: "Tentative", type_id: TYPE_STATUS_INVITATION, note: "Don't know yet", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_INVITATION_DECLINED, name: "Declined", type_id: TYPE_STATUS_INVITATION, note: "Sorry, can't make it", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)
Status.create_or_update(id: STATUS_INVITATION_NO_RESPONSE, name: "No Response", type_id: TYPE_STATUS_INVITATION, note: "No response was given yet", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

# re-create people FK to status
ActiveRecord::Base.connection.execute("alter table people add foreign key (status_id) references statuses(id)")

Group.create_or_update(id: 0, name: "All", note: "Default Group with all people", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

# person = nil
# File.open(File.expand_path(File.dirname(__FILE__))+'/people.txt') do |input|
# 	input.each_line do |line|
# 		line.strip!
# 		next if line.size == 0 || line =~ /first_name/i
# 		a = line.split(',')
# 		roles = ['user']
# 		roles = ['administrator','user'] if ['Steiner'].include?(a[1])
# 		puts a.join(", ")

# 		if a[4]
# 			person = Person.create_or_update(first_name: a[0], last_name: a[1], nick_name: a[2], email: a[3], roles: roles.join(','), status_id: STATUS_PERSON_ACTIVE, creator_id: USER_SYSTEM, updator_id: USER_SYSTEM, password_digest: a[4], auth_token: a[5])
# 		else
# 			person = Person.create_or_update(first_name: a[0], last_name: a[1], nick_name: a[2], email: a[3], roles: roles.join(','), status_id: STATUS_PERSON_ACTIVE, creator_id: USER_SYSTEM, updator_id: USER_SYSTEM, password: a[3]+'14!', password_confirmation: a[3]+'14!', auth_token: a[5])
# 		end

# 		Member.create_or_update(group_id: GROUP_ALL, person_id: person.id, creator_id: USER_SYSTEM)

# 	end
# end

Team.create_or_update(id: 1, name: "Example Team", type_id: TYPE_TEAM_DEFAULT, note: "Example Team", creator_id: USER_SYSTEM, updator_id: USER_SYSTEM)

[ "types", "statuses", "people", "members", "groups", "invitees", "events", "holidays", "comments", "teams" ].each do |table|
  result = ActiveRecord::Base.connection.exec_query("select max(id) n from #{table}")
  result.each do |row|
    n = row["n"].to_i
    n += 1
    result = ActiveRecord::Base.connection.execute("alter sequence #{table}_id_seq restart with #{n}")
    puts "Table #{table} => sequence restarted with #{n}"
  end
end
