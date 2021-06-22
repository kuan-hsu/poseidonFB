'Arrays
declare sub Erase ( array as any , ... )
declare function Lbound ( array() as any, byval dimension as integer = 1 ) as integer
declare function Ubound ( array() as any, byval dimension as integer = 1 ) as integer

'Bit manipulation
#define Bit( value, bit_number ) (((value) and (Cast(TypeOf(value), 1) shl (bit_number))) <> 0)
#define Bitreset( value, bit_number ) ((value) and not (Cast(TypeOf(Value), 1) shl (bit_number)))
#define Bitset( value, bit_number ) ((value) or (Cast(TypeOf(Value), 1) shl (bit_number)))
#define Hibyte( expr ) ((Cast(Uinteger, expr) and &h0000FF00) shr 8)
#define Hiword( expr ) ((Cast(Uinteger, expr) and &hFFFF0000) shr 16)
#define Lobyte( expr ) (Cast(Uinteger, expr) and &h000000FF)
#define Loword( expr ) (Cast(Uinteger, expr) and &h0000FFFF)

'Console
declare sub Beep ( )
declare sub Cls ( byval mode as long = 1 )
declare function Color ( byval foreground as ulong , byval background as ulong ) as ulong
declare function Csrlin ( ) as integer
declare function Locate( row as long = 0, column as long = 0, state as long = -1, start as long = 0, stop as long = 0 ) as long
declare function Pos ( ) as long
declare function Pos ( byval dummy as long ) as long
declare function Screen ( byval row as long, byval column as long, byval colorflag as long = 0 ) as long

'Date and time
declare function Date ( ) as string
declare function Setdate ( byref newdate as const string ) as long
declare function Settime ( byref newtime as const string ) as long
declare function Time ( ) as string
declare function Timer ( ) as double

'Debug support
#define ASSERT(expression) if (expression) = 0 then : fb_Assert( __FILE__, __LINE__, __FUNCTION__, #expression ) : end if
#define ASSERTWARN(expression) if (expression) = 0 then : fb_AssertWarn( __FILE__, __LINE__, __FUNCTION__, #expression ) : end if
declare sub Stop ( byval retval as long = 0 )

'Error handling
declare function Erfn ( ) as zstring ptr
declare function Erl ( ) as integer
declare function Ermn ( ) as zstring ptr
declare sub Error ( errno as integer )

'Files
declare function Bload ( byref filename as const string, byval dest as any ptr = 0, byval pal as any ptr = 0 ) as long
declare function Bsave ( byref filename as const string, byval source as any ptr, byval size as ulong = 0, byval pal as any ptr = 0, byval bitsperpixel as long = 0 ) as long
declare function Eof ( byval filenum as long ) as long
declare function Freefile ( ) as long
declare function Loc ( byval filenum as long ) as longint
declare function Lof ( byval filenum as long ) as longint
declare sub Reset ( )
declare sub Reset ( byval streamno as long )
declare function Seek ( byval filenum as long ) as longint

