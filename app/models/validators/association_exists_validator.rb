class AssociationExistsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank? && (record.send("#{ attribute }_id".to_sym).blank? || record.send("#{ attribute }_id".to_sym) == 0)
      record.errors.add(attribute, "can't be blank")
    end
  end
end
