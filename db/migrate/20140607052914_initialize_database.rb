class InitializeDatabase < ActiveRecord::Migration[4.2]
  def change
    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"

    create_table "events", force: true do |t|
      t.string "name", null: false, limit: 512
      t.text "content"
      t.string "location"
      t.integer "group_id", null: false
      t.column "when", "timestamp with time zone", null: false

      t.column "send_invitation_at", "timestamp with time zone"
      t.integer "required_people"
      t.column "send_cancellation_at", "timestamp with time zone"
      t.integer "next_event"

      t.integer "status_id", null: false

      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    create_table "statuses", force: true do |t|
      t.integer "type_id", null: false
      t.string "name", null: false
      t.text "note"
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :statuses, [ :type_id, :name ], unique: true

    create_table "types", force: true do |t|
      t.string "type_type", null: false
      t.string "name", null: false
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :types, [ :type_type, :name ], unique: true

    create_table :people, force: true do |t|
      t.string "first_name", null: false
      t.string "last_name", null: false
      t.string "nick_name", null: false
      t.string "email", limit: 512
      t.string "auth_token", null: false
      t.string "password_digest", limit: 512
      t.string "password_reset_token"
      t.column "password_reset_sent_at", "timestamp with time zone"
      t.string "roles", limit: 512
      t.integer "status_id", null: false
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :people, [ :email ], unique: true
    add_index :people, [ :nick_name ], unique: true

    create_table :groups, force: true do |t|
      t.string "name", limit: 512, null: false
      t.text "note"
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :groups, [ :name ], unique: true

    create_table :members, force: true do |t|
      t.integer "person_id", null: false
      t.integer "group_id", null: false
      t.integer "creator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
    end

    add_index :members, [ :person_id, :group_id ], unique: true

    execute "alter table members add foreign key (person_id) references people(id) on delete cascade"
    execute "alter table members add foreign key (group_id) references groups(id) on delete cascade"
    execute "alter table members add foreign key (creator_id) references people(id) on delete cascade"

    create_table :invitees, force: true do |t|
      t.integer "person_id", null: false
      t.integer "event_id", null: false
      t.integer "status_id", null: false
      t.string "invitation_key", limit: 512
      t.column "invitation_sent", "timestamp with time zone"
      t.string "invitation_sent_error", limit: 1024
      t.integer "invitation_sent_retry"
      t.column "last_response_at", "timestamp with time zone"
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :invitees, [ :invitation_key ], unique: true
    add_index :invitees, [ :person_id, :event_id ], unique: true

    execute "alter table invitees add foreign key (person_id) references people(id) on delete cascade"
    execute "alter table invitees add foreign key (event_id) references events(id) on delete cascade"
    execute "alter table invitees add foreign key (creator_id) references people(id) on delete cascade"
    execute "alter table invitees add foreign key (updator_id) references people(id) on delete cascade"

    create_table "holidays", force: true do |t|
      t.string "name", limit: 512, null: false
      t.date "from", null: false
      t.date "to", null: false
      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    add_index :holidays, [ :name ], unique: true
    add_index :holidays, [ :from ], unique: false
  end
end
