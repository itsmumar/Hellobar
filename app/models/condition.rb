class Condition < ApplicationRecord
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
    'TimeCondition' => 'tc',
    'UrlPathCondition' => 'pup',
    'UrlQueryCondition' => 'pq',
    'UTMCampaignCondition' => 'ad_ca',
    'UTMContentCondition' => 'ad_co',
    'UTMMediumCondition' => 'ad_me',
    'UTMSourceCondition' => 'ad_so',
    'UTMTermCondition' => 'ad_te'
  }.freeze

  MULTIPLE_CHOICE_SEGMENTS = %w[
    UrlPathCondition LocationCountryCondition LocationRegionCondition LocationCityCondition
    UTMCampaignCondition UTMContentCondition UTMMediumCondition UTMSourceCondition UTMTermCondition
  ].freeze

  PRECISE_SEGMENTS = %w[LocationRegionCondition LocationCityCondition].freeze

  # stored value: displayed value
  OPERANDS = {
    after: 'is after',
    before: 'is before',
    between: 'is between',
    does_not_include: 'does not include',
    greater_than: 'is greater than',
    includes: 'includes',
    keyword: 'keyword',
    is: 'is',
    is_not: 'is not',
    less_than: 'is less than'
  }.with_indifferent_access.freeze

  EU_COUNTRIES = %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE GB].freeze

  belongs_to :rule, inverse_of: :conditions

  before_validation :clear_blank_values
  before_validation :format_string_values
  before_validation :normalize_url_condition

  validates :rule, presence: true, association_exists: true
  validates :segment, presence: true, inclusion: { in: SEGMENTS.keys }
  validates :operand, presence: true
  validates :value, presence: true
  validate :value_correctness
  validate :operand_correctness

  delegate :site, to: :rule

  scope :custom, -> { where.not(value: 'mobile') }

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

  def operand
    value = self[:operand]

    value.to_s if value
  end

  def serialized_value
    return EU_COUNTRIES.dup + (self[:value] - ['EU']) if segment_key == 'gl_ctr' && self[:value]&.include?('EU')

    self[:value]
  end

  def to_sentence
    if MULTIPLE_CHOICE_SEGMENTS.include?(segment)
      multiple_condition_sentence
    elsif segment == 'EveryXSession'
      every_x_sessions_sentence
    elsif segment == 'TimeCondition'
      "#{ segment_data[:name] } #{ OPERANDS[operand] } #{ value[0] }:#{ value[1] }"
    elsif operand.to_s == 'between'
      "#{ segment_data[:name] } is between #{ value.first } and #{ value.last }"
    else
      "#{ segment_data[:name] } #{ OPERANDS[operand] } #{ value }"
    end
  end

  def segment_key
    SEGMENTS[segment]
  end

  def segment_data
    Hello::Segments::USER.find { |s| s[:key] == segment_key } || {}
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

  def precise?
    PRECISE_SEGMENTS.include?(segment)
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

    repetition = value.to_i == 1 ? '' : ' ' + value.to_i.ordinalize
    "Every#{ repetition } session"
  end

  def value_correctness
    if operand == 'between'
      errors.add(:value, 'is not a valid value') unless value.is_a?(Array) && value.length == 2 && value.all?(&:present?)
    elsif MULTIPLE_CHOICE_SEGMENTS.include?(segment) || (segment == 'TimeCondition') # time condition is also array, but not with multiple choice
      errors.add(:value, 'is not a valid value') unless value.is_a?(Array)
    else
      errors.add(:value, 'is not a valid value') unless value.is_a?(String)
    end
  end

  def operand_correctness
    @operands ||= {
      'DateCondition'             => %w[is is_not before after between],
      'DeviceCondition'           => %w[is is_not],
      'EveryXSession'             => %w[every],
      'LastVisitCondition'        => %w[is is_not less_than greater_than between],
      'LocationCityCondition'     => %w[is is_not],
      'LocationCountryCondition'  => %w[is is_not],
      'LocationRegionCondition'   => %w[is is_not],
      'NumberOfVisitsCondition'   => %w[is is_not less_than greater_than between],
      'PreviousPageURL'           => %w[includes does_not_include],
      'ReferrerCondition'         => %w[is is_not includes does_not_include],
      'ReferrerDomainCondition'   => %w[is is_not includes does_not_include],
      'TimeCondition'             => %w[before after],
      'UrlPathCondition'          => %w[is is_not includes does_not_include],
      'UrlQueryCondition'         => %w[is is_not includes does_not_include keyword],
      'UTMCampaignCondition'      => %w[is is_not includes does_not_include],
      'UTMContentCondition'       => %w[is is_not includes does_not_include],
      'UTMMediumCondition'        => %w[is is_not includes does_not_include],
      'UTMSourceCondition'        => %w[is is_not includes does_not_include],
      'UTMTermCondition'          => %w[is is_not includes does_not_include]
    }

    return if @operands[segment]&.include? operand

    errors.add(:operand, 'is not valid')
  end

  def clear_blank_values
    self.value = value.reject(&:blank?).uniq if value.is_a?(Array)
  end

  def normalize_url_condition
    return if segment != 'UrlPathCondition'

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

    # Don't do anything if it starts with "http(s)://" or '/'
    return url if url =~ /^(https?:\/\/|\/)/i

    # If user supplied url looks like a valid domain, add scheme
    if PublicSuffix.valid? NormalizeURI[url]&.domain, default_rule: nil
      "http://#{ url }"
    else # otherwise treat as path
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
