class Font < ActiveHash::Base
  include ActiveModel::Serialization

  class << self
    def guess(input)
      if input and input != ''
        font_names = input.to_s
        all_fonts = Font.all
        # The font_name might be "Helvetica,sans-serif"
        font_names.split(',').each do |font_name|
          font_name = font_name.gsub(/^\s+/, '').gsub(/\s+$/, '')
          # Try to find the font
          possible_fonts = all_fonts.each do |font|
            if font.value.downcase.include?(font_name.downcase)
              # Return the first found font
              return font
            end
          end
        end
      end
      return nil
    end
  end
end
