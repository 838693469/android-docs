# Copyright (c) 2017, The Linux Foundation. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

import os
from print_out import print_out_str

class module_table_entry():

    def __init__(self):
        self.name = ''
        self.module_offset = 0
        self.sym_lookup_table = []
        self.sym_path = ''

    def num_symbols(self):
        return len(self.sym_lookup_table)

    def set_sym_path(self, sym_path):
        if os.path.isfile(sym_path):
            self.sym_path = sym_path
            return True
        else:
            print_out_str('sym_path: ' + sym_path + ' not valid or file doesn\'t exist')
            return False

    def get_sym_path(self):
        return self.sym_path

class module_table_class():

    def __init__(self):
        self.module_table = []
        self.sym_path = ''

    def add_entry(self, new_entry):
        self.module_table.append(new_entry)

    def num_modules(self):
        return len(self.module_table)

    def setup_sym_path(self, sym_path):
        if sym_path is None:
            print_out_str('sym_path: not specified!')
            self.sym_path = ''
            return False
        elif not os.path.exists(sym_path):
            print_out_str('sym_path: ' + sym_path + ' not valid or directory doesn\'t exist')
            self.sym_path = ''
            return False
        else:
            self.sym_path = sym_path
            return True

    def sym_path_exists(self):
        return self.sym_path != ''


