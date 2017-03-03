class Color
  class << self
    def color_is_bright?(hex)
      luminance(*hex_string_to_rgb(hex)) >= 0.5
    end

    def hex_string_to_rgb(hex)
      rgb = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.match(hex).captures
      rgb.map do |value|
        value.to_i(16)
      end
    end

    # http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
    def luminance(r, g, b)
      rgb = [r, g, b]

      rgb.map! do |component|
        component = component / 255.0
        if component < 0.03928
          component / 12.92
        else
          ((component + 0.055) / 1.055)**2.4
        end
      end

      0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
    end
  end
end
