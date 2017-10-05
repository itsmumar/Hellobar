class AddStatusTextToBills < ActiveRecord::Migration
  def up
    add_column :bills, :status_text, :string, default: 'pending', null: false

    Bill.where(status: 0).update_all status_text: 'pending'
    Bill.where(status: 1).update_all status_text: 'paid'
    Bill.where(status: 2).update_all status_text: 'void'
    Bill.where(status: 3).update_all status_text: 'failed'
  end

  def down
    Bill.where(status_text: 'pending').update_all status: 0
    Bill.where(status_text: 'paid').update_all status: 1
    Bill.where(status_text: 'void').update_all status: 2
    Bill.where(status_text: 'failed').update_all status: 3

    remove_column :bills, :status_text, :string, default: 'pending', null: false
  end
end
