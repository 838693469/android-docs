from timechart.plugin import *
from timechart import colors
from timechart.model import tcProcess

# to use with start_spi.sh

class spi(plugin):
    additional_colors = """
spi_bg		      #80ff80
"""
    additional_ftrace_parsers = [
        ]
    additional_process_types = {
            "spi":(tcProcess, MISC_TRACES_CLASS),
        }
    @staticmethod
    def do_function_spi_sync(proj,event):
        process = proj.generic_find_process(0,"spi:%s"%(event.caller),"spi")
        proj.last_spi.append(process)
        proj.generic_process_start(process,event,False)
    @staticmethod
    def do_function_spi_complete(proj,event):
        process = proj.last_spi.pop(0)
        proj.generic_process_end(process,event,False)
    @staticmethod
    def do_function_spi_async(proj,event):
        if event.caller != 'spi_sync':
            spi.do_function_spi_sync(proj,event)

plugin_register(spi)
