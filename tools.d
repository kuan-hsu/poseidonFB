module tools;

import tango.stdc.stdlib, tango.stdc.string;


class CstringConvert
{
private:
	//import tango.stdc.stdlib, tango.stdc.string;

	char* CstringPointer = null;

	void copy( char[] Dstring )
	{
		CstringPointer = cast(char*)calloc( 1, Dstring.length + 1 );
		memcpy( CstringPointer, Dstring.ptr, Dstring.length );
	}

public:
	this(){}
	
	this( char[] Dstring )
	{
		copy( Dstring );
	}

	~this()
	{
		if( CstringPointer != null ) free( CstringPointer );
	}

	char* convert( char[] Dstring )
	{
		if( CstringPointer != null ) free( CstringPointer );
		copy( Dstring );

		return CstringPointer;
	}

	char* toStringz()
	{
		return toZ;
	}

	char* toZ()
	{
		return CstringPointer;
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


// To lowercase
char[] lowerCase( char[] text )
{
	char[] result;

	foreach( char c; text )
	{
		if ( c >= 'A' && c <= 'Z' ) result ~= ( c + 32 );else result ~= c;
	}

	return result.dup;
}

char[] upperCase( char[] text )
{
	char[] result;

	foreach( char c; text )
	{
		if ( c >= 'a' && c <= 'z' ) result ~= ( c - 32 );else result ~= c;
	}

	return result.dup;
}

int lowerCase( int num )
{
	int result = num;

	if ( num >= 'A' && num <= 'Z' ) result = ( num + 32 );

	return result;
}

int upperCase( int num )
{
	int result = num;

	if ( num >= 'a' && num <= 'z' ) result = ( num - 32 );

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