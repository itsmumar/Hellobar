class Font < ActiveHash::Base
  include ActiveModel::Serialization

  class << self
    # @param [String] font_names; e.g. "Helvetica,sans-serif"
    def guess(font_names)
      return unless font_names.present?
      font_names = font_names.to_s.split(',')
      all_fonts = Font.all

      font_names.each do |font_name|
        font = all_fonts.find { |font| font.same?(font_name.strip) }
        return font if font.present?
      end

      nil
    end
  end

  def same?(font_name)
    value.downcase.include?(font_name.downcase)
  end
end
