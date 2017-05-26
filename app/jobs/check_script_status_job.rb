class CheckScriptStatusJob < ApplicationJob
  def perform(site)
    check_installation(site)
  end

  private

  def check_installation(site)
    CheckStaticScriptInstallation.new(site).call
  end
end
