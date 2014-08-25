require 'spec_helper'

describe Cleaners::EmbedCode do
  fixtures :all

  subject { contact_lists(:embed_code) }
  let(:embed_code) { "Test embed code" }

  before do
    subject.provider = 'mad_mimi'
    subject.data['embed_code'] = embed_code
    expect(subject.service_provider).not_to be_nil
    subject.save!
  end

  context 'curly quotes' do
    let(:embed_code) { '“I want to go to the gym”, he said.' }
    its(:data) { should == {'embed_code' => '"I want to go to the gym", he said.' } }
  end
end
