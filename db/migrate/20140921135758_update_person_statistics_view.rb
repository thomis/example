class UpdatePersonStatisticsView < ActiveRecord::Migration[4.2]
  def change
    execute "drop view v_person_statistics;"
    execute %{
  		create or replace view v_person_statistics as
			select
			  i.person_id, p.last_name || ' ' || p.first_name person_full_name, s.id status_id, s.name status_name, ps.id person_status_id, ps.name person_status_name, count(*) n
			from
			  invitees i inner join statuses s
			  on i.status_id = s.id
			  inner join events e
			  on i.event_id = e.id
			  inner join people p
			  on i.person_id = p.id
			  inner join statuses ps
			  on p.status_id = ps.id
			where
			  e.status_id in (3,10)
			group by
			  i.person_id, p.last_name || ' ' || p.first_name, s.id, s.name, ps.id, ps.name;
  	}
  end
end
