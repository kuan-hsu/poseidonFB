module actionManager;

public import executer;

private import iup.iup, iup.iup_scintilla;

private import global, tools;

private import Integer = tango.text.convert.Integer;
private import Util = tango.text.Util;
private import tango.stdc.stringz;

// Action for FILE operate
struct FileAction
{
private:
	import	tango.text.convert.Utf, tango.io.UnicodeFile, tango.io.device.File;
	import	tango.io.FilePath;//, Path = tango.io.Path;
	
	version(Windows) import tango.sys.win32.CodePage;
	
	//static char[] content;
	
	static bool isUTF8WithouBOM( ubyte[] data )
	{
		int size = data.length;
		for( int i = 0; i < size; ++ i )
		{
			if( ( data[i] & 0x80 ) == 0x00 )
			{
				continue;
			}
			else if( ( data[i] & 0xE0 ) == 0xC0 )
			{
				if( i + 1 >= size ) return false; // data tail
	 
				if( ( data[i + 1] & 0xC0 ) != 0x80 ) return false;
	 
				i += 1;
			}
			else if( ( data[i] & 0xF0 ) == 0xE0 )
			{
				if( i + 2 >= size ) return false;
	 
				if( ( data[i + 1] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 2] & 0xC0 ) != 0x80 ) return false;
	 
				i += 2;
			}
			else if( ( data[i] & 0xF8 ) == 0xF0 )
			{
				if( i + 3 >= size ) return false;
				
				if( ( data[i + 1] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 2] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 3] & 0xC0 ) != 0x80 ) return false;
	 
				i += 3;
			}
			/*
			else if( ( data[i] & 0xFC ) == 0xF8 )
			{
				if( i + 4 >= size ) return false;
				
				if( ( data[i + 1] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 2] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 3] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 4] & 0xC0 ) != 0x80 ) return false;
	 
				i += 4;
			}
			else if( ( data[i] & 0xFE ) == 0xFC )
			{
				if( i + 5 >= size ) return false;
				
				if( ( data[i + 1] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 2] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 3] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 4] & 0xC0 ) != 0x80 ) return false;
				if( ( data[i + 5] & 0xC0 ) != 0x80 ) return false;
	 
				i += 5;
			}
			*/
			else
			{ 
				return false;
			}
			
		}

		return true;
	}

	static int isUTF16WithouBOM( ubyte[] data )
	{
		if( data.length % 2 != 0 ) return 0;
		
		// Check New line char
		int countBE, countLE;
		
		for( int i = 0; i < data.length; i += 2 )
		{
			if( data[i] == 0 )
			{
				if( data[i+1] == 0x0a || data[i+1] == 0x0d ) countBE++;
			}
			else if( data[i+1] == 0 )
			{
				if( data[i] == 0x0a || data[i] == 0x0d ) countLE++;
			}
		}

		if( countBE && !countLE ) return 1;
		if( !countBE && countLE ) return 2;
		
		
		// ASCII
		countBE = countLE = 0;
		for( int i = 0; i < data.length; i += 2 )
		{
			if( data[i] == 0 ) countBE++;
		}

		if( countBE > data.length / 3 ) return 1;

		for( int i = 1; i < data.length; i += 2 )
		{
			if( data[i] == 0 ) countLE++;
		}

		if( countLE > data.length / 3 ) return 2;
		
		
		return 0;
	}

	static int isUTF32WithouBOM( ubyte[] data )
	{
		int BELE;
		
		if( data.length % 4 != 0 || data.length < 4 ) return 0;

		for( int i = 0; i < data.length; i += 4 )
		{
			if( data[i] == 0 ) // BE
			{
				if( data[i+1] <= 0x10 )
				{
					if( BELE == 2 ) return 0;
					BELE = 1;
					continue;
				}
				else
				{
					return 0;
				}
			}
			else if( data[i+3] == 0 ) //LE
			{
				if( data[i+2] <= 0x10 )
				{
					if( BELE == 1 ) return 0;
					BELE = 2;
					continue;
				}
				else
				{
					return 0;
				}
			}
			else
			{
				return 0;
			}
		}

		return BELE;
	}
	
	
	static ubyte[] swapBytes( ubyte[] _data, int bytes )
	{
		if( _data.length % 2 != 0 || _data.length == 0 ) return null;
		
		ubyte[] ret;
		ret.length = _data.length;

		if( bytes == 2 )
		{
			for( int i = 0; i < _data.length; i = i + 2 )
			{
				ret[i] = _data[i+1];
				ret[i+1] = _data[i];
			}
		}
		else if( bytes == 4 )
		{
			for( int i = 0; i < _data.length; i = i + 4 )
			{
				ret[i] = _data[i+3];
				ret[i+1] = _data[i+2];
				ret[i+2] = _data[i+1];
				ret[i+3] = _data[i];
			}
		}
		
		return ret;
	}
	

