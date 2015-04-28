#!/usr/bin/tclsh

# api 파라메터가 저장된 경로
set api_param_path "./"
# 출력 파일이 저장될 경로
set output_path "./param/"
######################################################################
#Recursive glob function
#procedure from http://paste.tclers.tk/1346
proc scan_dir {dirname pattern} {
    set out [list]
    foreach d [glob -type d -nocomplain -dir $dirname *] {
        set out [concat $out [scan_dir $d $pattern]]
    }
    concat $out [glob -type f -nocomplain -dir $dirname $pattern]
}
######################################################################

######################################################################
#Recursive glob function for dir only
proc scan_dir_only {dirname} {
    set out [list]
    foreach d [glob -type d -nocomplain -dir $dirname *] {
        set out [concat $out [scan_dir_only $d]]
    }
    concat $out [glob -type d -nocomplain -dir $dirname *]
}
######################################################################
######################################################################
#File 내용 바꿔치기 하는 함수...
package require fileutil
proc fileContentsReplace_xml {contents} {
    set lastindex 0
    set retval $contents
    while 1 {
        set index [string first ".xml" $retval $lastindex]
        if {$index == -1} break
        set lastindex 4
        set retval [string replace $retval $index [ expr $lastindex + 2 ] ".c" ]
    }
}
######################################################################
# 테이블 난독화를 한다.
puts "LGSE API 파라메터 XML unwrapping을 합니다..."
#프로젝트 파일 목록을 얻는다.
set filelist [scan_dir $api_param_path *.{xml}]
puts "API unwrapping을 시작합니다..."
foreach each_file_name $filelist {
    #파일이 저장될 경로명을 만든다. 앞부분의 경로를 바꿔치기한다.
    set output [string map "$api_param_path $output_path" $each_file_name]
    set output [string map ".xml .c" $output]
    puts "$output"

    set fp_in [open $each_file_name]
    set fp_out [open $output "w"]

    # set in_read [read $fp_in]
    # set in_list [split $in_read]
    set in_list [read $fp_in]


    set count 0
    set writetag 0
    set inittag 0
    foreach each_token $in_list {
        if { [string equal -nocase $each_token "<INIT>"] == 1 } {
            puts $fp_out "// INIT"
            incr inittag
            continue
        }

        if { [string equal -nocase $each_token "<VAR>"] == 1 } {
            if { $inittag == 1 } {
                puts $fp_out ""
                if { $count != 0 } {
                    puts $fp_out ""
                }
            }
            set count 0
            puts $fp_out "// VARIABLE"
            continue
        }

        if { [string equal -nocase [string range $each_token end-7 end] "</value>"] == 1 } {
            set tempstr [string range $each_token end-17 end-8]
            if { [string equal -nocase -length 2 $tempstr "0x"] == 1 } {
                puts -nonewline $fp_out "$tempstr, "
                incr count
                if { $count == 5 } {
                    puts $fp_out ""
                    set count 0
                }
            }

        }
    }
    if { $count != 0 } {
        puts $fp_out ""
    }


    close $fp_in
    close $fp_out



}
puts "unwrapping이 완료되었습니다."
