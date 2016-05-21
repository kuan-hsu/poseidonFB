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
	import tango.text.convert.Utf, tango.io.UnicodeFile, tango.io.device.File;
	version( Windows ) import tango.sys.win32.CodePage;

	static bool isUTF8WithouBOM( char[] data )
	{
		for( int i = 0; i < data.length; ++ i )
		{
			if( data[i] < 0x80 )
			{
				continue;
			}
			else
			{
				bool bChecked;
				for( int k = 1; k < 6; ++ k )
				{
					if( ( data[i] >> k ) == ( (254 >> k) - 1 ) )
					{
						if( i <= data.length - ( 7 - k ) )
						{
							for( int j = 1; j < (7 - k); ++ j)
							{
								if( data[i+j] >> 6 != 2 ) return false;
							}

							bChecked = true;
							i += ( 7 - k - 1 );
							break;
						}
					}
				}
				if( !bChecked ) return false;
			}
		}

		return true;
	}

	static int isUTF16WithouBOM( char[] data )
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

		if( countBE && countLE ) return 0;

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

	static int isUTF32WithouBOM( char[] data )
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

	public:
	static void newFile( char[] fullPath )
	{
		auto _file = new File( fullPath, File.ReadWriteCreate );
		_file.close;
		
		scope file = new UnicodeFile!(char)( fullPath, Encoding.Unknown );
	}

	static char[] loadFile( char[] fullPath, inout int _encoding )
	{
		char[] result;
		
		scope file = new UnicodeFile!(char)( fullPath, Encoding.Unknown );
		char[] text = file.read;

		if( !file.bom.encoded )
		{
			//IupMessage( "No Bom", toStringz( Integer.toString( file.encoding() ) ) );
			if( isUTF8WithouBOM( text ) )
			{
				result = text;
				_encoding = Encoding.UTF_8N;
			}
			else
			{	
				int BELE = isUTF32WithouBOM( text );
				if( BELE > 0 )
				{
					ubyte[]	bomData;
					scope _bom = new UnicodeBom!(char)( Encoding.Unknown );
					
					if( BELE == 1 )
					{
						bomData = [ 0x00, 0x00 , 0xFE, 0xFF ];
						_encoding = 9;
					}
					else
					{
						bomData = [ 0xFF, 0xFE , 0x00, 0x00 ];
						_encoding = 10;
					}

					for( int i = 3; i > -1; -- i )
						text = cast(char)bomData[i] ~ text;

					result = _bom.decode( text );
				}
				else
				{
					//IupMessage( "No Bom 16", toStringz( Integer.toString( BELE ) ) );
					BELE = isUTF16WithouBOM( text );
					if( BELE > 0 )
					{
						ubyte[]	bomData;
						scope _bom = new UnicodeBom!(char)( Encoding.Unknown );
						
						if( BELE == 1 )
						{
							bomData = [ 0xFE, 0xFF ];
							_encoding = Encoding.UTF_16BE;
						}
						else
						{
							bomData = [ 0xFF, 0xFE ];
							_encoding = Encoding.UTF_16LE;
						}
						

						for( int i = 1; i >= 0; -- i )
							text = cast(char)bomData[i] ~ text;

						result = _bom.decode( text );
					}
					else
					{
						version( Windows )
						{
							if( !CodePage.isAscii( text ) ) // MBCS
							{
								char[] _text;
								_text.length = 2 * text.length;
								result = CodePage.from( text, _text );
								_text.length = result.length;
								_encoding = Encoding.Unknown;
							}
							else
							{
								result = text;
							}
						}
						else
						{
							result = text;
						}
					}
				}					
			}
		}
		else
		{
			_encoding = file.encoding();
			result = text;
		}

		return result;
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

				default:
					scope file = new UnicodeFile!(char)( fullPath, Encoding.UTF_8 );
					file.write( data, true );
			}
		}
		catch
		{
			IupMessage("","ERROR");
			return false;
		}

		return true;
	}
	
}


