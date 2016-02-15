class AddQuestionsAndAnswersToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :question, :string
    add_column :site_elements, :answer1, :string
    add_column :site_elements, :answer2, :string
    add_column :site_elements, :answer1response, :string
    add_column :site_elements, :answer2response, :string
    add_column :site_elements, :answer1link_text, :string
    add_column :site_elements, :answer2link_text, :string
  end
end
