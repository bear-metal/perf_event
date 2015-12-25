# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'perf_event/version'

Gem::Specification.new do |s|
  s.name = "perf_event"
  s.version = PerfEvent::VERSION
  s.summary = "Ruby interface to libperf, a library that exposes the kernel performance counters subsystem to userspace code"
  s.description = "Ruby interface to libperf, an API for interfacing with the perf system call in modern Linux kernels"
  s.authors = ["Bear Metal"]
  s.email = ["info@bearmetal.eu"]
  s.license = "MIT"
  s.homepage = "https://github.com/bear-metal/perf_event"
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.extensions = "ext/perf_event/extconf.rb"
  s.test_files = `git ls-files test`.split($/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.1.0'

  s.add_development_dependency('rake-compiler', '~> 0.9', '>= 0.9.5')
  s.add_development_dependency('minitest', '~> 5.8', '>= 5.8.3')
end