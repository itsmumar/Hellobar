class Modal < SiteElement
  def default_email_thank_you_text
    if site&.free?
      DEFAULT_FREE_EMAIL_POPUP_THANK_YOU_TEXT
    else
      DEFAULT_EMAIL_THANK_YOU
    end
  end

  def placement
    self[:placement] || 'middle'
  end
end