struct DocumentTabAction
{
	private:
	import scintilla;
	
	public:
	static int tabChangePOS( Ihandle* ih, int new_pos, int old_pos )
	{
		Ihandle* _child = IupGetChild( ih, new_pos );
		CScintilla cSci = actionManager.ScintillaAction.getCScintilla( _child );
		
		if( cSci !is null )
		{
			IupSetFocus( _child );
			StatusBarAction.update();

			// Marked the trees( FileList & ProjectTree )
			actionManager.ScintillaAction.toTreeMarked( cSci.getFullPath() );
			GLOBAL.outlineTree.changeTree( cSci.getFullPath() );
		}

		return IUP_DEFAULT;
	}
}


struct ScintillaAction
{
	private:
	import tango.io.UnicodeFile, tango.io.FilePath, dialogs.fileDlg;
	import scintilla;
	import parser.scanner,  parser.token, parser.parser;

	public:
	static bool newFile( char[] fullPath, Encoding _encoding = Encoding.UTF_8, char[] existData = null, bool bCreateActualFile = true )
	{
		// FullPath had already opened
		if( upperCase(fullPath) in GLOBAL.scintillaManager ) 
		{
			IupMessage( "Waring!!", GLOBAL.cString.convert( fullPath ~ "\n has already exist!" ) );
			return false;
		}

		auto 	_sci = new CScintilla( fullPath );
		if( bCreateActualFile ) FileAction.newFile( fullPath );
		_sci.setEncoding( _encoding );
		GLOBAL.scintillaManager[upperCase(fullPath)] = _sci;

		// Set documentTabs to visible
		if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "YES" );

