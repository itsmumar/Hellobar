class UrlValidator < ActiveModel::Validator
  def validate(record)
    field = options[:url_field]
    url = record.public_send(field)

    record.errors.add(field, "can't be blank") unless url.present?

    uri = URI.parse(url)

    if uri.scheme.blank? || uri.host.blank? || url !~ /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
      record.errors.add(field, "is invalid")
    end
  rescue URI::InvalidURIError
    record.errors.add(field, "is invalid")
  end
end
