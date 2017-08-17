class GenerateStaticScriptJob < ApplicationJob
  queue_as { "hb3_#{ Rails.env }" }

  def perform(site)
    # preload relations for better performance
    GenerateAndStoreStaticScript.new(Site.preload_for_script.find(site.id)).call
  end
end
