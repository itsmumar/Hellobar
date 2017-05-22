# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'service_providers/version'

Gem::Specification.new do |spec|
  spec.name = 'service_providers'
  spec.version = ServiceProviders::VERSION
  spec.authors = ['Anton Sozontov']
  spec.email = ['anton.sozontov@crossover.com']

  spec.summary = 'Service Providers adapters'
  spec.description = 'Service Providers adapters'
  spec.homepage = 'https://github.com/Hello-bar/hellobar_new'
  spec.license = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  unless spec.respond_to?(:metadata)
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.metadata['allowed_push_host'] = ''

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(/^(test|spec|features)\//)
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(/exe\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'vcr', '~> 3.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'activesupport', '~> 4.2'
end
