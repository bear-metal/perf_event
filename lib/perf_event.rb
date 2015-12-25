require 'perf_event/version' unless defined? PerfEvent::VERSION
require 'perf_event/perf_event_ext'

class PerfEvent
  def trace(*events)
    reset
    events.each{|e| enable(e) }
    yield
    report
  end

  def trace_all
    trace(*TRACE_ALL_EVENTS){ yield }
  end

  def trace_hardware
    trace(*TRACE_HW_EVENTS){ yield }
  end

  def trace_software
    trace(*TRACE_SW_EVENTS){ yield }
  end
end