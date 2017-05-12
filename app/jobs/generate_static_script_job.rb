class GenerateStaticScriptJob < ApplicationJob
  def perform(site)
    generate_script_if_needed(site)
    check_installation(site)
  end

  private

  def generate_script_if_needed(site)
    return if skip_generate?(site)
    GenerateAndStoreStaticScript.new(site).call
  end

  def skip_generate?(site)
    site.script_generated_at.blank? || 3.hours.ago < site.script_generated_at
  end

  def check_installation(site)
    CheckStaticScriptInstallation.new(site).call
  end
end
