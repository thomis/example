class SpiderTracking < ActiveRecord::Migration[7.0]
  def change
    create_table "spider_tracking", force: true do |t|
      t.string "ip", limit: 128, null: true
      t.string "person", limit: 512, null: true
      t.text "url", null: true
      t.text "agent", null: true
      t.column "created_at", "timestamp with time zone", null: false, default: -> { "now()" }
    end
  end
end
