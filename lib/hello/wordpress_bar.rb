require 'color'

class Hello::WordpressBar < Hello::WordpressModel
  self.table_name = "hbwp_posts"

  BUTTON_COLORS = {
    "light-images" => "2d2c29",
    "default" => "e8e7e9"
  }

  def convert_to_site_element!(rule)
    params = {
      rule: rule,
      element_subtype: "traffic",
      link_text: hellobar_meta["linktext"],
      headline: post_content,
      font: hellobar_meta["meta"]["fontFamily"],
      created_at: post_date,
      wordpress_bar_id: id,
      show_border: hellobar_meta["meta"]["border"] == "1",
      font: hellobar_meta["meta"]["fontFamily"].presence || "Helvetica,Arial,sans-serif",
      paused: paused?,
      settings: {
        url: link_url
      }
    }

    params[:background_color] = standardize_color(background_color) if background_color.present?
    params[:text_color] = standardize_color(text_color) if text_color.present?
    params[:link_color] = standardize_color(link_color) if link_color.present?
    params[:border_color] = standardize_color(border_color) if border_color.present?
    params[:button_color] = button_color

    Bar.create!(params)
  end

  def paused?
    post_status == "draft" || (parent.try(:post_status) == "draft")
  end

  def parent
    if post_parent.present? && post_parent != 0
      Hello::WordpressBar.where(post_author: post_author, id: post_parent).first
    else
      nil
    end
  end

  def hellobar_meta
    return @hellobar_meta if @hellobar_meta

    value = Hello::WordpressBarMeta.where(post_id: id, meta_key: "_hellobar_meta").first.try(:meta_value) || nil
    @hellobar_meta = value ? Hello::WordpressModel.deserialize(value) : {"meta" => {}}
  end

  def background_color
    hellobar_meta["meta"]["barcolor"]
  end

  def text_color
    hellobar_meta["meta"]["textcolor"]
  end

  def link_color
    hellobar_meta["meta"]["linkcolor"]
  end

  def border_color
    hellobar_meta["meta"]["bordercolor"]
  end

  def button_color
    color = BUTTON_COLORS[hellobar_meta["meta"]["imageStyle"]]

    if color.nil?
      if link_color.present?
        if Color.color_is_bright?(standardize_color(link_color))
          color = BUTTON_COLORS["light-images"]
        end
      end
    end

    color || BUTTON_COLORS["default"]
  end

  def standardize_color(color)
    color = color.gsub("#", "")
    if color.length == 3
      color.scan(/\w/).map{ |x| x * 2 }.join
    else
      color
    end
  end

  def link_url
    hellobar_meta["linkurl"].blank? ? "" : CGI.unescapeHTML(hellobar_meta["linkurl"])
  end
end