'Graphics
declare function Flip ( byval frompage as long = -1, byval topage as long = -1 ) as long
declare sub ImageConvertRow ( byval src as any ptr, byval src_bpp as long, byval dst as any ptr, byval dst_bpp as long, byval width as long, byval isrgb as long = 1 )
declare function ImageCreate ( byval width as long, byval height as long, byval color as ulong = transparent_color ) as any ptr
declare function ImageCreate ( byval width as long, byval height as long, byval color as ulong = transparent_color, byval depth as long ) as any ptr
declare sub ImageDestroy ( byval image as any ptr )
declare function Imageinfo ( byval image as any ptr, byref width as integer = 0, byref height as integer = 0, byref bypp as integer = 0, byref pitch as integer = 0, byref pixdata as any ptr = 0, byref size as integer = 0 ) as long
declare function Pcopy ( byval source as long = -1, byval destination as long = -1 ) as long
declare function PMap ( byval coord as single, byval func as long ) as single
Declare Function PointCoord( ByVal func As Long ) As Single
#define RGB(r,g,b) ((culng(r) shl 16) or (culng(g) shl 8) or culng(b) or &hFF000000)
#define RGBA(r,g,b,a) ((CUlng(r) shl 16) or (CUlng(g) shl 8) or CUlng(b) or (CUlng(a) shl 24))
declare sub ScreenControl ( byval what as long, byref param1 as integer = 0, byref param2 as integer = 0, byref param3 as integer = 0, byref param4 as integer = 0 )
declare sub ScreenControl ( byval what as long, byref param as string = "" )
declare function Screencopy ( byval from_page as long = -1, byval to_page as long = -1 ) as long
declare function ScreenEvent ( byval event as any ptr = 0 ) as long
declare sub Screeninfo ( byref w as integer = 0, byref h as integer = 0, byref depth as integer = 0, byref bpp as integer = 0, byref pitch as integer = 0, byref rate as integer = 0, byref driver as string = "" )
declare function ScreenGLProc ( byref procname as const string ) as any ptr
declare function Screenlist ( byval depth as long = 0 ) as long
declare sub Screenlock ( )
declare function Screenptr ( ) as any ptr
declare function Screenres ( byval width as long, byval height as long, byval depth as long = 8, byval num_pages as long = 1, byval flags as long = 0, byval refresh_rate as long = 0 ) as long
declare sub Screenset ( byval work_page as long = -1, byval visible_page as long = -1 )
declare function Screensync ( ) as long
declare sub Screenunlock ( byval startline as long = -1, byval endline as long = -1 )

'Hardware access
declare function Inp ( byval port as ushort ) as integer
declare function Out ( byval port as ushort , byval data as ubyte ) as long
declare function Wait ( byval port as ushort, byval and_mask as long, byval xor_mask as long = 0 ) as long
declare function Lpos ( byval printer as long ) as long

'Math
declare function Abs ( byval number as integer ) as integer
declare function Abs ( byval number as uinteger ) as uinteger
declare function Abs ( byval number as double ) as double
declare function Acos ( byval number as double ) as double
declare function Asin ( byval number as double ) as double
declare function ATan2 ( byval y as double, byval x as double ) as double
declare function Atn ( byval number as double ) as double
declare function Cos ( byval angle as double ) as double
declare function Exp cdecl ( byval number as double ) as double
declare function Fix ( byval number as single ) as single
declare function Fix ( byval number as double ) as double
declare function Fix ( byval number as integer ) as integer
declare function Fix ( byval number as uinteger ) as uinteger
declare function Frac ( byval number as double ) as double
declare function Frac ( byval number as integer ) as integer
declare function Frac ( byval number as uinteger ) as uinteger
declare function Int ( byval number as single ) as single
declare function Int ( byval number as double ) as double
declare function Int ( byval number as integer ) as integer
declare function Int ( byval number as uinteger ) as uinteger
declare function Log cdecl ( byval number as double ) as double
declare sub Randomize ( byval seed as double = -1.0, byval algorithm as long = 0 )
declare function Rnd ( byval seed as single = 1.0 ) as double
declare function Sgn ( byval number as integer ) as integer
declare function Sgn ( byval number as longint ) as longint
declare function Sgn ( byval number as double ) as double
declare function Sin ( byval angle as double ) as double
declare function Sqr ( byval number as double ) as double
declare function Tan ( byval angle as double ) as double

'Memory
declare function Allocate cdecl ( byval count as uinteger ) as any ptr
declare function Callocate cdecl ( byval num_elements as uinteger, byval size as uinteger = 1 ) as any ptr
declare sub Clear cdecl ( byref dst as any, byval value as long = 0, byval bytes as uinteger )
declare sub Deallocate cdecl ( byval pointer as any ptr )
declare function fb_memcopy cdecl ( byref dst as any, byref src as any, byval bytes as uinteger ) as any ptr
declare function fb_memmove cdecl ( byref dst as any, byref src as any, byval bytes as uinteger ) as any ptr
declare function Fre ( byval value as long = 0 ) as uinteger
declare function Peek ( byval address as any ptr ) byref as ubyte
declare function Peek ( datatype, byval address as any ptr ) byref as datatype
declare sub Poke ( byval address as any ptr, byref value as ubyte )
declare sub Poke ( datatype, byval address as any ptr, byref value as datatype )
declare function Reallocate cdecl ( byval pointer as any ptr, byval count as uinteger ) as any ptr

