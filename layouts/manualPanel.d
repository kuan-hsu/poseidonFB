module layouts.manualPanel;

private import iup.iup;
private import iup.iup_scintilla;

private import global, scintilla, actionManager, tools;

private import tango.stdc.stringz, tango.io.FilePath, Util = tango.text.Util;


class CManual
{
	private:
	import				iup.iupweb;

	import				menu;
	
	import				tango.core.Thread;
	
	Ihandle*			layoutHandle, webHandle, tempTextHandle, clipboard;
	IupString			title;
	static IupString	prevClipboard;
	int					fullPathState;
	
	static	bool		bShowType;

	void createLayout()
	{
		webHandle = IupWebBrowser();
		IupSetCallback( webHandle, "COMPLETED_CB",cast(Icallback) &COMPLETED_CB );
		IupSetCallback( webHandle, "ERROR_CB",cast(Icallback) &ERROR_CB );
		/*
		if( GLOBAL.manualPath.toDString.length )
		{
			if( GLOBAL.toggleUseManual == "ON" ) IupSetAttribute( webHandle, "VALUE", GLOBAL.manualPath.toCString );
		}
		*/
		
		tempTextHandle= IupText( null );
		IupSetAttributes( tempTextHandle, "MULTILINE=YES,VISIBLE=NO,VISIBLELINES=0,VISIBLECOLUMNS=0" );
		IupSetHandle( "manualTextHandle", tempTextHandle );
		
		layoutHandle = IupZbox( webHandle, tempTextHandle, null );
		
		
		title = new IupString( GLOBAL.languageItems["manual"] );
		IupSetAttribute( layoutHandle, "TABTITLE", title.toCString );
		IupSetAttribute( layoutHandle, "TABIMAGE", "icon_manual" );
		
		clipboard = IupClipboard();
		IupSetHandle( "clipboard", clipboard );
	}

	public:
	this()
	{
		CManual.prevClipboard = new IupString();
		IupWebBrowserOpen();
		createLayout();
	}
	
	~this()
	{
	}	
	
	Ihandle* getWebHandle()
	{
		return webHandle;
	}
	
	Ihandle* getTextHandle()
	{
		return tempTextHandle;
	}
	
	Ihandle* getLayoutHandle()
	{
		return layoutHandle;
	}	
	
	void setValue( char[] _url )
	{
		if( Util.index( _url, "http://" ) != 0 && Util.index( _url, "https://" ) != 0 ) _url = "file:///" ~ _url;
		
		IupSetAttribute( webHandle, "VALUE", toStringz( _url ) );
	}
	
	void setValue( char* _url )
	{
		char[] url = fromStringz( _url );
		if( Util.index( url, "http://" ) != 0 && Util.index( url, "https://" ) != 0 )
		{
			url = "file:///" ~ url;
			IupSetAttribute( webHandle, "VALUE", toStringz( url ) );
		}
		else
		{
			IupSetAttribute( webHandle, "VALUE", _url );
		}
	}
	
	char[] getText()
	{
		Ihandle* manualTextHandle = IupGetHandle( "manualTextHandle" );
		
		if( manualTextHandle != null ) return fromStringz( IupGetAttribute( manualTextHandle, "VALUE" ) );
		
		return null;
	}

	bool jumpDefinition( char[] _keyWord )
	{
		foreach( char[] _s; GLOBAL.KEYWORDS )
		{
			foreach( char[] targetText; Util.split( _s, " " ) )
			{
				if( _keyWord == targetText )
				{
					scope _fp = new FilePath( GLOBAL.manualPath.toDString );
					version(linux)
					{
						targetText = lowerCase( targetText );
						if ( targetText[0] >= 'a' && targetText[0] <= 'z' ) targetText[0] = targetText[0] - 32;
					}
					_fp.set( _fp.path() ~ "KeyPg" ~ targetText ~ ".html" );
					if( _fp.exists() )
					{
						setValue( _fp.toString );
						return true;
					}
				}
			}
		}
		
		return false;
	}
	
