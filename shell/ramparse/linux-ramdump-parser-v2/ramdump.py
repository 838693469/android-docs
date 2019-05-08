# Copyright (c) 2012-2018, The Linux Foundation. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

import sys
import re
import os
import struct
import gzip
import functools
import string
import random
import platform
import stat

from boards import get_supported_boards, get_supported_ids
from tempfile import NamedTemporaryFile

import gdbmi
from print_out import print_out_str
from mmu import Armv7MMU, Armv7LPAEMMU, Armv8MMU
import parser_util
import minidump_util
from importlib import import_module
import module_table

FP = 11
SP = 13
LR = 14
PC = 15

# The smem code is very stable and unlikely to go away or be changed.
# Rather than go through the hassel of parsing the id through gdb,
# just hard code it

SMEM_HW_SW_BUILD_ID = 0x89
BUILD_ID_LENGTH = 32

first_mem_file_names = ['EBICS0.BIN',
                        'EBI1.BIN', 'DDRCS0.BIN', 'ebi1_cs0.bin', 'DDRCS0_0.BIN']
extra_mem_file_names = ['EBI1CS1.BIN', 'DDRCS1.BIN', 'ebi1_cs1.bin',
                        'DDRCS0_1.BIN', 'DDRCS1_0.BIN', 'DDRCS1_1.BIN',
                        'DDRCS1_2.BIN', 'DDRCS1_3.BIN', 'DDRCS1_4.BIN',
                        'DDRCS1_5.BIN']

DDR_FILE_NAMES = ['DDRCS0.BIN', 'DDRCS1.BIN', 'DDRCS0_0.BIN',
                  'DDRCS1_0.BIN', 'DDRCS0_1.BIN', 'DDRCS1_1.BIN',
                  'DDR_0.BIN', 'DDR_1.BIN', 'DDR_2.BIN', 'DDR_3.BIN',
                  'RESET_INFO.BIN']
OTHER_DUMP_FILE_NAMES = ['PIMEM.BIN', 'OCIMEM.BIN','md_shared_imem.BIN',
                         'md_smem_info.BIN']
RAM_FILE_NAMES = set(DDR_FILE_NAMES +
                     OTHER_DUMP_FILE_NAMES +
                     first_mem_file_names +
                     extra_mem_file_names)


class AutoDumpInfo(object):
    priority = 0

    def __init__(self, autodumpdir):
        self.autodumpdir = autodumpdir
        self.ebi_files = []

    def parse(self):
        for (filename, base_addr) in self._parse():
            fullpath = os.path.join(self.autodumpdir, filename)
            if not os.path.exists(fullpath):
                continue
            end = base_addr + os.path.getsize(fullpath) - 1
            self.ebi_files.append((open(fullpath, 'rb'), base_addr, end, fullpath))
            # sort by addr, DDR files first. The goal is for
            # self.ebi_files[0] to be the DDR file with the lowest address.
            self.ebi_files.sort(
                key=lambda x: (os.path.basename(x[-1]) not in DDR_FILE_NAMES,
                               x[1]))

    def _parse(self):
        # Implementations should return an interable of (filename, base_addr)
        raise NotImplementedError


class AutoDumpInfoCMM(AutoDumpInfo):
    # Parses CMM scripts (like load.cmm)
    def _parse(self):
        filename = 'load.cmm'
        if not os.path.exists(os.path.join(self.autodumpdir, filename)):
            print_out_str('!!! AutoParse could not find load.cmm!')
            return

        with open(os.path.join(self.autodumpdir, filename)) as f:
            for line in f.readlines():
                words = line.split()
                if len(words) == 4 and words[1] in RAM_FILE_NAMES:
                    fname = words[1]
                    start = int(words[2], 16)
                    yield fname, start


class AutoDumpInfoDumpInfoTXT(AutoDumpInfo):
    # Parses dump_info.txt
    priority = 1

    def _parse(self):
        filename = 'dump_info.txt'
        if not os.path.exists(os.path.join(self.autodumpdir, filename)):
            print_out_str('!!! AutoParse could not find dump_info.txt!')
            return

        with open(os.path.join(self.autodumpdir, filename)) as f:
            for line in f.readlines():
                words = line.split()
                if not words or words[-1] not in RAM_FILE_NAMES:
                    continue
                fname = words[-1]
                start = int(words[1], 16)
                size = int(words[2])
                filesize = os.path.getsize(
                    os.path.join(self.autodumpdir, fname))
                if size != filesize:
                    print_out_str(
                        ("!!! Size of %s on disk (%d) doesn't match size " +
                         "from dump_info.txt (%d). Skipping...")
                        % (fname, filesize, size))
                    continue
                yield fname, start


