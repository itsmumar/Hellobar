# breaks up user input to be used by a PaymentMethodDetail instance
class PaymentForm
  attr_reader :data

  def initialize(data)
    @data = data.with_indifferent_access
    @data[:name] ||= ''
  end

  # derived from name
  def first_name
    data[:name].split(' ').first
  end

  # derived from name
  def last_name
    data[:name].split(' ')[1..-1].try(:join, ' ')
  end

  # derived from expiration
  def month
    Date.parse(data[:expiration]).month rescue data[:expiration]
  end

  # derived from expiration
  def year
    Date.parse(data[:expiration]).year rescue data[:expiration]
  end

  def to_hash
    {
      :number => data[:number],
      :month => month,
      :year => year,
      :first_name => first_name,
      :last_name => last_name,
      :verification_value => data[:verification_value],
      :city => data[:city],
      :state => data[:state],
      :zip => data[:zip],
      :address1 => data[:address],
      :country => data[:country]
    }
  end
end
