# Copyright (c) 2013-2018, The Linux Foundation. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

import bitops


def page_buddy(ramdump, page):
    mapcount_offset = ramdump.field_offset('struct page', '_mapcount')
    val = ramdump.read_int(page + mapcount_offset)
    # -128 is the magic for in the buddy allocator
    return val == 0xffffff80


def page_count(ramdump, page):
    """Commit: 0139aa7b7fa12ceef095d99dc36606a5b10ab83a
    mm: rename _count, field of the struct page, to _refcount"""
    if (ramdump.kernel_version < (4, 6, 0)):
        count = ramdump.read_structure_field(page, 'struct page',
                                             '_count.counter')
    else:
        count = ramdump.read_structure_field(page, 'struct page',
                                             '_refcount.counter')
    return count


def page_ref_count(ramdump, page):
    return page_count(ramdump, page)

def get_debug_flags(ramdump, page):
    debug_flag_offset = ramdump.field_offset('struct page', 'debug_flags')
    flagval = ramdump.read_word(page + debug_flag_offset)
    return flagval


def page_zonenum(page_flags):
    # save this in a variable somewhere...
    return (page_flags >> 26) & 3


def page_to_nid(page_flags):
    return 0


def page_zone(ramdump, page):
    contig_page_data = ramdump.address_of('contig_page_data')
    node_zones_offset = ramdump.field_offset(
        'struct pglist_data', 'node_zones')
    page_flags_offset = ramdump.field_offset('struct page', 'flags')
    zone_size = ramdump.sizeof('struct zone')
    page_flags = ramdump.read_word(page + page_flags_offset)
    if page_flags is None:
        return None
    zone = contig_page_data + node_zones_offset + \
        (page_zonenum(page_flags) * zone_size)
    return zone


def zone_is_highmem(ramdump, zone):
    if not ramdump.is_config_defined('CONFIG_HIGHMEM'):
        return False

    if zone is None:
        return False
    # not at all how linux does it but it works for our purposes...
    zone_name_offset = ramdump.field_offset('struct zone', 'name')
    zone_name_addr = ramdump.read_word(zone + zone_name_offset)
    if zone_name_addr is None:
        return False
    zone_name = ramdump.read_cstring(zone_name_addr, 48)
    if zone_name is None:
        # XXX do something?
        return False
    if zone_name == 'HighMem':
        return True
    else:
        return False


def hash32(val, bits):
    chash = c_uint(val * 0x9e370001).value
    return chash >> (32 - bits)


def page_slot(ramdump, page):
    hashed = hash32(page, 7)
    htable = ramdump.address_of('page_address_htable')
    htable_size = ramdump.sizeof('page_address_htable[0]')
    return htable + htable_size * hashed


def page_to_section(page_flags):
    # again savefn8n variable
    return (page_flags >> 28) & 0xF


def nr_to_section(ramdump, sec_num):
    memsection_struct_size = ramdump.sizeof('struct mem_section')
    sections_per_root = 4096 / memsection_struct_size
    sect_nr_to_root = sec_num / sections_per_root
    masked = sec_num & (sections_per_root - 1)
    mem_section_addr = ramdump.address_of('mem_section')
    mem_section = ramdump.read_word(mem_section_addr)
    if mem_section is None:
        return None
    return mem_section + memsection_struct_size * (sect_nr_to_root * sections_per_root + masked)


def section_mem_map_addr(ramdump, section):
    map_offset = ramdump.field_offset('struct mem_section', 'section_mem_map')
    result = ramdump.read_word(section + map_offset)
    return result & ~((1 << 2) - 1)


def pfn_to_section_nr(pfn):
    return pfn >> (28 - 12)


def pfn_to_section(ramdump, pfn):
    return nr_to_section(ramdump, pfn_to_section_nr(pfn))


def pfn_to_page_sparse(ramdump, pfn):
    sec = pfn_to_section(ramdump, pfn)
    sizeof_page = ramdump.sizeof('struct page')
    return section_mem_map_addr(ramdump, sec) + pfn * sizeof_page


def page_to_pfn_sparse(ramdump, page):
    page_flags_offset = ramdump.field_offset('struct page', 'flags')
    sizeof_page = ramdump.sizeof('struct page')
    flags = ramdump.read_word(page + page_flags_offset)
    if flags is None:
        return 0
    section = page_to_section(flags)
    nr = nr_to_section(ramdump, section)
    addr = section_mem_map_addr(ramdump, nr)
    # divide by struct page size for division fun
    return (page - addr) / sizeof_page


