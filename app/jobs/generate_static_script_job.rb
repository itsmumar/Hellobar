class GenerateStaticScriptJob < ApplicationJob
  queue_as { "hb3_#{ Rails.env }" }

  def perform(site)
    # preload relations for better performance
    site = Site.preload_for_script.find_by id: site.id

    return unless site

    GenerateAndStoreStaticScript.new(site).call
  end
end
