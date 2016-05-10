class ActivityMessage
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include SiteElementsHelper

  attr_reader :site_element, :body

  def initialize(site_element)
    @site_element = site_element
  end

  def body
    content_tag(:strong) do
      content_tag(:a, href: "/sites/#{self.site_element.site.id}/site_elements##{self.site_element.id}") do
        "The #{self.site_element.short_subtype} bar you added #{time_ago_in_words(self.site_element.created_at)} ago"
      end
    end
  end
end
