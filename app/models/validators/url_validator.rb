class URLValidator < ActiveModel::EachValidator
  URL_REGEXP = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix

  def validate_each(record, attribute, value)
    record.errors.add(attribute, "can't be blank") if value.blank?

    record.errors.add(attribute, 'is invalid') if invalid_url?(value)
  rescue Addressable::URI::InvalidURIError
    record.errors.add(attribute, 'is invalid')
  end

  private

  def invalid_url?(url)
    uri = Addressable::URI.parse(url)

    !%w[http https].include?(uri.scheme) ||
      uri.host.blank? ||
      !uri.ip_based? && uri !~ URL_REGEXP
  end
end

# Add an alias (diff versions of Rails/Ruby constantize this differently)
class UrlValidator < URLValidator
end
