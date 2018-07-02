class URLValidator < ActiveModel::EachValidator
  URL_REGEXP = /^https?:\/\/([a-z0-9][a-z0-9_\-]*)(\.[a-z0-9][a-z0-9_\-]*)*(:[0-9]{1,5})?(\/.*)*$/ix

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "can't be blank")
      return
    end

    record.errors.add(attribute, 'is invalid') unless value =~ URL_REGEXP
  end
end

# Add an alias (diff versions of Rails/Ruby constantize this differently)
class UrlValidator < URLValidator
end
