class OptionalTentativeSelection < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :allow_tentative_selection, :boolean, default: false, null: false
  end
end
