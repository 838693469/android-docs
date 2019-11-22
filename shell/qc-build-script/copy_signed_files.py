#! /usr/bin/python
import os

os.system("rm -rf signed_out/");
os.system("mkdir signed_out");

files = [
	"adspso.bin",
	"cmnlib.mbn",
	"cmnlib64.mbn",
	"devcfg.mbn",
	"keymaster.mbn",
	"lksecapp.mbn",
	"NON-HLOS.bin",
	"rpm.mbn",
	"sbl1.mbn",
	"tz.mbn"
]

for _file in files:
	s_file_8917 = "".join(["signed_out_8917/", _file]);
	file_name_8917 = "".join(["8917_", _file]);
	t_file_8917 = "".join(["signed_out/", file_name_8917]);
	cmdline = " ".join(["cp", s_file_8917, t_file_8917]);
	print (cmdline);
	os.system(cmdline);

	s_file_8937 = "".join(["signed_out_8937/", _file]);
	file_name_8937 = "".join(["8937_", _file]);
	t_file_8937 = "".join(["signed_out/", file_name_8937]);
	cmdline = " ".join(["cp", s_file_8937, t_file_8937]);
	print (cmdline);
	os.system(cmdline);

os.system("cp signed_out_8917/sec.dat signed_out/");
os.system("cp signed_out_8917/prog_emmc_firehose_8917_ddr.mbn signed_out/");
os.system("cp signed_out_8937/prog_emmc_firehose_8937_ddr.mbn signed_out/");
