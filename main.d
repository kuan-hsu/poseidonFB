module main;

import iup.iup;
import iup.iup_scintilla;

import global, layout, images.imageData, tools, navcache;
import menu, scintilla, actionManager;
import parser.autocompletion;

import tango.io.Stdout, tango.stdc.stringz, Integer = tango.text.convert.Integer, Float = tango.text.convert.Float;
import tango.sys.Environment, tango.io.FilePath;
import tango.sys.Process, tango.io.stream.Lines;

import tango.sys.SharedLib;
/*
version(linux)
{
	import tango.stdc.posix.pwd;
	
	extern(C) uid_t geteuid();
	extern(C) uid_t getuid();
}
*/
version(Windows)
{
	import tango.sys.win32.UserGdi;
	
	pragma(lib, "winmm.lib"); // For PlaySound()
	pragma(lib, "iup.lib");
	pragma(lib, "iup_scintilla.lib");
}
else
{
	import tango.sys.HomeFolder;
	
	// libgtk2.0-dev
	//-lgtk-x11-2.0 -lgdk-x11-2.0 -lpangox-1.0 -lgdk_pixbuf-2.0 -lpango-1.0 -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -liup -liup_scintilla
	
	// -lgtk-3 gdk-3 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpango-1.0 -lcairo   -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -lXext -lX11 -lm  (for GTK 3)
	//pragma(lib, "gtk-x11-2.0");
	//pragma(lib, "gdk-x11-2.0");
	//pragma(lib, "pangox-1.0");
	/*
	pragma(lib, "gdk_pixbuf-2.0");
	pragma(lib, "pango-1.0");
	pragma(lib, "gobject-2.0");
	pragma(lib, "gmodule-2.0");
	pragma(lib, "glib-2.0");
	*/
	/*
	pragma(lib, "gtk-3");
	pragma(lib, "gdk-3");
	pragma(lib, "gdk_pixbuf-2.0");
	pragma(lib, "pangocairo-1.0");
	pragma(lib, "pango-1.0");
	pragma(lib, "cairo");
	*/

	pragma(lib, "iup");
	pragma(lib, "iup_scintilla");
}

