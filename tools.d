module tools;

import tango.stdc.stdlib, tango.stdc.string, tango.stdc.stringz, tango.time.Clock;
import Util = tango.text.Util, tango.io.device.File, tango.io.stream.Lines, tango.io.FilePath, Path = tango.io.Path;

version(DIDE)
{
	class CContainer( T )
	{
	protected:
		int     container_size = 0, max_container_size;
		T[]     container;

	public:
		this(){}
		
		this( int size ){ container.length = max_container_size = size; }

		~this(){ container.length = 0; }

		// Overload []
		T opIndex( int i ){ return container[i]; }
		
		int size(){ return container_size; }

		bool empty(){ if( container_size == 0 ) return true;else return false; }

		void clear()
		{
			container_size = 0;
			//container.length = 0;
		}
	}


	class CStack( T ) : CContainer!( T )
	{
	public:
		this(){ super( 50 ); }
		
		this( int size ){ super( size ); }

		~this(){ delete container; }

		void push( T t )
		{
			container_size   ++;
			if( container_size > max_container_size )
			{
				max_container_size = container_size + 50;
				container.length   = max_container_size; // Resize
			}

			container[container_size - 1] = t;
		}

		void pop(){ if( container_size < 1 ) return;else container_size --; }

		T top(){ if( container_size < 1 ) return null; else return container[container_size - 1]; }
	}
}

class IupString
{
private:
	import	tango.stdc.stringz;
	
	char*	_CstringPointer = null;
	char[]	_DString;

	void copy( char[] Dstring )
	{
		_DString = Dstring;
		_CstringPointer = cast(char*)calloc( 1, Dstring.length + 1 );
		memcpy( _CstringPointer, Dstring.ptr, Dstring.length );
	}

public:
	this(){}
	
	this( char[] Dstring )
	{
		copy( Dstring );
	}

	this( char* Cstring )
	{
		if( Cstring != null )
		{
			_DString = fromStringz( Cstring );
			
			int _len = strlen( Cstring );
			_CstringPointer = cast(char*)calloc( 1, _len + 1 );
			memcpy( _CstringPointer, Cstring, _len );
		}
	}	

	~this()
	{
		if( _CstringPointer != null ) free( _CstringPointer );
	}
	
	void opAssign( char[] rhs )
	{
		convert( rhs );
	}
	
	void opAssign( char* rhs )
	{
		convert( fromStringz( rhs ).dup );
	}
	
	char* opShl( char* rhs )
	{
		if( rhs != null )
		{
			char* _tempPointer = _CstringPointer;
			copy( fromStringz( rhs ).dup );
			if( _tempPointer != null ) free( _tempPointer );
		}
		else
		{
			if( _CstringPointer != null ) free( _CstringPointer );
			_DString.length = 0;
			return null;
		}
		
		return _CstringPointer;
	}

	char* convert( char[] Dstring )
	{
		if( _CstringPointer != null ) free( _CstringPointer );
		copy( Dstring );

		return _CstringPointer;
	}

	char* toCString()
	{
		return _CstringPointer;
	}

	char[] toDString()
	{
		return _DString;
	}
}

char* getCString( char[] Dstring )
{
	char* CstringPointer = cast(char*)calloc( 1, Dstring.length + 1 );
	memcpy( CstringPointer, Dstring.ptr, Dstring.length );

	return CstringPointer;
}

void freeCString( char* cString )
{
	if( cString != null ) free( cString );
}

char* toStringPtr( char[] DString )
{
	int len = DString.length;
	char[] _str = new char[len+1];
	_str[0..len] = DString;
	_str[len] = '\0';
	return _str.ptr;
}


// To lowercase
char[] lowerCase( char[] text )
{
	char[] result;

	foreach( char c; text )
	{
		if ( c >= 'A' && c <= 'Z' ) result ~= cast(char)( c + 32 );else result ~= c;
	}

	return result.dup;
}

char[] upperCase( char[] text )
{
	char[] result;

	foreach( char c; text )
	{
		if ( c >= 'a' && c <= 'z' ) result ~= cast(char)( c - 32 );else result ~= c;
	}

	return result.dup;
}

