from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess, _pretty_time
from enthought.traits.api import Bool

c_state_table = ["C0","C1","C2","C4","C6","S0i1","S0i3"]

#by default it is hidden...
class tcCpuIdle(tcProcess):
    show = Bool(False)
    def _get_name(self):
        return "%s (%s)"%(self.comm, _pretty_time(self.total_time))

class cpu_idle(plugin):
    additional_colors = """
C0			#000000
C1			#bbbbff
C2			#7777ff
C3			#5555ff
C4			#3333ff
C5			#1111ff
C6			#0000ff
S0i3			#0011ff
S0i1			#0022ff
cpuidle_bg		#ffdddd
cpufreq_bg		#ffddee
"""
    additional_ftrace_parsers = [
        ('power_start',   'type=%d state=%d', 'type','state'),
        ('power_frequency',   'type=%d state=%d', 'type','state'),
        #('power_end', 'nothing interesting to parse'),
        ('cpu_idle',  'state=%d cpu_id=%d', 'state', 'cpuid'),
        ('cpu_frequency',  'state=%d cpu_id=%d', 'state', 'cpuid'),
        ]

    additional_process_types = {
        "cpuidle":(tcCpuIdle,POWER_CLASS),
        "cpufreq":(tcCpuIdle,POWER_CLASS),
        }

    @staticmethod
    def start_cpu_idle(self, event):
        try:
            tc = self.tmp_c_states[event.cpuid]
        except:
            self.ensure_cpu_allocated(event.cpuid)
            tc = self.tmp_c_states[event.cpuid]
        if len(tc['start_ts'])>len(tc['end_ts']):
            tc['end_ts'].append(event.timestamp)
            self.missed_power_end +=1
            if self.missed_power_end < 10:
                print "warning: missed cpu_idle end"
            if self.missed_power_end == 10:
                print "warning: missed cpu_idle end: wont warn anymore!"
        name = c_state_table[int(event.state)]
        tc['start_ts'].append(event.timestamp)
        tc['types'].append(colors.get_color_id(name))
        process = self.generic_find_process(0,"cpu%d/%s"%(event.cpuid,name),"cpuidle")
        self.generic_process_start(process,event, build_p_stack=False)
    @staticmethod
    def stop_cpu_idle(self, event):
        try:
            tc = self.tmp_c_states[event.cpuid]
        except:
            self.ensure_cpu_allocated(event.cpuid)
            tc = self.tmp_c_states[event.cpuid]
        if len(tc['start_ts'])>len(tc['end_ts']):
            name = colors.get_colorname_by_id(tc['types'][-1])
            tc['end_ts'].append(event.timestamp)
            process = self.generic_find_process(0,"cpu%d/%s"%(event.cpuid,name),"cpuidle")
            self.generic_process_end(process,event, build_p_stack=False)

    # stable event support
    @staticmethod
    def do_event_cpu_idle(self,event):
        if event.state != 4294967295 :
            cpu_idle.start_cpu_idle(self, event)
        else :
            cpu_idle.stop_cpu_idle(self, event)

    # legacy event support
    @staticmethod
    def do_event_power_start(self,event):
        event.cpuid = event.common_cpu
        if event.type==1:# c_state
            cpu_idle.start_cpu_idle(self, event)


    @staticmethod
    def do_event_power_end(self,event):
        event.cpuid = event.common_cpu
        cpu_idle.stop_cpu_idle(self, event)
    @staticmethod
    def do_all_events(self,event):
        event.cpuid = event.common_cpu
        cpu_idle.stop_cpu_idle(self, event)

    @staticmethod
    def do_event_cpu_frequency(self,event):
        self.ensure_cpu_allocated(event.common_cpu)
        tc = self.tmp_p_states[event.cpuid]
        if len(tc['types']) > 0:
            name = tc['types'][-1]
            process = self.generic_find_process(0,"cpu%d/freq:%s"%(event.cpuid,name),"cpufreq")
            self.generic_process_end(process,event, build_p_stack=False)
        tc['start_ts'].append(event.timestamp)
        tc['types'].append(event.state)
        name = event.state
        process = self.generic_find_process(0,"cpu%d/freq:%s"%(event.cpuid,name),"cpufreq")
        self.generic_process_start(process,event, build_p_stack=False)
    @staticmethod
    def do_event_power_frequency(self,event):
        if event.type==2:# p_state
            event.cpuid = event.common_cpu
            cpu_idle.do_event_cpu_frequency(self, event)

plugin_register(cpu_idle)