void main( char[][] args )
{
	version(Windows)
	{
		SharedLib sharedlib;
		GLOBAL.htmlHelp = null;
		
		try
		{
			sharedlib = SharedLib.load( `hhctrl.ocx` );
			
			//Stdout("Library successfully loaded").newline;
			
			void* ptr = sharedlib.getSymbol("HtmlHelpW");
			if( ptr )
			{
			
				GLOBAL.htmlHelp = cast(_htmlHelp) ptr;
				//Trace.formatln("Symbol dllprint found. Address = 0x{:x}", ptr);
				//void **point = cast(void **)&GLOBAL.htmlHelp; // binding function address from DLL to our function pointer
				//*point = ptr;
				
				//Stdout("DONE").newline;
			}
			else
			{
				//Stdout("Symbol not found").newline;
			}
		}
		catch( Exception e )
		{
			GLOBAL.htmlHelp = null;
			
			//Stdout(e.toString).newline;
		}
		

		SharedLib loaderlib;
		GLOBAL.iconv_open = null;
		GLOBAL.iconv = null;
		GLOBAL.iconv_close = null;		
		try
		{
			loaderlib = SharedLib.load( `iconv.dll` );
			if( loaderlib !is null )
			{
				void* ptr = loaderlib.getSymbol("libiconv_open");
				if( ptr )
				{
					void **point = cast(void **)&GLOBAL.iconv_open; // binding function address from DLL to our function pointer
					*point = ptr;
				}
				else
					debug Stdout("Symbol 'iconv_open' not found").newline;
				
				
				ptr = null;
				ptr = loaderlib.getSymbol("libiconv");
				if( ptr )
				{
					void **point = cast(void **)&GLOBAL.iconv; // binding function address from DLL to our function pointer
					*point = ptr;
				}
				else
					debug Stdout("Symbol 'iconv' not found").newline;

				ptr = null;
				ptr = loaderlib.getSymbol("libiconv_close");
				if( ptr )
				{
					void **point = cast(void **)&GLOBAL.iconv_close; // binding function address from DLL to our function pointer
					*point = ptr;
				}
				else
					debug Stdout("Symbol 'iconv_close' not found").newline;
					
					
				debug Stdout("SUCCESS!" ).newline;
			}
			else
			{
				debug Stdout("LOAD DLL ERROR!" ).newline;
				GLOBAL.iconv = null;
			}
		}
		catch( Exception e )
		{
			GLOBAL.iconv = null;
			debug Stdout(e.toString).newline;
		}		
	}
	
	if( IupOpen( null, null ) == IUP_ERROR )
	{
		Stdout( "IUP open error!!!" ).newline;
		return;
	}
	
	version(Windows)
	{
		version(FBIDE)
			IupSetGlobal("SINGLEINSTANCE", "poseidonFB - FreeBasic IDE");
		else
			IupSetGlobal("SINGLEINSTANCE", "poseidonD - D Programming Language IDE");
			
		if( IupGetGlobal( toStringz( "SINGLEINSTANCE" ) ) == null  )
		{
			IupClose();
			if( GLOBAL.htmlHelp != null ) sharedlib.unload();
			return;
		}
	}
	
	//  Get poseidonFB exePath & set the new cwd
	scope _poseidonPath = new FilePath( args[0] );
	if( _poseidonPath.exists() )
	{
		GLOBAL.poseidonPath = _poseidonPath.path;
		Environment.cwd( GLOBAL.poseidonPath );
		version(Windows)
		{
			GLOBAL.EnvironmentVars = Environment.get();
		}
		else
		{
			/*
			auto user = getpwuid( getuid() );
			char[] home = fromStringz( user.pw_dir );
			*/
			char[] home = expandTilde( "~" );
			
			if( Util.index( GLOBAL.poseidonPath, home ) != 0 )
			{
				GLOBAL.linuxHome = home.dup;
				version(FBIDE)	GLOBAL.linuxHome ~= "/.poseidonFB";
				version(DIDE)	GLOBAL.linuxHome ~= "/.poseidonD";
				
				scope dotPath = new FilePath( GLOBAL.linuxHome );
				if( !dotPath.exists() )	dotPath.create();
				
				dotPath.set( GLOBAL.linuxHome ~ "/settings" );
				if( !dotPath.exists() )	dotPath.create();
				
				dotPath.set( GLOBAL.linuxHome ~ "/colorTemplates" );
				if( !dotPath.exists() )	dotPath.create();
			}
		}
	}
	
	// Init IDE
	load_all_images_icons();
	
	createEditorSetting();
	
	IupScintillaOpen();

	// Set Default Font
	if(  GLOBAL.fonts[0].fontString.length )
	{
		IupSetGlobal( "DEFAULTFONT", toStringz( GLOBAL.fonts[0].fontString.dup ) );

		if( GLOBAL.fonts[0].fontString.length )
		{
			int comma = Util.index( GLOBAL.fonts[0].fontString, "," );
			if( comma < GLOBAL.fonts[0].fontString.length )
			{
				IupSetGlobal( "DEFAULTFONTFACE", toStringz( ( GLOBAL.fonts[0].fontString[0..comma] ).dup ) );

				for( int i = GLOBAL.fonts[0].fontString.length - 1; i > comma; -- i )
				{
					if( GLOBAL.fonts[0].fontString[i] < 48 || GLOBAL.fonts[0].fontString[i] > 57 )
					{
						IupSetGlobal( "DEFAULTFONTSIZE", toStringz( ( GLOBAL.fonts[0].fontString[i+1..$] ).dup ) );

						if( ++comma  < i ) IupSetGlobal( "DEFAULTFONTSTYLE", toStringz( ( GLOBAL.fonts[0].fontString[comma..i] ).dup ) );
						
						break;
					}
				}
			}
		}
	}

	IupSetGlobal( "UTF8MODE", "YES" );
	version(Windows) IupSetGlobal( "UTF8MODE_FILE", "YES" );

	/*
	char[] iupVersion = fromStringz( IupGetGlobal( "VERSION" ) );
	if( Util.count( iupVersion, "." ) == 2 )
	{
		int tailDotPos = Util.rindex( iupVersion, "." );
		if( tailDotPos < iupVersion.length ) GLOBAL.IUP_VERSION = Float.toFloat( iupVersion[0..tailDotPos] );
	}
	else
	{
		GLOBAL.IUP_VERSION = Float.toFloat( iupVersion );
	}
	
	if( GLOBAL.IUP_VERSION > 3.24 )
	{
		version(linux) if( fromStringz( IupGetGlobal( "TXTHLCOLOR" ) ) == "255 255 255" ) IupSetGlobal( "TXTHLCOLOR", "154 184 124" );
	}
	*/

	createMenu();
	
	// Creates a dialog containing the control
	GLOBAL.mainDlg = IupDialog( null );
	IupSetHandle( "POSEIDON_MAIN_DIALOG", GLOBAL.mainDlg );
	IupSetCallback( GLOBAL.mainDlg, "CLOSE_CB", cast(Icallback) &mainDialog_CLOSE_cb );
	IupSetCallback( GLOBAL.mainDlg, "SHOW_CB", cast(Icallback) &mainDialog_SHOW_cb );
	IupSetCallback( GLOBAL.mainDlg, "K_ANY", cast(Icallback) &mainKany_cb );
	IupSetCallback( GLOBAL.mainDlg, "RESIZE_CB", cast(Icallback) &mainDialog_RESIZE_cb );
	
	IupSetAttributes( GLOBAL.mainDlg, "SHRINK=YES" );
	
	version(Windows) IupSetCallback( GLOBAL.mainDlg, "COPYDATA_CB", cast(Icallback) &mainDialog_COPYDATA_CB ); else IupSetGlobal( "GLOBALMENU", "NO" ); // for ubuntu menu & toolbar overlap issue

	createLayout();
	
	version(FBIDE) IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" ); else IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonD - D Programming Language IDE" );
	IupSetAttribute( GLOBAL.mainDlg, "ICON", "icon_poseidonFB" );
	IupSetAttribute( GLOBAL.mainDlg, "MENU", "mymenu" );
	version(FBIDE) IupSetAttribute( GLOBAL.mainDlg, "NAME", "poseidonFB" ); else IupSetAttribute( GLOBAL.mainDlg, "NAME", "poseidonD" );
	//IupSetAttribute( GLOBAL.mainDlg, "BACKGROUND", "100 100 100" );

	//IupSetGlobal( "IMAGEAUTOSCALE", "DPI" );
	IupSetGlobal( "INPUTCALLBACKS", "YES" );
	IupSetFunction( "GLOBALKEYPRESS_CB", cast(Icallback) &GlobalKeyPress_CB );
	version(Windows) IupSetFunction( "GLOBALWHEEL_CB", cast(Icallback) &GlobalWHEEL_CB );
	
	if( GLOBAL.editorSetting01.PLACEMENT == "MAXIMIZED" ) IupSetAttribute( GLOBAL.mainDlg, "PLACEMENT", "MAXIMIZED" ); else IupSetAttribute( GLOBAL.mainDlg, "RASTERSIZE", toStringz( GLOBAL.editorSetting01.RASTERSIZE ) );

	// Set Split %
	IupSetAttribute( GLOBAL.explorerSplit, "VALUE", toStringz( GLOBAL.editorSetting01.ExplorerSplit ) );
	
	/*
	version(linux)
	{
		EditorToggleUint	_editorSetting00 = GLOBAL.editorSetting00;
		EditorLayoutSize	_editorSetting01 = GLOBAL.editorSetting01;
		EditorOpacity		_editorSetting02 = GLOBAL.editorSetting02;
		EditorColorUint		_editColor = GLOBAL.editColor;
		
		// Shows dialog
		IupShow( GLOBAL.mainDlg );
	
		GLOBAL.editorSetting00 = _editorSetting00;
		GLOBAL.editorSetting01 = _editorSetting01;
		GLOBAL.editorSetting02 = _editorSetting02;
		GLOBAL.editColor = _editColor;
	}
	else
	{
		// Shows dialog
		IupShow( GLOBAL.mainDlg );
	}
	*/
	
	EditorToggleUint	_editorSetting00 = GLOBAL.editorSetting00;
	EditorLayoutSize	_editorSetting01 = GLOBAL.editorSetting01;
	EditorOpacity		_editorSetting02 = GLOBAL.editorSetting02;
	EditorColorUint		_editColor = GLOBAL.editColor;
	
	// Shows dialog
	IupShow( GLOBAL.mainDlg );

	GLOBAL.editorSetting00 = _editorSetting00;
	GLOBAL.editorSetting01 = _editorSetting01;
	GLOBAL.editorSetting02 = _editorSetting02;
	GLOBAL.editColor = _editColor;
		
	IupSetAttribute( GLOBAL.messageSplit, "VALUE", toStringz( GLOBAL.editorSetting01.MessageSplit ) );	
	IupSetAttribute( GLOBAL.fileListSplit, "VALUE", toStringz( GLOBAL.editorSetting01.FileListSplit ) );
	if( GLOBAL.editorSetting01.OutlineWindow == "OFF" ) menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
	if( GLOBAL.editorSetting01.MessageWindow == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
	if( GLOBAL.editorSetting01.FilelistWindow == "OFF" ) menu.fileListMenuItem_cb( GLOBAL.menuFistlistWindow );
	

	createDialog();

	scope docTabString = new IupString( GLOBAL.fonts[0].fontString );	IupSetAttribute( GLOBAL.documentTabs, "TABFONT", docTabString.toCString );
	scope leftsideString = new IupString( GLOBAL.fonts[2].fontString );	IupSetAttribute( GLOBAL.projectViewTabs, "FONT", leftsideString.toCString );// Leftside
	scope fileListString = new IupString( GLOBAL.fonts[3].fontString );	IupSetAttribute( GLOBAL.fileListTree.getTreeHandle, "FONT", fileListString.toCString );// Filelist
	scope messageString = new IupString( GLOBAL.fonts[6].fontString );	IupSetAttribute( GLOBAL.messageWindowTabs, "TABFONT", messageString.toCString );// Bottom
	scope outputString = new IupString( GLOBAL.fonts[7].fontString );	IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "FONT", outputString.toCString );//IupSetAttribute( GLOBAL.outputPanel, "FONT", outputString.toCString );// Output
	scope searchString = new IupString( GLOBAL.fonts[8].fontString );	IupSetAttribute( GLOBAL.messagePanel.getSearchOutputPanelHandle, "FONT", searchString.toCString ); //IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", searchString.toCString );// Search
	scope statusString = new IupString( GLOBAL.fonts[11].fontString );	IupSetAttribute( GLOBAL.statusBar.getLayoutHandle, "FONT", statusString.toCString );// StatusBar
	scope outlineString = new IupString( GLOBAL.fonts[5].fontString );	IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", outlineString.toCString );// Outline
	scope prjString = new IupString( GLOBAL.fonts[4].fontString );
	IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", prjString.toCString );// Project
	IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "TITLEFONT0", prjString.toCString ); IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "TITLEFONTSTYLE0", "Bold" );// Project
	
	GLOBAL.fileListTree.setTitleFont(); // Change Filelist Title Font
	GLOBAL.messagePanel.setScintillaColor(); // Set MessagePanel Color
	
	if( args.length > 1 )
	{
		scope argPath = new FilePath( args[1] );
		if( argPath.exists() )
		{
			version(FBIDE)
			{
				if( argPath.file == "FB.poseidon" || argPath.file == ".poseidon" )
				{
					char[] dir = argPath.path;
					if( dir.length ) dir = dir[0..$-1]; // Remove tail '/'
					GLOBAL.projectTree.openProject( dir );				
				}
				else
				{
					if( tools.isParsableExt( argPath.ext, 7 ) ) ScintillaAction.openFile( args[1] );
				}
			}
			version(DIDE)
			{
				if( argPath.file == "D.poseidon" )
				{
					char[] dir = argPath.path;
					if( dir.length ) dir = dir[0..$-1]; // Remove tail '/'
					GLOBAL.projectTree.openProject( dir );				
				}
				else
				{
					if( lowerCase( argPath.ext ) == "d" || lowerCase( argPath.ext ) == "di" )	ScintillaAction.openFile( args[1] );
				}
			}
		}
	}

	if( GLOBAL.editorSetting00.LoadPrevDoc == "ON" )
	{
		foreach( char[] s; GLOBAL.prevPrj )
			GLOBAL.projectTree.openProject( s );
		
		int activePos = -1;
		foreach( char[] s; GLOBAL.prevDoc )
		{
			if( s.length )
			{
				if( s[0] == '*' )
				{
					ScintillaAction.openFile( s[1..$] );
					activePos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
				}
				else
					ScintillaAction.openFile( s );
			}
		}
		
		if( activePos > -1 )
		{
			DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, activePos );
			IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", activePos );
		}
	}
	
	version(Windows)
	{
		if( GLOBAL.editorSetting00.AutoKBLayout == "ON" )
		{
			// From WQ1980
			//HKL enghkl = LoadKeyboardLayoutA( "00000409",KLF_ACTIVATE & KLF_SETFORPROCESS );
			HKL enghkl = LoadKeyboardLayoutA( "00000409", 0x00000001 | 0x00000100 ); // 00000409 English layout
			ActivateKeyboardLayout( enghkl, 0x00000100 );
		}
	}
	
	if( GLOBAL.editorSetting01.USEFULLSCREEN == "ON" ) IupSetAttribute( GLOBAL.mainDlg, "FULLSCREEN", "YES" );
	/*
	IupMessage("",IupGetGlobal( "MONITORSCOUNT" ) );
	IupMessage("MONITORSINFO",IupGetGlobal( "MONITORSINFO" ) );
	IupMessage("VIRTUALSCREEN",IupGetGlobal( "VIRTUALSCREEN" ) );
	*/
	
	int monitorID;
	foreach( char[] s; Util.splitLines( fromStringz( IupGetGlobal( "MONITORSINFO" ) ) ) )
	{
		if( s.length )
		{
			char[][] information = Util.split( s, " " );
			if( information.length == 4 )
			{
				Monitor m = { Integer.atoi( information[0] ), Integer.atoi( information[1] ), Integer.atoi( information[2] ), Integer.atoi( information[3] ), monitorID++ };
				GLOBAL.monitors ~= m;
			}
		}
	}
	/*
	if( GLOBAL.monitors.length )
	{
		for( int i = 0; i < GLOBAL.monitors.length; ++i )
			IupMessage( "", toStringz( Integer.toString( GLOBAL.monitors[i].id ) ~ ", " ~ Integer.toString( GLOBAL.monitors[i].x ) ~ ", " ~ Integer.toString( GLOBAL.monitors[i].y ) ~ ", " ~
			Integer.toString( GLOBAL.monitors[i].w ) ~ "x" ~ Integer.toString( GLOBAL.monitors[i].h ) ) );
	}
	*/

	// Init Nav Cache
	GLOBAL.navigation = new CNavCache();
	
	// Init
	AutoComplete.init();
	
	IupRefresh( GLOBAL.mainDlg );
	
	//IUP main Loop
	IupMainLoop();
	
	if( GLOBAL.compilerHelpDlg !is null ) delete GLOBAL.compilerHelpDlg;
	if( GLOBAL.serachInFilesDlg !is null ) delete GLOBAL.serachInFilesDlg;
	
	foreach( _plugin; GLOBAL.pluginMnager )
	{
		if( _plugin !is null ) delete _plugin;
	}	
	
	IupClose();
	
	version(Windows)
	{
		if( GLOBAL.htmlHelp != null ) sharedlib.unload();
		//if( GLOBAL.readFile != null ) sharedFileLoader.unload();
		if( GLOBAL.iconv != null ) loaderlib.unload();
	}
}