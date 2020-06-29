# timechart project
# the timechart model with all loading facilities

from numpy import amin, amax, arange, searchsorted, sin, pi, linspace
import numpy as np
import traceback
import re
from enthought.traits.api import HasTraits, Instance, Str, Float,Delegate,\
    DelegatesTo, Int, Long, Enum, Color, List, Bool, CArray, Property, cached_property, String, Button, Dict
from enthought.traits.ui.api import Group, HGroup, Item, View, spring, Handler,VGroup,TableEditor
from enthought.enable.colors import ColorTrait
from enthought.pyface.image_resource import ImageResource
from enthought.pyface.api import ProgressDialog

from process_table import process_table_editor
import colors

import numpy
import sys

def _pretty_time(time):
    if time > 1000000:
        time = time/1000000.
        return "%.1f s"%(time)
    if time > 1000:
        time = time/1000.
        return "%.1f ms"%(time)
    return "%.1f us"%(time)

class tcGeneric(HasTraits):
    name = String
    start_ts = CArray
    end_ts = CArray
    types = CArray
    has_comments = Bool(True)
    total_time = Property(Int)
    max_types = Property(Int)
    max_latency = Property(Int)
    max_latency_ts = Property(CArray)
    overview_ts_cache = Dict({})

    @cached_property
    def _get_total_time(self):
        return sum(self.end_ts-self.start_ts)
    @cached_property
    def _get_max_types(self):
        return amax(self.types)
    @cached_property
    def _get_max_latency(self):
        return -1

    def get_partial_tables(self,start,end):
        low_i = searchsorted(self.end_ts,start)
        high_i = searchsorted(self.start_ts,end)
        ends = self.end_ts[low_i:high_i].copy()
        starts = self.start_ts[low_i:high_i].copy()
        if len(starts)==0:
            return np.array([]),np.array([]),[]
        # take care of activities crossing the selection
        if starts[0]<start:
            starts[0] = start
        if ends[-1]>end:
            ends[-1] = end
        types = self.types[low_i:high_i]
        return starts,ends,types
    def get_overview_ts(self, threshold):
        """merge events so that there never are two events in the same "threshold" microsecond
        """
        if threshold in self.overview_ts_cache:
            return self.overview_ts_cache[threshold]
        # we recursively use the lower threshold caches
        # this allows to pre-compute the whole cache more efficiently
        if threshold > 4:
            origin_start_ts, origin_end_ts = self.get_overview_ts(threshold/2)
        else:
            origin_start_ts, origin_end_ts = self.start_ts, self.end_ts
        # only calculate overview if it worth.
        if len(origin_start_ts) < 500:
            overview = (origin_start_ts, origin_end_ts)
            self.overview_ts_cache[threshold] = overview
            return overview
        # assume at least one event
        start_ts = []
        end_ts = []
        # start is the first start of the merge list
        start = origin_start_ts[0]
        i = 1
        while i < len(origin_start_ts):
            if origin_start_ts[i] > origin_start_ts[i-1] + threshold:
                start_ts.append(start)
                end_ts.append(origin_end_ts[i-1])
                start = origin_start_ts[i]
            i += 1
        start_ts.append(start)
        end_ts.append(origin_end_ts[i-1])
        overview = (numpy.array(start_ts), numpy.array(end_ts))
        self.overview_ts_cache[threshold] = overview
        return overview
    # UI traits
    default_bg_color = Property(ColorTrait)
    bg_color = Property(ColorTrait)
    @cached_property
    def _get_bg_color(self):
        return colors.get_traits_color_by_name("idle_bg")

class tcIdleState(tcGeneric):
    def get_comment(self,i):
        return colors.get_colorname_by_id(self.types[i])
class tcFrequencyState(tcGeneric):
    def get_comment(self,i):
        return "%d"%(self.types[i])

class tcProcess(tcGeneric):
    name = Property(String) # overide TimeChart
    # start_ts=CArray # inherited from TimeChart
    # end_ts=CArray # inherited from TimeChart
    # values = CArray   # inherited from TimeChart
    pid = Long
    ppid = Long
    selection_time = Long(0)
    selection_pc = Float(0)
    comm = String
    cpus = CArray
    comments = []
    has_comments = Bool(True)
    show = Bool(True)
    process_type = String
    project = None
    @cached_property
    def _get_name(self):
        return "%s:%d (%s)"%(self.comm,self.pid, _pretty_time(self.total_time))

    def get_comment(self,i):
        if len(self.comments)>i:
            return "%s"%(self.comments[int(i)])
        elif len(self.cpus)>i:
            return "%d"%(self.cpus[i])
        else:
            return ""
    @cached_property
    def _get_max_latency(self):
        if self.pid==0 and self.comm.startswith("irq"):
            return 1000

    @cached_property
    def _get_max_latency_ts(self):
        if self.max_latency > 0:
            indices = np.nonzero((self.end_ts - self.start_ts) > self.max_latency)[0]
            return np.array(sorted(map(lambda i:self.start_ts[i], indices)))
        return []

    @cached_property
    def _get_default_bg_color(self):
        if self.max_latency >0 and max(self.end_ts - self.start_ts)>self.max_latency:
            return (1,.1,.1,1)
        return colors.get_traits_color_by_name(self.process_type+"_bg")

    def _get_bg_color(self):
        if self.project != None and self in self.project.selected:
            return  colors.get_traits_color_by_name("selected_bg")
        return self.default_bg_color


