#!/system/bin/sh
#########################################################################
# File Name: adb_ftrace.sh
#########################################################################

echo "====== $0: PID of this script: $$ ======\n"

Script_PATH=/data
Script_NAME=${Script_PATH}/tracing_on.sh

# Step 1
echo 0 > /d/tracing/tracing_on
echo 50000 > /d/tracing/buffer_size_kb
cat /d/tracing/buffer_size_kb
echo "" > /d/tracing/set_event
echo "" > /d/tracing/trace
echo power:cpu_idle power:cpu_frequency power:cpu_frequency_switch_start msm_low_power:* sched:sched_cpu_hotplug sched:sched_switch sched:sched_wakeup sched:sched_wakeup_new sched:sched_enq_deq_task >> /d/tracing/set_event
echo power:clock_set_rate power:clock_enable power:clock_disable msm_bus:bus_update_request >> /d/tracing/set_event
echo cpufreq_interactive:cpufreq_interactive_target cpufreq_interactive:cpufreq_interactive_setspeed >> /d/tracing/set_event
echo irq:* >> /d/tracing/set_event
echo mdss:* >> /d/tracing/set_event
echo mdss:mdp_mixer_update mdss:mdp_sspp_change mdss:mdp_commit >> /d/tracing/set_event
echo workqueue:workqueue_execute_end workqueue:workqueue_execute_start workqueue:workqueue_activate_work workqueue:workqueue_queue_work >> /d/tracing/set_event
echo kgsl:kgsl_pwrlevel kgsl:kgsl_buslevel kgsl:kgsl_pwr_set_state >> /d/tracing/set_event
echo regulator:regulator_set_voltage_complete regulator:regulator_disable_complete regulator:regulator_enable_complete >> /d/tracing/set_event
echo power:* >> /d/tracing/set_event
cat /d/tracing/set_event

# Step 2
buffer_size_kb=`cat /d/tracing/buffer_size_kb`
echo "====== ${buffer_size_kb} ======\n"
if [ ${buffer_size_kb} -ne 50000 ]; then
    echo 50000 > /d/tracing/buffer_size_kb
fi
cat /d/tracing/buffer_size_kb

# Step 3
#nohup sleep 10 && echo 1 > /d/tracing/tracing_on && sleep 30 && echo 0 > /d/tracing/tracing_on &
${Script_NAME} &
sync