		// Set new tabitem to focus
		IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)_sci.getIupScintilla );
		IupSetFocus( _sci.getIupScintilla );

		//StatusBarAction.update();

		IupSetAttribute( GLOBAL.fileListTree, "ADDLEAF0", GLOBAL.cString.convert( fullPath ) );
		IupSetAttribute( GLOBAL.fileListTree, "USERDATA1", cast(char*) _sci  );

		if( existData.length) _sci.setText( existData );

		scope f = new FilePath( fullPath );

		if( lowerCase( f.ext() ) == "bas" || lowerCase( f.ext() ) == "bi" )
		{
			//Parser
			OutlineAction.loadFile( fullPath );
		}

		if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );

		return true;
	}
	
	static bool openFile( char[] fullPath, int lineNumber = -1 )
	{
		// FullPath had already opened
		if( upperCase(fullPath) in GLOBAL.scintillaManager ) 
		{
			Ihandle* ih = GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla;
			
			IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)ih );
			IupSetFocus( ih );
			if( lineNumber > -1 )
			{
				IupScintillaSendMessage( ih, 2024, --lineNumber, 0 ); // SCI_GOTOLINE 2024

				// If debug window is on, don't scroll to top
				if( fromStringz( IupGetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2 ) ) == "NO" )	IupSetAttribute( ih, "FIRSTVISIBLELINE", toStringz( Integer.toString( lineNumber ) ) );
			}
			StatusBarAction.update();

			toTreeMarked( fullPath );
			GLOBAL.outlineTree.changeTree( fullPath );

			return true;
		}

		try
		{
			scope filePath = new FilePath( fullPath );
			if( !filePath.exists ) return false;
			
			Encoding		_encoding;
			auto 	_sci = new CScintilla( fullPath );
			char[] 	_text = FileAction.loadFile( fullPath, _encoding );
			_sci.setEncoding( _encoding );
			_sci.setText( _text );
			GLOBAL.scintillaManager[upperCase(fullPath)] = _sci;

			// Set documentTabs to visible
			if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "YES" );

			// Set new tabitem to focus
			IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)_sci.getIupScintilla );
			IupSetFocus( _sci.getIupScintilla );
			if( lineNumber > -1 )
			{
				IupScintillaSendMessage( _sci.getIupScintilla, 2024, lineNumber - 1, 0 ); // SCI_GOTOLINE = 2024
			}
			//StatusBarAction.update();

			IupSetAttribute( GLOBAL.fileListTree, "ADDLEAF0", GLOBAL.cString.convert( fullPath ) );
			IupSetAttribute( GLOBAL.fileListTree, "USERDATA1", cast(char*) _sci  );
			IupSetAttributeId( GLOBAL.fileListTree, "MARKED", 1, "YES" );
			
			// Parser
			OutlineAction.loadFile( fullPath );

			if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );

			return true;
		}
		catch
		{
		}

		return false;
	}

	static void toTreeMarked( char[] fullPath, int _switch = 3 )
	{
		if( upperCase(fullPath) in GLOBAL.scintillaManager )
		{
			CScintilla cSci = GLOBAL.scintillaManager[upperCase(fullPath)];
			if( cSci !is null )
			{
				if( _switch & 1 ) // Mark the FileList
				{
					int nodeCount = IupGetInt( GLOBAL.fileListTree, "COUNT" );
					for( int id = 1; id <= nodeCount; id++ ) // Not include Parent "FileList" node
					{
						CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree, "USERDATA", id );
						if( _sci_node == cSci )
						{
							IupSetAttributeId( GLOBAL.fileListTree, "MARKED", id, "YES" );
							break;
						}
					}
				}

				if( _switch & 2 ) // Mark the ProjectTree
				{
					
					int nodeCount = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
					for( int id = 1; id <= nodeCount; id++ )
					{
						char[] s = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
						if( upperCase(s) == upperCase(fullPath) )
						{
							IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
							break;
						}
					}
				}
			}
		}
	}

	static bool removeFileListNode( char[] fullPath, CScintilla cSci )
	{
		// Remove the fileListTree's node
		int nodeCount = IupGetInt( GLOBAL.fileListTree, "COUNT" );
		
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree, "USERDATA", id );
			if( fullPath.length )
			{
				if( _sci_node.getFullPath == fullPath )
				{
					IupSetAttributeId( GLOBAL.fileListTree, "DELNODE", id, "SELECTED" );
					return true;
				}
			}
			else if( cSci !is null )
			{
				if( _sci_node == cSci )
				{
					IupSetAttributeId( GLOBAL.fileListTree, "DELNODE", id, "SELECTED" );
					return true;
				}
			}
		}

		return false;
	}

	static Ihandle* getActiveIupScintilla()
	{
		int pos = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
		return IupGetChild( GLOBAL.documentTabs, pos );

		/*
		for( int i = 0; i < IupGetChildCount( GLOBAL.documentTabs ); i++ )
		{
			Ihandle* _child = IupGetChild( GLOBAL.documentTabs, i );
			if( fromStringz( IupGetAttribute( _child, "VISIBLE" ) ) == "YES" )  // Active Tab Child
			{
				return _child;
			}
		}

		return null;
		*/
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

	static int closeDocument( char[] fullPath )
	{
		if( upperCase(fullPath) in GLOBAL.scintillaManager )
		{
			CScintilla	cSci		= GLOBAL.scintillaManager[upperCase(fullPath)];
			Ihandle*	iupSci		= cSci.getIupScintilla;

			if( fromStringz( IupGetAttribute( iupSci, "SAVEDSTATE" ) ) == "YES" )
			{
				int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ fullPath ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
				if( button == 3 ) return IUP_IGNORE;
				if( button == 1 )
				{
					if( fullPath.length >= 7 )
					{
						if( fullPath[0..7] == "NONAME#" )
						{
							saveAs( cSci );
							return IUP_DEFAULT;
						}
					}

					cSci.saveFile();
				}
			}
	
			IupDestroy( iupSci );
			removeFileListNode( null, cSci );
			GLOBAL.scintillaManager.remove( upperCase(fullPath) );
			delete cSci;
			actionManager.OutlineAction.cleanTree( fullPath );
			if( IupGetChildCount( GLOBAL.documentTabs ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 0 );
		}

		StatusBarAction.update();

		return IUP_DEFAULT;
	}

	static int closeOthersDocument( char[] fullPath )
	{
		char[][] KEYS;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( upperCase(cSci.getFullPath) != upperCase(fullPath) )
			{
				Ihandle* iupSci = cSci.getIupScintilla;
				
				if( fromStringz( IupGetAttribute( iupSci, "SAVEDSTATE" ) ) == "YES" )
				{
					IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*) iupSci );
					int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ cSci.getFullPath() ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
					if( button == 3 )
					{
						break;
					}
					else if( button == 2 )
					{
						KEYS ~= cSci.getFullPath;
					}					
					else if( button == 1 )
					{
						bool bNoNameFile;
						if( fullPath.length >= 7 )
						{
							if( fullPath[0..7] == "NONAME#" )
							{
								if( !saveAs( cSci, false ) ) break;
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

				removeFileListNode( null, cSci );
				actionManager.OutlineAction.cleanTree( cSci.getFullPath );
				IupDestroy( iupSci );
				delete cSci;
			}
		}

		foreach( char[] s; KEYS )
		{
			if( upperCase(s) != upperCase(fullPath) )	GLOBAL.scintillaManager.remove( upperCase(s) );
		}

		StatusBarAction.update();

		return IUP_DEFAULT;
	}	

	static int closeAllDocument()
	{
		char[][] 	KEYS;
		bool 		bCancel;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			Ihandle* iupSci = cSci.getIupScintilla;
			
			if( fromStringz( IupGetAttribute( iupSci, "SAVEDSTATE" ) ) == "YES" )
			{
				IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*) iupSci );
				int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ cSci.getFullPath() ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
				if( button == 3 )
				{
					bCancel = true;
					break;
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
							if( !saveAs( cSci, false ) )
							{
								bCancel = true;
								break;
							}
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

			removeFileListNode( null, cSci );
			actionManager.OutlineAction.cleanTree( cSci.getFullPath );
			IupDestroy( iupSci );
		}

		foreach( char[] s; KEYS )
		{
			CScintilla cSci = GLOBAL.scintillaManager[upperCase(s)];
			delete cSci;

			GLOBAL.scintillaManager.remove( upperCase(s) );
		}

		if( IupGetChildCount( GLOBAL.documentTabs ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 0 );

		if( bCancel ) return IUP_IGNORE;

		StatusBarAction.update();
		
		return IUP_DEFAULT;
	}

	static bool saveFile( CScintilla cSci )
	{
		if( cSci is null ) return false;
		
		try
		{
			if( fromStringz( IupGetAttribute( cSci.getIupScintilla, "SAVEDSTATE" ) ) == "YES" )
			{
				char[] fullPath = cSci.getFullPath();

				if( fullPath.length >= 7 )
				{
					if( fullPath[0..7] == "NONAME#" ) return saveAs( cSci, true );
				}

				cSci.saveFile();
				OutlineAction.refresh( fullPath ); //Update Parser
			}
		}
		catch
		{
			return false;
		}

		return true;
	}

	static bool saveAs( CScintilla cSci, bool bDel = false )
	{
		if( cSci is null ) return false;

		try
		{
			scope dlg = new CFileDlg( "Save As...", "Source File|*.bas|Inculde File|*.bi|All Files|*.*", "SAVE" );//"Source File|*.bas|Include File|*.bi" );

			char[] fullPath = dlg.getFileName();
			switch( dlg.getFilterUsed )
			{
				case "1":
					if( fullPath.length > 4 )
					{
						if( fullPath[length-4..length] == ".bas" ) fullPath = fullPath[0..length-4];
					}
					fullPath ~= ".bas";	break;
				case "2":
					if( fullPath.length > 3 )
					{
						if( fullPath[length-3..length] == ".bi" ) fullPath = fullPath[0..length-3];
					}
					fullPath ~= ".bi";
					break;
				default:
			}
			
			if( fullPath.length )
			{
				if( upperCase(fullPath) in GLOBAL.scintillaManager ) return saveFile( cSci );
				
				char[] newDocument = fromStringz( IupGetAttribute( cSci.getIupScintilla, "VALUE" ) ).dup;
				ScintillaAction.newFile( fullPath, Encoding.UTF_8, newDocument );
				FileAction.saveFile( fullPath, newDocument );

				char[] originalFullPath = cSci.getFullPath;

				if( originalFullPath.length >= 7 )
				{
					if( originalFullPath[0..7] == "NONAME#" )
					{
						if( bDel )
						{
							IupDestroy( cSci.getIupScintilla );
							removeFileListNode( null, cSci );
							GLOBAL.scintillaManager.remove( upperCase(originalFullPath) );
							delete cSci;
							actionManager.OutlineAction.cleanTree( originalFullPath );
						}
					}
				}
			}
			else
			{
				return false;
			}
		}
		catch
		{
			return false;
		}

		
		/+
		if( iupSci == null ) return false;
		
		try
		{
			char[] _text = fromStringz( IupGetAttribute( iupSci, "VALUE" ) ).dup;

			return ScintillaAction.newFile( fullPath, Encoding.UTF_8, _text );
		}
		catch
		{
			return false;
		}
		+/

		return true;
	}	

	static bool saveAllFile()
	{
		for( int i = 0; i < IupGetChildCount( GLOBAL.documentTabs ); i++ )
		{
			Ihandle* _child = IupGetChild( GLOBAL.documentTabs, i );

			if( fromStringz( IupGetAttribute( _child, "SAVEDSTATE" ) ) == "YES" )
			{
				foreach( CScintilla _sci; GLOBAL.scintillaManager )
				{
					if( _sci.getIupScintilla == _child )
					{
						if( _sci.getFullPath.length >= 7 )
						{
							if( _sci.getFullPath[0..7] == "NONAME#" )
							{
								IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*) _child );
								actionManager.ScintillaAction.saveAs( actionManager.ScintillaAction.getActiveCScintilla(), true );
								break;
							}
						}
						
						_sci.saveFile();
						OutlineAction.refresh( _sci.getFullPath() );
						break;
					}
				}
			}
		}

		return true;
	}

	static int getCurrentPos( Ihandle* ih )
	{
		if( ih != null ) return IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
	}

	static int iup_XkeyShift( int _c ){ return _c | 0x10000000; }

	static int iup_XkeyCtrl( int _c ){ return _c | 0x20000000; }

	static int iup_XkeyAlt( int _c ){ return _c | 0x40000000; }
}


