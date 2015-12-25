#ifndef PERF_EVENT_EXT_H
#define PERF_EVENT_EXT_H

#include "ruby/ruby.h"
#include "ruby/debug.h"

extern VALUE rb_cPerfEvent;

#include <fcntl.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stropts.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <linux/perf_event.h>

typedef struct {
    int fds[SUPPORTED_PERF_EVENTS];
    struct perf_event_attr attrs[SUPPORTED_PERF_EVENTS];
    pid_t pid;
    int cpu;
    VALUE enabled;
} rb_perf_event_t;

#define GetPerfEvent(obj) \
    rb_perf_event_t *perf_event = NULL; \
    Data_Get_Struct(obj, rb_perf_event_t, perf_event); \
    if (!perf_event) rb_raise(rb_eTypeError, "uninitialized PerfEvent instance!");

#define AssertPerfEvent(event) do {\
    Check_Type(event, T_FIXNUM); \
    counter = NUM2INT(event); \
    if (!(counter >= 0 && counter < SUPPORTED_PERF_EVENTS)) rb_raise(rb_eTypeError, "invalid perf event %d (should be between 0 and %d)!", counter, SUPPORTED_PERF_EVENTS); \
} while (0)

#define define_counter(counter, value, desc) do {\
    rb_const_set(rb_cPerfEvent, rb_intern(#counter), INT2NUM(value)); \
    rb_hash_aset(rb_const_get(rb_cPerfEvent, rb_intern("EVENTS")), INT2NUM(value), rb_str_new2(desc)); \
    rb_hash_aset(rb_const_get(rb_cPerfEvent, rb_intern("EVENTS_MAP")), INT2NUM(value), ID2SYM(rb_intern(#counter))); \
    rb_hash_aset(rb_const_get(rb_cPerfEvent, rb_intern("EVENTS_MAP")), ID2SYM(rb_intern(#counter)), INT2NUM(value)); \
    rb_ary_push(rb_const_get(rb_cPerfEvent, rb_intern("TRACE_ALL_EVENTS")), INT2NUM(value)); \
} while (0)

#define define_sw_counter(counter, value, desc) do {\
    define_counter(counter, value, desc); \
    rb_ary_push(rb_const_get(rb_cPerfEvent, rb_intern("TRACE_SW_EVENTS")), INT2NUM(value)); \
} while (0)

#define define_hw_counter(counter, value, desc) do {\
    define_counter(counter, value, desc); \
    rb_ary_push(rb_const_get(rb_cPerfEvent, rb_intern("TRACE_HW_EVENTS")), INT2NUM(value)); \
} while (0)

inline pid_t rb_perf_event_gettid();
long rb_perf_event_open(struct perf_event_attr *event, pid_t pid, int cpu, int group_fd, unsigned long flags);

#endif