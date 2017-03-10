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
    return data[:expiration] if data[:expiration].split('/').length < 2
    data[:expiration].split('/')[0].to_i
  rescue
    data[:expiration]
  end

  # derived from expiration
  def year
    y = data[:expiration].split('/')[1]
    if y.length == 2
      "20#{ y }".to_i
    elsif y.length == 4
      y.to_i
    else
      Date.parse(data[:expiration]).year
    end
  rescue
    data[:expiration]
  end

  def to_hash
    {
      number: data[:number],
      month: month,
      year: year,
      first_name: first_name,
      last_name: last_name,
      verification_value: data[:verification_value],
      city: data[:city],
      state: data[:state],
      zip: data[:zip],
      address1: data[:address],
      country: data[:country]
    }
  end
end
