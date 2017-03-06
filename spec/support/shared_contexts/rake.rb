require 'rake'

shared_context 'rake' do
  before { Rake::Task.define_task(:environment) }
  subject { Rake.application[self.class.description] }
  after { subject.reenable }
end
