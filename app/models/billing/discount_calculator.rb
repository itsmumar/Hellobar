class DiscountCalculator
  attr_reader :discounts

  def initialize(discounts)
    @discounts = discounts
    @ranges = []

    discounts.each do |discount|
      if discount[:end].nil?
        @ranges << DiscountRange.new(nil, discount[:amount])
      else
        @ranges << DiscountRange.new((1 + discount[:end]) - (discount[:start] || 1), discount[:amount])
      end
    end

    @ranges.sort_by!(&:amount)
  end

  def current_discount
    @ranges.detect { |x| !x.full? }.amount
  end

  def add_by_amount(amount)
    return if amount.nil?
    range = @ranges.detect { |x| x.amount <= amount && !x.full? } || @ranges.detect { |x| !x.full? }
    range.add
  end
end

DiscountRange = Struct.new(:slots, :amount) do
  def add
    @recorded_discounts += 1
  end

  def full?
    @recorded_discounts ||= 0
    !slots.nil? && @recorded_discounts >= slots
  end
end
