module menu;

import iup.iup;
import iup.iup_scintilla;

import global, actionManager, scintilla, project, tools;
import dialogs.singleTextDlg, dialogs.prjPropertyDlg, dialogs.preferenceDlg, dialogs.fileDlg;

import tango.io.Stdout;
import tango.stdc.stringz;
import Integer = tango.text.convert.Integer;
import Util = tango.text.Util, tango.io.UnicodeFile;

import parser.scanner,  parser.token, parser.parser;



void createMenu()
{
	// For Menu
	Ihandle* menu;
	Ihandle* item_new, item_save, item_saveAll, item_open, item_exit, file_menu;
	Ihandle* item_redo, item_undo, item_cut, item_copy, item_paste, item_selectAll, edit_menu;
	Ihandle* item_findReplace, item_findNext, item_findPrevious, item_findReplaceInFiles, item_goto, search_menu;
	Ihandle* view_menu;
	Ihandle* item_newProject, item_openProject, item_closeProject, item_saveProject, item_projectProperties, project_menu;
	Ihandle* item_compile, item_buildrun, item_run, item_build, item_buildAll, item_clean, item_quickRun, build_menu;
	Ihandle* item_runDebug, item_withDebug, item_BuildwithDebug, debug_menu;
	Ihandle* item_tool, item_preference, option_menu;
	

	Ihandle* mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Debug, mainMenu8_Option;

	// File -> New
	item_new = IupItem ("New", null);
	IupSetAttribute(item_new, "KEY", "N");
	IupSetAttribute(item_new, "IMAGE", "icon_newfile");
	IupSetCallback(item_new, "ACTION", cast(Icallback)&newFile_cb);

	item_open = IupItem ("Open", null);
	IupSetAttribute(item_open, "KEY", "O");
	IupSetAttribute(item_open, "IMAGE", "icon_openfile");
	IupSetCallback(item_open, "ACTION", cast(Icallback)&openFile_cb);
	
	item_save = IupItem( "Save", null );
	IupSetAttribute( item_save, "KEY", "S" );
	IupSetAttribute( item_save, "IMAGE", "icon_save" );
	IupSetCallback( item_save, "ACTION", cast(Icallback)&saveFile_cb );

	
	Ihandle* item_saveAs = IupItem( "Save As", null );
	//IupSetAttribute( item_saveAll, "KEY", "A" );
	IupSetAttribute( item_saveAs, "IMAGE", "icon_saveas" );
	IupSetCallback( item_saveAs, "ACTION", cast(Icallback)&saveAsFile_cb );
	

	item_saveAll = IupItem( "SaveAll", null );
	IupSetAttribute( item_saveAll, "KEY", "A" );
	IupSetAttribute( item_saveAll, "IMAGE", "icon_saveall" );
	IupSetCallback( item_saveAll, "ACTION", cast(Icallback)&saveAllFile_cb );
 
	Ihandle* item_close = IupItem( "Close", null );
	IupSetAttribute( item_close, "KEY", "C" );
	IupSetAttribute( item_close, "IMAGE", "icon_delete" );
	IupSetCallback( item_close, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
	});

	Ihandle* item_closeAll = IupItem( "Close All", null );
	IupSetAttribute( item_closeAll, "KEY", "l" );
	IupSetAttribute( item_closeAll, "IMAGE", "icon_deleteall" );
	IupSetCallback( item_closeAll, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		actionManager.ScintillaAction.closeAllDocument();
	});


	Ihandle* recentFilesSubMenu;
	recentFilesSubMenu = IupMenu( null );
	IupSetHandle( "recentFilesSubMenu", recentFilesSubMenu );

	Ihandle* _clearRecentFiles = IupItem( toStringz( "Clear All" ), null );
	IupSetAttribute( _clearRecentFiles, "IMAGE", "icon_deleteall" );
	IupSetCallback( _clearRecentFiles, "ACTION", cast(Icallback) &submenuRecentFilesClear_click_cb );
	IupInsert( recentFilesSubMenu, null, _clearRecentFiles );
	IupInsert( recentFilesSubMenu, null, IupSeparator() );
	IupMap( _clearRecentFiles );

	//Ihandle*[] submenuItem;
	for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
	{
		Ihandle* _new = IupItem( toStringz(GLOBAL.recentFiles[i]), null );
		IupSetCallback( _new, "ACTION", cast(Icallback) &submenuRecentFiles_click_cb );
		IupInsert( recentFilesSubMenu, null, _new );
		IupMap( _new );
	}
	IupRefresh( recentFilesSubMenu );
	
	Ihandle* item_recentFiles = IupSubmenu( "Recent Files", recentFilesSubMenu );
	



	Ihandle* recentPrjsSubMenu;
	recentPrjsSubMenu = IupMenu( null );
	IupSetHandle( "recentPrjsSubMenu", recentPrjsSubMenu );

	Ihandle* _clearRecentPrjs = IupItem( toStringz( "Clear All" ), null );
	IupSetAttribute(_clearRecentPrjs, "IMAGE", "icon_clearall");
	IupSetCallback( _clearRecentPrjs, "ACTION", cast(Icallback) &submenuRecentPrjsClear_click_cb );
	IupInsert( recentPrjsSubMenu, null, _clearRecentPrjs );
	IupInsert( recentPrjsSubMenu, null, IupSeparator() );
	IupMap( _clearRecentPrjs );

	//Ihandle*[] submenuItem;
	for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
	{
		Ihandle* _new = IupItem( toStringz(GLOBAL.recentProjects[i]), null );
		IupSetCallback( _new, "ACTION", cast(Icallback) &submenuRecentProject_click_cb );
		IupInsert( recentPrjsSubMenu, null, _new );
		IupMap( _new );
	}
	IupRefresh( recentPrjsSubMenu );	
	
	Ihandle* item_recent = IupSubmenu( "Recent Projects", recentPrjsSubMenu );

	item_exit = IupItem ("Exit", null);
	IupSetAttribute(item_exit, "KEY", "x");
	IupSetCallback(item_exit, "ACTION", cast(Icallback)&exit_cb);

	// Edit
	item_undo = IupItem ("Undo", null);
	IupSetAttribute(item_undo, "KEY", "U");
	IupSetAttribute(item_undo, "IMAGE", "icon_undo");
	IupSetCallback( item_undo, "ACTION", cast(Icallback) &undo_cb );

	item_redo = IupItem ("Redo", null);
	IupSetAttribute(item_redo, "KEY", "R");
	IupSetAttribute(item_redo, "IMAGE", "icon_redo");
	IupSetCallback( item_redo, "ACTION", cast(Icallback) &redo_cb );

	item_cut = IupItem ("Cut", null);
	IupSetAttribute(item_cut, "KEY", "C");
	IupSetAttribute(item_cut, "IMAGE", "icon_cut");
	IupSetCallback( item_cut, "ACTION", cast(Icallback) &cut_cb );


	item_copy = IupItem ("Copy", null);
	IupSetAttribute(item_copy, "KEY", "o");
	IupSetAttribute(item_copy, "IMAGE", "icon_copy");
	IupSetCallback( item_copy, "ACTION", cast(Icallback) &copy_cb );

	item_paste = IupItem ("Paste", null);
	IupSetAttribute(item_paste, "KEY", "P");
	IupSetAttribute(item_paste, "IMAGE", "icon_paste");
	IupSetCallback( item_paste, "ACTION", cast(Icallback) &paste_cb );

	item_selectAll = IupItem ("Select All", null);
	IupSetAttribute(item_selectAll, "KEY", "A");
	IupSetAttribute(item_selectAll, "IMAGE", "icon_selectall");
	IupSetCallback( item_selectAll, "ACTION", cast(Icallback) &selectall_cb );

	Ihandle* item_comment = IupItem ("(Un)Comment Line", null);
	//IupSetAttribute(item_selectAll, "KEY", "c");
	IupSetAttribute(item_comment, "IMAGE", "icon_comment");
	IupSetCallback( item_comment, "ACTION", cast(Icallback) &comment_cb );

	// Search
	item_findReplace = IupItem( "Find / Replace", null );
	IupSetAttribute(item_findReplace, "IMAGE", "icon_find");
	IupSetAttribute( item_findReplace, "KEY", "F" );
	IupSetCallback( item_findReplace, "ACTION", cast(Icallback) &findReplace_cb );

	item_findNext = IupItem( "Find Next", null );
	IupSetAttribute(item_findNext, "IMAGE", "icon_findnext");
	IupSetAttribute( item_findNext, "KEY", "N" );
	IupSetCallback( item_findNext, "ACTION", cast(Icallback) &findNext_cb );

	item_findPrevious = IupItem( "Find Previous", null );
	IupSetAttribute(item_findPrevious, "IMAGE", "icon_findprev");
	IupSetAttribute( item_findPrevious, "KEY", "P" );
	IupSetCallback( item_findPrevious, "ACTION", cast(Icallback) &findPrev_cb );
	
	item_findReplaceInFiles = IupItem ("Find / Replace In Files", null);
	IupSetAttribute(item_findReplaceInFiles, "IMAGE", "icon_findfiles");
	IupSetAttribute(item_findReplaceInFiles, "KEY", "R");
	IupSetCallback( item_findReplaceInFiles, "ACTION", cast(Icallback) &findReplaceInFiles );

	item_goto = IupItem( "Goto Line", null );
	IupSetAttribute( item_goto, "KEY", "G" );
	IupSetAttribute(item_goto, "IMAGE", "icon_goto");
	IupSetCallback( item_goto, "ACTION", cast(Icallback) &item_goto_cb );

	// View
	GLOBAL.menuOutlineWindow = IupItem ("OutLine", null);
	IupSetAttribute(GLOBAL.menuOutlineWindow, "KEY", "O");
	IupSetAttribute(GLOBAL.menuOutlineWindow, "VALUE", "ON");
	IupSetCallback(GLOBAL.menuOutlineWindow, "ACTION", cast(Icallback)&outline_cb);

	GLOBAL.menuMessageWindow = IupItem ("Message", null);
	IupSetAttribute(GLOBAL.menuMessageWindow, "KEY", "M");
	IupSetAttribute(GLOBAL.menuMessageWindow, "VALUE", "ON");
	IupSetCallback(GLOBAL.menuMessageWindow, "ACTION", cast(Icallback)&message_cb);

	// Project
	item_newProject= IupItem ("New Project", null);
	IupSetAttribute(item_newProject, "KEY", "N");
	IupSetAttribute(item_newProject, "IMAGE", "icon_newprj");
	IupSetCallback(item_newProject, "ACTION", cast(Icallback)&newProject_cb);

	item_openProject = IupItem ("Open Project", null);
	IupSetAttribute(item_openProject, "KEY", "O");
	IupSetAttribute(item_openProject, "IMAGE", "icon_openprj");
	IupSetCallback(item_openProject, "ACTION", cast(Icallback)&openProject_cb);

	Ihandle* item_import = IupItem ("Import FbEdit Project", null);
	//IupSetAttribute(item_exit, "KEY", "x");
	IupSetAttribute(item_import, "IMAGE", "icon_importprj");
	IupSetCallback(item_import, "ACTION", cast(Icallback)&importProject_cb);
	

	item_closeProject = IupItem ("Close Project", null);
	IupSetAttribute(item_closeProject, "KEY", "C");
	IupSetAttribute(item_closeProject, "IMAGE", "icon_clear");
	IupSetCallback(item_closeProject, "ACTION", cast(Icallback)&closeProject_cb);

	Ihandle* item_closeAllProject = IupItem ("Close All Project", null);
	IupSetAttribute(item_closeAllProject, "KEY", "j");
	IupSetAttribute(item_closeAllProject, "IMAGE", "icon_clearall");
	IupSetCallback(item_closeAllProject, "ACTION", cast(Icallback)&closeAllProject_cb);
	
	item_saveProject = IupItem ("Save Project", null);
	IupSetAttribute(item_saveProject, "KEY", "M");
	IupSetCallback(item_saveProject, "ACTION", cast(Icallback)&saveProject_cb);

	Ihandle* item_saveAllProject = IupItem ("Save All Project", null);
	IupSetAttribute(item_saveAllProject, "KEY", "M");
	IupSetCallback(item_saveAllProject, "ACTION", cast(Icallback)&saveAllProject_cb);

	item_projectProperties = IupItem("Properties...", null);
	IupSetAttribute(item_projectProperties, "IMAGE", "icon_properties");
	IupSetAttribute(item_projectProperties, "KEY", "P");
	IupSetCallback(item_projectProperties, "ACTION", cast(Icallback)&projectProperties_cb);

	// Build
	item_compile = IupItem( "Compile File", null );
	IupSetAttribute( item_compile, "KEY", "N" );
	IupSetAttribute(item_compile, "IMAGE", "icon_compile");
	IupSetCallback( item_compile, "ACTION", cast(Icallback)&compile_cb );

	item_buildrun = IupItem( "Compile Run", null );
	IupSetAttribute( item_buildrun, "KEY", "Z" );
	IupSetAttribute(item_buildrun, "IMAGE", "icon_buildrun");
	IupSetCallback( item_buildrun, "ACTION", cast(Icallback)&buildrun_cb );
	
	item_run = IupItem ("Run", null);
	IupSetAttribute(item_run, "KEY", "O");
	IupSetAttribute(item_run, "IMAGE", "icon_run");
	IupSetCallback( item_run, "ACTION", cast(Icallback)&run_cb );

	// Debug
	item_runDebug = IupItem ("Run Debug", null);
	IupSetAttribute(item_runDebug, "KEY", "R");
	IupSetAttribute(item_runDebug, "IMAGE", "icon_debugrun");
	IupSetCallback( item_runDebug, "ACTION", cast(Icallback)&runDebug_cb );

	item_withDebug = IupItem ("Compile With Debug", null);
	IupSetAttribute(item_withDebug, "KEY", "C");
	IupSetAttribute(item_withDebug, "IMAGE", "icon_debugbuild");
	IupSetCallback( item_withDebug, "ACTION", cast(Icallback)&compileWithDebug_cb );
	
	item_BuildwithDebug = IupItem ("Build Project With Debug", null);
	IupSetAttribute(item_BuildwithDebug, "KEY", "B");
	IupSetAttribute(item_BuildwithDebug, "IMAGE", "icon_debugbuild");
	IupSetCallback( item_BuildwithDebug, "ACTION", cast(Icallback)&buildAllWithDebug_cb );
	

	item_buildAll = IupItem ("Build Project", null);
	IupSetAttribute(item_buildAll, "KEY", "M");
	IupSetAttribute(item_buildAll, "IMAGE", "icon_rebuild");
	IupSetCallback( item_buildAll, "ACTION", cast(Icallback)&buildAll_cb );

	item_clean = IupItem("Clean", null);
	IupSetAttribute(item_clean, "KEY", "P");

	item_quickRun = IupItem("Quick Run", null);
	IupSetAttribute( item_quickRun, "IMAGE", "icon_quickrun" );
	IupSetAttribute( item_quickRun, "KEY", "P" );
	IupSetCallback( item_quickRun, "ACTION", cast(Icallback)&quickRun_cb );

	// Option
	Ihandle* _windowsEOL = IupItem( toStringz( "Windows" ), null );
	//IupSetAttribute(_windowsEOL, "IMAGE", "icon_windows");
	IupSetCallback( _windowsEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "0";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 0, 0 ); // SCI_SETEOLMODE	= 2031

		StatusBarAction.update();
	});	
	
	Ihandle* _macEOL = IupItem( toStringz( "Mac" ), null );
	//IupSetAttribute(_macEOL, "IMAGE", "icon_mac");
	IupSetCallback( _macEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "1";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 1, 0 ); // SCI_SETEOLMODE	= 2031
		
		StatusBarAction.update();
	});	
	
	Ihandle* _unixEOL = IupItem( toStringz( "Unix" ), null );
	//IupSetAttribute(_unixEOL, "IMAGE", "icon_linux");
	IupSetCallback( _unixEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "2";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 2, 0 ); // SCI_SETEOLMODE	= 2031

		StatusBarAction.update();
	});

	Ihandle* _eolSubMenu = IupMenu( _windowsEOL, _macEOL, _unixEOL, null  );
	IupSetAttribute(_eolSubMenu, "RADIO", "YES");
	switch( GLOBAL.editorSetting00.EolType )
	{
		case "0":	IupSetAttribute( _windowsEOL, "VALUE", "ON"); break;
		case "1":	IupSetAttribute( _macEOL, "VALUE", "ON"); break;
		case "2":	IupSetAttribute( _unixEOL, "VALUE", "ON"); break;
		default:
	}
	Ihandle* setEOL = IupSubmenu( toStringz( "Set EOL Character" ), _eolSubMenu );

	Ihandle* windowsEOL = IupItem( toStringz( "Windows" ), null );
	IupSetAttribute(windowsEOL, "IMAGE", "icon_windows");
	IupSetCallback( windowsEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			IupScintillaSendMessage( cSci.getIupScintilla, 2029, 0, 0 ); // SCI_CONVERTEOLS 2029
			actionManager.StatusBarAction.update();
		}
	});	
	
	Ihandle* macEOL = IupItem( toStringz( "Mac" ), null );
	IupSetAttribute(macEOL, "IMAGE", "icon_mac");
	IupSetCallback( macEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			IupScintillaSendMessage( cSci.getIupScintilla, 2029, 1, 0 ); // SCI_CONVERTEOLS 2029
			actionManager.StatusBarAction.update();
		}
	});	
	
	Ihandle* unixEOL = IupItem( toStringz( "Unix" ), null );
	IupSetAttribute(unixEOL, "IMAGE", "icon_linux");
	IupSetCallback( unixEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			IupScintillaSendMessage( cSci.getIupScintilla, 2029, 2, 0 ); // SCI_CONVERTEOLS 2029
			actionManager.StatusBarAction.update();
		}
	});	

	Ihandle* eolSubMenu = IupMenu( windowsEOL, macEOL, unixEOL, null  );
	Ihandle* convertEOL = IupSubmenu( toStringz( "Convert EOL Character" ), eolSubMenu );
	

	Ihandle* encodeDefault = IupItem( toStringz( "Default" ), null );
	IupSetCallback( encodeDefault, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF8 = IupItem( toStringz( "UTF8" ), null );
	IupSetCallback( encodeUTF8, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF8BOM = IupItem( toStringz( "UTF8.BOM" ), null );
	IupSetCallback( encodeUTF8BOM, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF16BEBOM = IupItem( toStringz( "UTF16BE.BOM" ), null );
	IupSetCallback( encodeUTF16BEBOM, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF16LEBOM = IupItem( toStringz( "UTF16LE.BOM" ), null );
	IupSetCallback( encodeUTF16LEBOM, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF32BE = IupItem( toStringz( "UTF32BE" ), null );
	IupSetCallback( encodeUTF32BE, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF32BEBOM = IupItem( toStringz( "UTF32BE.BOM" ), null );
	IupSetCallback( encodeUTF32BEBOM, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF32LE = IupItem( toStringz( "UTF32LE" ), null );
	IupSetCallback( encodeUTF32LE, "ACTION", cast(Icallback) &encode_cb );
	Ihandle* encodeUTF32LEBOM = IupItem( toStringz( "UTF32LE.BOM" ), null );
	IupSetCallback( encodeUTF32LEBOM, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeSubMenu = IupMenu( encodeDefault, encodeUTF8, encodeUTF8BOM, encodeUTF16BEBOM, encodeUTF16LEBOM, encodeUTF32BE, encodeUTF32BEBOM, encodeUTF32LE, encodeUTF32LEBOM, null  );
	Ihandle* convertEncoding = IupSubmenu( toStringz( "Convert Encoding" ), encodeSubMenu );

	// Convert Keyword
	Ihandle* upperCase = IupItem( toStringz( "UPPERCASE" ), null );
	//IupSetAttribute(upperCase, "IMAGE", "icon_windows");
	IupSetCallback( upperCase, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		_convertKeyWordCase( 2 );
	});	
	
	Ihandle* lowerCase = IupItem( toStringz( "lowercase" ), null );
	//IupSetAttribute(lowerCase, "IMAGE", "icon_mac");
	IupSetCallback( lowerCase, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		_convertKeyWordCase( 1 );
	});	
	
	Ihandle* mixedCase = IupItem( toStringz( "Mixedcase" ), null );
	//IupSetAttribute(mixedCase, "IMAGE", "icon_linux");
	IupSetCallback( mixedCase, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		_convertKeyWordCase( 3 );
	});	

	Ihandle* caseSubMenu = IupMenu( upperCase, lowerCase, mixedCase, null  );
	Ihandle* convertCase = IupSubmenu( toStringz( "Convert Keyword Case" ), caseSubMenu );


	Ihandle* toolsSubMenu = IupMenu( setEOL, convertEOL, convertEncoding, convertCase, null  );
	item_tool = IupSubmenu( "Tools", toolsSubMenu );
	IupSetAttribute(item_tool, "IMAGE", "icon_tools");
	IupSetAttribute(item_tool, "KEY", "T");



	item_preference = IupItem ("Preference", null);
	IupSetAttribute(item_preference, "IMAGE", "icon_preference");
	IupSetAttribute(item_preference, "KEY", "P");
	IupSetCallback(item_preference, "ACTION", cast(Icallback)&preference_cb);

	Ihandle* item_about = IupItem ("About", null);
	IupSetAttribute(item_about, "IMAGE", "icon_information");
	IupSetCallback( item_about, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		IupMessage( "About", "FreeBasic IDE\nPoseidonFB V0.227\nBy Kuan Hsu (Taiwan)\n2016.10.25" );
	});

	file_menu = IupMenu( 	item_new, 
							item_open, 
							IupSeparator(),
							item_save,
							item_saveAs,
							item_saveAll,
							IupSeparator(),
							item_close,
							item_closeAll,
							IupSeparator(),
							item_recentFiles,
							item_recent,
							IupSeparator(),
							item_exit,
							null );

	edit_menu = IupMenu( 	item_redo,
							item_undo,
							IupSeparator(),
							item_cut,
							item_copy,
							item_paste,
							IupSeparator(),
							item_comment,
							IupSeparator(),
							item_selectAll,
							null );

	search_menu= IupMenu( 	item_findReplace,
							item_findNext,
							item_findPrevious,
							IupSeparator(),
							item_findReplaceInFiles,
							IupSeparator(),
							item_goto,
							null );

	view_menu = IupMenu( 	GLOBAL.menuOutlineWindow,
							GLOBAL.menuMessageWindow,
							null );

	project_menu = IupMenu( item_newProject,
							item_openProject,
							IupSeparator(),
							item_import,
							IupSeparator(),
							item_saveProject,
							item_saveAllProject,
							IupSeparator(),
							item_closeProject,
							item_closeAllProject,
							IupSeparator(),
							item_projectProperties,
							null );							

	build_menu= IupMenu( 	item_compile,
							item_buildrun,
							item_run,
							item_buildAll,
							IupSeparator(),
							//item_clean,
							//IupSeparator(),
							item_quickRun,
							null );

	debug_menu= IupMenu( 	item_runDebug,
							item_withDebug,
							item_BuildwithDebug,
							null );							

	option_menu= IupMenu( 	item_tool,
							item_preference,
							item_about,
							null );

	mainMenu1_File = IupSubmenu( "File", file_menu );
	IupSetAttribute( mainMenu1_File, "KEY" ,"F" );
	mainMenu2_Edit = IupSubmenu( "Edit", edit_menu );
	IupSetAttribute( mainMenu2_Edit, "KEY" ,"E" );
	mainMenu3_Search = IupSubmenu( "Search", search_menu );
	IupSetAttribute( mainMenu3_Search, "KEY" ,"S" );
	mainMenu4_View = IupSubmenu( "View", view_menu );
	IupSetAttribute( mainMenu4_View, "KEY" ,"V" );
	mainMenu5_Project = IupSubmenu( "Project", project_menu );
	IupSetAttribute( mainMenu5_Project, "KEY" ,"P" );	
	mainMenu6_Build = IupSubmenu( "Build", build_menu );
	IupSetAttribute( mainMenu6_Build, "KEY" ,"B" );	
	mainMenu7_Debug = IupSubmenu( "Debug", debug_menu );
	IupSetAttribute( mainMenu7_Debug, "KEY" ,"D" );
	version( linux ) IupSetAttribute( mainMenu7_Debug, "ACTIVE" ,"NO" );
	mainMenu8_Option = IupSubmenu( "Options", option_menu );
	IupSetAttribute( mainMenu8_Option, "KEY" ,"O" );	

	menu = IupMenu( mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Debug, mainMenu8_Option, null );
	IupSetAttribute( menu, "GAP", "30" );
	
	IupSetHandle("mymenu", menu);
}


private void _convertKeyWordCase( int type )
{
	/*
	SCI_SETTARGETSTART = 2190,
	SCI_GETTARGETSTART = 2191,
	SCI_SETTARGETEND = 2192,
	SCI_GETTARGETEND = 2193,
	SCI_REPLACETARGET 2194
	SCI_SEARCHINTARGET = 2197,
	SCI_SETSEARCHFLAGS = 2198,
	SCFIND_WHOLEWORD = 2,
	SCFIND_MATCHCASE = 4,

	SCFIND_WHOLEWORD = 2,
	SCFIND_MATCHCASE = 4,
	SCFIND_WORDSTART = 0x00100000,
	SCFIND_REGEXP = 0x00200000,
	SCFIND_POSIX = 0x00400000,
	*/		
	CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
	if( cSci !is null )
	{
		Ihandle* iupSci = cSci.getIupScintilla;

		foreach( char[] _s; GLOBAL.KEYWORDS )
		{
			foreach( char[] targetText; Util.split( _s, " " ) )
			{
				if( targetText.length )
				{
					int		replaceTextLength = targetText.length;
					char[]	replaceText = tools.convertKeyWordCase( type, targetText );
					
					int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );	// SCI_GETLENGTH = 2006,
					IupScintillaSendMessage( iupSci, 2198, 2, 0 );						// SCI_SETSEARCHFLAGS = 2198,
					IupScintillaSendMessage( iupSci, 2190, 0, 0 ); 						// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );		// SCI_SETTARGETEND = 2192,	

					int posHead = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
					while( posHead > 0 )
					{
						IupScintillaSendMessage( iupSci, 2194, replaceText.length, cast(int) GLOBAL.cString.convert( replaceText ) );				// SCI_REPLACETARGET 2194
						IupScintillaSendMessage( iupSci, 2190, posHead + replaceTextLength, 0 );													// SCI_SETTARGETSTART = 2190,
						documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );																// SCI_GETLENGTH = 2006,
						IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );																// SCI_SETTARGETEND = 2192,	
						posHead = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
					}					
				}
			}
		}
	}
}