'Miscellaneous
#define Offsetof(typename, fieldname) cint( @cast( typename ptr, 0 )->fieldname )
declare sub Swap ( byref a as any, byref b as any )

'Modularizing
declare sub Dylibfree ( byval library as any pointer )
declare function Dylibload ( byref filename as string ) as any Pointer
declare function Dylibsymbol ( byval library as any ptr, byref symbol as string ) as any ptr
declare function Dylibsymbol ( byval library as any ptr, byval symbol as short ) as any ptr

'Multithreading
declare sub Condbroadcast ( byval handle as any ptr )
declare function Condcreate ( ) as any ptr
declare sub Conddestroy ( byval handle as any ptr )
declare sub Condsignal ( byval handle as any ptr )
declare sub Condwait ( byval handle as any ptr, byval mutex as any ptr )
declare function Mutexcreate ( ) as any ptr
declare sub Mutexdestroy ( byval id as any ptr )
declare sub Mutexlock ( byval id as any ptr )
declare sub Mutexunlock ( byval id as any ptr )
Declare Function Threadcreate ( ByVal procptr As Sub ( ByVal userdata As Any Ptr ), ByVal param As Any Ptr = 0, ByVal stack_size As Integer = 0 ) As Any Ptr
Declare Sub ThreadWait ( Byval id As Any Ptr )

'OS / shell
declare function Chain ( byref program as const string ) as long
declare function Chdir ( byref path as const string ) as long
declare function Command ( byval index as long = -1 ) as string
declare function Curdir ( ) as string
declare function Dir ( byref item_spec as const string, byval attrib_mask as integer = fbNormal, byref out_attrib as integer ) as string
declare function Dir ( byref item_spec as const string, byval attrib_mask as integer = fbNormal, byval p_out_attrib as integer ptr = 0 ) as string
declare function Dir ( byval attrib_mask as integer = fbNormal, byref out_attrib as integer ) as string
declare function Dir ( byval attrib_mask as integer = fbNormal, byval p_out_attrib as integer ptr = 0 ) as string
declare sub End ( byval retval as long = 0 )
declare function Environ ( byref varname as const string ) as string
declare function Exec ( byref program as const string, byref arguments as const string ) as long
declare function Exepath ( ) as string
declare function Kill ( byref filename as const string ) as long
declare function Mkdir ( byref folder as const string ) as long
declare function Name( byref oldname as const string, byref newname as const string ) as long
declare function Rmdir ( byref folder as const string ) as long
declare function Run ( byref program as const string, byref arguments as const string = "" ) as long
declare function Setenviron ( byref varexpression as string ) as long
declare function Shell ( byref command as const string ) as long
declare sub System ( byval retval as long = 0 )
declare sub Windowtitle ( byref title as const string )

'Pointers
declare function Sadd ( byref str as string ) as Zstring ptr
declare function Sadd ( byref str as Wstring ) as Wstring ptr
declare function Sadd ( byref str as Zstring ) as Zstring ptr


declare function Instr ( byref str as const string, [ Any ] byref substring as const string ) as integer
declare function Instr ( byref str as const wstring, [ Any ] byref substring as const wstring ) as integer
declare function Instr ( byval start as integer, byref str as const string, [ Any ] byref substring as const string ) as integer
declare function Instr ( byval start as integer, byref str as const wstring, [ Any ] byref substring as const wstring ) as integer

