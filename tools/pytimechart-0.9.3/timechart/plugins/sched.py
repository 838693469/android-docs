from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess

class sched(plugin):
    additional_colors = """
"""
    additional_ftrace_parsers = [
        ]

    additional_process_types = {
            "kernel_process":(tcProcess, KERNEL_CLASS),
            "user_process":(tcProcess, USER_CLASS)
        }

    @staticmethod
    def do_event_sched_switch(self,event):
        # @todo differenciate between kernel and user process
        prev = self.generic_find_process(event.prev_pid,event.prev_comm,"user_process",event.timestamp-100000000)
        next = self.generic_find_process(event.next_pid,event.next_comm,"user_process",event.timestamp-100000000)

        self.generic_process_end(prev,event)

        if event.__dict__.has_key('prev_state') and event.prev_state == 'R':# mark prev to be waiting for cpu
            prev['start_ts'].append(event.timestamp)
            prev['types'].append(colors.get_color_id("waiting_for_cpu"))
            prev['cpus'].append(event.common_cpu)

        self.generic_process_start(next,event)

    @staticmethod
    def do_event_sched_wakeup(self,event):
        p_stack = self.cur_process[event.common_cpu]
        if p_stack:
            p = p_stack[-1]
            self.wake_events.append(((p['comm'],p['pid']),(event.comm,event.pid),event.timestamp))
        else:
            self.wake_events.append(((event.common_comm,event.common_pid),(event.comm,event.pid),event.timestamp))


plugin_register(sched)
