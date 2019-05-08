# Copyright (c) 2014-2018, The Linux Foundation. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

class Board(object):
    """ Class to describe a board the parser knows how to parse
    socid = shared id unique to a board type
    board_num = human readable board number indicating the board type
                (e.g. 8960, 8974)
    cpu = T32 cpu model
    ram_start = start of the DDR
    imem_start = start of location in which the watchdog address is stored
    smem_addr = start of the shared memory region
    phys_offset = physical offset of the board (CONFIG_PHYS_OFFSET)
    wdog_addr = absolute physical address to check for FIQs
    imem_file_name = file name corresponding to imem_start

    It is not recommended to create instances of this class directly.
    Instead, classes should derive from this class and set fiels appropriately
    for each socid

    """
    def __init__(self):
        self.socid = -1
        self.board_num = "-1"
        self.cpu = 'UNKNOWN'
        self.ram_start = 0
        self.imem_start = 0
        self.smem_addr = 0
        self.phys_offset = 0
        self.wdog_addr = 0
        self.imem_file_name = None

class Board8960(Board):
    def __init__(self, socid, board_num, phys_offset=0x80200000, ram_start=0x80000000):
        super(Board8960, self).__init__()
        self.socid = socid
        self.board_num = board_num
        self.cpu = 'KRAIT'
        self.ram_start = ram_start
        self.imem_start = 0x2a03f000
        self.smem_addr = 0x0
        self.phys_offset = phys_offset
        self.wdog_addr = 0x2a03f658
        self.imem_file_name = 'IMEM_C.BIN'

class Board8625(Board):
    def __init__(self, socid, board_num):
        super(Board8625, self).__init__()
        self.socid = socid
        self.board_num = board_num
        self.cpu = 'SCORPION'
        self.ram_start = 0
        self.imem_start = 0x0
        self.smem_addr = 0x00100000
        self.phys_offset = 0x00200000

class Board9615(Board):
    def __init__(self, socid):
        super(Board9615, self).__init__()
        self.socid = socid
        self.board_num = "9615"
        self.cpu = 'CORTEXA5'
        self.ram_start = 0x40000000
        self.imem_start = 0
        self.smem_addr = 0x0
        self.phys_offset = 0x40800000

class Board8974(Board):
    def __init__(self, socid, board_num="8974"):
        super(Board8974, self).__init__()
        self.socid = socid
        self.board_num = board_num
        self.cpu = 'KRAIT'
        self.ram_start = 0x0
        self.imem_start = 0xfe800000
        self.smem_addr = 0xfa00000
        self.phys_offset = 0x0
        self.wdog_addr = 0xfe805658
        self.imem_file_name = 'OCIMEM.BIN'

class Board9625(Board):
    def __init__(self, socid):
        super(Board9625, self).__init__()
        self.socid = socid
        self.board_num = "9625"
        self.cpu = 'CORTEXA5'
        self.ram_start = 0x0
        self.imem_start = 0xfe800000
        self.smem_addr = 0x0
        self.phys_offset = 0x200000
        self.wdog_addr = 0xfe805658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8626(Board):
    def __init__(self, socid, board_num="8626"):
        super(Board8626, self).__init__()
        self.socid = socid
        self.board_num = board_num
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x0
        self.imem_start = 0xfe800000
        self.smem_addr = 0x0fa00000
        self.phys_offset = 0x0
        self.wdog_addr = 0xfe805658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8026LW(Board):
    def __init__(self, socid, board_num="8026"):
        super(Board8026LW, self).__init__()
        self.socid = socid
        self.board_num = board_num
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x0
        self.imem_start = 0xfe800000
        self.smem_addr = 0x03000000
        self.phys_offset = 0x0
        self.wdog_addr = 0xfe805658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8610(Board):
    def __init__(self, socid, board_num="8610"):
        super(Board8610, self).__init__()
        self.socid = socid
        self.board_num = board_num
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x0
        self.imem_start = 0xfe800000
        self.smem_addr = 0x0d900000
        self.phys_offset = 0x0
        self.wdog_addr = 0xfe805658
        self.imem_file_name = 'OCIMEM.BIN'

