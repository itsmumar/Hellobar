class URLValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, "can't be blank") unless value.present?

    uri = Addressable::URI.parse(value)

    if !%w{http https}.include?(uri.scheme) || uri.host.blank? || !uri.ip_based? && url !~ /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
      record.errors.add(attribute, 'is invalid')
    end
  rescue Addressable::URI::InvalidURIError
    record.errors.add(attribute, 'is invalid')
  end
end

# Add an alias (diff versions of Rails/Ruby constantize this differently)
class UrlValidator < URLValidator; end
