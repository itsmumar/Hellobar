require 'spec_helper'

describe ServiceProviders::GetResponseApi do
  it 'raises error if identity is missing api key'

  context 'lists' do
    it 'makes request to get list of campaigns'
    it 'returns hash array of hashes of ids and names'
    it 'handles time out'
    it 'logs parsed error message in the event of failed request'
  end

  context 'subscribe' do
    it 'posts request with correct params'
    it 'logs parsed error message in the event of failed request'
    it 'handles time out'
  end
end
