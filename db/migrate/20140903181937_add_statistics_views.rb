class AddStatisticsViews < ActiveRecord::Migration[4.2]
  def up
    execute %{
      create or replace view v_event_statistics as
      select
        e.name event_name, s.name status_name, count(*) n
      from
        events e inner join statuses s
        on e.status_id = s.id
      where
        e.status_id in (3,10)
      group by e.name, s.name;
    }

    execute %{
      create or replace view v_person_statistics as
      select
        i.person_id, p.last_name || ' ' || p.first_name person_full_name, s.id status_id, s.name status_name, count(*) n
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
        i.person_id, p.last_name || ' ' || p.first_name, s.id, s.name;
    }
  end

  def down
    execute "drop view v_event_statistics;"
    execute "drop view v_person_statistics;"
  end
end
