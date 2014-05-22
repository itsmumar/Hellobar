shared_examples_for :embeddable_content do
  let(:model) { described_class }

  it 'raises an error if content_name is not defined' do
    model.remove_instance_variable("@content_name") if model.instance_variable_defined?('@content_name')

    expect {
      model.content_name
    }.to raise_error('implement me')
  end

  it 'does NOT raise an error if content_name is defined' do
    model.content_name = 'hello'

    expect {
      model.content_name
    }.to_not raise_error
  end
end
