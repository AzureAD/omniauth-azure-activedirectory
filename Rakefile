#!/usr/bin/env rake

require 'rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# This can be run with `bundle exec rake spec`.
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = `git ls-files`.split("\n").select { |f| f.end_with? 'spec.rb' }
  t.rspec_opts = '--format documentation'
end

# This can be run with `bundle exec rake rubocop`.
RuboCop::RakeTask.new(:rubocop) do |t|
  t.patterns = `git ls-files`.split("\n").select { |f| f.end_with? '.rb' }
  t.fail_on_error = false
end

task default: :spec
