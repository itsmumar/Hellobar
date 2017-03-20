namespace :backend do
  desc 'Generate the missing rspec files from base tempaltes'
  task :generate_missing_specs do
    require 'missing_spec_generator'
    msg = MissingSpecGenerator.new
    msg.generate_missing_helper_specs
    msg.generate_missing_controller_specs
    msg.generate_missing_model_specs
  end
end