class RamDump():
    """The main interface to the RAM dump"""

    class Unwinder ():

        class Stackframe ():

            def __init__(self, fp, sp, lr, pc):
                self.fp = fp
                self.sp = sp
                self.lr = lr
                self.pc = pc

        class UnwindCtrlBlock ():

            def __init__(self):
                self.vrs = 16 * [0]
                self.insn = 0
                self.entries = -1
                self.byte = -1
                self.index = 0

        def __init__(self, ramdump):
            start = ramdump.address_of('__start_unwind_idx')
            end = ramdump.address_of('__stop_unwind_idx')
            self.ramdump = ramdump
            if (start is None) or (end is None):
                if ramdump.arm64:
                    self.unwind_frame = self.unwind_frame_generic64
                else:
                    self.unwind_frame = self.unwind_frame_generic
                return None
            # addresses
            self.unwind_frame = self.unwind_frame_tables
            self.start_idx = start
            self.stop_idx = end
            self.unwind_table = []
            i = 0
            for addr in range(start, end, 8):
                r = ramdump.read_string(addr, '<II')
                if r is None:
                    break
                (a, b) = r
                self.unwind_table.append((a, b, start + 8 * i))
                i += 1

            ver = ramdump.version
            if re.search('3.0.\d', ver) is not None:
                self.search_idx = self.search_idx_3_0
            else:
                self.search_idx = self.search_idx_3_4
                # index into the table
                self.origin = self.unwind_find_origin()

        def unwind_find_origin(self):
            start = 0
            stop = len(self.unwind_table)
            while (start < stop):
                mid = start + ((stop - start) >> 1)
                if (self.unwind_table[mid][0] >= 0x40000000):
                    start = mid + 1
                else:
                    stop = mid
            return stop

        def unwind_frame_generic64(self, frame):
            fp = frame.fp
            low = frame.sp
            mask = (self.ramdump.thread_size) - 1
            high = (low + mask) & (~mask)

            if (fp < low or fp > high or fp & 0xf):
                return

            frame.sp = fp + 0x10
            frame.fp = self.ramdump.read_word(fp)
            frame.pc = self.ramdump.read_word(fp + 8)
            return 0

        def unwind_frame_generic(self, frame):
            high = 0
            fp = frame.fp

            low = frame.sp
            mask = (self.ramdump.thread_size) - 1

            high = (low + mask) & (~mask)  # ALIGN(low, THREAD_SIZE)

            # /* check current frame pointer is within bounds */
            if (fp < (low + 12) or fp + 4 >= high):
                return -1

            fp_is_at = self.ramdump.read_word(frame.fp - 12)
            sp_is_at = self.ramdump.read_word(frame.fp - 8)
            pc_is_at = self.ramdump.read_word(frame.fp - 4)

            frame.fp = fp_is_at
            frame.sp = sp_is_at
            frame.pc = pc_is_at

            return 0

        def walk_stackframe_generic(self, frame):
            while True:
                symname = self.ramdump.addr_to_symbol(frame.pc)
                print_out_str(symname)

                ret = self.unwind_frame_generic(frame)
                if ret < 0:
                    break

        def unwind_backtrace_generic(self, sp, fp, pc):
            frame = self.Stackframe()
            frame.fp = fp
            frame.pc = pc
            frame.sp = sp
            walk_stackframe_generic(frame)

        def search_idx_3_4(self, addr):
            start = 0
            stop = len(self.unwind_table)
            orig = addr

            if (addr < self.start_idx):
                stop = self.origin
            else:
                start = self.origin

            if (start >= stop):
                return None

            addr = (addr - self.unwind_table[start][2]) & 0x7fffffff

            while (start < (stop - 1)):
                mid = start + ((stop - start) >> 1)

                dif = (self.unwind_table[mid][2]
                       - self.unwind_table[start][2])
                if ((addr - dif) < self.unwind_table[mid][0]):
                    stop = mid
                else:
                    addr = addr - dif
                    start = mid

            if self.unwind_table[start][0] <= addr:
                return self.unwind_table[start]
            else:
                return None

        def search_idx_3_0(self, addr):
            first = 0
            last = len(self.unwind_table)
            while (first < last - 1):
                mid = first + ((last - first + 1) >> 1)
                if (addr < self.unwind_table[mid][0]):
                    last = mid
                else:
                    first = mid

            return self.unwind_table[first]

        def unwind_get_byte(self, ctrl):

            if (ctrl.entries <= 0):
                print_out_str('unwind: Corrupt unwind table')
                return 0

            val = self.ramdump.read_word(ctrl.insn)

            ret = (val >> (ctrl.byte * 8)) & 0xff

            if (ctrl.byte == 0):
                ctrl.insn += 4
                ctrl.entries -= 1
                ctrl.byte = 3
            else:
                ctrl.byte -= 1

            return ret

        def unwind_exec_insn(self, ctrl):
            insn = self.unwind_get_byte(ctrl)

            if ((insn & 0xc0) == 0x00):
                ctrl.vrs[SP] += ((insn & 0x3f) << 2) + 4
            elif ((insn & 0xc0) == 0x40):
                ctrl.vrs[SP] -= ((insn & 0x3f) << 2) + 4
            elif ((insn & 0xf0) == 0x80):
                vsp = ctrl.vrs[SP]
                reg = 4

                insn = (insn << 8) | self.unwind_get_byte(ctrl)
                mask = insn & 0x0fff
                if (mask == 0):
                    print_out_str("unwind: 'Refuse to unwind' instruction")
                    return -1

                # pop R4-R15 according to mask */
                load_sp = mask & (1 << (13 - 4))
                while (mask):
                    if (mask & 1):
                        ctrl.vrs[reg] = self.ramdump.read_word(vsp)
                        if ctrl.vrs[reg] is None:
                            return -1
                        vsp += 4
                    mask >>= 1
                    reg += 1
                if not load_sp:
                    ctrl.vrs[SP] = vsp

            elif ((insn & 0xf0) == 0x90 and (insn & 0x0d) != 0x0d):
                ctrl.vrs[SP] = ctrl.vrs[insn & 0x0f]
            elif ((insn & 0xf0) == 0xa0):
                vsp = ctrl.vrs[SP]
                a = list(range(4, 4 + (insn & 7)))
                a.append(4 + (insn & 7))
                # pop R4-R[4+bbb] */
                for reg in (a):
                    ctrl.vrs[reg] = self.ramdump.read_word(vsp)
                    if ctrl.vrs[reg] is None:
                        return -1
                    vsp += 4
                if (insn & 0x80):
                    ctrl.vrs[14] = self.ramdump.read_word(vsp)
                    if ctrl.vrs[14] is None:
                        return -1
                    vsp += 4
                ctrl.vrs[SP] = vsp
            elif (insn == 0xb0):
                if (ctrl.vrs[PC] == 0):
                    ctrl.vrs[PC] = ctrl.vrs[LR]
                ctrl.entries = 0
            elif (insn == 0xb1):
                mask = self.unwind_get_byte(ctrl)
                vsp = ctrl.vrs[SP]
                reg = 0

                if (mask == 0 or mask & 0xf0):
                    print_out_str('unwind: Spare encoding')
                    return -1

                # pop R0-R3 according to mask
                while mask:
                    if (mask & 1):
                        ctrl.vrs[reg] = self.ramdump.read_word(vsp)
                        if ctrl.vrs[reg] is None:
                            return -1
                        vsp += 4
                    mask >>= 1
                    reg += 1
                ctrl.vrs[SP] = vsp
            elif (insn == 0xb2):
                uleb128 = self.unwind_get_byte(ctrl)
                ctrl.vrs[SP] += 0x204 + (uleb128 << 2)
            else:
                print_out_str('unwind: Unhandled instruction')
                return -1

            return 0

        def prel31_to_addr(self, addr):
            value = self.ramdump.read_word(addr)
            # offset = (value << 1) >> 1
            # C wants this sign extended. Python doesn't do that.
            # Sign extend manually.
            if (value & 0x40000000):
                offset = value | 0x80000000
            else:
                offset = value

            # This addition relies on integer overflow
            # Emulate this behavior
            temp = addr + offset
            return (temp & 0xffffffff) + ((temp >> 32) & 0xffffffff)

        def unwind_frame_tables(self, frame):
            low = frame.sp
            high = ((low + (self.ramdump.thread_size - 1)) & \
                ~(self.ramdump.thread_size - 1)) + self.ramdump.thread_size
            idx = self.search_idx(frame.pc)

            if (idx is None):
                return -1

            ctrl = self.UnwindCtrlBlock()
            ctrl.vrs[FP] = frame.fp
            ctrl.vrs[SP] = frame.sp
            ctrl.vrs[LR] = frame.lr
            ctrl.vrs[PC] = 0

            if (idx[1] == 1):
                return -1

            elif ((idx[1] & 0x80000000) == 0):
                ctrl.insn = self.prel31_to_addr(idx[2] + 4)

            elif (idx[1] & 0xff000000) == 0x80000000:
                ctrl.insn = idx[2] + 4
            else:
                print_out_str('not supported')
                return -1

            val = self.ramdump.read_word(ctrl.insn)

            if ((val & 0xff000000) == 0x80000000):
                ctrl.byte = 2
                ctrl.entries = 1
            elif ((val & 0xff000000) == 0x81000000):
                ctrl.byte = 1
                ctrl.entries = 1 + ((val & 0x00ff0000) >> 16)
            else:
                return -1

            while (ctrl.entries > 0):
                urc = self.unwind_exec_insn(ctrl)
                if (urc < 0):
                    return urc
                if (ctrl.vrs[SP] < low or ctrl.vrs[SP] >= high):
                    return -1

            if (ctrl.vrs[PC] == 0):
                ctrl.vrs[PC] = ctrl.vrs[LR]

            # check for infinite loop */
            if (frame.pc == ctrl.vrs[PC]):
                return -1

            frame.fp = ctrl.vrs[FP]
            frame.sp = ctrl.vrs[SP]
            frame.lr = ctrl.vrs[LR]
            frame.pc = ctrl.vrs[PC]

            return 0

        def unwind_backtrace(self, sp, fp, pc, lr, extra_str='',
                             out_file=None):
            offset = 0
            frame = self.Stackframe(fp, sp, lr, pc)
            frame.fp = fp
            frame.sp = sp
            frame.lr = lr
            frame.pc = pc

            while True:
                where = frame.pc
                offset = 0

                if frame.pc is None:
                    break

                r = self.ramdump.unwind_lookup(frame.pc)
                if r is None:
                    symname = 'UNKNOWN'
                    offset = 0x0
                else:
                    symname, offset = r
                pstring = (
                    extra_str + '[<{0:x}>] {1}+0x{2:x}'.format(frame.pc, symname, offset))
                if out_file:
                    out_file.write(pstring + '\n')
                else:
                    print_out_str(pstring)

                urc = self.unwind_frame(frame)
                if urc < 0:
                    break

    def __init__(self, options, nm_path, gdb_path, objdump_path):
        self.ebi_files = []
        self.ebi_files_minidump = []
        self.ebi_pa_name_map = {}
        self.phys_offset = None
        self.kaslr_offset = options.kaslr_offset
        self.tz_start = 0
        self.ebi_start = 0
        self.cpu_type = None
        self.hw_id = options.force_hardware or None
        self.hw_version = options.force_hardware_version or None
        self.offset_table = []
        self.vmlinux = options.vmlinux
        self.nm_path = nm_path
        self.gdb_path = gdb_path
        self.objdump_path = objdump_path
        self.outdir = options.outdir
        self.imem_fname = None
        self.gdbmi = gdbmi.GdbMI(self.gdb_path, self.vmlinux,
                                 self.kaslr_offset or 0)
        self.gdbmi.open()
        self.arm64 = options.arm64
        self.page_offset = 0xc0000000
        self.thread_size = 8192
        self.qtf_path = options.qtf_path
        self.qtf = options.qtf
        self.skip_qdss_bin = options.skip_qdss_bin
        self.dcc = False
        self.sysreg = False
        self.t32_host_system = options.t32_host_system or None
        self.ipc_log_test = options.ipc_test
        self.ipc_log_skip = options.ipc_skip
        self.ipc_log_debug = options.ipc_debug
        self.ipc_log_help = options.ipc_help
        self.use_stdout = options.stdout
        self.kernel_version = (0, 0, 0)
        self.minidump = options.minidump
        self.elffile = None
        self.ram_elf_file = None
        self.ram_addr = options.ram_addr
        self.autodump = options.autodump
        self.module_table = module_table.module_table_class()
        self.module_table.setup_sym_path(options.sym_path)
        if self.minidump:
            try:
                mod = import_module('elftools.elf.elffile')
                ELFFile = mod.ELFFile
                StringTableSection = mod.StringTableSection
                mod = import_module('elftools.common.py3compat')
                bytes2str = mod.bytes2str
            except ImportError:
                print "Oops, missing required library for minidump. Check README"
                sys.exit(1)

        if options.ram_addr is not None:
            # TODO sanity check to make sure the memory regions don't overlap
            for file_path, start, end in options.ram_addr:
                fd = open(file_path, 'rb')
                if not fd:
                    print_out_str(
                        'Could not open {0}. Will not be part of dump'.format(file_path))
                    continue
                self.ebi_files.append((fd, start, end, file_path))
        elif not options.minidump:
            if not self.auto_parse(options.autodump):
                return None
        if options.minidump:
            file_path = options.ram_elf_addr
            self.ram_elf_file = file_path
            fd = open(file_path, 'rb')
            self.elffile = ELFFile(fd)
            for idx, s in enumerate(self.elffile.iter_segments()):
                pa = int(s['p_paddr'])
                va = int(s['p_vaddr'])
                size = int(s['p_filesz'])
                end_addr = pa + size
                for section in self.elffile.iter_sections():
                    if (not section.is_null() and
                            s.section_in_segment(section)):
                        self.ebi_pa_name_map[pa] = section.name
                self.ebi_files_minidump.append((idx, pa, end_addr, va,size))

        if options.minidump:
            if self.ebi_start == 0:
                self.ebi_start = self.ebi_files_minidump[0][1]
        else:
            if self.ebi_start == 0:
                self.ebi_start = self.ebi_files[0][1]
        if self.phys_offset is None:
            self.get_hw_id()

        if self.kaslr_offset is None:
            self.determine_kaslr_offset()
            self.gdbmi.kaslr_offset = self.get_kaslr_offset()

        if options.phys_offset is not None:
            print_out_str(
                '[!!!] Phys offset was set to {0:x}'.format(\
                    options.phys_offset))
            self.phys_offset = options.phys_offset

        self.wlan = options.wlan
        self.lookup_table = []
        self.config = []
        self.config_dict = {}
        if self.arm64:
            self.page_offset = 0xffffffc000000000
            self.thread_size = 16384
        if options.page_offset is not None:
            print_out_str(
                '[!!!] Page offset was set to {0:x}'.format(page_offset))
            self.page_offset = options.page_offset
        self.setup_symbol_tables()

        va_bits = 39
        modules_vsize = 0x08000000
        self.va_start = (0xffffffffffffffff << va_bits) \
            & 0xffffffffffffffff
        if self.address_of("kasan_init") is None:
            self.kasan_shadow_size = 0
        else:
            self.kasan_shadow_size = 1 << (va_bits - 3)

        self.kimage_vaddr = self.va_start + self.kasan_shadow_size + \
            modules_vsize
        self.kimage_vaddr = self.kimage_vaddr + self.get_kaslr_offset()
        self.modules_end = self.page_offset
        self.kimage_voffset = self.address_of("kimage_voffset")
        if self.kimage_voffset is not None:
            self.kimage_voffset = self.kimage_vaddr - self.phys_offset
            self.modules_end = self.kimage_vaddr
            print_out_str("The kimage_voffset extracted is: {:x}".format(self.kimage_voffset))

        # The address of swapper_pg_dir can be used to determine
        # whether or not we're running with LPAE enabled since an
        # extra 4k is needed for LPAE. If it's 0x5000 below
        # PAGE_OFFSET + TEXT_OFFSET then we know we're using LPAE. For
        # non-LPAE it should be 0x4000 below PAGE_OFFSET + TEXT_OFFSET
        self.swapper_pg_dir_addr = self.address_of('swapper_pg_dir')
        if self.swapper_pg_dir_addr is None:
            print_out_str('!!! Could not get the swapper page directory!')
            if not self.minidump:
                print_out_str(
                    '!!! Your vmlinux is probably wrong for these dumps')

                print_out_str('!!! Exiting now')
                sys.exit(1)

        stext = self.address_of('stext')
        if self.kimage_voffset is None:
            self.kernel_text_offset = stext - self.page_offset
        else:
            self.kernel_text_offset = stext - self.kimage_vaddr

        pg_dir_size = self.kernel_text_offset + self.page_offset \
            - self.swapper_pg_dir_addr

        if self.arm64:
            print_out_str('Using 64bit MMU')
            self.mmu = Armv8MMU(self)
        elif pg_dir_size == 0x4000:
            print_out_str('Using non-LPAE MMU')
            self.mmu = Armv7MMU(self)
        elif pg_dir_size == 0x5000:
            print_out_str('Using LPAE MMU')
            text_offset = 0x8000
            pg_dir_size = 0x5000    # 0x4000 for non-LPAE
            swapper_pg_dir_addr = self.phys_offset + text_offset - pg_dir_size

            # We deduce ttbr1 and ttbcr.t1sz based on the value of
            # PAGE_OFFSET. This is based on v7_ttb_setup in
            # arch/arm/mm/proc-v7-3level.S:

            # * TTBR0/TTBR1 split (PAGE_OFFSET):
            # *   0x40000000: T0SZ = 2, T1SZ = 0 (not used)
            # *   0x80000000: T0SZ = 0, T1SZ = 1
            # *   0xc0000000: T0SZ = 0, T1SZ = 2
            if self.page_offset == 0x40000000:
                t1sz = 0
            elif self.page_offset == 0x80000000:
                t1sz = 1
            elif self.page_offset == 0xc0000000:
                t1sz = 2
                # need to fixup ttbr1 since we'll be skipping the
                # first-level lookup (see v7_ttb_setup):
                # /* PAGE_OFFSET == 0xc0000000, T1SZ == 2 */
                # add      \ttbr1, \ttbr1, #4096 * (1 + 3) @ only L2 used, skip
                # pgd+3*pmd
                swapper_pg_dir_addr += (4096 * (1 + 3))
            else:
                raise Exception(
                    'Invalid phys_offset for page_table_walk: 0x%x'
                    % self.page_offset)
            self.mmu = Armv7LPAEMMU(self, swapper_pg_dir_addr, t1sz)
        else:
            print_out_str(
                "!!! Couldn't determine whether or not we're using LPAE!")
            print_out_str(
                '!!! This is a BUG in the parser and should be reported.')
            sys.exit(1)

        if not self.get_version():
            print_out_str('!!! Could not get the Linux version!')
            print_out_str(
                '!!! Your vmlinux is probably wrong for these dumps')
            print_out_str('!!! Exiting now')
            sys.exit(1)
        if not self.minidump:
            if not self.get_config():
                print_out_str('!!! Could not get saved configuration')
                print_out_str(
                    '!!! This is really bad and probably indicates RAM corruption')
                print_out_str('!!! Some features may be disabled!')

        self.unwind = self.Unwinder(self)
        if self.module_table.sym_path_exists():
            self.setup_module_symbols()
            self.gdbmi.setup_module_table(self.module_table)

    def __del__(self):
        self.gdbmi.close()

    def open_file(self, file_name, mode='wb'):
        """Open a file in the out directory.

        Example:

        >>> with self.ramdump.open_file('pizza.txt') as p:
                p.write('Pizza is the best\\n')
        """
        file_path = os.path.join(self.outdir, file_name)
        f = None
        try:
            dir_path = os.path.dirname(file_path)
            if not os.path.exists(dir_path) and 'w' in mode:
                os.makedirs(dir_path)
            f = open(file_path, mode)
        except:
            print_out_str('Could not open path {0}'.format(file_path))
            print_out_str('Do you have write/read permissions on the path?')
            sys.exit(1)
        return f

    def remove_file(self, file_name):
	file_path = os.path.join(self.outdir, file_name)
	try:
	    if (os.path.exists(file_path)):
		os.remove(file_path)
	except:
	    print_out_str('Could not remove file {0}'.format(file_path))
	    print_out_str('Do you have write/read permissions on the path?')
	    sys.exit(1)

    def get_config(self):
        kconfig_addr = self.address_of('kernel_config_data')
        if kconfig_addr is None:
            return
        kconfig_size = self.sizeof('kernel_config_data')
        # size includes magic, offset from it
        kconfig_size = kconfig_size - 16 - 1
        zconfig = NamedTemporaryFile(mode='wb', delete=False)
        # kconfig data starts with magic 8 byte string, go past that
        s = self.read_cstring(kconfig_addr, 8)
        if s != 'IKCFG_ST':
            return
        kconfig_addr = kconfig_addr + 8
        for i in range(0, kconfig_size):
            val = self.read_byte(kconfig_addr + i)
            zconfig.write(struct.pack('<B', val))

        zconfig.close()
        zconfig_in = gzip.open(zconfig.name, 'rb')
        try:
            t = zconfig_in.readlines()
        except:
            return False
        zconfig_in.close()
        os.remove(zconfig.name)
        for l in t:
            self.config.append(l.rstrip().decode('ascii', 'ignore'))
            if not l.startswith('#') and l.strip() != '':
                eql = l.find('=')
                cfg = l[:eql]
                val = l[eql+1:]
                self.config_dict[cfg] = val.strip()
        return True

    def get_config_val(self, config):
        """Gets the value of a kernel config option.

        Example:

        >>> va_bits = int(dump.get_config_val("CONFIG_ARM64_VA_BITS"))
        39
        """
        return self.config_dict.get(config)

    def is_config_defined(self, config):
        s = config + '=y'
        return s in self.config

    def kernel_virt_to_phys(self, addr):
        if self.minidump:
            return minidump_util.minidump_virt_to_phys(self.ebi_files_minidump,addr)
        else:
            va_bits = 39
            if self.kimage_voffset is None:
                return addr - self.page_offset + self.phys_offset
            else:
                if addr & (1 << (va_bits - 1)):
                    return addr - self.page_offset + self.phys_offset
                else:
                    return addr - (self.kimage_voffset)

    def get_version(self):
        banner_addr = self.address_of('linux_banner')
        if banner_addr is not None:
            banner_addr = self.kernel_virt_to_phys(banner_addr)
            b = self.read_cstring(banner_addr, 256, False)
            if b is None:
                print_out_str('!!! Could not read banner address!')
                return False
            v = re.search('Linux version (\d{0,2}\.\d{0,2}\.\d{0,2})', b)
            if v is None:
                print_out_str('!!! Could not match version! {0}'.format(b))
                return False
            self.version = v.group(1)
            match = re.search('(\d+)\.(\d+)\.(\d+)', self.version)
            if match is not None:
                self.kernel_version = tuple(map(int, match.groups()))
            else:
                print_out_str('!!! Could not extract version info! {0}'.format(self.version))

            print_out_str('Linux Banner: ' + b.rstrip())
            print_out_str('version = {0}'.format(self.version))
            vm_v = self.gdbmi.get_value_of_string('linux_banner')
            if vm_v is None:
                print_out_str('!!! Could not read banner address from vmlinux!')
                return False
            if str(vm_v) in str(b):
                print_out_str("Linux banner from vmlinux = %s" % vm_v)
                print_out_str("Linux banner from dump = %s" % b)
                return True
            else:
                print_out_str("Expected Linux banner = %s" % vm_v)
                print_out_str("But Linux banner got = %s" % b)
                return False
        else:
            print_out_str('!!! Could not lookup banner address')
            return False

    def print_command_line(self):
        command_addr = self.address_of('saved_command_line')
        if command_addr is not None:
            command_addr = self.read_word(command_addr)
            b = self.read_cstring(command_addr, 2048)
            if b is None:
                print_out_str('!!! could not read saved command line address')
                return False
            print_out_str('Command Line: ' + b)
            return True
        else:
            print_out_str('!!! Could not lookup saved command line address')
            return False
        
    def print_socinfo_minidump(self):
        content_socinfo = None
        boards = get_supported_boards()
        for board in boards:
            if self.hw_id == board.board_num:
                content_socinfo = board.ram_start + board.smem_addr_buildinfo
                break
        sernum_offset = self.field_offset('struct socinfo_v10', 'serial_number')
        if sernum_offset is None:
            sernum_offset = self.field_offset('struct socinfo_v0_10', 'serial_number')
            if sernum_offset is None:
                print_out_str("No serial number information available")
                return False
        if content_socinfo:
            addr_of_sernum = content_socinfo + sernum_offset
            serial_number = self.read_u32(addr_of_sernum, False)
            if serial_number is not None:
                print_out_str('Serial number %s' % hex(serial_number))
                return True
            return False

        return False

    def print_socinfo(self):
        content_socinfo = hex(self.read_pointer('socinfo'))
        content_socinfo = content_socinfo.strip('L')

        sernum_offset = self.field_offset('struct socinfo_v10', 'serial_number')
        if sernum_offset is None:
            sernum_offset = self.field_offset('struct socinfo_v0_10', 'serial_number')
            if sernum_offset is None:
                print_out_str("No serial number information available")
                return False
        addr_of_sernum = hex(int(content_socinfo, 16) + sernum_offset)
        addr_of_sernum = addr_of_sernum.strip('L')
        serial_number = self.read_u32(int(addr_of_sernum, 16))
        if serial_number is not None:
            print_out_str('Serial number %s' % hex(serial_number))
            return True

        return False

    def auto_parse(self, file_path):
        for cls in sorted(AutoDumpInfo.__subclasses__(),
                          key=lambda x: x.priority, reverse=True):
            info = cls(file_path)
            info.parse()
            if info is not None and len(info.ebi_files) > 0:
                self.ebi_files = info.ebi_files
                self.phys_offset = self.ebi_files[0][1]
                if self.get_hw_id():
                    for (f, start, end, filename) in self.ebi_files:
                        print_out_str('Adding {0} {1:x}--{2:x}'.format(
                            filename, start, end))
                    return True
        self.ebi_files = None
        return False

    def create_t32_launcher(self):
        out_path = os.path.abspath(self.outdir)

        t32_host_system = self.t32_host_system or platform.system()

        launch_config = open(out_path + '/t32_config.t32', 'wb')
        launch_config.write('OS=\n')
        launch_config.write('ID=T32_1000002\n')
        if t32_host_system != 'Linux':
            launch_config.write('TMP=C:\\TEMP\n')
            launch_config.write('SYS=C:\\T32\n')
            launch_config.write('HELP=C:\\T32\\pdf\n')
        else:
            launch_config.write('TMP=/tmp\n')
            launch_config.write('SYS=/opt/t32\n')
            launch_config.write('HELP=/opt/t32/pdf\n')
        launch_config.write('\n')
        launch_config.write('PBI=SIM\n')
        launch_config.write('\n')
        launch_config.write('SCREEN=\n')
        if t32_host_system != 'Linux':
            launch_config.write('FONT=SMALL\n')
        else:
            launch_config.write('FONT=LARGE\n')
        launch_config.write('HEADER=Trace32-ScorpionSimulator\n')
        launch_config.write('\n')
        if t32_host_system != 'Linux':
            launch_config.write('PRINTER=WINDOWS\n')
        launch_config.write('\n')
        launch_config.write('RCL=NETASSIST\n')
        launch_config.write('PACKLEN=1024\n')
        launch_config.write('PORT=%d\n' % random.randint(20000, 30000))
        launch_config.write('\n')

        launch_config.close()

        startup_script = open(out_path + '/t32_startup_script.cmm', 'wb')

        startup_script.write(('title \"' + out_path + '\"\n').encode('ascii', 'ignore'))

        is_cortex_a53 = self.hw_id in ["8916", "8939", "8936"]

        if self.arm64 and is_cortex_a53:
            startup_script.write('sys.cpu CORTEXA53\n'.encode('ascii', 'ignore'))
        else:
            startup_script.write('sys.cpu {0}\n'.format(self.cpu_type).encode('ascii', 'ignore'))
        startup_script.write('sys.up\n'.encode('ascii', 'ignore'))

        for ram in self.ebi_files:
            ebi_path = os.path.abspath(ram[3])
            startup_script.write('data.load.binary {0} 0x{1:x}\n'.format(
                ebi_path, ram[1]).encode('ascii', 'ignore'))
        if self.minidump:
            dload_ram_elf = 'data.load.elf {} /LOGLOAD /nosymbol\n'.format(os.path.abspath(self.ram_elf_file))
            startup_script.write(dload_ram_elf.encode('ascii', 'ignore'))

        if not self.minidump:
            if self.arm64:
                startup_script.write('Register.Set NS 1\n'.encode('ascii', 'ignore'))
                startup_script.write('Data.Set SPR:0x30201 %Quad 0x{0:x}\n'.format(
                    self.kernel_virt_to_phys(self.swapper_pg_dir_addr))
                    .encode('ascii', 'ignore'))

                if is_cortex_a53:
                    startup_script.write('Data.Set SPR:0x30202 %Quad 0x00000012B5193519\n'.encode('ascii', 'ignore'))
                    startup_script.write('Data.Set SPR:0x30A20 %Quad 0x000000FF440C0400\n'.encode('ascii', 'ignore'))
                    startup_script.write('Data.Set SPR:0x30A30 %Quad 0x0000000000000000\n'.encode('ascii', 'ignore'))
                    startup_script.write('Data.Set SPR:0x30100 %Quad 0x0000000034D5D91D\n'.encode('ascii', 'ignore'))
                else:
                    startup_script.write('Data.Set SPR:0x30202 %Quad 0x00000032B5193519\n'.encode('ascii', 'ignore'))
                    startup_script.write('Data.Set SPR:0x30A20 %Quad 0x000000FF440C0400\n'.encode('ascii', 'ignore'))
                    startup_script.write('Data.Set SPR:0x30A30 %Quad 0x0000000000000000\n'.encode('ascii', 'ignore'))
                    startup_script.write('Data.Set SPR:0x30100 %Quad 0x0000000004C5D93D\n'.encode('ascii', 'ignore'))

                startup_script.write('Register.Set CPSR 0x3C5\n'.encode('ascii', 'ignore'))
                startup_script.write('MMU.Delete\n'.encode('ascii', 'ignore'))
                startup_script.write('MMU.SCAN PT 0xFFFFFF8000000000--0xFFFFFFFFFFFFFFFF\n'.encode('ascii', 'ignore'))
                startup_script.write('mmu.on\n'.encode('ascii', 'ignore'))
                startup_script.write('mmu.pt.list 0xffffff8000000000\n'.encode('ascii', 'ignore'))
            else:
                startup_script.write(
                    'PER.S.F C15:0x2 %L 0x{0:x}\n'.format(self.mmu.ttbr).encode('ascii', 'ignore'))
                if isinstance(self.mmu, Armv7LPAEMMU):
                    # TTBR1. This gets setup once and never change again even if TTBR0
                    # changes
                    startup_script.write('PER.S.F C15:0x102 %L 0x{0:x}\n'.format(
                        self.mmu.ttbr + 0x4000).encode('ascii', 'ignore'))
                    # TTBCR with EAE and T1SZ set approprately
                    startup_script.write(
                        'PER.S.F C15:0x202 %L 0x80030000\n'.encode('ascii', 'ignore'))
                startup_script.write('mmu.on\n'.encode('ascii', 'ignore'))
                startup_script.write('mmu.scan\n'.encode('ascii', 'ignore'))

        where = os.path.abspath(self.vmlinux)
        kaslr_offset = self.get_kaslr_offset()
        if kaslr_offset != 0:
            where += ' 0x{0:x}'.format(kaslr_offset)
        dloadelf = 'data.load.elf {} /nocode\n'.format(where)
        startup_script.write(dloadelf.encode('ascii', 'ignore'))

        if t32_host_system != 'Linux':
            if self.arm64:
                startup_script.write(
                     'task.config C:\\T32\\demo\\arm64\\kernel\\linux\\linux-3.x\\linux3.t32\n'.encode('ascii', 'ignore'))
                startup_script.write(
                     'menu.reprogram C:\\T32\\demo\\arm64\\kernel\\linux\\linux-3.x\\linux.men\n'.encode('ascii', 'ignore'))
            else:
                if self.kernel_version > (3, 0, 0):
                    startup_script.write(
                        'task.config c:\\t32\\demo\\arm\\kernel\\linux\\linux-3.x\\linux3.t32\n'.encode('ascii', 'ignore'))
                    startup_script.write(
                        'menu.reprogram c:\\t32\\demo\\arm\\kernel\\linux\\linux-3.x\\linux.men\n'.encode('ascii', 'ignore'))
                else:
                    startup_script.write(
                        'task.config c:\\t32\\demo\\arm\\kernel\\linux\\linux.t32\n'.encode('ascii', 'ignore'))
                    startup_script.write(
                        'menu.reprogram c:\\t32\\demo\\arm\\kernel\\linux\\linux.men\n'.encode('ascii', 'ignore'))
        else:
            if self.arm64:
                startup_script.write(
                    'task.config /opt/t32/demo/arm64/kernel/linux/linux-3.x/linux3.t32\n'.encode('ascii', 'ignore'))
                startup_script.write(
                    'menu.reprogram /opt/t32/demo/arm64/kernel/linux/linux-3.x/linux.men\n'.encode('ascii', 'ignore'))
            else:
                if self.kernel_version > (3, 0, 0):
                    startup_script.write(
                        'task.config /opt/t32/demo/arm/kernel/linux/linux-3.x/linux3.t32\n'.encode('ascii', 'ignore'))
                    startup_script.write(
                        'menu.reprogram /opt/t32/demo/arm/kernel/linux/linux-3.x/linux.men\n'.encode('ascii', 'ignore'))
                else:
                    startup_script.write(
                        'task.config /opt/t32/demo/arm/kernel/linux/linux.t32\n'.encode('ascii', 'ignore'))
                    startup_script.write(
                        'menu.reprogram /opt/t32/demo/arm/kernel/linux/linux.men\n'.encode('ascii', 'ignore'))

        for mod_tbl_ent in self.module_table.module_table:
            mod_sym_path = mod_tbl_ent.get_sym_path()
            if mod_sym_path != '':
                where = os.path.abspath(mod_sym_path)
                where += ' 0x{0:x}'.format(mod_tbl_ent.module_offset)
                dloadelf = 'data.load.elf {} /nocode /noclear\n'.format(where)
                startup_script.write(dloadelf.encode('ascii', 'ignore'))

        if not self.minidump:
            startup_script.write('task.dtask\n'.encode('ascii', 'ignore'))

        startup_script.write(
            'v.v  %ASCII %STRING linux_banner\n'.encode('ascii', 'ignore'))
        if os.path.exists(out_path + '/regs_panic.cmm'):
            startup_script.write(
                'do {0}\n'.format(out_path + '/regs_panic.cmm').encode('ascii', 'ignore'))
        elif os.path.exists(out_path + '/core0_regs.cmm'):
            startup_script.write(
                'do {0}\n'.format(out_path + '/core0_regs.cmm').encode('ascii', 'ignore'))
        startup_script.close()

        if t32_host_system != 'Linux':
            launch_file = os.path.join(out_path, 'launch_t32.bat')
            t32_bat = open(launch_file, 'wb')
            if self.arm64:
                t32_binary = 'C:\\T32\\bin\\windows64\\t32MARM64.exe'
            elif is_cortex_a53:
                t32_binary = 'C:\\T32\\bin\\windows64\\t32MARM.exe'
            else:
                t32_binary = 'c:\\t32\\t32MARM.exe'
            t32_bat.write(('start '+ t32_binary + ' -c ' + out_path + '/t32_config.t32, ' +
                          out_path + '/t32_startup_script.cmm').encode('ascii', 'ignore'))
            t32_bat.close()
        else:
            launch_file = os.path.join(out_path, 'launch_t32.sh')
            t32_sh = open(launch_file, 'wb')
            if self.arm64:
                t32_binary = '/opt/t32/bin/pc_linux64/t32marm64-qt'
            elif is_cortex_a53:
                t32_binary = '/opt/t32/bin/pc_linux64/t32marm-qt'
            else:
                t32_binary = '/opt/t32/bin/pc_linux64/t32marm-qt'
            t32_sh.write('#!/bin/sh\n\n')
            t32_sh.write('{0} -c {1}/t32_config.t32, {1}/t32_startup_script.cmm &\n'.format(t32_binary, out_path))
            t32_sh.close()
            os.chmod(launch_file, stat.S_IRWXU)

        print_out_str(
            '--- Created a T32 Simulator launcher (run {})'.format(launch_file))

    def read_tz_offset(self):
        if self.tz_addr == 0:
            print_out_str(
                'No TZ address was given, cannot read the magic value!')
            return None
        else:
            return self.read_word(self.tz_addr, False)

    def get_kaslr_offset(self):
        return self.kaslr_offset

    def determine_kaslr_offset(self):
        self.kaslr_offset = 0
        if self.kaslr_addr is None:
            print_out_str('!!!! Kaslr addr is not provided.')
        else:
            kaslr_magic = self.read_u32(self.kaslr_addr, False)
            if kaslr_magic != 0xdead4ead:
                print_out_str('!!!! Kaslr magic does not match.')
            else:
                self.kaslr_offset = self.read_u64(self.kaslr_addr + 4, False)
                print_out_str("The kaslr_offset extracted is: " + str(hex(self.kaslr_offset)))

    def get_hw_id(self, add_offset=True):
        socinfo_format = -1
        socinfo_id = -1
        socinfo_version = 0
        socinfo_build_id = 'DUMMY'
        chosen_board = None

        boards = get_supported_boards()

        if (self.hw_id is None):
            if not self.minidump:
                heap_toc_offset = self.field_offset('struct smem_shared', 'heap_toc')
                if heap_toc_offset is None:
                    print_out_str(
                        '!!!! Could not get a necessary offset for auto detection!')
                    print_out_str(
                        '!!!! Please check the gdb path which is used for offsets!')
                    print_out_str('!!!! Also check that the vmlinux is not stripped')
                    print_out_str('!!!! Exiting...')
                    sys.exit(1)

                smem_heap_entry_size = self.sizeof('struct smem_heap_entry')
                offset_offset = self.field_offset('struct smem_heap_entry', 'offset')
            for board in boards:
                if not self.minidump:
                    socinfo_start_addr = board.smem_addr + heap_toc_offset + smem_heap_entry_size * SMEM_HW_SW_BUILD_ID + offset_offset
                else:
                    if hasattr(board, 'smem_addr_buildinfo'):
                        socinfo_start_addr = board.smem_addr_buildinfo
                    else:
                        continue
                if add_offset:
                    socinfo_start_addr += board.ram_start
                if not self.minidump:
                    soc_start = self.read_int(socinfo_start_addr, False)
                    if soc_start is None:
                        continue
                    socinfo_start = board.smem_addr + soc_start
                    if add_offset:
                        socinfo_start += board.ram_start
                else:
                    socinfo_start = socinfo_start_addr
                socinfo_id = self.read_int(socinfo_start + 4, False)
                if socinfo_id != board.socid:
                    continue

                socinfo_format = self.read_int(socinfo_start, False)
                socinfo_version = self.read_int(socinfo_start + 8, False)
                socinfo_build_id = self.read_cstring(
                    socinfo_start + 12, BUILD_ID_LENGTH, virtual=False)

                chosen_board = board
                break

            if chosen_board is None:
                print_out_str('!!!! Could not find hardware')
                print_out_str("!!!! The SMEM didn't match anything")
                print_out_str(
                    '!!!! You can use --force-hardware to use a specific set of values')
                sys.exit(1)

        else:
            for board in boards:
                if self.hw_id == board.board_num:
                    print_out_str(
                        '!!! Hardware id found! The socinfo values given are bogus')
                    print_out_str('!!! Proceed with caution!')
                    chosen_board = board
                    break
            if chosen_board is None:
                print_out_str(
                    '!!! A bogus hardware id was specified: {0}'.format(self.hw_id))
                print_out_str('!!! Supported ids:')
                for b in get_supported_ids():
                    print_out_str('    {0}'.format(b))
                sys.exit(1)

        print_out_str('\nHardware match: {0}'.format(board.board_num))
        print_out_str('Socinfo id = {0}, version {1:x}.{2:x}'.format(
            socinfo_id, socinfo_version >> 16, socinfo_version & 0xFFFF))
        print_out_str('Socinfo build = {0}'.format(socinfo_build_id))
        print_out_str(
            'Now setting phys_offset to {0:x}'.format(board.phys_offset))
        if board.wdog_addr is not None:
            print_out_str(
            'TZ address: {0:x}'.format(board.wdog_addr))
        if self.phys_offset is None:
            self.phys_offset = board.phys_offset
        self.tz_addr = board.wdog_addr
        self.ebi_start = board.ram_start
        self.tz_start = board.imem_start
        self.hw_id = board.board_num
        self.cpu_type = board.cpu
        self.imem_fname = board.imem_file_name
        if hasattr(board, 'kaslr_addr'):
            self.kaslr_addr = board.kaslr_addr
        else:
            self.kaslr_addr = None
        self.board = board
        return True

    def resolve_virt(self, virt_or_name):
        """Takes a virtual address or variable name, returns a virtual
        address
        """
        if not isinstance(virt_or_name, basestring):
            return virt_or_name
        return self.address_of(virt_or_name)

    def virt_to_phys(self, virt_or_name):
        """Does a virtual-to-physical address lookup of the virtual address or
        variable name."""
        if self.minidump:
            return minidump_util.minidump_virt_to_phys(self.ebi_files_minidump,self.resolve_virt(virt_or_name))
        else:
            return self.mmu.virt_to_phys(self.resolve_virt(virt_or_name))

    def setup_symbol_tables(self):
        stream = os.popen(self.nm_path + ' -n ' + self.vmlinux)
        symbols = stream.readlines()
        kaslr = self.get_kaslr_offset()

        for line in symbols:
            s = line.split(' ')
            if len(s) == 3:
                self.lookup_table.append((int(s[0], 16) + kaslr,
                                         s[2].rstrip()))
        stream.close()

    def retrieve_modules(self):
        mod_list = self.address_of('modules')
        next_offset = self.field_offset('struct list_head', 'next')
        list_offset = self.field_offset('struct module', 'list')
        name_offset = self.field_offset('struct module', 'name')

        if self.kernel_version > (4, 9, 0):
            module_core_offset = self.field_offset('struct module', 'core_layout.base')
        else:
            module_core_offset = self.field_offset('struct module', 'module_core')

        next_list_ent = self.read_pointer(mod_list + next_offset)
        while next_list_ent != mod_list:
            mod_tbl_ent = module_table.module_table_entry()
            module = next_list_ent - list_offset
            name_ptr = module + name_offset
            mod_tbl_ent.name = self.read_cstring(name_ptr)
            mod_tbl_ent.module_offset = self.read_pointer(module + module_core_offset)
            self.module_table.add_entry(mod_tbl_ent)
            next_list_ent = self.read_pointer(next_list_ent + next_offset)

    def parse_symbols_of_one_module(self, mod_tbl_ent, sym_path):
        if not mod_tbl_ent.set_sym_path( os.path.join(sym_path, mod_tbl_ent.name + '.ko') ):
            return
        stream = os.popen(self.nm_path + ' -n ' + mod_tbl_ent.get_sym_path())
        symbols = stream.readlines()

        for line in symbols:
            s = line.split(' ')
            if len(s) == 3:
                mod_tbl_ent.sym_lookup_table.append(
                    (int(s[0], 16) + mod_tbl_ent.module_offset,
                    s[2].rstrip() + '[' + mod_tbl_ent.name + ']'))
        stream.close()

    def parse_module_symbols(self):
        for mod_tbl_ent in self.module_table.module_table:
            self.parse_symbols_of_one_module(mod_tbl_ent, self.module_table.sym_path)

    def add_symbols_to_global_lookup_table(self):
        for mod_tbl_ent in self.module_table.module_table:
            for sym in mod_tbl_ent.sym_lookup_table:
                self.lookup_table.append(sym)
        self.lookup_table.sort()

    def setup_module_symbols(self):
        self.retrieve_modules()
        self.parse_module_symbols();
        self.add_symbols_to_global_lookup_table()

    def address_of(self, symbol):
        """Returns the address of a symbol.

        Example:

        >>> hex(dump.address_of('linux_banner'))
        '0xffffffc000c7a0a8L'
        """
        try:
            return self.gdbmi.address_of(symbol)
        except gdbmi.GdbMIException:
            pass

    def symbol_at(self, addr):
        try:
            return self.gdbmi.symbol_at(addr)
        except gdbmi.GdbMIException:
            pass

    def sizeof(self, the_type):
        try:
            return self.gdbmi.sizeof(the_type)
        except gdbmi.GdbMIException:
            pass

    def array_index(self, addr, the_type, index):
        """Index into the array of type ``the_type`` located at ``addr``.

        I.e., given::

            int my_arr[3];
            my_arr[2] = 42;

        You could do the following:

        >>> addr = dump.address_of("my_arr")
        >>> dump.read_word(dump.array_index(addr, "int", 2))
        42
        """
        offset = self.gdbmi.sizeof(the_type) * index
        return addr + offset

    def field_offset(self, the_type, field):
        """Gets the offset of a field from the base of its containing struct.

        This can be useful when reading struct fields, although you should
        consider using :func:`~read_structure_field` if
        you're reading a word-sized value.

        Example:

        >>> dump.field_offset('struct device', 'bus')
        168
        """
        try:
            return self.gdbmi.field_offset(the_type, field)
        except gdbmi.GdbMIException:
            pass

    def container_of(self, ptr, the_type, member):
        """Like ``container_of`` in the kernel."""
        try:
            return self.gdbmi.container_of(ptr, the_type, member)
        except gdbmi.GdbMIException:
            pass

    def sibling_field_addr(self, ptr, parent_type, member, sibling):
        """Gets the address of a sibling structure field.

        Given the address of some field within a structure, returns the
        address of the requested sibling field.
        """
        try:
            return self.gdbmi.sibling_field_addr(ptr, parent_type, member, sibling)
        except gdbmi.GdbMIException:
            pass

    def unwind_lookup(self, addr, symbol_size=0):
        if (addr is None):
            return ('(Invalid address)', 0x0)

        low = 0
        high = len(self.lookup_table)
        # Python now complains about division producing floats
        mid = (low + high) >> 1
        premid = 0

        while(not(addr >= self.lookup_table[mid][0] and addr < self.lookup_table[mid + 1][0])):

            if(addr < self.lookup_table[mid][0]):
                high = mid - 1

            if(addr > self.lookup_table[mid][0]):
                low = mid + 1

            mid = (high + low) >> 1

            if(mid == premid):
                return None
            if (mid + 1) >= len(self.lookup_table) or mid < 0:
                return None

            premid = mid

        if symbol_size == 0:
            return (self.lookup_table[mid][1], addr - self.lookup_table[mid][0])
        else:
            return (self.lookup_table[mid][1], self.lookup_table[mid + 1][0] - self.lookup_table[mid][0])

    def read_physical(self, addr, length):
        if self.minidump:
            addr_data = minidump_util.read_physical_minidump(
                        self.ebi_files_minidump, self.ebi_files,self.elffile,
                        addr, length)
            return addr_data
        else:
            ebi = (-1, -1, -1)
            for a in self.ebi_files:
                fd, start, end, path = a
                if addr >= start and addr <= end:
                    ebi = a
                    break
            if ebi[0] is -1:
                return None
            offset = addr - ebi[1]
            ebi[0].seek(offset)
            a = ebi[0].read(length)
            return a

    def read_dword(self, addr_or_name, virtual=True, cpu=None):
        s = self.read_string(addr_or_name, '<Q', virtual, cpu)
        return s[0] if s is not None else None

    def read_word(self, addr_or_name, virtual=True, cpu=None):
        """returns a word size (pointer) read from ramdump"""
        if self.arm64:
            s = self.read_string(addr_or_name, '<Q', virtual, cpu)
        else:
            s = self.read_string(addr_or_name, '<I', virtual, cpu)
        return s[0] if s is not None else None

    def read_halfword(self, addr_or_name, virtual=True, cpu=None):
        """returns a value corresponding to half the word size"""
        if self.arm64:
            s = self.read_string(addr_or_name, '<I', virtual, cpu)
        else:
            s = self.read_string(addr_or_name, '<H', virtual, cpu)
        return s[0] if s is not None else None

    def read_byte(self, addr_or_name, virtual=True, cpu=None):
        """Reads a single byte."""
        s = self.read_string(addr_or_name, '<B', virtual, cpu)
        return s[0] if s is not None else None

    def read_bool(self, addr_or_name, virtual=True, cpu=None):
        """Reads a bool."""
        s = self.read_string(addr_or_name, '<?', virtual, cpu)
        return s[0] if s is not None else None

    def read_s64(self, addr_or_name, virtual=True, cpu=None):
        """returns a value guaranteed to be 64 bits"""
        s = self.read_string(addr_or_name, '<q', virtual, cpu)
        return s[0] if s is not None else None

    def read_u64(self, addr_or_name, virtual=True, cpu=None):
        """returns a value guaranteed to be 64 bits"""
        s = self.read_string(addr_or_name, '<Q', virtual, cpu)
        return s[0] if s is not None else None

    def read_s32(self, addr_or_name, virtual=True, cpu=None):
        """returns a value guaranteed to be 32 bits"""
        s = self.read_string(addr_or_name, '<i', virtual, cpu)
        return s[0] if s is not None else None

    def read_u32(self, addr_or_name, virtual=True, cpu=None):
        """returns a value guaranteed to be 32 bits"""
        s = self.read_string(addr_or_name, '<I', virtual, cpu)
        return s[0] if s is not None else None

    def read_int(self, addr_or_name, virtual=True,  cpu=None):
        """Alias for :func:`~read_u32`"""
        return self.read_u32(addr_or_name, virtual, cpu)

    def read_u16(self, addr_or_name, virtual=True, cpu=None):
        """returns a value guaranteed to be 16 bits"""
        s = self.read_string(addr_or_name, '<H', virtual, cpu)
        return s[0] if s is not None else None

    def read_pointer(self, addr_or_name, virtual=True, cpu=None):
        """Reads ``addr_or_name`` as a pointer variable.

        The read length is either 32-bit or 64-bit depending on the
        architecture.  This returns the *value* of the pointer variable
        (i.e. the address it contains), not the data it points to.
        """
        fn = self.read_u32 if self.sizeof('void *') == 4 else self.read_u64
        return fn(addr_or_name, virtual, cpu)

    def read_structure_field(self, addr_or_name, struct_name, field, virtual=True):
        """reads a 4 or 8 byte field from a structure"""
        size = self.sizeof("(({0} *)0)->{1}".format(struct_name, field))
        addr = self.resolve_virt(addr_or_name)
        if addr is None or size is None:
            return None

        addr += self.field_offset(struct_name, field)
        if size == 4:
            return self.read_u32(addr, virtual)
        if size == 8:
            return self.read_u64(addr, virtual)
        return None

    def read_structure_cstring(self, addr_or_name, struct_name, field,
                               max_length=100):
        """reads a C string from a structure field.  The C string field will be
        dereferenced before reading, so it should be a ``char *``, not a
        ``char []``.
        """
        virt = self.resolve_virt(addr_or_name)
        cstring_addr = virt + self.field_offset(struct_name, field)
        return self.read_cstring(self.read_pointer(cstring_addr), max_length)

    def read_cstring(self, addr_or_name, max_length=100, virtual=True,
                     cpu=None):
        """Reads a C string."""
        addr = addr_or_name
        if virtual:
            if cpu is not None:
                pcpu_offset = self.per_cpu_offset(cpu)
                addr_or_name = self.resolve_virt(addr_or_name)
                addr_or_name += pcpu_offset + self.per_cpu_offset(cpu)
            addr = self.virt_to_phys(addr_or_name)
        s = self.read_physical(addr, max_length)
        if s is not None:
            a = s.decode('ascii', 'ignore')
            return a.split('\0')[0]
        else:
            return s

    def read_string(self, addr_or_name, format_string, virtual=True, cpu=None):
        """Reads data using a format string.

        Reads data from addr_or_name using format_string (which should be a
        struct.unpack format).

        Returns the tuple returned by struct.unpack.
        """
        addr = addr_or_name
        per_cpu_string = ''
        if virtual:
            if cpu is not None:
                pcpu_offset = self.per_cpu_offset(cpu)
                addr_or_name = self.resolve_virt(addr_or_name)
                addr_or_name += pcpu_offset
                per_cpu_string = ' with per-cpu offset of ' + hex(pcpu_offset)
            addr = self.virt_to_phys(addr_or_name)
        s = self.read_physical(addr, struct.calcsize(format_string))
        if (s is None) or (s == ''):
            return None
        return struct.unpack(format_string, s)

    def hexdump(self, addr_or_name, length, virtual=True, file_object=None):
        """Returns a string with a hexdump (in the format of ``xxd``).

        ``length`` is in bytes.

        Example (intentionally not in doctest format since it would require
        a specific dump to be loaded to pass as a doctest):

        >>> print(dump.hexdump('linux_banner', 0x80))
        ffffffc000c610a8: 4c69 6e75 7820 7665 7273 696f 6e20 332e  Linux version 3.
        ffffffc000c610b8: 3138 2e32 302d 6761 3762 3238 6539 2d31  18.20-ga7b28e9-1
        ffffffc000c610c8: 3333 3830 2d67 3036 3032 6531 3020 286c  3380-g0602e10 (l
        ffffffc000c610d8: 6e78 6275 696c 6440 6162 6169 7431 3532  nxbuild@abait152
        ffffffc000c610e8: 2d73 642d 6c6e 7829 2028 6763 6320 7665  -sd-lnx) (gcc ve
        ffffffc000c610f8: 7273 696f 6e20 342e 392e 782d 676f 6f67  rsion 4.9.x-goog
        ffffffc000c61108: 6c65 2032 3031 3430 3832 3720 2870 7265  le 20140827 (pre
        ffffffc000c61118: 7265 6c65 6173 6529 2028 4743 4329 2029  release) (GCC) )
        """
        import StringIO
        sio = StringIO.StringIO()
        address = self.resolve_virt(addr_or_name)
        parser_util.xxd(
            address,
            [self.read_byte(address + i, virtual=virtual) or 0
             for i in xrange(length)],
            file_object=sio)
        ret = sio.getvalue()
        sio.close()
        return ret

    def per_cpu_offset(self, cpu):
        per_cpu_offset_addr = self.address_of('__per_cpu_offset')
        if per_cpu_offset_addr is None:
            return 0
        per_cpu_offset_addr_indexed = self.array_index(
            per_cpu_offset_addr, 'unsigned long', cpu)
        return self.read_word(per_cpu_offset_addr_indexed)

    def get_num_cpus(self):
        """Gets the number of CPUs in the system."""
        major, minor, patch = self.kernel_version
        cpu_present_bits_addr = self.address_of('cpu_present_bits')
        cpu_present_bits = self.read_word(cpu_present_bits_addr)

        if (major, minor) >= (4, 5):
            cpu_present_bits_addr = self.address_of('__cpu_present_mask')
            bits_offset = self.field_offset('struct cpumask', 'bits')
            cpu_present_bits = self.read_word(cpu_present_bits_addr + bits_offset)
        return bin(cpu_present_bits).count('1')

    def iter_cpus(self):
        """Returns an iterator over all CPUs in the system.

        Example:

        >>> list(dump.iter_cpus())
        [0, 1, 2, 3]
        """
        return xrange(self.get_num_cpus())

    def is_thread_info_in_task(self):
        return self.is_config_defined('CONFIG_THREAD_INFO_IN_TASK')

    def get_thread_info_addr(self, task_addr):
        if self.is_thread_info_in_task():
            thread_info_address = task_addr + self.field_offset('struct task_struct', 'thread_info')
        else:
            thread_info_ptr = task_addr + self.field_offset('struct task_struct', 'stack')
            thread_info_address = self.read_word(thread_info_ptr, True)
        return thread_info_address

    def get_task_cpu(self, task_struct_addr, thread_info_struct_addr):
        if self.is_thread_info_in_task():
            offset_cpu = self.field_offset('struct task_struct', 'cpu')
            cpu = self.read_int(task_struct_addr + offset_cpu)
        else:
            offset_cpu = self.field_offset('struct thread_info', 'cpu')
            cpu = self.read_int(thread_info_struct_addr + offset_cpu)
        return cpu

    def thread_saved_field_common_32(self, task, reg_offset):
        thread_info = self.get_thread_info_addr(task)
        cpu_context_offset = self.field_offset('struct thread_info', 'cpu_context')
        val = self.read_word(thread_info + cpu_context_offset + reg_offset)
        return val

    def thread_saved_field_common_64(self, task, reg_offset):
        thread_offset = self.field_offset('struct task_struct', 'thread')
        cpu_context_offset = self.field_offset('struct thread_struct', 'cpu_context')
        val = self.read_word(task + thread_offset + cpu_context_offset + reg_offset)
        return val

    def thread_saved_pc(self, task):
        if self.arm64:
            return self.thread_saved_field_common_64(task, self.field_offset('struct cpu_context', 'pc'))
        else:
            return self.thread_saved_field_common_32(task, self.field_offset('struct cpu_context_save', 'pc'))

    def thread_saved_sp(self, task):
        if self.arm64:
            return self.thread_saved_field_common_64(task, self.field_offset('struct cpu_context', 'sp'))
        else:
            return self.thread_saved_field_common_32(task, self.field_offset('struct cpu_context_save', 'sp'))

    def thread_saved_fp(self, task):
        if self.arm64:
            return self.thread_saved_field_common_64(task, self.field_offset('struct cpu_context', 'fp'))
        else:
            return self.thread_saved_field_common_32(task, self.field_offset('struct cpu_context_save', 'fp'))


