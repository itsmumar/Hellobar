class Modal < SiteElement
  def placement
    read_attribute(:placement) || 'middle'
  end
end
