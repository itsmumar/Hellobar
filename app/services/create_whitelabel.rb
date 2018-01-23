class CreateWhitelabel
  def initialize site:, params:
    @site = site
    @params = params
  end

  def call
    verify_no_whitelabel_exists
    build_whitelabel
    validate_whitelabel
    create_at_sendgrid
    validate_sendgrid_response
    assign_domain_identifier_and_dns_records
    save_whitelabel
    whitelabel
  end

  private

  attr_reader :site, :params, :whitelabel, :sendgrid_response

  def verify_no_whitelabel_exists
    return if site.whitelabel.nil?

    @whitelabel = site.whitelabel
    @whitelabel.errors.add :base, 'Whitelabel is already defined for this site'

    raise_exception
  end

  def build_whitelabel
    @whitelabel = site.build_whitelabel params
  end

  def validate_whitelabel
    raise_exception unless whitelabel.valid?
  end

  def create_at_sendgrid
    params = {
      request_body: sendgrid_request_params
    }

    @sendgrid_response = sendgrid.client.whitelabel.domains.post params
  end

  def validate_sendgrid_response
    return if sendgrid_response.status_code.to_i == 201

    error = sendgrid_response_body['errors'].first['message']

    whitelabel.errors.add :domain, error
    raise_exception
  end

  def assign_domain_identifier_and_dns_records
    domain_identifier = sendgrid_response_body['id']
    dns_records = sendgrid_response_body['dns']

    whitelabel.domain_identifier = domain_identifier
    whitelabel.dns_records = dns_records
  end

  def save_whitelabel
    whitelabel.save!
  end

  def raise_exception
    raise ActiveRecord::RecordInvalid, whitelabel
  end

  def sendgrid_response_body
    JSON.parse sendgrid_response.body
  end

  def sendgrid_request_params
    {
      domain: whitelabel.domain,
      subdomain: whitelabel.subdomain,
      default: false,
      automatic_security: true,
      custom_spf: false
    }
  end

  def sendgrid
    @sendgrid ||= SendGrid::API.new api_key: Settings.sendgrid_campaigns_api_key
  end
end
