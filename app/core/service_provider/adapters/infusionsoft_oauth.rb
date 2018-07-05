module ServiceProvider::Adapters
  class InfusionsoftOauth < FaradayClient
    configure do |config|
      config.oauth = true
      config.url = 'https://api.infusionsoft.com/crm/rest/v1'
    end

    def initialize(identity)
      super identity, config.url,
        request: :json,
        headers: { 'Authorization': "Bearer #{ identity.credentials['token'] }" }
    end

    def lists
      campaigns = (get('campaigns') || {}).fetch('campaigns', [])
      campaigns
        .select { |campaign| campaign['published_date'].present? }
        .map { |campaign| campaign.slice('id', 'name') }
    end

    def subscribe(campaign_id, params)
      contact_id = add_contact(params)&.fetch('id', nil)
      return unless contact_id

      add_to_campaign(campaign_id, contact_id) if campaign_id
      apply_tags(params[:tags], contact_id)
    end

    def tags
      (get('tags') || {}).fetch('tags', [])
    end

    private

    def add_contact(params)
      data = default_request(params)

      first_name, last_name = params[:name].split(' ', 2) if params[:name].present?
      data[:given_name] = first_name if first_name.present?
      data[:family_name] = last_name if last_name.present?

      post('contacts', data)
    end

    def default_request(params)
      {
        email_addresses: [
          {
            email: params[:email],
            field: 'EMAIL1'
          }
        ],
        opt_in_reason: 'Customer opted-in through a Hello Bar webform',
        source_type: 'API'
      }
    end

    def add_to_campaign(campaign_id, contact_id)
      campaign = get("campaigns/#{ campaign_id }?optional_properties=sequences")
      sequence_id = campaign.dig('sequences', 0, 'id')
      post("campaigns/#{ campaign_id }/sequences/#{ sequence_id }/contacts/#{ contact_id }")
    end

    def apply_tags(tags, contact_id)
      return if tags.blank?
      post("contacts/#{ contact_id }/tags", tagIds: tags)
    end

    def test_connection
      lists
    end
  end
end
