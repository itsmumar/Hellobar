class ChangeBarsMessageLength < ActiveRecord::Migration
  def change
    change_column :bars, :message, :string, default: 'Hello. Add your message here.', limit: 5_000
    change_column :bars, :link_text, :string, default: 'Click Here', limit: 5_000
  end
end