class Board9635(Board):
    def __init__(self, socid):
        super(Board9635, self).__init__()
        self.socid = socid
        self.board_num = "9635"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x0
        self.imem_start = 0xfe800000
        self.smem_addr = 0x1100000
        self.phys_offset = 0
        self.wdog_addr = 0xfe805658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8916(Board):
    def __init__(self, socid, smem_addr):
        super(Board8916, self).__init__()
        self.socid = socid
        self.board_num = "8916"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        #self.ram_start = 0x0
        self.smem_addr = smem_addr
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8939(Board):
    def __init__(self, socid, smem_addr):
        super(Board8939, self).__init__()
        self.socid = socid
        self.board_num = "8939"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = smem_addr
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8936(Board):
    def __init__(self, socid):
        super(Board8936, self).__init__()
        self.socid = socid
        self.board_num = "8936"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8994(Board):
    def __init__(self, socid):
        super(Board8994, self).__init__()
        self.socid = socid
        self.board_num = "8994"
        self.cpu = 'CORTEXA57A53'
        self.ram_start = 0x0
        self.smem_addr = 0x6a00000
        self.phys_offset = 0x0
        self.imem_start = 0xfe800000
        self.wdog_addr = 0xfe87f658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8909(Board):
    def __init__(self, socid):
        super(Board8909, self).__init__()
        self.socid = socid
        self.board_num = "8909"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x7d00000
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8908(Board):
    def __init__(self, socid):
        super(Board8908, self).__init__()
        self.socid = socid
        self.board_num = "8908"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x7d00000
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board9640(Board):
    def __init__(self, socid):
        super(Board9640, self).__init__()
        self.socid = socid
        self.board_num = "9640"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x7e80000
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8992(Board):
    def __init__(self, socid):
        super(Board8992, self).__init__()
        self.socid = socid
        self.board_num = "8992"
        self.cpu = 'CORTEXA57A53'
        self.ram_start = 0x0
        self.smem_addr = 0x6a00000
        self.phys_offset = 0x0
        self.imem_start = 0xfe800000
        self.wdog_addr = 0xfe87f658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8929(Board):
    def __init__(self, socid, smem_addr):
        super(Board8929, self).__init__()
        self.socid = socid
        self.board_num = "8929"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = smem_addr
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658

class Board8996(Board):
    def __init__(self, socid):
        super(Board8996, self).__init__()
        self.socid = socid
        self.board_num = "8996"
        self.cpu = 'HYDRA'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.phys_offset = 0x80000000
        self.imem_start = 0x6680000
        self.wdog_addr = 0x66BF658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8952(Board):
    def __init__(self, socid):
        super(Board8952, self).__init__()
        self.socid = socid
        self.board_num = "8952"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8976(Board):
    def __init__(self, socid):
        super(Board8976, self).__init__()
        self.socid = socid
        self.board_num = "8976"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x20000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board9607(Board):
    def __init__(self, socid):
        super(Board9607, self).__init__()
        self.socid = socid
        self.board_num = "9607"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x7d00000
        self.phys_offset = 0x80000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'


class Board8937(Board):
    def __init__(self, socid):
        super(Board8937, self).__init__()
        self.socid = socid
        self.board_num = "8937"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.kaslr_addr = 0x86006d0
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8940(Board):
     def __init__(self, socid):
         super(Board8940, self).__init__()
         self.socid = socid
         self.board_num = "8940"
         self.cpu = 'CORTEXA53'
         self.ram_start = 0x80000000
         self.smem_addr = 0x6300000
         self.phys_offset = 0x40000000
         self.imem_start = 0x8600000
         self.wdog_addr = 0x8600658
         self.imem_file_name = 'OCIMEM.BIN'

class Board8953(Board):
    def __init__(self, socid):
        super(Board8953, self).__init__()
        self.socid = socid
        self.board_num = "8953"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board450(Board):
    def __init__(self, socid):
        super(Board450, self).__init__()
        self.socid = socid
        self.board_num = "450"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.kaslr_addr = 0x86006d0
        self.imem_file_name = 'OCIMEM.BIN'

class Board632(Board):
    def __init__(self, socid):
        super(Board632, self).__init__()
        self.socid = socid
        self.board_num = "632"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.kaslr_addr = 0x86006d0
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board439(Board):
    def __init__(self, socid):
        super(Board439, self).__init__()
        self.socid = socid
        self.board_num = "sdm439"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.kaslr_addr = 0x86006d0
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board429(Board):
    def __init__(self, socid):
        super(Board429, self).__init__()
        self.socid = socid
        self.board_num = "sdm429"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.kaslr_addr = 0x86006d0
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8917(Board):
    def __init__(self, socid):
        super(Board8917, self).__init__()
        self.socid = socid
        self.board_num = "8917"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8920(Board):
     def __init__(self, socid):
         super(Board8920, self).__init__()
         self.socid = socid
         self.board_num = "8920"
         self.cpu = 'CORTEXA53'
         self.ram_start = 0x80000000
         self.smem_addr = 0x6300000
         self.phys_offset = 0x40000000
         self.imem_start = 0x8600000
         self.wdog_addr = 0x8600658
         self.imem_file_name = 'OCIMEM.BIN'