public:
	static void newFile( char[] fullPath )
	{
		auto _file = new File( fullPath, File.ReadWriteCreate );
		_file.close;
		
		scope file = new UnicodeFile!(char)( fullPath, Encoding.Unknown );
	}


	static char[] loadFile( char[] fullPath, ref int _encoding )
	{
		char[] content;
		
		try
		{
			scope _fp = new FilePath( fullPath );
			if( !_fp.exists )
			{
				debug IupMessageError( null, toStringz( fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString() ) );
				return null;
			}
			else
			{
				if( _fp.isFolder ) 
				{
					debug IupMessageError( null, toStringz( fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString() ) );
					return null;
				}
			}
			

			auto str = cast(ubyte[]) File.get( fullPath );
			// If the DLL be loaded, the function pointer is not null
			if( GLOBAL.iconv == null )
			{
				if( str.length > 3 )
				{
					//UTF32 with BOM
					if( str[0] == 0xFF && str[1] == 0xFE && str[2] == 0x00 && str[3] == 0x00 )
					{
						_encoding = Encoding.UTF_32LE;
						content = toString( cast(dchar[]) str[4..$] );
						return content;
					}
					else if( str[0] == 0x00 && str[1] == 0x00 && str[2] == 0xFE && str[3] == 0xFF )
					{
						_encoding = Encoding.UTF_32BE;
						content = toString( cast(dchar[]) swapBytes( str[4..$], 4 ) );
						return content;
					}
				}
				
				//UTF8 with BOM
				if( str.length > 2 )
				{
					//UTF8 with BOM
					if( str[0] == 0xEF && str[1] == 0xBB && str[2] == 0xBF )
					{
						_encoding = Encoding.UTF_8;
						content = cast(char[]) str[3..$];
						return content;
					}
				}				
				
				//UTF16 with BOM
				if( str.length > 1 )
				{
					//UTF16 with BOM
					if( str[0] == 0xFF && str[1] == 0xFE)
					{
						_encoding = Encoding.UTF_16LE;
						content = toString( cast(wchar[]) str[2..$] );
						return content;
					}
					else if( str[0] == 0xFE && str[1] == 0xFF)
					{
						_encoding = Encoding.UTF_16BE;
						content = toString( cast(wchar[]) swapBytes( str[2..$], 2 ) );
						return content;
					}
				}			
				
				
				// Check Without BOM
				int BELE = isUTF32WithouBOM( str );
				if( BELE == 1 )
				{
					_encoding = 9; // UTF-32BE without BOM
					content = toString( cast(dchar[]) swapBytes( str, 4 ) );
					return content;
				}
				else if( BELE == 2 )
				{
					_encoding = 10; // UTF-32LE without BOM
					content = toString( cast(dchar[]) str );
					return content;
				}			

				BELE = isUTF16WithouBOM( str );
				if( BELE == 1 )
				{
					_encoding = 11; // UTF-16BE without BOM
					content = toString( cast(wchar[]) swapBytes( str, 2 ) );
					return content;
				}
				else if( BELE == 2 )
				{
					_encoding = 12; // UTF-16LE without BOM
					content = toString( cast(wchar[]) str );
					return content;
				}
				
				if( isUTF8WithouBOM( str ) )
				{
					_encoding = Encoding.UTF_8N;
					content = cast(char[]) str;
					return content;
				}
				else
				{
					_encoding = Encoding.Unknown;
					version(Windows)
					{
						if( !CodePage.isAscii(cast(char[]) str ) ) // MBCS
						{
							char[] _text;
							_text.length = 2 * str.length;
							content = CodePage.from( cast(char[]) str, _text, 0 );
						}
						else
							content = cast(char[]) str;
					}
					else
						content = cast(char[]) str;
						
					//return content;
				}
			}
			else
			{
				// CHECK BOM
				bool bBOM = true;
				//auto str = cast(ubyte[]) File.get( fullPath );
				
				void* cd = null;
				
				if( str.length > 3 )
				{
					//UTF32 with BOM
					if( str[0] == 0xFF && str[1] == 0xFE && str[2] == 0x00 && str[3] == 0x00 )
					{
						// UTF32-LE
						cd = GLOBAL.iconv_open("UTF-8","UTF-32LE");
						//stdout("UTF-32LE").newline;
						_encoding = Encoding.UTF_32LE;
					}
					else if( str[0] == 0x00 && str[1] == 0x00 && str[2] == 0xFE && str[3] == 0xFF )
					{
						// UTF32-BE
						cd = GLOBAL.iconv_open("UTF-8","UTF-32BE");	
						//stdout("UTF-32BE").newline;
						_encoding = Encoding.UTF_32BE;
					}
				}
				
				if( cd == null )
				{
					if( str.length > 2 )
					{
						//UTF8 with BOM
						if( str[0] == 0xEF && str[1] == 0xBB && str[2] == 0xBF )
						{
							// UTF-8
							//cd = GLOBAL.iconv_open("UTF-8","UTF-8");
							//stdout("UTF-8").newline;
							_encoding = Encoding.UTF_8;
						}
					}
				}
				
				if( _encoding != Encoding.UTF_8 )
				{
					if( cd == null )
					{
						if( str.length > 1 )
						{
							//UTF16 with BOM
							if( str[0] == 0xFF && str[1] == 0xFE)
							{
								// UTF16-LE
								cd = GLOBAL.iconv_open("UTF-8","UTF-16LE");
								//stdout("UTF-16LE").newline;
								_encoding = Encoding.UTF_16LE;
							}
							else if( str[0] == 0xFE && str[1] == 0xFF)
							{
								// UTF16-BE
								cd = GLOBAL.iconv_open("UTF-8","UTF-16BE");	
								//stdout("UTF-16BE").newline;
								_encoding = Encoding.UTF_16BE;
							}
						}
					}			

					// Check Without BOM
					if( cd == null )
					{
						int BELE = isUTF32WithouBOM( str );
						if( BELE == 1 )
						{
							cd = GLOBAL.iconv_open("UTF-8","UTF-32BE");	
							//stdout("UTF-32BE without BOM").newline;
							_encoding = 9;
							bBOM = false;
						}
						else if( BELE == 2 )
						{
							cd = GLOBAL.iconv_open("UTF-8","UTF-32LE");	
							//stdout("UTF-32LE without BOM").newline;
							_encoding = 10;
							bBOM = false;
						}
						
						if( cd == null )
						{
							BELE = isUTF16WithouBOM( str );
							if( BELE == 1 )
							{
								cd = GLOBAL.iconv_open("UTF-8","UTF-16BE");	
								//stdout("UTF-16BE without BOM").newline;
								_encoding = 11;
								bBOM = false;
							}
							else if( BELE == 2 )
							{
								cd = GLOBAL.iconv_open("UTF-8","UTF-16LE");	
								//stdout("UTF-16LE without BOM").newline;
								_encoding = 12;
								bBOM = false;
							}
						}
						
						if( cd == null )
						{
							if( isUTF8WithouBOM( str ) )
							{
								bBOM = false;
								//cd = GLOBAL.iconv_open("UTF-8","UTF-8");
								//stdout("UTF-8 without BOM").newline;
								_encoding = Encoding.UTF_8N;
							}
							else
							{
								_encoding = Encoding.Unknown;
							}
						}
					}
				}

				
				// Trans Data
				if( cd != null )
				{
					void* inp = str.ptr;
					size_t inbytesleft = str.length;
					
					char[] outBuffer;
					outBuffer.length = inbytesleft;
					size_t outbytesleft = outBuffer.length;
					void* outp = outBuffer.ptr;
					size_t res = GLOBAL.iconv(cd,&inp,&inbytesleft,&outp,&outbytesleft);

					//Stdout(outbytesleft).newline;
					if( bBOM )
						content = outBuffer[3..$-outbytesleft]; // UTF-8 with BOM (3 bytes)
					else
						content = outBuffer[0..$-outbytesleft]; // UTF-8 without BOM
						
					GLOBAL.iconv_close( cd );
						
					//return content;
				}
				else
				{
					if( _encoding == Encoding.UTF_8 )
					{
						content = cast(char[]) str[3..$]; // UTF-8 with BOM (3 bytes)
					}
					else
					{
						if( _encoding == Encoding.UTF_8N )
							content = cast(char[]) str;
						else
						{
							version(Windows)
							{
								if( !CodePage.isAscii(cast(char[]) str ) ) // MBCS
								{
									char[] _text;
									_text.length = 2 * str.length;
									content = CodePage.from( cast(char[]) str, _text, 0 );
								}
								else
									content = cast(char[]) str;
							}
							else
								content = cast(char[]) str;
						}
					}
					
					//return content;
				}
			
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "Bug", toStringz( "FileAction.loadFile() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
			throw e;
		}

		return content;
	}
	

	static bool saveFile( char[] fullPath, char[] data, int encoding = Encoding.UTF_8 )
	{
		try
		{
			switch( encoding )
			{
				case Encoding.Unknown:
					version( Windows )
					{
						char[] _text;
						_text.length = 2 * data.length;
						char[] result = CodePage.into( data, _text );
						File.set( fullPath, result );
					}
					else
					{
						scope file = new UnicodeFile!(char)( fullPath, Encoding.UTF_8 );
						file.write( data , false );
					}
					break;
				
				case Encoding.UTF_8N:
					scope file = new UnicodeFile!(char)( fullPath, Encoding.UTF_8 );
					file.write( data , false );
					break;

				case Encoding.UTF_8:
					scope file = new UnicodeFile!(char)( fullPath, Encoding.UTF_8 );
					file.write( data , true );
					break;

				case Encoding.UTF_16:
				case Encoding.UTF_16BE:
					scope file = new UnicodeFile!(wchar)( fullPath, Encoding.UTF_16BE );
					file.write( toString16( data ), true );
					break;

				case Encoding.UTF_16LE:
					scope file = new UnicodeFile!(wchar)( fullPath, Encoding.UTF_16LE );
					file.write( toString16( data ) , true );
					break;

				
				case Encoding.UTF_32BE:
					scope file = new UnicodeFile!(dchar)( fullPath, Encoding.UTF_32BE );
					file.write( toString32( data ) , true );
					break;

				case Encoding.UTF_32LE:
					scope file = new UnicodeFile!(dchar)( fullPath, Encoding.UTF_32LE );
					file.write( toString32( data ) , true );
					break;

				case 9:
					scope file = new UnicodeFile!(dchar)( fullPath, Encoding.UTF_32BE );
					file.write( toString32( data ) , false );
					break;

				case 10:
					scope file = new UnicodeFile!(dchar)( fullPath, Encoding.UTF_32LE );
					file.write( toString32( data ) , false );
					break;

				case 11:
					scope file = new UnicodeFile!(wchar)( fullPath, Encoding.UTF_16BE );
					file.write( toString16( data ) , false );
					break;

				case 12:
					scope file = new UnicodeFile!(wchar)( fullPath, Encoding.UTF_16LE );
					file.write( toString16( data ) , false );
					break;


				default:
					scope file = new UnicodeFile!(char)( fullPath, Encoding.UTF_8 );
					file.write( data, true );
			}
		}
		catch( Exception e )
		{
			IupMessage( "FileAction.saveFile Error", toStringz( e.toString ) );
			return false;
		}

		return true;
	}
	
}


struct DocumentTabAction
{
private:
	import scintilla;
	import tango.io.FilePath;
	
public:
	static int tabChangePOS( Ihandle* ih, int new_pos )
	{
		try
		{
			Ihandle* _child = IupGetChild( ih, new_pos );
			if( _child != null )
			{
				CScintilla cSci = actionManager.ScintillaAction.getCScintilla( _child );
				
				if( cSci !is null )
				{
					StatusBarAction.update( _child );
					//IupSetInt( ih, "VALUEPOS" , new_pos );
					IupSetFocus( _child );
					IupScintillaSendMessage( _child, 2380, 1, 0 ); // SCI_SETFOCUS 2380

					// Marked the trees( FileList & ProjectTree )
					IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
					
					if( !( actionManager.ScintillaAction.toTreeMarked( cSci.getFullPath() ) & 2 ) )
					{
						GLOBAL.statusBar.setPrjName( "                                            " );
					}/*
					else
					{
						GLOBAL.statusBar.setPrjName( null, true );
					}
					*/
					return IUP_DEFAULT;
				}
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "tabChangePOS", toStringz( e.toString() ) );
		}		

		return IUP_DEFAULT;
	}
	

	static void resetTip()
	{
		for( int i = 0; i < IupGetInt( GLOBAL.activeDocumentTabs, "COUNT" ); ++ i )
		{
			Ihandle* _ih = IupGetChild( GLOBAL.activeDocumentTabs, i );
			if( _ih != null )
			{
				auto _cSci = ScintillaAction.getCScintilla( _ih );
				if( _cSci !is null ) IupSetAttributeId( GLOBAL.activeDocumentTabs , "TABTIP", i, _cSci.getFullPath_IupString.toCString );
			}
		}
	}
	
	static int setFocus( Ihandle* ih )
	{
		if( ih != null )
		{
			IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE" , cast(char*) ih );
			//IupScintillaSendMessage( ih, 2380, 1, 0 ); // SCI_SETFOCUS 2380
			IupSetFocus( ih );
			return IUP_CONTINUE;
		}
		
		return IUP_DEFAULT;
	}
	
	static int setFocus( int pos )
	{
		if( pos >= 0 && pos <= IupGetInt( GLOBAL.activeDocumentTabs, "COUNT" ) )
		{
			IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" , pos );
			IupScintillaSendMessage( IupGetChild( GLOBAL.activeDocumentTabs, pos ), 2380, 1, 0 ); // SCI_SETFOCUS 2380
			//IupSetFocus( cast(Ihandle*) IupGetChild( GLOBAL.activeDocumentTabs, pos ) );
			return IUP_CONTINUE;
		}
		
		return IUP_DEFAULT;
	}
	
	
	static void setTabItemDocumentImage( Ihandle* workDocumentTab, int newDocumentPos, char[] _fullPath )
	{
		scope mypath = new FilePath( _fullPath );
		
		version(FBIDE)
		{
			if( lowerCase( mypath.ext )== "bas" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bas" );
			}
			else if( lowerCase( mypath.ext )== "bi" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bi" );
			}
			else
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_txt" );
			}
		}
		version(DIDE)
		{
			if( lowerCase( mypath.ext )== "d" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bas" );
			}
			else if( lowerCase( mypath.ext )== "di" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bi" );
			}
			else
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_txt" );
			}
		}	
	}
	
	static Ihandle* getDocumentTabs( Ihandle* sci )
	{
		int documentPos = IupGetChildPos( GLOBAL.documentTabs, sci );
		
		if( documentPos > -1 )
		{
			return GLOBAL.documentTabs;
		}
		else
		{
			documentPos = IupGetChildPos( GLOBAL.documentTabs_Sub, sci );
			if( documentPos > -1 ) return GLOBAL.documentTabs_Sub;
		}
		
		return null;
	}
	
	static int getDocumentPos( Ihandle* sci )
	{
		int documentPos = IupGetChildPos( GLOBAL.documentTabs, sci );
		
		if( documentPos > -1 )
		{
			return documentPos;
		}
		else
		{
			documentPos = IupGetChildPos( GLOBAL.documentTabs_Sub, sci );
			if( documentPos > -1 ) return documentPos;
		}
		
		return -1;
	}
	
	static Ihandle* getDocumentAndPos( Ihandle* sci, out int documentPos = -1 )
	{
		documentPos = IupGetChildPos( GLOBAL.documentTabs, sci );
		
		if( documentPos > -1 )
		{
			return GLOBAL.documentTabs;
		}
		else
		{
			documentPos = IupGetChildPos( GLOBAL.documentTabs_Sub, sci );
			if( documentPos > -1 ) return GLOBAL.documentTabs;
		}
		
		return null;
	}
	
	static void moveBetweenTabs( Ihandle* srcTabs, Ihandle* DestTabs )
	{
		for( int i = IupGetChildCount( srcTabs ) - 1; i >= 0; --i )
		{
			Ihandle* dragHandle = IupGetChild( srcTabs, i );
			auto beMoveDocumentCSci = ScintillaAction.getCScintilla( dragHandle );

			if( beMoveDocumentCSci !is null )
			{
				//Ihandle* dragHandle = IupGetChild( GLOBAL.documentTabs, IupGetInt( GLOBAL.documentTabs, "VALUEPOS" ) );
				Ihandle* dropHandle = IupGetChild( DestTabs, 0 );
				
				if( dragHandle != null )
				{
					int newDocumentPos = 0;
					if( IupGetChildCount( DestTabs ) == 0 )
					{
						IupReparent( dragHandle, DestTabs, null );
						newDocumentPos = IupGetChildCount( DestTabs ) - 1;
					}
					else
					{
						IupReparent( dragHandle, DestTabs, IupGetChild( DestTabs, 0 ) );
					}
					IupSetAttributeId( DestTabs, "TABTITLE", newDocumentPos, beMoveDocumentCSci.getTitleHandle.toCString );
					IupSetAttributeId( DestTabs, "TABTIP", newDocumentPos, beMoveDocumentCSci.getFullPath_IupString.toCString );
				}				
			}		
		}
		
		IupRefresh( DestTabs );
	}
	
	static void setActiveDocumentTabs( Ihandle* _tabs )
	{
		GLOBAL.activeDocumentTabs = _tabs;
		
		if( GLOBAL.activeDocumentTabs == GLOBAL.documentTabs )
		{
			IupSetAttribute( GLOBAL.documentTabs, "SHOWLINES", "YES" );
			IupSetAttribute( GLOBAL.documentTabs_Sub, "SHOWLINES", "NO" );
		}
		else if( GLOBAL.activeDocumentTabs == GLOBAL.documentTabs_Sub )
		{
			IupSetAttribute( GLOBAL.documentTabs, "SHOWLINES", "NO" );
			IupSetAttribute( GLOBAL.documentTabs_Sub, "SHOWLINES", "YES" );
		}
	}
	
	static void updateTabsLayout()
	{
		if( IupGetChildCount( GLOBAL.documentTabs ) == 0 )
		{
			if( IupGetChildCount( GLOBAL.documentTabs_Sub ) > 0 )
				DocumentTabAction.moveBetweenTabs( GLOBAL.documentTabs_Sub, GLOBAL.documentTabs );
			else
				IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 0 );

			DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs );
		}
		
		if( IupGetChildCount( GLOBAL.documentTabs_Sub ) == 0 )
		{
			DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs );
			
			if( GLOBAL.editorSetting01.RotateTabs == "OFF" )
			{
				if( IupGetInt( GLOBAL.documentSplit, "BARSIZE" ) > 0 )
				{
					GLOBAL.documentSplit_value = IupGetInt( GLOBAL.documentSplit, "VALUE" );
					IupSetAttributes( GLOBAL.documentSplit, "VALUE=1000,BARSIZE=0" );
				}
			}
			else
			{
				if( IupGetInt( GLOBAL.documentSplit2, "BARSIZE" ) > 0 )
				{
					GLOBAL.documentSplit2_value = IupGetInt( GLOBAL.documentSplit2, "VALUE" );
					IupSetAttributes( GLOBAL.documentSplit2, "VALUE=1000,BARSIZE=0" );
				}
			}			
		
			DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, IupGetInt( GLOBAL.documentTabs, "VALUEPOS" ) );
		}
		
		if( !GLOBAL.scintillaManager.length )
		{
			Ihandle* _undo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Undo" );
			if( _undo != null ) IupSetAttribute( _undo, "ACTIVE", "NO" ); // SCI_CANUNDO 2174

			Ihandle* _redo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Redo" );
			if( _redo != null ) IupSetAttribute( _redo, "ACTIVE", "NO" ); // SCI_CANREDO 2016
		}		
	}
	
	static char[] getBeforeWord( Ihandle* iupSci, int pos )
	{
		// Check before targetText word.......
		char[]	beforeWord;
		for( int j = pos; j >= 0; --j )
		{
			char[] _s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
			int key = cast(int) _s[0];
			
			if( key >= 0 && key <= 127 )
			{
				if( key == 13 || _s == ":" || _s == "\n" )
				{
					break;
				}
				else if( _s == " " || _s == "\t" )
				{
					if( beforeWord.length ) break;
				}
				else
				{
					beforeWord ~= _s;
				}
			}
		}
		
		return beforeWord.reverse;
	}
	
	static char[] getAfterWord( Ihandle* iupSci, int pos )
	{
		// Check after targetText word.......
		char[]	afterWord;
		for( int j = pos; j < IupGetInt( iupSci, "COUNT" ); ++j )
		{
			char[] _s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
			int key = cast(int) _s[0];
			
			if( key >= 0 && key <= 127 )
			{
				if( key == 13 || _s == ":" || _s == "\n" )
				{
					break;
				}
				else if( _s == " " || _s == "\t" )
				{
					if( afterWord.length ) break;
				}
				else
				{
					afterWord ~= _s;
				}
			}
		}
		
		return afterWord;
	}
	
	static char[] getTailWord( Ihandle* iupSci, int pos )
	{
		// Check after targetText word.......
		char[]	tailWord;
		int line = ScintillaAction.getLinefromPos( iupSci, pos );
		int lineEndPos = cast(int) IupScintillaSendMessage( iupSci, 2136, line, 0 ); // SCI_GETLINEENDPOSITION 2136
		
		for( int j = --lineEndPos; j >= 0; --j )
		{
			char[] _s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
			int key = cast(int) _s[0];
			
			if( key >= 0 && key <= 127 )
			{
				if( key == 13 || _s == ":" || _s == "\n" )
				{
					break;
				}
				else if( _s == " " || _s == "\t" )
				{
					if( tailWord.length ) break;
				}
				else
				{
					tailWord ~= _s;
				}
			}
		}
		
		return tailWord.reverse;
	}	
	
	// hasTail = -1  Whatever, hasTail = 0  No Tail, hasTail = 1  Tail
	
	static int getKeyWordCount( Ihandle* iupSci, char[] target, char[] beforeWord, char[] tailWord = "" )
	{
		int count;
		
		// Search Document
		IupSetAttribute( iupSci, "SEARCHFLAGS", "WHOLEWORD" );
		IupSetInt( iupSci, "TARGETSTART", 0 );
		IupSetInt( iupSci, "TARGETEND", -1 );
		
		scope _t = new IupString( target );
		
		int findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, target.length, cast(int) _t.toCString ); // SCI_SEARCHINTARGET = 2197,
		
		while( findPos != -1 )
		{
			if( getBeforeWord( iupSci, findPos - 1 ) == lowerCase( beforeWord ) )
			{
				if( tailWord.length )
				{
					if( getTailWord( iupSci, findPos ) == lowerCase(tailWord) ) count++;
				}
				else
					count++;
			}
			
			IupSetInt( iupSci, "TARGETSTART", findPos + target.length );
			IupSetInt( iupSci, "TARGETEND", -1 );
			findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, target.length, cast(int) _t.toCString ); // SCI_SEARCHINTARGET = 2197,
		}		
		
		return count;
	}
	
	
	static bool isDoubleClick( char* status )
	{
		char[] _s = fromStringz( status ).dup;
		if( _s.length > 5 )
		{
			if( _s[5] == 'D' ) return true; // Double Click
		}
		
		return false;
	}
}