struct ProjectAction
{
	private:
	import Util = tango.text.Util;
	
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
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( splitText[counterSplitText] ) );
					if( pos != 0 )
					{
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId, tools.getCString( "FIXED" ) );
					}
					else
					{
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, tools.getCString( splitText[counterSplitText] ) );
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
}


struct StatusBarAction
{
	private:
	import parser.autocompletion;
	import tango.text.convert.Layout;
		
	public:
	static void update()
	{
		int childCount = Integer.atoi( fromStringz( IupGetAttribute( GLOBAL.documentTabs, "COUNT" ) ) );
		if( childCount > 0 )
		{
			// SCI_GETCURRENTPOS = 2008
			// SCI_LINEFROMPOSITION = 2166
			// SCI_GETCOLUMN = 2129
			// SCI_GETOVERTYPE = 2187
			// SCI_GETEOLMODE 2030
			auto	cSci = ScintillaAction.getActiveCScintilla();

			if( cSci !is null )
			{
				int pos = IupScintillaSendMessage( cSci.getIupScintilla, 2008, 0, 0 );
				int line = IupScintillaSendMessage( cSci.getIupScintilla, 2166, pos, 0 ) + 1; // 0 based
				int col = IupScintillaSendMessage( cSci.getIupScintilla, 2129, pos, 0 );
				int bOverType = IupScintillaSendMessage( cSci.getIupScintilla, 2187, pos, 0 );
				int eolType = IupScintillaSendMessage( cSci.getIupScintilla, 2030, 0, 0 );

				scope Layouter = new Layout!(char)();
				char[] output = Layouter( "{,7}x{,5}", line, col );

				IupSetAttribute( GLOBAL.statusBar_Line_Col, "TITLE", toStringz( output ) );// Update line x col

				if( bOverType )
				{
					IupSetAttribute( GLOBAL.statusBar_Ins, "TITLE", "OVR" ); // Update line x col
				}
				else
				{
					IupSetAttribute( GLOBAL.statusBar_Ins, "TITLE", "INS" ); // Update line x col
				}

				switch( eolType )
				{
					case 0: //  SC_EOL_CRLF (0)
						IupSetAttribute( GLOBAL.statusBar_EOLType, "TITLE", "WINDOWS" ); break;
					case 1: //    SC_EOL_CR (1)
						IupSetAttribute( GLOBAL.statusBar_EOLType, "TITLE", "    MAC" ); break;
					case 2: //   SC_EOL_LF (2)
						IupSetAttribute( GLOBAL.statusBar_EOLType, "TITLE", "   UNIX" ); break;
					default:
						IupSetAttribute( GLOBAL.statusBar_EOLType, "TITLE", " UNKNOW" );
				}

				switch( cSci.encoding )
				{
					case 0: // Encoding.Unknown
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "DEFAULT    " ); break;
					case 1: // Encoding.UTF_8N
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF8       " ); break;
					case 2: // Encoding.UTF_8
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF8.BOM   " ); break;
					case 3: // Encoding.UTF_16
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF16      " ); break;
					case 4: // Encoding.UTF_16BE
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF16BE.BOM" ); break;
					case 5: // Encoding.UTF_16LE
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF16LE.BOM" ); break;
					case 6: // Encoding.UTF_32
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF32      " ); break;
					case 7: // Encoding.UTF_32BE
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF32BE.BOM" ); break;
					case 8: // Encoding.UTF_32LE
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF32LE.BOM" ); break;
					case 9: //
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF32BE    " ); break;
					case 10: //
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UTF32LE    " ); break;
					default:
						IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "UNKNOWN?   " );
						
				}

				if( GLOBAL.showFunctionTitle ) IupSetAttribute( GLOBAL.functionTitleHandle, "VALUE", toStringz( AutoComplete.getFunctionTitle( cSci.getIupScintilla, ScintillaAction.getCurrentPos( cSci.getIupScintilla ) ) ) );
			}
		}
		else
		{
			IupSetAttribute( GLOBAL.statusBar_Line_Col, "TITLE", "             " );
			IupSetAttribute( GLOBAL.statusBar_Ins, "TITLE", "   " );
			IupSetAttribute( GLOBAL.statusBar_EOLType, "TITLE", "        " );	
			IupSetAttribute( GLOBAL.statusBar_encodingType, "TITLE", "           " );
		}
	}
}

