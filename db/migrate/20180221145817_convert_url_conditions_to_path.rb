class ConvertURLConditionsToPath < ActiveRecord::Migration
  URL_SCHEMES = ['http', 'https'].freeze
  ROOT_PATH = '/'.freeze

  def up
    Condition.includes(rule: :site).where(segment: 'UrlCondition').find_each do |condition|
      condition.segment = 'UrlPathCondition'

      begin
        condition.value = condition.value.map do |url|
          convert_url_to_path(url).tap do |path|
            puts "Converted condition (ID: #{condition.id}): #{url} => #{path}"
          end
        end.compact
        condition.save
      rescue => e
        puts "Error while converting (condition ID: #{condition.id}): #{e.message} (#{e.class})"
      end
    end
  end

  def down
  end

  private

  def convert_url_to_path(url)
    uri = URI(url)
    uri.path.presence || ROOT_PATH
  rescue URI::InvalidURIError
    matched_urls = URI.extract(url, URL_SCHEMES)
    if matched_urls.present?
      convert_url_to_path(matched_urls.first)
    else
      convert_url_to_path(URI.escape(url))
    end
  end
end