struct ScintillaAction
{
private:
	import tango.io.UnicodeFile, tango.io.FilePath, dialogs.fileDlg, parser.ast;
	import scintilla, menu;
	import parser.scanner,  parser.token, parser.parser, parser.autocompletion;

	import tango.core.Thread, Path = tango.io.Path;
	
	static bool[char[]] preParsedIncludes;

public:
	static bool newFile( char[] fullPath, Encoding _encoding = Encoding.UTF_8N, char[] existData = null, bool bCreateActualFile = true, int insertPos = -1 )
	{
		// FullPath had already opened
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
		{
			IupMessage( "Waring!!", toStringz( fullPath ~ "\n has already exist!" ) );
			return false;
		}

		auto 	_sci = new CScintilla( fullPath, null, _encoding, insertPos );
		if( bCreateActualFile ) FileAction.newFile( fullPath );
		//_sci.setEncoding( _encoding );
		GLOBAL.scintillaManager[fullPathByOS(fullPath)] = _sci;

		// Set documentTabs to visible
		if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "YES" );

		// Set new tabitem to focus
		IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*)_sci.getIupScintilla );
		IupSetFocus( _sci.getIupScintilla );

		//StatusBarAction.update();

		if( existData.length) _sci.setText( existData );

		scope f = new FilePath( fullPath );

		version(FBIDE)
		{
			if( tools.isParsableExt( f.ext, 3 ) )
			{
				//Parser
				GLOBAL.outlineTree.loadFile( fullPath );
			}
		}
		version(DIDE)
		{
			if( lowerCase( f.ext() ) == "d" || lowerCase( f.ext() ) == "di" )
			{
				//Parser
				GLOBAL.outlineTree.loadFile( fullPath );
			}
		}

		if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );

		StatusBarAction.update();

		if( !( toTreeMarked( fullPath ) & 2 ) )
		{
			GLOBAL.statusBar.setPrjName( "                                            " );
		}
		else
		{
			GLOBAL.statusBar.setPrjName( null, true );
		}
			
		return true;
	}
	
	static bool openFile( char[] fullPath, int lineNumber = -1 )
	{
		fullPath =  Path.normalize( fullPath );
		
		// FullPath had already opened
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
		{
			Ihandle* ih = GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla;
			
			Ihandle* _documentTabs = DocumentTabAction.getDocumentTabs( ih );
			if( _documentTabs != null )	DocumentTabAction.setActiveDocumentTabs( _documentTabs ); else return false;

			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
			
			DocumentTabAction.setFocus( ih );
			
			if( lineNumber > 0 )
			{
				IupSetAttributeId( ih, "ENSUREVISIBLE", --lineNumber, "ENFORCEPOLICY" );
				IupSetInt( ih, "CARET", lineNumber );
			}
			StatusBarAction.update();

			if( !( toTreeMarked( fullPath ) & 2 ) )
			{
				GLOBAL.statusBar.setPrjName( "                                            " );
			}/*
			else
			{
				GLOBAL.statusBar.setPrjName( null, true );
			}*/
			
			return true;
		}

		try
		{
			if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
			
			scope filePath = new FilePath( fullPath );
			if( !filePath.exists ) return false;

			Encoding		_encoding;
			char[] 	_text = FileAction.loadFile( fullPath, _encoding );
			
			
			
			// Parser
			if( fullPathByOS(fullPath) in GLOBAL.parserManager )
			{
				Ihandle* _tree = GLOBAL.outlineTree.getTree( fullPath );
				if( _tree == null )	GLOBAL.outlineTree.createTree( GLOBAL.parserManager[fullPathByOS(fullPath)] );
				
				GLOBAL.outlineTree.changeTree( fullPath );
				
				// Load and parse to fill up includesMarkContainer, for speed-up
				if( !( fullPathByOS(fullPath) in preParsedIncludes ) )
				{
					preParsedIncludes[fullPathByOS(fullPath)] = true;
					AutoComplete.cleanIncludeContainer();
					AutoComplete.setPreLoadContainer( GLOBAL.parserManager[fullPathByOS(fullPath)] );
				}
			}
			else
			{
				auto pParseTree = GLOBAL.outlineTree.createParserByText( fullPath, _text );
				
				// Preload
				if( pParseTree !is null ) 
				{
					// Load and parse to fill up includesMarkContainer, for speed-up
					//if( !( fullPathByOS(fullPath) in preParsedIncludes ) )
					//{
						preParsedIncludes[fullPathByOS(fullPath)] = true;
						AutoComplete.cleanIncludeContainer();
						AutoComplete.setPreLoadContainer( GLOBAL.parserManager[fullPathByOS(fullPath)] );
					//}
				}
			}
			
			
			
			auto 	_sci = new CScintilla( fullPath, _text, _encoding );
			GLOBAL.scintillaManager[fullPathByOS(fullPath)] = _sci;

			// Set documentTabs to visible
			if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "YES" );
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
			
			// Set new tabitem to focus
			if( DocumentTabAction.setFocus( _sci.getIupScintilla ) == IUP_DEFAULT ) return false;
			IupScintillaSendMessage( _sci.getIupScintilla, 2380, 1, 0 ); // SCI_SETFOCUS 2380
			
			int		fileStatusPos = -1;
			bool	bDirectGotoLine = lineNumber < 0 ? false : true;
			
			if( GLOBAL.editorSetting00.DocStatus == "ON" )
			{
				if( fullPath in GLOBAL.fileStatusManager )
				{
					foreach( int _pos, int value; GLOBAL.fileStatusManager[fullPath] )
					{
						if( _pos == 0 )
						{
							if( !bDirectGotoLine ) lineNumber = ScintillaAction.getLinefromPos( _sci.getIupScintilla, value ); else lineNumber --;
							fileStatusPos = value;
						}
						else
						{
							//IupScintillaSendMessage( _sci.getIupScintilla, 2229, value, 0 ); //  SCI_SETFOLDEXPANDED 2229
							IupSetInt( _sci.getIupScintilla, "FOLDTOGGLE", value );
						}
					}
				}
			}			
			
			if( fileStatusPos > -1 )
			{
				IupSetAttributeId( _sci.getIupScintilla, "ENSUREVISIBLE", lineNumber, "ENFORCEPOLICY" );
				if( !bDirectGotoLine ) IupSetInt( _sci.getIupScintilla, "CARETPOS", fileStatusPos ); else IupSetInt( _sci.getIupScintilla, "CARET", lineNumber );
			}
			else
			{
				if( lineNumber > -1 )
				{
					IupSetAttributeId( _sci.getIupScintilla, "ENSUREVISIBLE", --lineNumber, "ENFORCEPOLICY" );
					IupSetInt( _sci.getIupScintilla, "CARET", lineNumber );
				}
			}
			//StatusBarAction.update();

			if( !( toTreeMarked( fullPath ) & 2 ) )
			{
				GLOBAL.statusBar.setPrjName( "                                            " );
			}/*
			else
			{
				GLOBAL.statusBar.setPrjName( null, true );
			}*/		


			StatusBarAction.update();
			
			return true;
		}
		catch( Exception e )
		{
			//GLOBAL.IDEMessageDlg.print( "openFile() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			IupMessage( "Bug", toStringz( "openFile() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );

			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
			{
				auto _sci = GLOBAL.scintillaManager[fullPathByOS(fullPath)];
				if( _sci !is null ) delete _sci;
					
				GLOBAL.scintillaManager.remove( fullPathByOS(fullPath) );
			}
		}

		return false;
	}

	static int toTreeMarked( char[] fullPath, int _switch = 7 )
	{
		int result;
		
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{
			CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(fullPath)];
			if( cSci !is null )
			{
				/*
				if( _switch & 1 ) // Mark the FileList
				{
					GLOBAL.fileListTree.markItem( cSci.getFullPath );
					result = result | 1;
				}
				*/
				
				if( _switch & 4 ) // Mark the OutlineTree
				{
					GLOBAL.outlineTree.changeTree( cSci.getFullPath );
					result = result | 4;
				}				

				if( _switch & 2 ) // Mark the ProjectTree
				{
					
					int nodeCount = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
					for( int id = 1; id <= nodeCount; id++ )
					{
						char[] s = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
						if( fullPathByOS(s) == fullPathByOS(fullPath) )
						{
							IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
							IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );
							GLOBAL.statusBar.setPrjName( null, true );
							result = result | 2;
							break;
						}
					}
				}
			}
		}
		
		return result;
	}

	static Ihandle* getActiveIupScintilla()
	{
		int pos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
		if( pos < 0 ) return null;
		
		return IupGetChild( GLOBAL.activeDocumentTabs, pos );
	}

	static CScintilla getActiveCScintilla()
	{
		Ihandle* iupSci = getActiveIupScintilla();
		if( iupSci != null )
		{
			foreach( CScintilla _sci; GLOBAL.scintillaManager )
			{
				if( _sci.getIupScintilla == iupSci ) return _sci;
			}
		}

		return null;
	}

	static CScintilla getCScintilla( Ihandle* iupSci )
	{
		foreach( CScintilla _sci; GLOBAL.scintillaManager )
		{
			if( _sci.getIupScintilla == iupSci )
			{
				return _sci;
			}
		}

		return null;
	}

	static void gotoLine( char[] fileName, int lineNum )
	{
		openFile( fileName, lineNum );
	}
	
	static bool getModifyByTitle( CScintilla cSci )
	{
		if( cSci !is null )
		{
			char[] _title = cSci.getTitle();
			if( _title.length )
			{
				if( _title[0] == '*' ) return true;
			}
		}
		return false;
	}
	
	static int getModify( CScintilla cSci )
	{
		if( cSci !is null )	return cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2159, 0, 0 ); // SCI_GETMODIFY = 2159
		return 0;
	}

	static int getModify( Ihandle* ih )
	{
		if( ih != null ) return cast(int) IupScintillaSendMessage( ih, 2159, 0, 0 ); // SCI_GETMODIFY = 2159
		return 0;
	}

	static void closeAndMoveDocument( CScintilla cSci, bool bShowNew = false )
	{
		if( cSci !is null )
		{
			if( !bShowNew )
			{
				// Change Tree Selection and move new tab pos to left 1
				int oldPos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
				int newPos = 0;
				if( oldPos > 0 )
				{
					newPos = oldPos - 1;
					IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", newPos );
				}
				else
				{
					newPos = 1;
					IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", newPos );
				}
				
				actionManager.DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, newPos );
			}
			
			//IupDestroy( cSci.getIupScintilla );
			//GLOBAL.fileListTree.removeItem( cSci );
			//GLOBAL.scintillaManager.remove( fullPathByOS( cSci.getFullPath ) );
			//GLOBAL.outlineTree.cleanTree( cSci.getFullPath );
			delete cSci;
			IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", null );
			IupRefresh( GLOBAL.activeDocumentTabs );
			
			DocumentTabAction.updateTabsLayout();
		}
	}

	static int closeDocument( char[] fullPath, int pos = -1 )
	{
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{
			CScintilla	cSci		= GLOBAL.scintillaManager[fullPathByOS(fullPath)];
			
			if( cSci !is null )
			{
				//if( ScintillaAction.getModify( iupSci ) != 0 )
				if( ScintillaAction.getModifyByTitle( cSci ) )
				{
					if( pos > -1 ) IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" , pos ); 
					scope cStringDocument = new IupString( "\"" ~ fullPath ~ "\"\n" ~ GLOBAL.languageItems["bechange"].toDString() );
					
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=3,BUTTONS=YESNOCANCEL" );
					IupSetAttribute( messageDlg, "VALUE", cStringDocument.toCString );
					IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString );
					IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
					//int button = IupAlarm( toStringz( GLOBAL.languageItems["alarm"] ), GLOBAL.cString.convert( "\"" ~ fullPath ~ "\"\n" ~ GLOBAL.languageItems["bechange"] ), toStringz( GLOBAL.languageItems["yes"] ), toStringz( GLOBAL.languageItems["no"] ), toStringz( GLOBAL.languageItems["cancel"] ) );
					int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );
					if( button == 3 )
					{
						IupSetFocus( cSci.getIupScintilla );
						return IUP_IGNORE;
					}
					if( button == 1 )
					{
						if( fullPath.length >= 7 )
						{
							if( fullPath[0..7] == "NONAME#" )
							{
								saveAs( cSci, true, false );
								return IUP_DEFAULT;
							}
						}

						cSci.saveFile();
					}
				}

				closeAndMoveDocument( cSci, false );
			}
		}

		StatusBarAction.update();
		DocumentTabAction.resetTip();

		return IUP_DEFAULT;
	}

	static int closeOthersDocument( char[] fullPath )
	{
		char[][] KEYS;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( cSci !is null )
			{
				if( fullPathByOS(cSci.getFullPath) != fullPathByOS(fullPath) )
				{
					Ihandle* iupSci = cSci.getIupScintilla;
					
					if( DocumentTabAction.getDocumentTabs( iupSci ) != GLOBAL.activeDocumentTabs ) continue;
					
					//if( ScintillaAction.getModify( iupSci ) != 0 )
					if( ScintillaAction.getModifyByTitle( cSci ) )
					{
						IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*) iupSci );
						
						scope cStringDocument = new IupString( "\"" ~ cSci.getFullPath() ~ "\"\n" ~ GLOBAL.languageItems["bechange"].toDString() );
						
						Ihandle* messageDlg = IupMessageDlg();
						IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=3,BUTTONS=YESNOCANCEL" );
						IupSetAttribute( messageDlg, "VALUE", cStringDocument.toCString );
						IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString );
						IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
						int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );
						//int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ cSci.getFullPath() ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
						if( button == 3 )
						{
							IupSetFocus( iupSci );
							return IUP_DEFAULT;
						}
						else if( button == 2 )
						{
							KEYS ~= cSci.getFullPath;
						}					
						else if( button == 1 )
						{
							bool bNoNameFile;
							if( cSci.getFullPath.length >= 7 )
							{
								if( cSci.getFullPath[0..7] == "NONAME#" )
								{
									saveAs( cSci, false, false );
									KEYS ~= cSci.getFullPath;
									bNoNameFile = true;
								}
							}

							if( !bNoNameFile )
							{
								cSci.saveFile();
								KEYS ~= cSci.getFullPath;
							}
						}
					}
					else
					{
						KEYS ~= cSci.getFullPath;
					}
				}
			}
		}

		foreach( char[] s; KEYS )
		{
			if( fullPathByOS(s) in GLOBAL.scintillaManager )
			{
				CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(s)];
				if( cSci !is null )
				{
					//GLOBAL.fileListTree.removeItem( cSci );
					//GLOBAL.outlineTree.cleanTree( cSci.getFullPath );
					//IupDestroy( cSci );				
					delete cSci;
				}

				//GLOBAL.scintillaManager.remove( fullPathByOS(s) );
			}
		}		

		StatusBarAction.update();
		DocumentTabAction.resetTip();

		return IUP_DEFAULT;
	}	

	static int closeAllDocument( Ihandle* _activeTabs = null )
	{
		if( _activeTabs == null ) _activeTabs = GLOBAL.activeDocumentTabs;
		
		if( _activeTabs == null ) return -1;
		
		
		char[][] 	KEYS;
		bool 		bCancel;		
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( cSci !is null )
			{
				Ihandle* iupSci = cSci.getIupScintilla;
				
				if( IupGetChildPos( _activeTabs, iupSci ) != -1 )
				{
					if( ScintillaAction.getModifyByTitle( cSci ) )
					{
						IupSetAttribute( _activeTabs, "VALUE_HANDLE", cast(char*) iupSci );
						
						scope cStringDocument = new IupString( "\"" ~ cSci.getFullPath() ~ "\"\n" ~ GLOBAL.languageItems["bechange"].toDString() );
						
						Ihandle* messageDlg = IupMessageDlg();
						IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=3,BUTTONS=YESNOCANCEL" );
						IupSetAttribute( messageDlg, "VALUE", cStringDocument.toCString );
						IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString );
						IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
						int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );				
						if( button == 3 ) // Cancel the Close All action...
						{
							return IUP_IGNORE;
						}
						else if( button == 2 )
						{
							KEYS ~= cSci.getFullPath;
						}
						else if( button == 1 )
						{
							bool bNoNameFile;
							if( cSci.getFullPath.length >= 7 )
							{
								if( cSci.getFullPath[0..7] == "NONAME#" )
								{
									saveAs( cSci, false, false );
									KEYS ~= cSci.getFullPath;
									bNoNameFile = true;
								}
							}

							if( !bNoNameFile )
							{
								KEYS ~= cSci.getFullPath;
								cSci.saveFile();
							}
						}
					}
					else
					{
						KEYS ~= cSci.getFullPath;
					}
				}
			}
		}

		foreach( char[] s; KEYS )
		{
			if( fullPathByOS(s) in GLOBAL.scintillaManager )
			{
				CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(s)];
				if( cSci !is null )
				{
					//GLOBAL.fileListTree.removeItem( cSci );
					//GLOBAL.outlineTree.cleanTree( cSci.getFullPath );
					//IupDestroy( cSci );				
					delete cSci;
				}

				//GLOBAL.scintillaManager.remove( fullPathByOS(s) );
			}
		}
		
		DocumentTabAction.updateTabsLayout();

		StatusBarAction.update();
		DocumentTabAction.resetTip();
		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", null );
		
		return IUP_DEFAULT;
	}

	static bool saveFile( CScintilla cSci, bool bForce = false )
	{
		if( cSci is null ) return false;
		
		try
		{
			char[] fullPath = cSci.getFullPath();
			//if( ScintillaAction.getModify( cSci.getIupScintilla ) != 0 || bForce )
			
			if( fullPath.length >= 7 )
			{
				if( fullPath[0..7] == "NONAME#" )
				{
					IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*) cSci.getIupScintilla );
					int oldPos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );						
					return saveAs( cSci, true, true, oldPos );
				}
			}
			
			if( ScintillaAction.getModifyByTitle( cSci ) || bForce )
			{
				cSci.saveFile();
				GLOBAL.outlineTree.refresh( cSci ); //Update Parser
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "actionManager", toStringz( "saveFile Error:" ~ cSci.getFullPath ) );
			return false;
		}
		
		IupSetFocus( cSci.getIupScintilla );
		return true;
	}

	static bool saveAs( CScintilla cSci, bool bCloseOld = false, bool bShowNew = true, int insertPos = -1 )
	{
		if( cSci is null ) return false;

		try
		{
			version(FBIDE)	scope dlg = new CFileDlg( GLOBAL.languageItems["saveas"].toDString() ~ "...", GLOBAL.languageItems["basfile"].toDString() ~ "|*.bas|" ~  GLOBAL.languageItems["bifile"].toDString() ~ "|*.bi|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*", "SAVE", "NO", cSci.getFullPath );//"Source File|*.bas|Include File|*.bi" );
			version(DIDE)	scope dlg = new CFileDlg( GLOBAL.languageItems["saveas"].toDString() ~ "...", GLOBAL.languageItems["basfile"].toDString() ~ "|*.d|" ~  GLOBAL.languageItems["bifile"].toDString() ~ "|*.di|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*", "SAVE", "NO", cSci.getFullPath );//"Source File|*.bas|Include File|*.bi" );

			char[] fullPath = dlg.getFileName();
			switch( dlg.getFilterUsed )
			{
				case "1":
					version(FBIDE)
					{
						if( fullPath.length > 4 )
						{
							if( fullPath[$-4..$] == ".bas" ) fullPath = fullPath[0..$-4];
						}
						fullPath ~= ".bas";
					}
					version(DIDE)
					{
						if( fullPath.length > 2 )
						{
							if( fullPath[$-2..$] == ".d" ) fullPath = fullPath[0..$-2];
						}
						fullPath ~= ".d";
					}
					break;
				case "2":
					version(FBIDE)
					{
						if( fullPath.length > 3 )
						{
							if( fullPath[$-3..$] == ".bi" ) fullPath = fullPath[0..$-3];
						}
						fullPath ~= ".bi";
					}
					version(DIDE)
					{
						if( fullPath.length > 3 )
						{
							if( fullPath[$-3..$] == ".di" ) fullPath = fullPath[0..$-3];
						}
						fullPath ~= ".di";
					}					
					break;
				default:
			}
			
			if( fullPath.length )
			{
				if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) return saveFile( cSci );
				
				char[] newDocument = fromStringz( IupGetAttribute( cSci.getIupScintilla, "VALUE" ) ).dup;
				if( bShowNew ) ScintillaAction.newFile( fullPath, cast(Encoding) cSci.encoding, newDocument, true, insertPos );
				FileAction.saveFile( fullPath, newDocument, cast(Encoding) cSci.encoding );
				if( bCloseOld )	closeAndMoveDocument( cSci, bShowNew );
			}
			else
			{
				return false;
			}
		}
		catch( Exception e )
		{
			return false;
		}

		return true;
	}
	
	static bool saveTabs()
	{
		CScintilla[] NoNameGroup;

		for( int i = 0; i < IupGetChildCount( GLOBAL.activeDocumentTabs ); i++ )
		{
			Ihandle* _child = IupGetChild( GLOBAL.activeDocumentTabs, i );
			
			auto _cSci = ScintillaAction.getCScintilla( _child );
			
			if( _cSci !is null )
			{
				if( ScintillaAction.getModifyByTitle( _cSci ) )
				{
					if( _cSci.getFullPath.length >= 7 )
					{
						if( _cSci.getFullPath[0..7] == "NONAME#" )
						{
							NoNameGroup ~= _cSci;
							continue;
						}
					}
					
					_cSci.saveFile();
					GLOBAL.outlineTree.refresh( _cSci );
				}
			}
		}
		
		if( NoNameGroup.length )
		{
			foreach( CScintilla _sci; NoNameGroup )
			{
				IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*) _sci.getIupScintilla );
				int oldPos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
				saveAs( _sci, true, true, oldPos );
			}
		}

		return true;
	}
	

	static bool saveAllFile()
	{
		CScintilla[] NoNameGroup;
		
		
		foreach( CScintilla _cSci; GLOBAL.scintillaManager )
		{
			if( _cSci !is null )
			{
				if( ScintillaAction.getModifyByTitle( _cSci ) )
				{
					if( _cSci.getFullPath.length >= 7 )
					{
						if( _cSci.getFullPath[0..7] == "NONAME#" )
						{
							NoNameGroup ~= _cSci;
							continue;
						}
					}
					
					_cSci.saveFile();
					GLOBAL.outlineTree.refresh( _cSci );
				}
			}
		}
		
		/*
		for( int i = 0; i < IupGetChildCount( GLOBAL.activeDocumentTabs ); i++ )
		{
			Ihandle* _child = IupGetChild( GLOBAL.activeDocumentTabs, i );
			
			auto _cSci = ScintillaAction.getCScintilla( _child );
			
			if( _cSci !is null )
			{
				if( ScintillaAction.getModifyByTitle( _cSci ) )
				{
					if( _cSci.getFullPath.length >= 7 )
					{
						if( _cSci.getFullPath[0..7] == "NONAME#" )
						{
							NoNameGroup ~= _cSci;
							continue;
						}
					}
					
					_cSci.saveFile();
					GLOBAL.outlineTree.refresh( _cSci );
				}
			}
		}
		*/
		
		if( NoNameGroup.length )
		{
			foreach( CScintilla _sci; NoNameGroup )
			{
				IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*) _sci.getIupScintilla );
				int oldPos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
				saveAs( _sci, true, true, oldPos );
			}
		}

		return true;
	}

	static int getCurrentPos( Ihandle* ih )
	{
		if( ih != null ) return cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		
		return -1;
	}
	
	static int getLinefromPos( Ihandle* ih, int pos )
	{
		if( ih != null ) return cast(int) IupScintillaSendMessage( ih, 2166, pos, 0 );
		
		return -1;
	}
	
	static int getCurrentLine( Ihandle* ih )
	{
		if( ih != null ) return getLinefromPos( ih, getCurrentPos( ih ) ) + 1;
		
		return -1;
	}
	

	static char[] getCurrentChar( int bias, Ihandle* ih = null )
	{
		if( ih == null ) ih = getActiveIupScintilla();

		if( ih != null )
		{
			int pos = getCurrentPos( ih );
			return fromStringz( IupGetAttributeId( ih, "CHAR", pos + bias ) );
		}

		return null;
	}	

	static int iup_XkeyShift( int _c ){ return _c | 0x10000000; }

	static int iup_XkeyCtrl( int _c ){ return _c | 0x20000000; }

	static int iup_XkeyAlt( int _c ){ return _c | 0x40000000; }

	static bool isComment( Ihandle* ih, int pos, bool bString = true )
	{
		int style = cast(int) IupScintillaSendMessage( ih, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
		
		if( bString )
		{
			version(FBIDE)
			{
				if( style == 1 || style == 19 || style == 4 ) return true;
			}
			version(DIDE)
			{
				if( style == 1 || style == 2 || style == 3 || style == 4 || style == 10 ) return true;
			}
		}
		else
		{
			version(FBIDE)
			{
				if( style == 1 || style == 19 ) return true;
			}
			version(DIDE)
			{
				if( style == 1 || style == 2 || style == 3 || style == 4 ) return true;
			}
		}
		
		int lineStartPos = cast(int) IupScintillaSendMessage( ih, 2167, IupScintillaSendMessage( ih, 2166, pos, 0 ), 0 ); // SCI_LINEFROMPOSITION = 2166, SCI_POSITIONFROMLINE=2167
		//IupMessage("", toStringz( Integer.toString(pos) ~ " / " ~ Integer.toString(lineStartPos) ) );

		if( pos == 0 ) return false;
			
		for( int i = pos - 1; i >= lineStartPos; --i )
		{
			if( IupScintillaSendMessage( ih, 2010, i, 0 ) == 1 ) return true;
		}
		return false;
	}
	
	static void updateRecentFiles( char[] fullPath )
	{
		if( fullPath.length )
		{
			IupString[]	temps;
			
			for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
			{
				if( GLOBAL.recentFiles[i].toDString != fullPath ) temps ~= new IupString( GLOBAL.recentFiles[i].toDString );
			}

			temps ~= new IupString( fullPath );
			
			for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
				delete GLOBAL.recentFiles[i];
			
			int count, index;
			if( temps.length > 8 )
			{
				GLOBAL.recentFiles.length = 8;
				for( count = temps.length - 8; count < temps.length; ++count )
					GLOBAL.recentFiles[index++] = temps[count];
			}
			else
			{
				GLOBAL.recentFiles.length = temps.length;
				for( count = 0; count < temps.length; ++count )
					GLOBAL.recentFiles[index++] = temps[count];
			}
		}
		else
		{
			for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
				delete GLOBAL.recentFiles[i];
				
			GLOBAL.recentFiles.length = 0;
		}


		Ihandle* recentFile_ih = IupGetHandle( "recentFilesSubMenu" );
		if( recentFile_ih != null )
		{
			// Clear All iupItem......
			for( int i = IupGetChildCount( recentFile_ih ) - 1; i >= 0; -- i )
			{
				IupDestroy( IupGetChild( recentFile_ih, i ) );
			}

			Ihandle* _clearRecentFiles = IupItem( GLOBAL.languageItems["clearall"].toCString, null );
			IupSetAttribute( _clearRecentFiles, "IMAGE", "icon_deleteall" );
			IupSetCallback( _clearRecentFiles, "ACTION", cast(Icallback) &menu.submenuRecentFilesClear_click_cb );
			IupInsert( recentFile_ih, null, _clearRecentFiles );
			IupMap( IupGetChild( recentFile_ih, 0 ) );
			IupInsert( recentFile_ih, null, IupSeparator() );
			IupMap( IupGetChild( recentFile_ih, 0 ) );
			
			// Create New iupItem
			for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
			{
				Ihandle* _new = IupItem( GLOBAL.recentFiles[i].toCString, null );
				IupSetCallback( _new, "ACTION", cast(Icallback)&menu.submenuRecentFiles_click_cb );
				IupInsert( recentFile_ih, null, _new );
				IupMap( _new );
			}
	
			IupRefresh( recentFile_ih );
		}
	}
	
	static void applyAllSetting()
	{
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( cSci !is null ) cSci.setGlobalSetting();
		}
	}

	static char[] textWrap( char[] oriText, int textWidth = -1 )
	{
		if( textWidth == -1 )
		{
			try
			{
				Ihandle* actIupSci = getActiveIupScintilla;
				if( actIupSci != null )
				{
					char[] wh = fromStringz( IupGetAttribute( actIupSci, "RASTERSIZE" ) );
					int xPos = Util.index( wh, "x" );
					if( xPos < wh.length )
					{
						int spacePos = Util.rindex( GLOBAL.fonts[1].fontString, " " );
						if( spacePos < GLOBAL.fonts[1].fontString.length )
						{
							int size = Integer.toInt( GLOBAL.fonts[1].fontString[spacePos+1..$] );
							if( size > 6 )
							{
								size -= 2;
								int caretX = cast(int) IupScintillaSendMessage( actIupSci, 2164, 0, getCurrentPos( actIupSci ) ); // SCI_POINTXFROMPOSITION 2164
								textWidth =  cast(int) ( ( cast(float) Integer.toInt( wh[0..xPos] ) - cast(float) caretX ) / cast(float) size );
							}
						}
					}
				}
			}
			catch( Exception e )
			{
			}
			
			if( textWidth == -1 ) return oriText;
		}
	
		char[] result;
		
		char[]	tmp;
		char	last = ' ';
		int		count;
		
		
		for( int i = 0; i < oriText.length; ++ i )
		{
			if( ++count == textWidth )
			{
				result = result ~ "\n" ~ Util.triml( tmp );
				count = tmp.length;
				tmp.length = 0;
			}
			else if( oriText[i] == ' ' &&  last != ' ' )
			{
				result ~= tmp;
				tmp.length = 0;
			}
			
			tmp ~= oriText[i];
			last = oriText[i];
			
			if( i == oriText.length - 1 )
				if( count + tmp.length < textWidth ) result ~= tmp; else result = result ~ "\n" ~ Util.triml( tmp );

		}
		
		return result;
	}
}


