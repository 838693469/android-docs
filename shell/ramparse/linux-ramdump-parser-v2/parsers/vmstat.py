# Copyright (c) 2013-2015, 2017 The Linux Foundation. All rights reserved.
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
from parser_util import register_parser, RamParser


@register_parser('--print-vmstats', 'Print the information similar to /proc/zoneinfo and /proc/vmstat')
class ZoneInfo(RamParser):

    def print_zone_stats(self, zone, vmstat_names, max_zone_stats):
        nr_watermark = self.ramdump.gdbmi.get_value_of('NR_WMARK')
        wmark_names = self.ramdump.gdbmi.get_enum_lookup_table(
            'zone_watermarks', nr_watermark)

        zone_name_offset = self.ramdump.field_offset('struct zone', 'name')
        zname_addr = self.ramdump.read_word(zone + zone_name_offset)
        zname = self.ramdump.read_cstring(zname_addr, 12)

        zstats_addr = zone + \
            self.ramdump.field_offset('struct zone', 'vm_stat')
        zwatermark_addr = zone + \
            self.ramdump.field_offset('struct zone', 'watermark')

        print_out_str('\nZone {0:8}'.format(zname))
        for i in xrange(0, max_zone_stats):
            print_out_str('{0:30}: {1:8}'.format(vmstat_names[i], self.ramdump.read_word(
                self.ramdump.array_index(zstats_addr, 'atomic_long_t', i))))

        for i in xrange(0, nr_watermark):
            print_out_str('{0:30}: {1:8}'.format(wmark_names[i], self.ramdump.read_word(
                self.ramdump.array_index(zwatermark_addr, 'unsigned long', i))))

    def parse(self):
        max_zone_stats = self.ramdump.gdbmi.get_value_of(
            'NR_VM_ZONE_STAT_ITEMS')
        vmstat_names = self.ramdump.gdbmi.get_enum_lookup_table(
            'zone_stat_item', max_zone_stats)
        max_nr_zones = self.ramdump.gdbmi.get_value_of('__MAX_NR_ZONES')

        contig_page_data = self.ramdump.address_of('contig_page_data')
        node_zones_offset = self.ramdump.field_offset(
            'struct pglist_data', 'node_zones')
        present_pages_offset = self.ramdump.field_offset(
            'struct zone', 'present_pages')
        sizeofzone = self.ramdump.sizeof('struct zone')
        zone = contig_page_data + node_zones_offset

        while zone < (contig_page_data + node_zones_offset + max_nr_zones * sizeofzone):
            present_pages = self.ramdump.read_word(zone + present_pages_offset)
            if not not present_pages:
                self.print_zone_stats(zone, vmstat_names, max_zone_stats)

            zone = zone + sizeofzone

        print_out_str('\nGlobal Stats')
        if self.ramdump.kernel_version < (4,9,0):
            vmstats_addr = self.ramdump.address_of('vm_stat')
        else:
            vmstats_addr = self.ramdump.address_of('vm_zone_stat')
        for i in xrange(0, max_zone_stats):
            print_out_str('{0:30}: {1:8}'.format(vmstat_names[i], self.ramdump.read_word(
                self.ramdump.array_index(vmstats_addr, 'atomic_long_t', i))))
        print_out_str('Total system pages: {0}'.format(self.ramdump.read_word(
            self.ramdump.address_of('totalram_pages'))))
