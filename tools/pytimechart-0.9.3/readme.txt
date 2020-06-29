PyTimechart, a tool to display ftrace (or perf) traces

This is a reimplemetation of some of the main features of timechart from Arjan Van de Ven.

On top of original timechart features, pytimechart adds:
a parser for ftrace traces
a gui for fast navigation, even with big traces
* integrates irq traces to view how irq handlers influences the system.

See INSTALL for installation procedures.


Color Codes, Interpretation

As a prototype, this software is not a model of easy to use UI. We still need at least a legend…

Process states

light grey: Long running process
dark grey: Process that is running, but interrupted frequently. Most likely, changing the zoom level will help you to understand why.
light yellow: The process is waiting for CPU, it is in the RUNNING state, but is scheduled out.
The number inside the process state box is the CPU number on which this process is running.
CPU state

The C state is represented with level of blue dark blue is C6 and light blue is C2
The number inside the box is the C state.
Wake events

When you activate wake events, some arrows are shown from one process line to another. This represents wake events. For some reason, the process A as woken up the Process B. Several wake up reason are possible:
Process A is sending data to Process B via a fifo or a file
Process A is releasing a semaphore also hold by Process B
Process A is an actually an ISR, spawning a BH/tasklet/work
etc.

Usage

Launch from the desktop icon or program menu, and you will be prompted for a trace.txt file.
A sample one is given.

You can zoom horizontaly (strech the view) with the scroll wheel, and pan with left button.
Use control + scroll wheel to zoom on each axis

The left pane allows you to control what is displayed:

you can filter out process that do not contribute much or are not visible in current view.
you can choose to display or not wake up relationships between processes

Generating trace.txt

Kernel Config

Please ensure that the following option are enabled in your .config
CONFIG_FUNCTION_TRACER=y
CONFIG_SYSPROF_TRACER=y  
CONFIG_SCHED_TRACER=y  
CONFIG_POWER_TRACER=y  
CONFIG_WORKQUEUE_TRACER=y
You can find them in menuconfig:
–> Kernel hacking –> Tracers

Scripts

See scripts in examples/
as root:
Use start.sh to start the tracer. It may print error if you did not have all patches installed and activated.
Use stop.sh to stop the tracer and generate a trace.txt file in home directory
use the provided cmdline to trace the boot process. The traces will begin just after the ftrace system is initialized. Then only use stop.sh to get the trace.
Function Tracing

Please refer to ftrace documentation to see how is working function tracing.

First, it is neccesary to enable function tracing in menuconfig: ‘’‘CONFIG_FUNCTION_TRACER’‘’ at:
-> Kernel hacking -> Tracers
Here is an example of a trace configuration script that will show at the spi subsystem, and max3110 spi to rs232 driver behaviour. We allocated 50MB of buffer to allow a lot of

Usage with trace-cmd from kernelshark project:

sudo ./trace-cmd record -e sched:sched_wakeup -e sched:sched_switch -e workqueue:workqueue_execution -e power:* -e irq:* -o trace.dat

pytimechart will open .dat files as trace-cmd file using python wrapper of trace-cmd.

At the moment trace-cmd does not install its python wrapper, you need to provide path to trace-cmd
export PYTHONPATH=/path/to/trace-cmd

Usage with perf from linux tree:

sudo perf timechart record
sudo chmod a+r perf.data
perf trace -s timechart.py
    

