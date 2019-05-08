a) 
adb root 
adb remount 
adb shell 
echo 0 > /d/tracing/tracing_on 
echo 70000 > /d/tracing/buffer_size_kb 
cat /d/tracing/buffer_size_kb 
echo "" > /d/tracing/set_event 
echo "" > /d/tracing/trace 

echo power:cpu_idle power:cpu_frequency power:cpu_frequency_switch_start msm_low_power:* sched:sched_cpu_hotplug sched:sched_switch sched:sched_wakeup sched:sched_wakeup_new sched:sched_enq_deq_task >> /sys/kernel/debug/tracing/set_event 
echo power:memlat_dev_update power:memlat_dev_meas msm_bus:bus_update_request msm_bus:* power:bw_hwmon_update power:bw_hwmon_meas >> /sys/kernel/debug/tracing/set_event 
echo power:bw_hwmon_meas power:bw_hwmon_update>> /sys/kernel/debug/tracing/set_event 
echo clk:clk_set_rate clk:clk_enable clk:clk_disable >> /sys/kernel/debug/tracing/set_event 
echo power:clock_set_rate power:clock_enable power:clock_disable msm_bus:bus_update_request >> /sys/kernel/debug/tracing/set_event 
echo cpufreq_interactive:cpufreq_interactive_target cpufreq_interactive:cpufreq_interactive_setspeed >> /sys/kernel/debug/tracing/set_event 
echo irq:* >> /sys/kernel/debug/tracing/set_event 
echo mdss:mdp_mixer_update mdss:mdp_sspp_change mdss:mdp_commit >> /sys/kernel/debug/tracing/set_event 
echo workqueue:* >> /sys/kernel/debug/tracing/set_event 
echo kgsl:kgsl_pwrlevel kgsl:kgsl_buslevel kgsl:kgsl_pwr_set_state >> /sys/kernel/debug/tracing/set_event 
echo regulator:regulator_set_voltage_complete regulator:regulator_disable_complete regulator:regulator_enable_complete >> /sys/kernel/debug/tracing/set_event 
echo thermal:* >> /sys/kernel/debug/tracing/set_event 

//Confrim the setting 
cat /d/tracing/set_event 

b) 
//Give the below commands before disconnecting the USB and once you completed the 120 secs test then connect the USB. 
//Once the below commands are executed , make sure you start your test case within 10 secs. 
sleep 10 && echo 1 > /d/tracing/tracing_on && sleep 120 && echo 0 > /d/tracing/tracing_on && cat /d/tracing/trace > /sdcard/trace_wakeup.txt & 

//remove USB and start your test case within 10s 

c) 
//after test, connect USB and pull the trace_wakeup.txt 
adb shell "cat /d/tracing/tracing_on" 
adb pull /data/local/tmp/trace_wakeup.txt .