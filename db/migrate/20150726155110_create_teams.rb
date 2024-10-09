class CreateTeams < ActiveRecord::Migration[4.2]
  def change
    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"

    create_table :teams do |t|
      t.string "name", limit: 512, null: false
      t.integer "type_id", null: false
      t.text "note"
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :teams, [:name], unique: true
    execute "alter table teams add foreign key (type_id) references types(id)"
    execute "alter table teams add foreign key (creator_id) references people(id)"
    execute "alter table teams add foreign key (updator_id) references people(id)"

    # Add team to events table
    add_column :events, :team_id, :integer, null: false, defaut: 1
    execute "alter table events add foreign key (team_id) references teams(id)"
    execute "alter sequence teams_id_seq restart  with 100"
  end
end
