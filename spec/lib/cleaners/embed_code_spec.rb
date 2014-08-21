require 'spec_helper'

describe Cleaners::EmbedCode do
  fixtures :contact_lists

  subject { contact_lists(:embed_code) }
  let(:embed_code) { "Test embed code" }
  before do
    subject.data['embed_code'] = embed_code
    subject.save!
  end

  context 'curly quotes' do
    let(:embed_code) { '“I want to go to the gym”, he said.' }
    its(:embed_code) { should == '"I want to go to the gym", he said.' }
  end
end
