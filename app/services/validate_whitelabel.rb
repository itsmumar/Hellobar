class ValidateWhitelabel
  ERRORS = 'errors'.freeze
  MESSAGE = 'message'.freeze
  REASON = 'reason'.freeze
  VALIDATION_RESULTS = 'validation_results'.freeze
  VALIDATION_FAILED = 'Validation failed'.freeze

  def initialize whitelabel:
    @whitelabel = whitelabel
  end

  def call
    validate_at_sendgrid
    validate_sendgrid_response
    parse_validation_result
    whitelabel
  end

  private

  attr_reader :whitelabel, :sendgrid_response

  delegate :domain_identifier, to: :whitelabel

  def validate_at_sendgrid
    @sendgrid_response = sendgrid.client.whitelabel.domains._(domain_identifier).validate.post
  end

  def validate_sendgrid_response
    return if sendgrid_response.status_code.to_i == 200

    error = sendgrid_response_body[ERRORS].first[MESSAGE]

    whitelabel.errors.add :base, error
    raise_exception
  end

  def parse_validation_result
    if sendgrid_response_body['valid']
      validate_whitelabel
    else
      invalidate_whitelabel

      whitelabel.errors.add :base, VALIDATION_FAILED

      add_validation_results_to_errors

      raise_exception
    end
  end

  def add_validation_results_to_errors
    return unless validation_results

    validation_results.each_value do |result|
      whitelabel.errors.add(:domain, result[REASON]) if result[REASON].present?
    end
  end

  def validation_results
    sendgrid_response_body[VALIDATION_RESULTS]
  end

  def validate_whitelabel
    whitelabel.valid!
  end

  def invalidate_whitelabel
    whitelabel.invalid!
  end

  def raise_exception
    raise ActiveRecord::RecordInvalid, whitelabel
  end

  def sendgrid_response_body
    JSON.parse sendgrid_response.body
  end

  def sendgrid
    @sendgrid ||= SendGrid::API.new api_key: Settings.sendgrid_campaigns_api_key
  end
end
