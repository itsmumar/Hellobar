class GenerateDailyStaticScriptJob < ApplicationJob
  def perform(site)
    generate_script_if_needed(site)
  end

  private

  def generate_script_if_needed(site)
    return if skip_generate?(site)

    # preload relations for better performance
    GenerateAndStoreStaticScript.new(Site.preload_for_script.find(site.id)).call
  end

  def skip_generate?(site)
    site.script_generated_at.blank? || 3.hours.ago < site.script_generated_at
  end
end
