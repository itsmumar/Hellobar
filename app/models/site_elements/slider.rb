class Slider < SiteElement
  def placement
    read_attribute(:placement) || 'bottom-right'
  end
end
