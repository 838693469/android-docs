from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess

class irq(plugin):
    additional_colors = """
"""
    additional_ftrace_parsers = [
        ]

    additional_process_types = {
        "irq":(tcProcess, IRQ_CLASS),
        "softirq":(tcProcess, IRQ_CLASS),
        "work":(tcProcess, WORK_CLASS),
        }
    @staticmethod
    def do_event_irq_handler_entry(self,event,soft=""):
        process = self.generic_find_process(0,"%sirq%d:%s"%(soft,event.irq,event.name),soft+"irq")
        self.last_irq[(event.irq,soft)] = process
        self.generic_process_start(process,event)
    @staticmethod
    def do_event_irq_handler_exit(self,event,soft=""):
        try:
            process = self.last_irq[(event.irq,soft)]
        except KeyError:
            print "error did not find last irq"
            print self.last_irq.keys(),(event.irq,soft)
            return
        self.generic_process_end(process,event)
        try:
            if event.ret=="unhandled":
                process['types'][-1]=4
	except:
	    pass
    @staticmethod
    def do_event_softirq_entry(self,event):
        event.irq = event.vec
        return irq.do_event_irq_handler_entry(self,event,"soft")
    @staticmethod
    def do_event_softirq_exit(self,event):
        event.irq = event.vec
        return irq.do_event_irq_handler_exit(self,event,"soft")

    @staticmethod
    def do_event_workqueue_execution(self,event):
        process = self.generic_find_process(0,"work:%s"%(event.func),"work")
        self.generic_process_start(process,event)
        self.generic_process_end(process,event)

    @staticmethod
    def do_event_softirq_raise(self,event):
        p_stack = self.cur_process[event.common_cpu]
        softirqname = "softirq:%d:%s"%(event.vec,event.name)
        if p_stack:
            p = p_stack[-1]
            self.wake_events.append(((p['comm'],p['pid']),(softirqname,0),event.timestamp))
        else:
            p = self.generic_find_process(0,softirqname+" raise","softirq")
            self.generic_process_single_event(p,event)

plugin_register(irq)
