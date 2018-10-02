class Takeover < SiteElement
  def image_style
    :large
  end

  def default_email_thank_you_text
    if site&.free?
      DEFAULT_FREE_EMAIL_POPUP_THANK_YOU_TEXT
    else
      DEFAULT_EMAIL_THANK_YOU
    end
  end
end
