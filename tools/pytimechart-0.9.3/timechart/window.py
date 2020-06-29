import sys,os
from enthought.traits.api import  HasTraits,Str,Button
from enthought.traits.ui.api import InstanceEditor,Item,View,HSplit,VSplit,Handler, StatusItem
from enthought.traits.ui.menu import Action, MenuBar, ToolBar, Menu, Separator
from model import tcProject
from plot import tcPlot, create_timechart_container
from enthought.enable.component_editor import ComponentEditor
from actions import _create_toolbar_actions, _create_menubar_actions

__doc__ = """http://packages.python.org/pytimechart/"""
__version__="0.9.3"

def browse_doc():
    from enthought.etsconfig.api import ETSConfig
    if ETSConfig.toolkit == 'wx':
        try:
            from wx import LaunchDefaultBrowser
            LaunchDefaultBrowser(__doc__)
        except:
            print "failure to launch browser"

class aboutBox(HasTraits):
    program = Str("pytimechart: linux traces exploration and visualization")
    author = Str("Pierre Tardy <tardyp@gmail.com>")
    version = Str(__version__)
    doc = Button(__doc__)
    traits_view = View(
        Item("program", show_label=False, style="readonly"),
        Item("author" , style="readonly"),
        Item("version", style="readonly"),
        Item("doc"),
        width=500,
        title="about"
        )
    def _doc_changed(self,ign):
        browse_doc()
class tcActionHandler(Handler):
    handler_list = []
    actions = {}
    def chooseAction(self, UIInfo,name):
        window = UIInfo.ui.context['object']
        handler_list = [window, window.project, window.plot, window.plot.options, window.plot.range_tools]
        for i in handler_list:
            fn = getattr(i, name, None)
            if fn is not None:
                if name.startswith("_on_toggle"):
                    fn(getattr(UIInfo,name[len("_on_"):]).checked)
                else:
                    fn()

class tcWindow(HasTraits):
    project = tcProject
    plot = tcPlot
    def __init__(self,project):
        self.project = project
        self.plot =  create_timechart_container(project)
        self.plot_range_tools = self.plot.range_tools
        self.plot_range_tools.on_trait_change(self._selection_time_changed, "time")
        self.trait_view().title = self.get_title()
    def get_title(self):
        if self.project.filename == "dummy":
            return "PyTimechart: Please Open a File"
        return "PyTimechart:"+self.project.filename
    # Create an action that exits the application.
    status = Str("Welcome to PyTimechart")
    traits_view = View(
        HSplit(
            VSplit(
                Item('project', show_label = False, editor=InstanceEditor(view = 'process_view'), style='custom',width=150),
#                Item('plot_range_tools', show_label = False, editor=InstanceEditor(view = 'selection_view'), style='custom',width=150,height=100)
                ),
            Item('plot', show_label = False, editor = ComponentEditor()),
            ),
        toolbar = ToolBar(*_create_toolbar_actions(),
                           image_size      = ( 24, 24 ),
                           show_tool_names = False),
        menubar = MenuBar(*_create_menubar_actions()),
        statusbar = [StatusItem(name='status'),],
        resizable = True,
        width = 1280,
        height = 1024,
        handler = tcActionHandler()
        )
    def _on_open_trace_file(self):
        if open_file(None) and self.project.filename=="dummy":
            self._ui.dispose()
    def _on_view_properties(self):
        self.plot.options.edit_traits()
    def _on_exit(self,n=None):
        self.close()
        sys.exit(0)
    def close(self,n=None):
        pass
    def _on_about(self):
        aboutBox().edit_traits()
    def _on_doc(self):
        browse_doc()
    def _selection_time_changed(self):
        self.status = "selection time:%s"%(self.plot_range_tools.time)


prof = 0

import wx
def open_dialog():
    dlg = wx.FileDialog(None, "Choose a file", "", "", "*.txt;*.gz;*.lzma", wx.OPEN)
    rv = None
    if dlg.ShowModal() == wx.ID_OK:
        filename=dlg.GetFilename()
        dirname=dlg.GetDirectory()
        rv = os.path.join(dirname, filename)

    dlg.Destroy()
    return rv

def save_dialog():
    dlg = wx.FileDialog(None, "Save file...", "", "", "*.txt", wx.SAVE)
    rv = None
    if dlg.ShowModal() == wx.ID_OK:
        filename=dlg.GetFilename()
        dirname=dlg.GetDirectory()
        rv = os.path.join(dirname, filename)

    dlg.Destroy()
    return rv

def open_file(fn=None):
    from backends.perf import detect_perf
    from backends.ftrace import detect_ftrace
    from backends.tracecmd import detect_tracecmd
    from backends.dummy import detect_dummy
    if fn == None:
        fn = open_dialog()
        if fn == None:
            return 0
    parser = None
    for func in detect_ftrace, detect_perf, detect_tracecmd, detect_dummy:
        parser = func(fn)
        if parser:
            break
    if prof:
        import cProfile
        cProfile.run('proj = parser(fn)','timechart_load.prof')
    elif fn:
        proj = parser(fn)
    if proj:
        # Create and open the main window.
        window = tcWindow(project = proj)
        window._ui = window.edit_traits()
        # Traits has the bad habbit of autoselecting the first row in the table_editor. Workaround this.
        proj.selected = []
        return 1
    return 0
