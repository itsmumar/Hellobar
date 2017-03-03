require 'spec_helper'

describe Font do
  describe '#guess' do
    it 'should guess correctly with the first value' do
      expect(Font.guess('Arial')).to eq(Font.find('arial'))
    end

    it 'should guess correctly using the second value' do
      expect(Font.guess('monkey,Arial')).to eq(Font.find('arial'))
    end

    it 'should be case-insensitive' do
      expect(Font.guess('ARIAL')).to eq(Font.find('arial'))
      expect(Font.guess('arial')).to eq(Font.find('arial'))
    end

    it 'should ignore extra spaces' do
      expect(Font.guess('monkey, Arial')).to eq(Font.find('arial'))
    end

    it "should return nil when it can't find a match" do
      expect(Font.guess('monkey')).to be_nil
    end
  end
end
