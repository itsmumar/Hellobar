class PageObject
  include Rails.application.routes.url_helpers
  include Capybara::DSL

  class_attribute :page_url

  delegate :find, :find_all, to: :page

  def self.visit(*args)
    new.tap { |page| page.load_page(*args) }
  end

  def load_page(*args)
    visit instance_exec(*args, &page_url)
  end

  def assign_attributes(attrs)
    attrs.each do |attr, value|
      send "#{ attr }=", value
    end
  end
end
