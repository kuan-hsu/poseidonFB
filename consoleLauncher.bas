#ifdef __FB_WIN32__
	#include once "crt/stdlib.bi"
	'#include once "win/shellapi.bi"
	#include once "windows.bi"

	#inclib "shell32"
#endif

dim as string	exeName, args

/'
command(1) = ID
command(2) = consoleX
command(3) = consoleY
command(4) = consoleW
command(5) = consoleH
command(6) = exeName
'/

cls

if( __fb_argc__ >= 6 ) then
	exeName = command(6)
	for i as integer = 7 to __fb_argc__
		args +=  ( " " + command(i) )
	next
	
	dim as string _id = command(1), _x = command(2), _y = command(3), _w = command(4), _h = command(5)
	
	dim as integer ID = valint( _id )
	dim as integer X = valint( _x )
	dim as integer Y = valint( _y )
	dim as integer W = valint( _w )
	dim as integer H = valint( _h )
	
	#ifdef __FB_WIN32__
	
		if( W <= 0 OR H <=0 ) then
			SetWindowPos( GetConsoleWindow, HWND_TOP, X, Y, 0, 0, SWP_NOSIZE )
		else
			SetWindowPos( GetConsoleWindow, HWND_TOP, X, Y, W, H, SWP_SHOWWINDOW )
		end if
		
	#else
	
		if( X < 0 ) then _x = "-1"
		if( Y < 0 ) then _y = "-1"
		if( W <= 0 ) then
			_w = "-1"
			_h = "-1"
		end if
		if( H <= 0 ) then
			_w = "-1"
			_h = "-1"
		end if

		'if( id > 0 ) then exec( "wmctrl", "-r poseidonFB_terminal -t " + _id )
		exec( "wmctrl", "-r poseidon_terminal -e 0," + _x + "," + _y + "," + _w + "," + _h )
		
	#endif
	
	dim as integer result = exec( exeName, trim( args ) )
	if result = -1 then print "error running="; exeName
else
	print "error Args aren't enough!"
end if


#ifdef __FB_WIN32__
	system_( "pause" )
#else
	print( "Press any Key to continue...")
	getkey
#endif

end