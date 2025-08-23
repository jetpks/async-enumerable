# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

desc "Run benchmarks"
task :benchmark do
  puts "Running benchmark comparison..."
  system("ruby benchmark/comparison.rb")
end

desc "Run benchmarks with benchmark-driver"
task :benchmark_driver do
  puts "Running benchmarks with benchmark-driver..."
  system("benchmark-driver benchmark/*.yml")
end
