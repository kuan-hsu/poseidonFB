module tools;

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


/+

// Sort Class
abstract class CHeapSort( T )
{
	protected:
	T[]		container;
	T		global_temp;
	int 	c_index;

	void down_heap( int parent_index, int last_heap_index )
	{
		int		p_index, last_parent_index;

		global_temp			= container[parent_index];
		p_index           	= parent_index;
		last_parent_index 	= ( last_heap_index - 1 ) >> 1;

		while( p_index <= last_parent_index )
		{
			c_index = ( p_index << 1 ) + 1;
			if( c_index < last_heap_index )
				if( compFunc1 ) c_index ++;
			if( compFunc2() )
			{
				container[p_index] = container[c_index];
				p_index = c_index;
			}
			else break;
		}
		if( p_index != parent_index ) container[p_index] = global_temp;
	}

	void heap_sort()
	{
		if( container.length < 2 ) return;

		int		last_parent_index, last_heap_index;
		T		temp;

		last_heap_index   = container.length - 1;
		last_parent_index = ( last_heap_index - 1 ) >> 1;

		for( int i = last_parent_index; i >= 0; i -- )
			down_heap( i, container.length - 1 );

		temp = container[0];
		container[0] = container[last_heap_index];
		container[last_heap_index] = temp;

		last_heap_index --;
		last_parent_index = ( last_heap_index - 1 ) >> 1;
		for( int i = container.length - 2; i > 0; i -- )
		{
			down_heap( 0, i );
			temp = container[0];
			container[0] = container[i];
			container[i] = temp;
		}
	}

	bool 	compFunc1();

	bool 	compFunc2();	


	public:
	this( T[] elements )
	{ 
		container = elements;
		sort();
	}

	~this(){ container.length = 0; }

	T 		opIndex( int i ){ return container[i]; } // Overload []

	void 	push( T[] elements ){ container = elements; }

	void 	push( T elements ){ container ~= elements; }

	T	 	pop(){ return container[length-1]; }

	T[] 	dump(){ return container; }

	T[] 	dumpRemoveRepeat()
	{
		T[] temp;

		if( container.length > 1 )
		{
			temp ~= container[0];
			
			for( int i = 1; i < container.length; ++ i )
			{
				if( container[i].name != container[i-1].name ) temp ~= container[i];
			}
		}
		else
		{
			return container;
		}
		
		return temp;
	}
	
	void 	sort(){ heap_sort(); }
	
	int 	size(){ return container.length; }

	void	clear(){ container.length = 0; }
}

class CNameSort( T ) : CHeapSort!( T )
{
	private:
	import Util = tango.text.Util;
	
	protected:

	bool compFunc1(){ return ( lowerCase( container[c_index + 1].name ) >= lowerCase( container[c_index].name ) ); }

	bool compFunc2(){ return ( lowerCase( container[c_index].name ) >= lowerCase( global_temp.name ) ); }

	public:
	
	this( T[] elements )
	{
		foreach( t; elements )
		{
			Util.replace( t.name, '_', '~' );
		}

		super( elements );

		foreach( t; elements )
		{
			Util.replace( t.name, '~', '_' );
		}
	}
}
+/