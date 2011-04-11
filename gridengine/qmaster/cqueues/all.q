# Version: 6.2u5
# 
# DO NOT MODIFY THIS FILE MANUALLY!
# 
qname                 all.q
hostlist              @allhosts
seq_no                0
load_thresholds       np_load_avg=1.75
suspend_thresholds    NONE
nsuspend              1
suspend_interval      00:05:00
priority              0
min_cpu_interval      00:05:00
processors            UNDEFINED
qtype                 BATCH INTERACTIVE
ckpt_list             NONE
pe_list               make mpich mpi orte
rerun                 FALSE
slots                 1,[compute-0-0.local=4],[dell-0-0.local=4],[dell-0-13.local=4],[dell-0-12.local=4],[dell-0-4.local=4],[dell-0-5.local=4],[dell-0-1.local=4],[dell-0-6.local=4],[dell-0-2.local=4],[dell-0-3.local=4],[dell-0-9.local=4],[dell-0-8.local=4],[dell-0-10.local=4],[dell-0-7.local=4],[dell-0-11.local=4],[compute-1-0.local=4],[compute-1-1.local=4],[compute-1-2.local=4],[compute-1-3.local=4],[compute-1-4.local=4],[compute-1-5.local=4],[compute-1-6.local=4],[compute-1-7.local=4],[compute-1-8.local=4],[compute-1-9.local=4],[compute-1-10.local=4],[compute-1-11.local=4],[compute-1-12.local=4],[compute-1-13.local=4],[compute-0-1.local=4],[compute-0-2.local=4],[compute-0-3.local=4],[compute-0-4.local=4]
tmpdir                /tmp
shell                 /bin/csh
prolog                NONE
epilog                NONE
shell_start_mode      posix_compliant
starter_method        NONE
suspend_method        NONE
resume_method         NONE
terminate_method      NONE
notify                00:00:60
owner_list            NONE
user_lists            NONE
xuser_lists           NONE
subordinate_list      NONE
complex_values        gaussquad=1
projects              NONE
xprojects             NONE
calendar              NONE
initial_state         default
s_rt                  INFINITY
h_rt                  INFINITY
s_cpu                 INFINITY
h_cpu                 INFINITY
s_fsize               INFINITY
h_fsize               INFINITY
s_data                INFINITY
h_data                INFINITY
s_stack               INFINITY
h_stack               INFINITY
s_core                INFINITY
h_core                INFINITY
s_rss                 INFINITY
h_rss                 INFINITY
s_vmem                INFINITY
h_vmem                INFINITY