struct ProjectAction
{
	private:
		import project;
		
	public:
	static int getTargetDepthID( int targetDepth )
	{
		int 	id		= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Get Focus TreeNode
		int 	depth	= IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );

		if( depth > targetDepth )
		{
			while( depth > targetDepth )
			{
				id = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "PARENT", id );
				depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );
			}
		}
		else if( depth < targetDepth )
		{
			return -1;
		}
		
		return id;
	}

	static int getActiveProjectID()
	{
		return getTargetDepthID( 1 );
	}

	static char[] getActiveProjectName()
	{
		int id = getActiveProjectID();

		if( id < 1 ) return null;

		return fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;
	}

	static char[] getActiveProjectTreeNodeTitle()
	{
		int id = getActiveProjectID();

		if( id < 1 ) return null;
		
		return fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ).dup;//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;
	}
	
	static bool changeActiveProjectTreeNodeTitle( char[] newName )
	{
		int id = getActiveProjectID();

		if( id < 1 ) return false;
		
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id, toStringz( newName.dup ) );

		return true;
	}

	static int addTreeNode( char[] _prjDirName, char[] fullPath, int folderLocateId )
	{
		char[] _titleName;

		int pos = Util.index( fullPath, _prjDirName );
		if( pos == 0 ) 	_titleName = Util.substitute( fullPath, _prjDirName, "" );

		if( _titleName.length )
		{
			// Check the child Folder
			char[][]	splitText = Util.split( _titleName, "/" );
		
			int counterSplitText;
			for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
			{
				//int 	countChild = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "TOTALCHILDCOUNT", folderLocateId );
				int 	countChild = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "COUNT", folderLocateId );

				bool bFolerExist = false;
				for( int i = 1; i <= countChild; ++ i )
				{
					char[]	kind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", folderLocateId + i ) );
					if( kind == "BRANCH" )
					{
						if( splitText[counterSplitText] == fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", folderLocateId + i ) ) )
						{
							// folder already exist
							folderLocateId = folderLocateId+i;
							bFolerExist = true;
							break;
						}
					}
				}
				if( !bFolerExist )
				{
					IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, toStringz( splitText[counterSplitText] ) );
					if( pos != 0 )
					{
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId, tools.getCString( "FIXED" ) );
					}
					else
					{
						IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, toStringz( splitText[counterSplitText] ) );
					}
					/*
					// Shadow
					if( pos != 0 )
					{
						IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( "FIXED" ) );
					}
					else
					{
						IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( splitText[counterSplitText] ) );
					}
					*/
					folderLocateId ++;
				}
			}
		}
		
		return folderLocateId;
	}

	static char[] fileInProject( char[] fullPath, char[] projectName = null )
	{
		if( fullPath.length )
		{
			if( projectName.length )
			{
				if( projectName in GLOBAL.projectManager )
				{
					foreach( char[] prjFileFullPath; GLOBAL.projectManager[projectName].sources ~ GLOBAL.projectManager[projectName].includes )
					{
						if( fullPath == prjFileFullPath ) return projectName;
					}
				}
			}
			else
			{
				foreach( p; GLOBAL.projectManager )
				{
					foreach( char[] prjFileFullPath; p.sources ~ p.includes )
					{
						if( fullPath == prjFileFullPath ) return p.dir;
					}
				}
			}
		}

		return null;
	}
	
	static char[] getActiveProjectDir()
	{
		auto cSci = ScintillaAction.getActiveCScintilla();

		if( cSci !is null )
		{
			foreach( p; GLOBAL.projectManager )
			{
				foreach( char[] prjFileFullPath; p.sources ~ p.includes )
				{
					if( cSci.getFullPath() == prjFileFullPath ) return p.dir;
				}
			}
		}

		return null;
	}
	
	static PROJECT getActiveProject()
	{
		auto cSci = ScintillaAction.getActiveCScintilla();

		if( cSci !is null )
		{
			foreach( p; GLOBAL.projectManager )
			{
				foreach( char[] prjFileFullPath; p.sources ~ p.includes )
				{
					if( cSci.getFullPath() == prjFileFullPath ) return p;
				}
			}
		}

		PROJECT nullProject;
		return nullProject;
	}		
	
	static int getSelectCount()
	{
		int		result;
		char[] 	status = fromStringz( IupGetAttribute( GLOBAL.projectTree.getTreeHandle,"MARKEDNODES" ) );
		
		for( int i = 0; i < status.length; ++ i )
		{
			if( status[i] == '+' ) result ++;
		}
		
		return result;
	}
	
	static int[] getSelectIDs()
	{
		int[]	result;
		char[] 	status = fromStringz( IupGetAttribute( GLOBAL.projectTree.getTreeHandle,"MARKEDNODES" ) );
		
		for( int i = 0; i < status.length; ++ i )
		{
			if( status[i] == '+' ) result ~= i;
		}
		
		return result;
	}	
}


