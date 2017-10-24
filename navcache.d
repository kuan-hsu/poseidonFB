module navcache;

class CNavCache
{
	private:
	import iup.iup;
	import actionManager;
	
	import tango.io.FilePath;

	// Nested Struct
	struct CacheUnit
	{
		char[]		_fullPath;
		int			_line;
	}
	
	int				index;
	CacheUnit		nullElement = { null, -1 };
	CacheUnit[1000]	cache;

	public:
	this()
	{
		//cache.length	= 1000;
		index			= 0;
		cache[]			= nullElement;
	}
	
	bool addCache( char[] fullPath, int line )
	{
		CacheUnit _element = { fullPath, line };
		
		if( index == 0 && cache[0]._line == -1 )
		{
			scope fp = new FilePath( fullPath );
			
			if( !fp.exists() ) return false;
			
			auto cSci = ScintillaAction.getActiveCScintilla;
			if( cSci !is null )
			{
				cache[0]._fullPath = cSci.getFullPath;
				cache[0]._line = ScintillaAction.getCurrentLine( cSci.getIupScintilla ); // 1 based
			}
		}
		
		if( index >= 999 )
		{
			cache[0..999] = cache[1..999];
			cache[999] = _element;
		}
		else
		{
			cache[++index] = _element;
		}
		
		IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
		
		return true;
	}
	
	CacheUnit back()
	{
		if( index > 0 )
		{
			if( index == 1 ) IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "NO" );
			if( cache[index]._line != -1 ) IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "YES" );
			return cache[--index];
		}
		return nullElement;
	}
	
	CacheUnit forward()
	{
		if( index < 999 )
		{
			if( cache[index+1]._line != -1 )
			{
				if( index < 998 )
				{
					if( cache[index+2]._line == -1 ) IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
				}
				else
				{
					IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
				}
				
				IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
				return cache[++index];
			}
		}
		
		return nullElement;
	}
	
	void clear()
	{
		index = 0;
		cache[] = nullElement;
		IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "NO" );
		IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
	}
	
	void eraseTail()
	{
		cache[index] = nullElement;
		if( index > 0 ) --index;
	}
	/*
	int getIndex()
	{
		return index;
	}
	
	CacheUnit getCache( int _index )
	{
		if( _index < 1000 ) return cache[_index];
	}
	*/
}