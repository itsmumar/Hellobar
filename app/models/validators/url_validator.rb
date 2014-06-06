class UrlValidator < ActiveModel::Validator
  def validate(record)
    field = options[:url_field]
    url = record.public_send(field)

    record.errors.add(field, "can't be blank") unless url.present?

    uri = URI.parse(url)

    if uri.scheme.blank? || uri.host.blank? || uri.host !~ /^\w+\-?\w+\.\w\-?\w/ || url !~ /^(http(s)?:\/\/)?[\w\.\-]+$/
      record.errors.add(field, "is invalid")
    end
  rescue URI::InvalidURIError
    record.errors.add(field, "is invalid")
  end
end