struct StatusBarAction
{
private:
	import parser.autocompletion, parser.ast, scintilla;
	import tango.text.convert.Layout;
	
public:
	static void update( Ihandle* _handle = null )
	{
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" )
			{
				IupHide( GLOBAL.scrollICONHandle );
				IupSetAttribute( GLOBAL.scrollTimer, "RUN", "NO" );
			}
		}
		
		int childCount = IupGetInt( GLOBAL.activeDocumentTabs, "COUNT" );
		if( childCount > 0 )
		{
			// SCI_GETCURRENTPOS = 2008
			// SCI_LINEFROMPOSITION = 2166
			// SCI_GETCOLUMN = 2129
			// SCI_GETOVERTYPE = 2187
			// SCI_GETEOLMODE 2030
			
			CScintilla cSci;
			if( _handle != null ) cSci = ScintillaAction.getCScintilla( _handle ); else cSci = ScintillaAction.getActiveCScintilla();

			if( cSci !is null )
			{
				Ihandle* _undo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Undo" );
				if( _undo != null ) // SCI_CANUNDO 2174
				{
					if( ( cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2174, 0, 0 ) ) == 0 ) IupSetAttribute( _undo, "ACTIVE", "NO" ); else IupSetAttribute( _undo, "ACTIVE", "YES" );
				}					
				Ihandle* _redo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Redo" );
				if( _redo != null ) // SCI_CANREDO 2016
				{
					if( ( cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2016, 0, 0 ) ) == 0 ) IupSetAttribute( _redo, "ACTIVE", "NO" ); else IupSetAttribute( _redo, "ACTIVE", "YES" );
				}					
				
				
				int pos = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2008, 0, 0 );
				int line = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, pos, 0 ) + 1; // 0 based
				int col = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2129, pos, 0 ) + 1;  // 0 based
				int bOverType = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2187, 0, 0 );
				int eolType = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2030, 0, 0 );

				scope Layouter = new Layout!(char)();
				char[] output = Layouter( "{,7}x{,5}", line, col );
				GLOBAL.statusBar.setLINExCOL( output );

				if( bOverType )
				{
					GLOBAL.statusBar.setIns( "OVR" ); // Update line x col
				}
				else
				{
					GLOBAL.statusBar.setIns( "INS" ); // Update line x col
				}

				switch( eolType )
				{
					case 0: //  SC_EOL_CRLF (0)
						GLOBAL.statusBar.setEOLType( "WINDOWS" ); break;
					case 1: //    SC_EOL_CR (1)
						GLOBAL.statusBar.setEOLType( "    MAC" ); break;
					case 2: //   SC_EOL_LF (2)
						GLOBAL.statusBar.setEOLType( "   UNIX" ); break;
					default:
						GLOBAL.statusBar.setEOLType( " UNKNOW" );
				}

				switch( cSci.encoding )
				{
					case 0: // Encoding.Unknown
						GLOBAL.statusBar.setEncodingType( "DEFAULT    " ); break;
					case 1: // Encoding.UTF_8N
						GLOBAL.statusBar.setEncodingType( "UTF8       " ); break;
					case 2: // Encoding.UTF_8
						GLOBAL.statusBar.setEncodingType( "UTF8.BOM   " ); break;
					case 3: // Encoding.UTF_16
						GLOBAL.statusBar.setEncodingType( "UTF16      " ); break;
					case 4: // Encoding.UTF_16BE
						GLOBAL.statusBar.setEncodingType( "UTF16BE.BOM" ); break;
					case 5: // Encoding.UTF_16LE
						GLOBAL.statusBar.setEncodingType( "UTF16LE.BOM" ); break;
					case 6: // Encoding.UTF_32
						GLOBAL.statusBar.setEncodingType( "UTF32      " ); break;
					case 7: // Encoding.UTF_32BE
						GLOBAL.statusBar.setEncodingType( "UTF32BE.BOM" ); break;
					case 8: // Encoding.UTF_32LE
						GLOBAL.statusBar.setEncodingType( "UTF32LE.BOM" ); break;
					case 9: //
						GLOBAL.statusBar.setEncodingType( "UTF32BE    " ); break;
					case 10: //
						GLOBAL.statusBar.setEncodingType( "UTF32LE    " ); break;
					case 11: //
						GLOBAL.statusBar.setEncodingType( "UTF16BE    " ); break;
					case 12: //
						GLOBAL.statusBar.setEncodingType( "UTF16LE    " ); break;
					default:
						GLOBAL.statusBar.setEncodingType( "UNKNOWN?   " );
				}

				if( GLOBAL.showFunctionTitle == "ON" )
				{
					if( GLOBAL.enableParser == "ON" )
					{
						if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager )
						{
							CASTnode 		AST_Head = actionManager.ParserAction.getActiveASTFromLine( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], line );
							
							if( AST_Head !is null )
							{
								version(FBIDE)
								{
									if( AST_Head.kind & ( B_WITH | B_SCOPE ) )
									{
										do
										{
											if( AST_Head.getFather !is null ) AST_Head = AST_Head.getFather; else break;
										}
										while( AST_Head.kind & ( B_WITH | B_SCOPE ) );
									}
									
									IupSetStrAttribute( GLOBAL.toolbar.getListHandle(), "1", toStringz( AST_Head.name ) );
									switch( AST_Head.kind )
									{
										case B_FUNCTION:	IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_function" );		break;
										case B_SUB:			IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_sub" );			break;
										case B_TYPE:		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_struct" );		break;
										case B_ENUM:		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_enum" );			break;
										case B_UNION:		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_union" );		break;
										case B_CTOR:		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_ctor" );			break;
										case B_DTOR:		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_dtor" );			break;
										case B_PROPERTY:	IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_property" );		break;
										case B_OPERATOR:	IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_operator" );		break;
										default:
											IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1", null );
											IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", "" );
									}
								}
								version(DIDE)
								{
									IupSetStrAttribute( GLOBAL.toolbar.getListHandle(), "1", toStringz( AST_Head.name ) );
									
									if( AST_Head.kind & D_MODULE )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_module" );
									else if( AST_Head.kind & D_FUNCTION )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_function" );
									else if( AST_Head.kind & D_VERSION )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_version" );
									else if( AST_Head.kind & D_STRUCT )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_struct" );
									else if( AST_Head.kind & D_ENUM )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_enum" );
									else if( AST_Head.kind & D_UNION )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_union" );
									else if( AST_Head.kind & D_CLASS )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_class" );
									else if( AST_Head.kind & D_INTERFACE )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_interface" );
									else if( AST_Head.kind & D_FUNCTIONLITERALS )
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_anonymous" );
									else if( AST_Head.kind & D_CTOR )
									{
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", toStringz( "this" ) );
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_ctor" );
									}
									else if( AST_Head.kind & D_DTOR )
									{
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", toStringz( "~this") );
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_dtor" );
									}
								}
							}
							else
							{
								IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", "" );
							}
						}
					}
				}
			}
		}
		else
		{
			GLOBAL.statusBar.setPrjName( "                                            " );
			GLOBAL.statusBar.setLINExCOL( "             " );
			GLOBAL.statusBar.setIns( "   " );
			GLOBAL.statusBar.setEOLType( "        " );	
			GLOBAL.statusBar.setEncodingType( "           " );
			GLOBAL.searchExpander.contract();
		}
	}
}


