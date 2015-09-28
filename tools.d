module tools;

class CstringConvert
{
private:
	import tango.stdc.stdlib, tango.stdc.string;

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

// To lowercase
char[] lowerCase( char[] text )
{
	char[] result;

	foreach( char c; text )
	{
		if ( c >= 'A' && c <= 'Z' ) result ~= ( c + 32 );else result ~= c;
	}

	return result;
}

char[] upperCase( char[] text )
{
	char[] result;

	foreach( char c; text )
	{
		if ( c >= 'a' && c <= 'z' ) result ~= ( c - 32 );else result ~= c;
	}

	return result;
}

int upperCase( int num )
{
	int result = num;

	if ( num >= 'a' && num <= 'z' ) result = ( num - 32 );

	return result;
}

