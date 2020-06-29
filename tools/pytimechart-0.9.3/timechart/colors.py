from enthought.traits.api import Color
from enthought.enable.colors import ColorTrait
from enthought.kiva.agg.agg import Rgba

# hint: use gcolor2 to pick up colors
# if you omit several color, it will automatically gradiant...
_tc_colors_txt = """
idle_bg			#ffdddd
irq_bg 	      		#f5ffe1
softirq_bg
work_bg
function_bg        	#80ff80
event_bg
kernel_process_bg       #F0F5A3
user_process_bg       	#E1DFFF
selected_bg		#ACD7E6
idle			#000000
waiting_for_cpu		#ffff88
running			#555555
overview       		#333333
shown_process		#111111
hidden_process		#777777

"""
_tc_colors_by_name = {}
_tc_colorname_by_id = []
_tc_colors_by_id = []
_tc_aggcolors_by_id = []

def _to_traits(color):
    r = int(color[1:3],16)/256.
    g = int(color[3:5],16)/256.
    b = int(color[5:7],16)/256.
    return r,g,b

def add_color(colorname, color):
    _tc_colors_by_name[colorname] = (color,len(_tc_colors_by_id))
    _tc_colorname_by_id.append(colorname)
    _tc_colors_by_id.append(color)
    _tc_aggcolors_by_id.append(Rgba(_to_traits(color)))

def parse_colors(color_text):
    # first parse the syntax sugared color definition table and change it to dictionary
    pending_colors = []
    last_color=0,0,0
    for line in color_text.split("\n"):
        line = line.split()
        if len(line)==2:
            colorname, color = line
            if pending_colors:
                r1,g1,b1 = last_color
                r2,g2,b2 = _to_traits(color)
                n = len(pending_colors)+2
                for i in xrange(1,n-1):
                    r = r1+(r2-r1)*i/n
                    g = g1+(g2-g1)*i/n
                    b = b1+(b2-b1)*i/n
                    add_color(pending_colors[i-1], "#%02X%02X%02X"%(255*r,255*g,255*b))
                pending_colors = []
            add_color(colorname,color)
            last_color = _to_traits(color)
        elif len(line)==1:
            pending_colors.append(line[0])

parse_colors(_tc_colors_txt)

def get_colorname_by_id(i):
    return _tc_colorname_by_id[i]

def get_color_by_name(name):
    return _tc_colors_by_name[name][0]

def get_color_id(name):
    return _tc_colors_by_name[name][1]

def get_traits_color_by_name(name):
    return _to_traits(_tc_colors_by_name[name][0])

def get_color_by_id(i):
    return _tc_colors_by_id[i]

def get_traits_color_by_id(i):
    return _to_traits(_tc_colors_by_id[i])

def get_aggcolor_by_id(i):
    return _tc_aggcolors_by_id[i]

if __name__ == '__main__':
    print get_traits_color_by_name("running"),get_traits_color_by_id(get_color_id("running"))
