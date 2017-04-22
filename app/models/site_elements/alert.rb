class Alert < SiteElement
  def placement
    self[:placement] || 'bottom-left'
  end

  def view_condition
    self[:view_condition] || 'wait-5'
  end

  def sound
    self[:sound] || 'bell'
  end
end
