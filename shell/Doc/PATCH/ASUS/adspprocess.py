
#=================================================================================
#   File Name: adspprocess.py
#
#   ADSP build system: build process functions
#
#   Copyright (c) 2014 QUALCOMM Technologies Incorporated.
#   All rights reserved. Qualcomm Proprietary and Confidential.
#
#---------------------------------------------------------------------------------
#
#  $Header: //components/rel/dspbuild.adsp/2.7.2/adspprocess.py#10 $
#  $DateTime: 2018/02/15 02:26:42 $
#  $Change: 15475035 $
#                      EDIT HISTORY FOR FILE
#
#  This section contains comments describing changes made to the module.
#  Notice that changes are listed in reverse chronological order.
#
#   when     who            what, where, why
# --------   ---        ----------------------------------------------------------
# 04/24/14   corinc      Move functions from build\build.py to adspprocess.py
# 04/29/14   corinc      Initial check-in and promotion to PW
# 05/08/14   corinc      re-architect and fixed the issue for alias
# 07/24/14   corinc      set_chipset_target() update
#=================================================================================

import os
import re
import subprocess
import sys
import time
import fnmatch
import shutil, errno
import buildSysInfo
try:
   import argparse
except ImportError:
   print 'Python version is: ' + sys.version
   print 'ADSP build system  requires Python version 2.7.6 and above.'
   print 'If you have Python version 2.7.6 installed, please check the environment path.'
   sys.exit(0)
#=================================================================================
#=================================================================================
#                  Function definitions are below
#=================================================================================
#=================================================================================

# Function definition 'set_chipset_target' is here
def set_chipset_target(str, chipset_param, opts):
# Setting CHIPSET and TARGET here
   opts_chipset = opts.chipset
   
   if str is None or opts_chipset:
      str = chipset_param

#   print "str = ", str
   a = re.compile('\d\w\d+')
   targets = a.findall(str)+[0]
   print targets
   target = targets[0]
   target1 = targets[1]
   print "target :",target
   print "target1:",target1
      
   if target=='8974':
     os.environ['CHIPSET'] = "msm8974"
     os.environ['TARGET'] = "8974"
     q6_version = "v5"
     q6_tools_version = '5.1.04'
   elif target=='9625':
     os.environ['CHIPSET'] = "mdm9x25"
     os.environ['TARGET'] = "9x25"
     q6_version = "v5"
     q6_tools_version = '5.1.05'
   elif target=='8626' or target=='8x26':
     os.environ['CHIPSET'] = "msm8x26"
     os.environ['TARGET'] = "8x26"   
     q6_version = "v5"
     q6_tools_version = '5.1.04'
   elif target=='8610' or target=='8610':
     os.environ['CHIPSET'] = "msm8x10"
     os.environ['TARGET'] = "8x10"
     q6_version = "v5"
     q6_tools_version = '5.1.04'
   elif target=='8084':
     os.environ['CHIPSET'] = "apq8084"
     os.environ['TARGET'] = "8084"
     q6_version = "v5"
     q6_tools_version = '5.1.04'
   elif target=='9635' or target=='9x35':
     os.environ['CHIPSET'] = "mdm9x35"
     os.environ['TARGET'] = "9x35"
     q6_version = "v55"
     q6_tools_version = '5.1.05'
   elif target=='8994':
     os.environ['CHIPSET'] = "msm8994"
     os.environ['TARGET'] = "8994"
     q6_version = "v55"
     q6_tools_version = '5.1.05'
   elif target=='8992':
     os.environ['CHIPSET'] = "msm8992"
     os.environ['TARGET'] = "8992"
     q6_version = "v55"
     q6_tools_version = '5.1.05'
   elif target=='8952':
     os.environ['CHIPSET'] = "msm8952"
     os.environ['TARGET'] = "8952"
     q6_version = "v55"
     q6_tools_version = '5.1.05'     
   elif target=='8953':
     os.environ['CHIPSET'] = "msm8953"
     os.environ['TARGET'] = "8953"
     q6_version = "v55"
     q6_tools_version = '8.0.07' 
     # q6_tools_version = '7.4.02' 
     # q6_tools_version = '5.1.05' 
   elif target=='8937':
     os.environ['CHIPSET'] = "msm8937"
     os.environ['TARGET'] = "8937"
     q6_version = "v55"
     q6_tools_version = '8.0.09' 
     # q6_tools_version = '7.4.02' 
     # q6_tools_version = '5.1.05'
   elif target=='439':
     os.environ['CHIPSET'] = "sdm439"
     os.environ['TARGET'] = "439"
     q6_version = "v55"
     q6_tools_version = '8.0.07' 
     # q6_tools_version = '7.4.02' 
     # q6_tools_version = '5.1.05'	 
   elif target=='8976':
     os.environ['CHIPSET'] = "msm8976"
     os.environ['TARGET'] = "8976"
     q6_version = "v55"
     q6_tools_version = '8.0.07'       
     # q6_tools_version = '7.4.02'       
