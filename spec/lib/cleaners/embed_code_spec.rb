describe Cleaners::EmbedCode do
  subject { create(:contact_list, :embed_code) }
  let(:embed_code) { 'Here I am' }

  before do
    subject.provider_token = 'mad_mimi_form'
    subject.data['embed_code'] = embed_code
    expect(subject.service_provider).not_to be_nil
    subject.save!
  end

  context 'curly quotes' do
    let(:embed_code) do
      '<html><body><iframe><form>“I want to go to the gym”, he said.</form></iframe></body></html>'
    end

    describe '#data' do
      it { expect(subject.data).to eql 'embed_code' => embed_code.tr!('“”', '"') }
    end
  end
end
