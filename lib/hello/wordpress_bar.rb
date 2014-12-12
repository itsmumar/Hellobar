class Hello::WordpressBar < Hello::WordpressModel
  self.table_name = "hbwp_posts"

  def hellobar_meta
    value = Hello::WordpressBarMeta.where(post_id: id, meta_key: "_hellobar_meta").first.try(:meta_value) || ""
    Hello::WordpressModel.deserialize(value) || {"meta" => {}}
  end

  def background_color
    hellobar_meta["meta"]["barcolor"]
  end

  def text_color
    hellobar_meta["meta"]["textcolor"]
  end
end
