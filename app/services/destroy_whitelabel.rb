class DestroyWhitelabel
  def initialize site:
    @site = site
  end

  def call
    destroy_at_sendgrid
    destroy_whitelabel
  end

  private

  attr_reader :site

  delegate :whitelabel, to: :site, allow_nil: true
  delegate :domain_identifier, to: :whitelabel, allow_nil: true

  def destroy_at_sendgrid
    return unless domain_identifier

    sendgrid.client.whitelabel.domains._(domain_identifier).delete
  end

  def destroy_whitelabel
    return unless whitelabel

    whitelabel.destroy!
  end

  def sendgrid
    @sendgrid ||= SendGrid::API.new api_key: Settings.sendgrid_campaigns_api_key
  end
end