class BoardCalifornium(Board):
    def __init__(self, socid):
        super(BoardCalifornium, self).__init__()
        self.socid = socid
        self.board_num = "californium"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x7e80000
        self.phys_offset = 0x80000000
        self.imem_start = 0x08600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'


class BoardCobalt(Board):
    def __init__(self, socid):
        super(BoardCobalt, self).__init__()
        self.socid = socid
        self.board_num = "cobalt"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardSDM845(Board):
    def __init__(self, socid):
        super(BoardSDM845, self).__init__()
        self.socid = socid
        self.board_num = "sdm845"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.smem_addr_buildinfo = 0x6007210
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardSDM710(Board):
    def __init__(self, socid):
        super(BoardSDM710, self).__init__()
        self.socid = socid
        self.board_num = "sdm710"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.smem_addr_buildinfo = 0x6007210
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardQCS605(Board):
    def __init__(self, socid):
        super(BoardQCS605, self).__init__()
        self.socid = socid
        self.board_num = "qcs605"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardQCS405(Board):
    def __init__(self, socid):
        super(BoardQCS405, self).__init__()
        self.socid = socid
        self.board_num = "qcs405"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardQCS403(Board):
    def __init__(self, socid):
        super(BoardQCS403, self).__init__()
        self.socid = socid
        self.board_num = "qcs403"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6300000
        self.phys_offset = 0x40000000
        self.imem_start = 0x8600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class Board8998(Board):
    def __init__(self, socid):
        super(Board8998, self).__init__()
        self.socid = socid
        self.board_num = "8998"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class Board660(Board):
    def __init__(self, socid):
        super(Board660, self).__init__()
        self.socid = socid
        self.board_num = "660"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.smem_addr_buildinfo = 0x6006ec0
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class Board630(Board):
    def __init__(self, socid):
        super(Board630, self).__init__()
        self.socid = socid
        self.board_num = "630"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardSDX20(Board):
    def __init__(self, socid):
        super(BoardSDX20, self).__init__()
        self.socid = socid
        self.board_num = "SDX20"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0x7e80000
        self.phys_offset = 0x80000000
        self.imem_start = 0x08600000
        self.wdog_addr = 0x8600658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardSM8150(Board):
    def __init__(self, socid):
        super(BoardSM8150, self).__init__()
        self.socid = socid
        self.board_num = "sm8150"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.smem_addr_buildinfo = 0x6007210
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146bf6d0
        self.wdog_addr = 0x146BF658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardSteppe(Board):
    def __init__(self, socid):
        super(BoardSteppe, self).__init__()
        self.socid = socid
        self.board_num = "steppe"
        self.cpu = 'CORTEXA53'
        self.ram_start = 0x80000000
        self.smem_addr = 0x6000000
        self.smem_addr_buildinfo = 0x6007210
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.kaslr_addr = 0x146aa6d0
        self.wdog_addr = 0x146aa658
        self.imem_file_name = 'OCIMEM.BIN'

class BoardPoorwills(Board):
    def __init__(self, socid):
        super(BoardPoorwills, self).__init__()
        self.socid = socid
        self.board_num = "poorwills"
        self.cpu = 'CORTEXA7'
        self.ram_start = 0x80000000
        self.smem_addr = 0xFE40000
        self.phys_offset = 0x80000000
        self.imem_start = 0x14680000
        self.wdog_addr =  0x14680658
        self.imem_file_name = 'OCIMEM.BIN'

boards = []

boards.append(Board9640(socid=234))
boards.append(Board9640(socid=235))
boards.append(Board9640(socid=236))
boards.append(Board9640(socid=237))
boards.append(Board9640(socid=238))

boards.append(Board8916(socid=206, smem_addr=0xe200000))
boards.append(Board8916(socid=206, smem_addr=0x6300000))

boards.append(Board8939(socid=239, smem_addr=0xe200000))
boards.append(Board8939(socid=241, smem_addr=0xe200000))
boards.append(Board8939(socid=239, smem_addr=0x6300000))
boards.append(Board8939(socid=241, smem_addr=0x6300000))

