describe Autofill do
  it { is_expected.to validate_presence_of :site }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :listen_selector }
  it { is_expected.to validate_presence_of :populate_selector }

  it_behaves_like 'a model triggering script regeneration'
end
