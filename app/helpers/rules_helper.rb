module RulesHelper
  def format_errors(errors)
    json = errors.as_json
    result = {}
    json.delete(:conditions)
    json.each do |k, v|
      next if k == :conditions
      key = k.to_s.split('.').size > 1 ? k.to_s.split('.').last : k
      key = key.to_s.camelize
      result[key] = v
    end
    result
  end
end
