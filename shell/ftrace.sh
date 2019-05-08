
adb root
adb remount
adb shell

adb shell 'echo 0 > /d/tracing/tracing_on'
adb shell 'echo 50000 > /d/tracing/buffer_size_kb'

adb shell 'echo "" > /d/tracing/set_event'
adb shell 'echo "" > /d/tracing/trace'
adb shell sync
adb shell 'echo power:cpu_idle power:cpu_frequency power:cpu_frequency_switch_start msm_low_power:* sched:sched_cpu_hotplug sched:sched_switch sched:sched_wakeup sched:sched_wakeup_new sched:sched_enq_deq_task >> /d/tracing/set_event'
adb shell 'echo power:clock_set_rate power:clock_enable power:clock_disable msm_bus:bus_update_request >> /d/tracing/set_event'
adb shell 'echo irq:* >> /d/tracing/set_event'
adb shell 'echo mdss:* >> /d/tracing/set_event'
adb shell 'echo mdss:mdp_mixer_update mdss:mdp_sspp_change mdss:mdp_commit >> /d/tracing/set_event'
adb shell 'echo kgsl:kgsl_pwrlevel kgsl:kgsl_buslevel kgsl:kgsl_pwr_set_state >> /d/tracing/set_event'
adb shell 'echo power:* >> /d/tracing/set_event'

adb shell 'sleep 20 && echo 1 > /d/tracing/tracing_on && sleep 180 && echo 0 > /d/tracing/tracing_on &'

#adb shell cat /d/tracing/tracing_on
#adb shell echo 0 > /d/tracing/tracing_on
#adb shell cat /d/tracing/trace > /sdcard/trace.txt
