guard :rspec, cmd: 'rspec' do
  watch(%r{^lib/(.+).rb$})      { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^spec/(.+).rb$})     { |m| "spec/#{m[1]}.rb" }
  watch('spec/spec_helper.rb')  { 'spec' }
  watch('Gemfile')
end

guard :rubocop, all_on_start: false, cli: ['--format', 'clang'] do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