def get_vmemmap(ramdump):
    # See: include/asm-generic/pgtable-nopud.h,
    # arch/arm64/include/asm/pgtable-hwdef.h,
    # arch/arm64/include/asm/pgtable.h
    # kernel/arch/arm64/include/asm/memory.h
    if (ramdump.kernel_version < (3, 18, 0)):
        nlevels = int(ramdump.get_config_val("CONFIG_ARM64_PGTABLE_LEVELS"))
    else:
        nlevels = int(ramdump.get_config_val("CONFIG_PGTABLE_LEVELS"))

    if ramdump.is_config_defined("CONFIG_ARM64_64K_PAGES"):
        page_shift = 16
    else:
        page_shift = 12
    pgdir_shift = ((page_shift - 3) * nlevels) + 3
    pud_shift = pgdir_shift
    pud_size = 1 << pud_shift
    va_bits = int(ramdump.get_config_val("CONFIG_ARM64_VA_BITS"))
    spsize = ramdump.sizeof('struct page')
    vmemmap_size = bitops.align((1 << (va_bits - page_shift)) * spsize,
                                pud_size)

    memstart_addr = ramdump.read_s64('memstart_addr')
    page_section_mask = ~((1 << 18) - 1)
    memstart_offset = (memstart_addr >> page_shift) & page_section_mask
    memstart_offset *= spsize

    if (ramdump.kernel_version < (3, 18, 31)):
        # vmalloc_end = 0xFFFFFFBC00000000
        vmemmap = ramdump.page_offset - pud_size - vmemmap_size
    elif (ramdump.kernel_version < (4, 9, 0)):
        # for version >= 3.18.31,
        # vmemmap is shifted to base addr (0x80000000) pfn.
        vmemmap = (ramdump.page_offset - pud_size - vmemmap_size -
                   memstart_offset)
    else:
        # for version >= 4.9.0,
        # vmemmap_size = ( 1 << (39 - 12 - 1 + 6))
        struct_page_max_shift = 6
        vmemmap_size = ( 1 << (va_bits - page_shift - 1 + struct_page_max_shift))
        vmemmap = ramdump.page_offset - vmemmap_size - memstart_offset
    return vmemmap


def page_to_pfn_vmemmap(ramdump, page):
    vmemmap = get_vmemmap(ramdump)
    page_size = ramdump.sizeof('struct page')
    return ((page - vmemmap) / page_size)


def pfn_to_page_vmemmap(ramdump, pfn):
    vmemmap = get_vmemmap(ramdump)
    page_size = ramdump.sizeof('struct page')
    return vmemmap + (pfn * page_size)


def page_to_pfn_flat(ramdump, page):
    mem_map_addr = ramdump.address_of('mem_map')
    mem_map = ramdump.read_word(mem_map_addr)
    page_size = ramdump.sizeof('struct page')
    # XXX Needs to change for LPAE
    pfn_offset = ramdump.phys_offset >> 12
    return ((page - mem_map) / page_size) + pfn_offset


def pfn_to_page_flat(ramdump, pfn):
    mem_map_addr = ramdump.address_of('mem_map')
    mem_map = ramdump.read_word(mem_map_addr)
    page_size = ramdump.sizeof('struct page')
    # XXX Needs to change for LPAE
    pfn_offset = ramdump.phys_offset >> 12
    return mem_map + ((pfn - pfn_offset) * page_size)


def page_to_pfn(ramdump, page):
    if ramdump.arm64:
        return page_to_pfn_vmemmap(ramdump, page)
    if ramdump.is_config_defined('CONFIG_SPARSEMEM'):
        return page_to_pfn_sparse(ramdump, page)
    else:
        return page_to_pfn_flat(ramdump, page)


def pfn_to_page(ramdump, pfn):
    if ramdump.arm64:
        return pfn_to_page_vmemmap(ramdump, pfn)
    if ramdump.is_config_defined('CONFIG_SPARSEMEM'):
        return pfn_to_page_sparse(ramdump, pfn)
    else:
        return pfn_to_page_flat(ramdump, pfn)


