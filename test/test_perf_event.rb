require 'perf_event'
begin
  require 'minitest/autorun'
rescue LoadError
  require 'minitest'
end

class TestPerfEvent < Minitest::Test
  def test_events
    expected = {
      0  => "This reports the CPU clock, a high-resolution per-CPU timer.",
      1  => "This reports a clock count specific to the task that is running.",
      2  => "This reports the number of page faults.",
      3  => "This counts context switches.",
      4  => "This reports the number of times the process has migrated to a new CPU.",
      5  => "This counts the number of minor page faults. These did not require disk I/O to handle.",
      6  => "This counts the number of major page faults. These required disk I/O to handle.",
      7  => "This counts the number of alignment faults. These happen on unaligned memory accesses.",
      8  => "This counts the number of emulation faults. This can negatively impact performance.",
      9  => "Total cycles. Be wary of what happens during CPU frequency scaling.",
      10 => "Retired instructions. Can be affected by hardware interrupts.",
      11 => "Cache accesses.",
      12 => "Cache misses.",
      13 => "Retired branch instructions.",
      14 => "Mispredicted branch instructions.",
      15 => "Bus cycles, which can be different from total cycles.",
      16 => "Stalled cycles during issue.",
      17 => "Stalled cycles during retirement.",
      18 => "Total cycles. Not affected by CPU frequency scaling."
    }
    assert_equal expected, PerfEvent::EVENTS
  end

  def test_events_map
    expected = {0=>:PERF_COUNT_SW_CPU_CLOCK, :PERF_COUNT_SW_CPU_CLOCK=>0, 1=>:PERF_COUNT_SW_TASK_CLOCK, :PERF_COUNT_SW_TASK_CLOCK=>1, 2=>:PERF_COUNT_SW_PAGE_FAULTS, :PERF_COUNT_SW_PAGE_FAULTS=>2, 3=>:PERF_COUNT_SW_CONTEXT_SWITCHES, :PERF_COUNT_SW_CONTEXT_SWITCHES=>3, 4=>:PERF_COUNT_SW_CPU_MIGRATIONS, :PERF_COUNT_SW_CPU_MIGRATIONS=>4, 5=>:PERF_COUNT_SW_PAGE_FAULTS_MIN, :PERF_COUNT_SW_PAGE_FAULTS_MIN=>5, 6=>:PERF_COUNT_SW_PAGE_FAULTS_MAJ, :PERF_COUNT_SW_PAGE_FAULTS_MAJ=>6, 7=>:PERF_COUNT_SW_ALIGNMENT_FAULTS, :PERF_COUNT_SW_ALIGNMENT_FAULTS=>7, 8=>:PERF_COUNT_SW_EMULATION_FAULTS, :PERF_COUNT_SW_EMULATION_FAULTS=>8, 9=>:PERF_COUNT_HW_CPU_CYCLES, :PERF_COUNT_HW_CPU_CYCLES=>9, 10=>:PERF_COUNT_HW_INSTRUCTIONS, :PERF_COUNT_HW_INSTRUCTIONS=>10, 11=>:PERF_COUNT_HW_CACHE_REFERENCES, :PERF_COUNT_HW_CACHE_REFERENCES=>11, 12=>:PERF_COUNT_HW_CACHE_MISSES, :PERF_COUNT_HW_CACHE_MISSES=>12, 13=>:PERF_COUNT_HW_BRANCH_INSTRUCTIONS, :PERF_COUNT_HW_BRANCH_INSTRUCTIONS=>13, 14=>:PERF_COUNT_HW_BRANCH_MISSES, :PERF_COUNT_HW_BRANCH_MISSES=>14, 15=>:PERF_COUNT_HW_BUS_CYCLES, :PERF_COUNT_HW_BUS_CYCLES=>15, 16=>:PERF_COUNT_HW_STALLED_CYCLES_FRONTEND, :PERF_COUNT_HW_STALLED_CYCLES_FRONTEND=>16, 17=>:PERF_COUNT_HW_STALLED_CYCLES_BACKEND, :PERF_COUNT_HW_STALLED_CYCLES_BACKEND=>17, 18=>:PERF_COUNT_HW_REF_CPU_CYCLES, :PERF_COUNT_HW_REF_CPU_CYCLES=>18}
    assert_equal expected, PerfEvent::EVENTS_MAP
  end

  def test_sw_events
    expected = [:PERF_COUNT_SW_CPU_CLOCK, :PERF_COUNT_SW_TASK_CLOCK, :PERF_COUNT_SW_PAGE_FAULTS, :PERF_COUNT_SW_CONTEXT_SWITCHES,
                :PERF_COUNT_SW_CPU_MIGRATIONS, :PERF_COUNT_SW_PAGE_FAULTS_MIN, :PERF_COUNT_SW_PAGE_FAULTS_MAJ, :PERF_COUNT_SW_ALIGNMENT_FAULTS,
                :PERF_COUNT_SW_EMULATION_FAULTS].map{|e| PerfEvent.const_get(e) }
    assert_equal expected, PerfEvent::TRACE_SW_EVENTS
  end

  def test_hw_events
    expected = [:PERF_COUNT_HW_CPU_CYCLES, :PERF_COUNT_HW_INSTRUCTIONS, :PERF_COUNT_HW_CACHE_REFERENCES, :PERF_COUNT_HW_CACHE_MISSES,
                :PERF_COUNT_HW_BRANCH_INSTRUCTIONS, :PERF_COUNT_HW_BRANCH_MISSES, :PERF_COUNT_HW_BUS_CYCLES, :PERF_COUNT_HW_STALLED_CYCLES_FRONTEND,
                :PERF_COUNT_HW_STALLED_CYCLES_BACKEND, :PERF_COUNT_HW_REF_CPU_CYCLES].map{|e| PerfEvent.const_get(e) }
    assert_equal expected, PerfEvent::TRACE_HW_EVENTS
  end

  def test_initialize
    pe = PerfEvent.new(-1, -1)
    assert_instance_of PerfEvent, pe
    assert pe.close
  end

  def test_defined_counters
    assert_instance_of Fixnum, PerfEvent::PERF_COUNT_SW_CPU_CLOCK
  end

  def test_enable_disable_counter
    pe = PerfEvent.new(-1, -1)
    assert pe.enable(PerfEvent::PERF_COUNT_SW_CPU_CLOCK)
    assert pe.disable(PerfEvent::PERF_COUNT_SW_CPU_CLOCK)
    assert pe.close
  end

  def test_read_counter
    pe = PerfEvent.new(-1, -1)
    assert pe.enable(PerfEvent::PERF_COUNT_SW_CONTEXT_SWITCHES)
    500.times{|i| i.to_i }
    assert_instance_of Fixnum, pe.read(PerfEvent::PERF_COUNT_SW_CONTEXT_SWITCHES)
    assert pe.close
  end

  def test_report
    pe = PerfEvent.new(-1, -1)
    assert_equal({}, pe.report)
    assert pe.enable(PerfEvent::PERF_COUNT_SW_CONTEXT_SWITCHES)
    assert_equal([:PERF_COUNT_SW_CONTEXT_SWITCHES], pe.report.keys)
    assert pe.close
  end

  def test_trace
    pe = PerfEvent.new(-1, -1)
    report = pe.trace_software do
      500.times{|i| i.to_i }
    end
    assert_equal [:PERF_COUNT_SW_CPU_CLOCK, :PERF_COUNT_SW_TASK_CLOCK, :PERF_COUNT_SW_PAGE_FAULTS, :PERF_COUNT_SW_CONTEXT_SWITCHES, :PERF_COUNT_SW_CPU_MIGRATIONS, :PERF_COUNT_SW_PAGE_FAULTS_MIN, :PERF_COUNT_SW_PAGE_FAULTS_MAJ, :PERF_COUNT_SW_ALIGNMENT_FAULTS, :PERF_COUNT_SW_EMULATION_FAULTS], report.keys

    report = pe.trace_hardware do
      500.times{|i| i.to_i }
    end
    assert_equal [:PERF_COUNT_HW_CPU_CYCLES, :PERF_COUNT_HW_INSTRUCTIONS, :PERF_COUNT_HW_CACHE_REFERENCES, :PERF_COUNT_HW_CACHE_MISSES, :PERF_COUNT_HW_BRANCH_INSTRUCTIONS, :PERF_COUNT_HW_BRANCH_MISSES, :PERF_COUNT_HW_BUS_CYCLES, :PERF_COUNT_HW_REF_CPU_CYCLES], report.keys

    report = pe.trace_all do
      500.times{|i| i.to_i }
    end
    assert_equal [:PERF_COUNT_SW_CPU_CLOCK, :PERF_COUNT_SW_TASK_CLOCK, :PERF_COUNT_SW_PAGE_FAULTS, :PERF_COUNT_SW_CONTEXT_SWITCHES, :PERF_COUNT_SW_CPU_MIGRATIONS, :PERF_COUNT_SW_PAGE_FAULTS_MIN, :PERF_COUNT_SW_PAGE_FAULTS_MAJ, :PERF_COUNT_SW_ALIGNMENT_FAULTS, :PERF_COUNT_SW_EMULATION_FAULTS, :PERF_COUNT_HW_CPU_CYCLES, :PERF_COUNT_HW_INSTRUCTIONS, :PERF_COUNT_HW_CACHE_REFERENCES, :PERF_COUNT_HW_CACHE_MISSES, :PERF_COUNT_HW_BRANCH_INSTRUCTIONS, :PERF_COUNT_HW_BRANCH_MISSES, :PERF_COUNT_HW_BUS_CYCLES, :PERF_COUNT_HW_REF_CPU_CYCLES], report.keys
  end
end