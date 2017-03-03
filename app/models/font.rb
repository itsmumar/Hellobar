class Font < ActiveHash::Base
  include ActiveModel::Serialization

  class << self
    # @param [String] font_names; e.g. "Helvetica,sans-serif"
    def guess(font_names)
      return unless font_names.present?

      all_fonts = Font.all
      font_names.to_s.split(',').find do |font_name|
        all_fonts.find { |font| font.same?(font_name.strip) }
      end
    end
  end

  def same?(font_name)
    value.downcase.include?(font_name.downcase)
  end
end
