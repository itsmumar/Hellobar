
require 'erb'

class MissingSpecGenerator
  def spec_file(spec_path, file_name, spec_template, namespace)
    spec_name = file_name.gsub('.rb', '') + '_spec.rb'
    if File.exist?("#{spec_path}/#{spec_name}")
      logger.info "#{spec_path}/#{spec_name} exists"
    else
      logger.info "#{spec_path}/#{spec_name} missing"
      logger.info "\n"
      spec_file = ERB.new(spec_template)
      class_name = "#{namespace}#{file_name.gsub('.rb', '').camelcase}"
      spec = spec_file.result(binding)
      logger.info spec
      FileUtils.mkdir_p(spec_path) unless File.exist?(spec_path)
      File.open("#{spec_path}/#{spec_name}", 'w') { |f| f.write(spec) }
    end
  end

  def traverse_specs(path, spec_template, namespace = '')
    Dir.open(Rails.root + 'app/' + path).each do |file_name|
      next if file_name =~ /^\./ # skip hidden folders (.svn)
      if File.directory?(Rails.root + 'app/' + path + '/' + file_name)
        traverse_specs("#{path}/#{file_name}", spec_template,
          "#{namespace}#{file_name.camelcase}::")
        next
      end
      spec_file("#{Rails.root}/spec/#{path}",
        file_name, spec_template, namespace)
    end
  end

  def generate_missing_helper_specs
    helper_template = %q{require 'spec_helper'
      describe <%= class_name %> do
        #Delete this example and add some real ones or delete this file
        it "should be included in the object returned by #helper" do
          included_modules = (class << helper; self; end).send :included_modules
          included_modules.should include(<%= class_name %>Helper)
        end
      end
      }.gsub(/^      /, '')
    traverse_specs('helpers', helper_template)
  end

  def generate_missing_controller_specs
    controller_template = %q{require 'spec_helper'
      describe <%= class_name %> do
        #Delete this example and add some real ones
        it "should use <%= class_name %>" do
          controller.should be_an_instance_of(<%= class_name %>)
        end
      end
      }.gsub(/^      /, '')
    traverse_specs('controllers', controller_template)
  end

  def generate_missing_model_specs
    model_template = %q{require 'spec_helper'
      describe <%= class_name %> do
        before(:each) { @valid_attributes = { } }
        it "should create a new instance given valid attributes" do
          <%= class_name %>.create!(@valid_attributes)
        end
      end
      }.gsub(/^      /, '')
    traverse_specs('models', model_template)
  end
end
