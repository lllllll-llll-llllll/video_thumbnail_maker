#include <Array.au3>
#include <Date.au3>
#include <AutoItConstants.au3>

   $config_input	= null
   $config_output	= null
   $config_columns	= null
   $config_rows		= null
   $config_size		= null
   $config_border	= null
   $config_font		= null
   $config_fontsize	= null
   $config_header	= null
   $config_timestamp	= null

for $i = 1 to $cmdline[0]
   $parameter = stringsplit($cmdline[$i], '=')
   if $parameter[0] = 2 then
	  $key   = $parameter[1]
	  $value = $parameter[2]

	  select
	  case ($key = 'input') or ($key = 'in') or ($key = 'i')
		 $config_input = $value

	  case ($key = 'output') or ($key = 'out') or ($key = 'o')
		 $config_output = $value

	  case ($key = 'columns') or ($key = 'column') or ($key = 'cols') or ($key = 'col') or ($key = 'c') or ($key = 'width')
		 $temp = abs(int($value))
		 if ($temp <> 0) then $config_columns = $temp

	  case ($key = 'rows') or ($key = 'row') or ($key = 'r') or ($key = 'height')  or ($key = 'high')
		 $temp = abs(int($value))
		 if ($temp <> 0) then $config_rows = $temp

	  case ($key = 'size') or ($key = 's')
		 $temp = abs(int($value))
		 if ($temp <> 0) then $config_size = $temp

	  case ($key = 'border') or ($key = 'b')
		 $config_border = abs(int($value))

	  case ($key = 'font') or ($key = 'f')
		 $command = 'convert -list font'
		 runwait(@ComSpec & ' /c ' & $command & ' > fonts.txt', '', @SW_HIDE)
		 local $fonts[0]
		 if fileexists('fonts.txt') then
			$text = FileReadToArray('fonts.txt')
			for $line in $text
			   if stringleft($line, 8) = '  Font: ' then
				  $trim = $line
				  $trim = stringtrimleft($trim, 8)
				  if $trim = $value then
					 $config_font = $value
					 exitloop
				  endif
			   endif
			next
			filedelete('fonts.txt')
		 endif

	  case ($key = 'fontsize') or ($key = 'fs')
		 $temp = abs(int($value))
		 if ($temp <> 0) then $config_fontsize = $temp

	  case ($key = 'header') or ($key = 'head') or ($key = 'h')
		 if $value <> 'none' then $config_header = stringsplit($value, ',', 2)


	  case ($key = 'timestamp') or ($key = 'time') or ($key = 'ts') or ($key = 't')
		 select
		 case ($value = 'north')			or ($value = 'n')
			$config_timestamp = 'north'
		 case ($value = 'northeast')		or ($value = 'ne')
			$config_timestamp = 'northeast'
		 case ($value = 'east')				or ($value = 'e')
			$config_timestamp = 'east'
		 case ($value = 'southeast')		or ($value = 'se')
			$config_timestamp = 'southeast'
		 case ($value = 'south')			or ($value = 's')
			$config_timestamp = 'south'
		 case ($value = 'southwest')		or ($value = 'sw')
			$config_timestamp = 'southwest'
		 case ($value = 'west')				or ($value = 'w')
			$config_timestamp = 'west'
		 case ($value = 'northwest')		or ($value = 'nw')
			$config_timestamp = 'northwest'
		 case ($value = 'none')
			$config_timestamp = 'none'
		 endselect

	  endselect
   endif
next


;defaults if no parameter is supplied
if $config_input 	= null then abort()
if $config_output 	= null then $config_output	= 'output.png'
if $config_columns 	= null then $config_columns	= 4
if $config_rows 	= null then $config_rows	= 3
if $config_size 	= null then $config_size	= 135
if $config_border	= null then $config_border	= 1
if $config_font 	= null then $config_font	= 'arial'
if $config_fontsize	= null then $config_fontsize	= 12
if $config_header 	= null then $config_header[4]	= ['name', 'size', 'resolution', 'duration']
if $config_timestamp	= null then $config_timestamp	= 'southeast'


;metadata
const $info = 'info.ini'
$command = 'ffprobe -v error -show_format -show_streams ' & $config_input
runwait(@ComSpec & ' /c ' & $command & ' > info.ini', '', @SW_HIDE)
if not fileexists('info.ini') then abort()
   $ini_ratio      = IniRead($info, 'stream', 'display_aspect_ratio', null)	; aspect ratio?	>	...
   $ini_width  	= number(IniRead($info, 'stream', 'width', null))		; horizontal resolution	>	out_resolution
   $ini_height 	= number(IniRead($info, 'stream', 'height', null))		; vertical resolution	>	^
   $ini_duration	= number(IniRead($info, 'stream', 'duration', null))	; time in seconds		>	out_duration
   $ini_fps		= IniRead($info, 'stream', 'avg_frame_rate', null)	; average frame rate	>	out_fps
   $ini_name		= IniRead($info, 'format', 'filename', null)		; filename				>	...
   $ini_size		= number(IniRead($info, 'format', 'size', null))	; filesize in bytes		>	out_size
   $ini_date		= FileGetTime($config_input, 0)				; last modified			>	out_date



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
	  $out_size = $ini_size			& ' B'
endselect
$out_size = stringformat("%.2f", $out_size)