	void showType( char[] _keyWord )
	{
		CManual.bShowType = true;
		if( !jumpDefinition( _keyWord ) )
		{
			CManual.bShowType = false;
		}
	}
	
	void showTab( bool bShow )
	{
		Ihandle* menuManualWindowHandle = IupGetHandle( "menuManualWindow" );
		if( menuManualWindowHandle != null )
		{
			if( bShow )
			{
				if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
				
				IupSetAttribute( menuManualWindowHandle, "VALUE", "ON" );
				IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 3, "YES" ); // Show
				IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 3 );		
			}
			else
			{
				IupSetAttribute( menuManualWindowHandle, "VALUE", "OFF" );
				IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 3, "NO" ); // Show
			}
		}
	}
}


extern(C)
{
	private char[] refreshWidth( int startPos, int width, char[] s )
	{
		char[]	result;
		
		if( s[startPos..$].length <= width )
		{
			result ~= ( s[startPos..$] ~ "\n" );
		}
		else
		{
			// get New width
			while( s[startPos+width] != ' ' )
			{
				width --;
				if( startPos + width <= startPos + 1 )
				{
					result ~= ( s[startPos..startPos+width] ~ "\n" );
					return result;
				}
			}
			
			
			result ~= ( s[startPos..startPos+width] ~ "\n" );
			
			startPos += width;
			
			result ~= refreshWidth( startPos, 100, s );
		}
		
		return result;
	}
	
	private int COMPLETED_CB( Ihandle* ih, char* url )
	{
		Ihandle* manualTextHandle = IupGetHandle( "manualTextHandle" );
		
		if( manualTextHandle != null )
		{
			// Save previous clipboard text
			CManual.prevClipboard = IupGetAttribute( IupGetHandle( "clipboard" ), "TEXT" );
			
			IupSetAttribute( ih, "SELECTALL", "YES" );
			IupSetAttribute( ih, "COPY", null );
			IupSetAttribute( ih, "RELOAD", "1" );
			IupSetAttribute( ih, "STOP", "1" );
			IupSetAttribute( manualTextHandle, "VALUE", null );
			IupSetAttribute( manualTextHandle, "CLIPBOARD", "PASTE" );
			
			// Restore previous clipboard text
			IupSetAttribute( IupGetHandle( "clipboard" ), "TEXT", CManual.prevClipboard.toCString );
			
			if( CManual.bShowType )
			{
				Ihandle* iupSci = ScintillaAction.getActiveIupScintilla();
				if( iupSci != null )
				{
					int	lineNumber = IupScintillaSendMessage( iupSci, 2166, ScintillaAction.getCurrentPos( iupSci ), 0 ); //SCI_LINEFROMPOSITION = 2166,
					
					char[]	annotationText;
					bool	bFirstLine = true;
					foreach( char[] line; Util.splitLines( fromStringz( IupGetAttribute( manualTextHandle, "VALUE" ) ) ) )
					{
						if( bFirstLine )
						{
							bFirstLine = false;
							int spacePos = Util.index( line, " " );
							if( spacePos < line.length )
							{
								annotationText ~= ( line[0..spacePos] ~ "\n" ~ line[spacePos..$] ~ "\n" );
								continue;
							}
						}
						if( line == "Example" ) break;
						annotationText ~= refreshWidth( 0, 100, line );
					}
					
					IupSetAttributeId( iupSci, "ANNOTATIONTEXT", lineNumber, toStringz( annotationText ) );
					IupSetIntId( iupSci, "ANNOTATIONSTYLE", lineNumber, 42 );
					IupSetAttribute( iupSci, "ANNOTATIONVISIBLE", "BOXED" );
				}
			}
		}
		
		CManual.bShowType = false;
		
		return IUP_IGNORE;
	}
	
	private int ERROR_CB( Ihandle* ih, char* url )
	{
		Ihandle* manualTextHandle = IupGetHandle( "manualTextHandle" );
		if( manualTextHandle != null ) IupSetAttribute( manualTextHandle, "VALUE", null );
		
		CManual.bShowType = false;
		
		return IUP_DEFAULT;
	}	
}