struct ParserAction
{
private:
	import scintilla;
	import parser.ast;

public:
	static CASTnode getActiveParseAST()
	{
		CScintilla cSci = ScintillaAction.getActiveCScintilla();
		
		if( cSci !is null )
		{
			if( fullPathByOS( cSci.getFullPath ) in GLOBAL.parserManager ) return GLOBAL.parserManager[fullPathByOS( cSci.getFullPath )];
		}

		return null;
	}
	
	static CASTnode getActiveASTFromLine( CASTnode _fatherNode, int line, int _kind = -1 )
	{
		version(FBIDE)
		{
			if( _kind == -1 ) _kind = B_BAS | B_BI | B_FUNCTION | B_SUB | B_OPERATOR | B_PROPERTY | B_CTOR | B_DTOR | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_WITH | B_SCOPE | B_NAMESPACE | B_VERSION;
		}
		version(DIDE)
		{
			if( _kind == -1 ) _kind = D_MODULE | D_FUNCTION | D_CLASS | D_STRUCT | D_INTERFACE | D_UNION | D_ENUM | D_CTOR | D_DTOR | D_TEMPLATE | D_VERSION | D_FUNCTIONLITERALS;
		}
		
		
		if( _fatherNode !is null )
		{
			//if( _fatherNode.kind & (D_CTOR | D_DTOR ) )
			//	IupMessage("_fatherNode",toStringz( Integer.toString( _fatherNode.lineNumber ) ~ "~" ~ Integer.toString( _fatherNode.endLineNum )  ) );
			if( _fatherNode.kind & _kind )
			{
				if(  _fatherNode.lineNumber < _fatherNode.endLineNum ) // If equal, not BLOCK
				{
					if( line >= _fatherNode.lineNumber && line <= _fatherNode.endLineNum )
					{
						foreach_reverse( CASTnode _node; _fatherNode.getChildren() )
						{
							auto _result = getActiveASTFromLine( _node, line, _kind );
							if( _result !is null ) return _result;
						}

						return _fatherNode;
					}
				}
			}
		}

		return null;
	}
	
	static CASTnode getRoot( CASTnode node )
	{
		if( node !is null )
		{
			while( node.getFather !is null )
				node = node.getFather();
		}
		return node;
	}
	
	static char[] removeArrayAndPointer( char[] word )
	{
		char[] result;
		
		int starIndex;
		for( starIndex = 0; starIndex < word.length; ++starIndex )
			if( word[starIndex] != '*' ) break;
			
		if( starIndex > 0 ) word = word[starIndex..$].dup;
			
		version(FBIDE)
		{
			foreach( char c; word )
			{
				if( c == '(' || c == '*' ) break; else result ~= c;
			}
		}
		version(DIDE)
		{
			foreach( char c; word )
			{
				if( c == '[' || c == '*' || c == '!' ) break; else result ~= c;
			}
		}
		
		if( starIndex > 0 )
		{
			for( int i = 0; i < starIndex; ++ i )
				result = "*" ~ result;
		}

		return result;
	}

	static char[] getSeparateType( char[] _string, bool bemoveArrayAndPoint = false )
	{
		int openParenPos = Util.index( _string, "(" );

		if( openParenPos > 0 && openParenPos < _string.length )
		{
			version(DIDE) if( _string[openParenPos-1] == '!' ) openParenPos = Util.index( _string, "(", openParenPos + 1 );
		}
		
		if( openParenPos < _string.length )
		{
			if( bemoveArrayAndPoint ) return removeArrayAndPointer( _string[0..openParenPos] ); else return _string[0..openParenPos];
		}

		return !bemoveArrayAndPoint ? _string : removeArrayAndPointer( _string );
	}

