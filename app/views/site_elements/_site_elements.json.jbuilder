json.ignore_nil!
json.cache! site_elements do
  json.array! site_elements, partial: 'site_elements/site_element', as: :site_element
end
