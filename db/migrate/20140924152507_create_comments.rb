class CreateComments < ActiveRecord::Migration[4.2]
  def change
    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"

    create_table "comments", force: true do |t|
      t.integer "type_id", null: false # can refere to events, people, blogs
      t.integer "reference_id", null: false

      t.integer "comment_id", null: true # if you comment a comment but can be null

      t.text "content"

      t.integer "creator_id", null: false
      t.integer "updator_id", null: false
      t.column "created_at", "timestamp with time zone", null: false
      t.column "updated_at", "timestamp with time zone", null: false
    end

    # type reference constraints
    execute "alter table comments add foreign key (type_id) references types(id)"
  end
end
