class Bar < SiteElement
  def secondary_color
    button_color
  end

  def placement
    self[:placement] || 'bar-top'
  end
end