int lowerCase( int num )
{
	int result = num;

	if ( num >= 'A' && num <= 'Z' ) result = cast(char)( num + 32 );

	return result;
}

int upperCase( int num )
{
	int result = num;

	if ( num >= 'a' && num <= 'z' ) result = cast(char)( num - 32 );

	return result;
}

void sleep( uint millisecond )
{
	auto now = Clock.now.span.millis;
	
	while( Clock.now.span.millis - now < millisecond )
	{
	}
}

version(FBIDE)
{
	char[] convertKeyWordCase( int type, char[] replaceText )
	{
		switch( type )
		{
			case 1: replaceText = lowerCase( replaceText ); break; // lowercase
			case 2: replaceText = upperCase( replaceText ); break; // UPPERCASE
			case 3: // MixedCase
				replaceText = lowerCase( replaceText );
				for( int i = 0; i < replaceText.length; ++ i )
				{
					if( replaceText[i] >= 'a' && replaceText[i] <= 'z' )
					{
						replaceText[i] = cast(char) ( replaceText[i] - 32 );
						break;
					}
				}
				break;
			default:
		}

		return replaceText;
	}
}

char[] setINILineData( char[] left, char[] right = "" )
{
	if( !right.length )
	{
		if( left.length > 1 )
		{
			if( left[0] == '[' && left[$-1] == ']' ) return left ~ "\n";
		}
	}
	return left ~ "=" ~ right ~ "\n";
}

// Return: 1 = Block, 2 = Items, 0 = Illegal
int getINILineData( char[] lineData, out char[] left, out char[] right )
{
	int assignPos = Util.index( lineData, "=" );
	if( assignPos < lineData.length )
	{
		left	= Util.trim( lineData[0..assignPos] );
		right	= Util.trim( lineData[assignPos+1..$] );
		
		// For previous reversion.....
		if( left.length > 1 )
			if( left[0] == '[' && left[$-1] == ']' ) return 1;

		return 2;
	}
	else
	{
		if( lineData.length > 1 )
		{
			lineData = Util.trim( lineData );
			if( lineData[0] == '[' && lineData[$-1] == ']' ) left = lineData;
			return 1;
		}
	}
	return 0;
}

