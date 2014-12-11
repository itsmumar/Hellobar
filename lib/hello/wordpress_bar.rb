class Hello::WordpressBar < Hello::WordpressModel
  self.table_name = "hbwp_posts"

  def hellobar_meta
    value = Hello::WordpressBarMeta.where(post_id: id, meta_key: "_hellobar_meta").first.try(:meta_value) || ""
    Hello::WordpressModel.deserialize(value)
  end
end