struct ToolAction
{
	private:
	import Util = tango.text.Util;

	public:
	static int convertIupColor( char[] color )
	{
		int result = 0xffffff;
		
		if( color.length )
		{
			if( color[0] == '#' )
			{
				color = "0x" ~ color[1..length];
				result = Integer.atoi( color );
			}
			else
			{
				char[][] colors = Util.split( color, " " );
				if( colors.length == 3 )
				{
					result = ( Integer.atoi( colors[2] ) << 16 ) | ( Integer.atoi( colors[1] ) << 8 ) | ( Integer.atoi( colors[0] ) );
				}
			}
		}

		return result;
	}	
}

// Action for FILE operate
struct SearchAction
{
	private:
	import global, scintilla, project, menu;
	import tango.io.FilePath, tango.text.Ascii, tango.stdc.stringz, Util = tango.text.Util;//, tango.io.UnicodeFile;
	import tango.io.device.File;//, tango.io.stream.Lines;

	static int _find( Ihandle* ih, char[] targetText, int type = 2, bool bNext = true )
	{
		int			findPos = -1;

		if( !( type & MATCHCASE ) ) targetText = toLower( targetText );

		//IupMessage( "Text:", toStringz(targetText) );
		
		int currentPos = cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		int	documentLength = IupGetInt( ih, "COUNT" );
		IupScintillaSendMessage( ih, 2198, type, 0 ); // SCI_SETSEARCHFLAGS = 2198,

		if( targetText.length )
		{
			IupSetInt( ih, "TARGETSTART", currentPos );

			if( bNext )	IupSetInt( ih, "TARGETEND", 0 ); else IupSetInt( ih, "TARGETEND", 1 );

			findPos = cast(int) IupScintillaSendMessage( ih, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) ); //SCI_SEARCHINTARGET = 2197,

			// reSearch form file's head
			if( findPos < 0 )
			{
				if( bNext )
				{
					IupSetInt( ih, "TARGETSTART", 0 );
					IupSetInt( ih, "TARGETEND", currentPos );
				}
				else
				{
					IupSetInt( ih, "TARGETSTART", documentLength );
					IupSetInt( ih, "TARGETEND", currentPos );
				}

				findPos = cast(int) IupScintillaSendMessage( ih, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) ); //SCI_SEARCHINTARGET = 2197,
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
				IupSetAttribute( ih, "SELECTIONPOS", GLOBAL.cString.convert( pos ) );
		
			}
			return findPos;
		}
	}

	/*
    SCFIND_WHOLEWORD = 2,
    SCFIND_MATCHCASE = 4,
    SCFIND_WORDSTART = 0x00100000,
    SCFIND_REGEXP = 0x00200000,
    SCFIND_POSIX = 0x00400000,
	*/	

	public:
	const int MATCHCASE = 2;
	const int WHOLEWORD = 4;
	
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
		return pos;
	}	

	static bool IsWholeWord( char[] lineData, char[] target, int pos )
	{
		char targetPLUS1, targetMinus1;
		
		if( pos == 0 )
		{
			targetMinus1 = 32; // Ascii 32 = space
			if( lineData.length == target.length ) targetPLUS1 = ' ';else targetPLUS1 = lineData[target.length];
		}
		else if( pos + target.length == lineData.length )
		{
			targetMinus1 = lineData[pos-1];
			targetPLUS1 = 32; // Ascii 32 = space
		}
		else
		{
			targetMinus1 = lineData[pos-1];
			targetPLUS1 = lineData[pos+target.length];
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
		int count;

		scope f = new FilePath( fullPath );
		if( f.exists() )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
			IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );

			char[] 	document;
			//char[]	splitLineDocument;
			if( upperCase(fullPath) in GLOBAL.scintillaManager )
			{
				document = fromStringz( IupGetAttribute( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, "VALUE" ) );
			}
			else
			{
				if( buttonIndex == 3 ) return 0;
				document = cast(char[]) File.get( fullPath );
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
						findIndex = Util.index( toLower( document ), toLower( findText ), findIndex );
					}
					
					if( findIndex < document.length )
					{
						if( searchRule & WHOLEWORD )
						{
							if( IsWholeWord( document, findText, findIndex ) )
							{
								count ++;
								document = document[0..findIndex] ~ replaceText ~ document[findIndex+findText.length..length];
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
							document = document[0..findIndex] ~ replaceText ~ document[findIndex+findText.length..length];
							findIndex += replaceText.length;
						}
					}
				}

				File.set( fullPath, document );
				if( toUpper( fullPath ) in GLOBAL.scintillaManager )
				{
					GLOBAL.scintillaManager[toUpper( fullPath )].setText( document );
					OutlineAction.refresh( fullPath );
					
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
					if(!( searchRule & MATCHCASE ) )
					{
						pos = Util.index( toLower( line ) , toLower( findText ) );
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
									pos = Util.index( line, findText, pos + findText.length );
								}
							}
							
							if( !bGetWholeWord ) continue;
						}
						
						count++;
						
						if( buttonIndex == 0 )
						{
							char[] outputWords = fullPath ~ "(" ~ Integer.toString( lineNum ) ~ "): " ~ line;
							IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", GLOBAL.cString.convert( outputWords ) );
						}
						else if( buttonIndex == 3 )
						{
							if( upperCase(fullPath) in GLOBAL.scintillaManager )
							{
								//int linNum = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPath].getIupScintilla, 2166, totalLength + pos, 0 );// SCI_LINEFROMPOSITION = 2166
								if( !( IupGetIntId( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, "MARKERGET", lineNum-1 ) & 2 ) ) IupSetIntId( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, "MARKERADD", lineNum-1, 1 );
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
			
			for( int i = 1; i <= itemCount; ++ i )
			{
				if( fromStringz( IupGetAttribute( ih, GLOBAL.cString.convert( Integer.toString( i ) ) ) ) == text )
				{
					IupSetInt( ih, "REMOVEITEM", i );
					break;
				}
			}

			itemCount = IupGetInt( ih, "COUNT" );
			if( itemCount == limit )
			{
				IupSetInt( ih, "REMOVEITEM", limit );
				IupSetAttributeId( ih, "INSERTITEM", 1, GLOBAL.cString.convert( text ) );
			}
			else
			{
				
				IupSetAttributeId( ih, "INSERTITEM", 1, GLOBAL.cString.convert( text ) );
			}
		}
	}
}


