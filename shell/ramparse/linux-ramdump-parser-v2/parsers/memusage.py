# Copyright (c) 2016-2018 The Linux Foundation. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

from print_out import print_out_str
from parser_util import register_parser, RamParser, cleanupString


def do_dump_process_memory(ramdump):
    if ramdump.kernel_version < (4, 9):
        total_free = ramdump.read_word('vm_stat[NR_FREE_PAGES]')
        slab_rec = ramdump.read_word('vm_stat[NR_SLAB_RECLAIMABLE]')
        slab_unrec = ramdump.read_word('vm_stat[NR_SLAB_UNRECLAIMABLE]')
        total_shmem = ramdump.read_word('vm_stat[NR_SHMEM]')
    else:
        total_free = ramdump.read_word('vm_zone_stat[NR_FREE_PAGES]')
        # slab memory
        if ramdump.kernel_version >= (4, 14):
            slab_rec = ramdump.read_word('vm_node_stat[NR_SLAB_RECLAIMABLE]')
            slab_unrec = ramdump.read_word(
                            'vm_node_stat[NR_SLAB_UNRECLAIMABLE]')
        else:
            slab_rec = ramdump.read_word('vm_zone_stat[NR_SLAB_RECLAIMABLE]')
            slab_unrec = ramdump.read_word(
                            'vm_zone_stat[NR_SLAB_UNRECLAIMABLE]')
        total_shmem = ramdump.read_word('vm_node_stat[NR_SHMEM]')

    total_slab = slab_rec + slab_unrec
    total_mem = ramdump.read_word('totalram_pages') * 4
    offset_tasks = ramdump.field_offset('struct task_struct', 'tasks')
    offset_comm = ramdump.field_offset('struct task_struct', 'comm')
    offset_signal = ramdump.field_offset('struct task_struct', 'signal')
    prev_offset = ramdump.field_offset('struct list_head','prev')
    offset_adj = ramdump.field_offset('struct signal_struct', 'oom_score_adj')
    offset_thread_group = ramdump.field_offset(
        'struct task_struct', 'thread_group')
    offset_pid = ramdump.field_offset('struct task_struct', 'pid')
    init_addr = ramdump.address_of('init_task')
    init_next_task = init_addr + offset_tasks
    orig_init_next_task = init_next_task
    init_thread_group = init_addr + offset_thread_group
    seen_tasks = set()
    task_info = []
    offset_thread_group = ramdump.field_offset(
        'struct task_struct', 'thread_group')
    memory_file = ramdump.open_file('memory.txt')
    memory_file.write('Total RAM: {0:,}kB\n'.format(total_mem))
    memory_file.write('Total free memory: {0:,}kB({1:.1f}%)\n'.format(
            total_free * 4, (100.0 * total_free * 4) / total_mem))
    memory_file.write('Slab reclaimable: {0:,}kB({1:.1f}%)\n'.format(
            slab_rec * 4, (100.0 * slab_rec * 4) / total_mem))
    memory_file.write('Slab unreclaimable: {0:,}kB({1:.1f}%)\n'.format(
            slab_unrec * 4, (100.0 * slab_unrec * 4) / total_mem))
    memory_file.write('Total Slab memory: {0:,}kB({1:.1f}%)\n'.format(
            total_slab * 4, (100.0 * total_slab * 4) / total_mem))
    memory_file.write('Total SHMEM: {0:,}kB({1:.1f}%)\n\n'.format(
        total_shmem * 4, (100.0 * total_shmem * 4) / total_mem))
    while True:
        task_struct = init_thread_group - offset_thread_group
        next_thread_comm = task_struct + offset_comm
        thread_task_name = cleanupString(
            ramdump.read_cstring(next_thread_comm, 16))
        next_thread_pid = task_struct + offset_pid
        thread_task_pid = ramdump.read_int(next_thread_pid)
        signal_struct = ramdump.read_word(task_struct + offset_signal)

        next_task = ramdump.read_word(init_next_task)
        if next_task is None:
            init_next_task = init_addr + offset_tasks
            init_next_task = init_next_task + prev_offset
            init_next_task = ramdump.read_word(init_next_task)
            init_thread_group = init_next_task - offset_tasks \
                                + offset_thread_group
            while True:
                init_next_task = init_next_task + prev_offset
                orig_init_next_task = init_next_task
                task_struct = init_thread_group - offset_thread_group
                next_thread_comm = task_struct + offset_comm
                thread_task_name = cleanupString(
                    ramdump.read_cstring(next_thread_comm, 16))
                next_thread_pid = task_struct + offset_pid
                thread_task_pid = ramdump.read_int(next_thread_pid)
                signal_struct = ramdump.read_word(task_struct + offset_signal)
                next_task = ramdump.read_word(init_next_task)
                if next_task is None:
                    break
                if (next_task == init_next_task and
                            next_task != orig_init_next_task):
                    break
                if next_task in seen_tasks:
                    break
                seen_tasks.add(next_task)
                init_next_task = next_task
                init_thread_group = init_next_task - offset_tasks\
                                    + offset_thread_group
                if init_next_task == orig_init_next_task:
                    break

                if signal_struct == 0 or signal_struct is None:
                    continue
                adj = ramdump.read_u16(signal_struct + offset_adj)
                if adj & 0x8000:
                    adj = adj - 0x10000
                rss, swap = get_rss(ramdump, task_struct)
                if rss != 0:
                    task_info.append([thread_task_name, thread_task_pid, rss,
                                      swap, rss + swap, adj])
            break

        if (next_task == init_next_task and
                next_task != orig_init_next_task):
            break

        if next_task in seen_tasks:
            break

        seen_tasks.add(next_task)
        init_next_task = next_task
        init_thread_group = init_next_task - offset_tasks + offset_thread_group
        if init_next_task == orig_init_next_task:
            break

        if signal_struct == 0 or signal_struct is None:
            continue

        adj = ramdump.read_u16(signal_struct + offset_adj)
        if adj & 0x8000:
            adj = adj - 0x10000
        rss, swap = get_rss(ramdump, task_struct)
        if rss != 0:
            task_info.append([thread_task_name, thread_task_pid, rss, swap, rss + swap, adj])

    task_info = sorted(task_info, key=lambda l: l[4], reverse=True)
    str = '{0:<17s}{1:>8s}{2:>19s}{3:>12s}{4:>8}\n'.format(
        'Task name', 'PID', 'RSS in kB', 'SWAP in kB', 'ADJ')
    memory_file.write(str)
    for item in task_info:
        str = '{0:<17s}{1:8d}{2:13,d}({4:2.1f}%){3:13,d} {5:6}\n'.format(
            item[0], item[1], item[2], item[3], (100.0 * item[2]) / total_mem, item[5])
        memory_file.write(str)
    memory_file.close()
    print_out_str('---wrote meminfo to memory.txt')


