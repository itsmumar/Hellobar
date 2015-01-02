class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

  serialize :value

  # class name: Hello::Segments::User key
  SEGMENTS = {
    'DateCondition' => 'dt',
    'DeviceCondition' => 'dv',
    'NumberOfVisitsCondition' => 'nv',
    'ReferrerCondition' => 'rf',
    'SearchTermCondition' => 'st',
    'UrlCondition' => 'pu',
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

  belongs_to :rule, inverse_of: :conditions

  validates :rule, association_exists: true
  validates :value, presence: true
  validate :value_is_valid

  def operand
    value = read_attribute(:operand)

    value.to_s if value
  end

  def to_sentence
    if operand.to_s == 'between'
      "#{segment_data[:name]} is between #{value.first} and #{value.last}"
    else
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value}"
    end
  end

  def segment_key
    SEGMENTS[segment]
  end

  def segment_data
    Hello::Segments::User.find { |s| s[:key] == segment_key } || {}
  end

  private

  def value_is_valid
    if operand == 'between'
      errors.add(:value, 'is not a valid value') unless value.kind_of?(Array) && value.length == 2 && value.all?(&:present?)
    elsif segment == 'UrlCondition'
      errors.add(:value, 'is not a valid value') unless value.kind_of?(Array)
    else
      errors.add(:value, 'is not a valid value') unless value.kind_of?(String)
    end
  end
end
