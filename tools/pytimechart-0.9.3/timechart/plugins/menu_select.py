from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess

class menu_select(plugin):
    additional_colors = """
menu_select_bg		#e5bebe
menu_select		#ee0000
"""
    additional_ftrace_parsers = [
    ( 'menu_select', 'expected:%d predicted %d state:%s %d','expected','predicted','next_state','num_state'),
    ]
    additional_process_types = {
        "menu_select":(tcProcess, POWER_CLASS),
        }
    @staticmethod
    def do_event_menu_select(proj,event):
	try:
	   a= event.predicted
	except AttributeError:
	   return
        found = 0
        i = 0
        while not found:
            p = proj.generic_find_process(0,"menu_select_cpu%d_%d_predicted"%(event.common_cpu,i),"menu_select")
            p2 = proj.generic_find_process(0,"menu_select_cpu%d_%d_expected"%(event.common_cpu,i),"menu_select")
            if len(p['end_ts'])>0 and len(p2['end_ts'])>0 and (p['end_ts'][-1]>event.timestamp or p2['end_ts'][-1]>event.timestamp):
                i+=1
                continue
            found = 1
        p['start_ts'].append(int(event.timestamp))
        p['end_ts'].append(int(event.timestamp+event.predicted))
        p['types'].append(colors.get_color_id("menu_select"))
        p['cpus'].append(event.common_cpu)

        p = p2
        p['start_ts'].append(int(event.timestamp))
        p['end_ts'].append(int(event.timestamp+event.expected))
        p['types'].append(colors.get_color_id("menu_select"))
        p['cpus'].append(event.common_cpu)
plugin_register(menu_select)

menu_select_patch="""
diff --git a/drivers/cpuidle/governors/menu.c b/drivers/cpuidle/governors/menu.c
index 1b12870..4b18893 100644
--- a/drivers/cpuidle/governors/menu.c
+++ b/drivers/cpuidle/governors/menu.c
@@ -292,6 +292,7 @@ static int menu_select(struct cpuidle_device *dev)
                data->exit_us = s->exit_latency;
                data->last_state_idx = i;
        }
+       trace_printk("expected:%u predicted %llu state:%s %d\n",data->expected_us, data->predicted_us, dev->states[data->last_state_idx].name, dev->state_count);

        return data->last_state_idx;
 }
"""
