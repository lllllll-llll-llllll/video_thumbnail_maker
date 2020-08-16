#include <Array.au3>
#include <Date.au3>
#include <AutoItConstants.au3>


$input_file = 'video_filename_here'
const $info = 'info.ini'

$config_output      = 'result.png'
$config_columns     = 5
$config_rows        = 3
$config_cell_size   = 135
$config_height      = null
$config_width       = null
$config_border      = 2
$config_font        = 'arial'
$config_font_Size   = 12


;metadata
$command = 'ffprobe -v error -show_format -show_streams ' & $input_file
runwait(@ComSpec & ' /c ' & $command & ' > info.ini', '', @SW_HIDE)
$ini_ratio      = 	 IniRead($info, 'stream', 'display_aspect_ratio', null)	; aspect ratio?		>	...
$ini_width  	= number(IniRead($info, 'stream', 'width', null))		; horizontal resolution	>	out_resolution
$ini_height 	= number(IniRead($info, 'stream', 'height', null))		; vertical resolution	>	^
$ini_duration	= number(IniRead($info, 'stream', 'duration', null))		; time in seconds	>	out_duration
$ini_fps	= 	 IniRead($info, 'stream', 'avg_frame_rate', null)	; average frame rate	>	out_fps
$ini_name	= 	 IniRead($info, 'format', 'filename', null)		; filename		>	...
$ini_size	= number(IniRead($info, 'format', 'size', null))		; filesize in bytes	>	out_size
$ini_date	= FileGetTime($input_file, 0)					; last modified		>	out_date


;format time
$out_duration = timestamp($ini_duration)
func timestamp($seconds)
   local $time[3]
   _TicksToTime(int($seconds) * 1000, $time[0], $time[1], $time[2])
   if $time[0] < 10 then $time[0] = '0' & $time[0]
   if $time[1] < 10 then $time[1] = '0' & $time[1]
   if $time[2] < 10 then $time[2] = '0' & $time[2]
   return $time[0] & ':' & $time[1] & ':' & $time[2]
endfunc


;format date
local $month[12] = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
$out_date = $month[$ini_date[1] - 1] & ' ' & $ini_date[2] & ', ' & $ini_date[0] & ', ' & $ini_date[3] & ':' & $ini_date[4] & ':' & $ini_date[5]


;format file size
select
   case $ini_size >= 1024^3	;gigabytes
	  $out_size = ($ini_size / 1024^3)	& ' GB'
   case $ini_size >= 1024^2	;megabytes
	  $out_size = ($ini_size / 1024^2)	& ' MB'
   case $ini_size >= 1024	;kilobytes
	  $out_size = ($ini_size / 1024)	& ' KB'
   case else   ;  <  1024	bytes
	  $out_size = $ini_size				& ' B'
endselect
$out_size = stringformat("%.2f", $out_size)


;format dimension
$out_resolution = $ini_width & 'x' & $ini_height


;format fps
$out_fps = StringSplit($ini_fps, '/', 2)
$out_fps = $out_fps[0] / $out_fps[1]
$out_fps = stringformat("%.2f", $out_fps)


;create metadata header using imagemagick
$header_text	= 'File name '		& '\n' _
		& 'File size   '	& '\n' _
		& 'Resolution  '	& '\n' _
		& 'Duration    '
$command = 'convert -background black -fill white -font ' & $config_font & ' -pointsize ' & $config_font_size & ' label:"' & $header_text & '" header1.png'
runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)
$header_text	= ':  ' & $ini_name		& '\n' _
		& ':  ' & $out_size		& '\n' _
		& ':  ' & $out_resolution	& '\n' _
		& ':  ' & $out_duration
$command = 'convert -background black -fill white -font ' & $config_font & ' -pointsize ' & $config_font_size & ' label:"' & $header_text & '" header2.png'
runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)


;create the 9 thumbnails of the video
$config_height = ($ini_width > $ini_height) ? $config_cell_size : int($ini_height / ($ini_width / $config_cell_size))
$config_width  = ($ini_width > $ini_height) ? int($ini_width / ($ini_height / $config_cell_size)) : $config_cell_size
for $i = 0  to (($config_rows * $config_columns) - 1)
   $time = int($ini_duration * ($i / (($config_rows * $config_columns) - 1)))
   $thumbs_filename = $i + 1 & '.png'
   $command = 'ffmpeg -ss ' & $time & ' -i ' & $input_file & ' -s ' & $config_width & 'x' & $config_height & ' -frames:v 1 ' & $thumbs_filename
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   $time_watermark = timestamp($time)
   $command = 'convert ' & $thumbs_filename & ' -gravity southeast -stroke black -pointsize 14 -strokewidth 2 -annotate 0 ' & $time_watermark & ' -stroke none -pointsize 14 -fill white -annotate 0 ' & $time_watermark & ' ' & $thumbs_filename
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
next


;combine everything together
local $montage[$config_rows * $config_columns]
for $i = 1 to ubound($montage)
   $montage[$i - 1] = $i & '.png'
next
$command = 'montage ' & _ArrayToString($montage, ' ') & ' -geometry +2+2  -background black -tile ' & $config_columns & 'x' & $config_rows & ' mosaic.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

$command = 'convert header1.png header2.png +append -bordercolor black -border 4x4 header.png mosaic.png -append ' & $config_output
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)


for $file in $montage
   filedelete($file)
next
FileDelete("header1.png")
FileDelete("header2.png")
FileDelete("mosaic.png")
FileDelete("info.ini")
exit
