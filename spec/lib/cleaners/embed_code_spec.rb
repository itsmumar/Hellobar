require 'spec_helper'

describe Cleaners::EmbedCode do
  fixtures :all

  subject { contact_lists(:embed_code) }
  let(:embed_code) { "Here I am" }

  before do
    subject.provider = 'mad_mimi_form'
    subject.data['embed_code'] = embed_code
    expect(subject.service_provider).not_to be_nil
    subject.save!
  end

  context 'curly quotes' do
    let(:embed_code) {
      "<html><body><iframe><form>“I want to go to the gym”, he said.</form></iframe></body></html>"
    }

    its(:data) { should == { 'embed_code' => embed_code.tr!('“”', '"') } }
  end
end
