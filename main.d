module main;

import iup.iup;
import iup.iup_scintilla;

import global, layout, images.imageData, tools, navcache;
import menu, scintilla, actionManager;
import parser.autocompletion, parser.ast;

debug import std.stdio;
import std.file, std.string, std.conv, std.process, Path = std.path, Array = std.array;

version(Windows)
{
	import core.sys.windows.winuser, core.sys.windows.windef;
	
	version(GUI)
	{
		version(D_Version2)
		{
			pragma(linkerDirective, "/entry:mainCRTStartup");
			pragma(linkerDirective, "/SUBSYSTEM:WINDOWS");
		}
	}
	
	pragma(lib, "winmm.lib"); // For PlaySound()
	pragma(lib, "user32.lib");
	pragma(lib, "iup.lib");
	pragma(lib, "iup_scintilla.lib");
}
else
{
	pragma(lib, "iup");
	pragma(lib, "iup_scintilla");
}


void main( string[] args )
{
	if( IupOpen( null, null ) == IUP_ERROR )
	{
		debug writefln( "IUP open error!!!" );
		return;
	}
	
	version(Windows)
	{
		version(FBIDE)	IupSetGlobal("SINGLEINSTANCE", "poseidonFB - FreeBasic IDE");
		version(DIDE)	IupSetGlobal("SINGLEINSTANCE", "poseidonD - D Programming Language IDE");
			
		if( IupGetGlobal( toStringz( "SINGLEINSTANCE" ) ) == null  )
		{
			IupClose();
			return;
		}
	}
	
	// Dynamic Libraries Load...
	version(Windows)
	{
		SharedLib sharedlib;
		GLOBAL.htmlHelp = null;
		
		try
		{
			sharedlib = SharedLib.load( `hhctrl.ocx` );
			void* ptr = sharedlib.getSymbol("HtmlHelpW");
			if( ptr )
			{
				GLOBAL.htmlHelp = cast(GLOBAL._htmlHelp) ptr;
			}
			else
			{
				debug writefln("HtmlHelpW Symbol not found");
			}
		}
		catch( Exception e )
		{
			GLOBAL.htmlHelp = null;
			
			debug writefln(e.toString);
		}
	}
	

	// Dark Mode
	SharedLib DarkModeLoader;
	version(Windows)
	{
		GLOBAL.AllowDarkModeForWindow = null;
		GLOBAL.InitDarkMode = null;
		GLOBAL.SetWindowTheme = null;
	}
	GLOBAL.SetDarkMode = null;
	try
	{
		version(Windows) DarkModeLoader = SharedLib.load( `DarkMode.dll` );// else DarkModeLoader = SharedLib.load( `./DarkMode.so` );
		if( DarkModeLoader !is null )
		{
			void* ptr = null;
			version(Windows)
			{
				ptr = DarkModeLoader.getSymbol("AllowDarkModeForWindow_FB");
				if( ptr )
				{
					void **point = cast(void **)&GLOBAL.AllowDarkModeForWindow; // binding function address from DLL to our function pointer
					*point = ptr;
				}
				else
					throw new Exception( "Symbol 'AllowDarkModeForWindow_FB' not found" );
				
				
				ptr = null;
				ptr = DarkModeLoader.getSymbol("InitDarkMode_FB");
				if( ptr )
				{
					void **point = cast(void **)&GLOBAL.InitDarkMode; // binding function address from DLL to our function pointer
					*point = ptr;
				}
				else
					throw new Exception( "Symbol 'InitDarkMode_FB' not found" );

				ptr = null;
				ptr = DarkModeLoader.getSymbol("SetWindowTheme_FB");
				if( ptr )
				{
					void **point = cast(void **)&GLOBAL.SetWindowTheme; // binding function address from DLL to our function pointer
					*point = ptr;
				}
				else
					throw new Exception( "Symbol 'SetWindowTheme_FB' not found" );
			}
			
			ptr = null;
			ptr = DarkModeLoader.getSymbol("SetDarkMode_FB");
			if( ptr )
			{
				void **point = cast(void **)&GLOBAL.SetDarkMode; // binding function address from DLL to our function pointer
				*point = ptr;
			}
			else
				throw new Exception( "Symbol 'SetDarkMode_FB' not found" );					
				
				
			debug writefln( "DarkMode.dll and Symbols loaded success!" );
		}
		else
		{
			GLOBAL.SetDarkMode = null;
			throw new Exception( "LOAD DLL ERROR!" );
		}
	}
	catch( Exception e )
	{
		GLOBAL.SetDarkMode = null;
		debug writefln(e.toString);
	}	
	
	
	//  Get poseidonFB exePath & set the new cwd
	GLOBAL.poseidonPath = Path.dirName( args[0] ); // without tail /
	GLOBAL.EnvironmentVars = environment.toAA();
	version(Posix)
	{
		/*
		auto user = getpwuid( getuid() );
		char[] home = fromStringz( user.pw_dir );
		*/
		string home = Path.expandTilde( "~" );

		if( indexOf( GLOBAL.poseidonPath, home ) != 0 )
		{
			GLOBAL.linuxHome = home;
			version(FBIDE)	GLOBAL.linuxHome ~= "/.poseidonFB";
			version(DIDE)	GLOBAL.linuxHome ~= "/.poseidonD";
			
			if( !exists( GLOBAL.linuxHome ) ) std.file.mkdir( GLOBAL.linuxHome );
			if( !exists( GLOBAL.linuxHome ~ "/settings" ) ) std.file.mkdir( GLOBAL.linuxHome ~ "/settings" );
			if( !exists( GLOBAL.linuxHome ~ "/settings/colorTemplates" ) ) std.file.mkdir( GLOBAL.linuxHome ~ "/settings/colorTemplates" );

			foreach( string filename; dirEntries( GLOBAL.poseidonPath ~ "/settings/colorTemplates", "*.ini", SpanMode.shallow) )
				std.file.copy( filename, GLOBAL.linuxHome ~ "/settings/colorTemplates/" ~ Path.baseName( filename ) );
		}
	}
	
	// Init IDE
	createEditorSetting();
	
	load_all_images_icons();
	
	IupScintillaOpen();

	// Set Default Font
	if(  GLOBAL.fonts[0].fontString.length ) IupSetStrGlobal( "DEFAULTFONT", toStringz( GLOBAL.fonts[0].fontString ) );
	IupSetGlobal( "UTF8MODE", "YES" );
	version(Windows) IupSetGlobal( "UTF8MODE_FILE", "YES" );
	
	IupSetStrGlobal( "DLGFGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
	IupSetStrGlobal( "DLGBGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );	
	IupSetStrGlobal( "TXTFGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
	IupSetStrGlobal( "TXTBGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
	
	version(Posix) createMenu();
	
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
	
	version(FBIDE)	IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
	version(DIDE)	IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonD - D Programming Language IDE" );
	IupSetAttribute( GLOBAL.mainDlg, "ICON", "icon_poseidonFB" );
	IupSetAttribute( GLOBAL.mainDlg, "MENU", "mymenu" );
	version(FBIDE)	IupSetAttribute( GLOBAL.mainDlg, "NAME", "poseidonFB" );
	version(DIDE)	IupSetAttribute( GLOBAL.mainDlg, "NAME", "poseidonD" );

	//IupSetGlobal( "IMAGEAUTOSCALE", "DPI" );
	IupSetGlobal( "INPUTCALLBACKS", "YES" );
	IupSetFunction( "GLOBALKEYPRESS_CB", cast(Icallback) &GlobalKeyPress_CB );
	version(Windows) IupSetFunction( "GLOBALWHEEL_CB", cast(Icallback) &GlobalWHEEL_CB );
	
	if( GLOBAL.editorSetting01.PLACEMENT == "MAXIMIZED" ) IupSetAttribute( GLOBAL.mainDlg, "PLACEMENT", "MAXIMIZED" ); else IupSetStrAttribute( GLOBAL.mainDlg, "RASTERSIZE", toStringz( GLOBAL.editorSetting01.RASTERSIZE ) );

	// Set Split %
	IupSetStrAttribute( GLOBAL.explorerSplit, "VALUE", toStringz( GLOBAL.editorSetting01.ExplorerSplit ) );
	

	// For Linux mod
	EditorToggleUint	_editorSetting00 = GLOBAL.editorSetting00;
	EditorLayoutSize	_editorSetting01 = GLOBAL.editorSetting01;
	EditorOpacity		_editorSetting02 = GLOBAL.editorSetting02;
	EditorColorUint		_editColor = GLOBAL.editColor;
	
	if( GLOBAL.SetDarkMode != null && GLOBAL.editorSetting00.UseDarkMode == "ON" )
	{
		version(Windows)
		{
			GLOBAL.bDarkMode = cast(bool) GLOBAL.InitDarkMode();
			if( GLOBAL.bDarkMode )
				GLOBAL.SetDarkMode( true, true );
			else
			{
				debug writefln( "Couldn't fit DarkMode API needs!" );
			}
		}
	}
	
	// Shows dialog
	IupShow( GLOBAL.mainDlg );

	// Restore settings
	GLOBAL.editorSetting00 = _editorSetting00;
	GLOBAL.editorSetting01 = _editorSetting01;
	GLOBAL.editorSetting02 = _editorSetting02;
	GLOBAL.editColor = _editColor;
		
	IupSetStrAttribute( GLOBAL.messageSplit, "VALUE", toStringz( GLOBAL.editorSetting01.MessageSplit ) );	
	if( GLOBAL.editorSetting01.OutlineWindow == "OFF" ) menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
	if( GLOBAL.editorSetting01.MessageWindow == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
	
	createDialog();
	
	IupSetStrAttribute( GLOBAL.documentTabs, "TABFONT", toStringz( GLOBAL.fonts[0].fontString ) );
	IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABFONT", toStringz( GLOBAL.fonts[0].fontString ) );
	IupSetStrAttribute( GLOBAL.projectViewTabs, "FONT", toStringz( GLOBAL.fonts[2].fontString ) );// Leftside
	//IupSetStrAttribute( GLOBAL.fileListTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[3].fontString ) );// Filelist
	IupSetStrAttribute( GLOBAL.messageWindowTabs, "FONT", toStringz( GLOBAL.fonts[6].fontString ) );// Bottom
	IupSetStrAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "FONT", toStringz( GLOBAL.fonts[7].fontString ) );// Output
	IupSetStrAttribute( GLOBAL.messagePanel.getSearchOutputPanelHandle, "FONT", toStringz( GLOBAL.fonts[8].fontString ) );// Search
	IupSetStrAttribute( GLOBAL.statusBar.getLayoutHandle, "FONT", toStringz( GLOBAL.fonts[11].fontString ) );// StatusBar
	IupSetStrAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", toStringz( GLOBAL.fonts[5].fontString ) );// Outline	
	IupSetStrAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[4].fontString ) );// Project
	IupSetStrAttribute( GLOBAL.projectTree.getTreeHandle, "TITLEFONT0", toStringz( GLOBAL.fonts[4].fontString ) );
	IupSetStrAttribute( GLOBAL.projectTree.getTreeHandle, "TITLEFONTSTYLE0", "Bold" );// Project	
	
	GLOBAL.messagePanel.setScintillaColor(); // Set MessagePanel Color
	
	if( GLOBAL.bDarkMode && GLOBAL.editorSetting00.UseDarkMode == "ON" )
	{
		GLOBAL.searchExpander.changeColor();
		GLOBAL.outlineTree.changeColor();
	}
	
	// Load Default Parser
	GLOBAL.objectDefaultParser = cast(shared CASTnode) ParserAction.loadObjectParser();
	
	if( args.length > 1 )
	{
		auto argPath = args[1];
		if( exists( argPath ) )
		{
			version(FBIDE)
			{
				if( Path.baseName( argPath ) == "FB.poseidon" )
				{
					GLOBAL.projectTree.openProject( Path.dirName( argPath ) );				
				}
				else
				{
					if( tools.isParsableExt( Path.extension( argPath ), 7 ) ) ScintillaAction.openFile( argPath );
				}
			}
			else // version(DIDE)
			{
				if( Path.baseName( argPath ) == "D.poseidon" )
				{
					GLOBAL.projectTree.openProject( Path.dirName( argPath ) );				
				}
				else
				{
					if( tools.isParsableExt( Path.extension( argPath ), 3 ) )	ScintillaAction.openFile( argPath );
				}
			}
		}
	}

	if( GLOBAL.editorSetting00.LoadPrevDoc == "ON" )
	{
		foreach( s; GLOBAL.prevPrj )
			GLOBAL.projectTree.openProject( s );
		
		int activePos = -1;
		foreach( s; GLOBAL.prevDoc )
		{
			if( s.length )
			{
				if( s[0] == '*' )
				{
					ScintillaAction.openFile( s[1..$].dup );
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
	foreach( string s; std.string.splitLines( fSTRz( IupGetGlobal( "MONITORSINFO" ) ) ) )
	{
		if( s.length )
		{
			string[] information = Array.split( s, " " );
			if( information.length == 4 )
			{
				Monitor m = { to!(int)( information[0] ), to!(int)( information[1] ), to!(int)( information[2] ), to!(int)( information[3] ), monitorID++ };
				GLOBAL.monitors ~= m;
			}
		}
	}
	

	// Init Nav Cache
	GLOBAL.navigation = new CNavCache();
	
	// Init
	AutoComplete.init();
	
	IupRefresh( GLOBAL.mainDlg );
	
	//IUP main Loop
	IupMainLoop();
	
	if( GLOBAL.compilerHelpDlg !is null ) destroy( GLOBAL.compilerHelpDlg );
	if( GLOBAL.serachInFilesDlg !is null ) destroy( GLOBAL.serachInFilesDlg );
	if( GLOBAL.debugPanel !is null ) GLOBAL.debugPanel.terminal();
	
	foreach( _plugin; GLOBAL.pluginMnager )
		if( _plugin !is null ) destroy( _plugin );
	
	IupClose();
	
	version(Windows) if( sharedlib !is null ) sharedlib.unload();
	if( DarkModeLoader !is null ) DarkModeLoader.unload();
}