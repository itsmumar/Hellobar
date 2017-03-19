RSpec.shared_examples 'a model triggering script regeneration' do
  let(:model) { create described_class.table_name.singularize }

  it 'triggers static script regeneration when changed' do
    site = model.site
    site.instance_variable_set :@needs_script_regeneration, false

    expect(site.needs_script_regeneration?).to be_falsey

    model.touch

    expect(site.needs_script_regeneration?).to be_truthy
  end
end
