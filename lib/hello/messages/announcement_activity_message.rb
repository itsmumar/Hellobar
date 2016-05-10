class AnnouncementActivityMessage < ActivityMessage
  def body
    append_number_of_views_text_to_message(element, super)
  end

  private

  def append_number_of_views_text_to_message(site_element, message)
    "#{message} has already resulted in #{number_with_delimiter(site_element.total_views)} views."
  end
end
