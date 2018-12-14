RSpec.configure do |config|
  config.before do
    # Stub Services
    allow_any_instance_of(FetchSiteStatisticsFromES).to(receive :call).and_return({'call': 1, 'total': 1, 'social': 1, 'email': 1, 'traffic': 2})
    allow_any_instance_of(FetchGraphStatisticsFromES).to(receive :call).and_return([{:date=>"1/15", :value=>12},
                                                                                    {:date=>"7/05", :value=>12},
                                                                                    {:date=>"9/04", :value=>12}])
  end
end
