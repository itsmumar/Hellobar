# Below is a list of all segments that are tracked. The short code (the
# key) is what is used in the backend storage and in the Javascript.
module Hello
  module Segments
    USER = [
      { key: 'fv', name: 'First Visit', type: :timestamp },
      { key: 'lv', name: 'Last Visit', type: :timestamp },
      { key: 'nv', name: 'Number of Visits', type: :number, units: 'visit' },
      { key: 'lf', name: 'Life of Visitor', type: :number, units: 'day' },
      { key: 'ls', name: 'Days Since Last Visit', type: :number, units: 'day' },
      { key: 'xs', name: 'Number of sessions', type: :number, units: 'sessions' },
      { key: 'pp', name: 'Previous page URL', type: :string, units: 'url' },
      { key: 'rf', name: 'Referrer URL', type: :string, units: 'url' },
      { key: 'rd', name: 'Referrer Domain', type: :string, units: 'domain' },
      { key: 'or', name: 'Original Referrer', type: :string, units: 'url' },
      { key: 'pu', name: 'Page URL', type: :string, units: 'url' },
      { key: 'pq', name: 'Page Query', type: :string, units: 'url' },
      { key: 'pup', name: 'URL Path', type: :string, units: 'url' },
      { key: 'st', name: 'Search Terms', type: :string },
      { key: 'dt', name: 'Date', type: :date },
      { key: 'ts', name: 'Date/Time', type: :timestamp },
      { key: 'dv', name: 'Device', type: :device, units: 'device' },
      { key: 'co', name: 'Country', type: :country, units: 'country' },
      { key: 'ad_so', name: 'Ad Source', type: :string },
      { key: 'ad_ca', name: 'Ad Campaign', type: :string },
      { key: 'ad_me', name: 'Ad Medium', type: :string },
      { key: 'ad_co', name: 'Ad Content', type: :string },
      { key: 'ad_te', name: 'Ad Term', type: :string },
      { key: 'ec', name: 'Email Conversion', type: :conversion, units: 'conversion' },
      { key: 'fl', name: 'Facebook Like', type: :conversion, units: 'conversion' },
      { key: 'gl_cty', name: 'Geolocation City', type: :string },
      { key: 'gl_ctr', name: 'Geolocation Country', type: :string },
      { key: 'gl_rgn', name: 'Geolocation Region', type: :string },
      { key: 'tc', name: 'Time', type: :string }
    ].freeze
  end
end
