class UrlValidator < ActiveModel::Validator
  def validate(record)
    url_field = options[:url_field]
    url = record.public_send(url_field)

    record.errors.add(url_field, "can't be blank") unless url.present?

    uri = URI.parse(url)

    if uri.scheme.blank? || uri.host.blank? || uri.host !~ /^\w+\.\w/ || url !~ /^(http(s)?:\/\/)?[\w\.]+$/
      record.errors.add(url_field, "is invalid")
    end
  rescue URI::InvalidURIError
    record.errors.add(url_field, "is invalid")
  end
end
