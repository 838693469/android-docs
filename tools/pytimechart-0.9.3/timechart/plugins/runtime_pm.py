from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess

class tcRuntimePM(tcProcess):
    def _get_name(self):
        return "%s"%(self.comm)
    def get_comment(self,i):
        return colors.get_colorname_by_id(self.types[i])[len("rpm_"):]

class runtime_pm(plugin):
    additional_colors = """
runtime_pm_bg		#e5bebe
rpm_usage=-1		#ff0000
rpm_usage=0		#eeeeee
rpm_usage=1		#FA8072
rpm_usage=2		#FFA500
rpm_usage=3		#FF8C00
rpm_usage=4		#FF7F50
rpm_usage=5		#FF6347
rpm_usage=6		#FF4500
rpm_suspended		#eeeeee
rpm_suspending		#eeaaaa
rpm_resuming		#aaaaee
rpm_active		#ee0000
"""
    additional_ftrace_parsers = [
    ('runtime_pm_status',   'driver=%s dev=%s status=%s', 'driver','dev','status'),
    ('runtime_pm_usage',   'driver=%s dev=%s usage=%d', 'driver','dev','usage'),
    ]
    additional_process_types = {"runtime_pm":(tcRuntimePM,POWER_CLASS)}
    @staticmethod
    def do_event_runtime_pm_status(proj,event):
        if proj.first_ts == 0:
            proj.first_ts = event.timestamp-1

        p = proj.generic_find_process(0,"runtime_pm:%s %s"%(event.driver,event.dev),"runtime_pm")
        if len(p['start_ts'])>len(p['end_ts']):
            p['end_ts'].append(event.timestamp)
        if event.status!="SUSPENDED":
            p['start_ts'].append(int(event.timestamp))
            p['types'].append(colors.get_color_id("rpm_%s"%(event.status.lower())))
            p['cpus'].append(event.common_cpu)

    @staticmethod
    def do_event_runtime_pm_usage(proj, event):
        p = proj.generic_find_process(0,"runtime_pm_usage:%s %s"%(event.driver,event.dev),"runtime_pm")
        if len(p['start_ts'])>len(p['end_ts']):
            p['end_ts'].append(event.timestamp)
        if event.usage!=0:
            p['start_ts'].append(int(event.timestamp))
            usagecolor = event.usage
            if usagecolor<0:
                usagecolor = -1
            if usagecolor>6:
                usagecolor = 6
            p['types'].append(colors.get_color_id("rpm_usage=%d"%(usagecolor)))
            p['cpus'].append(event.common_cpu)

plugin_register(runtime_pm)
