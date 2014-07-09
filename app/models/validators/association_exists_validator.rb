class AssociationExistsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank? && record.send("#{attribute}_id".to_sym).blank?
      record.errors.add(attribute, "cannot be blank")
    end
  end
end