	static char[] getSeparateParam( char[] _string )
	{
		int openParenPos = Util.index( _string, "(" );

		if( openParenPos > 0 && openParenPos < _string.length )
		{
			version(DIDE) if( _string[openParenPos-1] == '!' ) openParenPos = Util.index( _string, "(", openParenPos + 1 );
		}
		
		if( openParenPos < _string.length )
		{
			return _string[openParenPos..$];
		}

		return null;
	}	
	
	static void getSplitDataFromNodeTypeString( char[] s, ref char[] _type, ref char[] _paramString, bool bemoveArrayAndPoint = false  )
	{
		_type			= getSeparateType( s, bemoveArrayAndPoint );
		_paramString	= getSeparateParam( s );
	}
	
	version(DIDE) static CASTnode getFatherOfMemberMethod( CASTnode node )
	{
		if( node is null ) return null;
		
		if( node.kind & D_FUNCTION )
		{
			do
			{
				node = node.getFather();
				if( node is null ) return null;
			}
			while( !node.kind & ( D_CLASS | D_STRUCT | D_INTERFACE ) )
		}
		else
		{
			return null;
		}
		
		return node;
	}
	
	static char[][] getDivideWordWithoutSymbol( char[] word )
	{
		int _getDelimitedString( int _index, char _delimitedOpen, char _delimitedClose )
		{
			int		_countDemlimit, _i;
			
			for( _i = _index; _i < word.length; ++ _i )
			{
				if( word[_i] == _delimitedOpen ) _countDemlimit ++;
				if( word[_i] == _delimitedClose ) _countDemlimit --;
			
				if( _countDemlimit <= 0 ) break;
			}
			/*
			do
			{
				if( word[_index] == _delimitedOpen ) _countDemlimit ++;
				if( word[_index] == _delimitedClose ) _countDemlimit --;

				if( _countDemlimit == 0 ) break;
				if( ++_index >= word.length ) break;
			}
			while( _countDemlimit > 0 );

			return _index;
			*/
			return _i;
		}

		char[][]	splitWord;
		char[]		tempWord;

		int			returnIndex;

		for( int i = 0; i < word.length ; ++ i )
		{
			if( word[i] == '.' )
			{
				splitWord ~= ParserAction.removeArrayAndPointer( tempWord );
				tempWord = "";
			}
			else
			{
				if( word[i] == '(' )
				{
					returnIndex = _getDelimitedString( i, '(', ')' );
					if( returnIndex < word.length )
					{
						i = returnIndex;
						//tempWord ~= ")";
					}
				}
				else if( word[i] == '[' )
				{
					returnIndex = _getDelimitedString( i, '[', ']' );
					if( returnIndex < word.length )
					{
						i = returnIndex;
						//tempWord ~= "]";
					}				
				}
				else
				{
					version(FBIDE)
					{
						if( i > 0 )
						{
							if( word[i] == '>' )
							{
								if( word[i-1] == '-' )
								{
									splitWord ~= ParserAction.removeArrayAndPointer( tempWord );
									tempWord = "";
									continue;
								}
							}
						}
					}
				
					tempWord ~= word[i];
				}
			}			
		}

		splitWord ~= ParserAction.removeArrayAndPointer( tempWord );

		return splitWord;
	}
}


// Action for FILE operate
struct SearchAction
{
private:
	import scintilla, project, menu;
	import tango.io.FilePath, tango.text.Ascii;
	import tango.io.device.File;//, tango.io.stream.Lines;

	static int _find( Ihandle* ih, char[] targetText, int type = 2, bool bNext = true )
	{
		int			findPos = -1;

		if( !( type & MATCHCASE ) ) targetText = lowerCase( targetText );

		//IupMessage( "Text:", toStringz(targetText) );
		
		int currentPos = cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		int	documentLength = IupGetInt( ih, "COUNT" );
		IupScintillaSendMessage( ih, 2198, type, 0 ); // SCI_SETSEARCHFLAGS = 2198,

		if( targetText.length )
		{
			scope _t = new IupString( targetText );
			IupScintillaSendMessage( ih, 2190, currentPos, 0 ); 						// SCI_SETTARGETSTART = 2190,
			if( bNext )	IupScintillaSendMessage( ih, 2192, documentLength, 0 ); else IupScintillaSendMessage( ih, 2192, 0, 0 );

			findPos = cast(int) IupScintillaSendMessage( ih, 2197, targetText.length, cast(int) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
			
			// reSearch form file's head
			if( findPos < 0 )
			{
				if( bNext )
				{
					IupScintillaSendMessage( ih, 2190, 0, 0 ); 						// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( ih, 2192, currentPos, 0 );				// SCI_SETTARGETEND = 2192,
				}
				else
				{
					IupScintillaSendMessage( ih, 2190, documentLength, 0 ); 		// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( ih, 2192, currentPos, 0 );				// SCI_SETTARGETEND = 2192,
				}

				findPos = cast(int) IupScintillaSendMessage( ih, 2197, targetText.length, cast(int) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
			}
	
			if( findPos < 0 )
			{
				return -1;
			}
			else
			{
				char[] pos;
				if( bNext )
				{
					pos = Integer.toString( findPos ) ~ ":" ~ Integer.toString( findPos+targetText.length );
				}
				else
				{
					pos = Integer.toString( findPos+targetText.length ) ~ ":" ~ Integer.toString( findPos );
				}
				IupSetStrAttribute( ih, "SELECTIONPOS", toStringz( pos ) );
				//DocumentTabAction.setFocus( ih );
			}
		}
		
		return findPos;
	}

	/*
    SCFIND_WHOLEWORD = 2,
    SCFIND_MATCHCASE = 4,
    SCFIND_WORDSTART = 0x00100000,
    SCFIND_REGEXP = 0x00200000,
    SCFIND_POSIX = 0x00400000,
	*/	

public:
	const int WHOLEWORD = 2;
	const int MATCHCASE = 4;
	
	static int search( Ihandle* iupSci, char[] findText, int searchRule, bool bForward = true )
	{
		int pos = -1;

		if( iupSci != null && findText.length )
		{
			if( bForward )
			{
				pos = _find( iupSci, findText, searchRule, true );
			}
			else
			{
				pos = _find( iupSci, findText, searchRule, false );
			}
		}

		// IUP_IGNORE = -1, IUP_DEFAULT = -2, 
		if( pos == -1 ) return -2;
		
		int ln = ScintillaAction.getLinefromPos( iupSci, pos );
		IupSetAttributeId( iupSci, "ENSUREVISIBLE", ln, "ENFORCEPOLICY" );
		
		return pos;
	}	

	static bool IsWholeWord( char[] lineData, char[] target, int pos )
	{
		int targetPLUS1, targetMinus1;
		
		if( pos == 0 )
		{
			targetMinus1 = 32; // Ascii 32 = space
			if( lineData.length == target.length ) targetPLUS1 = 32;else targetPLUS1 = cast(int)lineData[target.length];
		}
		else if( pos + target.length == lineData.length )
		{
			targetMinus1 = cast(int)lineData[pos-1];
			targetPLUS1 = 32; // Ascii 32 = space
		}
		else
		{
			targetMinus1 = cast(int)lineData[pos-1];
			targetPLUS1 = cast(int)lineData[pos+target.length];
		}

		//IupMessage( "Minus:Plus", toStringz( Integer.toString( targetMinus1 ) ~ ":" ~ Integer.toString( targetPLUS1 ) ) );

		if( targetPLUS1 >= 48 && targetPLUS1 <= 57 ) return false;
		if( targetPLUS1 >= 65 && targetPLUS1 <= 90 ) return false;
		if( targetPLUS1 >= 97 && targetPLUS1 <= 122 ) return false;

		if( targetMinus1 >= 48 && targetMinus1 <= 57 ) return false;
		if( targetMinus1 >= 65 && targetMinus1 <= 90 ) return false;
		if( targetMinus1 >= 97 && targetMinus1 <= 122 ) return false;

		
		return true;
	}

	/*
	buttonIndex = 0 Find
	buttonIndex = 1 Replace
	buttonIndex = 2 Count
	buttonIndex = 3 Mark
	*/
	static int findInOneFile( char[] fullPath, char[] findText, char[] replaceText, int searchRule = 6, int buttonIndex = 0 )
	{
		int		count, _encoding;
		bool	bInDocument;

		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) bInDocument = true;
		scope f = new FilePath( fullPath );
		
		if( f.exists() || bInDocument )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
			IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 1 );

			char[] 	document;
			//char[]	splitLineDocument;
			if( bInDocument )
			{
				document = fromStringz( IupGetAttribute( GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla, "VALUE" ) );
			}
			else
			{
				if( buttonIndex == 3 ) return 0;
				document = FileAction.loadFile( fullPath, _encoding );
			}			
			//scope file = new File( fullPath, File.ReadExisting );

			if( buttonIndex == 1 )
			{
				int findIndex = 0;
				while( findIndex < document.length )
				{
					if( searchRule & MATCHCASE )
					{
						findIndex = Util.index( document, findText, findIndex );
					}
					else
					{
						findIndex = Util.index( lowerCase( document ), lowerCase( findText ), findIndex );
					}
					
					if( findIndex < document.length )
					{
						if( searchRule & WHOLEWORD )
						{
							if( IsWholeWord( document, findText, findIndex ) )
							{
								count ++;
								document = document[0..findIndex] ~ replaceText ~ document[findIndex+findText.length..$];
								findIndex += replaceText.length;
							}
							else
							{
								findIndex += findText.length;
							}
						}
						else
						{
							count ++;
							document = document[0..findIndex] ~ replaceText ~ document[findIndex+findText.length..$];
							findIndex += replaceText.length;
						}
					}
				}

				if( bInDocument )
				{
					FileAction.saveFile( fullPath, document, GLOBAL.scintillaManager[fullPathByOS( fullPath )].encoding );
					GLOBAL.scintillaManager[fullPathByOS( fullPath )].setText( document );
					GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[fullPathByOS( fullPath )] );
				}
				else
				{
					FileAction.saveFile( fullPath, document, _encoding );
				}
				
				return count;
			}

			int lineNum;
			foreach( line; Util.splitLines( document ) )
			{
				lineNum++;

				if( line.length )
				{
					int pos;
					if( !( searchRule & MATCHCASE ) )
					{
						pos = Util.index( lowerCase( line ) , lowerCase( findText ) );
					}
					else
					{
						pos = Util.index( line , findText );
					}
					
					if( pos < line.length )
					{
						if( searchRule & WHOLEWORD )
						{
							bool bGetWholeWord;
							while( pos < line.length )
							{
								if( IsWholeWord( line, findText, pos ) )
								{
									bGetWholeWord = true;
									break;
								}
								else
								{
									if( pos + findText.length >= line.length ) break;
									pos = Util.index( line, findText, pos + findText.length );
								}
							}
							
							if( !bGetWholeWord ) continue;
						}
						
						count++;
						
						if( buttonIndex == 0 )
						{
							char[] outputWords = fullPath ~ "(" ~ Integer.toString( lineNum ) ~ "): " ~ line;
							//IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", GLOBAL.cString.convert( outputWords ) );
							GLOBAL.messagePanel.printSearchOutputPanel( outputWords );
						}
						else if( buttonIndex == 3 )
						{
							if( bInDocument )
							{
								//int linNum = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPath].getIupScintilla, 2166, totalLength + pos, 0 );// SCI_LINEFROMPOSITION = 2166
								if( !( IupGetIntId( GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla, "MARKERGET", lineNum-1 ) & 2 ) ) IupSetIntId( GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla, "MARKERADD", lineNum-1, 1 );
							}
						}
					}
				}
			}
		}

		return count;
	}
	
	static void addListItem( Ihandle* ih, char[] text, int limit = 15 )
	{
		if( ih != null )
		{
			int itemCount = IupGetInt( ih, "COUNT" );
			
			for( int i = itemCount; i > 0; --i )
			{
				char[] itemText = fromStringz( IupGetAttributeId( ih, "", i ) ).dup;
				if( itemText.length )
				{
					if( itemText == text )
					{
						IupSetInt( ih, "REMOVEITEM", i );
					}
				}
				else
				{
					IupSetInt( ih, "REMOVEITEM", i );
				}				
			}
			
			itemCount = IupGetInt( ih, "COUNT" );
			if( itemCount == limit )
			{
				IupSetInt( ih, "REMOVEITEM", limit );
				IupSetAttributeId( ih, "INSERTITEM", 1, toStringz( text.dup ) );
			}
			else
			{
				IupSetAttributeId( ih, "INSERTITEM", 1, toStringz( text.dup ) );
			}
		}
	}
}


