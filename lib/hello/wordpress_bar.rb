class Hello::WordpressBar < Hello::WordpressModel
  self.table_name = "hbwp_posts"

  def convert_to_site_element!(rule)
    params = {
      rule: rule,
      element_subtype: "traffic",
      link_text: hellobar_meta["linktext"],
      message: post_content,
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

    params[:background_color] = background_color.gsub("#", "") if background_color.present?
    params[:text_color] = text_color.gsub("#", "") if text_color.present?
    params[:link_color] = link_color.gsub("#", "") if link_color.present?
    params[:border_color] = border_color.gsub("#", "") if border_color.present?

    SiteElement.create!(params)
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

  def link_url
    hellobar_meta["linkurl"].blank? ? "" : CGI.unescapeHTML(hellobar_meta["linkurl"])
  end
end
