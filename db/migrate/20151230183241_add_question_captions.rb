class AddQuestionCaptions < ActiveRecord::Migration
  def change
    add_column :site_elements, :answer1caption, :string
    add_column :site_elements, :answer2caption, :string
  end
end
