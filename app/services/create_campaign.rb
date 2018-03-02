class CreateCampaign
  EMAIL_ATTRIBUTES = %i[from_name from_email subject body].freeze

  def initialize(site, attributes)
    @site = site
    @attributes = attributes
  end

  def call
    split_attributes!

    Campaign.transaction do
      create_campaign(create_email!)
    end
  end

  private

  attr_reader :site, :attributes, :email_attributes

  def split_attributes!
    @email_attributes = attributes.extract!(*EMAIL_ATTRIBUTES)
  end

  def create_email!
    Email.create!(email_attributes)
  end

  def create_campaign(email)
    Campaign.create!(attributes.merge(email: email))
  end
end