extern(C)
{
	int newFile_cb( Ihandle* ih )
	{
		int[] existedID;
		
		foreach( char[] s; GLOBAL.scintillaManager.keys )
		{
			// NONAME#....bas
			if( s.length >= 7 )
			{
				if( s[0..7] == "NONAME#" ) existedID ~= Integer.atoi( s[7..length-4] );
			}
		}

		existedID.sort;

		char[] noname;
		
		if( !existedID.length )
		{
			noname = "NONAME#0.bas";
		}
		else
		{
			for( int i = 0; i < existedID.length; ++ i )
			{
				if( i < existedID[i] )
				{
					noname = "NONAME#" ~ Integer.toString( i ) ~ ".bas";
					break;
				}
			}
		}

		if( !noname.length ) noname = "NONAME#" ~ Integer.toString( existedID.length ) ~ ".bas";

		actionManager.ScintillaAction.newFile( noname, Encoding.UTF_8N, null, false );

		/+
		scope dlg = new CFileDlg( "Create New File", "Source File|*.bas|Inculde File|*.bi|All Files|*.*", "SAVE" );//"Source File|*.bas|Include File|*.bi" );
		char[] fullPath = dlg.getFileName();

		if( fullPath.length )
		{
			actionManager.ScintillaAction.newFile( fullPath );
		}
		+/

		return IUP_DEFAULT;
	}

	
	int openFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( "Open File...", "All Files|*.*|FreeBASIC Sources|*.bas|FreeBASIC Includes|*.bi" );
		char[] fileName = fileSecectDlg.getFileName();

		//Util.substitute( fileName, "\\", "/" );
		if( fileName.length )
		{
			//Stdout( fileName ).newline;
			ScintillaAction.openFile( fileName );
			actionManager.ScintillaAction.updateRecentFiles( fileName );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
			//writefln( "Nothing" );
		}

		return IUP_DEFAULT;
	}

	int saveFile_cb( Ihandle* ih )
	{
		actionManager.ScintillaAction.saveFile( actionManager.ScintillaAction.getActiveCScintilla() );
		return IUP_DEFAULT;
	}
	
	int saveAsFile_cb( Ihandle* ih )
	{
		actionManager.ScintillaAction.saveAs( actionManager.ScintillaAction.getActiveCScintilla(), true, true, IupGetInt( GLOBAL.documentTabs, "VALUEPOS" ) );
		return IUP_DEFAULT;
	}		

	int saveAllFile_cb( Ihandle* ih )
	{
		actionManager.ScintillaAction.saveAllFile();
		return IUP_DEFAULT;
	}
	
	int submenuRecentFilesClear_click_cb( Ihandle* ih )
	{
		GLOBAL.recentFiles.length = 0;
		actionManager.ScintillaAction.updateRecentFiles( null );
		
		return IUP_DEFAULT;
	}

	int submenuRecentFiles_click_cb( Ihandle* ih )
	{
		char[] title = fromStringz( IupGetAttribute( ih, "TITLE" ) ).dup;
		if( title.length )
		{
			if( !ScintillaAction.openFile( title ) )
			{
				IupDestroy( ih );
				char[][] _recentFiles;
				foreach( char[] s; GLOBAL.recentFiles )
				{
					if( s != title ) _recentFiles ~= s;
				}
				GLOBAL.recentFiles.length = 0;
				GLOBAL.recentFiles = _recentFiles;
			}
		}

		return IUP_DEFAULT;
	}
	
	int submenuRecentPrjsClear_click_cb( Ihandle* ih )
	{
		GLOBAL.recentProjects.length = 0;
		GLOBAL.projectTree.updateRecentProjects( null, null );
		
		return IUP_DEFAULT;
	}
	
	int submenuRecentProject_click_cb( Ihandle* ih )
	{
		char[] title = fromStringz( IupGetAttribute( ih, "TITLE" ) ).dup;
		int pos = Util.index( title, " : " );
		if( pos < title.length )
		{
			if( !GLOBAL.projectTree.openProject( Util.trim( title[0..pos].dup ) ) )
			{
				IupDestroy( ih );
				char[][] _recentProjects;
				foreach( char[] s; GLOBAL.recentProjects )
				{
					if( s != title ) _recentProjects ~= s;
				}
				GLOBAL.recentProjects.length = 0;
				GLOBAL.recentProjects = _recentProjects;
			}
		}

		return IUP_DEFAULT;
	}	

	int exit_cb()
	{
		return IUP_CLOSE;
	}

	void undo_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			if( fromStringz(IupGetAttribute( ih, "UNDO" )) == "YES" )
			{
				IupSetAttribute( ih, "UNDO", "YES" );
				IupSetFocus( ih );
			}
		}
	}

	void redo_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			if( fromStringz(IupGetAttribute( ih, "REDO" )) == "YES" )
			{
				IupSetAttribute( ih, "REDO", "YES" );
				IupSetFocus( ih );
			}
		}
	}

	void cut_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetAttribute( ih, "CLIPBOARD", "CUT" );
	}

	void copy_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetAttribute( ih, "CLIPBOARD", "COPY" );
	}

	void paste_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetAttribute( ih, "CLIPBOARD", "PASTE" );
	}		

	void clear_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetAttribute( ih, "CLIPBOARD", "CLEAR" );
	}

	void selectall_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetAttribute( ih, "SELECTION", "ALL" );
	}
	
	void comment_cb()
	{
		Ihandle*	iupSci = actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			int			lineheadPos;
			int			currentPos = actionManager.ScintillaAction.getCurrentPos( iupSci );
			int			currentLine = IupScintillaSendMessage( iupSci, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
			
			char* _selectText = IupGetAttribute( iupSci, "SELECTION" );
			if( _selectText == null ) // Non Selection
			{
				char[] currentLineText = fromStringz( IupGetAttribute( iupSci, "LINEVALUE" ) ).dup;
				if( currentLineText.length )
				{
					//SCI_POSITIONFROMLINE   2167
					if( currentLineText[0] == '\'' )
					{
						lineheadPos = IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
						IupSetAttribute( iupSci, "DELETERANGE", toStringz( Integer.toString( lineheadPos ) ~ "," ~ "1" ) );
					}
					else
					{
						lineheadPos = IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
						IupSetAttributeId( iupSci, "INSERT", lineheadPos, "'" );
					
					}
				}
			}
			else
			{
				char[] selectText = fromStringz( _selectText );
				int headCommaPos = Util.index( selectText, "," );
				int headColonPos = Util.index( selectText, ":" );
				int tailCommaPos = Util.rindex( selectText, "," );
				if( tailCommaPos > headCommaPos )
				{
					int line1 = Integer.atoi( selectText[0..headCommaPos] );
					int line2 = Integer.atoi( selectText[headColonPos+1..headCommaPos] );
					
					if( line1 > line2 )
					{
						int temp = line1;
						line1 = line2;
						line2 = temp;
					}
					
					for( int i = line1; i <= line2; ++ i )
					{
						char[] currentLineText = fromStringz( IupGetAttributeId( iupSci, "LINE", i ) ).dup;
						if( currentLineText.length )
						{
							//SCI_POSITIONFROMLINE   2167
							if( currentLineText[0] == '\'' )
							{
								lineheadPos = IupScintillaSendMessage( iupSci, 2167, i, 0 );
								IupSetAttribute( iupSci, "DELETERANGE", toStringz( Integer.toString( lineheadPos ) ~ "," ~ "1" ) );
							}
							else
							{
								lineheadPos = IupScintillaSendMessage( iupSci, 2167, i, 0 );
								IupSetAttributeId( iupSci, "INSERT", lineheadPos, "'" );
							
							}
						}					
					}
				}
			}
		}
	}

	void findReplace_cb()
	{
		if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
		{
			if( GLOBAL.searchDlg !is null )
			{
				char[] targetText;
				Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
				if( ih !is null ) targetText = fromStringz(IupGetAttribute( ih, toStringz("SELECTEDTEXT") ));

				//if( fromStringz(IupGetAttribute( GLOBAL.searchDlg.getIhandle, "VISIBLE" )) == "NO" ) GLOBAL.searchDlg.show( targetText );
				GLOBAL.searchDlg.show( targetText );
			}
		}
	}

	void findReplaceInFiles()
	{
		if( GLOBAL.serachInFilesDlg !is null )
		{
			char[] targetText;
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih !is null ) targetText = fromStringz(IupGetAttribute( ih, toStringz("SELECTEDTEXT") ));

			//if( fromStringz(IupGetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE" )) == "NO" ) GLOBAL.serachInFilesDlg.show( targetText );
			GLOBAL.serachInFilesDlg.show( targetText );
		}

	}

	
	/*
    SCFIND_WHOLEWORD = 2,
    SCFIND_MATCHCASE = 4,
    SCFIND_WORDSTART = 0x00100000,
    SCFIND_REGEXP = 0x00200000,
    SCFIND_POSIX = 0x00400000,
	*/
	void findNext_cb()
	{
		Ihandle* ih	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			char[] targetText = fromStringz( IupGetAttribute( ih, "SELECTEDTEXT" ) );
			if( targetText.length )
			{
				IupSetAttribute( ih, "SELECTIONPOS", IupGetAttribute( ih, "SELECTIONPOS" ) );
				actionManager.SearchAction.search( ih, targetText, GLOBAL.searchDlg.searchRule, true );
			}
		}
	}

	void findPrev_cb()
	{
		Ihandle* ih	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			char[] targetText = fromStringz(IupGetAttribute( ih, "SELECTEDTEXT" ));
			if( targetText.length )
			{
				char[] beginEndPos = fromStringz( IupGetAttribute( ih, "SELECTIONPOS" ) );
				if( beginEndPos.length )
				{
					int colonPos = Util.index( beginEndPos, ":" );
					if( colonPos < beginEndPos.length )
					{
						char[] newBeginEndPos = beginEndPos[colonPos+1..length] ~ ":" ~ beginEndPos[0..colonPos];
						IupSetAttribute( ih, "SELECTIONPOS", toStringz( newBeginEndPos.dup ) );
						actionManager.SearchAction.search( ih, targetText, GLOBAL.searchDlg.searchRule, false );
					}
				}
				
			}
			
			//actionManager.SearchAction.findPrev( ih, targetText, GLOBAL.searchDlg.searchRule );
			//actionManager.SearchAction.search( ih, targetText, GLOBAL.searchDlg.searchRule, false );
		}
	}

	void item_goto_cb()
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			// Open Dialog Window
			scope gotoLineDlg = new CSingleTextDialog( -1, -1, "Goto Line...", "Line:", null, null, false );
			char[] lineNum = gotoLineDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
			
			if( lineNum.length) actionManager.ScintillaAction.gotoLine( cSci.getFullPath, Integer.atoi( lineNum )  );
		}
	}
	

	int outline_cb( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "ON" )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			GLOBAL.explorerSplit_value = IupGetInt( GLOBAL.explorerSplit, "VALUE" );
			IupSetInt( GLOBAL.explorerSplit, "VALUE", 0 );
			IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 0 );
			IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 0 );

			IupSetAttribute( GLOBAL.explorerSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* thirdChild = IupGetChild( GLOBAL.explorerSplit, 2 );
			IupSetAttribute( thirdChild, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			version(Windows)
			{
				IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 3 );
				IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 3 );
			}
			else
			{
				IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 2 );
				IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 2 );
			}
			IupSetInt( GLOBAL.explorerSplit, "VALUE", GLOBAL.explorerSplit_value );
			IupSetAttribute( GLOBAL.explorerSplit, "ACTIVE", "YES" );
		}

		Ihandle* _activeDocument = ScintillaAction.getActiveIupScintilla();
		if( _activeDocument != null ) IupSetFocus( _activeDocument ); else IupSetFocus( GLOBAL.mainDlg );
		
		return IUP_DEFAULT;
	}

	int message_cb( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "ON" )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			
			int fileListTreeH = -1;
			char[] size = fromStringz( IupGetAttribute( GLOBAL.fileListTree.getTreeHandle, "SIZE" ) );
			int xPos = Util.index( size, "x" );
			if( xPos < size.length ) fileListTreeH = Integer.atoi( size[++xPos..length] );
			
			GLOBAL.messageSplit_value = IupGetInt( GLOBAL.messageSplit, "VALUE" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", 1000 );

			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* SecondChild = IupGetChild( GLOBAL.messageSplit, 1 );
			IupSetAttribute( SecondChild, "ACTIVE", "YES" );

			IupSetAttribute( GLOBAL.outputPanel, "VISIBLE", "NO" );
			IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLE", "NO" );

			if( fileListTreeH == 0 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "YES" );
			IupSetAttribute( GLOBAL.outputPanel, "VISIBLE", "YES" );
			IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLE", "YES" );
		}
		
		return IUP_DEFAULT;
	}

	int preference_cb( Ihandle *ih )
	{
		/*
		version( Windows ) 
		{
			scope dlg = new CPreferenceDialog( 546, 560, "Preference", true );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		else
		{
			scope dlg = new CPreferenceDialog( 546, 576, "Preference", true );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		*/
		scope dlg = new CPreferenceDialog( -1, -1, "Preference", true );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int newProject_cb( Ihandle *ih )
	{
		/*
		version( Windows )
		{
			scope dlg = new CProjectPropertiesDialog( 648, 426, "Project Properties", true, true );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		else
		{
			scope dlg = new CProjectPropertiesDialog( 660, 470, "Project Properties", true, true );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		*/
		scope dlg = new CProjectPropertiesDialog( -1, -1, "Project Properties", true, true );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int openProject_cb( Ihandle *ih )
	{
		GLOBAL.projectTree.openProject();
		return IUP_DEFAULT;
	}

	int importProject_cb( Ihandle *ih )
	{
		GLOBAL.projectTree.importFbEditProject();
		return IUP_DEFAULT;
	}

	int closeProject_cb( Ihandle* ih )
	{
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( activePrjName.length )
		{
			foreach( char[] s; GLOBAL.projectManager[activePrjName].sources ~ GLOBAL.projectManager[activePrjName].includes ~ GLOBAL.projectManager[activePrjName].others )
			{
				if( actionManager.ScintillaAction.closeDocument( s ) == IUP_IGNORE ) return IUP_DEFAULT;
			}

			GLOBAL.projectManager[activePrjName].saveFile();
			if( GLOBAL.editorSetting00.Message == "ON" ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Close Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]"  ) );
			GLOBAL.projectManager.remove( activePrjName );

			int countChild = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
			for( int i = 1; i <= countChild; ++ i )
			{
				int depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", i );
				if( depth == 1 )
				{
					//if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", i )) == activePrjName )
					if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i )) == activePrjName )
					{
						char* user = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i );
						if( user != null ) delete user;
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", i, "SELECTED" );
						// Shadow
						//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "DELNODE", i, "SELECTED" );
						break;
					}
				}
			}

			if( IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
			/*
			int 	id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Get Focus TreeNode
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", id, "SELECTED" );
			*/
		}

		return IUP_DEFAULT;
	}

	int closeAllProject_cb( Ihandle* ih )
	{
		char[][] prjsDir;
		
		foreach( PROJECT p; GLOBAL.projectManager )
		{
			//IupMessage("",toStringz(p.dir) );
			foreach( char[] s; p.sources ~ p.includes ~ p.others )
			{
				if( actionManager.ScintillaAction.closeDocument( s ) == IUP_IGNORE )
				{
					foreach( char[] _s; prjsDir )
					{
						GLOBAL.projectManager.remove( _s );
					}

					IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
					return IUP_DEFAULT; 
				}
			}

			prjsDir ~= p.dir.dup;
			p.saveFile();
			
			int countChild = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
			for( int i = countChild - 1; i > 0; -- i )
			{
				int depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", i );
				if( depth == 1 )
				{
					try
					{
						//char[] _cstring = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", i ) );
						char[] _cstring = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i ) );
						if( _cstring == p.dir )
						{
							char* user = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i );
							if( user != null ) delete user;
							IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", i, "SELECTED" );
							// Shadow
							//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "DELNODE", i, "SELECTED" );

							break;
						}
					}
					catch( Exception e )
					{
						//IupMessage( "", toStringz( e.toString ) );
					}
				}
			}

			if( GLOBAL.editorSetting00.Message == "ON" ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Close Project: [" ~ p.name ~ "]"  ) );
		}

		foreach( char[] s; prjsDir )
		{
			GLOBAL.projectManager.remove( s );
			//IupMessage("Remove",toStringz(s) );
		}

		if( IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" ) == 1 ) IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );

		return IUP_DEFAULT;
	}	

	int saveProject_cb( Ihandle *ih )
	{
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( activePrjName.length )
		{
			GLOBAL.projectManager[activePrjName].saveFile();
		}

		return IUP_DEFAULT;
	}

	int saveAllProject_cb( Ihandle *ih )
	{
		foreach( PROJECT p; GLOBAL.projectManager )
		{
			p.saveFile();
		}
		
		return IUP_DEFAULT;
	}

	int projectProperties_cb( Ihandle *ih )
	{
		//if( !GLOBAL.activeProjectDirName.length ) return IUP_DEFAULT;
		if( !actionManager.ProjectAction.getActiveProjectName.length ) return IUP_DEFAULT;

		/*
		version( Windows )
		{
			scope dlg = new CProjectPropertiesDialog( 648, 426, "Project Properties", true, false );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		else
		{
			scope dlg = new CProjectPropertiesDialog( 656, 470, "Project Properties", true, false );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		*/
		scope dlg = new CProjectPropertiesDialog( -1, -1, "Project Properties", true, false );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int compile_cb( Ihandle *ih )
	{
		ExecuterAction.compile( Util.trim( GLOBAL.defaultOption ) );
		return IUP_DEFAULT;
	}

	int buildrun_cb( Ihandle *ih )
	{
		if( ExecuterAction.compile( Util.trim( GLOBAL.defaultOption ) ) ) ExecuterAction.run();
		return IUP_DEFAULT;
	}	

	int buildAll_cb( Ihandle *ih )
	{
		//saveAllFile_cb( ih );
		ExecuterAction.buildAll();
		return IUP_DEFAULT;
	}

	int quickRun_cb( Ihandle *ih )
	{
		ExecuterAction.quickRun( Util.trim( GLOBAL.defaultOption ) );
		return IUP_DEFAULT;
	}

	int run_cb( Ihandle *ih )
	{
		ExecuterAction.run();
		return IUP_DEFAULT;
	}

	int runDebug_cb( Ihandle *ih )
	{
		if( !GLOBAL.debugPanel.isExecuting && !GLOBAL.debugPanel.isRunning ) GLOBAL.debugPanel.runDebug();
		return IUP_DEFAULT;
	}

	int compileWithDebug_cb( Ihandle *ih )
	{
		GLOBAL.debugPanel.compileWithDebug();
		return IUP_DEFAULT;
	}

	int buildAllWithDebug_cb( Ihandle *ih )
	{
		GLOBAL.debugPanel.buildAllWithDebug();
		return IUP_DEFAULT;
	}

	private int encode_cb( Ihandle *ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			if( !ScintillaAction.saveFile( cSci ) ) return IUP_DEFAULT;
			
			switch( fromStringz( IupGetAttribute( ih, "TITLE" ) ) )
			{
				case "Default"		: cSci.setEncoding( Encoding.Unknown ); break;
				case "UTF8"			: cSci.setEncoding( Encoding.UTF_8N ); break;
				case "UTF8.BOM"		: cSci.setEncoding( Encoding.UTF_8 ); break;
				case "UTF16BE.BOM"	: cSci.setEncoding( Encoding.UTF_16BE ); break;
				case "UTF16LE.BOM"	: cSci.setEncoding( Encoding.UTF_16LE ); break;
				case "UTF32BE"		: cSci.setEncoding( 9 ); break;
				case "UTF32BE.BOM"	: cSci.setEncoding( Encoding.UTF_32BE ); break;
				case "UTF32LE"		: cSci.setEncoding( 10 ); break;
				case "UTF32LE.BOM"	: cSci.setEncoding( Encoding.UTF_32LE ); break;
				default: return IUP_DEFAULT;
			}

			ScintillaAction.saveFile( cSci, true );
			actionManager.StatusBarAction.update();
		}
		return IUP_DEFAULT;
	}
}