def get_rss(ramdump, task_struct):
    offset_mm = ramdump.field_offset('struct task_struct', 'mm')
    offset_rss_stat = ramdump.field_offset('struct mm_struct', 'rss_stat')
    offset_file_rss = ramdump.field_offset('struct mm_rss_stat', 'count')
    offset_anon_rss = ramdump.field_offset('struct mm_rss_stat', 'count[1]')
    offset_swap_rss = ramdump.field_offset('struct mm_rss_stat', 'count[2]')
    if ramdump.kernel_version >= (4, 9):
        offset_shmem_rss = ramdump.field_offset('struct mm_rss_stat', 'count[3]')
    mm_struct = ramdump.read_word(task_struct + offset_mm)
    if mm_struct == 0:
        return 0, 0
    anon_rss = ramdump.read_word(mm_struct + offset_rss_stat + offset_anon_rss)
    swap_rss = ramdump.read_word(mm_struct + offset_rss_stat + offset_swap_rss)
    file_rss = ramdump.read_word(mm_struct + offset_rss_stat + offset_file_rss)
    if ramdump.kernel_version >= (4, 9):
        shmem_rss = ramdump.read_word(mm_struct + offset_rss_stat + offset_shmem_rss)
    else:
        shmem_rss = 0
    # Ignore negative RSS values
    if anon_rss > 0x80000000:
        anon_rss = 0
    if swap_rss > 0x80000000:
        swap_rss = 0
    if file_rss > 0x80000000:
        file_rss = 0
    if shmem_rss > 0x80000000:
        shmem_rss = 0
    total_rss = anon_rss + file_rss + shmem_rss
    return total_rss * 4, swap_rss * 4


@register_parser('--print-memory-info', 'Print memory usage info')
class DumpProcessMemory(RamParser):

    def parse(self):
        do_dump_process_memory(self.ramdump)
