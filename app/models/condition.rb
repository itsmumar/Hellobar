class Condition < ActiveRecord::Base
  serialize :value

  # class name: Hello::Segments::User key
  SEGMENTS = {
    'DateCondition' => 'dt',
    'LastVisitCondition' => 'ls',
    'DeviceCondition' => 'dv',
    'EveryXSession' => 'ns',
    'NumberOfVisitsCondition' => 'nv',
    'PreviousPageURL' => 'pp',
    'ReferrerCondition' => 'rf',
    'SearchTermCondition' => 'st',
    'UrlCondition' => 'pu',
    'ReferrerDomainCondition' => 'rd',
    'UTMSourceCondition' => 'ad_so',
    'UTMCampaignCondition' => 'ad_ca',
    'UTMMediumCondition' => 'ad_me',
    'UTMContentCondition' => 'ad_co',
    'UTMTermCondition' => 'ad_te'
  }

  # stored value: displayed value
  OPERANDS = {
    after: 'is after',
    before: 'is before',
    between: 'is between',
    does_not_include: 'does not include',
    greater_than: 'is greater than',
    includes: 'includes',
    is: 'is',
    is_not: 'is not',
    less_than: 'is less than'
  }.with_indifferent_access

  belongs_to :rule, inverse_of: :conditions, touch: true

  before_validation :clear_blank_values
  before_validation :format_string_values
  before_validation :normalize_url_condition

  validates :rule, association_exists: true
  validates :value, presence: true
  validate :value_is_valid
  validate :operand_is_valid

  def operand
    value = read_attribute(:operand)

    value.to_s if value
  end

  def to_sentence
    if segment == "UrlCondition"
      url_condition_sentence
    elsif segment == "EveryXSession"
      every_x_sessions_sentence
    else
      name = segment == "CustomCondition" ? custom_segment : segment_data[:name]
      if operand.to_s == 'between'
        "#{name} is between #{value.first} and #{value.last}"
      else
        "#{name} #{OPERANDS[operand]} #{value}"
      end
    end
  end

  def segment_key
    SEGMENTS[segment]
  end

  def segment_data
    Hello::Segments::User.find { |s| s[:key] == segment_key } || {}
  end

  private

  def url_condition_sentence
    return "" unless segment == "UrlCondition"
    if value.count > 2
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value.first} or #{value.count - 1} other URLs"
    elsif value.count == 2
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value.first} or 1 other URL"
    else
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value.first}"
    end
  end

  def every_x_sessions_sentence
    return "" unless segment == "EveryXSession"
    if value.to_i == 1
      "Every session"
    else
      "Every #{value.to_i.ordinalize} session"
    end
  end

  def value_is_valid
    if operand == 'between'
      errors.add(:value, 'is not a valid value') unless value.kind_of?(Array) && value.length == 2 && value.all?(&:present?)
    elsif segment == 'UrlCondition'
      errors.add(:value, 'is not a valid value') unless value.kind_of?(Array)
    else
      errors.add(:value, 'is not a valid value') unless value.kind_of?(String)
    end
  end

  def operand_is_valid
    @@operands ||= {
      "DateCondition"           => %w{ is is_not before after between },
      "LastVisitCondition"      => %w{ is is_not less_than greater_than between },
      "EveryXSession"           => %w{ every },
      "DeviceCondition"         => %w{ is is_not },
      "NumberOfVisitsCondition" => %w{ is is_not less_than greater_than between },
      "PreviousPageURL"         => %w{ includes does_not_include },
      "ReferrerCondition"       => %w{ is is_not includes does_not_include },
      "ReferrerDomainCondition" => %w{ is is_not includes does_not_include },
      "SearchTermCondition"     => %w{ is is_not includes does_not_include },
      "UrlCondition"            => %w{ is is_not includes does_not_include },
      "UtmCondition"            => %w{ is is_not includes does_not_include }
    }

    if @@operands[segment] && !@@operands[segment].include?(operand)
      errors.add(:operand, 'is not valid')
    end
  end

  def clear_blank_values
    self.value = value.select{|v| !v.blank?} if value.kind_of?(Array)
  end

  def self.date_condition_from_params(start_date, end_date)
    return unless [start_date, end_date].any?(&:present?)

    if [start_date, end_date].all?(&:present?)
      operand = 'between'
      value = [start_date, end_date]
    elsif start_date.present?
      operand = 'after'
      value = start_date
    elsif end_date.present?
      operand = 'before'
      value = end_date
    end

    new(operand: operand, value: value, segment: "DateCondition")
  end

  def normalize_url_condition
    return if self.segment != "UrlCondition"

    if self.value.kind_of?(String)
      self.value = normalize_url(self.value)
    elsif self.value.kind_of?(Array)
      self.value.each_with_index do |val, i|
        self.value[i] = normalize_url(val)
      end
    end
  end

  def normalize_url(url)
    return url if url.blank?
    # Don't do anything if it starts with '/' or "http(s)://"
    return url if url.match(/^(https?:\/\/|\/)/i)
    if PublicSuffix.valid?(url.split('/').first)
      "http://#{url}"
    else
      "/#{url}"
    end
  end

  def format_string_values
    if self.value.kind_of?(String)
      self.value = self.value.strip
    elsif self.value.kind_of?(Array)
      self.value.each_with_index do |val, i|
        self.value[i] = val.strip if val.kind_of?(String)
      end
    end
  end
end
