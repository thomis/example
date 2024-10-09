class NewStatisticViews < ActiveRecord::Migration[4.2]
  def change
    # drop old views
    execute "drop view v_event_statistics;" if view_exist?("v_event_statistics")
    execute "drop view v_team_statistics;" if view_exist?("v_team_statistics")

    execute %{
      create or replace view v_team_statistics as
      select
        t.id team_id, t.name team_name, to_char(e.when,'YYYY'), s.name status_name, count(*) n
      from
        teams t inner join events e
        on t.id = e.team_id
        inner join statuses s
        on e.status_id = s.id
      where
        e.status_id in (3,10)
      group by t.id, t.name, to_char(e.when,'YYYY'), s.name;
    }

    # drop old views
    execute "drop view v_person_statistics;"

    execute %{
      create or replace view v_person_statistics as
      select
        e.team_id,
        i.person_id,
        p.last_name || ' ' || p.first_name person_full_name,
        s.id status_id, s.name status_name,
        p.status_id person_status_id,
        count(*) n,
        max(i.updated_at) last_response_at
      from
        invitees i inner join statuses s
        on i.status_id = s.id
        inner join events e
        on i.event_id = e.id
        inner join people p
        on i.person_id = p.id
      where
        e.status_id in (3,10)
      group by
        e.team_id, i.person_id, p.last_name || ' ' || p.first_name, s.id, s.name, p.status_id;
    }

    execute %{
      create or replace view v_person_statistics_last_response as
      select
        team_id, person_full_name, person_id, max(last_response_at) last_response_at
      from
        v_person_statistics
      where
        status_id in (6,7,8)
        and person_status_id = 4
      group by team_id, person_full_name, person_id
    }
  end
end

def view_exist?(name)
  response = ActiveRecord::Base.connection.select_all("select count(*) from pg_views where viewname = '#{name}'")[0]
  response["count"] == "1"
end
