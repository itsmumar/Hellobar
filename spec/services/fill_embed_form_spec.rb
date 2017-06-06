describe FillEmbedForm do
  let(:delete) { [] }
  let(:ignore) { [] }

  let(:inputs_in) do
    {
      'foo' => '',
      'bar' => '',
      'fields_email' => '',
      'fields_fname' => '',
      'fields_lname' => '',
      'name' => '',
      'email' => '',
      'Submit' => 'Submit'
    }
  end

  let(:service) do
    form = EmbedForm.new nil, inputs_in, nil
    described_class.new(form, email: 'email@example.com', name: 'FirstName LastName', delete: delete, ignore: ignore)
  end
  let(:filled_inputs) { service.call.inputs }

  describe '#call' do
    let(:inputs) do
      {
        'foo' => '',
        'bar' => '',
        'fields_email' => 'email@example.com',
        'fields_fname' => 'FirstName',
        'fields_lname' => 'LastName',
        'name' => 'FirstName LastName',
        'email' => '',
        'Submit' => 'Submit'
      }
    end

    it 'returns filled inputs as name => value' do
      expect(filled_inputs).to match(inputs)
    end

    context 'with delete: option' do
      let(:delete) { ['foo', 'bar'] }

      it 'does not return given inputs' do
        expect(filled_inputs).not_to include 'foo'
        expect(filled_inputs).not_to include 'bar'
      end
    end

    context 'with ignore: option' do
      let(:ignore) { ['fields_email'] }

      it 'does not fill given inputs' do
        expect(filled_inputs['fields_email']).to be_blank
        expect(filled_inputs['email']).to eql 'email@example.com'
      end
    end
  end
end