version(DIDE)
{
	char[] removeArrayAndPointer( char[] word )
	{
		char[] result;

		foreach( char c; word )
		{
			if( c == '[' || c == '*' || c == '!' ) break; else result ~= c;
		}

		return result;
	}

	char[] getSeparateType( char[] _string, bool bemoveArrayAndPoint = false )
	{
		int openParenPos = Util.index( _string, "(" );

		if( openParenPos > 0 && openParenPos < _string.length )
		{
			if( _string[openParenPos-1] == '!' ) openParenPos = Util.index( _string, "(", openParenPos + 1 );
		}
		
		if( openParenPos < _string.length )
		{
			if( bemoveArrayAndPoint ) return removeArrayAndPointer( _string[0..openParenPos] ); else return _string[0..openParenPos];
		}

		return !bemoveArrayAndPoint ? _string : removeArrayAndPointer( _string );
	}

	char[] getSeparateParam( char[] _string )
	{
		int openParenPos = Util.index( _string, "(" );

		if( openParenPos > 0 && openParenPos < _string.length )
		{
			if( _string[openParenPos-1] == '!' ) openParenPos = Util.index( _string, "(", openParenPos + 1 );
		}
		
		if( openParenPos < _string.length )
		{
			return _string[openParenPos..$];
		}

		return null;
	}

	char[] convertGoUPLevel( char[] oriPath )
	{
		scope _sp = new FilePath;
		
		int upPos = Util.index( oriPath, "../" );

		while( upPos < oriPath.length )
		{
			if( upPos > 0 )
			{
				_sp.set( oriPath[0..upPos] );
				oriPath = _sp.parent ~ oriPath[upPos+2..$];

				upPos = Util.index( oriPath, "../" );

				continue;
			}
		}

		return oriPath;
	}

	char[][] getImportPath( char[] compilerFullPath )
	{
		char[][] _split( char[] txt )
		{
			char[][]	_results;
			char[]		_tempTxt;
			bool		bString;
			
			foreach( char c; txt )
			{
				switch( c )
				{
					case '"':
						if( !bString ) bString = true; else bString = false;
						_tempTxt ~= c;
						break;
					
					case ' ':
						if( !bString )
						{
							if( _tempTxt.length ) _results ~= _tempTxt;
							_tempTxt = "";
						}
						else
						{
							_tempTxt ~= c;
						}
						break;
						
					default:
						_tempTxt ~= c;
				}
			}
			
			if( _tempTxt.length && !bString ) _results ~= _tempTxt;
			
			return _results;
		}

		// Get and Set Default Import Path
		scope filePath = new FilePath( compilerFullPath );

		FilePath sc;
		version(Windows) sc = new FilePath( filePath.path() ~ "sc.ini" ); else sc = new FilePath( filePath.path() ~ "dmd.conf" );

		char[][] results;
		
		if( sc.exists() )
		{
			scope scfile = new File( sc.toString(), File.ReadExisting );
		
			foreach( line; new Lines!(char)(scfile) )
			{
				if( line.length > 7 )
				{
					if( line[0..7] == "DFLAGS=" )
					{
						line = line[7..$];
						if( line.length )
						{
							Util.replace( line, '\t', ' ' );
							foreach( char[] _section; _split( line ) )
							{
								if( _section.length > 2 )
								{
									if( _section[0..3] == "\"-I" )
									{
										int endPos = Util.index( _section, "\"", 3 );
										if( endPos < _section.length )
										{
											_section = _section[3..endPos];
											foreach( char[] s; Util.split( _section, ";" ) )
											{
												if( s.length )
												{
													char[] compilerPath = filePath.path();
													if( compilerPath.length )
														if( compilerPath[$-1] == '/' ) compilerPath = compilerPath[0..$-1];

													s = Util.substitute( s, "%@P%", compilerPath );
													s = Path.normalize( s );
													if(s[$-1] != '/' ) s ~= '/';
													results ~= convertGoUPLevel( s );
												}
											}
										}
									}
									else if( _section[0..2] == "-I" )
									{
										_section = _section[2..$];
										foreach( char[] s; Util.split( _section, ";" ) )
										{
											if( s.length )
											{
												char[] compilerPath = filePath.path();
												if( compilerPath.length )
													if( compilerPath[$-1] == '/' ) compilerPath = compilerPath[0..$-1];

												s = Util.substitute( s, "%@P%", compilerPath );
												s = Path.normalize( s );
												if(s[$-1] != '/' ) s ~= '/';
												results ~= convertGoUPLevel( s );
											}
										}								
									}
								}
							}
						}
					}
				}
			
				/+
				if( line.length > 7 )
				{
					if( line[0..7] == "DFLAGS=" )
					{
						int importPos;

						do
						{
							line = Path.normalize( line );
							
							importPos = Util.index( line, "\"-I", importPos );
							if( importPos < line.length )
							{
								int endPos = Util.index( line, "\"", importPos + 3 );
								if( endPos < line.length )
								{
									char[] importString = line[importPos+3..endPos];

									foreach( char[] s; Util.split( importString, ";" ) )
									{
										if( s.length )
										{
											char[] compilerPath = filePath.path();
											if( compilerPath.length )
												if( compilerPath[$-1] == '/' ) compilerPath = compilerPath[0..$-1];

											s = Util.substitute( s, "%@P%", compilerPath );
											Util.replace( s, '\\', '/' );
											if(s[$-1] != '/' ) s ~= '/';
											results ~= convertGoUPLevel( s );
										}
									}
								}

								importPos = endPos;
							}
							else
							{
								importPos = Util.index( line, "-I", importPos );
								if( importPos < line.length )
								{
									int		i;
									char[]	importString;
									
									for( i = importPos + 2; i < line.length; ++ i )
									{
										if( line[i] != ' ' && line[i] != '\t' )
										{
											importString ~= line[i];
										}
										else
										{
											break;
										}
									}

									importPos = i;

									foreach( char[] s; Util.split( importString, ";" ) )
									{
										if( s.length )
										{
											char[] compilerPath = filePath.path();
											if( compilerPath.length )
												if( compilerPath[$-1] == '/' ) compilerPath = compilerPath[0..$-1];

											s = Util.substitute( s, "%@P%", compilerPath );
											Util.replace( s, '\\', '/' );
											if(s[$-1] != '/' ) s ~= '/';
											results ~= convertGoUPLevel( s );
										}
									}								
								}
							}
						}
						while( importPos < line.length )
					}
				}
				+/
			}
		}

		delete sc;	
		return results;
	}
}