#     q6_tools_version = '5.1.05'       
   elif target=='8996':
     os.environ['CHIPSET'] = "msm8996"
     os.environ['TARGET'] = "8996"
     q6_version = "v60"
     q6_tools_version = '7.2.05'
   else:
     print 'CHIPSET not detected'
     sys.exit(0)
   
   # write the QDSP6 version into OS environments - need to reduce these to just 1
   os.environ['Q6VERSION'] = q6_version
   os.environ['HEXAGON_Q6VERSION'] = q6_version
   os.environ['HEXAGON_REQD_Q6VERSION'] = q6_version
   
   # check the tool version set from the command line, use the one from command line
   if opts.toolversion != "":
      q6_tools_version = opts.toolversion
   
   os.environ['HEXAGON_RTOS_RELEASE'] = q6_tools_version
   # temporary workaround to fix Sensors' scons file
   os.environ['HEXAGON_REQD_RTOS_RELEASE'] = '5.1.04'

   if int(q6_tools_version[0]) <= 5:
      os.environ['COMPILER'] = "gcc"
   else:
      os.environ['COMPILER'] = "llvm"


   print 'CHIPSET: ', os.environ['CHIPSET']
   print 'TARGET: ', os.environ['TARGET']
   print 'HEXAGON_Q6VERSION: ', os.environ['HEXAGON_Q6VERSION']
   print 'HEXAGON_RTOS_RELEASE:', os.environ['HEXAGON_RTOS_RELEASE']
   print 'Hexagon Tool COMPILER Type: ', os.environ['COMPILER']
   print '\n'
   
   return;


# Function definition 'cosim_tfw' is here
def cosim_tfw():
# only cosim build test      
      os.environ['VS90COMNTOOLS'] = "C:/Program Files (x86)/Microsoft Visual Studio 9.0/Common7/Tools/"
      print 'Build Cosim...'
      cosim_build_cmd = ''.join(['adsptest-build.cmd '])
      print cosim_build_cmd
      proc = subprocess.Popen(cosim_build_cmd, shell=True)
      (out, err) = proc.communicate()
      
      return;
   
# Function to Verify if watchdog timeout happened during CoSim test
def verify_test_log(logfile_name_temp):
       result_flag = 0
       logfile = open(logfile_name_temp, 'r')
       
       for line in logfile:        
          test_match = re.search('WATCHDOG TIMEOUT EXPIRED!', line)
          if test_match:
             result_flag = 1             
       logfile.close()
       
       if os.path.exists(logfile_name_temp):
             try:
                     os.remove(logfile_name_temp)                             
             except:
                     print "Exception: ",str(sys.exc_info())
       else:
             print "File '%s' not found" % logfile_name_temp
             
       return result_flag
       
   
# Function definition 'cosim_tfw_run' is here
def oemroot_cosim_tfw_run():
# cosim build and test      
      print 'Run CoSim Test...'
      print '\n\nRunning \'elite_examples.qtfw\' Test...\n'
      cosim_run_cmd = ''.join(['adsptest-run.cmd --test elite_examples.qtfw ', '--watchdog-timeout 2000 --- --dsp_clock 83 > ../../opendsp_elite_examples.log 2>&1'])    
      print cosim_run_cmd
      proc = subprocess.Popen(cosim_run_cmd, shell=True)
      #waiting for 10 mins before terminating the tfwk process
      #exits if process completes before time-out
      elite_time_out = 600.0
      elapsed = 0
      flag_elapsed = 0
      wait_b4_poll = 120  # wait for 2 mins
      while proc.poll() is None:
             time.sleep(wait_b4_poll)
             elapsed = elapsed + wait_b4_poll
             #print "elapsed = %s" % elapsed
             logfile_name = '../../opendsp_elite_examples.log'
             logfile_name_temp = '../../opendsp_elite_examples_temp.log'
             if os.path.exists(logfile_name):
                 shutil.copy(logfile_name, logfile_name_temp)               
                 result_flag = verify_test_log(logfile_name_temp)   #Verify if watchdog timeout happened during CoSim test             
             if elapsed > elite_time_out or result_flag == 1:
                  subprocess.Popen("start taskkill /F /T /PID %i"%proc.pid , shell=True)
                  if elapsed > elite_time_out:
                     print "elite_examples Test process is killed as it exceeded time-out of (in secs): ", elite_time_out
                  if result_flag == 1:
                     print "elite_examples Test process is killed as watchdog timer (2 Secs) is expired !!!"                  
                  flag_elapsed = 1
      if flag_elapsed == 0:
         print "elite_examples Test process completed (in secs) before time-out: ", elapsed   
      
      
      print '\n\nRunning \'example_capi.qtfw\' Test...\n'
      cosim_run_cmd = ''.join(['adsptest-run.cmd --test example_capi.qtfw ', '--watchdog-timeout 2000 --- --dsp_clock 83 > ../../opendsp_example_capi.log 2>&1'])    
      print cosim_run_cmd
      proc = subprocess.Popen(cosim_run_cmd, shell=True)
      #waiting for 10 mins before terminating the tfwk process
      #exits if process completes before time-out
      capi_time_out = 600.0
      elapsed = 0
      flag_elapsed = 0
      while proc.poll() is None:
             time.sleep(wait_b4_poll)
             elapsed = elapsed + wait_b4_poll
             #print "elapsed = %s" % elapsed
             logfile_name = '../../opendsp_example_capi.log'
             logfile_name_temp = '../../opendsp_example_capi_temp.log'
             if os.path.exists(logfile_name):
                 shutil.copy(logfile_name, logfile_name_temp)               
                 result_flag = verify_test_log(logfile_name_temp)   #Verify if watchdog timeout happened during CoSim test
             if elapsed > capi_time_out or result_flag == 1:
                  subprocess.Popen("start taskkill /F /T /PID %i"%proc.pid , shell=True)
                  if elapsed > capi_time_out:
                     print "example_capi Test process is killed as it exceeded time-out of (in secs): ", capi_time_out
                  if result_flag == 1:
                     print "example_capi Test process is killed as watchdog timer (2 Secs) is expired !!!"                  
                  flag_elapsed = 1
      if flag_elapsed == 0:
         print "example_capi Test process completed (in secs) before time-out: ", elapsed    
      
      
      print '\n\nRunning \'examples.qtfw\' Test...\n'
      cosim_run_cmd = ''.join(['adsptest-run.cmd --test examples.qtfw ', '--watchdog-timeout 2000 --- --dsp_clock 83 > ../../opendsp_examples.log 2>&1'])    
      print cosim_run_cmd
      proc = subprocess.Popen(cosim_run_cmd, shell=True)
      #waiting for 10 mins before terminating the tfwk process
      #exits if process completes before time-out
      examples_time_out = 600.0
      elapsed = 0
      flag_elapsed = 0
      while proc.poll() is None:
             time.sleep(wait_b4_poll)
             elapsed = elapsed + wait_b4_poll
             #print "elapsed = %s" % elapsed
             logfile_name = '../../opendsp_examples.log'
             logfile_name_temp = '../../opendsp_examples_temp.log'
             if os.path.exists(logfile_name):
                 shutil.copy(logfile_name, logfile_name_temp)               
                 result_flag = verify_test_log(logfile_name_temp)   #Verify if watchdog timeout happened during CoSim test           
             if elapsed > examples_time_out or result_flag == 1:
                  subprocess.Popen("start taskkill /F /T /PID %i"%proc.pid , shell=True)
                  if elapsed > examples_time_out:
                     print "examples Test process is killed as it exceeded time-out of (in secs): ", examples_time_out
                  if result_flag == 1:
                     print "examples Test process is killed as watchdog timer (2 Secs) is expired !!!"
                  flag_elapsed = 1
      if flag_elapsed == 0:
         print "examples Test process completed (in secs) before time-out: ", elapsed
      
      
      adsp_dir = "../.."
      try:
           os.chdir(adsp_dir)
           cwd_dir = os.getcwd()
           print "\n\nCurrent working directory now changed to %s" % cwd_dir
      except os.error:
           print "Your are already in 'adsp_proc' or not able to change directory to this directory"
           pass # do nothing!
         
      return;      


   
