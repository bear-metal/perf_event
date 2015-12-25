# encoding: utf-8

require 'rubygems' unless defined?(Gem)
require 'rake' unless defined?(Rake)

require 'rake/extensiontask'
require 'rake/testtask'

Rake::ExtensionTask.new('perf_event') do |ext|
  ext.name = 'perf_event_ext'
  ext.ext_dir = 'ext/perf_event'
  ext.lib_dir = "lib/perf_event"
  CLEAN.include 'lib/**/perf_event_ext.*'
end

desc 'Run perf_event tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = "test/**/test_*.rb"
  t.verbose = true
  t.warning = true
end

namespace :debug do
  desc "Run the test suite under gdb"
  task :gdb do
    system "gdb --args ruby rake"
  end
end

task :test => :compile
task :default => :test