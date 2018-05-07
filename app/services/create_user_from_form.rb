class CreateUserFromForm
  def initialize(form)
    @form = form
  end

  # @return User
  def call
    form.validate!
    CreateUser.new(form.user).call
  end

  private

  attr_reader :form
end
