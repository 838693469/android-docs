#!/system/bin/sh
#########################################################################
# File Name: run_ftrance_ion.sh
#########################################################################

echo "====== $0: PID of this script: $$ ======\n"

Script_PATH=/data
Script_NAME=${Script_PATH}/tracing_on.sh

# Step 1
echo "" > /d/tracing/set_event
echo 50000 > /d/tracing/buffer_size_kb
cat /d/tracing/buffer_size_kb

# Step 2
buffer_size_kb=`cat /d/tracing/buffer_size_kb`
echo "====== ${buffer_size_kb} ======\n"
if [ ${buffer_size_kb} -ne 50000 ]; then
    echo 50000 > /d/tracing/buffer_size_kb
fi
cat /d/tracing/buffer_size_kb

# Step 3
echo 1 > /d/tracing/events/vmscan/enable
echo 1 > /d/tracing/events/kmem/ion_secure_cma_add_to_pool_start/enable
echo 1 > /d/tracing/events/kmem/ion_secure_cma_add_to_pool_end/enable
echo 1 > /d/tracing/events/kmem/ion_secure_cma_allocate_start/enable
echo 1 > /d/tracing/events/kmem/ion_secure_cma_allocate_end/enable
echo 1 > /d/tracing/events/kmem/ion_secure_cma_shrink_pool_start/enable
echo 1 > /d/tracing/events/kmem/ion_secure_cma_shrink_pool_end/enable
echo 1 > /d/tracing/events/kmem/ion_alloc_buffer_end/enable
echo 1 > /d/tracing/events/kmem/ion_alloc_buffer_fail/enable
echo 1 > /d/tracing/events/kmem/ion_alloc_buffer_fallback/enable
echo 1 > /d/tracing/events/kmem/ion_alloc_buffer_start/enable
echo 1 > /d/tracing/events/kmem/mm_page_alloc/enable
echo 1 > /sys/kernel/debug/tracing/events/sync/enable
echo 1 > /sys/kernel/debug/tracing/events/workqueue/enable
echo 1 > /sys/kernel/debug/tracing/options/print-tgid
sync

cat /d/tracing/trace > /data/trace.log &
echo "$0 -> END !"

while true
do
    sleep 1
    sync
done
sync
