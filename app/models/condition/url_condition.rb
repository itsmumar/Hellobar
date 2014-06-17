class UrlCondition < Condition
  # { include_urls: [<String>], exclude_urls: [<String>] }
  serialize :value, Hash
end
