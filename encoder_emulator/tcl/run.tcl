config_webtalk -user off
config_webtalk -install off

if {![file isdirectory sim]} {
    file mkdir sim
}

exec xelab top_tb glbl \
    -prj ./main.prj \
    -debug typical \
    -s top_sim \
    -L unisims_ver -L unimacro_ver -L secureip -L xpm \
    -relax \
    -nolog
exec xsim top_sim \
    -gui \
    -nolog \
    -view ./tcl/wave.wcfg \
    -wdb ./sim/top_sim.wdb

exit