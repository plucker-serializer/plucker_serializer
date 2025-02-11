# frozen_string_literal: true

require 'benchmark/ips'
require 'json'
require 'memory_profiler'

module Benchmark
  module Runner
    def run(label = nil, time: 10, disable_gc: true, warmup: 3, &block)
      raise ArgumentError.new, 'block should be passed' unless block_given?

      GC.start

      if disable_gc
        GC.disable
      else
        GC.enable
      end

      memory_report = MemoryProfiler.report(&block)

      report = Benchmark.ips(time, warmup, true) do |x|
        x.report(label, &block)
      end

      results = {
        label: label,
        ips: ActiveSupport::NumberHelper.number_to_delimited(report.entries.first.ips.round(2)),
        allocs: "#{memory_report.total_allocated}/#{memory_report.total_retained}"
      }.to_json

      puts results
    end
  end

  extend Benchmark::Runner
end
