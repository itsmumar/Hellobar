namespace :clone do
  desc "Clone a user's account to the local machine ARGS [admin_token, user_id]"
  task :user, [:api_token, :user_id] => :environment do |t, args|
    host = Hellobar::Settings[:test_cloning].present? ? "www.hellobar.com" : "edge.hellobar.com"
    client = Faraday.new(url: "http://#{host}/api/user_state/#{args[:user_id]}?api_token=#{args[:api_token]}") do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    response = client.get

    if response.status == 200
      UserStateCloner.new(response.body).save
    else
      raise 'Bad api token or user id'
    end
  end
end
