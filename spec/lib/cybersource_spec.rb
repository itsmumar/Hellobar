require 'spec_helper'

class CyberSourceCreditCardValidator < ActiveModel::Validator; end

describe CyberSourceCreditCard do
  describe '#token_present?' do
    it 'returns true when data is present, and token is present' do
      cscc = CyberSourceCreditCard.new data: { 'token' => 'my_cool_token' }
      expect(cscc.token_present?).to be_true
    end
    it 'returns false when data is present, and token is not present' do
      cscc = CyberSourceCreditCard.new data: {}
      expect(cscc.token_present?).to be_false
    end
    it 'returns false when data is not present' do
      cscc = CyberSourceCreditCard.new
      expect(cscc.token_present?).to be_false
    end
  end

  describe '#delete_token' do
    it 'deletes token when it is present' do
      cscc = CyberSourceCreditCard.new data: { 'token' => 'my_cool_token' }
      cscc.save(validate: false)
      cscc.reload.delete_token
      expect(cscc.reload.token).to be_nil
    end
  end
end