class tcProject(HasTraits):
    c_states = List(tcGeneric)
    p_states = List(tcGeneric)
    processes = List(tcProcess)
    selected =  List(tcProcess)
    filtered_processes = List(tcProcess)
    remove_filter = Button(image=ImageResource("clear.png"),width_padding=0,height_padding=0,style='toolbar')
    minimum_time_filter = Enum((0,1000,10000,50000,100000,500000,1000000,5000000,1000000,5000000,10000000,50000000))
    minimum_events_filter = Enum((0,2,4,8,10,20,40,100,1000,10000,100000,1000000))
    plot_redraw = Long()
    filter =  Str("")
    filter_invalid = Property(depends_on="filter")
    filename = Str("")
    power_event = CArray
    num_cpu = Property(Int,depends_on='c_states')
    num_process = Property(Int,depends_on='process')
    traits_view = View(
        VGroup(
            HGroup(
                Item('filter',invalid="filter_invalid",width=1,
                     tooltip='filter the process list using a regular expression,\nallowing you to quickly find a process'),
                Item('remove_filter', show_label=False, style='custom',
                     tooltip='clear the filter')
                ),
            HGroup(
                Item('minimum_time_filter',width=1,label='dur',
                     tooltip='filter the process list with minimum duration process is scheduled'),
                Item('minimum_events_filter',width=1,label='num',
                     tooltip='filter the process list with minimum number of events process is generating'),
                )
            ),
        Item( 'filtered_processes',
              show_label  = False,
              height=40,
              editor      = process_table_editor
              )
        )
    first_ts = 0
    def _get_filter_invalid(self):
        try:
            r = re.compile(self.filter)
        except:
            return True
        return False
    def _remove_filter_changed(self):
        self.filter=""
    def _filter_changed(self):
        try:
            r = re.compile(self.filter)
        except:
            r = None
        filtered_processes =self.processes
        if self.minimum_events_filter:
            filtered_processes = filter(lambda p:self.minimum_events_filter < len(p.start_ts), filtered_processes)
        if self.minimum_time_filter:
            filtered_processes = filter(lambda p:self.minimum_time_filter < p.total_time, filtered_processes)
        if r:
            filtered_processes = filter(lambda p:r.search(p.comm), filtered_processes)
        self.filtered_processes = filtered_processes
    _minimum_time_filter_changed = _filter_changed
    _minimum_events_filter_changed = _filter_changed
    def _processes_changed(self):
        self._filter_changed()
    def _on_show(self):
        for i in self.selected:
            i.show = True
        self.plot_redraw +=1
    def _on_hide(self):
        for i in self.selected:
            i.show = False
        self.plot_redraw +=1
    def _on_select_all(self):
        if self.selected == self.filtered_processes:
            self.selected = []
        else:
            self.selected = self.filtered_processes
        self.plot_redraw +=1

    def _on_invert(self):
        for i in self.filtered_processes:
            i.show = not i.show
        self.plot_redraw +=1

    @cached_property
    def _get_num_cpu(self):
        return len(self.c_states)
    def _get_num_process(self):
        return len(self.processes)
    def process_list_selected(self, selection):
        print selection
######### stats part ##########

    def process_stats(self,start,end):
        fact = 100./(end-start)
        for tc in self.processes:
            starts,ends,types = tc.get_partial_tables(start,end)
            inds = np.where(types==colors.get_color_id("running"))
            tot = sum(ends[inds]-starts[inds])
            tc.selection_time = int(tot)
            tc.selection_pc = tot*fact
    def get_selection_text(self,start,end):
        low_line = -1
        high_line = -1
        low_i = searchsorted(self.timestamps,start)
        high_i = searchsorted(self.timestamps,end)
        low_line = self.linenumbers[low_i]
        high_line = self.linenumbers[high_i]
        return self.get_partial_text(self.filename, low_line, high_line)