'String functions
declare function Instr ( byref str as const string, [ Any ] byref substring as const string ) as integer
declare function Instr ( byref str as const wstring, [ Any ] byref substring as const wstring ) as integer
declare function Instr ( byval start as integer, byref str as const string, [ Any ] byref substring as const string ) as integer
declare function Instr ( byval start as integer, byref str as const wstring, [ Any ] byref substring as const wstring ) as integer
declare function Instrrev ( byref str as const string, [ Any ] byref substring as const string, byval start as integer = -1 ) as integer
declare function Instrrev ( byref str as const wstring, [ Any ] byref substring as const wstring, byval start as integer = -1 ) as integer
declare function Lcase ( byref str as const string, byval mode as long = 0 ) as string
declare function Lcase ( byref str as const wstring, byval mode as long = 0 ) as wstring
declare function Left ( byref str as const string, byval n as integer ) as string
declare function Left ( byref str as const wstring, byval n as integer ) as wstring
declare function Len ( byref expression as string ) as integer
declare function Len ( byref expression as zstring ) as integer
declare function Len ( byref expression as wstring ) as integer
declare function Len ( datatype ) as integer
declare sub Lset ( byref dst as string, byref src as const string )
declare sub Lset ( byval dst as wstring ptr, byval src as const wstring ptr )
declare sub Lset ( byref dst as string, byref src as const string )
declare sub Lset ( byval dst as wstring ptr, byval src as const wstring ptr )
declare sub Mid ( byref text as string, byval start as integer, byval length as integer, byref expression as const string )
declare sub Mid ( byval text as wstring ptr, byval start as integer, byval length as integer, byval expression as const wstring ptr )
declare function Mid ( byref str as const string, byval start as integer ) as string
declare function Mid ( byval str as const wstring ptr, byval start as integer ) as wstring
declare function Mid ( byref str as const string, byval start as integer, byval n as integer ) as string
declare function Mid ( byval str as const wstring ptr, byval start as integer, byval n as integer ) as wstring
declare function Right ( byref str as const string, byval n as integer ) as string
declare function Right ( byref str as const wstring, byval n as integer ) as wstring
declare sub Rset ( byref dst as string, byref src as const string )
declare sub Rset ( byval dst as wstring ptr, byval src as const wstring ptr )
declare function Rtrim ( byref str as const string, [ Any ] byref trimset as const string = " " ) as string
declare function Rtrim ( byref str as const wstring, [ Any ] byref trimset as const wstring = Wstr(" ") ) as wstring
declare function Space( byval count as integer ) as string
declare function String ( byval count as integer, byval ch_code as long ) as string
declare function String ( byval count as integer, byref ch as const string ) as string
declare function Trim ( byref str as const string, [ Any ] byref trimset as const string = " " ) as string
declare function Trim ( byref str as const wstring, [ Any ] byref trimset as const wstring = Wstr(" ") ) as wstring
declare function Ucase ( byref str as const string, byval mode as long = 0 ) as string
declare function Ucase ( byref str as const wstring, byval mode as long = 0 ) as wstring
declare function Wspace( byval count as integer ) as wstring
declare function Wstring ( byval count as integer, byval ch_code as long ) as wstring
declare function Wstring ( byval count as integer, byref ch as const wstring ) as wstring

