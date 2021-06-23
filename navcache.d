module navcache;

class CNavCache
{
	private:
	import iup.iup;
	import global, actionManager, tools;
	
	import tango.io.FilePath, tango.stdc.stringz;

	// Nested Struct
	struct CacheUnit
	{
		char[]		_fullPath;
		int			_line;
	}
	
	int				index;
	CacheUnit		nullElement = { null, -1 };
	CacheUnit[2000]	cache;

	public:
	this()
	{
		index			= 0;
		cache[]			= nullElement;
	}
	
	
	bool addCache()
	{
		auto cSci = ScintillaAction.getActiveCScintilla;
		if( cSci !is null )
		{
			char[] nowFullPath	= cSci.getFullPath;
			int nowLine			= ScintillaAction.getCurrentLine( cSci.getIupScintilla );
			
			
			if( cache[index]._line != -1 ) index += 1;
			
			if( index > 1998 )
			{
				CacheUnit[] temp;
				temp.length = index - 1000;
				temp = cache[1000..index];
				cache[] = nullElement;
				cache[0..temp.length] = temp;
				
				index = temp.length;
			}
			else
			{
				cache[index+1] = nullElement;
			}			
			
			if( index > 0 )
			{
				if( nowLine == cache[index - 1]._line )
				{
					if( nowFullPath == cache[index - 1]._fullPath ) return false;
				}
				
				cache[index]._fullPath = nowFullPath;
				cache[index]._line = nowLine;
				index += 1;
			}
			else
			{
				cache[index]._fullPath = nowFullPath;
				cache[index]._line = nowLine;
				index += 1;
			}
			
			IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
			IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
		}
		else
		{
			return false;
		}

		return true;
	}	
	
	
	bool addCache( char[] fullPath, int line )
	{
		CacheUnit _element = { fullPath, line };
		
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{}
		else
		{
			scope fp = new FilePath( fullPath );
			if( !fp.exists() ) return false;
		}
		
		
		if( cache[index]._line != -1 ) index += 1;
		
		if( index > 1998 )
		{
			CacheUnit[] temp;
			temp.length = index - 1000;
			temp = cache[1000..index];
			cache[] = nullElement;
			cache[0..temp.length] = temp;
			
			index = temp.length;
		}
		else
		{
			cache[index+1] = nullElement;
		}
		
		
		IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
		IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
		
		auto cSci = ScintillaAction.getActiveCScintilla;
		if( cSci !is null )
		{
			char[] nowFullPath	= cSci.getFullPath;
			int nowLine			= ScintillaAction.getCurrentLine( cSci.getIupScintilla );
			
			if( index > 0 )
			{
				if( nowLine == cache[index - 1]._line )
				{
					if( nowFullPath == cache[index - 1]._fullPath )
					{
						cache[index++] = _element;
						IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
						IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
						return true;
					}
				}
				
				cache[index]._fullPath = nowFullPath;
				cache[index]._line = nowLine;
				index += 1;
				cache[index] = _element;
				index += 1;
			}
			else
			{
				cache[index]._fullPath = nowFullPath;
				cache[index]._line = nowLine;
				index += 1;
				cache[index] = _element;
				index += 1;
			}
		}
		else
		{
			cache[index++] = _element;
			IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "NO" );
		}
		
		
		return true;
	}
	
	CacheUnit back()
	{
		if( index > 0 )
		{
			if( index > 1 )
			{
				auto cSci = ScintillaAction.getActiveCScintilla;
				if( cSci !is null )
				{
					if( ScintillaAction.getCurrentLine( cSci.getIupScintilla ) == cache[index - 1]._line )
					{
						if( cSci.getFullPath == cache[index - 1]._fullPath ) index -= 1;
					}
				}
			}

			if( cache[index]._line != -1 ) IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "YES" );
			index -= 1;
			if( index == 0 ) IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "NO" );
			
			return cache[index];
		}
		
		return nullElement;
	}
	
	CacheUnit forward()
	{
		if( index < 1999 )
		{
			auto cSci = ScintillaAction.getActiveCScintilla;
			if( cSci !is null )
			{
				if( ScintillaAction.getCurrentLine( cSci.getIupScintilla ) == cache[index + 1]._line )
				{
					if( cSci.getFullPath == cache[index + 1]._fullPath ) index += 1;
				}
			}
		}	
	
	
	
		if( index < 1999 )
		{
			if( cache[index+1]._line != -1 )
			{
				if( index < 1998 )
				{
					if( cache[index+2]._line == -1 ) IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" ); else  IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "YES" );
				}
				else
				{
					IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
				}
				
				IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
				return cache[++index];
			}
		}

		IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
		IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "YES" );
		
		return nullElement;
	}
	
	void clear()
	{
		index = 0;
		cache[] = nullElement;
		IupSetAttribute( IupGetHandle( "toolbar_BackNav" ), "ACTIVE", "NO" );
		IupSetAttribute( IupGetHandle( "toolbar_ForwardNav" ), "ACTIVE", "NO" );
	}
}