# Function definition 'cosim_tfw_run' is here
def cosim_tfw_run():
# cosim build and test      
      print 'Run CoSim Test...'
      print '\n\nRunning Sanity Test...\n'
      cosim_run_cmd = ''.join(['adsptest-run.cmd --test sanity.qtfw ', '--watchdog-timeout 2000 --- --dsp_clock 83 > ../../opendsp_sanity.log 2>&1'])    
      print cosim_run_cmd
      proc = subprocess.Popen(cosim_run_cmd, shell=True)
      #waiting for 30 mins before terminating the tfwk process
      #exits if process completes before time-out      
      sanity_time_out = 1800.0
      elapsed = 0
      flag_elapsed = 0
      wait_b4_poll = 120  # wait for 2 mins
      while proc.poll() is None:
             time.sleep(wait_b4_poll)
             elapsed = elapsed + wait_b4_poll
             #print "elapsed = %s" % elapsed
             logfile_name = '../../opendsp_sanity.log'
             logfile_name_temp = '../../opendsp_sanity_temp.log'
             if os.path.exists(logfile_name):
                 shutil.copy(logfile_name, logfile_name_temp)               
                 result_flag = verify_test_log(logfile_name_temp)   #Verify if watchdog timeout happened during CoSim test             
             if elapsed > sanity_time_out or result_flag == 1:
                  subprocess.Popen("start taskkill /F /T /PID %i"%proc.pid , shell=True)
                  if elapsed > sanity_time_out:
                     print "Sanity Test process is killed as it exceeded time-out of (in secs): ", sanity_time_out
                  if result_flag == 1:
                     print "Sanity Test process is killed as watchdog timer (2 Secs) is expired !!!"                  
                  flag_elapsed = 1
      if flag_elapsed == 0:
         print "Sanity Test process completed (in secs) before time-out: ", elapsed
       
            
      print '\n\nRunning Lua-Sanity Test...\n'
      cosim_run_cmd = ''.join(['adsptest-run.cmd --test lua-sanity.qtfw ', '--watchdog-timeout 2000 --- --dsp_clock 83 > ../../opendsp_lua_sanity.log 2>&1'])    
      print cosim_run_cmd
      proc = subprocess.Popen(cosim_run_cmd, shell=True)
      #waiting for 30 mins before terminating the tfwk process
      #exits if process completes before time-out
      lua_time_out = 1800.0
      elapsed = 0
      flag_elapsed = 0
      while proc.poll() is None:
             time.sleep(wait_b4_poll)
             elapsed = elapsed + wait_b4_poll
             #print "elapsed = %s" % elapsed
             logfile_name = '../../opendsp_lua_sanity.log'
             logfile_name_temp = '../../opendsp_lua_sanity_temp.log'
             if os.path.exists(logfile_name):
                 shutil.copy(logfile_name, logfile_name_temp)               
                 result_flag = verify_test_log(logfile_name_temp)   #Verify if watchdog timeout happened during CoSim test             
             if elapsed > lua_time_out or result_flag == 1:
                  subprocess.Popen("start taskkill /F /T /PID %i"%proc.pid , shell=True)
                  if elapsed > lua_time_out:
                     print "Lua-Sanity Test process is killed as it exceeded time-out of (in secs): ", lua_time_out
                  if result_flag == 1:
                     print "Lua-Sanity Test process is killed as watchdog timer (2 Secs) is expired !!!"                  
                  flag_elapsed = 1
      if flag_elapsed == 0:
         print "Lua-Sanity Test process completed (in secs) before time-out: ", elapsed
      
      
      adsp_dir = "../.."
      try:
           os.chdir(adsp_dir)
           cwd_dir = os.getcwd()
           print "\n\nCurrent working directory now changed to %s" % cwd_dir
      except os.error:
           print "Your are already in 'adsp_proc' or not able to change directory to this directory"
           pass # do nothing!
         
      return;      


