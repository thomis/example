class AddGuestToInvitees < ActiveRecord::Migration[4.2]
  def change
    add_column :invitees, :guest, :integer
  end
end
