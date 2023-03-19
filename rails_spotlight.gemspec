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
  spec.required_ruby_version = '>= 3.2.0'

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

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
