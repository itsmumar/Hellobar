class Hello::WordpressBar < Hello::WordpressModel
  self.table_name = "hbwp_posts"

  def convert_to_site_element!(rule)
    # site element attributes we might want to capture:
    #      "show_border"=>false,
    #      "border_color"=>"ffffff",
    #      "button_color"=>"000000",
    #      "font"=>"Helvetica,Arial,sans-serif",
    #      "link_color"=>"ffffff",
    #      "texture"=>"none",
    #      "paused"=>false,
    #      "show_branding"=>true,
    #      "display_when"=>"immediately",
    #      "pushes_page_down"=>true,
    #      "remains_at_top"=>true

    params = {
      rule: rule,
      element_subtype: "traffic",
      link_text: hellobar_meta["linktext"],
      message: post_content,
      font: hellobar_meta["meta"]["fontFamily"],
      created_at: post_date,
      settings: {
        url: hellobar_meta["linkurl"]
      }
    }

    params[:background_color] = background_color.gsub("#", "") if background_color.present?
    params[:text_color] = text_color.gsub("#", "") if text_color.present?

    SiteElement.create!(params)
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
end
