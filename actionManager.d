module actionManager;

public import executer;
private import iup.iup, iup.iup_scintilla;
private import global, tools;
private import std.string, std.file, std.conv, std.algorithm.mutation, Path = std.path, Uni = std.uni, Array = std.array;

// Action for FILE operate
struct FileAction
{
private:
	import std.stdio, std.encoding, std.utf, std.windows.charset;
	
	static bool isAscii( string src )
	{
		foreach( c; src )
			if( c & 0x80 ) return false;
		return true;
	}
	
	static bool isUTF8WithouBOM( ubyte[] data )
	{
		int size = cast(int) data.length;
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
			else
				return false;
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
	static void newFile( string fullPath )
	{
		auto _file = File( fullPath, "w" );
		_file.close;
	}


	static string loadFile( string fullPath, ref int encoding, ref int withBOM )
	{
		try
		{
			if( !std.file.exists( fullPath ) )
			{
				tools.MessageDlg( GLOBAL.languageItems["error"].toDString, fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString, "ERROR", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
				return null;
			}
			else
			{
				if( std.file.isDir( fullPath ) ) 
				{
					tools.MessageDlg( GLOBAL.languageItems["error"].toDString, fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString, "ERROR", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
					return null;
				}
			}
			
			auto str = cast(ubyte[]) std.file.read( fullPath );
			if( str.length )
			{
				auto _BOMSeq = getBOM( str );
				switch( _BOMSeq.schema )
				{
					case BOM.utf32le:		encoding = BOM.utf32le;		withBOM = true;		return toUTF8( cast(dchar[]) str[4..$] );
					case BOM.utf32be:		encoding = BOM.utf32be;		withBOM = true;		return toUTF8( cast(dchar[]) swapBytes( str[4..$], 4 ) );
					case BOM.utf16le:		encoding = BOM.utf16le;		withBOM = true;		return toUTF8( cast(wchar[]) str[2..$] );
					case BOM.utf16be:		encoding = BOM.utf16be;		withBOM = true;		return toUTF8( cast(wchar[]) swapBytes( str[2..$], 2 ) );
					case BOM.utf8:			encoding = BOM.utf8;		withBOM = true;		return cast(string) str[3..$];
					default:
				}
				// Check Without BOM
				withBOM = false;
				int BELE = isUTF32WithouBOM( str );
				if( BELE == 1 )
				{
					encoding = BOM.utf32be;		return toUTF8( cast(dchar[]) swapBytes( str, 4 ) );
				}
				else if( BELE == 2 )
				{
					encoding = BOM.utf32le;		return toUTF8( cast(dchar[]) str );
				}
				BELE = isUTF16WithouBOM( str );
				if( BELE == 1 )
				{
					encoding = BOM.utf16be;		return toUTF8( cast(wchar[]) swapBytes( str, 2 ) );
				}
				else if( BELE == 2 )
				{
					encoding = BOM.utf16le;		return toUTF8( cast(wchar[]) str );
				}
				
				if( isUTF8WithouBOM( str ) )
				{
					encoding = BOM.utf8;		return cast(string) str;
				}
				else
				{
					encoding = BOM.none;
					version(Windows) if( !isAscii( cast(string) str ) ) return fromMBSz( cast(immutable char*) (str~'\0') );
					return cast(string) str;
				}				
				
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "Bug", toStringz( "FileAction.loadFile() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			throw e;
		}

		return null;
	}
	

	static bool saveFile( string fullPath, string data, int _bom, int withBOM )
	{
		File _fp;
		try
		{
			_fp = File( fullPath, "w" );
			if( withBOM )
			{
				switch( cast(BOM) _bom )
				{
					case BOM.utf32le:	_fp.rawWrite( cast(ubyte[])[0xFF, 0xFE, 0x00, 0x00] );		_fp.rawWrite( toUTF32( data ) );									break;
					case BOM.utf32be:	_fp.rawWrite( cast(ubyte[])[0x00, 0x00, 0xFE, 0xFF] );		_fp.rawWrite( swapBytes( cast(ubyte[]) toUTF32( data ), 4 ) );		break;
					case BOM.utf16le:	_fp.rawWrite( cast(ubyte[])[0xFF, 0xFE] );					_fp.rawWrite( toUTF16( data ) );									break;
					case BOM.utf16be:	_fp.rawWrite( cast(ubyte[])[0xFE, 0xFF]);					_fp.rawWrite( swapBytes( cast(ubyte[]) toUTF16( data ), 2 ) );		break;
					case BOM.utf8:		_fp.rawWrite( cast(ubyte[])[0xEF, 0xBB, 0xBF]);				_fp.rawWrite( data );												break;
					default:			version( Windows ) _fp.rawWrite( fromStringz( toMBSz( data, 0 ) ) ); else _fp.rawWrite( data );																									break;
				}
				
				_fp.close;
				return true;
			}
			else
			{
				switch( _bom )
				{
					case BOM.utf32le:	_fp.rawWrite( toUTF32( data ) );									break;
					case BOM.utf32be:	_fp.rawWrite( swapBytes( cast(ubyte[]) toUTF32( data ), 4 ) );		break;
					case BOM.utf16le:	_fp.rawWrite( toUTF16( data ) );									break;
					case BOM.utf16be:	_fp.rawWrite( swapBytes( cast(ubyte[]) toUTF16( data ), 2 ) );		break;
					case BOM.utf8:		_fp.rawWrite( data );												break;
					default:
						version( Windows ) _fp.rawWrite( fromStringz( toMBSz( data, 0 ) ) ); else _fp.rawWrite( data );
				}

				_fp.close;
				return true;
			}
		}
		catch( Exception e )
		{
			if( _fp.isOpen ) _fp.close;
		}
		
		return false;
	}
}


struct DocumentTabAction
{
private:
	import scintilla;
	import std.file, Path = std.path, Uni = std.uni;
	
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

					// Marked the trees( ProjectTree )
					version(Windows) ProjectAction.clearDarkModeNodesForeColor();
					IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
					if( !( actionManager.ScintillaAction.toTreeMarked( cSci.getFullPath() ) & 2 ) )
					{
						GLOBAL.statusBar.setPrjName( "                                            " );
					}
					
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
				if( _cSci !is null ) IupSetStrAttributeId( GLOBAL.activeDocumentTabs , "TABTIP", i, toStringz( _cSci.getFullPath ) );
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
	
	
	static void setTabItemDocumentImage( Ihandle* workDocumentTab, int newDocumentPos, string _fullPath )
	{
		string _ext = Uni.toLower( Path.extension( _fullPath ) );
		
		version(FBIDE)
		{
			if( _ext == ".bas" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bas" );
			}
			else if( _ext == ".bi" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bi" );
			}
			else
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_txt" );
			}
		}
		else //version(DIDE)
		{
			if( _ext == ".d" )
			{
				IupSetAttributeId( workDocumentTab, "TABIMAGE", newDocumentPos, "icon_bas" );
			}
			else if( _ext == ".di" )
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
	
	static Ihandle* getDocumentAndPos( Ihandle* sci, out int documentPos )
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
		
		documentPos = -1;
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
					IupSetStrAttributeId( DestTabs, "TABTITLE", newDocumentPos, toStringz( beMoveDocumentCSci.getTitle ) );
					IupSetStrAttributeId( DestTabs, "TABTIP", newDocumentPos, toStringz( beMoveDocumentCSci.getFullPath ) );
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
	
	static string getBeforeWord( Ihandle* iupSci, int pos )
	{
		// Check before targetText word.......
		string	beforeWord;
		for( int j = pos; j >= 0; --j )
		{
			string _s = Uni.toLower( fSTRz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
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
		
		return reverse( beforeWord.dup );
	}
	
	static string getAfterWord( Ihandle* iupSci, int pos )
	{
		// Check after targetText word.......
		string	afterWord;
		for( int j = pos; j < IupGetInt( iupSci, "COUNT" ); ++j )
		{
			string _s = Uni.toLower( fSTRz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
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
	
	static string getTailWord( Ihandle* iupSci, int pos )
	{
		// Check after targetText word.......
		string tailWord;
		int line = ScintillaAction.getLinefromPos( iupSci, pos );
		int lineEndPos = cast(int) IupScintillaSendMessage( iupSci, 2136, line, 0 ); // SCI_GETLINEENDPOSITION 2136
		
		for( int j = --lineEndPos; j >= 0; --j )
		{
			string _s = Uni.toLower( fSTRz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
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
		
		return reverse( tailWord.dup );
	}	
	
	// hasTail = -1  Whatever, hasTail = 0  No Tail, hasTail = 1  Tail
	static int getKeyWordCount( Ihandle* iupSci, string target, string beforeWord, string tailWord = "" )
	{
		int count;
		
		// Search Document
		IupSetAttribute( iupSci, "SEARCHFLAGS", "WHOLEWORD" );
		IupSetInt( iupSci, "TARGETSTART", 0 );
		IupSetInt( iupSci, "TARGETEND", -1 );
		
		scope _t = new IupString( target );
		
		int findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) target.length, cast(ptrdiff_t) _t.toCString ); // SCI_SEARCHINTARGET = 2197,
		while( findPos != -1 )
		{
			if( getBeforeWord( iupSci, findPos - 1 ) == Uni.toLower( beforeWord ) )
			{
				if( tailWord.length )
				{
					if( getTailWord( iupSci, findPos ) == Uni.toLower( tailWord ) ) count++;
				}
				else
					count++;
			}
			
			IupSetInt( iupSci, "TARGETSTART", findPos + cast(int) target.length );
			IupSetInt( iupSci, "TARGETEND", -1 );
			findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) target.length, cast(ptrdiff_t) _t.toCString ); // SCI_SEARCHINTARGET = 2197,
		}		
		
		return count;
	}
	
	
	static bool isDoubleClick( char* status )
	{
		string _s = fSTRz( status );
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
	extern(C) alias ptrdiff_t function(ptrdiff_t DirectPointer, uint msg, size_t wparam, ptrdiff_t lparam) SciFnDirect;

	import dialogs.fileDlg, parser.ast;
	import scintilla, menu;
	import parser.scanner,  parser.token, parser.parser, parser.autocompletion;
	import std.encoding;
	
	static bool[string] preParsedIncludes;

public:
	static bool newFile( string fullPath, int _encoding, int _withBom, string existData = null, bool bCreateActualFile = true, int insertPos = -1 )
	{
		// FullPath had already opened
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
		{
			IupMessage( "Waring!!", toStringz( fullPath ~ "\n has already exist!" ) );
			return false;
		}

		auto _sci = new CScintilla( fullPath, null, _encoding, _withBom, insertPos );
		_sci.withBOM = cast(bool) _withBom;
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

		string _ext = Uni.toLower( Path.extension( fullPath ) );

		version(FBIDE)
		{
			if( tools.isParsableExt( _ext, 3 ) )
			{
				//Parser
				GLOBAL.outlineTree.loadFile( fullPath );
			}
		}
		version(DIDE)
		{
			if( _ext == ".d" || _ext == ".di" )
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

		// if( GLOBAL.enableParser == "ON" ) GLOBAL.compilerSettings.activeCompiler = tools.getActiveCompilerInformation();

		return true;
	}
	
	static bool openFile( string fullPath, int lineNumber = -1 )
	{	//import std.stdio;
		fullPath = tools.normalizeSlash( fullPath );
		
		// FullPath had already opened
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
		{
			Ihandle* ih = GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla;
			
			Ihandle* _documentTabs = DocumentTabAction.getDocumentTabs( ih );
			if( _documentTabs != null )	DocumentTabAction.setActiveDocumentTabs( _documentTabs ); else return false;
			version(Windows) ProjectAction.clearDarkModeNodesForeColor();
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
			}
			
			return true;
		}

		try
		{
			if( !std.file.exists( fullPath ) ) return false;
			
			if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );

			int		_bom, _withBom;
			string 	_text = FileAction.loadFile( fullPath, _bom, _withBom );
			
			// Parser
			if( fullPathByOS(fullPath) in GLOBAL.parserManager )
			{
				Ihandle* _tree = GLOBAL.outlineTree.getTree( fullPath );
				if( _tree == null )	GLOBAL.outlineTree.createTree( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)] );
				
				//GLOBAL.outlineTree.changeTree( fullPath );
				
				// Load and parse to fill up includesMarkContainer, for speed-up
				if( !( fullPathByOS(fullPath) in preParsedIncludes ) )
				{
					preParsedIncludes[fullPathByOS(fullPath)] = true;
					AutoComplete.cleanIncludeContainer();
					AutoComplete.setPreLoadContainer( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)] );
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
						AutoComplete.setPreLoadContainer( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)] );
					//}
				}
			}
			
			auto 	_sci = new CScintilla( fullPath, _text, _bom, _withBom, -1 );
			GLOBAL.scintillaManager[fullPathByOS(fullPath)] = _sci;

			// Set documentTabs to visible
			if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "YES" );
			version(Windows)
			{
				if( GLOBAL.bCanUseDarkMode )
				{
					int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
					if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) ) == "LEAF" ) IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id, toStringz( GLOBAL.editColor.projectFore ) );
				}
			}			
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
					foreach( size_t _pos, int value; GLOBAL.fileStatusManager[fullPath] )
					{
						if( _pos == 0 )
						{
							if( !bDirectGotoLine ) lineNumber = ScintillaAction.getLinefromPos( _sci.getIupScintilla, value ); else lineNumber --;
							fileStatusPos = value;
						}
						else
						{
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
			}

			StatusBarAction.update();

			return true;
		}
		catch( Exception e )
		{
			//GLOBAL.IDEMessageDlg.print( "openFile() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) );
			IupMessage( "Bug", toStringz( "openFile() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );

			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
			{
				auto _sci = GLOBAL.scintillaManager[fullPathByOS(fullPath)];
				if( _sci !is null ) destroy( _sci );
					
				GLOBAL.scintillaManager.remove( fullPathByOS(fullPath) );
			}
		}

		return false;
	}

	static int toTreeMarked( string fullPath, int _switch = 7 )
	{
		int result;
		
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{
			CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(fullPath)];
			if( cSci !is null )
			{
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
						string s = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
						if( fullPathByOS(s) == fullPathByOS(fullPath) )
						{
							IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
							IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );
							version(Windows) if( GLOBAL.bCanUseDarkMode ) IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id, toStringz( tools.invertColor( GLOBAL.editColor.prjViewHLT ) ) );
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
	
	static string getFullPath()
	{
		auto _sci = getActiveCScintilla();
		if( _sci !is null ) return _sci.getFullPath;
		return null;
	}

	static void gotoLine( string fileName, int lineNum )
	{
		openFile( fileName, lineNum );
	}
	
	static bool getModifyByTitle( CScintilla cSci )
	{
		if( cSci !is null )
		{
			string _title = cSci.getTitle();
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
			destroy( cSci) ;
			IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", "" );
			IupRefresh( GLOBAL.activeDocumentTabs );
			
			DocumentTabAction.updateTabsLayout();
		}
	}

	static int closeDocument( string fullPath, int pos = -1 )
	{
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{
			CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(fullPath)];
			if( cSci !is null )
			{
				//if( ScintillaAction.getModify( iupSci ) != 0 )
				if( ScintillaAction.getModifyByTitle( cSci ) )
				{
					if( pos > -1 ) IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" , pos ); 
					scope cStringDocument = new IupString( "\"" ~ fullPath ~ "\"\n" ~ GLOBAL.languageItems["bechange"].toDString() );
					
					int button = tools.MessageDlg( GLOBAL.languageItems["quest"].toDString(), cStringDocument.toDString, "QUESTION", "YESNOCANCEL", IUP_CENTER, IUP_CENTER );
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

	static int closeOthersDocument( string fullPath )
	{
		string[] KEYS;
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
						
						int button = tools.MessageDlg( GLOBAL.languageItems["quest"].toDString(), cStringDocument.toDString, "QUESTION", "YESNOCANCEL", IUP_CENTER, IUP_CENTER );
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

		foreach( s; KEYS )
		{
			if( fullPathByOS(s) in GLOBAL.scintillaManager )
			{
				CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(s)];
				if( cSci !is null )
				{
					//GLOBAL.fileListTree.removeItem( cSci );
					//GLOBAL.outlineTree.cleanTree( cSci.getFullPath );
					//IupDestroy( cSci );				
					destroy( cSci );
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
		
		
		string[] 	KEYS;
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
						int button = tools.MessageDlg( GLOBAL.languageItems["quest"].toDString, cStringDocument.toDString, "QUESTION", "YESNOCANCEL", IUP_CENTER, IUP_CENTER );
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

		foreach( s; KEYS )
		{
			if( fullPathByOS(s) in GLOBAL.scintillaManager )
			{
				CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(s)];
				if( cSci !is null )
				{
					//GLOBAL.fileListTree.removeItem( cSci );
					//GLOBAL.outlineTree.cleanTree( cSci.getFullPath );
					//IupDestroy( cSci );				
					destroy( cSci );
				}

				//GLOBAL.scintillaManager.remove( fullPathByOS(s) );
			}
		}
		
		DocumentTabAction.updateTabsLayout();

		StatusBarAction.update();
		DocumentTabAction.resetTip();
		IupSetAttribute( GLOBAL.toolbar.getListHandle(), "1", "" );
		
		return IUP_DEFAULT;
	}

	static bool saveFile( CScintilla cSci, bool bForce = false )
	{
		if( cSci is null ) return false;
		
		try
		{
			string fullPath = cSci.getFullPath();
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

			string fullPath = tools.normalizeSlash( dlg.getFileName() );
			switch( dlg.getFilterUsed )
			{
				case "1":
					version(FBIDE)
					{
						if( fullPath.length > 4 )
						{
							if( fullPath[$-4..$] == ".bas" ) fullPath = fullPath[0..$-4].dup;
						}
						fullPath ~= ".bas";
					}
					version(DIDE)
					{
						if( fullPath.length > 2 )
						{
							if( fullPath[$-2..$] == ".d" ) fullPath = fullPath[0..$-2].dup;
						}
						fullPath ~= ".d";
					}
					break;
				case "2":
					version(FBIDE)
					{
						if( fullPath.length > 3 )
						{
							if( fullPath[$-3..$] == ".bi" ) fullPath = fullPath[0..$-3].dup;
						}
						fullPath ~= ".bi";
					}
					version(DIDE)
					{
						if( fullPath.length > 3 )
						{
							if( fullPath[$-3..$] == ".di" ) fullPath = fullPath[0..$-3].dup;
						}
						fullPath ~= ".di";
					}					
					break;
				default:
			}
			
			if( fullPath.length )
			{
				if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) return saveFile( cSci );
				
				string newDocument = fSTRz( IupGetAttribute( cSci.getIupScintilla, "VALUE" ) );
				if( bShowNew ) ScintillaAction.newFile( fullPath, cSci.encoding, cSci.withBOM, newDocument, true, insertPos );
				FileAction.saveFile( fullPath, newDocument, cSci.encoding, cSci.withBOM );
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
	

	static string getCurrentChar( int bias, Ihandle* ih = null )
	{
		if( ih == null ) ih = getActiveIupScintilla();

		if( ih != null )
		{
			int pos = getCurrentPos( ih );
			return fSTRz( IupGetAttributeId( ih, "CHAR", pos + bias ) );
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
		//IupMessage("", toStringz( to!(string)(pos) ~ " / " ~ to!(string)(lineStartPos) ) );

		if( pos == 0 ) return false;
			
		for( int i = pos - 1; i >= lineStartPos; --i )
		{
			if( IupScintillaSendMessage( ih, 2010, i, 0 ) == 1 ) return true;
		}
		return false;
	}
	
	static void updateRecentFiles( string fullPath )
	{
		fullPath = tools.normalizeSlash( fullPath );
		if( fullPath.length )
		{
			IupString[]	temps;
			
			for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
			{
				if( GLOBAL.recentFiles[i].toDString != fullPath ) temps ~= new IupString( GLOBAL.recentFiles[i].toDString );
			}

			temps ~= new IupString( fullPath );
			
			for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
				destroy( GLOBAL.recentFiles[i]);
			
			int count, index;
			if( temps.length > 8 )
			{
				GLOBAL.recentFiles.length = 8;
				for( count = cast(int) temps.length - 8; count < cast(int) temps.length; ++count )
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
				destroy( GLOBAL.recentFiles[i] );
				
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
			if( GLOBAL.recentFiles.length )
			{
				IupInsert( recentFile_ih, null, IupSeparator() );
				IupMap( IupGetChild( recentFile_ih, 0 ) );
			}
			
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

	static string textWrap( string oriText, int textWidth = -1 )
	{
		if( textWidth == -1 )
		{
			try
			{
				Ihandle* actIupSci = getActiveIupScintilla;
				if( actIupSci != null )
				{
					string wh = fSTRz( IupGetAttribute( GLOBAL.mainDlg, "RASTERSIZE" ) );
					auto xPos = indexOf( wh, "x" );
					if( xPos > -1 )
					{
						auto spacePos = lastIndexOf( GLOBAL.fonts[1].fontString, " " );
						if( spacePos > -1 )
						{
							int size = to!(int)( GLOBAL.fonts[1].fontString[spacePos+1..$] );
							if( size > 6 )
							{
								size -= 2;
								int caretX = cast(int) IupScintillaSendMessage( actIupSci, 2164, 0, getCurrentPos( actIupSci ) ); // SCI_POINTXFROMPOSITION 2164
								textWidth =  cast(int) ( ( to!(float)( wh[0..xPos] ) - cast(float) caretX ) / cast(float) size );
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
	
		string result;
		string	tmp;
		char	last = ' ';
		int		count;
		
		
		for( int i = 0; i < oriText.length; ++ i )
		{
			if( ++count == textWidth )
			{
				result = result ~ "\n" ~ stripLeft( tmp );
				count = cast(int) tmp.length;
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
				if( count + tmp.length < textWidth ) result ~= tmp; else result = result ~ "\n" ~ stripLeft( tmp );

		}
		
		return result;
	}
	
	static ptrdiff_t directSendMessage( Ihandle* ih, uint msg, size_t wParam, ptrdiff_t lParam )
	{
		auto directFunction = cast(SciFnDirect) IupScintillaSendMessage( ih, 2184, 0, 0 ); // #define SCI_GETDIRECTFUNCTION 2184
		auto directPointer = IupScintillaSendMessage( ih, 2185, 0, 0 ); // #define SCI_GETDIRECTPOINTER 2185
		return directFunction( directPointer, msg, wParam, lParam ); // #define SCI_APPENDTEXT 2282
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

	static string getActiveProjectName( bool bCheckScintilla = false )
	{
		if( bCheckScintilla )
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			if( cSci !is null ) return fileInProject( cSci.getFullPath );
		}
	
		// There is no any scintilla tabitem or force pass, search project node
		int id = getActiveProjectID();
		if( id < 1 ) return null;

		return fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;
	}

	static string getActiveProjectTreeNodeTitle()
	{
		int id = getActiveProjectID();

		if( id < 1 ) return null;
		
		return fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) );//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;
	}
	
	static bool changeActiveProjectTreeNodeTitle( string newName )
	{
		int id = getActiveProjectID();

		if( id < 1 ) return false;
		
		IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id, toStringz( newName ) );

		return true;
	}

	static int addTreeNode( string _prjDirName, string fullPath, int folderLocateId )
	{
		string _titleName;

		auto pos = indexOf( fullPath, _prjDirName );
		if( pos == 0 ) 	_titleName = Array.replace( fullPath, _prjDirName, "" );

		if( _titleName.length )
		{
			// Check the child Folder
			string[] splitText = Array.split( _titleName, "/" );
		
			int counterSplitText;
			for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
			{
				int 	countChild = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "COUNT", folderLocateId );

				bool bFolerExist = false;
				for( int i = 1; i <= countChild; ++ i )
				{
					string	kind = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", folderLocateId + i ) );
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
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId, "FIXED" );
					}
					else
					{
						IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, toStringz( splitText[counterSplitText] ) );
					}
					
					folderLocateId ++;
				}
			}
		}
		
		return folderLocateId;
	}

	static string fileInProject( string fullPath, string projectName = null )
	{
		if( fullPath.length )
		{
			if( projectName.length )
			{
				if( projectName in GLOBAL.projectManager )
				{
					foreach( prjFileFullPath; GLOBAL.projectManager[projectName].sources ~ GLOBAL.projectManager[projectName].includes )
					{
						if( fullPath == prjFileFullPath ) return projectName;
					}
				}
			}
			else
			{
				foreach( p; GLOBAL.projectManager )
				{
					foreach( prjFileFullPath; p.sources ~ p.includes )
					{
						if( fullPath == prjFileFullPath ) return p.dir;
					}
				}
			}
		}

		return null;
	}
	
	static string getActiveProjectDir()
	{
		auto cSci = ScintillaAction.getActiveCScintilla();

		if( cSci !is null )
		{
			foreach( p; GLOBAL.projectManager )
			{
				foreach( prjFileFullPath; p.sources ~ p.includes )
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
				foreach( prjFileFullPath; p.sources ~ p.includes )
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
		string 	status = fSTRz( IupGetAttribute( GLOBAL.projectTree.getTreeHandle,"MARKEDNODES" ) );
		
		for( int i = 0; i < status.length; ++ i )
		{
			if( status[i] == '+' ) result ++;
		}
		
		return result;
	}
	
	static int[] getSelectIDs()
	{
		int[]	result;
		string 	status = fSTRz( IupGetAttribute( GLOBAL.projectTree.getTreeHandle,"MARKEDNODES" ) );
		
		for( int i = 0; i < status.length; ++ i )
		{
			if( status[i] == '+' ) result ~= i;
		}
		
		return result;
	}
	
	version(Windows)
	{
		static void clearDarkModeNodesForeColor( int id = -1 )
		{
			if( GLOBAL.bCanUseDarkMode )
			{
				if( id == -1 )
				{
					foreach( int _i; ProjectAction.getSelectIDs() )
						if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", _i ) ) == "LEAF" ) IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", _i, toStringz( GLOBAL.editColor.projectFore ) );
				}
				else
				{
					if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) ) == "LEAF" ) IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id, toStringz( GLOBAL.editColor.projectFore ) );
				}
			}
		}
	}
}


struct StatusBarAction
{
private:
	import parser.autocompletion, parser.ast, scintilla;
	import std.format, std.encoding;
	
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
				GLOBAL.statusBar.setLINExCOL( format( "%-7sx%-5s", line, col ) );

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

				switch( cast(BOM) cSci.encoding )
				{
					case BOM.none:
						GLOBAL.statusBar.setEncodingType( "DEFAULT    " ); break;
					case BOM.utf8:
						if( cSci.withBOM ) GLOBAL.statusBar.setEncodingType( "UTF8.BOM   " ); else GLOBAL.statusBar.setEncodingType( "UTF8       " ); break;
					case BOM.utf16le:
						if( cSci.withBOM ) GLOBAL.statusBar.setEncodingType( "UTF16LE.BOM" ); else GLOBAL.statusBar.setEncodingType( "UTF16LE    " ); break;
					case BOM.utf16be:
						if( cSci.withBOM ) GLOBAL.statusBar.setEncodingType( "UTF16BE.BOM" ); else GLOBAL.statusBar.setEncodingType( "UTF16BE    " ); break;
					case BOM.utf32le:
						if( cSci.withBOM ) GLOBAL.statusBar.setEncodingType( "UTF32LE.BOM" ); else GLOBAL.statusBar.setEncodingType( "UTF32LE    " ); break;
					case BOM.utf32be:
						if( cSci.withBOM ) GLOBAL.statusBar.setEncodingType( "UTF32BE.BOM" ); else GLOBAL.statusBar.setEncodingType( "UTF32BE    " ); break;
					default:
						GLOBAL.statusBar.setEncodingType( "UNKNOWN?   " );
				}

				if( GLOBAL.showFunctionTitle == "ON" )
				{
					if( GLOBAL.enableParser == "ON" )
					{
						if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager )
						{
							CASTnode AST_Head = actionManager.ParserAction.getActiveASTFromLine( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], line );
							
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
										IupSetStrAttribute( GLOBAL.toolbar.getListHandle(), "1", toStringz( "this" ) );
										IupSetAttribute( GLOBAL.toolbar.getListHandle(), "IMAGE1","IUP_ctor" );
									}
									else if( AST_Head.kind & D_DTOR )
									{
										IupSetStrAttribute( GLOBAL.toolbar.getListHandle(), "1", toStringz( "~this") );
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
	import parser.ast, parser.scanner, parser.parser;

public:
	static CASTnode getActiveParseAST()
	{
		CScintilla cSci = ScintillaAction.getActiveCScintilla();
		
		if( cSci !is null )
		{
			auto _parserManager = cast(CASTnode[string]) GLOBAL.parserManager;
			if( fullPathByOS( cSci.getFullPath ) in _parserManager ) return _parserManager[fullPathByOS( cSci.getFullPath )];
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
			//	IupMessage("_fatherNode",toStringz( to!(string)( _fatherNode.lineNumber ) ~ "~" ~ to!(string)( _fatherNode.endLineNum )  ) );
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
	
	static string removeArrayAndPointer( string word )
	{
		string result;
		
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

	static string getSeparateType( string _string, bool bemoveArrayAndPoint = false )
	{
		auto openParenPos = indexOf( _string, "(" );

		if( openParenPos > 0 ) // should be >= 1
		{
			version(DIDE) if( _string[openParenPos-1] == '!' ) openParenPos = indexOf( _string, "(", openParenPos + 1 );
		}
		
		if( openParenPos > -1 )
		{
			if( bemoveArrayAndPoint ) return removeArrayAndPointer( _string[0..openParenPos] ); else return _string[0..openParenPos].dup;
		}

		return !bemoveArrayAndPoint ? _string : removeArrayAndPointer( _string );
	}

	static string getSeparateParam( string _string )
	{
		auto openParenPos = indexOf( _string, "(" );

		if( openParenPos > 0 ) // should be >= 1
		{
			version(DIDE) if( _string[openParenPos-1] == '!' ) openParenPos = indexOf( _string, "(", openParenPos + 1 );
		}
		
		if( openParenPos > -1 )
		{
			return _string[openParenPos..$].dup;
		}

		return null;
	}	
	
	static void getSplitDataFromNodeTypeString( string s, ref string _type, ref string _paramString, bool bemoveArrayAndPoint = false  )
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
			while( !node.kind & ( D_CLASS | D_STRUCT | D_INTERFACE ) );
		}
		else
		{
			return null;
		}
		
		return node;
	}
	
	static string[] getDivideWordWithoutSymbol( string word )
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

			return _i;
		}

		string[]	splitWord;
		string		tempWord;
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
					}
				}
				else if( word[i] == '[' )
				{
					returnIndex = _getDelimitedString( i, '[', ']' );
					if( returnIndex < word.length )
					{
						i = returnIndex;
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
	
	
	// No GLOBAL depend function
	static CASTnode createParser( string fullPath, bool bSaveInManager = false )
	{
		string _ext = Path.extension( fullPath );
		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) )	return null;
		version(DIDE)	if( !tools.isParsableExt( _ext, 3 ) )	return null;		

		if( std.file.exists( fullPath ) )
		{
			scope _parser = new CParser( Scanner.scanFile( fullPath ) );
			auto _ast = _parser.parse( fullPath );
			if( _ast !is null && bSaveInManager ) GLOBAL.parserManager[fullPathByOS(fullPath)] = cast(shared CASTnode) _ast;
			return _ast;
		}
		return null;
	}	
	
	// No GLOBAL depend function
	static CASTnode loadParser( string fullPath, bool bSaveInManager = false )
	{
		string _ext = Path.extension( fullPath );
		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) )	return null;
		version(DIDE)	if( !tools.isParsableExt( _ext, 3 ) )	return null;		

		if( fullPathByOS(fullPath) in GLOBAL.parserManager )
		{
			return cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)];
		}
		else
		{
			// Don't Create Tree
			// Parser
			if( std.file.exists( fullPath ) )
			{
				scope _parser = new CParser( Scanner.scanFile( fullPath ) );
				auto _ast = _parser.parse( fullPath );
				if( _ast !is null && bSaveInManager ) GLOBAL.parserManager[fullPathByOS(fullPath)] = cast(shared CASTnode) _ast;
				return _ast;
			}
		}
		return null;
	}
	
	// No GLOBAL depend function
	static CASTnode createParserByText( string fullPath, string document, bool bSaveInManager = false )
	{
		string _ext = Path.extension( fullPath );
		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) )	return null;
		version(DIDE)	if( !tools.isParsableExt( _ext, 3 ) )	return null;

		scope _parser = new CParser( Scanner.scan( document ) );
		auto _ast = _parser.parse( fullPath );
		if( _ast !is null && bSaveInManager ) GLOBAL.parserManager[fullPathByOS(fullPath)] = cast(shared CASTnode) _ast;
		return _ast;
	}
	
	static CASTnode loadObjectParser()
	{
		int bom, withBom;
		
		try
		{
			version(FBIDE)
			{
				string objectFilePath = GLOBAL.poseidonPath ~ "/settings/json/FB_BuiltinFunctions.json";
				if( std.file.exists( objectFilePath ) ) return GLOBAL.Parser.json2Ast( FileAction.loadFile( objectFilePath, bom, withBom ) );
			}
			else //version(DIDE)
			{
				string objectFilePath = GLOBAL.poseidonPath ~ "/settings/json/ObjectD2.json";
				if( tools.DMDversion( GLOBAL.compilerSettings.compilerFullPath ) == 1 ) objectFilePath = GLOBAL.poseidonPath ~ "/settings/json/ObjectD1.json";
				if( std.file.exists( objectFilePath ) ) return GLOBAL.Parser.json2Ast( FileAction.loadFile( objectFilePath, bom, withBom ) );
			}
		}
		catch( Exception e)
		{
			IupMessage("",toStringz( e.toString ) );
		}
		
		return null;
	}	
}


// Action for FILE operate
struct SearchAction
{
private:
	import scintilla, project, menu;

	static int _find( Ihandle* ih, string targetText, int type = 2, bool bNext = true )
	{
		int			findPos = -1;

		if( !( type & MATCHCASE ) ) targetText = Uni.toLower( targetText );

		//IupMessage( "Text:", toStringz(targetText) );
		
		int currentPos = cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		int	documentLength = IupGetInt( ih, "COUNT" );
		IupScintillaSendMessage( ih, 2198, type, 0 ); // SCI_SETSEARCHFLAGS = 2198,

		if( targetText.length )
		{
			scope _t = new IupString( targetText );
			IupScintillaSendMessage( ih, 2190, currentPos, 0 ); 						// SCI_SETTARGETSTART = 2190,
			if( bNext )	IupScintillaSendMessage( ih, 2192, documentLength, 0 ); else IupScintillaSendMessage( ih, 2192, 0, 0 );

			findPos = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
			
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

				findPos = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
			}
	
			if( findPos < 0 )
			{
				return -1;
			}
			else
			{
				string pos;
				if( bNext )
				{
					pos = to!(string)( findPos ) ~ ":" ~ to!(string)( findPos+targetText.length );
				}
				else
				{
					pos = to!(string)( findPos+targetText.length ) ~ ":" ~ to!(string)( findPos );
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
	static const int WHOLEWORD = 2;
	static const int MATCHCASE = 4;
	
	static int search( Ihandle* iupSci, string findText, int searchRule, bool bForward = true )
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

	static bool IsWholeWord( string lineData, string target, ptrdiff_t pos )
	{
		int targetPLUS1, targetMinus1;
		
		if( pos == 0 )
		{
			targetMinus1 = 32; // Ascii 32 = space
			if( lineData.length == target.length )
				targetPLUS1 = 32;
			else if( lineData.length > target.length )
				targetPLUS1 = cast(int)lineData[target.length];
			else
				targetPLUS1 = 48; // Not Match
		}
		else if( pos + target.length == lineData.length )
		{
			targetMinus1 = cast(int)lineData[pos-1];
			targetPLUS1 = 32; // Ascii 32 = space
		}
		else if( pos + target.length < lineData.length )
		{
			targetMinus1 = cast(int)lineData[pos-1];
			targetPLUS1 = cast(int)lineData[pos+target.length];
		}
		else
		{
			targetMinus1 = 48;//cast(int)lineData[pos-1];
			targetPLUS1 = 48; // Not Match
		}
		

		//IupMessage( "Minus:Plus", toStringz( to!(string)( targetMinus1 ) ~ ":" ~ to!(string)( targetPLUS1 ) ) );

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
	static int findInOneFile( string fullPath, string findText, string replaceText, int searchRule = 6, int buttonIndex = 0 )
	{
		int		count, _encoding, _withbom;
		bool	bInDocument;

		try
		{
			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) bInDocument = true;
			if( std.file.exists( fullPath ) || bInDocument )
			{
				if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
				IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 1 );

				string 	document;
				//string	splitLineDocument;
				if( bInDocument )
				{
					document = fSTRz( IupGetAttribute( GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla, "VALUE" ) );
				}
				else
				{
					if( buttonIndex == 3 ) return 0;
					document = FileAction.loadFile( fullPath, _encoding, _withbom );
				}			

				if( buttonIndex == 1 )
				{
					ptrdiff_t findIndex = 0;
					while( findIndex > -1 )
					{
						if( searchRule & MATCHCASE )
						{
							findIndex = indexOf( document, findText, findIndex );
						}
						else
						{
							findIndex = indexOf( Uni.toLower( document ), Uni.toLower( findText ), findIndex );
						}
						
						if( findIndex > -1 )
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
						IupSetStrAttribute( GLOBAL.scintillaManager[fullPathByOS( fullPath )].getIupScintilla, "VALUE", toStringz( document ) );
					}
					else
					{
						FileAction.saveFile( fullPath, document, _encoding, _withbom );
					}
					
					return count;
				}

				int lineNum;
				foreach( line; splitLines( document ) )
				{
					lineNum++;

					if( line.length )
					{
						ptrdiff_t pos;
						if( !( searchRule & MATCHCASE ) )
						{
							pos = indexOf( Uni.toLower( line ), Uni.toLower( findText ) );
						}
						else
						{
							pos = indexOf( line , findText );
						}
						
						if( pos > -1 )
						{
							if( searchRule & WHOLEWORD )
							{
								bool bGetWholeWord;
								while( pos > -1 )
								{
									if( ( pos < 0 ) || ( pos + findText.length > line.length ) ) break;
									if( IsWholeWord( line, findText, pos ) )
									{
										bGetWholeWord = true;
										break;
									}
									else
									{
										pos = indexOf( line, findText, pos + findText.length );
									}
								}
								
								if( !bGetWholeWord ) continue;
							}
							
							count++;
							
							if( buttonIndex == 0 )
							{
								string outputWords = fullPath ~ "(" ~ to!(string)( lineNum ) ~ "): " ~ strip( line );
								GLOBAL.messagePanel.printSearchOutputPanel( outputWords );
							}
							else if( buttonIndex == 3 )
							{
								if( bInDocument )
								{
									if( !( IupGetIntId( GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla, "MARKERGET", lineNum-1 ) & 2 ) ) IupSetIntId( GLOBAL.scintillaManager[fullPathByOS(fullPath)].getIupScintilla, "MARKERADD", lineNum-1, 1 );
								}
							}
						}
					}
				}
			}
		}
		catch( Exception e )
		{
			throw e;
		}

		return count;
	}
	
	static void addListItem( Ihandle* ih, string text, int limit = 15 )
	{
		if( ih != null )
		{
			int itemCount = IupGetInt( ih, "COUNT" );
			
			for( int i = itemCount; i > 0; --i )
			{
				string itemText = fSTRz( IupGetAttributeId( ih, "", i ) );
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
				IupSetStrAttributeId( ih, "INSERTITEM", 1, toStringz( text ) );
			}
			else
			{
				IupSetStrAttributeId( ih, "INSERTITEM", 1, toStringz( text ) );
			}
		}
	}
}


// Action for FILE operate
struct CustomToolAction
{
private:
	import project;
	
public:	
	static void run( CustomTool tool )
	{
		if( !std.file.exists( tool.dir ) )
		{
			tools.MessageDlg( GLOBAL.languageItems["error"].toDString, tool.dir ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString, "ERROR", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
			return;
		}
		
		bool bGoPlugin;
		version(Windows)
		{
			if( Uni.toLower( Path.extension( tool.dir ) ) == ".dll" ) bGoPlugin = true;
		}
		version(linux)
		{
			if( Uni.toLower( Path.extension( tool.dir ) ) == ".so" ) bGoPlugin = true;
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
							destroy( temp );
							GLOBAL.pluginMnager[tool.name] = new CPLUGIN( tool.name, tool.dir );
							GLOBAL.pluginMnager[tool.name].go();
						}
					}
					else
					{
						tools.MessageDlg( GLOBAL.languageItems["error"].toDString, tool.name ~ " Is Null", "ERROR", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
						GLOBAL.pluginMnager.remove( tool.name );
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
				IupMessage( "CustomTool Run()", toStringz( e.toString ) );
				if( tool.name in GLOBAL.pluginMnager ) GLOBAL.pluginMnager.remove( tool.name );
			}
		}
		else
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			string args;
			if( cSci !is null )
			{
				// %s Selected Text
				string s = fSTRz( IupGetAttribute( cSci.getIupScintilla, toStringz("SELECTEDTEXT") ) );
				
				// %s% Selected Word
				args = Array.replace( tool.args, "%s%", s );
				args = Array.replace( args, "\"%s%\"", "\"" ~ s ~ "\"" );
				
				// %f% Active File
				string fPath = cSci.getFullPath;
				args = Array.replace( args, "%f%", fPath );
				args = Array.replace( args, "\"%f%\"", "\"" ~ fPath ~ "\"" );
				
				args = Array.replace( args, "%fn%", Path.dirName( fPath ) ~ "/" ~ Path.stripExtension( Path.baseName( fPath ) ) );
				args = Array.replace( args, "\"%fn%\"", "\"" ~ Path.dirName( fPath ) ~ "/" ~ Path.stripExtension( Path.baseName( fPath ) ) ~ "\"" );
				
				args = Array.replace( args, "%fdir%", Path.dirName( fPath ) );
				args = Array.replace( args, "\"%fdir%\"", "\"" ~ Path.dirName( fPath ) ~ "\"" );
			}
			
			string pDir = ProjectAction.getActiveProjectDir;
			if( pDir.length )
			{
				string pName = GLOBAL.projectManager[pDir].name;
				string pTargetName = GLOBAL.projectManager[pDir].targetName;
				string pTotal;
				
				if( !pTargetName.length ) pTotal = pDir ~ "/" ~ pName; else	pTotal = pDir ~ "/" ~ pTargetName;
				
				args = Array.replace( args, "%pn%", pTotal );
				args = Array.replace( args, "\"%pn%\"", "\"" ~ pTotal ~ "\"" );
				
				string pAllFiles;
				foreach( s; GLOBAL.projectManager[pDir].sources )
					pAllFiles ~= ( s ~ " " );

				foreach( s; GLOBAL.projectManager[pDir].includes )
					pAllFiles ~= ( s ~ " " );
				
				pAllFiles = strip( pAllFiles );
				args = Array.replace( args, "%p%", pAllFiles );
				args = Array.replace( args, "\"%p%\"", "\"" ~ pAllFiles ~ "\"" );
				
				args = Array.replace( args, "%pdir%", pDir );
				args = Array.replace( args, "\"%pdir%\"", "\"" ~ pDir ~ "\"" );			
			}
			else
			{
				args = Array.replace( args, "%pn%", "" );
				args = Array.replace( args, "\"%pn%\"", "" );
				
				args = Array.replace( args, "%p%", "" );
				args = Array.replace( args, "\"%p%\"", "" );
				
				args = Array.replace( args, "%pdir%", "" );
				args = Array.replace( args, "\"%pdir%\"", "" );
			}		

			string useConsole = tool.toggleShowConsole == "ON" ? "1 " : "0 ";
			version(Windows)
			{
				if( useConsole == "1 " )
				{
					if( GLOBAL.consoleWindow.id < GLOBAL.monitors.length )
					{
						int x = GLOBAL.consoleWindow.x + GLOBAL.monitors[GLOBAL.consoleWindow.id].x;
						int y = GLOBAL.consoleWindow.y + GLOBAL.monitors[GLOBAL.consoleWindow.id].y;
						
						args = "0 " ~ to!(string)( x ) ~ " " ~ to!(string)( y ) ~ " " ~ to!(string)( GLOBAL.consoleWindow.w ) ~ " " ~ to!(string)( GLOBAL.consoleWindow.h ) ~ " " ~ useConsole ~ tool.dir ~ " " ~ args;
					}
					else
					{
						args = "0 0 0 0 0 " ~ useConsole ~ tool.dir ~ " " ~ args;
					}
					
					args = Array.replace( args, "/", "\\" );
				
					IupExecute( "consoleLauncher", toStringz( args ) );
				}
				else
				{
					IupExecute( toStringz( tool.dir ), toStringz( args ) );
				}
			}
			else
			{
				string command = Array.replace( tool.dir, " ", "\\ " ); // For space in path;
				if( useConsole == "1 " )
				{
					if( command[0] == '"' && command[$-1] == '"' )
						args = "\"" ~ GLOBAL.poseidonPath ~ "consoleLauncher " ~ to!(string)( GLOBAL.consoleWindow.id ) ~ " -1 -1 " ~ to!(string)( GLOBAL.consoleWindow.w ) ~ " " ~ to!(string)( GLOBAL.consoleWindow.h ) ~ " 1 " ~ command[1..$-1] ~ " " ~ args ~ "\"";
					else
						args = "\"" ~ GLOBAL.poseidonPath ~ "consoleLauncher " ~ to!(string)( GLOBAL.consoleWindow.id ) ~ " -1 -1 " ~ to!(string)( GLOBAL.consoleWindow.w ) ~ " " ~ to!(string)( GLOBAL.consoleWindow.h ) ~ " 1 " ~ command ~ " " ~ args ~ "\"";
						
						
					string geoString;
					if( GLOBAL.consoleWindow.id < GLOBAL.monitors.length )
					{
						int x = GLOBAL.consoleWindow.x + GLOBAL.monitors[GLOBAL.consoleWindow.id].x;
						int y = GLOBAL.consoleWindow.y + GLOBAL.monitors[GLOBAL.consoleWindow.id].y;
						int w = GLOBAL.consoleWindow.w < 80 ? 80 : GLOBAL.consoleWindow.w;
						int h = GLOBAL.consoleWindow.h < 24 ? 24 : GLOBAL.consoleWindow.h;
						//geoString = " --geometry=80x24+" ~ to!(string)( x ) ~ "+" ~ to!(string)( y );
						geoString = " --geometry=" ~ to!(string)( w ) ~ "x" ~ to!(string)( h ) ~ "+" ~ to!(string)( x ) ~ "+" ~ to!(string)( y );
					}
					
					if( GLOBAL.linuxTermName.length )
					{
						switch( strip( GLOBAL.linuxTermName ) )
						{
							case "xterm", "uxterm":
								geoString = Array.replace( geoString, "--geometry=", "-geometry " );
								args = "-T poseidon_terminal" ~ geoString ~ " -e " ~ args;
								break;
							case "mate-terminal" ,"xfce4-terminal" ,"lxterminal", "gnome-terminal", "tilix":
								args = "--title poseidon_terminal" ~ geoString ~ " -e " ~ args;
								break;

							default:
								args = "-e " ~ args;
						}
						
						IupExecute( toStringz( GLOBAL.linuxTermName ), toStringz( args ) );
					}						
				}
				else
				{
					IupExecute( toStringz( tool.dir ), toStringz( args ) );
				}
			}
		}
	}
	
	static bool getCustomCompilers( ref string _opt, ref string _compiler )
	{
		if( GLOBAL.compilerSettings.currentCustomCompilerOption.length )
		{
			foreach( s; GLOBAL.compilerSettings.customCompilerOptions )
			{
				auto bpos = lastIndexOf( s, "%::% " );
				auto fpos = indexOf( s, "%::% " );
				if( bpos > -1 )
				{
					if( s[bpos+5..$] == GLOBAL.compilerSettings.currentCustomCompilerOption )
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
}