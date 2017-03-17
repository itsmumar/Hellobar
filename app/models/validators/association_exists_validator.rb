class AssociationExistsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.blank? && association_empty?
    record.errors.add(attribute, "can't be blank")
  end

  private

  def association_empty?
    record.send("#{ attribute }_id".to_sym).blank? || record.send("#{ attribute }_id".to_sym) == 0
  end
end
