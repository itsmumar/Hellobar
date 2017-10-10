class AddStatusTextToBills < ActiveRecord::Migration
  def up
    add_column :bills, :status_text, :string, default: Bill::PENDING, null: false

    Bill.where(status: 0).update_all status_text: Bill::PENDING
    Bill.where(status: 1).update_all status_text: Bill::PAID
    Bill.where(status: 2).update_all status_text: Bill::VOIDED
    Bill.where(status: 3).update_all status_text: Bill::FAILED
  end

  def down
    Bill.where(status_text: Bill::PENDING).update_all status: 0
    Bill.where(status_text: Bill::PAID).update_all status: 1
    Bill.where(status_text: Bill::VOIDED).update_all status: 2
    Bill.where(status_text: Bill::FAILED).update_all status: 3

    remove_column :bills, :status_text, :string, default: Bill::PENDING, null: false
  end
end
