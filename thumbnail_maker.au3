#include <Array.au3>
#include <Date.au3>
#include <AutoItConstants.au3>

$input_file = 'enter filename'
$output_width  = 240	;320x240 - 240x135 - ?
$output_height = 135
const $info = 'info.ini'


;video data
$command = 'ffprobe -v error -show_format -show_streams ' & $input_file
runwait(@ComSpec & ' /c ' & $command & ' > info.ini', '', @SW_HIDE)
$ini_width  	= IniRead($info, 'stream', 'width', null)			; horizontal resolution	>	out_resolution
$ini_height 	= IniRead($info, 'stream', 'height', null)			; vertical resolution	>	^
$ini_duration	= IniRead($info, 'stream', 'duration', null)			; time in seconds	>	out_duration
$ini_fps		= IniRead($info, 'stream', 'avg_frame_rate', null)	; average frame rate	>	out_fps
$ini_name		= IniRead($info, 'format', 'filename', null)		; filename		>	ini_name
$ini_size		= IniRead($info, 'format', 'size', null)		; filesize in bytes	>	out_size
$ini_date		= FileGetTime($input_file, 0)				; last modified		>	out_date


;format time
$out_duration = timestamp($ini_duration)
func timestamp($seconds)
   local $time[3]
   _TicksToTime(int($seconds) * 1000, $time[0], $time[1], $time[2])
   if stringlen($time[0]) = 1 then $time[0] = '0' & $time[0]
   if stringlen($time[1]) = 1 then $time[1] = '0' & $time[1]
   if stringlen($time[2]) = 1 then $time[2] = '0' & $time[2]
   return $time[0] & ':' & $time[1] & ':' & $time[2]
   ;msgbox(1,'duration', $out_duration)
endfunc


;format date
local $month[12] = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
$out_date = $month[$ini_date[1] - 1] & ' ' & $ini_date[2] & ', ' & $ini_date[0] & ', ' & $ini_date[3] & ':' & $ini_date[4] & ':' & $ini_date[5]
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
;text labels
$header_font 	  = 'Arial'
$header_font_size = 12
$header_file      = 'header1.png'
$header_text      = 'File name   '	& '\n' _
		& 'File size   '	& '\n' _
		& 'Resolution  '	& '\n' _
		& 'Duration    '	;& '\n' _
;		& ' fps        : '	& '\n' _
;		& ' modified   : '
$command = 'convert -background black -fill white -font ' & $header_font & ' -pointsize ' & $header_font_size & ' label:"' & $header_text & '" ' & $header_file
clipput($command)
runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)
;text data
$header_file      = 'header2.png'
$header_text      = ':  ' & $ini_name		& '\n' _
		& ':  ' & $out_size & $out_size_meta	& '\n' _
		& ':  ' & $out_resolution	& '\n' _
		& ':  ' & $out_duration		;& '\n' _
;		& ':  ' & $out_fps		& '\n' _
;		& ':  ' & $out_date
$command = 'convert -background black -fill white -font ' & $header_font & ' -pointsize ' & $header_font_size & ' label:"' & $header_text & '" ' & $header_file
clipput($command)
runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)
;combine the label and data and make border around it
msgbox(1,'','pause')
$command = 'convert header1.png header2.png +append header.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
$command = 'convert header.png -bordercolor black -border 4x4 header.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)



;create the 9 snapshots of the video
for $i = 0  to 8
   ;get snapshot
   $time = int($ini_duration * ($i / 8))
   $output_file = $i + 1 & '.png'
   $command = 'ffmpeg -ss ' & $time & ' -i ' & $input_file & ' -s ' & $output_width & 'x' & $output_height & ' -frames:v 1 ' & $output_file
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   ;add border around snapshot
   $command = 'convert ' & $output_file & ' -bordercolor black -border 1x1 ' & $output_file
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;add timestamp to bottom right
   $time_watermark = timestamp($time)
   $command = 'convert ' & $output_file & ' -gravity southeast -stroke black -pointsize 14 -strokewidth 2 -annotate 0 ' & $time_watermark & ' -stroke none -pointsize 14 -fill white -annotate 0 ' & $time_watermark & ' ' & $output_file
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
next


;combine the snapshots together
$command = 'convert 1.png 2.png 3.png +append a.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
$command = 'convert 4.png 5.png 6.png +append b.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
$command = 'convert 7.png 8.png 9.png +append c.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
$command = 'convert a.png b.png c.png -append mosaic.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)


;combine header and thumbnails
$output_file = 'result.jpg'
$command = 'convert header.png mosaic.png -append result.jpg'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)


;cleanup all the garbage
FileDelete("1.png")
FileDelete("2.png")
FileDelete("3.png")
FileDelete("4.png")
FileDelete("5.png")
FileDelete("6.png")
FileDelete("7.png")
FileDelete("8.png")
FileDelete("9.png")
FileDelete("a.png")
FileDelete("b.png")
FileDelete("c.png")
FileDelete("mosaic.png")
FileDelete("header.png")
FileDelete("header1.png")
FileDelete("header2.png")
FileDelete("info.ini")
exit
