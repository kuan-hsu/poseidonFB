module actionManager;

public import executer;


private import iup.iup, iup.iup_scintilla;

private import Integer = tango.text.convert.Integer;
private import Util = tango.text.Util;
private import tango.stdc.stringz, tango.io.Stdout;
private version(Windows) import tango.sys.win32.UserGdi;

private import global, tools;

long SendMessage( Ihandle* ih, uint msg, ulong wParam, long lParam )
{
	version(Windows)
	{
		return SendMessageA( ih.handle, msg, wParam, lParam );
	}
	else
	{
		return IupScintillaSendMessage( ih, msg, wParam, lParam );
	}
}


// Action for FILE operate
struct FileAction
{
	private:
	import tango.io.UnicodeFile, tango.io.device.File;

	public:
	static void newFile( char[] fullPath )
	{
		auto _file = new File( fullPath, File.ReadWriteCreate );
		_file.close;
		
		scope file = new UnicodeFile!(char)( fullPath, Encoding.Unknown );
	}

	static char[] loadFile( char[] fullPath, inout int _encoding )
	{
		scope file = new UnicodeFile!(char)( fullPath, Encoding.Unknown );
		char[] text = file.read;
		_encoding = cast(int)file.encoding();

		return text;
	}

	static bool saveFile( char[] fullPath, char[] data, Encoding encoding = Encoding.UTF_8 )
	{
		try
		{
			scope file = new UnicodeFile!(char)( fullPath, encoding );
			file.write( data, true );
		}
		catch
		{
			IupMessage("","ERROR");
			return false;
		}

		return true;
	}
	
}


struct ScintillaAction
{
	private:
	import tango.io.UnicodeFile, tango.io.FilePath;
	import scintilla;
	import parser.scanner,  parser.token, parser.parser;
		
	public:
	static bool newFile( char[] fullPath, Encoding _encoding = Encoding.UTF_8, char[] existData = null )
	{
		// FullPath had already opened
		if( fullPath in GLOBAL.scintillaManager ) 
		{
			IupMessage( "Waring!!", "File has already exist!" );
			return false;
		}

		auto 	_sci = new CScintilla( fullPath );
		FileAction.newFile( fullPath );
		_sci.setEncoding( _encoding );
		GLOBAL.scintillaManager[fullPath] = _sci;

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

		return true;
	}
	
	static bool openFile( char[] fullPath, int lineNumber = -1 )
	{
		// FullPath had already opened
		if( fullPath in GLOBAL.scintillaManager ) 
		{
			Ihandle* ih = GLOBAL.scintillaManager[fullPath].getIupScintilla;
			
			IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)ih );
			IupSetFocus( ih );
			if( lineNumber > -1 ) IupScintillaSendMessage( ih, 2024, lineNumber - 1, 0 ); // SCI_GOTOLINE = 2024
			StatusBarAction.update();

			toTreeMarked( fullPath );
			GLOBAL.outlineTree.changeTree( fullPath );

