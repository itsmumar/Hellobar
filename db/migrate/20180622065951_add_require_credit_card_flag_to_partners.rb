class AddRequireCreditCardFlagToPartners < ActiveRecord::Migration
  def change
    add_column :partners, :require_credit_card, :boolean, default: false
  end
end
