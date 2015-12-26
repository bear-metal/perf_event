#include "perf_event_ext.h"
#include "perf_event_env.h"

VALUE rb_cPerfEvent;

inline pid_t rb_perf_event_gettid()
{
    return syscall(SYS_gettid);
}

long rb_perf_event_open(struct perf_event_attr *event, pid_t pid, int cpu, int group_fd, unsigned long flags)
{
    return syscall(__NR_perf_event_open, event, pid, cpu, group_fd, flags);
}

static void rb_mark_perf_event(void *ptr)
{
  rb_perf_event_t *perf_event = (rb_perf_event_t *)ptr;
  if (perf_event) {
      rb_gc_mark(perf_event->enabled);
  }
}

static void _rb_perf_event_close(rb_perf_event_t *perf_event)
{
    int i;
    for (i = 0; i < SUPPORTED_PERF_EVENTS; i++)
    {
        close(perf_event->fds[i]);
    }
}

static void rb_free_perf_event(void *ptr)
{
    rb_perf_event_t *perf_event = (rb_perf_event_t *)ptr;
    if (perf_event){
        _rb_perf_event_close(perf_event);
        xfree(perf_event);
    }
}

static VALUE rb_perf_event_s_new(VALUE obj, VALUE pid, VALUE cpu)
{
    rb_perf_event_t *perf_event = NULL;
    Check_Type(pid, T_FIXNUM);
    Check_Type(cpu, T_FIXNUM);
    obj = Data_Make_Struct(rb_cPerfEvent, rb_perf_event_t, rb_mark_perf_event, rb_free_perf_event, perf_event);
    perf_event->pid = -1;
    perf_event->cpu = -1;
    perf_event->enabled = rb_hash_new();
    rb_perf_event_events_init(perf_event, NUM2INT(pid), NUM2INT(cpu));
    rb_obj_call_init(obj, 0, NULL);
    return obj;
}

static VALUE rb_perf_event_enablecounter(VALUE obj, VALUE event)
{
    int ret;
    int counter;
    GetPerfEvent(obj);
    AssertPerfEvent(event);
    ret = ioctl(perf_event->fds[counter], PERF_EVENT_IOC_ENABLE);
    if (ret == 0){
        rb_hash_aset(perf_event->enabled, rb_hash_aref(rb_const_get(rb_cPerfEvent, rb_intern("EVENTS_MAP")), event), Qnil);
        return Qtrue;
    }
    return Qfalse;
}

static VALUE rb_perf_event_disablecounter(VALUE obj, VALUE event)
{
    int ret;
    int counter;
    GetPerfEvent(obj);
    AssertPerfEvent(event);
    if (perf_event->fds[counter] == -1) return Qfalse;
    ret = ioctl(perf_event->fds[counter], PERF_EVENT_IOC_DISABLE);
    if (ret == 0){
        rb_hash_delete(perf_event->enabled, rb_hash_aref(rb_const_get(rb_cPerfEvent, rb_intern("EVENTS_MAP")), event));
        return Qtrue;
    }
    return Qfalse;
}

static VALUE rb_perf_event_read(VALUE obj, VALUE event)
{
    uint64_t value;
    int ret;
    int counter;
    GetPerfEvent(obj);
    Check_Type(event, T_FIXNUM);
    counter = NUM2INT(event);
    if (!(counter >= 0 && counter < SUPPORTED_PERF_EVENTS)) rb_raise(rb_eTypeError, "invalid perf event %d (should be between 0 and %d)!", counter, SUPPORTED_PERF_EVENTS);
    ret = read(perf_event->fds[counter], &value, sizeof(uint64_t));
    if (ret == sizeof(uint64_t)) return LONG2FIX(value);
    return 0;
}

static int rb_perf_event_reset_i(VALUE c, VALUE val, VALUE obj)
{
    int counter;
    GetPerfEvent(obj);
    counter = FIX2INT(val);
    if (perf_event->fds[counter] == -1) return ST_CONTINUE;
    ioctl(perf_event->fds[counter], PERF_EVENT_IOC_RESET);
    return ST_CONTINUE;
}

static int rb_perf_event_set(VALUE counter, VALUE val, VALUE obj)
{
    GetPerfEvent(obj);
    rb_hash_aset(perf_event->enabled, counter, rb_perf_event_read(obj, rb_hash_aref(rb_const_get(rb_cPerfEvent, rb_intern("EVENTS_MAP")), counter)));
    return ST_CONTINUE;
}

static VALUE rb_perf_event_report(VALUE obj)
{
    GetPerfEvent(obj);
    rb_hash_foreach(perf_event->enabled, rb_perf_event_set, (VALUE)obj);
    return perf_event->enabled;
}

static VALUE rb_perf_event_reset(VALUE obj)
{
    GetPerfEvent(obj);
    rb_hash_foreach(perf_event->enabled, rb_perf_event_reset_i, (VALUE)obj);
    rb_hash_clear(perf_event->enabled);
    return Qtrue;
}

static VALUE rb_perf_event_close(VALUE obj)
{
    GetPerfEvent(obj);
    _rb_perf_event_close(perf_event);
    rb_hash_clear(perf_event->enabled);
    return Qtrue;
}

void Init_perf_event_ext()
{
    rb_cPerfEvent = rb_define_class("PerfEvent", rb_cObject);

    rb_define_const(rb_cPerfEvent, "EVENTS", rb_hash_new());
    rb_define_const(rb_cPerfEvent, "EVENTS_MAP", rb_hash_new());
    rb_define_const(rb_cPerfEvent, "TRACE_HW_EVENTS", rb_ary_new());
    rb_define_const(rb_cPerfEvent, "TRACE_SW_EVENTS", rb_ary_new());
    rb_define_const(rb_cPerfEvent, "TRACE_ALL_EVENTS", rb_ary_new());

    rb_define_singleton_method(rb_cPerfEvent, "new", rb_perf_event_s_new, 2);
    rb_define_method(rb_cPerfEvent, "enable", rb_perf_event_enablecounter, 1);
    rb_define_method(rb_cPerfEvent, "disable", rb_perf_event_disablecounter, 1);
    rb_define_method(rb_cPerfEvent, "report", rb_perf_event_report, 0);
    rb_define_method(rb_cPerfEvent, "read", rb_perf_event_read, 1);
    rb_define_method(rb_cPerfEvent, "reset", rb_perf_event_reset, 0);
    rb_define_method(rb_cPerfEvent, "close", rb_perf_event_close, 0);

#include "perf_event_consts.h"
}