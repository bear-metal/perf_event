# encoding: utf-8

# check for presence of  /proc/sys/kernel/perf_event_paranoid.

require 'mkmf'

dir_config('perf_event')

if RUBY_PLATFORM !~ /linux/
  abort "-----\n perf_event only runs on Linux\n-----"
end

abort "-----\nCannot find sys/syscall.h\n----" unless have_header('sys/syscall.h')
abort "-----\nCannot find linux/perf_event.h\n----" unless have_header('linux/perf_event.h')

@known_perf_events = {
  :PERF_COUNT_HW_CPU_CYCLES => "Total cycles. Be wary of what happens during CPU frequency scaling.",
  :PERF_COUNT_HW_INSTRUCTIONS => "Retired instructions. Can be affected by hardware interrupts.",
  :PERF_COUNT_HW_CACHE_REFERENCES => "Cache accesses.",
  :PERF_COUNT_HW_CACHE_MISSES => "Cache misses.",
  :PERF_COUNT_HW_BRANCH_INSTRUCTIONS => "Retired branch instructions.",
  :PERF_COUNT_HW_BRANCH_MISSES => "Mispredicted branch instructions.",
  :PERF_COUNT_HW_BUS_CYCLES => "Bus cycles, which can be different from total cycles.",
  :PERF_COUNT_HW_STALLED_CYCLES_FRONTEND => "Stalled cycles during issue.",
  :PERF_COUNT_HW_STALLED_CYCLES_BACKEND => "Stalled cycles during retirement.",
  :PERF_COUNT_HW_REF_CPU_CYCLES => "Total cycles. Not affected by CPU frequency scaling.",
  :PERF_COUNT_SW_CPU_CLOCK => "This reports the CPU clock, a high-resolution per-CPU timer.",
  :PERF_COUNT_SW_TASK_CLOCK => "This reports a clock count specific to the task that is running.",
  :PERF_COUNT_SW_PAGE_FAULTS => "This reports the number of page faults.",
  :PERF_COUNT_SW_CONTEXT_SWITCHES => "This counts context switches.",
  :PERF_COUNT_SW_CPU_MIGRATIONS => "This reports the number of times the process has migrated to a new CPU.",
  :PERF_COUNT_SW_PAGE_FAULTS_MIN => "This counts the number of minor page faults. These did not require disk I/O to handle.",
  :PERF_COUNT_SW_PAGE_FAULTS_MAJ => "This counts the number of major page faults. These required disk I/O to handle.",
  :PERF_COUNT_SW_ALIGNMENT_FAULTS => "This counts the number of alignment faults. These happen on unaligned memory accesses.",
  :PERF_COUNT_SW_EMULATION_FAULTS => "This counts the number of emulation faults. This can negatively impact performance."
}
@supported_perf_events = {}

def define_perf_event(f, type, event)
  event_idx = @supported_perf_events .size
  f.puts "    perf_event->attrs[#{event_idx}].type = #{type};"
  f.puts "    perf_event->attrs[#{event_idx}].config = #{event};"
  f.puts "    perf_event->attrs[#{event_idx}].size = sizeof(struct perf_event_attr);"
  f.puts "    perf_event->attrs[#{event_idx}].inherit = 1;"
  f.puts "    perf_event->attrs[#{event_idx}].disabled = 1;"
  f.puts "    perf_event->attrs[#{event_idx}].enable_on_exec = 0;"
  @supported_perf_events[event_idx] = event.to_sym
end

def have_sw_event(f, event)
   if have_const("PERF_COUNT_SW_#{event}", 'linux/perf_event.h')
     define_perf_event f, :PERF_TYPE_SOFTWARE, "PERF_COUNT_SW_#{event}"
   end
end

def have_hw_event(f, event)
   if have_const("PERF_COUNT_HW_#{event}", 'linux/perf_event.h')
     define_perf_event f, :PERF_TYPE_HARDWARE, "PERF_COUNT_HW_#{event}"
   end
end

open("perf_event_env.h", 'w'){|f|
  f.puts 'void rb_perf_event_events_init(rb_perf_event_t *perf_event, int pid, int cpu){'
    f.puts "    int i;"
    f.puts "    if (pid == -1) pid = rb_perf_event_gettid();"
    f.puts "    perf_event->pid = pid;"
    f.puts "    perf_event->cpu = cpu;"
    have_sw_event f, :CPU_CLOCK
    have_sw_event f, :TASK_CLOCK
    have_sw_event f, :PAGE_FAULTS
    have_sw_event f, :CONTEXT_SWITCHES
    have_sw_event f, :CPU_MIGRATIONS
    have_sw_event f, :PAGE_FAULTS_MIN
    have_sw_event f, :PAGE_FAULTS_MAJ
    have_sw_event f, :ALIGNMENT_FAULTS
    have_sw_event f, :EMULATION_FAULTS

    have_hw_event f, :CPU_CYCLES
    have_hw_event f, :INSTRUCTIONS
    have_hw_event f, :CACHE_REFERENCES
    have_hw_event f, :CACHE_MISSES
    have_hw_event f, :BRANCH_INSTRUCTIONS
    have_hw_event f, :BRANCH_MISSES
    have_hw_event f, :BUS_CYCLES
    have_hw_event f, :STALLED_CYCLES_FRONTEND
    have_hw_event f, :STALLED_CYCLES_BACKEND
    have_hw_event f, :REF_CPU_CYCLES
    f.puts "    for (i = 0; i < SUPPORTED_PERF_EVENTS; i++){";
    f.puts "        perf_event->fds[i] = -1;"
    f.puts "        perf_event->fds[i] = rb_perf_event_open(&perf_event->attrs[i], pid, cpu, -1, 0);"
    f.puts "    }"
  f.puts "}"
}

open("perf_event_consts.h", 'w'){|f|
  @supported_perf_events.each do |idx, event|
    f.puts "define_#{(event =~ /_HW_/ ? 'hw' : 'sw')}_counter(#{event}, #{idx}, \"#{@known_perf_events[event]}\");"
  end
}

$defs.push("-DSUPPORTED_PERF_EVENTS=#{@supported_perf_events.size}")

create_makefile('perf_event/perf_event_ext')
