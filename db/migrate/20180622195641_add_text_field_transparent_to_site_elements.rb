class AddTextFieldTransparentToSiteElements < ActiveRecord::Migration
  TRANSPARENT_THEMES = %w[arctic-facet smooth-impact subtle-facet].freeze

  def change
    add_column :site_elements, :text_field_transparent, :boolean, default: false

    reversible do |dir|
      dir.up do
        execute "UPDATE site_elements SET text_field_transparent=1 WHERE theme_id in (#{ transparent_themes })"
      end
    end
  end

  private

  def transparent_themes
    TRANSPARENT_THEMES.map { |theme| "'#{ theme }'" }.join(',')
  end
end
