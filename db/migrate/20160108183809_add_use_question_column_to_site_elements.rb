class AddUseQuestionColumnToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :use_question, :boolean, default: false
  end
end
