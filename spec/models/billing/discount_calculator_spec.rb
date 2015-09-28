require 'spec_helper'

describe DiscountCalculator do
  let(:discount_calculator) do
    DiscountCalculator.new([
      {start: 1, end: 3, amount: 1},
      {start: 4, end: 5, amount: 2},
      {start: 6, amount: 3}
    ])
  end

  describe "#current_discount" do
    context "nothing has been added" do
      it "returns the first amount" do
        expect(discount_calculator.current_discount).to eq(1)
      end
    end

    context "the first tier has been filled" do
      before do
        discount_calculator.add_by_amount(1)
        discount_calculator.add_by_amount(1)
        discount_calculator.add_by_amount(1)
      end

      it "returns the first amount" do
        expect(discount_calculator.current_discount).to eq(2)
      end
    end

    context "all tiers have been filled" do
      before do
        discount_calculator.add_by_amount(1)
        discount_calculator.add_by_amount(1)
        discount_calculator.add_by_amount(1)
        discount_calculator.add_by_amount(2)
        discount_calculator.add_by_amount(2)
        discount_calculator.add_by_amount(3)
      end

      it "returns the last amount" do
        expect(discount_calculator.current_discount).to eq(3)
      end
    end
  end
end
