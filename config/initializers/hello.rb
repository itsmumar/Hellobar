require "./config/initializers/settings"

require "./lib/hello/asset_storage"
require "./lib/hello/bar_data"
require "./lib/hello/email_digest"
require "./lib/hello/internal_analytics"
require "./lib/hello/tracking"
require "./lib/hello/tracking/internal_stats_harvester"
require "./lib/hello/tracking_param"
require "./lib/hello/wordpress_user"

Hello::BarData.connect!