######### generic parsing part ##########


    def generic_find_process(self,pid,comm,ptype,same_pid_match_timestamp=0):
        if self.tmp_process.has_key((pid,comm)):
            return self.tmp_process[(pid,comm)]
        # else try to find if there has been a process with same pid recently, and different name
        if same_pid_match_timestamp != 0 and comm != "swapper":
            for k, p in self.tmp_process.items():
                if k[0] == pid:
                    if len(p['start_ts'])>0 and p['start_ts'][-1] > same_pid_match_timestamp:
                        p['comm'] = comm
                        self.tmp_process[(pid,comm)] = p
                        del self.tmp_process[k]
                        return p
        tmp = {'type':ptype,'comm':comm,'pid':pid,'start_ts':[],'end_ts':[],'types':[],'cpus':[],'comments':[]}
        if not (pid==0 and comm =="swapper"):
            self.tmp_process[(pid,comm)] = tmp
        return tmp

    def generic_process_start(self,process,event, build_p_stack=True):
        if process['comm']=='swapper' and process['pid']==0:
            return # ignore swapper event
        if len(process['start_ts'])>len(process['end_ts']):
            process['end_ts'].append(event.timestamp)
        if self.first_ts == 0:
            self.first_ts = event.timestamp
        self.cur_process_by_pid[process['pid']] = process
        if build_p_stack :
            p_stack = self.cur_process[event.common_cpu]
            if p_stack:
                p = p_stack[-1]
                if len(p['start_ts'])>len(p['end_ts']):
                    p['end_ts'].append(event.timestamp)
                # mark old process to wait for cpu
                p['start_ts'].append(int(event.timestamp))
                p['types'].append(colors.get_color_id("waiting_for_cpu"))
                p['cpus'].append(event.common_cpu)
                p_stack.append(process)
            else:
                self.cur_process[event.common_cpu] = [process]
        # mark process to use cpu
        process['start_ts'].append(event.timestamp)
        process['types'].append(colors.get_color_id("running"))
        process['cpus'].append(event.common_cpu)


    def generic_process_end(self,process,event, build_p_stack=True):
        if process['comm']=='swapper' and process['pid']==0:
            return # ignore swapper event
        if len(process['start_ts'])>len(process['end_ts']):
            process['end_ts'].append(event.timestamp)
        if build_p_stack :
            p_stack = self.cur_process[event.common_cpu]
            if p_stack:
                p = p_stack.pop()
                if p['pid'] != process['pid']:
                    print  "warning: process premption stack following failure on CPU",event.common_cpu, p['comm'],p['pid'],process['comm'],process['pid'],map(lambda a:"%s:%d"%(a['comm'],a['pid']),p_stack),event.linenumber
                    p_stack = []

                if p_stack:
                    p = p_stack[-1]
                    if len(p['start_ts'])>len(p['end_ts']):
                        p['end_ts'].append(event.timestamp)
                    # mark old process to run on cpu 
                    p['start_ts'].append(event.timestamp)
                    p['types'].append(colors.get_color_id("running"))
                    p['cpus'].append(event.common_cpu)
    def generic_process_single_event(self,process,event):
        if len(process['start_ts'])>len(process['end_ts']):
            process['end_ts'].append(event.timestamp)
        # mark process to use cpu
        process['start_ts'].append(event.timestamp)
        process['types'].append(colors.get_color_id("running"))
        process['cpus'].append(event.common_cpu)
        process['end_ts'].append(event.timestamp)


    def do_function_default(self,event):
        process = self.generic_find_process(0,"kernel function:%s"%(event.callee),"function")
        self.generic_process_single_event(process,event)

    def do_event_default(self,event):
        event.name = event.event.split(":")[0]
        process = self.generic_find_process(0,"event:%s"%(event.name),"event")
        self.generic_process_single_event(process,event)
        process['comments'].append(event.event)


    def start_parsing(self, get_partial_text):
        # we build our data into python data formats, who are resizeable
        # once everything is parsed, we will transform it into numpy array, for fast access
        self.tmp_c_states = []
        self.tmp_p_states = []
        self.tmp_process = {}
        self.timestamps = []
        self.linenumbers = []
        self.cur_process_by_pid = {}
        self.wake_events = []
        self.cur_process = [None]*20
        self.last_irq={}
        self.last_spi=[]
        self.missed_power_end = 0
        self.get_partial_text = get_partial_text
        self.methods = {}
        import plugin
        colors.parse_colors(plugin.get_plugins_additional_colors())
        plugin.get_plugins_methods(self.methods)
        self.process_types = {
            "function":(tcProcess, plugin.MISC_TRACES_CLASS),
            "event":(tcProcess, plugin.MISC_TRACES_CLASS)}
        self.process_types.update(plugin.get_plugins_additional_process_types())
    def finish_parsing(self):
        #put generated data in unresizable numpy format
        c_states = []
        i=0
        for tc in self.tmp_c_states:
            t = tcIdleState(name='cpu%d'%(i))
            while len(tc['start_ts'])>len(tc['end_ts']):
                tc['end_ts'].append(tc['start_ts'][-1])
            t.start_ts = numpy.array(tc['start_ts'])
            t.end_ts = numpy.array(tc['end_ts'])
            t.types = numpy.array(tc['types'])
            c_states.append(t)
            i+=1
        self.c_states=c_states
        i=0
        p_states = []
        for tc in self.tmp_p_states:
            t = tcFrequencyState(name='cpu%d'%(i))
            t.start_ts = numpy.array(tc['start_ts'])
            t.end_ts = numpy.array(tc['end_ts'])
            t.types = numpy.array(tc['types'])
            i+=1
            p_states.append(t)
        self.wake_events = numpy.array(self.wake_events,dtype=[('waker',tuple),('wakee',tuple),('time','uint64')])
        self.p_states=p_states
        processes = []
        last_ts = 0
        for pid,comm in self.tmp_process:
            tc = self.tmp_process[pid,comm]
            if len(tc['end_ts'])>0 and last_ts < tc['end_ts'][-1]:
                last_ts = tc['end_ts'][-1]
        if len(self.tmp_process) >0:
            progress = ProgressDialog(title="precomputing data", message="precomputing overview data...", max=len(self.tmp_process), show_time=False, can_cancel=False)
            progress.open()
        i = 0
        for pid,comm in self.tmp_process:
            tc = self.tmp_process[pid,comm]
            if self.process_types.has_key(tc['type']):
                klass, order = self.process_types[tc['type']]
                t = klass(pid=pid,comm=tc['comm'],project=self)
            else:
                t = tcProcess(pid=pid,comm=comm,project=self)
            while len(tc['start_ts'])>len(tc['end_ts']):
                tc['end_ts'].append(last_ts)
            t.start_ts = numpy.array(tc['start_ts'])
            t.end_ts = numpy.array(tc['end_ts'])
            t.types = numpy.array(tc['types'])
            t.cpus = numpy.array(tc['cpus'])
            t.comments = tc['comments'] #numpy.array(tc['comments'])
            t.process_type = tc["type"]
            # precompute 16 levels of overview cache
            t.get_overview_ts(1<<16)
            processes.append(t)
            progress.update(i)
            i += 1
        if len(self.tmp_process) > 0:
            progress.close()
            self.tmp_process = []
        def cmp_process(x,y):
            # sort process by type, pid, comm
            def type_index(t):
                try:
                    return self.process_types[t][1]
                except ValueError:
                    return len(order)+1
            c = cmp(type_index(x.process_type),type_index(y.process_type))
            if c != 0:
                return c
            c = cmp(x.pid,y.pid)
            if c != 0:
                return c
            c = cmp(x.comm,y.comm)
            return c

        processes.sort(cmp_process)
        self.processes = processes
        self.p_states=p_states
        self.tmp_c_states = []
        self.tmp_p_states = []
        self.tmp_process = {}

    def ensure_cpu_allocated(self,cpu):
        # ensure we have enough per_cpu p/c_states timecharts
        while len(self.tmp_c_states)<=cpu:
            self.tmp_c_states.append({'start_ts':[],'end_ts':[],'types':[]})
        while len(self.tmp_p_states)<=cpu:
            self.tmp_p_states.append({'start_ts':[],'end_ts':[],'types':[]})

    def run_callbacks(self, callback, event):
        if callback in self.methods:
            for m in self.methods[callback]:
                try:
                    m(self,event)
                except AttributeError:
                    if not hasattr(m,"num_exc"):
                        m.num_exc = 0
                    m.num_exc += 1
                    if m.num_exc <10:
                        print "bug in ", m, "still continue.."
                        traceback.print_exc()
                        print event
                    if m.num_exc == 10:
                        print m, "is too buggy, disabling, please report bug!"
                        self.methods[callback].remove(m)
                        if len(self.methods[callback])==0:
                            del self.methods[callback]
            return True
        return False

    def handle_trace_event(self,event):
        self.linenumbers.append(event.linenumber)
        self.timestamps.append(event.timestamp)
        if event.event=='function':
            callback = "do_function_"+event.callee
            self.run_callbacks("do_all_functions", event)
        else:
            callback = "do_event_"+event.event
            self.run_callbacks("do_all_events", event)

        if not self.run_callbacks(callback, event):
            if event.event=='function':
                self.do_function_default(event)
            else:
                self.do_event_default(event)