'String and number conversion
declare function Bin ( byval number as ubyte ) as string
declare function Bin ( byval number as ushort ) as string
declare function Bin ( byval number as ulong ) as string
declare function Bin ( byval number as ulongint ) as string
declare function Bin ( byval number as const any ptr ) as string
declare function Bin ( byval number as ubyte, byval digits as long ) as string
declare function Bin ( byval number as ushort, byval digits as long ) as string
declare function Bin ( byval number as ulong, byval digits as long ) as string
declare function Bin ( byval number as ulongint, byval digits as long ) as string
declare function Bin ( byval number as const any ptr, byval digits as long ) as string
declare function Bin ( byval number as ubyte ) as string
declare function Bin ( byval number as ushort ) as string
declare function Bin ( byval number as ulong ) as string
declare function Bin ( byval number as ulongint ) as string
declare function Bin ( byval number as const any ptr ) as string
declare function Bin ( byval number as ubyte, byval digits as long ) as string
declare function Bin ( byval number as ushort, byval digits as long ) as string
declare function Bin ( byval number as ulong, byval digits as long ) as string
declare function Bin ( byval number as ulongint, byval digits as long ) as string
declare function Bin ( byval number as const any ptr, byval digits as long ) as string
declare function Chr ( byval ch as integer , ... ) as string
declare function Cvd ( byval l as longint ) as double
declare function Cvd ( byref str as const string ) as double
declare function Cvl ( byval sng as single ) as long
declare function Cvl ( byref str as const string ) as long
declare function Cvlongint ( byval dbl as double ) as longint
declare function Cvlongint ( byref str as const string ) as longint
declare function Cvs ( byval i as integer ) as single
declare function Cvs ( byref str as const string ) as single
declare function Cvshort ( byref str as const string ) as Short
declare function Hex ( byval number as ubyte ) as string
declare function Hex ( byval number as ushort ) as string
declare function Hex ( byval number as ulong ) as string
declare function Hex ( byval number as ulongint ) as string
declare function Hex ( byval number as const any ptr ) as string
declare function Hex ( byval number as ubyte, byval digits as long ) as string
declare function Hex ( byval number as ushort, byval digits as long ) as string
declare function Hex ( byval number as ulong, byval digits as long ) as string
declare function Hex ( byval number as ulongint, byval digits as long ) as string
declare function Hex ( byval number as const any ptr, byval digits as long ) as string
declare function Mkd ( byval number as double ) as string
declare function Mki ( byval number as integer ) as string
declare function Mkl ( byval number as long ) as string
declare function Mklongint ( byval number as longint ) as string
declare function Mks ( byval number as single ) as string
declare function Mkshort ( byval number as short ) as string
declare function Oct ( byval number as ubyte ) as string
declare function Oct ( byval number as ushort ) as string
declare function Oct ( byval number as ulong ) as string
declare function Oct ( byval number as ulongint ) as string
declare function Oct ( byval number as const any ptr ) as string
declare function Oct ( byval number as ubyte, byval digits as long ) as string
declare function Oct ( byval number as ushort, byval digits as long ) as string
declare function Oct ( byval number as ulong, byval digits as long ) as string
declare function Oct ( byval number as ulongint, byval digits as long ) as string
declare function Oct ( byval number as const any ptr, byval digits as long ) as string
declare function Str ( byval n as byte ) as string
declare function Str ( byval n as ubyte ) as string
declare function Str ( byval n as short ) as string
declare function Str ( byval n as ushort ) as string
declare function Str ( byval n as long ) as string
declare function Str ( byval n as ulong ) as string
declare function Str ( byval n as longint ) as string
declare function Str ( byval n as ulongint ) as string
declare function Str ( byval n as single ) as string
declare function Str ( byval n as double ) as string
declare function Str ( byval b as boolean ) as string
declare function Str ( byref str as const string ) as string
declare function Str ( byval str as const wstring ) as string
declare function Val ( byref str as const string ) as double
declare function Val ( byref str as const wstring ) as double
declare function Vallng ( byref strnum as const string ) as longint
declare function Vallng ( byref strnum as const wstring ) as longint
declare function Valint ( byref strnum as const string ) as long
declare function Valint ( byref strnum as const wstring ) as long
declare function Valuint ( byref strnum as const string ) as ulong
declare function Valuint ( byref strnum as const wstring ) as ulong
declare function Valulng ( byref strnum as const string ) as ulongint
declare function Valulng ( byref strnum as const wstring ) as ulongint
declare function Wbin ( byval number as ubyte ) as wstring
declare function Wbin ( byval number as ushort ) as wstring
declare function Wbin ( byval number as ulong ) as wstring
declare function Wbin ( byval number as ulongint ) as wstring
declare function Wbin ( byval number as const any ptr ) as wstring
declare function Wbin ( byval number as ubyte, byval digits as long ) as wstring
declare function Wbin ( byval number as ushort, byval digits as long ) as wstring
declare function Wbin ( byval number as ulong, byval digits as long ) as wstring
declare function Wbin ( byval number as ulongint, byval digits as long ) as wstring
declare function Wbin ( byval number as const any ptr, byval digits as long ) as wstring
declare function Wchr ( byval ch as integer [, ... ] ) as wstring
declare function Whex ( byval number as ubyte ) as wstring
declare function Whex ( byval number as ushort ) as wstring
declare function Whex ( byval number as ulong ) as wstring
declare function Whex ( byval number as ulongint ) as wstring
declare function Whex ( byval number as const any ptr ) as wstring
declare function Whex ( byval number as ubyte, byval digits as long ) as wstring
declare function Whex ( byval number as ushort, byval digits as long ) as wstring
declare function Whex ( byval number as ulong, byval digits as long ) as wstring
declare function Whex ( byval number as ulongint, byval digits as long ) as wstring
declare function Whex ( byval number as const any ptr, byval digits as long ) as wstring
declare function Woct ( byval number as ubyte ) as wstring
declare function Woct ( byval number as ushort ) as wstring
declare function Woct ( byval number as ulong ) as wstring
declare function Woct ( byval number as ulongint ) as wstring
declare function Woct ( byval number as const any ptr ) as wstring
declare function Woct ( byval number as ubyte, byval digits as long ) as wstring
declare function Woct ( byval number as ushort, byval digits as long ) as wstring
declare function Woct ( byval number as ulong, byval digits as long ) as wstring
declare function Woct ( byval number as ulongint, byval digits as long ) as wstring
declare function Woct ( byval number as const any ptr, byval digits as long ) as wstring 
declare function Wstr ( byval n as byte ) as wstring
declare function Wstr ( byval n as ubyte ) as wstring
declare function Wstr ( byval n as short ) as wstring
declare function Wstr ( byval n as ushort ) as wstring
declare function Wstr ( byval n as long ) as wstring
declare function Wstr ( byval n as ulong ) as wstring
declare function Wstr ( byval n as longint ) as wstring
declare function Wstr ( byval n as ulongint ) as wstring
declare function Wstr ( byval n as single ) as wstring
declare function Wstr ( byval n as double ) as wstring
declare function Wstr ( byref str as const string ) as wstring
declare function Wstr ( byval str as const wstring ptr ) as wstring
declare function Cbool ( byval expression as datatype ) as boolean
declare function Cbyte ( byval expression as datatype ) as byte
declare function Cdbl ( byval expression as datatype ) as double
declare function Cint ( byval expression as datatype ) as integer
declare function Clng ( byval expression as datatype ) as long
declare function Clngint ( byval expression as datatype ) as longint
declare function Cshort ( byval expression as datatype ) as short
declare function Csng ( byval expression as datatype ) as single
declare function Cubyte ( byval expression as datatype ) as ubyte
declare function Cuint ( byval expression as datatype ) as uinteger
declare function Culng ( byval expression as datatype ) as ulong
declare function Culngint ( byval expression as datatype ) as ulongint
declare function Cushort ( byval expression as datatype ) as ushort

'User input
declare function Getjoystick ( byval id as long, byref buttons as integer = 0, byref a1 as single = 0, byref a2 as single = 0, byref a3 as single = 0, byref a4 as single = 0, byref a5 as single = 0, byref a6 as single = 0, byref a7 as single = 0, byref a8 as single = 0 ) as integer
declare function Getkey ( ) as long
declare function Getmouse ( byref x as integer, byref y as integer, byref wheel as integer = 0, byref buttons as integer = 0, byref clip as integer = 0 ) as long
declare function Inkey ( ) as string
declare function Input ( n as integer ) as string
declare function Input ( n as integer, filenum as integer ) as string
declare function Multikey ( byval scancode as long ) as long
declare function Setmouse ( byval x as long = -1, byval y as long = -1, byval visibility as long = -1, byval clip as long = -1 ) as long
declare function Stick ( byval axis as long ) as long
declare function Strig ( byval button as long ) as long
declare function Winput( byval num as integer ) as wstring
declare function Winput( byval num as integer, byval filenum as long = 0 ) as wstring