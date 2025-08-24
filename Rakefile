# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

desc "Run quick benchmark overview"
task :benchmark_quick do
  require "benchmark"
  require_relative "lib/async/enumerable"

  # Simulate IO operations with random delays
  def io_operation(n)
    sleep(rand / 1000.0) # Sleep 0-1ms to simulate IO
    n * 2
  end

  def expensive_check(n)
    sleep(rand / 1000.0) # Sleep 0-1ms to simulate IO
    n % 10 == 0
  end

  puts "AsyncEnumerable Benchmark Comparison"
  puts "=" * 50
  puts "Simulating IO operations with 0-1ms delays"
  puts

  # Test different array sizes
  [10, 100, 1000, 10000].each do |size|
    array = (1..size).to_a

    puts "\nArray size: #{size} elements"
    puts "-" * 30

    Benchmark.bm(20) do |x|
      # Map benchmark
      x.report("sync map:") do
        array.map { |n| io_operation(n) }
      end

      x.report("async map:") do
        array.async.map { |n| io_operation(n) }
      end

      # For very large collections, also test with custom max_fibers
      if size >= 1000
        x.report("async map (100f):") do
          array.async(max_fibers: 100).map { |n| io_operation(n) }
        end
      end

      # Select benchmark
      x.report("sync select:") do
        array.select { |n| expensive_check(n) }
      end

      x.report("async select:") do
        array.async.select { |n| expensive_check(n) }
      end

      # Any? benchmark (with early termination)
      x.report("sync any?:") do
        array.any? { |n| expensive_check(n) }
      end

      x.report("async any?:") do
        array.async.any? { |n| expensive_check(n) }
      end

      # Find benchmark (with early termination)
      target = size / 2
      x.report("sync find:") do
        array.find { |n| n == target }
      end

      x.report("async find:") do
        array.async.find { |n|
          sleep(rand / 1000.0)
          n == target
        }
      end
    end
  end

  puts "\n" + "=" * 50
  puts "Note: Async methods show performance benefits when:"
  puts "  - Operations involve IO (network, disk, etc.)"
  puts "  - Collection size is large enough to offset async overhead"
end

desc "Run detailed benchmarks with clear comparisons"
task :benchmark do
  puts "=" * 80
  puts "AsyncEnumerable Benchmarks"
  puts "=" * 80
  puts

  # Size comparison benchmarks
  puts "📊 varying collection sizes"
  puts "-" * 40
  puts "\nThese benchmarks compare sync vs async performance across different collection sizes."
  puts "IO operations are simulated with sleep delays.\n\n"

  Dir.glob("benchmark/size_comparison/*.yaml").sort.each do |file|
    size = File.basename(file, ".yaml").split("_").last
    puts "\nCollection Size: #{size} items"
    system("bundle exec benchmark-driver #{file} 2>/dev/null")
  end

  # Early termination benchmarks
  puts "\n\n" + "=" * 80
  puts "⚡ early termination benchmarks"
  puts "-" * 40
  puts "\nThese benchmarks test methods that can terminate early (any?, find, etc.)."
  puts "They demonstrate async performance benefits even with early termination.\n\n"

  Dir.glob("benchmark/early_termination/*.yaml").sort.each do |file|
    name = File.basename(file, ".yaml").tr("_", " ")
    puts "\n#{name}"
    system("bundle exec benchmark-driver #{file} 2>/dev/null")
  end
end
