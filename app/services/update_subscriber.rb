class UpdateSubscriber
  def initialize(contact_list, email, params)
    @contact_list = contact_list
    @email = email
    @params = params
  end

  def call
    delete_subscriber
    create_subscriber
  end

  private

  attr_reader :contact_list, :email, :params

  def delete_subscriber
    DeleteSubscriber.new(contact_list, email).call
  end

  def create_subscriber
    CreateSubscriber.new(contact_list, params).call
  end
end