boards.append(Board8936(socid=233))
boards.append(Board8936(socid=240))
boards.append(Board8936(socid=242))
boards.append(Board8936(socid=243))

boards.append(Board8909(socid=245))
boards.append(Board8909(socid=258))
boards.append(Board8909(socid=265))

boards.append(Board8908(socid=259))

boards.append(Board8929(socid=268, smem_addr=0xe200000))
boards.append(Board8929(socid=269, smem_addr=0xe200000))
boards.append(Board8929(socid=270, smem_addr=0xe200000))
boards.append(Board8929(socid=271, smem_addr=0x6300000))

boards.append(Board8974(socid=126))
boards.append(Board8974(socid=184))
boards.append(Board8974(socid=185))
boards.append(Board8974(socid=186))
boards.append(Board8974(socid=208))
boards.append(Board8974(socid=211))
boards.append(Board8974(socid=214))
boards.append(Board8974(socid=217))
boards.append(Board8974(socid=209))
boards.append(Board8974(socid=212))
boards.append(Board8974(socid=215))
boards.append(Board8974(socid=218))
boards.append(Board8974(socid=194))
boards.append(Board8974(socid=210))
boards.append(Board8974(socid=213))
boards.append(Board8974(socid=216))

boards.append(Board9625(socid=134))
boards.append(Board9625(socid=148))
boards.append(Board9625(socid=149))
boards.append(Board9625(socid=150))
boards.append(Board9625(socid=151))
boards.append(Board9625(socid=152))
boards.append(Board9625(socid=173))
boards.append(Board9625(socid=174))
boards.append(Board9625(socid=175))


boards.append(Board8626(socid=145))
boards.append(Board8626(socid=158))
boards.append(Board8626(socid=159))
boards.append(Board8626(socid=198))
boards.append(Board8626(socid=199))
boards.append(Board8626(socid=200))
boards.append(Board8626(socid=205))
boards.append(Board8626(socid=219))
boards.append(Board8626(socid=220))
boards.append(Board8626(socid=222))
boards.append(Board8626(socid=223))
boards.append(Board8626(socid=224))

boards.append(Board8026LW(socid=145))
boards.append(Board8026LW(socid=158))
boards.append(Board8026LW(socid=159))
boards.append(Board8026LW(socid=198))
boards.append(Board8026LW(socid=199))
boards.append(Board8026LW(socid=200))
boards.append(Board8026LW(socid=205))
boards.append(Board8026LW(socid=219))
boards.append(Board8026LW(socid=220))
boards.append(Board8026LW(socid=222))
boards.append(Board8026LW(socid=223))
boards.append(Board8026LW(socid=224))

boards.append(Board8610(socid=147))
boards.append(Board8610(socid=161))
boards.append(Board8610(socid=162))
boards.append(Board8610(socid=163))
boards.append(Board8610(socid=164))
boards.append(Board8610(socid=165))
boards.append(Board8610(socid=166))

boards.append(Board8974(socid=178, board_num="8084"))

boards.append(Board9635(socid=187))
boards.append(Board9635(socid=227))
boards.append(Board9635(socid=228))
boards.append(Board9635(socid=229))
boards.append(Board9635(socid=230))
boards.append(Board9635(socid=231))

boards.append(Board8960(socid=87, board_num="8960"))
boards.append(Board8960(socid=122, board_num="8960"))
boards.append(Board8960(socid=123, board_num="8260"))
boards.append(Board8960(socid=124, board_num="8060"))

boards.append(Board8960(socid=244, board_num="8064", phys_offset=0x40200000,
                        ram_start=0x40000000))
boards.append(Board8960(socid=109, board_num="8064"))
boards.append(Board8960(socid=130, board_num="8064"))
boards.append(Board8960(socid=153, board_num="8064"))

boards.append(Board8960(socid=116, board_num="8930"))
boards.append(Board8960(socid=117, board_num="8930"))
boards.append(Board8960(socid=118, board_num="8930"))
boards.append(Board8960(socid=119, board_num="8930"))
boards.append(Board8960(socid=154, board_num="8930"))
boards.append(Board8960(socid=155, board_num="8930"))
boards.append(Board8960(socid=156, board_num="8930"))
boards.append(Board8960(socid=157, board_num="8930"))
boards.append(Board8960(socid=160, board_num="8930"))

