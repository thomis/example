class Team < ApplicationRecord
  validates :name, :type_id, presence: true
  validates :name, uniqueness: true

  belongs_to :type

  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  def self.statistics
    data = {}
    Team.connection.select_all("select team_name, status_name, n from v_team_statistics").rows.each do |row|
      item = data[row[0]]
      unless item
        item = { name: row[0], completed: 0, cancelled: 0, total: 0, rate: 0 }
        data[item[:name]] = item
      end
      item[row[1].downcase.to_sym] += row[2].to_i
      item[:total] += row[2].to_i
      item[:rate] = item[:completed].to_f / item[:total].to_f * 100.0
    end
    data
  end

  def top_acceptors
    data = []
    Team.connection.select_all("select person_full_name, n, person_id from v_person_statistics where team_id = #{id} and status_id = 6 and person_status_id = 4 order by n desc limit 5").rows.each do |row|
      data << [ row[0], row[1].to_i, row[2] ]
    end
    data
  end

  def top_decliners
    data = []
    Team.connection.select_all("select person_full_name, n, person_id from v_person_statistics where team_id = #{id} and status_id = 8 and person_status_id = 4 order by n desc limit 5").rows.each do |row|
      data << [ row[0], row[1].to_i, row[2] ]
    end
    data
  end

  def top_responders
    data = []
    Team.connection.select_all("select person_full_name, sum(n), person_id from v_person_statistics where team_id = #{id} and status_id in(6,7,8) and person_status_id = 4 group by person_id, person_full_name order by sum(n) desc  limit 5").rows.each do |row|
      data << [ row[0], row[1].to_i, row[2] ]
    end
    data
  end

  def not_anymore_responders(days = 90)
    data = []
    Team.connection.select_all("select person_full_name, last_response_at, person_id from v_person_statistics_last_response where team_id = #{id} and last_response_at < (NOW() - interval '#{days} days') order by last_response_at desc").rows.each do |row|
      data << [ row[0], enforce_time(row[1]), row[2] ]
    end
    data
  end

  def none_responders
    data = []
    Team.connection.select_all("select person_full_name, sum(n), person_id from v_person_statistics where team_id = #{id} and status_id = 9 and person_id not in (select person_id from v_person_statistics where status_id in (6,7,8)) and person_status_id = 4 group by person_id, person_full_name order by sum(n) desc, person_full_name").rows.each do |row|
      data << [ row[0], row[1].to_i, row[2] ]
    end
    data
  end

  private

  def enforce_time(value)
    return value if value.is_a?(Time)
    Time.parse(value)
  end
end
