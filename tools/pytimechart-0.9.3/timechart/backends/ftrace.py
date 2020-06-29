import re
import sys,os
from timechart.plugin import get_plugins_additional_ftrace_parsers
from enthought.pyface.api import ProgressDialog

# take the TP_printk from the /include/trace/events dir
# syntax is event_name, printk, printk_args...
events_desc = [
    ('sched_switch',  'task %s:%d [%d] (%s) ==> %s:%d [%d]',
     'prev_comm', 'prev_pid', 'prev_prio','prev_state' ,
     'next_comm', 'next_pid', 'next_prio'),
    ('sched_switch',  'task %s:%d [%d] ==> %s:%d [%d]',
     'prev_comm', 'prev_pid', 'prev_prio'  ,
     'next_comm', 'next_pid', 'next_prio'),
    ('sched_switch',  'prev_comm=%s prev_pid=%d prev_prio=%d prev_state=%s ==> next_comm=%s next_pid=%d next_prio=%d',
     'prev_comm', 'prev_pid', 'prev_prio'  , 'prev_state',
     'next_comm', 'next_pid', 'next_prio'),
    ('sched_wakeup','task %s:%d [%d] success=%d [%d]','comm', 'pid', 'prio', 'success', 'cpu'),
    ('sched_wakeup','task %s:%d [%d] success=%d','comm', 'pid', 'prio', 'success'),
    ('sched_wakeup','comm=%s pid=%d prio=%d success=%d target_cpu=%d','comm', 'pid', 'prio', 'success', 'cpu'),
    ('softirq_entry','softirq=%d action=%s','vec','name'),
    ('softirq_exit','softirq=%d action=%s','vec','name'),
    ('softirq_entry','vec=%d [action=%s]','vec','name'),
    ('softirq_exit','vec=%d [action=%s]','vec','name'),
    ('softirq_raise','vec=%d [action=%s]','vec','name'),
    ('irq_handler_entry', 'irq=%d handler=%s','irq','name'),
    ('irq_handler_entry', 'irq=%d name=%s','irq','name'),
    ('irq_handler_exit', 'irq=%d return=%s','irq','ret'),
    ('irq_handler_exit', 'irq=%d ret=%s','irq','ret'),
    ('workqueue_execution','thread=%s func=%s\\+%s/%s','thread','func','func_offset','func_size'),
    ('workqueue_execution','thread=%s func=%s','thread','func'),
    ]
events_desc += get_plugins_additional_ftrace_parsers()
# pre process our descriptions to transform it into re
events_re = {}
num_func = 0
for event in events_desc:
    name = event[0]
    printk = event[1]
    args = event[2:]
    args_l = []
    for i in '()[]':
        printk = printk.replace(i,'\\'+i)
    # we replace %d %s by the equivalent regular expression, and keep the type in memory for later
    i = 0
    func = "def my_dispatch_func%d(event,group):\n"%(num_func)
    for arg in args:
        idx = printk.index('%')
        format = printk[idx+1]
        if format=='d':
            filt=int
            regex="([-0-9]+)"
            func+=" event['%s'] = int(group[%d])\n"%(arg,i)
        elif format=='s':
            filt=str
            regex="(.*)"
            func+=" event['%s'] = group[%d]\n"%(arg,i)
        printk = printk.replace("%"+format,regex,1)
        args_l.append((arg,filt))
        i+=1
    if not events_re.has_key(name):
        events_re[name] = []
    exec func
    events_re[name].append((name,re.compile(printk),eval("my_dispatch_func%d"%num_func)))
    num_func+=1

# event class passed to callback, this is more convenient than passing a dictionary
class Event:
    def __init__(self,event):
        self.__dict__=event
    def __repr__(self):
        ret = ""
        for k in self.__dict__:
            ret += "%s: %s, "%(k,str(self.__dict__[k]))
        return ret
class TraceCmdEventWrapper:
    def __init__(self,event):
        self.tracecmd_event = event
        self.event = str(event.name)
        self.linenumber = 0
        self.common_cpu = int(event.cpu)
        self.common_comm = str(event.comm)
        self.common_pid = int(event.pid)
        self.timestamp = event.ts/1000
    def __getattr__(self,name):
        try:
            f = self.tracecmd_event[name]
        except KeyError:
            raise  KeyError(name+ " not in "+str( self.tracecmd_event.keys()))
        try:
            return long(f)
        except :
            return str(f)