boards.append(Board8960(socid=120, board_num="8627"))
boards.append(Board8960(socid=121, board_num="8627"))
boards.append(Board8960(socid=138, board_num="8960"))
boards.append(Board8960(socid=139, board_num="8960"))
boards.append(Board8960(socid=140, board_num="8960"))
boards.append(Board8960(socid=141, board_num="8960"))
boards.append(Board8960(socid=142, board_num="8930"))
boards.append(Board8960(socid=143, board_num="8630"))
boards.append(Board8960(socid=144, board_num="8630"))

boards.append(Board9615(socid=104))
boards.append(Board9615(socid=105))
boards.append(Board9615(socid=106))
boards.append(Board9615(socid=107))

boards.append(Board8625(socid=88, board_num="8625"))
boards.append(Board8625(socid=89, board_num="8625"))
boards.append(Board8625(socid=96, board_num="8625"))
boards.append(Board8625(socid=90, board_num="8625"))
boards.append(Board8625(socid=91, board_num="8625"))
boards.append(Board8625(socid=92, board_num="8625"))
boards.append(Board8625(socid=97, board_num="8625"))
boards.append(Board8625(socid=98, board_num="8625"))
boards.append(Board8625(socid=99, board_num="8625"))
boards.append(Board8625(socid=100, board_num="8625"))
boards.append(Board8625(socid=101, board_num="8625"))
boards.append(Board8625(socid=102, board_num="8625"))
boards.append(Board8625(socid=103, board_num="8625"))
boards.append(Board8625(socid=127, board_num="8625"))
boards.append(Board8625(socid=128, board_num="8625"))
boards.append(Board8625(socid=129, board_num="8625"))
boards.append(Board8625(socid=131, board_num="8625"))
boards.append(Board8625(socid=132, board_num="8625"))
boards.append(Board8625(socid=133, board_num="8625"))
boards.append(Board8625(socid=135, board_num="8625"))

boards.append(Board8994(socid=207))

boards.append(Board8992(socid=251))
boards.append(Board8992(socid=252))

boards.append(Board8996(socid=246))
boards.append(Board8996(socid=291))
boards.append(Board8996(socid=315))
boards.append(Board8996(socid=316))

boards.append(Board8952(socid=264))

boards.append(Board8976(socid=266))
boards.append(Board8976(socid=274))
boards.append(Board8976(socid=277))
boards.append(Board8976(socid=278))

boards.append(Board9607(socid=290))
boards.append(Board9607(socid=296))
boards.append(Board9607(socid=297))
boards.append(Board9607(socid=298))
boards.append(Board9607(socid=299))

boards.append(Board8937(socid=294))
boards.append(Board8937(socid=295))

boards.append(Board8940(socid=313))

boards.append(Board8953(socid=293))
boards.append(Board8953(socid=304))
boards.append(Board450(socid=338))
boards.append(Board632(socid=349))
boards.append(Board632(socid=350))

boards.append(Board8917(socid=303))
boards.append(Board8917(socid=307))
boards.append(Board8917(socid=308))
boards.append(Board8917(socid=309))

boards.append(Board8920(socid=320))

boards.append(BoardCalifornium(socid=279))

boards.append(BoardCobalt(socid=292))
boards.append(Board8998(socid=292))

boards.append(Board660(socid=317))
boards.append(Board660(socid=324))
boards.append(Board660(socid=325))
boards.append(Board660(socid=326))

boards.append(Board630(socid=318))
boards.append(Board630(socid=327))

boards.append(BoardSDM845(socid=321))
boards.append(BoardSM8150(socid=339))
boards.append(BoardSDX20(socid=333))

boards.append(BoardSteppe(socid=355))
boards.append(BoardSteppe(socid=369))

boards.append(BoardSDM710(socid=336))
boards.append(BoardSDM710(socid=337))
boards.append(BoardSDM710(socid=360))

boards.append(BoardQCS605(socid=347))
boards.append(BoardQCS405(socid=352))
boards.append(BoardQCS403(socid=373))

boards.append(BoardPoorwills(socid=334))
boards.append(BoardPoorwills(socid=335))

boards.append(Board439(socid=353))
boards.append(Board439(socid=363))

boards.append(Board429(socid=354))
boards.append(Board429(socid=364))

def get_supported_boards():
    """ Called by other part of the code to get a list of boards """
    return boards

def get_supported_ids():
    """ Returns a list of ids to be used with --force-hardware"""
    return list(set(b.board_num for b in boards))
