namespace :clone do
  desc "Clone a user's account to the local machine ARGS [admin_token, user_id]"
  task :user, [:api_token, :user_id] => :environment do |_t, args|
    host = Hellobar::Settings[:test_cloning].present? ? 'www.hellobar.com' : 'edge.hellobar.com'
    client = Faraday.new(url: "https://#{ host }/api/user_state/#{ args[:user_id] }?api_token=#{ args[:api_token] }") do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    response = client.get
    raise 'Bad api token or user id' unless response.status == 200

    UserStateCloner.new(response.body).save
  end

  desc 'Backfill API tokens for admin accounts'
  task backfill_api_tokens: :environment do
    Admin.all.each do |admin|
      admin.update(api_token: SecureRandom.urlsafe_base64)
    end
  end
end
