require 'rake'

shared_context 'rake' do
  before { Rake::Task.define_task(:environment) }
  let(:task) { Rake.application[self.class.description] }
  after { task.reenable }
end
