#
# Extra code loaded for Rake.
#
$:.unshift(File.expand_path(File.join('samples')))

#
# Testing tasks.
#
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

#
# Sample tasks.
#
Dir.glob('samples/**/Rakefile') do |rf|
  import rf
end

#
# Default task.
#
task :default => :spec

