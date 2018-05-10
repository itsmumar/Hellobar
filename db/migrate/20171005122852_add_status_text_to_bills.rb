class AddStatusTextToBills < ActiveRecord::Migration
  def up
    add_column :bills, :status_text, :string, default: Bill::STATE_PENDING, null: false

    Bill.where(status: 0).update_all status_text: Bill::STATE_PENDING
    Bill.where(status: 1).update_all status_text: Bill::STATE_PAID
    Bill.where(status: 2).update_all status_text: Bill::STATE_VOIDED
    Bill.where(status: 3).update_all status_text: Bill::STATE_FAILED
  end

  def down
    Bill.where(status_text: Bill::STATE_PENDING).update_all status: 0
    Bill.where(status_text: Bill::STATE_PAID).update_all status: 1
    Bill.where(status_text: Bill::STATE_VOIDED).update_all status: 2
    Bill.where(status_text: Bill::STATE_FAILED).update_all status: 3

    remove_column :bills, :status_text, :string, default: Bill::STATE_PENDING, null: false
  end
end
