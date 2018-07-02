class ReplaceProximaFontWithSansSerif < ActiveRecord::Migration
  PROXIMA_FONT = 'proxima'.freeze
  SANS_SERIF_FONT = 'open_sans'.freeze

  def up
    SiteElement.where(font_id: PROXIMA_FONT).update_all(font_id: SANS_SERIF_FONT)
  end

  def down
    # do nothing
  end
end
