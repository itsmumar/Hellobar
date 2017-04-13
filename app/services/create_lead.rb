class CreateLead
  attr_reader :user, :params

  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    create_lead
    update_user
  end

  private

  def create_lead
    user.create_lead!(params) unless user.lead
  end

  def update_user
    return unless user.lead
    user.update(user.lead.attributes.slice('first_name', 'last_name'))
  end
end
