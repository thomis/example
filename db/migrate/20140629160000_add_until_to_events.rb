class AddUntilToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :until, "timestamp with time zone"
  end
end
