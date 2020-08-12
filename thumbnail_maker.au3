#include <Array.au3>
#include <Date.au3>
#include <AutoItConstants.au3>

$input_file = 'filename_here'
$output_width  = 320
$output_height = 240
const $info = 'info.ini'
 

;metadata
$command = 'ffprobe -v error -show_format -show_streams ' & $input_file
runwait(@ComSpec & ' /c ' & $command & ' > info.ini', '', @SW_HIDE)
$ini_width  	= IniRead($info, 'stream', 'width', null)			; horizontal resolution	>	out_resolution
$ini_height 	= IniRead($info, 'stream', 'height', null)			; vertical resolution	>	^
$ini_duration	= IniRead($info, 'stream', 'duration', null)		; time in seconds		>	out_duration
$ini_fps		= IniRead($info, 'stream', 'avg_frame_rate', null)	; average frame rate	>	out_fps
$ini_name		= IniRead($info, 'format', 'filename', null)		; filename				>	...
$ini_size		= IniRead($info, 'format', 'size', null)			; filesize in bytes		>	out_size
$ini_date		= FileGetTime($input_file, 0)						; last modified			>	out_date


;format time
local $time[3]
_TicksToTime(int($ini_duration) * 1000, $time[0], $time[1], $time[2])
if stringlen($time[0]) = 1 then $time[0] = '0' & $time[0]
if stringlen($time[1]) = 1 then $time[1] = '0' & $time[1]
if stringlen($time[2]) = 1 then $time[2] = '0' & $time[2]
$out_duration = $time[0] & ':' & $time[1] & ':' & $time[2]
;msgbox(1,'duration', $out_duration)

 
;format date
local $date[6] = $ini_date
switch int($ini_date[1]);month
   case 1
	  $date[1] = 'Jan'
   case 2
	  $date[1] = 'Feb'
   case 3
	  $date[1] = 'Mar'
   case 4
	  $date[1] = 'Apr'
   case 5
	  $date[1] = 'May'
   case 6
	  $date[1] = 'Jun'
   case 7
	  $date[1] = 'Jul'
   case 8
	  $date[1] = 'Aug'
   case 9
	  $date[1] = 'Sep'
   case 10
	  $date[1] = 'Oct'
   case 11
	  $date[1] = 'Nov'
   case 12
	  $date[1] = 'Dec'
endswitch
$out_date = $date[1] & ' ' & $date[2] & ', ' & $date[0] & ', ' & $date[3] & ':' & $date[4] & ':' & $date[5]
;msgbox(1,'last modified', $out_date)


;format file size
select
   case $ini_size >= 1024^3	;gigabytes
	  $out_size = $ini_size / 1024^3
	  $out_size_meta = ' GB'
   case $ini_size >= 1024^2	;megabytes
	  $out_size = $ini_size / 1024^2
	  $out_size_meta = ' MB'
   case $ini_size >= 1024	;kilobytes
	  $out_size = $ini_size / 1024
	  $out_size_meta = ' KB'
   case else   ;  <  1024	bytes
	  $out_size = $ini_size
	  $out_size_meta = ' B'
endselect
$out_size = stringformat("%.2f", $out_size)
;msgbox(1,'file size', $out_size & ' ' & $out_size_meta)


;format dimension
$out_resolution = $ini_width & 'x' & $ini_height


;format fps
$out_fps = StringSplit($ini_fps, '/', 2)
$out_fps = $out_fps[0] / $out_fps[1]
$out_fps = stringformat("%.2f", $out_fps)


;create metadata header using imagemagick
$header_font 	  = 'courier-new'
$header_font_size = 16
$header_file      = 'header.png'
$header_text      = 'filename   : ' & $ini_name 			& '\n' _
				  & 'filesize   : ' & $out_size & $out_size_meta	& '\n' _
				  & 'resolution : ' & $out_resolution 	& '\n' _
				  & 'duration   : ' & $out_duration		& '\n' _
			      & 'fps        : ' & $out_fps 			& '\n' _
			      & 'modified   : ' & $out_date
$command = 'convert -background black -fill white -font ' & $header_font & ' -pointsize ' & $header_font_size & ' label:"' & $header_text & '" ' & $header_file
clipput($command)
runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)


;create the 9 thumbnails of the video
for $i = 0  to 8
   $time = int($ini_duration * ($i / 8))
   $output_file = $i + 1 & '.jpg'
   $command = 'ffmpeg -ss ' & $time & ' -i ' & $input_file & ' -s ' & $output_width & 'x' & $output_height & ' -frames:v 1 ' & $output_file
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
next


;combine the thumbnails together
$command = 'convert 1.jpg 2.jpg 3.jpg +append a.jpg'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

$command = 'convert 4.jpg 5.jpg 6.jpg +append b.jpg'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

$command = 'convert 7.jpg 8.jpg 9.jpg +append c.jpg'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

$command = 'convert a.jpg b.jpg c.jpg -append mosaic.jpg'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)


;combine header and thumbnails
$output_file = 'result.jpg'
$command = 'convert header.png mosaic.jpg -append result.jpg'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)


FileDelete("1.jpg")
FileDelete("2.jpg")
FileDelete("3.jpg")
FileDelete("4.jpg")
FileDelete("5.jpg")
FileDelete("6.jpg")
FileDelete("7.jpg")
FileDelete("8.jpg")
FileDelete("9.jpg")
FileDelete("a.jpg")
FileDelete("b.jpg")
FileDelete("c.jpg")
FileDelete("mosaic.jpg")
FileDelete("header.png")
FileDelete("info.ini")
exit
