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

char* getCString( char[] Dstring )
{
	char* CstringPointer = cast(char*)calloc( 1, Dstring.length + 1 );
	memcpy( CstringPointer, Dstring.ptr, Dstring.length );

	return CstringPointer;
}


class DstringConvert
{
private:
	char[] Dstring;

public:
	this(){}
	
	this( char* Cstring, int length = -1 )
	{
		int len;

		if( length == -1 ) len = strlen( Cstring );
		Dstring ~= Cstring[0..len];
	}

	~this()
	{
	}

	char[] convert( char* Cstring, int length = -1 )
	{
		if( Dstring.length ) Dstring.length = 0;

		int len;
		if( length == -1 ) len = strlen( Cstring );
		Dstring ~= Cstring[0..len];

		return Dstring;
	}

	char[] toDString()
	{
		return Dstring;
	}
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