			return true;
		}

		try
		{
			int		_encoding;
			auto 	_sci = new CScintilla( fullPath );
			char[] 	_text = FileAction.loadFile( fullPath, cast(int)_encoding );
			_sci.setEncoding( _encoding );
			_sci.setText( _text );
			GLOBAL.scintillaManager[fullPath] = _sci;

			// Set documentTabs to visible
			if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "YES" );

			// Set new tabitem to focus
			IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)_sci.getIupScintilla );
			IupSetFocus( _sci.getIupScintilla );
			if( lineNumber > -1 ) IupScintillaSendMessage( _sci.getIupScintilla, 2024, lineNumber - 1, 0 ); // SCI_GOTOLINE = 2024
			//StatusBarAction.update();

			IupSetAttribute( GLOBAL.fileListTree, "ADDLEAF0", GLOBAL.cString.convert( fullPath ) );
			IupSetAttribute( GLOBAL.fileListTree, "USERDATA1", cast(char*) _sci  );
			IupSetAttributeId( GLOBAL.fileListTree, "MARKED", 1, "YES" );
			
			// Parser
			OutlineAction.loadFile( fullPath );

			return true;
		}
		catch
		{
		}

		return false;
	}

	static void toTreeMarked( char[] fullPath, int _switch = 3 )
	{
		if( fullPath in GLOBAL.scintillaManager )
		{
			CScintilla cSci = GLOBAL.scintillaManager[fullPath];
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
						char[] s = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
						if( s == fullPath )
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
		for( int i = 0; i < IupGetChildCount( GLOBAL.documentTabs ); i++ )
		{
			Ihandle* _child = IupGetChild( GLOBAL.documentTabs, i );
			if( fromStringz( IupGetAttribute( _child, "VISIBLE" ) ) == "YES" )  // Active Tab Child
			{
				return _child;
			}
		}

		return null;
	}

	static CScintilla getActiveCScintilla()
	{
		Ihandle* iupSci = getActiveIupScintilla();
		if( iupSci != null )
		{
			foreach( CScintilla _sci; GLOBAL.scintillaManager )
			{
				if( _sci.getIupScintilla == iupSci )
				{
					return _sci;
				}
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

		//IupMessage( "BEFORE", toStringz(Integer.toString(IupGetChildCount( GLOBAL.documentTabs ))));
		if( fullPath in GLOBAL.scintillaManager )
		{
			CScintilla	cSci		= GLOBAL.scintillaManager[fullPath];
			Ihandle*	iupSci		= cSci.getIupScintilla;
			
			if( fromStringz( IupGetAttribute( iupSci, "SAVEDSTATE" ) ) == "YES" )
			{
				int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ fullPath ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
				if( button == 3 ) return IUP_IGNORE;
				if( button == 1 ) cSci.saveFile();
			}

			IupDestroy( iupSci );

			removeFileListNode( null, cSci );

			GLOBAL.scintillaManager.remove( fullPath );
			delete cSci;

			actionManager.OutlineAction.cleanTree( fullPath );

			if( IupGetChildCount( GLOBAL.documentTabs ) == 0 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "NO" );
		}

		//IupMessage( "AFTER", toStringz(Integer.toString(IupGetChildCount( GLOBAL.documentTabs ))));
		return IUP_DEFAULT;
	}

	static int closeOthersDocument( char[] fullPath )
	{
		char[][] KEYS = GLOBAL.scintillaManager.keys;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( cSci.getFullPath != fullPath )
			{
				Ihandle*	iupSci		= cSci.getIupScintilla;
				
				if( fromStringz( IupGetAttribute( iupSci, "SAVEDSTATE" ) ) == "YES" )
				{
					int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ cSci.getFullPath() ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
					if( button == 3 ) return IUP_IGNORE;
					if( button == 1 ) cSci.saveFile();
				}

				removeFileListNode( null, cSci );

				actionManager.OutlineAction.cleanTree( cSci.getFullPath );

				IupDestroy( iupSci );
				delete cSci;
			}
		}

		foreach( char[] s; KEYS )
		{
			if( s != fullPath )	GLOBAL.scintillaManager.remove( s );
		}

		return IUP_DEFAULT;
	}	

	static int closeAllDocument()
	{
		char[][] KEYS = GLOBAL.scintillaManager.keys;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			Ihandle*	iupSci		= cSci.getIupScintilla;
			
			if( fromStringz( IupGetAttribute( iupSci, "SAVEDSTATE" ) ) == "YES" )
			{
				int button = IupAlarm( "Quest", GLOBAL.cString.convert( "\"" ~ cSci.getFullPath() ~ "\"\nhas been changed, save it now?" ), "Yes", "No", "Cancel" );
				if( button == 3 ) return IUP_IGNORE;
				if( button == 1 ) cSci.saveFile();
			}

			removeFileListNode( null, cSci );

			actionManager.OutlineAction.cleanTree( cSci.getFullPath );

			IupDestroy( iupSci );
			delete cSci;
		}

		foreach( char[] s; KEYS )
			GLOBAL.scintillaManager.remove( s );

		if( IupGetChildCount( GLOBAL.documentTabs ) == 0 ) IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "NO" );

		return IUP_DEFAULT;
	}

	static bool saveFile( Ihandle* iupSci )
	{
		if( iupSci == null ) return false;
		
		try
		{
			CScintilla cSci = getCScintilla( iupSci );
			cSci.saveFile();

			//Update Parser
			OutlineAction.refresh( cSci.getFullPath()  );
		}
		catch
		{
			return false;
		}

		return true;
	}

	static bool saveAs( Ihandle* iupSci, char[] fullPath )
	{
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

		return fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;
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
					// Shadow
					if( pos != 0 )
					{
						IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( "FIXED" ) );
					}
					else
					{
						IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( splitText[counterSplitText] ) );
					}

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
			Ihandle* _sci = ScintillaAction.getActiveIupScintilla();

			int pos = IupScintillaSendMessage( _sci, 2008, 0, 0 );
			int line = IupScintillaSendMessage( _sci, 2166, pos, 0 ) + 1; // 0 based
			int col = IupScintillaSendMessage( _sci, 2129, pos, 0 );
			int bOverType = IupScintillaSendMessage( _sci, 2187, pos, 0 );

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

		}
		else
		{
			IupSetAttribute( GLOBAL.statusBar_Line_Col, "TITLE", "             " );
			IupSetAttribute( GLOBAL.statusBar_Ins, "TITLE", "   " );
			IupSetAttribute( GLOBAL.statusBar_FontType, "TITLE", "        " );	
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

	public:
	const int MATCHCASE = 1;
	const int WHOLEWORD = 2;
	
	static int search( Ihandle* iupSci, char[] findText, int searchRule, bool bForward = true, bool bJumpSelect = true )
	{
		int pos = -1;

		if( iupSci != null && findText.length )
		{
			if( bForward )
			{
				pos = actionManager.SearchAction.findNext( iupSci, findText, searchRule, bJumpSelect );
			}
			else
			{
				pos = actionManager.SearchAction.findPrev( iupSci, findText, searchRule, bJumpSelect );
			}
		}

		/*
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle = IupGetHandle( "CSearchDialog_listFind" );
			if( listFind_handle != null )
			{
				char[] findText = fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) );

				if( findText.length )
				{
					Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
					if( direction_handle != null )
					{
						if( fromStringz(IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
						{
							pos = actionManager.SearchAction.findNext( iupSci, findText, GLOBAL.searchDlg.searchRule, bJumpSelect );
						}
						else
						{
							pos = actionManager.SearchAction.findPrev( iupSci, findText, GLOBAL.searchDlg.searchRule, bJumpSelect );
						}

						addListItem( listFind_handle, findText, 15 );
					}
				}
			}
		}
		*/

		return pos;
	}	

	/+
	static int findNext( Ihandle* ih, char[] targetText, int type = 2, bool bJumpSelect = true )
	{
		int currentPos = IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		int anchorPos =  IupScintillaSendMessage( ih, 2009, 0, 0 ); // SCI_GETANCHOR = 2009

		IupSetInt( ih, "TARGETSTART", 0 );

		IupMessage( "TARGETSTART", IupGetAttribute( ih, "TARGETSTART" ) );

		int documentLength = IupScintillaSendMessage( ih, 2183, 0, 0 ); //SCI_GETTEXTLENGTH = 2183

		
		//IupSetInt( ih, "TARGETEND ",documentLength );
		IupScintillaSendMessage( ih, 2192, documentLength, 0 ); // SCI_SETTARGETEND = 2192,

		IupMessage( "TARGETEND", IupGetAttribute( ih, "TARGETEND" ) );

		IupScintillaSendMessage( ih, 2198, 4, 0 ); //SCI_SETSEARCHFLAGS = 2198
		
		//IupSetAttribute( ih, "SEARCHFLAGS", "MATCHCASE" );
char[] pp="print";

		IupSetAttribute( ih, "SEARCHINTARGET", toStringz(pp.dup) );
		
		//anchorPos = IupScintillaSendMessage( ih, 2197, 5, cast(long) toStringz(pp.dup) ); //SCI_SEARCHINTARGET = 2197,

		IupMessage( "next", toStringz( Integer.toString(anchorPos)));


		//IupGetAttribute( ih, "TARGETSTART" ) );

		
		//IupSetAttribute( ih, "SEARCHINTARGET", toStringz( "print" ) );
		/+

		int startPos =  IupScintillaSendMessage( ih, 2190, 0, 0 ); // SCI_SETTARGETSTART = 2190,
		int endPos =  IupScintillaSendMessage( ih, 2192, 0, 0 ); // SCI_SETTARGETEND = 2192,
		

		IupMessage( "currentPos", toStringz( Integer.toString( currentPos ) ) );
		IupMessage( "anchorPos", toStringz( Integer.toString( anchorPos ) ) );

		anchorPos =  IupScintillaSendMessage( ih, 2026, currentPos, 0 );    // SCI_SETANCHOR = 2026,

		IupMessage( "anchorPos", toStringz( Integer.toString( anchorPos ) ) );


		IupScintillaSendMessage( ih, 2366, 0, 0 ); //SCI_SEARCHANCHOR = 2366,
		IupMessage( "anchorPos", toStringz( Integer.toString( anchorPos ) ) );

		
		
		int nextPos = IupScintillaSendMessage( ih, 2367, 6, cast(long) toStringz( "print" ) ); // SCI_SEARCHNEXT = 2367
		IupMessage( "nextPos", toStringz( Integer.toString( nextPos ) ) );

		+/
		
		// SCI_SEARCHNEXT = 2367
		return -1;

	}

	+/

	static int findNext( Ihandle* ih, char[] targetText, int type = 2, bool bJumpSelect = true )
	{
		int			findPos = -1;

		if( !( type & MATCHCASE ) ) targetText = toLower( targetText );

		//IupMessage( "Text:", toStringz(targetText) );
		
		int currentPos = IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		int documentLength = IupScintillaSendMessage( ih, 2183, 0, 0 ); //SCI_GETTEXTLENGTH = 2183

		char[] document = fromStringz( IupGetAttribute( ih, "VALUE" ) );
		if( !( type & MATCHCASE ) ) document = toLower( document );

		if( currentPos + targetText.length <= documentLength )
		{
			if( document[currentPos..currentPos+targetText.length] == targetText ) currentPos += targetText.length;
		}

		if( currentPos < document.length )
		{
			findPos = Util.index( document, targetText, currentPos );

			if( type & WHOLEWORD )
			{
				while( findPos < document.length )
				{
					if( IsWholeWord( document, targetText, findPos ) )
					{
						break;
					}
					else
					{
						findPos = Util.index( document, targetText, findPos + targetText.length );
					}
				}
			}

			if( findPos < document.length )
			{
				if( bJumpSelect )
				{
					char[] pos = Integer.toString( findPos ) ~ ":" ~ Integer.toString( findPos+targetText.length );
					IupSetAttribute( ih, "SELECTIONPOS", GLOBAL.cString.convert( pos ) );
				}
				else
				{
					IupScintillaSendMessage( ih, 2141, findPos+targetText.length, 0 ); // SCI_SETCURRENTPOS = 2141,
					IupScintillaSendMessage( ih, 2163, 1, 0 ); // SCI_HIDESELECTION = 2163,
				}
				return findPos;
			}
			else
			{
				int startPos;

				if( startPos <= currentPos )
				{
					document = document[0..currentPos];
					findPos = Util.index( document, targetText, startPos );

					if( type & WHOLEWORD )
					{
						while( findPos < document.length )
						{
							if( IsWholeWord( document, targetText, findPos ) )
							{
								break;
							}
							else
							{
								findPos = Util.index( document, targetText, findPos + targetText.length );
							}
						}
					}
					
					if( findPos < currentPos )
					{
						if( bJumpSelect )
						{
							char[] pos = Integer.toString( findPos ) ~ ":" ~ Integer.toString( findPos+targetText.length );
							IupSetAttribute( ih, "SELECTIONPOS", GLOBAL.cString.convert( pos ) );
						}
						else
						{
							IupScintillaSendMessage( ih, 2141, findPos+targetText.length, 0 ); // SCI_SETCURRENTPOS = 2141,
							IupScintillaSendMessage( ih, 2163, 1, 0 ); // SCI_HIDESELECTION = 2163,
						}
						return findPos;
					}
				}
			}
		}

		return -1;
	}


	static int findPrev( Ihandle* ih, char[] targetText, int type = 2, bool bJumpSelect = true )
	{
		int			findPos = -1;

		if( !( type & MATCHCASE ) ) targetText = toLower( targetText );

		int currentPos = IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
		int documentLength = IupScintillaSendMessage( ih, 2183, 0, 0 ); //SCI_GETTEXTLENGTH = 2183

		char[] document = fromStringz( IupGetAttribute( ih, "VALUE" ) );
		if( !( type & MATCHCASE ) ) document = toLower( document );

		if( currentPos - targetText.length >= 0 )
		{
			if( document[currentPos-targetText.length..currentPos] == targetText ) currentPos -= targetText.length;
		}

		//if( ( type & WHOLEWORD ) ) currentPos = getWholeWordPos( document, targetText, currentPos, false );

		findPos = Util.rindex( document, targetText, currentPos );

		if( type & WHOLEWORD )
		{
			while( findPos < document.length )
			{
				if( IsWholeWord( document, targetText, findPos ) )
				{
					break;
				}
				else
				{
					findPos = Util.rindex( document, targetText, findPos );
				}
			}
		}
		
		if( findPos < document.length )
		{
			if( bJumpSelect )
			{
				char[] pos = Integer.toString( findPos ) ~ ":" ~ Integer.toString( findPos+targetText.length );
				IupSetAttribute( ih, "SELECTIONPOS", GLOBAL.cString.convert( pos ) );
			}
			else
			{
				IupScintillaSendMessage( ih, 2141, findPos+targetText.length, 0 ); // SCI_SETCURRENTPOS = 2141,
				IupScintillaSendMessage( ih, 2163, 1, 0 ); // SCI_HIDESELECTION = 2163,
			}
			
			return findPos;
		}
		else
		{
			int startPos = document.length;
			//if( ( type & WHOLEWORD ) ) startPos = getWholeWordPos( document, targetText, documentLength, false );
			
			if( currentPos < documentLength )
			{
				findPos = Util.rindex( document, targetText, startPos );

				if( type & WHOLEWORD )
				{
					while( findPos < document.length )
					{
						if( IsWholeWord( document, targetText, findPos ) )
						{
							break;
						}
						else
						{
							findPos = Util.rindex( document, targetText, findPos );
						}
					}
				}
				
				if( findPos < document.length )
				{
					if( findPos > currentPos )
					{
						if( bJumpSelect )
						{
							char[] pos = Integer.toString( findPos ) ~ ":" ~ Integer.toString( findPos+targetText.length );
							IupSetAttribute( ih, "SELECTIONPOS", GLOBAL.cString.convert( pos ) );
						}
						else
						{
							IupScintillaSendMessage( ih, 2141, findPos+targetText.length, 0 ); // SCI_SETCURRENTPOS = 2141,
							IupScintillaSendMessage( ih, 2163, 1, 0 ); // SCI_HIDESELECTION = 2163,
						}
						
						return findPos;
					}
				}
			}
		}
		
		return -1;
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
	static int findInOneFile( char[] fullPath, char[] targetText, int searchRule = 3, int buttonIndex = 0 )
	{
		int count;

		if( searchRule & MATCHCASE ) targetText = toLower( targetText );
		
		scope f = new FilePath( fullPath );
		if( f.exists() )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
			IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );

			char[] 	document;
			//char[]	splitLineDocument;
			if( fullPath in GLOBAL.scintillaManager )
			{
				document = fromStringz( IupGetAttribute( GLOBAL.scintillaManager[fullPath].getIupScintilla, "VALUE" ) );
			}
			else
			{
				if( buttonIndex == 3 ) return 0;
				document = cast(char[]) File.get( fullPath );
			}			
			//scope file = new File( fullPath, File.ReadExisting );

			int lineNum;
			//foreach( line; new Lines!(char)(file) )
			foreach( line; Util.splitLines( document ) )
			{
				lineNum++;

				if( line.length )
				{
					if( searchRule & MATCHCASE ) line = toLower( line );
					
					int pos = Util.index( line, targetText );
					if( pos < line.length )
					{
						if( searchRule & WHOLEWORD )
						{
							bool bGetWholeWord;
							while( pos < line.length )
							{
								//IupMessage( toStringz( Integer.toString(lineNum) ), toStringz( Integer.toString( pos ) ) );
								if( IsWholeWord( line, targetText, pos ) )
								{
									bGetWholeWord = true;
									break;
								}
								else
								{
									pos = Util.index( line, targetText, pos + targetText.length );
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
							if( fullPath in GLOBAL.scintillaManager )
							{
								//int linNum = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPath].getIupScintilla, 2166, totalLength + pos, 0 );// SCI_LINEFROMPOSITION = 2166
								if( !( IupGetIntId( GLOBAL.scintillaManager[fullPath].getIupScintilla, "MARKERGET", lineNum-1 ) & 2 ) ) IupSetIntId( GLOBAL.scintillaManager[fullPath].getIupScintilla, "MARKERADD", lineNum-1, 1 );
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
		scope f = new FilePath( fullPath );

		char[] _ext = toLower( f.ext() );

		if( _ext != "bas" && _ext != "bi" ) return;
		
		CScintilla actCSci;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( fullPath == cSci.getFullPath() )
			{
				actCSci = cSci;
				break;
			}
		}

		if( actCSci !is null )
		{
			// Parser
			scope scanner = new CScanner;

			char[] document = actCSci.getText();
			TokenUnit[] tokens = scanner.scan( document );
			scope _parser = new CParser( tokens );
			auto astHeadNode = _parser.parse( fullPath );

			if( fullPath in GLOBAL.parserManager )
			{
				auto temp = GLOBAL.parserManager[fullPath] ;
				delete temp;
				GLOBAL.parserManager[fullPath] = astHeadNode;

				GLOBAL.outlineTree.cleanTree( fullPath );
			}
			else
			{
				GLOBAL.parserManager[fullPath] = astHeadNode;
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

			if( fullPath in GLOBAL.parserManager )
			{
				auto temp = GLOBAL.parserManager[fullPath] ;
				delete temp;
				GLOBAL.parserManager[fullPath] = astHeadNode;

				GLOBAL.outlineTree.cleanTree( fullPath );
			}
			else
			{
				GLOBAL.parserManager[fullPath] = astHeadNode;
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
