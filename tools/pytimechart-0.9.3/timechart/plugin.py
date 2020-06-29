POWER_CLASS=0
IRQ_CLASS=1
WORK_CLASS=2
MISC_TRACES_CLASS=3
KERNEL_CLASS=4
USER_CLASS=5

plugin_list = []
class plugin:
    additional_colors = ""
    additional_ftrace_parsers = []
    additional_process_types = []

def plugin_register(plugin_class):
    plugin_list.append(plugin_class)

def get_plugins_methods(methods):
    for p in plugin_list:
        for name in dir(p):
            method = getattr(p, name)
            if callable(method):
                if not name in methods:
                    methods[name] = []
                methods[name].append(method)
def get_plugins_additional_process_types():
    s = {}
    for p in plugin_list:
        s.update(p.additional_process_types)
    return s
def get_plugins_additional_colors():
    s = ""
    for p in plugin_list:
        s += p.additional_colors
    return s
def get_plugins_additional_ftrace_parsers():
    s = []
    for p in plugin_list:
        s += p.additional_ftrace_parsers
    return s
import plugins
import os
for f in os.listdir(os.path.abspath(plugins.__path__[0])):
    module_name, ext = os.path.splitext(f)
    if (not module_name.startswith(".")) and ext == '.py' and module_name != "__init__":
        module = __import__("timechart.plugins."+module_name)
