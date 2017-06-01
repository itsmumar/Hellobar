describe FillEmbedForm do
  let(:service) { described_class.new(form, email: 'email@example.com', name: 'FirstName LastName') }
  let(:inputs) do
    {
      'foo' => nil,
      'bar' => nil,
      'fields_email' => nil,
      'fields_fname' => nil,
      'fields_lname' => nil,
      'email' => nil,
      'Submit' => 'Submit'
    }
  end

  let(:form) { EmbedForm.new nil, inputs, nil }

  describe '#call' do
    let(:filled_form) do
      {
        'foo' => nil,
        'bar' => nil,
        'fields_email' => 'email@example.com',
        'fields_fname' => 'FirstName',
        'fields_lname' => 'LastName',
        'email' => nil,
        'Submit' => 'Submit'
      }
    end

    let(:filled_form) { EmbedForm.new nil, inputs, nil }

    it 'returns filled inputs as name => value' do
      expect(service.call).to match(filled_form)
    end
  end
end
