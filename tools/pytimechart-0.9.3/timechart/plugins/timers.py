from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess

class timer(plugin):
    additional_colors = """
timer_bg		#e5bebe
timer	      		#ee0000
"""
    additional_ftrace_parsers = [
        ("timer_expire_entry","timer=%s function=%s now=%d","timer","function","now"),
        ("timer_expire_exit","timer=%s","timer"),
        ("hrtimer_expire_entry","timer=%s function=%s now=%d","timer","function","now"),
        ("hrtimer_expire_exit","timer=%s","timer"),
        ("hrtimer_cancel","timer=%s","timer"),
        ("hrtimer_start","hrtimer=%s function=%s expires=%d softexpires=%d","timer","function","expire","timeout"),
        ("itimer_expire","which=%d pid=%d now=%d","which","pid","now"),
        ("smp_apic_timer_interrupt","%s %s","state","func"),
        ]
    additional_process_types = {
            "timer":(tcProcess, IRQ_CLASS),
        }
    timers_dict = {}
    jitter = 0
    @staticmethod
    def do_event_timer_expire_entry(proj,event):
        process = proj.generic_find_process(0,"timer[%d]:%s"%(event.common_cpu,event.function),"timer")
        timer.timers_dict[event.timer] = process
        proj.generic_process_start(process,event,False)
        if event.event.startswith("hr"):
            event.now = event.now/1000
            timer.jitter =  event.now - event.timestamp
    @staticmethod
    def do_event_timer_expire_exit(proj,event):
        if timer.timers_dict.has_key(event.timer):
            process = timer.timers_dict[event.timer]
            proj.generic_process_end(process,event,False)
    do_event_hrtimer_expire_entry = do_event_timer_expire_entry
    do_event_hrtimer_expire_exit = do_event_timer_expire_exit
    @staticmethod
    def do_event_hrtimer_cancel(proj,event):
        if timer.timers_dict.has_key(event.timer):
            process = timer.timers_dict[event.timer]
            process = proj.generic_find_process(0,"%s:cancel"%(process["comm"]),"timer")
            proj.generic_process_start(process,event,False)
            proj.generic_process_end(process,event,False)
    @staticmethod
    def do_event_hrtimer_start(proj,event):
        if timer.timers_dict.has_key(event.timer):
            process = timer.timers_dict[event.timer]
            process = proj.generic_find_process(0,"%s:start"%(process["comm"]),"timer")
            proj.generic_process_start(process,event,False)
            proj.generic_process_end(process,event,False)

    @staticmethod
    def do_event_itimer_expire(proj,event):
        process = proj.generic_find_process(0,"itimer:%d %d"%(event.which,event.pid),"timer")
        proj.generic_process_start(process,event,False)
        proj.generic_process_end(process,event,False)

    @staticmethod
    def do_event_smp_apic_timer_interrupt(proj,event):
        if not event.__dict__.has_key("func"):
            return
        process = proj.generic_find_process(0,"apictimer[%d]:%s"%(event.common_cpu,event.func),"timer")
        if event.state == "start":
            proj.generic_process_start(process,event,False)
        else:
            proj.generic_process_end(process,event,False)
plugin_register(timer)
