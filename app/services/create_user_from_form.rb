class CreateUserFromForm
  def initialize(form, cookies = {})
    @form = form
    @cookies = cookies
  end

  def call
    validate_form
    create_user
  end

  private

  attr_reader :form, :cookies

  def validate_form
    form.validate!
  end

  def create_user
    CreateUser.new(form.user, cookies).call
  end
end
