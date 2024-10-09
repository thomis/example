class AddForeignKeyConstraints < ActiveRecord::Migration[4.2]
  def change
    # group reference constaints
    execute "alter table events add foreign key (group_id) references groups(id)"

    # type reference constraints
    execute "alter table statuses add foreign key (type_id) references types(id)"

    # status reference constaints
    execute "alter table events add foreign key (status_id) references statuses(id)"
    execute "alter table people add foreign key (status_id) references statuses(id)"
    execute "alter table invitees add foreign key (status_id) references statuses(id)"

    # creator and updator reference constraints for all tables
    execute "alter table events add foreign key (creator_id) references people(id)"
    execute "alter table events add foreign key (updator_id) references people(id)"

    execute "alter table groups add foreign key (creator_id) references people(id)"
    execute "alter table groups add foreign key (updator_id) references people(id)"

    execute "alter table holidays add foreign key (creator_id) references people(id)"
    execute "alter table holidays add foreign key (updator_id) references people(id)"

    execute "alter table invitees add foreign key (creator_id) references people(id)"
    execute "alter table invitees add foreign key (updator_id) references people(id)"

    execute "alter table members add foreign key (creator_id) references people(id)"

    execute "alter table people add foreign key (creator_id) references people(id)"
    execute "alter table people add foreign key (updator_id) references people(id)"

    execute "alter table statuses add foreign key (creator_id) references people(id)"
    execute "alter table statuses add foreign key (updator_id) references people(id)"

    execute "alter table types add foreign key (creator_id) references people(id)"
    execute "alter table types add foreign key (updator_id) references people(id)"
  end
end
