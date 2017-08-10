class MakeTokenNullAttributeInCreditCards < ActiveRecord::Migration
  def up
    change_column_null :credit_cards, :token, true
  end

  def down
    change_column_null :credit_cards, :token, false
  end
end
