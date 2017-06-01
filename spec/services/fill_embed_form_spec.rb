describe FillEmbedForm do
  let(:service) { described_class.new('embed_code', email: 'email@example.com', name: 'FirstName LastName') }
  let(:inputs) do
    [
      { name: 'foo', value: nil },
      { name: 'bar', value: nil },
      { name: 'fields_email', value: nil },
      { name: 'fields_fname', value: nil },
      { name: 'fields_lname', value: nil },
      { name: 'email', value: nil },
      { name: 'Submit', value: 'Submit' }
    ]
  end

  let(:form) { ExtractEmbedForm::Form.new nil, inputs, nil }

  before do
    allow(ExtractEmbedForm).to receive(:new).with('embed_code').and_return(double(call: form))
  end

  describe '#call' do
    it 'returns filled inputs as name => value' do
      expect(service.call).to match(
        'foo' => nil,
        'bar' => nil,
        'fields_email' => 'email@example.com',
        'fields_fname' => 'FirstName',
        'fields_lname' => 'LastName',
        'email' => nil,
        'Submit' => 'Submit'
      )
    end
  end
end