class CPLUGIN
{
	private:
	import											iup.iup;
	import											tango.sys.SharedLib;
	import											tango.stdc.stringz;
	
	extern(C) void function( Ihandle* )				poseidonFB_Dll_Go;
	
	SharedLib										sharedLib;
	char[]											pluginName, pluginPath;
	bool											bSuccess;
	
	public:
	
	/*
	typedef extern (C) void function( Ihandle* ) 	_Send_PoseidonFB_HANDLE;
	typedef extern (C) void function( Ihandle* ) 	_Send_SCINTILLA;
	typedef extern (C) void function( Ihandle* ) 	_poseidonFB_Dll_Go;
	*/
	
	this( char[] name, char[] fullPath )
	{
		try
		{
			pluginName = name;
			pluginPath = fullPath;
			
			sharedLib = SharedLib.load( fullPath );
			
			void* iupPtr = sharedLib.getSymbol( "poseidonFB_Dll_Go" );
			if( iupPtr )
			{
				void **point = cast(void **) &poseidonFB_Dll_Go; // binding function address from DLL to our function pointer
				*point = iupPtr;
				bSuccess = true;
			}
			else
			{
				unload();
				IupMessage( "Error", toStringz( "Load poseidonFB_Dll_Go Symbol in " ~ name ~ " Error!" ) );
				throw new Exception( "Load poseidonFB_Dll_Go Symbol in " ~ name ~ " Error!" );
			}
		}
		catch( Exception e )
		{
			unload();
			IupMessage( "Error", toStringz( "Load " ~ name ~ " Error!\n" ~ e.toString ) );
			throw new Exception( "Load " ~ name ~ " Error!\n" ~ e.toString );
		}
	}
	
	~this()
	{
		if( sharedLib !is null ) sharedLib.unload();
	}
	
	void go( Ihandle* poseidonFB_MainHandle )
	{
		if( bSuccess ) poseidonFB_Dll_Go( poseidonFB_MainHandle );
	}
	
	bool isSuccess()
	{
		return bSuccess;
	}
	
	char[] getPath()
	{
		return pluginPath;
	}
	
	void unload()
	{
		IupMessage("DLL UNLOAD","");
		if( sharedLib !is null ) sharedLib.unload();
	}
}

/+
private import  tango.sys.Common;

// The code is made by Christopher E. Miller 
char[] getEnvironmentVariable(char[] name)
{
	/+
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetEnvironmentVariableW proc;
		}
		else
		{
			const char[] NAME = "GetEnvironmentVariableW";
			static GetEnvironmentVariableWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetEnvironmentVariableWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar* strz, buf;
		DWORD len;
		strz = toUnicodez(name);
		len = proc(strz, null, 0);
		if(!len)
			return null;
		buf = (new wchar[len]).ptr;
		len = proc(strz, buf, len);
		return fromUnicode(buf, len);
	}
	else
	{
	+/
		char* strz, buf;
		ulong len;
		strz = toStringz(name);
		len = GetEnvironmentVariableA(strz, null, 0);
		if(!len)
			return null;
		buf = (new char[len]).ptr;
		len = GetEnvironmentVariableA(strz, buf, len);
		//return fromAnsi(buf, len);
		
		return fromStringz(buf);
	//}
}
+/