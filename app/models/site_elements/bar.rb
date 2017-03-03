class Bar < SiteElement
  def secondary_color
    button_color
  end

  def placement
    read_attribute(:placement) || "bar-top"
  end

  def pushes_page_down
    self[:pushes_page_down]
  end
end
