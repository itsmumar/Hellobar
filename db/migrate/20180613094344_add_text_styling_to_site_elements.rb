class AddTextStylingToSiteElements < ActiveRecord::Migration
  BORDERLESS_THEMES = %w[arctic-facet smooth-impact subtle-facet].freeze

  def change
    add_column :site_elements, :text_field_border_color, :string, limit: 10, default: 'e0e0e0'
    add_column :site_elements, :text_field_border_width, :integer, limit: 1, default: 1
    add_column :site_elements, :text_field_border_radius, :integer, limit: 1, default: 2
    add_column :site_elements, :text_field_text_color, :string, limit: 10, default: '5c5e60'
    add_column :site_elements, :text_field_background_color, :string, limit: 10, default: 'ffffff'
    add_column :site_elements, :text_field_background_opacity, :integer, limit: 1, default: 100

    reversible do |dir|
      dir.up do
        # Borderless themes
        execute "UPDATE site_elements SET text_field_border_width=0 WHERE theme_id in (#{ borderless_themes })"

        # Smooth impact specific styling
        execute "UPDATE site_elements SET text_field_border_radius=3 WHERE theme_id='smooth-impact'"
        execute "UPDATE site_elements SET text_field_text_color='ffffff' WHERE theme_id='smooth-impact'"
        execute "UPDATE site_elements SET text_field_background_color='000000' WHERE theme_id='smooth-impact'"
        execute "UPDATE site_elements SET text_field_background_opacity=10 WHERE theme_id='smooth-impact'"
      end
    end
  end

  private

  def borderless_themes
    BORDERLESS_THEMES.map { |theme| "'#{ theme }'" }.join(',')
  end
end
