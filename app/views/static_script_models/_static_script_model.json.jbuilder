json.ignore_nil!
json.cache_if! model.cache_enabled?, model do
  json.extract! model,
    :preview_is_active,
    :capabilities,
    :site_id,
    :site_url,
    :pro_secret,
    :site_timezone,
    :hellobar_container_css,
    :templates,
    :gdpr_consent,
    :terms_and_conditions_url,
    :privacy_policy_url,
    :geolocation_url,
    :hb_backend_host,
    :tracking_url,
    :site_write_key,
    :external_tracking,
    :hellobar_element_css,
    :content_upgrades,
    :content_upgrades_styles,
    :autofills,
    :gdpr_enabled

  json.rules model.rules do |rule|
    json.match rule[:match]
    json.conditions rule[:conditions]
    json.site_elements do
      json.array! rule[:site_elements], partial: 'site_elements/site_element', as: :site_element
    end
  end
end

json.extract! model,
  :disable_self_check,
  :modules_version,
  :version,
  :timestamp
