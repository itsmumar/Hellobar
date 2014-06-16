require "./config/initializers/settings"

require "./lib/hello/asset_storage"
require "./lib/hello/bar_data"
require "./lib/hello/email_digest"
require "./lib/hello/tracking"
require "./lib/hello/tracking_param"

Hello::BarData.connect!
