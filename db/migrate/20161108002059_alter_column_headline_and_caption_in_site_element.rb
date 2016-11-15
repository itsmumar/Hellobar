class AlterColumnHeadlineAndCaptionInSiteElement < ActiveRecord::Migration
  def up
    change_table :site_elements do |t|
      t.change_default :headline, nil
      t.change_default :caption, nil
      t.change :headline, :text, limit: 65536
      t.change :caption, :text, limit: 65536
    end
  end

  def down
    change_table :site_elements do |t|
      t.change :headline, :string, default: 'Hello. Add your message here.'
      t.change :caption, :string, default: ''
    end
  end
end