def sparsemem_lowmem_page_address(ramdump, page):
    membank1_start = ramdump.read_word(ramdump.address_of('membank1_start'))
    membank0_size = ramdump.read_word(ramdump.address_of('membank0_size'))
    # XXX currently magic
    membank0_phys_offset = ramdump.phys_offset
    membank0_page_offset = ramdump.page_offset
    membank1_phys_offset = membank1_start
    membank1_page_offset = membank0_page_offset + membank0_size
    phys = page_to_pfn(ramdump, page) << 12
    if phys >= membank1_start:
        return phys - membank1_phys_offset + membank1_page_offset
    else:
        return phys - membank0_phys_offset + membank0_page_offset


def dont_map_hole_lowmem_page_address(ramdump, page):
    phys = page_to_pfn(ramdump, page) << 12
    hole_end_addr = ramdump.address_of('memory_hole_end')
    if hole_end_addr is None:
        hole_end_addr = ramdump.address_of('membank1_start')
    hole_offset_addr = ramdump.address_of('memory_hole_offset')
    if hole_offset_addr is None:
        hole_offset_addr = ramdump.address_of('membank0_size')
    hole_end = ramdump.read_word(hole_end_addr)
    hole_offset = ramdump.read_word(hole_offset_addr)
    if hole_end != 0 and phys >= hole_end:
        return phys - hole_end + hole_offset + ramdump.page_offset
    else:
        return phys - ramdump.phys_offset + ramdump.page_offset


def normal_lowmem_page_address(ramdump, page):
    phys = page_to_pfn(ramdump, page) << 12
    if ramdump.arm64:
        memstart_addr = ramdump.read_s64('memstart_addr')
        return phys - memstart_addr + ramdump.page_offset
    else:
        return phys - ramdump.phys_offset + ramdump.page_offset


def lowmem_page_address(ramdump, page):
    if ramdump.is_config_defined('CONFIG_SPARSEMEM') and not ramdump.arm64:
        return sparsemem_lowmem_page_address(ramdump, page)
    elif ramdump.is_config_defined('CONFIG_DONT_MAP_HOLE_AFTER_MEMBANK0'):
        return dont_map_hole_lowmem_page_address(ramdump, page)
    else:
        return normal_lowmem_page_address(ramdump, page)


def page_address(ramdump, page):
    if not zone_is_highmem(ramdump, page_zone(ramdump, page)):
        return lowmem_page_address(ramdump, page)

    pas = page_slot(ramdump, page)
    lh_offset = ramdump.field_offset('struct page_address_slot', 'lh')
    start = pas + lh_offset
    pam = start
    while True:
        pam = pam - lh_offset
        pam_page_offset = ramdump.field_offset(
            'struct page_address_map', 'page')
        pam_virtual_offset = ramdump.field_offset(
            'struct page_address_map', 'virtual')
        pam_page = ramdump.read_word(pam + pam_page_offset)
        if pam_page == page:
            ret = ramdump.read_word(pam + pam_virtual_offset)
            return ret
        pam = ramdump.read_word(pam + lh_offset)
        if pam == start:
            return None

def phys_to_virt(ramdump, phys):
    if not ramdump.arm64:
        return phys - ramdump.phys_offset + ramdump.page_offset

    if ramdump.kernel_version < (4, 4, 0):
        return None

    memstart_addr = ramdump.read_s64('memstart_addr')
    val = (phys - memstart_addr) | ramdump.page_offset
    return val

def for_each_pfn(ramdump):
    """ creates a generator for looping through valid pfn
    Example:
    for i in for_each_pfn(ramdump):
        page = pfn_to_page(i)
    """
    page_size = (1 << 12)
    cnt = ramdump.read_structure_field('memblock', 'struct memblock',
                                       'memory.cnt')
    region = ramdump.read_structure_field('memblock', 'struct memblock',
                                          'memory.regions')
    memblock_region_size = ramdump.sizeof('struct memblock_region')
    for i in range(cnt):
        start = ramdump.read_structure_field(region, 'struct memblock_region',
                                             'base')
        end = start + ramdump.read_structure_field(
                            region, 'struct memblock_region', 'size')

        pfn = start / page_size
        end /= page_size
        while pfn < end:
            yield pfn
            pfn += 1

        region += memblock_region_size