# Function definition 'check_success' is here
def check_success():
# check if success file present
      file_name="success"
      if os.path.exists(file_name):
          try:
              os.remove(file_name)
          except:
              print "Exception: ",str(sys.exc_info())
      else:
          print "File '%s' not found" % file_name


      return;

# Function definition 'verify_args' is here
def verify_args(str, array_var):
      arg_flag = 0         
      for each_element in array_var:         
         match = re.search(str, each_element, re.I)
         if match: arg_flag = 1         

      return arg_flag;      

# Class definition 'other_options_cb' is here
class other_options_cb(argparse.Action):
        def __call__(self, parser, namespace, values, option_string=None):
           #print '%r %r %r' % (namespace, values, option_string)
           #setattr(namespace, self.dest, values)           
           
           args=[]
           temp_arg=0           
           for arg in values:
              if arg[0] != "-" or temp_arg != " ":                             
                 args.append(arg)                           
              else:
                 del values[:len(args)]
                 break
              temp_arg = arg[0]        
           
           if getattr(namespace, self.dest):                    
              args.extend(getattr(namespace, self.dest))
           setattr(namespace, self.dest, values)


# Function definition 'summary_build' is here
def summary_build(opts, defSysInfo, bldSysInfo):
      print '\n\n********************************************************'
      print '*************** Summary Build Environment **************'
      print '********************************************************'      
      print 'Command Given on Console: ', ' '.join(sys.argv)      
      if os.name == 'posix':
         print "Operating System:: Linux"
      else:
         print "Operating System:: Windows"
      
      if sys.version:
         print "Python Version::", sys.version_info[0:3]

         if sys.version_info[0] != 2:
             print "ERROR:: You are not using Python 2.x. Please use 2.7.6"
             sys.exit(0)
      else:
         print '\n\nERROR: Python not installed!!!'
         print 'If installed already, please verify if respective path added to PATH environment variable!!!\n\n'
         sys.exit(0)
      
      tool_version = ''.join(['perl -v'])
      proc = subprocess.Popen(tool_version, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
      (out, err) = proc.communicate()
      if out:
         print "Perl Version::", out
      else:
         print 'WARNING: Perl required to execute Post Build Step (Memory Profiling Scripts)!!!'

      if  os.environ.get('COMPILER') is 'llvm':
         print 'COMPILER= llvm'
      else:
         print 'COMPILER= gcc'	  
        
      tool_version = ''.join(['hexagon-sim --version'])
      proc = subprocess.Popen(tool_version, stdout=subprocess.PIPE, shell=True)

      (out, err) = proc.communicate()      
      if out:         
         tool_version = ''.join(['hexagon-sim --version > ./build/toolsver.txt 2>&1'])
         proc = subprocess.Popen(tool_version, stdout=subprocess.PIPE, shell=True)
         (out, err) = proc.communicate()
         toolsver_filelist = find_files('build', 'toolsver.txt')
	 if toolsver_filelist:
	    toolsver_file = open( "build/toolsver.txt", "r" )
	    lines = []
	    for line in toolsver_file:	       
	       toolsver_match = re.search('Hexagon Build Version \(*(\d.\d.\d\d)', line)
	       if toolsver_match:
	          tools_ver = toolsver_match.group(1)
	          print 'You are using Hexagon Tools Version: ', tools_ver
	    toolsver_file.close()
	    os.remove('build/toolsver.txt')
            # Tools version can be specified in the command line now, no need to check
            # the tools version and abort. User to make sure the tools version during compilation
            # if tools_ver != (os.environ['HEXAGON_REQD_RTOS_RELEASE']):	       
               # print '\nERROR: Please install Required Hexagon Tools Version: ', os.environ['HEXAGON_REQD_RTOS_RELEASE']
               # print '       If it is intentional, please update HEXAGON_REQD_RTOS_RELEASE at \'Required Versions\' section in \'build.py\' accordingly!!!'
               # print '         (OR) set HEXAGON_REQD_RTOS_RELEASE environment variable accordingly!!!'
               # sys.exit(0)
      # else:         
         # print '\n\nERROR: Hexagon Tools not installed!!!'
         # print 'Recommended locations:'
         # print '     Windows: C:\Qualcomm\HEXAGON_Tools'
         # print '     Linux: $HOME/Qualcomm/HEXAGON_Tools (OR) /pkg/qct/software/hexagon/releases/tools'
         # print '     Note: If installed at other locations, please update \'Software Paths & other definitions\' section in \'build.py\' accordingly'
         # print '           (OR) set HEXAGON_ROOT and HEXAGON_RTOS_RELEASE environment variables accordingly'
         # print '                 Eg: set HEXAGON_ROOT=C:\Qualtools\Hexagon'
         # print '                     set HEXAGON_RTOS_RELEASE=5.1.04'
         # sys.exit(0)
      
      print 'Q6VERSION=', os.environ['Q6VERSION']
      print 'Q6_TOOLS_ROOT=', os.environ['Q6_TOOLS_ROOT']
      if bldSysInfo.buildid_flag:
         print 'QDSP6_BUILD_VERSION=', os.environ.get('QDSP6_BUILD_VERSION', None)
      elif defSysInfo.default_buildid:
         print "QDSP6_BUILD_VERSION= [Value Taken from file 'adsp_proc/hap/default_pack.txt']:", os.environ.get('QDSP6_BUILD_VERSION', None)         
      else:
         print 'QDSP6_BUILD_VERSION= [Default Value Taken]', os.environ.get('QDSP6_BUILD_VERSION', None)
      
      # Corin: This chipset_flag is kind of redundant if setting the default chipset is not allowed, remove this later
      if bldSysInfo.chipset_flag:
         print 'CHIPSET=', os.environ.get('CHIPSET', None)
         print 'TARGET=',  os.environ.get('TARGET', None)
      
      if bldSysInfo.protection_domain_flag:
         print 'BUILD_FLAVOR=',  os.environ.get('BUILD_FLAVOR', None)
      elif defSysInfo.default_pid:
         print "BUILD_FLAVOR= [Value Taken from file 'adsp_proc/hap/default_pack.txt']:", os.environ.get('BUILD_FLAVOR', None)
      else:   
         print 'BUILD_FLAVOR= [Default Value Taken]',  os.environ.get('BUILD_FLAVOR', None)   
      
      if bldSysInfo.other_option_flag:
         if os.environ.get('BUILD_ACT', None) == '':
            print 'BUILD_ACT= all'
         else:   
            print 'BUILD_ACT=',  os.environ.get('BUILD_ACT', None)
      elif defSysInfo.default_others:
         print "BUILD_ACT= [Value Taken from file 'adsp_proc/hap/default_pack.txt']:",  os.environ.get('BUILD_ACT', None)
      
      arg_flag = 0
      if bldSysInfo.other_option_flag:
         arg_flag = verify_args('\Aklocwork\Z', opts.other_option)         
         if arg_flag or bldSysInfo.klocwork_flag:
            print 'Klocwork is Enabled!!!'
         else:
            print 'Klocwork is NOT Enabled!!!'   
      
      arg_flag = 0
      if bldSysInfo.other_option_flag:
         arg_flag = verify_args('cosim', opts.other_option)         
         if arg_flag:
            arg_flag = 0
            arg_flag = verify_args('\Acosim\Z', opts.other_option)         
            if arg_flag:      
               print 'Build & Run of CoSim Test is Enabled!!!'
            arg_flag = 0            
            arg_flag = verify_args('\Acosim_run\Z', opts.other_option)         
            if arg_flag:      
               print 'Only Run of CoSim Test is Enabled!!!'      
         else:
            print 'Build & Run of CoSim Test is NOT Enabled!!!'
            
      if bldSysInfo.build_verbose_flag:
         if os.environ['BUILD_VERBOSE'] == '0': 
            print 'Custom Verbose level taken is 0(=off)'
         elif os.environ['BUILD_VERBOSE'] == '1': 
            print 'Custom Verbose level taken is 1(=limited)'            
         elif os.environ['BUILD_VERBOSE'] == '2': 
            print 'Custom Verbose level taken is 2(=detailed)'
         elif os.environ['BUILD_VERBOSE'] == '3':
            print 'Custom Verbose level taken is 3(=raw, no formatting)'
         else:
            print 'WARNING: Specified Custom Verbose level NOT Supported!!!: ', os.environ['BUILD_VERBOSE']
            print '         So, Default Verbose level is taken i.e., 1(=limited)'
      elif defSysInfo.default_verbose:
         if os.environ['BUILD_VERBOSE'] == '0': 
            print "Custom Verbose level taken is 0(=off) [Value Taken from file 'adsp_proc/hap/default_pack.txt']"
         elif os.environ['BUILD_VERBOSE'] == '1': 
            print "Custom Verbose level taken is 1(=limited) [Value Taken from file 'adsp_proc/hap/default_pack.txt']"
         elif os.environ['BUILD_VERBOSE'] == '2': 
            print "Custom Verbose level taken is 2(=detailed) [Value Taken from file 'adsp_proc/hap/default_pack.txt']"
         elif os.environ['BUILD_VERBOSE'] == '3':
            print "Custom Verbose level taken is 3(=raw, no formatting) [Value Taken from file 'adsp_proc/hap/default_pack.txt']"
         else:
            print "WARNING: Specified Custom Verbose level NOT Supported [Value Taken from file 'adsp_proc/hap/default_pack.txt'] !!!: ", os.environ['BUILD_VERBOSE']                     
            print '         So, Default Verbose level is taken i.e., 1(=limited)'  
      else:
            print 'Default Verbose level is taken i.e., 1(=limited) !!!' 
         
      if bldSysInfo.build_filter_flag:
         print 'Individual Module Compilation Enabled for: ', os.environ['BUILD_FILTER']
      elif defSysInfo.default_flags:            
         print "Individual Module Compilation Enabled for [Value Taken from file 'adsp_proc/hap/default_pack.txt']: ", os.environ['BUILD_FILTER']         
      else:
         print 'Individual Module Compilation NOT Enabled !!!'
            
      if bldSysInfo.image_alias_flag:      
         print 'Image alias is: ', os.environ['BUILD_COMPONENT']
      elif defSysInfo.default_alias:            
         print "Image alias is [Value Taken from file 'adsp_proc/hap/default_pack.txt']: ", os.environ['BUILD_COMPONENT']                  
      else:
         print 'Image alias NOT assigned (By Default, script will assign target specific image aliases based on chipset information) !!!'         

      if bldSysInfo.build_sconsargs_flag:
         print 'SCons Options Enabled are:', bldSysInfo.opts_sconsargs
      elif defSysInfo.default_sconsargs:
         print "SCons Options Enabled are [Value Taken from file 'adsp_proc/hap/default_pack.txt']: ", bldSysInfo.opts_sconsargs
      else:
         print 'Any SCons Options NOT Enabled !!!'         

      if bldSysInfo.build_userargs_flag:
         print 'Custom user Options Enabled are:', bldSysInfo.opts_userargs
      elif defSysInfo.default_userargs:
         print "Custom user Options Enabled are [Value Taken from file 'adsp_proc/hap/default_pack.txt']: ", bldSysInfo.opts_userargs
      else:
         print 'Any custom user Options NOT Enabled !!!'  
      
      if bldSysInfo.build_flags:
         print 'Build Flags Enabled are:', bldSysInfo.flags_param
      elif defSysInfo.default_flags:
         print "Build Flags Enabled are [Value Taken from file 'adsp_proc/hap/default_pack.txt']:", bldSysInfo.flags_param
      else:
         print 'Any custom Build flags NOT Enabled !!!'   
         
      
      print "\nFor Build Command help, use -h option: python build.py -h"
      print '********************************************************'      
      print '************** End of Build Environment ****************'
      print '********************************************************'
      print '\n'
      

def find_files(base, pattern):
    '''Return list of files matching pattern in base folder.'''
    return [n for n in fnmatch.filter(os.listdir(base), pattern) if
        os.path.isfile(os.path.join(base, n))]

def test_framework(opts, bldSysInfo, new_path):
   arg_flag = 0
   if bldSysInfo.other_option_flag:
      arg_flag = verify_args('cosim', opts.other_option)         
   if arg_flag or bldSysInfo.cosim_flag or bldSysInfo.cosim_run_flag:
         new_cosim_path = ''.join([new_path, ';', bldSysInfo.local_path])
         os.environ['PATH'] = new_cosim_path
	 print 'New PATH before cosim/cosim_run:\n', os.environ['PATH']
         time.sleep(3)
         
         test_dir = "aDSPSim"
         try:
              os.chdir(test_dir)
              cwd_dir = os.getcwd()
              print "\n\nCurrent working directory now changed to %s" % cwd_dir
         except os.error:
              print "Your are already in aDSPSim or not able to change directory to this directory"
              pass # do nothing!
         
         arg_flag = 0
         if bldSysInfo.other_option_flag:
            arg_flag = verify_args('\Acosim\Z', opts.other_option)         
         if arg_flag or bldSysInfo.cosim_flag:
               cosim_tfw()   #Build cosim
               check_success()
               cosim_tfw_run()   #Test Cosim
       
         arg_flag = 0
         if bldSysInfo.other_option_flag:
            arg_flag = verify_args('\Acosim_run\Z', opts.other_option)         
         if arg_flag or bldSysInfo.cosim_run_flag: 
               check_success()
               cosim_tfw_run()   #Test Cosim
       
         arg_flag = 0
         if bldSysInfo.other_option_flag:
            arg_flag = verify_args('\Aoemroot_cosim_run\Z', opts.other_option)         
         if arg_flag or bldSysInfo.oemroot_cosim_run_flag: 
               check_success()
               oemroot_cosim_tfw_run()   #OEM_ROOT Test Cosim               
               
 

def postprocess_command_options(opts, args):
   #For windows: hypen('-') or double-dash('--') is converted to character 0x96 if build command is copy-pasted from outlook.
   #For Linux: hypen('-') or double-dash('--') is removed if build command is copy-pasted from outlook.
   
   #This function avoids script taking default value for the above cases by:
   #   a. replacing character 0x96 back to '-'.
   #   b. recognizing option without '-' or '--'.
   j = 0
   for i in args:
      temp = i.replace('\x96', '-')      
      args[j] = temp      
      if args[j] == '-b' or args[j] == 'b' or args[j] == '-buildid':
         opts.buildid = args[j+1]   
      if args[j] == '-c' or args[j] == 'c' or args[j] == '-chipset':
         opts.chipset = args[j+1]
      if args[j] == '-p' or args[j] == 'p' or args[j] == '-pid':
         opts.protection_domain = args[j+1]   
      if args[j] == '-o' or args[j] == 'o' or args[j] == '-others':
         opts.other_option = args[j+1]         
      if args[j] == '-f' or args[j] == 'f' or args[j] == '-flags':
         opts.flags = args[j+1]                    
      if args[j] == '-k' or args[j] == 'k' or args[j] == '-kloc':
         opts.kloc = True
      if args[j] == '-v' or args[j] == 'v' or args[j] == '-verbose':
         opts.verbose = args[j+1]
      if args[j] == '-m' or args[j] == 'm' or args[j] == '-module':
         opts.module = args[j+1]   
      if args[j] == '-a' or args[j] == 'a' or args[j] == '-alias':
         opts.alias = args[j+1]
      if args[j] == '-s' or args[j] == 's' or args[j] == '-sconsargs':
         opts.sconsargs = args[j+1]    
      if args[j] == '-u' or args[j] == 'u' or args[j] == '-userargs':
         opts.userargs = args[j+1]         
      if args[j] == '-tv' or args[j] == 'tv' or args[j] == '-toolversion':
         opts.toolversion = args[j+1]
      if args[j] == '-h' or args[j] == 'h' or args[j] == '-help':         
         parser.print_help()
         print "\n\n"
         sys.exit(0)
      j = j+1
   return (opts, args)

def process_array(array):
      n = 0
      for m in array:         
         temp = m.replace('\x96', '-')         
         match = re.search('(-)', temp)         
         if match:            
            break
         else:            
            array[n] = temp
            n = n + 1
      array = array[:n]      
      return array;



def search_exe_tool(search_tool):
   if search_tool == 'which':
     q6_tools_path_linux = 'None'
     tools_find = ''.join([search_tool, ' hexagon-sim'])
     proc = subprocess.Popen(tools_find, stdout=subprocess.PIPE, shell=True)
     (out, err) = proc.communicate()
     tools_match = re.search('(.*)(\d.\d.\d\d)', out)
     if tools_match:
        tools_path = tools_match.group(1).replace('\\', '/').rstrip('/')        
        if os.path.exists(tools_path):
           print 'For Linux: Hexagon tools taken from local path and not from recommended path: ', tools_path
           q6_tools_path_linux = tools_path
     return (q6_tools_path_linux)
   
   if search_tool == 'where':
     q6_tools_path_win = 'None'
     tools_find = ''.join(['where hexagon-sim'])
     proc = subprocess.Popen(tools_find, stdout=subprocess.PIPE, shell=True)
     (out, err) = proc.communicate()     
     tools_match = re.search('(.*)(\d.\d.\d\d)', out)   
     if tools_match:
        tools_path = tools_match.group(1).replace('\\', '/').rstrip('/')        
        if os.path.exists(tools_path):
           print 'For Windows: Hexagon tools taken from local path and not from recommended path: ', tools_path
           q6_tools_path_win = tools_path          
     return (q6_tools_path_win)
   
#=================================================================================
#================================================================================= 
def allOptionsCheck(opts, alloptions, defSysInfo, bldSysInfo):

    for m in alloptions:
        if m == 'chipset':
           if not opts.chipset:
              bldSysInfo.chipset_param = ''                 
              if defSysInfo.default_chipset:
                 bldSysInfo.chipset_param = defSysInfo.default_chipset
                 print "chipset option not specified, default value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % bldSysInfo.chipset_param
              else:
                 print 'chipset option not specified, chipset_param is: NULL'
           else:  
              print m
              bldSysInfo.chipset_param = getattr(opts, m)
              bldSysInfo.chipset_flag = 1
           bldSysInfo.chipset_param = bldSysInfo.chipset_param.lower()       
        if m == 'buildid':
           if not opts.buildid:
              bldSysInfo.buildid_param = '0x8fffffff'
              if defSysInfo.default_buildid:
                 bldSysInfo.buildid_param = defSysInfo.default_buildid
                 print "buildid option not specified, default value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % bldSysInfo.buildid_param
              else:
                 print 'buildid option not specified, setting default:', bldSysInfo.buildid_param
           else:
              bldSysInfo.buildid_param = getattr(opts, m)
              bldSysInfo.buildid_flag = 1
           bldSysInfo.buildid_param = bldSysInfo.buildid_param.lower()       
        if m == 'protection_domain':  
           if not opts.protection_domain:
              protection_domain_param = 'mpd'
              if defSysInfo.default_pid:
                 protection_domain_param = defSysInfo.default_pid
                 print "protection domain option not specified, default value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % protection_domain_param
              else:          
                 print 'protection domain option not specified, setting default:', protection_domain_param
           else:
              protection_domain_param = getattr(opts, m)
              bldSysInfo.protection_domain_flag = 1
           protection_domain_param = protection_domain_param.lower()       
           if protection_domain_param == 'mpd':
              bldSysInfo.mpd_flag = 1
           if protection_domain_param == 'spd':
              bldSysInfo.spd_flag = 1
        if m == 'other_option':
           print 'other options:', opts.other_option
           if opts.other_option:

              bldSysInfo.other_option_flag = 1
              if ((defSysInfo.default_testothers and opts.kloc) or opts.test):
                 #This is ONLY for CRM i.e., with -k option ONLY
                 #Also, enables only for opendsp packages as it needs 'hap/default_test.txt'
                 default_testarray = defSysInfo.default_testothers.split(',')
                 print 'other options from \'default_test.txt\': ', default_testarray
                 bldSysInfo.all_flag = verify_args('\Aall\Z', default_testarray) 
                 bldSysInfo.clean_flag = verify_args('\Aclean\Z', default_testarray)
                 bldSysInfo.klocwork_flag = verify_args('\Aklocwork\Z', default_testarray)
                 bldSysInfo.cosim_flag = verify_args('\Acosim\Z', default_testarray)
                 bldSysInfo.cosim_run_flag = verify_args('\Acosim_run\Z', default_testarray)
                 bldSysInfo.oemroot_cosim_run_flag = verify_args('\Aoemroot_cosim_run\Z', default_testarray)
                 bldSysInfo.sim_flag = verify_args('\ASIM\Z', default_testarray)
                 bldSysInfo.sim_check = verify_args('\Achecksim\Z', default_testarray)
                 bldSysInfo.check_dsp_flag = verify_args('\Acheck_dsp\Z', default_testarray)
              else:
                 bldSysInfo.all_flag = verify_args('\Aall\Z', opts.other_option)
                 bldSysInfo.clean_flag = verify_args('\Aclean\Z', opts.other_option)
                 bldSysInfo.klocwork_flag = verify_args('\Aklocwork\Z', opts.other_option)
                 bldSysInfo.cosim_flag = verify_args('\Acosim\Z', opts.other_option)
                 bldSysInfo.cosim_run_flag = verify_args('\Acosim_run\Z', opts.other_option)
                 bldSysInfo.oemroot_cosim_run_flag = verify_args('\Aoemroot_cosim_run\Z', opts.other_option)
                 bldSysInfo.sim_flag = verify_args('\ASIM\Z', opts.other_option)
                 bldSysInfo.sim_check = verify_args('\Achecksim\Z', opts.other_option)
                 bldSysInfo.pkg_all_flag = verify_args('\Apkg_all\Z', opts.other_option)
                 bldSysInfo.pkg_hy22_flag = verify_args('\Apkg_hy22\Z', opts.other_option)
                 bldSysInfo.pkg_hk11_flag = verify_args('\Apkg_hk11\Z', opts.other_option)
                 bldSysInfo.pkg_hk22_flag = verify_args('\Apkg_hk22\Z', opts.other_option)
                 bldSysInfo.pkg_oem_flag = verify_args('\Apkg_oem\Z', opts.other_option)
                 bldSysInfo.pkg_hd11_flag = verify_args('\Apkg_hd11\Z', opts.other_option)
                 bldSysInfo.pkg_isv_flag = verify_args('\Apkg_isv\Z', opts.other_option)
                 bldSysInfo.pkg_hcbsp_flag = verify_args('\Apkg_hcbsp\Z', opts.other_option)
                 bldSysInfo.pkg_hd22_flag = verify_args('\Apkg_hd22\Z', opts.other_option)
                 bldSysInfo.check_dsp_flag = verify_args('\Acheck_dsp\Z', opts.other_option)
           
           elif defSysInfo.default_others:             
                 bldSysInfo.all_flag = verify_args('\Aall\Z', defSysInfo.default_others.split(','))
                 bldSysInfo.clean_flag = verify_args('\Aclean\Z', defSysInfo.default_others.split(','))             
                    
           else:

             if ((defSysInfo.default_testothers and opts.kloc) or opts.test):
                 #This is ONLY for CRM i.e., with -k option ONLY
                 #Also, enables only for opendsp packages as it needs 'hap/default_test.txt'
                 default_testarray = defSysInfo.default_testothers.split(',')
                 print 'other options from \'default_test.txt\': ', default_testarray
                 bldSysInfo.all_flag = verify_args('\Aall\Z', default_testarray)
                 bldSysInfo.clean_flag = verify_args('\Aclean\Z', default_testarray)
                 bldSysInfo.klocwork_flag = verify_args('\Aklocwork\Z', default_testarray)
                 bldSysInfo.cosim_flag = verify_args('\Acosim\Z', default_testarray)
                 bldSysInfo.cosim_run_flag = verify_args('\Acosim_run\Z', default_testarray)
                 bldSysInfo.oemroot_cosim_run_flag = verify_args('\Aoemroot_cosim_run\Z', default_testarray)
                 bldSysInfo.sim_flag = verify_args('\ASIM\Z', default_testarray)
                 bldSysInfo.sim_check = verify_args('\Achecksim\Z', default_testarray)
                 bldSysInfo.check_dsp_flag = verify_args('\Acheck_dsp\Z', default_testarray)
             else:    
                 bldSysInfo.all_flag = 1          
        
        opts_flags = []
        if m == 'flags':
           if opts.flags or defSysInfo.default_flags:
              bldSysInfo.flags_param = ''          
              if defSysInfo.default_flags:
                 opts_flags = defSysInfo.default_flags.split(',')
              if opts.flags:   
                 opts_flags = ''.join(opts.flags).split(',')
                 bldSysInfo.build_flags = 1
              for n in opts_flags:    
                  #print "flags options are:", n
                  if n == 'OEM_ROOT':
                     os.environ['OEM_ROOT'] = '1'
                     print 'OEM_ROOT is set for customization!!!'
                  if n == 'HAP_AUDIO_EXAMPLES':
                     os.environ['HAP_AUDIO_EXAMPLES'] ='1'
                     print 'HAP Audio examples are enabled!!!'
                  if n == 'HAP_VOICE_EXAMPLES':   
                     os.environ['HAP_VOICE_EXAMPLES'] ='1'
                     print 'HAP Voice examples are enabled!!!'                  
                  bldSysInfo.flags_param = ''.join([n, ',' , bldSysInfo.flags_param])          
              bldSysInfo.flags_param = bldSysInfo.flags_param.rstrip(',')
              
        
        if m == 'kloc':
           if opts.kloc:
              bldSysInfo.klocwork_flag = 1 
        
        if m == 'verbose':
           if opts.verbose:
              bldSysInfo.build_verbose_flag = 1
              bldSysInfo.opts_verbose = opts.verbose
              print 'build verbose: ', opts.verbose
           elif defSysInfo.default_verbose:          
              bldSysInfo.opts_verbose = defSysInfo.default_verbose
              print "Verbose default value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % defSysInfo.default_verbose
              
        if m == 'module':
           if opts.module:
              bldSysInfo.build_filter_flag = 1
              bldSysInfo.opts_module = opts.module
              print 'build filter: ', opts.module
           elif defSysInfo.default_module:
              bldSysInfo.opts_module = defSysInfo.default_module
              print "Module compilation value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % defSysInfo.default_module          

        if m == 'alias':
           if opts.alias:
              bldSysInfo.image_alias_flag = 1
              bldSysInfo.opts_alias = opts.alias
              print 'image alias: ', opts.alias
           elif defSysInfo.default_alias:          
              bldSysInfo.opts_alias = defSysInfo.default_alias
              print "Module Alias value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % defSysInfo.default_alias
                      
        if m == 'sconsargs':
           bldSysInfo.opts_sconsargs = ''
           if opts.sconsargs:
              bldSysInfo.build_sconsargs_flag = 1 
              bldSysInfo.opts_sconsargs = opts.sconsargs
              print 'build scons arguments: ', opts.sconsargs
           elif defSysInfo.default_sconsargs:
              bldSysInfo.opts_sconsargs = defSysInfo.default_sconsargs
              print "Scons arguments value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % defSysInfo.default_sconsargs          

        if m == 'userargs':
           bldSysInfo.opts_userargs = ''
           if opts.userargs:
              bldSysInfo.build_userargs_flag = 1 
              bldSysInfo.opts_userargs = opts.userargs
              print 'build custom user arguments: ', opts.userargs
           elif defSysInfo.default_userargs:
              bldSysInfo.opts_userargs = defSysInfo.default_userargs
              print "Custom user arguments value taken from file: 'adsp_proc/hap/default_pack.txt': %s" % defSysInfo.default_userargs 

        if m == 'toolversion':
           if opts.toolversion:
              print 'Hexagon Tool version set from command line: ', opts.toolversion
           else: # no toolversion specified, set to NULL, this will be set in set_chipset_target()
              opts.toolversion = ''
              print 'No Hexagon Tool version specified from command line, will use chipset default!'
    print "\n\n"



   
#=================================================================================
#=================================================================================
#                  Function definitions ends here
#=================================================================================
#=================================================================================