// Action for FILE operate
struct CustomToolAction
{
	version(linux)	import tango.sys.Process;
	import	tango.io.FilePath;
	import	project;
	
	static void run( CustomTool tool )
	{
		scope toolPath = new FilePath( tool.dir );
		if( !toolPath.exists )
		{
			IupMessageError( null, toStringz( tool.dir ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString ) );
			return;
		}
		
		bool bGoPlugin;
		version(Windows)
		{
			if( lowerCase( toolPath.suffix ) == ".dll" ) bGoPlugin = true;
		}
		version(linux)
		{
			if( lowerCase( toolPath.suffix ) == ".so" ) bGoPlugin = true;
		}
		
		if( bGoPlugin )
		{
			try
			{
				if( tool.name in GLOBAL.pluginMnager )
				{
					if( GLOBAL.pluginMnager[tool.name] !is null )
					{
						if( GLOBAL.pluginMnager[tool.name].getPath == tool.dir )
							GLOBAL.pluginMnager[tool.name].go();
						else
						{
							auto temp = GLOBAL.pluginMnager[tool.name];
							delete temp;
							GLOBAL.pluginMnager[tool.name] = new CPLUGIN( tool.name, tool.dir );
							GLOBAL.pluginMnager[tool.name].go();
						}
					}
					else
					{
						IupMessageError( GLOBAL.mainDlg, toStringz( tool.name ~ " Is Null" ) );
						GLOBAL.pluginMnager.remove( tool.name );
						//GLOBAL.pluginMnager[tool.name.toDString] = new CPLUGIN( tool.name.toDString, tool.dir.toDString );
						//GLOBAL.pluginMnager[tool.name.toDString].go( GLOBAL.mainDlg );
					}
				}
				else
				{
					GLOBAL.pluginMnager[tool.name] = new CPLUGIN( tool.name, tool.dir );
					GLOBAL.pluginMnager[tool.name].go();
				}
			}
			catch( Exception e )
			{
				IupMessageError( GLOBAL.mainDlg, toStringz( e.toString ) );
				if( tool.name in GLOBAL.pluginMnager ) GLOBAL.pluginMnager.remove( tool.name );
			}
		}
		else
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			char[] args;
			if( cSci !is null )
			{
				// %s Selected Text
				char[] s = fromStringz( IupGetAttribute( cSci.getIupScintilla, toStringz("SELECTEDTEXT") ) );
				
				// %s% Selected Word
				args = Util.substitute( tool.args, "%s%", s );
				args = Util.substitute( args, "\"%s%\"", "\"" ~ s ~ "\"" );
				
				// %f% Active File
				scope fPath = new FilePath( cSci.getFullPath() );
				args = Util.substitute( args, "%f%", fPath.toString );
				args = Util.substitute( args, "\"%f%\"", "\"" ~ fPath.toString ~ "\"" );
				
				args = Util.substitute( args, "%fn%", fPath.path ~ "/" ~ fPath.name );
				args = Util.substitute( args, "\"%fn%\"", "\"" ~ fPath.path ~ "/" ~ fPath.name ~ "\"" );
				
				args = Util.substitute( args, "%fdir%", fPath.path );
				args = Util.substitute( args, "\"%fdir%\"", "\"" ~ fPath.path ~ "\"" );
			}
			
			char[] pDir = ProjectAction.getActiveProjectDir;
			if( pDir.length )
			{
				char[] pName = GLOBAL.projectManager[pDir].name;
				char[] pTargetName = GLOBAL.projectManager[pDir].targetName;
				char[] pTotal;
				
				if( !pTargetName.length ) pTotal = pDir ~ "/" ~ pName; else	pTotal = pDir ~ "/" ~ pTargetName;
				
				args = Util.substitute( args, "%pn%", pTotal );
				args = Util.substitute( args, "\"%pn%\"", "\"" ~ pTotal ~ "\"" );
				
				char[] pAllFiles;
				foreach( char[] s; GLOBAL.projectManager[pDir].sources )
					pAllFiles ~= ( s ~ " " );

				foreach( char[] s; GLOBAL.projectManager[pDir].includes )
					pAllFiles ~= ( s ~ " " );
				
				pAllFiles = Util.trim( pAllFiles );
				args = Util.substitute( args, "%p%", pAllFiles );
				args = Util.substitute( args, "\"%p%\"", "\"" ~ pAllFiles ~ "\"" );
				
				args = Util.substitute( args, "%pdir%", pDir );
				args = Util.substitute( args, "\"%pdir%\"", "\"" ~ pDir ~ "\"" );			
			}
			else
			{
				args = Util.substitute( args, "%pn%", "" );
				args = Util.substitute( args, "\"%pn%\"", "" );
				
				args = Util.substitute( args, "%p%", "" );
				args = Util.substitute( args, "\"%p%\"", "" );
				
				args = Util.substitute( args, "%pdir%", "" );
				args = Util.substitute( args, "\"%pdir%\"", "" );
			}		

			char[] useConsole = tool.toggleShowConsole == "ON" ? "1 " : "0 ";
			version(Windows)
			{
				if( useConsole == "1 " )
				{
					if( GLOBAL.consoleWindow.id < GLOBAL.monitors.length )
					{
						int x = GLOBAL.consoleWindow.x + GLOBAL.monitors[GLOBAL.consoleWindow.id].x;
						int y = GLOBAL.consoleWindow.y + GLOBAL.monitors[GLOBAL.consoleWindow.id].y;
						
						args = "0 " ~ Integer.toString( x ) ~ " " ~ Integer.toString( y ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.w ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.h ) ~ " " ~ useConsole ~ tool.dir ~ " " ~ args;
					}
					else
					{
						args = "0 0 0 0 0 " ~ useConsole ~ tool.dir ~ " " ~ args;
					}
					
					args = Util.substitute( args, "/", "\\" );
				
					IupExecute( "consoleLauncher", toStringz( args ) );
				}
				else
				{
					IupExecute( toStringz( tool.dir ), toStringz( args ) );
				}
			}
			else
			{
				char[] command = Util.substitute( tool.dir, " ", "\\ " ); // For space in path;
				if( useConsole == "1 " )
				{
					if( command[0] == '"' && command[$-1] == '"' )
						args = "\"" ~ GLOBAL.poseidonPath ~ "consoleLauncher " ~ Integer.toString( GLOBAL.consoleWindow.id ) ~ " -1 -1 " ~ Integer.toString( GLOBAL.consoleWindow.w ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.h ) ~ " 1 " ~ command[1..$-1] ~ " " ~ args ~ "\"";
					else
						args = "\"" ~ GLOBAL.poseidonPath ~ "consoleLauncher " ~ Integer.toString( GLOBAL.consoleWindow.id ) ~ " -1 -1 " ~ Integer.toString( GLOBAL.consoleWindow.w ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.h ) ~ " 1 " ~ command ~ " " ~ args ~ "\"";
						
						
					char[] geoString;
					if( GLOBAL.consoleWindow.id < GLOBAL.monitors.length )
					{
						int x = GLOBAL.consoleWindow.x + GLOBAL.monitors[GLOBAL.consoleWindow.id].x;
						int y = GLOBAL.consoleWindow.y + GLOBAL.monitors[GLOBAL.consoleWindow.id].y;
						int w = GLOBAL.consoleWindow.w < 80 ? 80 : GLOBAL.consoleWindow.w;
						int h = GLOBAL.consoleWindow.h < 24 ? 24 : GLOBAL.consoleWindow.h;
						//geoString = " --geometry=80x24+" ~ Integer.toString( x ) ~ "+" ~ Integer.toString( y );
						geoString = " --geometry=" ~ Integer.toString( w ) ~ "x" ~ Integer.toString( h ) ~ "+" ~ Integer.toString( x ) ~ "+" ~ Integer.toString( y );
					}
					
					if( GLOBAL.linuxTermName.length )
					{
						Process p;
						switch( Util.trim( GLOBAL.linuxTermName ) )
						{
							case "xterm", "uxterm":
								geoString = Util.substitute( geoString, "--geometry=", "-geometry " );
								args = "-T poseidon_terminal" ~ geoString ~ " -e " ~ args;
								//p = new Process( true, GLOBAL.linuxTermName ~ " -T poseidon_terminal" ~ geoString ~ " -e " ~ args );
								break;
							case "mate-terminal" ,"xfce4-terminal" ,"lxterminal", "gnome-terminal", "tilix":
								args = "--title poseidon_terminal" ~ geoString ~ " -e " ~ args;
								//p = new Process( true, GLOBAL.linuxTermName ~ " --title poseidon_terminal" ~ geoString ~ " -e " ~ args );
								break;

							default:
								args = "-e " ~ args;
								//p = new Process( true, GLOBAL.linuxTermName ~ " -e " ~ args );
						}
						
						//p.execute;
						IupExecute( toStringz( GLOBAL.linuxTermName ), toStringz( args ) );
					}						
				}
				else
				{
					Process p = new Process( true, tool.dir ~ " " ~ args );
					p.execute;
				}
			}
		}
	}
	
	static bool getCustomCompilers( ref char[] _opt, ref char[] _compiler )
	{
		if( GLOBAL.currentCustomCompilerOption.toDString.length )
		{
			foreach( char[] s; GLOBAL.customCompilerOptions )
			{
				int bpos = Util.rindex( s, "%::% " );
				int fpos = Util.index( s, "%::% " );
				if( bpos < s.length )
				{
					if( s[bpos+5..$] == GLOBAL.currentCustomCompilerOption.toDString )
					{
						if( fpos < bpos )
						{
							_opt = s[fpos+5..bpos];
							_compiler = s[0..fpos];
						}
						else
						{
							_opt = s[0..bpos];
						}
						return true;
					}
				}			
			}
		}
		return false;
	}
	
	version(DIDE)
	{
		static bool setActiveDefaultCompilerAndIncludePaths()
		{
			// Get Custom Compiler
			char[] customOpt, customCompiler;
			getCustomCompilers( customOpt, customCompiler );
			if( customCompiler.length )
			{
				if( customCompiler != GLOBAL.defaultCompilerPath )
				{
					if( customCompiler != GLOBAL.defaultCompilerPath ) GLOBAL.defaultImportPaths = tools.getImportPath( customCompiler );
					GLOBAL.defaultCompilerPath = customCompiler;
				}
				return true;
			}
			
			// Set Multiple Focus Project
			char[] _finalCompilerPath;
			char[] activePrjDir = GLOBAL.activeProjectPath;//.length ? GLOBAL.activeProjectPath : actionManager.ProjectAction.getActiveProjectName();
			if( activePrjDir.length )
			{
				if( activePrjDir in GLOBAL.projectManager )
				{
					if( !GLOBAL.projectManager[activePrjDir].focusOn.length )
					{
						_finalCompilerPath = GLOBAL.projectManager[activePrjDir].compilerPath.length ? GLOBAL.projectManager[activePrjDir].compilerPath : GLOBAL.compilerFullPath;
					}
					else
					{
						if( GLOBAL.projectManager[activePrjDir].focusOn in GLOBAL.projectManager[activePrjDir].focusUnit )
						{
							if( GLOBAL.projectManager[activePrjDir].focusUnit[GLOBAL.projectManager[activePrjDir].focusOn].Compiler.length )
								_finalCompilerPath = GLOBAL.projectManager[activePrjDir].focusUnit[GLOBAL.projectManager[activePrjDir].focusOn].Compiler;
							else
							{
								if( GLOBAL.projectManager[activePrjDir].compilerPath.length )
									_finalCompilerPath = GLOBAL.projectManager[activePrjDir].compilerPath;
								else
									_finalCompilerPath = GLOBAL.compilerFullPath;
							}
						}
					}
				}
			}
			else
			{
				_finalCompilerPath = GLOBAL.compilerFullPath;
			}
			
			if( _finalCompilerPath != GLOBAL.defaultCompilerPath )
			{
				GLOBAL.defaultCompilerPath = _finalCompilerPath;
				if( _finalCompilerPath.length )
					GLOBAL.defaultImportPaths = tools.getImportPath( GLOBAL.defaultCompilerPath );
				else
				{
					GLOBAL.defaultImportPaths.length = 0;
					return false;
				}
			}
		
			return true;
		}
	}
}