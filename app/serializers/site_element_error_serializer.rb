class SiteElementErrorSerializer < ActiveModel::Serializer
  attributes :errors, :full_messages

  def errors
    object.errors.to_hash
  end

  def full_messages
    messages = []

    object.errors.keys.each do |attribute|
      errors = object.errors[attribute]

      if attribute == :element_subtype && errors.include?("can't be blank")
        messages << "You must select a type in the \"settings\" section"
        next
      end

      if attribute == :rule && errors.include?("can't be blank")
        messages << "You must select who will see this in the \"targeting\" section"
        next
      end

      errors.each do |error|
        messages << object.errors.full_message(attribute, error)
      end
    end

    messages
  end
end