;format dimension
$out_resolution = $ini_width & 'x' & $ini_height


;format fps
$out_fps = StringSplit($ini_fps, '/', 2)
$out_fps = $out_fps[0] / $out_fps[1]
$out_fps = stringformat("%.2f", $out_fps)


;create metadata header using imagemagick
local $header_text1 = ''
local $header_text2 = ''
if $config_header <> 'none' then
   for $item in $config_header
	  select
	  case ($item = 'name') or ($item = 'n')
		 $header_text1 &= 'File name   \n'
		 $header_text2 &= ':  ' & $ini_name	& '\n'
	  case ($item = 'size') or ($item = 's')
		 $header_text1 &= 'File size   \n'
		 $header_text2 &= ':  ' & $out_size	& '\n'
	  case ($item = 'resolution') or ($item = 'res') or ($item = 'r')
		 $header_text1 &= 'Resolution  \n'
		 $header_text2 &= ':  ' & $out_resolution& '\n'
	  case ($item = 'duration') or ($item = 'd') or ($item = 'length') or ($item = 'l') or ($item = 'time') or ($item = 't')
		 $header_text1 &= 'Duration    \n'
		 $header_text2 &= ':  ' & $out_duration	& '\n'
	  case ($item = 'fps') or ($item = 'f')
		 $header_text1 &= 'FPS         \n'
		 $header_text2 &= ':  ' & $out_fps	& '\n'
	  case ($item = 'audio') or ($item = 'a')
		 ;$header_text1 &= 'Audio       \n'
		 ;$header_text2 &= ':  ' & $ini_name	& '\n'
	  case ($item = 'video') or ($item = 'v')
		;$header_text1 &= 'Video       \n'
		 ;$header_text2 &= ':  ' & $ini_name	& '\n'
	  case ($item = 'comment') or ($item = 'c')
		 ;$header_text1 &= 'Comment     \n'
		 ;$header_text2 &= ':  ' & $ini_name	& '\n'
	  case ($item = 'date')
		 $header_text1 &= 'Date        \n'
		 $header_text2 &= ':  ' & $out_date	& '\n'
	  endselect
   next
   $header_text1 = StringTrimRight($header_text1, 2)
   $header_text2 = StringTrimRight($header_text2, 2)


   $command = 'convert -background black -fill white -font ' & $config_font & ' -pointsize ' & $config_fontsize & ' label:"' & $header_text1 & '" header1.png'
   runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)

   $command = 'convert -background black -fill white -font ' & $config_font & ' -pointsize ' & $config_fontsize & ' label:"' & $header_text2 & '" header2.png'
   runwait(@ComSpec & ' /c ' & $command & '', '', @SW_HIDE)
endif



;create the 9 thumbnails of the video
$config_height = ($ini_width > $ini_height) ? $config_size : int($ini_height / ($ini_width / $config_size))
$config_width  = ($ini_width > $ini_height) ? int($ini_width / ($ini_height / $config_size)) : $config_size
for $i = 0  to (($config_rows * $config_columns) - 1)
   $time = int($ini_duration * ($i / (($config_rows * $config_columns) - 1)))
   $thumbs_filename = $i + 1 & '.png'
   $command = 'ffmpeg -ss ' & $time & ' -i ' & $config_input & ' -s ' & $config_width & 'x' & $config_height & ' -frames:v 1 ' & $thumbs_filename
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   if $config_timestamp <> 'none' then
	  $time_watermark = timestamp($time)
	  $command = 'convert ' & $thumbs_filename & ' -gravity ' & $config_timestamp & ' -background black -extent ' & ($config_width + $config_border) & 'x' & ($config_height + $config_border) & ' -stroke black -pointsize 14 -strokewidth 2 -annotate 0 ' & $time_watermark & ' -stroke none -pointsize 14 -fill white -annotate 0 ' & $time_watermark & ' ' & $thumbs_filename
	  runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   endif
next


;combine everything together
local $montage[$config_rows * $config_columns]
for $i = 1 to ubound($montage)
   $montage[$i - 1] = $i & '.png'
next
;$command = 'montage ' & _ArrayToString($montage, ' ') & ' -geometry +' & ($config_border / 2) & '+' & ($config_border / 2) & ' -background black -tile ' & $config_columns & 'x' & $config_rows & ' mosaic.png'
$command = 'montage ' & _ArrayToString($montage, ' ') & ' -geometry +0+0 -tile ' & $config_columns & 'x' & $config_rows & ' mosaic.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

$command = 'convert mosaic.png -gravity southeast -background black  -splice '& $config_border & 'x' & $config_border & '  mosaic.png'
runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

if $config_header <> 'none' then
   $command = 'convert header1.png header2.png +append -bordercolor black -border 4x4 header.png mosaic.png -append ' & $config_output
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
endif

abort()
func abort()
   for $file in $montage
	if FileExists($file) then filedelete($file)
   next
   if FileExists("fonts.txt")		then FileDelete("fonts.txt")
   if FileExists("header1.png")		then FileDelete("header1.png")
   if FileExists("header2.png")		then FileDelete("header2.png")
   if FileExists("mosaic.png")		then FileDelete("mosaic.png")
   if FileExists("info.ini")		then FileDelete("info.ini")
exit
endfunc
exit





























