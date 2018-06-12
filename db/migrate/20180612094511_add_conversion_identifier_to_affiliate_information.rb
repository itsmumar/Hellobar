class AddConversionIdentifierToAffiliateInformation < ActiveRecord::Migration
  def change
    add_column :affiliate_information, :conversion_identifier, :string, after: :affiliate_identifier
  end
end
