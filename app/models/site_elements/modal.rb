class Modal < SiteElement
  def placement
    self[:placement] || 'middle'
  end
end
