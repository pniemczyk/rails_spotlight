# frozen_string_literal: true

require_relative 'lib/rails_spotlight/version'

Gem::Specification.new do |spec|
  spec.name = 'rails_spotlight'
  spec.version = RailsSpotlight::VERSION
  spec.authors = ['Pawel Niemczyk']
  spec.email = ['pniemczyk.info@gmail.com']

  spec.summary = 'Lets have a look at your rails application in details'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/pniemczyk/rails_spotlight'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = [spec.homepage, 'blob', 'master', 'CHANGELOG.md'].join('/')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rack-contrib', '>= 1.1', '< 3'
  spec.add_dependency 'railties', '>= 3.0.0', '< 7.1'
  spec.add_runtime_dependency 'meta_request', '~> 0.7'
  spec.add_development_dependency 'awesome_print', '~> 1.6'
  spec.add_development_dependency 'guard', '~> 2.12'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2'
  spec.add_development_dependency 'rspec', '~> 3.8.0'
  spec.add_development_dependency 'rubocop', '~> 0.74.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
