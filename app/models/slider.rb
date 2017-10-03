class Slider < SiteElement
  def placement
    self[:placement] || 'bottom-right'
  end
end
