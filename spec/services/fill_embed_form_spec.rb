describe FillEmbedForm do
  let(:service) { described_class.new(form, email: 'email@example.com', name: 'FirstName LastName') }
  let(:inputs) do
    {
      'foo' => '',
      'bar' => '',
      'fields_email' => '',
      'fields_fname' => '',
      'fields_lname' => '',
      'email' => '',
      'Submit' => 'Submit'
    }
  end

  let(:form) { EmbedForm.new nil, inputs, nil }

  describe '#call' do
    let(:filled_form) do
      {
        'foo' => '',
        'bar' => '',
        'fields_email' => 'email@example.com',
        'fields_fname' => 'FirstName',
        'fields_lname' => 'LastName',
        'email' => '',
        'Submit' => 'Submit'
      }
    end

    let(:filled_form) { EmbedForm.new nil, inputs, nil }

    it 'returns filled inputs as name => value' do
      expect(service.call).to match(filled_form)
    end
  end
end
