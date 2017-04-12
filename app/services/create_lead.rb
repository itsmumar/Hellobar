class CreateLead
  def self.call(user, lead_params)
    new(user).create_lead(lead_params)
  end

  attr_reader :user

  def initialize(user)
    raise ArgumentError unless user.present?
    @user = user
  end

  def create_lead(params)
    user.create_lead!(params) unless user.lead
    update_user
  end

  private

  def update_user
    return unless user.lead
    user.update(user.lead.attributes.slice('first_name', 'last_name'))
  end
end