class Struct(object):
    """
    Helper class to abstract C structs retrieval by providing a map of fields
    to functions on how to retrieve these

    Given C struct::

        struct my_struct {
            char label[MAX_STR_SIZE];
            u32 number;
            void *address;
        }

    You can abstract as:

    >>> var = Struct(ramdump, var_name, struct_name="struct my_struct",
                                        fields={'label': Struct.get_cstring,
                                                'number': Struct.get_u32,
                                                'address': Struct.get_pointer})
    >>> var.label
    'label string'
    >>> var.number
    1234
    """
    _struct_name = None
    _fields = None

    def __init__(self, ramdump, base, struct_name=None, fields=None):
        """
        :param ram_dump:    Reference to the ram dump
        :param base:        The virtual address or variable name of struct
        :param struct_name: Name of the structure, should start with 'struct'.
                            Ex: 'struct my_struct'
        :param fields:  Dictionary with key being the element name and value
                        being a function pointer to method used to retrieve it.
        """
        self.ramdump = ramdump
        self._base = self.ramdump.resolve_virt(base)
        self._data = {}
        if struct_name:
            self._struct_name = struct_name
        if fields:
            self._fields = fields

    def is_empty(self):
        """
        :return: true if struct is empty
        """
        return self._base == 0 or self._base is None or self._fields is None

    def get_address(self, key):
        """
        :param key: struct field name
        :return: returns address of the named field within the struct
        """
        return self._base + self.ramdump.field_offset(self._struct_name, key)

    def get_pointer(self, key):
        """
        :param key: struct field name
        :return: returns the addressed pointed by field within the struct

        example struct::

            struct {
                void *key;
            };
        """
        address = self.get_address(key)
        return self.ramdump.read_pointer(address)

    def get_struct_sizeof(self, key):
        """
        :param key: struct field name
        :return: returns the size of a field within struct

        Given C struct::

            struct my_struct {
                char key1[10];
                u32 key2;
            };

        You could do:

        >>> struct = Struct(ramdump, 0, struct="struct my_struct",
                                        fields={"key1": Struct.get_cstring,
                                                "key2": Struct.get_u32})
        >>> struct.get_struct_sizeof(key1)
        10
        >>> struct.get_struct_sizeof(key2)
        4
        """
        return self.ramdump.sizeof('((%s *) 0)->%s' % (self._struct_name, key))

    def get_cstring(self, key):
        """
        :param key: struct field name
        :return: returns a string that is contained within struct memory

        Example C struct::

            struct {
                char key[10];
            };
        """
        address = self.get_address(key)
        length = self.get_struct_sizeof(key)
        return self.ramdump.read_cstring(address, length)

    def get_u32(self, key):
        """
        :param key: struct field name
        :return: returns a u32 integer within the struct

        Example C struct::

            struct {
                u32 key;
            };
        """
        address = self.get_address(key)
        return self.ramdump.read_u32(address)

    def get_array_ptrs(self, key):
        """
        :param key: struct field name
        :return: returns an array of pointers

        Example C struct::

            struct {
                void *key[4];
            };
        """
        ptr_size = self.ramdump.sizeof('void *')
        length = self.get_struct_sizeof(key) / ptr_size
        address = self.get_address(key)
        arr = []
        for i in range(0, length - 1):
            ptr = self.ramdump.read_pointer(address + (ptr_size * i))
            arr.append(ptr)
        return arr

    def __setattr__(self, key, value):
        if self._fields and key in self._fields:
            raise ValueError(key + "is read-only")
        else:
            super(Struct, self).__setattr__(key, value)

    def __getattr__(self, key):
        if not self.is_empty():
            if key in self._data:
                return self._data[key]
            elif key in self._fields:
                fn = self._fields[key]
                value = fn(self, key)
                self._data[key] = value
                return value
        return None