struct OutlineAction
{
	private:
	import scintilla;
	import parser.scanner, parser.token, parser.parser;

	import tango.io.FilePath, tango.text.Ascii;


	public:
	static void loadFile( char[] fullPath )
	{
		refresh( fullPath );
	}
	
	static void refresh( char[] fullPath )
	{
		if( GLOBAL.enableParser != "ON" ) return;
		
		scope f = new FilePath( fullPath );

		char[] _ext = toLower( f.ext() );

		if( _ext != "bas" && _ext != "bi" ) return;
		
		CScintilla actCSci;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( upperCase(fullPath) == upperCase(cSci.getFullPath()) )
			{
				actCSci = cSci;
				break;
			}
		}

		if( actCSci !is null )
		{
			//IupSetAttribute( actCSci.getIupScintilla, "ANNOTATIONCLEARALL", "YES" );
			// Parser
			scope scanner = new CScanner;

			char[] document = actCSci.getText();
			TokenUnit[] tokens = scanner.scan( document );
			scope _parser = new CParser( tokens );
			auto astHeadNode = _parser.parse( fullPath );

			if( upperCase(fullPath) in GLOBAL.parserManager )
			{
				auto temp = GLOBAL.parserManager[upperCase(fullPath)] ;
				delete temp;
				GLOBAL.parserManager[upperCase(fullPath)] = astHeadNode;

				GLOBAL.outlineTree.cleanTree( fullPath );
			}
			else
			{
				GLOBAL.parserManager[upperCase(fullPath)] = astHeadNode;
			}

			GLOBAL.outlineTree.createTree( astHeadNode );

			GLOBAL.outlineTree.changeTree( fullPath );
		}
		else
		{
			// Don't Create Tree
			// Parser
			scope scanner = new CScanner;

			TokenUnit[] tokens = scanner.scanFile( fullPath );
			scope _parser = new CParser( tokens );
			auto astHeadNode = _parser.parse( fullPath );

			if( upperCase(fullPath) in GLOBAL.parserManager )
			{
				auto temp = GLOBAL.parserManager[upperCase(fullPath)] ;
				delete temp;
				GLOBAL.parserManager[upperCase(fullPath)] = astHeadNode;

				GLOBAL.outlineTree.cleanTree( fullPath );
			}
			else
			{
				GLOBAL.parserManager[upperCase(fullPath)] = astHeadNode;
			}			

		}
	}

	static void cleanTree( char[] fullPath )
	{
		for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i );
			if( ih != null )
			{
				char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) );

				if( fullPath == _fullPath )
				{
					IupSetAttribute( ih, "DELNODE", "ALL" );
					IupDestroy( ih );
					break;
				}
			}
		}
	}	
}
