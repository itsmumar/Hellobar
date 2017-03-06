class Condition < ActiveRecord::Base
  serialize :value

  # class name: Hello::Segments::User key
  SEGMENTS = {
    'DateCondition' => 'dt',
    'DeviceCondition' => 'dv',
    'EveryXSession' => 'ns',
    'LastVisitCondition' => 'ls',
    'LocationCityCondition' => 'gl_cty',
    'LocationCountryCondition' => 'gl_ctr',
    'LocationRegionCondition' => 'gl_rgn',
    'NumberOfVisitsCondition' => 'nv',
    'PreviousPageURL' => 'pp',
    'ReferrerCondition' => 'rf',
    'ReferrerDomainCondition' => 'rd',
    'SearchTermCondition' => 'st',
    'TimeCondition' => 'tc',
    'UTMCampaignCondition' => 'ad_ca',
    'UTMContentCondition' => 'ad_co',
    'UTMMediumCondition' => 'ad_me',
    'UTMSourceCondition' => 'ad_so',
    'UTMTermCondition' => 'ad_te',
    'UrlCondition' => 'pu',
    'UrlPathCondition' => 'pup',
    'UrlQuery' => 'pq'
  }

  MULTIPLE_CHOICE_SEGMENTS = %w(UrlCondition UrlPathCondition LocationCountryCondition)

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

  delegate :site, to: :rule

  def operand
    value = self[:operand]

    value.to_s if value
  end

  def to_sentence
    if MULTIPLE_CHOICE_SEGMENTS.include?(segment)
      multiple_condition_sentence
    elsif segment == 'EveryXSession'
      every_x_sessions_sentence
    elsif segment == 'TimeCondition'
      "#{ segment_data[:name] } #{ OPERANDS[operand] } #{ value[0] }:#{ value[1] }"
    else
      name = segment == 'CustomCondition' ? custom_segment : segment_data[:name]
      if operand.to_s == 'between'
        "#{ name } is between #{ value.first } and #{ value.last }"
      else
        "#{ name } #{ OPERANDS[operand] } #{ value }"
      end
    end
  end

  def segment_key
    SEGMENTS[segment]
  end

  def segment_data
    Hello::Segments::User.find { |s| s[:key] == segment_key } || {}
  end

  def timezone_offset
    return unless segment == 'TimeCondition'

    if value[2] == 'visitor'
      'visitor'
    else
      Time.use_zone(value[2]) do
        Time.zone.now.formatted_offset
      end
    end
  end

  private

  def multiple_condition_sentence
    # value might be not an array for old rules created before value type was changed
    if !value.is_a?(Array) || (value.count == 1)
      "#{ segment_data[:name] } #{ OPERANDS[operand] } #{ value.is_a?(Array) ? value.first : value }"
    else
      "#{ segment_data[:name] } #{ OPERANDS[operand] } #{ value.first } or #{ value.count - 1 } other#{ value.count == 2 ? '' : 's' }"
    end
  end

  def every_x_sessions_sentence
    return '' unless segment == 'EveryXSession'
    if value.to_i == 1
      'Every session'
    else
      "Every #{ value.to_i.ordinalize } session"
    end
  end

  def value_is_valid
    if operand == 'between'
      errors.add(:value, 'is not a valid value') unless value.is_a?(Array) && value.length == 2 && value.all?(&:present?)
    elsif MULTIPLE_CHOICE_SEGMENTS.include?(segment) || (segment == 'TimeCondition') # time condition is also array, but not with multiple choice
      errors.add(:value, 'is not a valid value') unless value.is_a?(Array)
    else
      errors.add(:value, 'is not a valid value') unless value.is_a?(String)
    end
  end

  def operand_is_valid
    @@operands ||= {
      'DateCondition'             => %w(is is_not before after between),
      'DeviceCondition'           => %w(is is_not),
      'EveryXSession'             => %w(every),
      'LastVisitCondition'        => %w(is is_not less_than greater_than between),
      'LocationCityCondition'     => %w(is is_not),
      'LocationCountryCondition'  => %w(is is_not),
      'LocationRegionCondition'   => %w(is is_not),
      'NumberOfVisitsCondition'   => %w(is is_not less_than greater_than between),
      'PreviousPageURL'           => %w(includes does_not_include),
      'ReferrerCondition'         => %w(is is_not includes does_not_include),
      'ReferrerDomainCondition'   => %w(is is_not includes does_not_include),
      'SearchTermCondition'       => %w(is is_not includes does_not_include),
      'TimeCondition'             => %w(before after),
      'UrlCondition'              => %w(is is_not includes does_not_include),
      'UrlPathCondition'          => %w(is is_not includes does_not_include),
      'UtmCondition'              => %w(is is_not includes does_not_include)
    }

    if @@operands[segment] && !@@operands[segment].include?(operand)
      errors.add(:operand, 'is not valid')
    end
  end

  def clear_blank_values
    self.value = value.select { |v| !v.blank? }.uniq if value.is_a?(Array)
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

    new(operand: operand, value: value, segment: 'DateCondition')
  end

  def normalize_url_condition
    return if segment != 'UrlCondition' && segment != 'UrlPathCondition'

    if value.is_a?(String)
      self.value = normalize_url(value)
    elsif value.is_a?(Array)
      value.each_with_index do |val, i|
        value[i] = normalize_url(val)
      end
    end
  end

  def normalize_url(url)
    return url if url.blank?
    # Don't do anything if it starts with '/' or "http(s)://"
    return url if url =~ /^(https?:\/\/|\/)/i
    if PublicSuffix.valid?(url.split('/').first)
      "http://#{ url }"
    else
      "/#{ url }"
    end
  end

  def format_string_values
    if value.is_a?(String)
      self.value = value.strip
    elsif value.is_a?(Array)
      value.each_with_index do |val, i|
        value[i] = val.strip if val.is_a?(String)
      end
    end
  end
end