def load_tracecmd(filename,callback):
    try:
        import tracecmd
    except ImportError:
        raise Exception("please compile python support in trace-cmd and add trace-cmd directory into your PYTHONPATH environment variable")
    t = tracecmd.Trace(filename)
    # the higher level assumes events are already system sorted, but tracecmd sort them by cpus.
    # so we have to manually sort them.
    cpu_event_list_not_empty = t.cpus
    events = [ t.read_event(cpu) for cpu in xrange(t.cpus)]
    while cpu_event_list_not_empty > 0:
        ts = 0xFFFFFFFFFFFFFFFF
        first_cpu = 0
        for cpu in range(0, t.cpus):
            if events[cpu].ts < ts:
                first_cpu = cpu
                ts = events[cpu].ts
        callback(TraceCmdEventWrapper(events[first_cpu]))

        events[first_cpu] = t.read_event(first_cpu)
        if events[first_cpu] == None:
            cpu_event_list_not_empty -= 1
# seamlessly open gziped of raw text files
def ftrace_open(filename):
    if filename.endswith(".gz"):
        import gzip
        return gzip.open(filename,"r")
    elif filename.endswith(".lzma"):
        try:
            import lzma
        except:
            raise Exception("lzma module could not be imported. Please install python-lzma to seamlessly open lzma compressed file: http://pypi.python.org/pypi/pyliblzma")
        return lzma.LZMAFile(filename,"r")
    else:
        return open(filename,"r")
#@profile
def parse_ftrace(filename,callback):
    fid = ftrace_open(filename)
    progress = ProgressDialog(title="ftrace", message="loading %s..."%(os.path.basename(filename)), max=100, show_time=True, can_cancel=True)
    progress.open()
    try:
        fid.seek(0,2)
    except ValueError:
        # gzip do not support seek end
        # do we uncompress everything. :-/
        # parsing is already far slower than uncompressing.
        while fid.read(1024):
            pass
    totsize = fid.tell()
    fid.seek(0,0)
    last_percent = 0
    # the base regular expressions
    event_re = re.compile(
        r'\s*(.+)-([0-9]+)\s+\[([0-9]+)\]\s+([0-9.]+): (.*): (.*)')
    function_re = re.compile(
        r'\s*(.+)-([0-9]+)\s+\[([0-9]+)\]\s+([0-9.]+): (.*) <-(.*)')
    last_timestamp = 0
    linenumber = 0
    for line in fid:
        percent = int(fid.tell()*100./totsize)
        if percent != last_percent:
            last_percent = percent
            (cont, skip) = progress.update(percent)
            if not cont or skip:
                break
        linenumber+=1
        line = line.rstrip()
        res = event_re.match(line)
        if res:
            groups = res.groups()
            event_name = groups[4]
            event = {
                'linenumber': linenumber,
                'common_comm' : groups[0],
                'common_pid' :  int(groups[1]),
                'common_cpu' : int(groups[2]),
                'timestamp' : int(float(groups[3])*1000000),
                'event' : event_name,
                'event_arg' : groups[5]
                }
            last_timestamp = event['timestamp']
            to_match = event['event_arg']
            try:
                for name,regex,func in events_re[event_name]:
                    res = regex.search(to_match)
                    if res:
                        func(event,res.groups())
            except KeyError:
                pass
            callback(Event(event))
            continue

        res = function_re.match(line)
        if res:
            event = {
                'linenumber': linenumber,
                'common_comm' : res.group(1),
                'common_pid' :  int(res.group(2)),
                'common_cpu' : int(res.group(3)),
                'timestamp' : int(float(res.group(4))*1000000),
                'event':'function',
                'callee' : res.group(5),
                'caller' : res.group(6)
                }
            callback(Event(event))
            continue
    fid.close()
def get_partial_text(fn,start,end):
    text = ""
    fid = ftrace_open(fn)
    linenumber = 0
    for line in fid:
        linenumber+=1
        if linenumber >= start and linenumber <= end:
            text+=line
    return text

def load_ftrace(fn):
    from timechart.model import tcProject
    proj = tcProject()
    proj.filename = fn
    proj.start_parsing(get_partial_text)
    parse_ftrace(fn,proj.handle_trace_event)
    proj.finish_parsing()
    return proj


def detect_ftrace(fn):
    if fn.endswith(".txt"):
        return load_ftrace
    if fn.endswith(".txt.gz"):
        return load_ftrace
    if fn.endswith(".txt.lzma"):
        return load_ftrace
    return None
#### TEST ######################################################################
if __name__ == "__main__":
    def callback(event):
        #print event.__dict__
        pass
    parse_ftrace(sys.argv[1],callback)

#### EOF ######################################################################
