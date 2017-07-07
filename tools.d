module tools;

import tango.stdc.stdlib, tango.stdc.string, tango.stdc.stringz;

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
					replaceText[i] = replaceText[i] - 32;
					break;
				}
			}
			break;
		default:
	}

	return replaceText;
}

private import  tango.sys.Common;

/+
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