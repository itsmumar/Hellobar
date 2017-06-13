EmbedForm = Struct.new(:form, :inputs, :action_url) do
  def valid?
    form.present? && inputs.present? && action_url.present?
  end
end
