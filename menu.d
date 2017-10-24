module menu;

import iup.iup;
import iup.iup_scintilla;

import global, actionManager, scintilla, project, tools, layout;
import dialogs.singleTextDlg, dialogs.prjPropertyDlg, dialogs.preferenceDlg, dialogs.fileDlg, dialogs.customDlg;

import tango.io.Stdout;
import tango.stdc.stringz;
import Integer = tango.text.convert.Integer;
import Util = tango.text.Util, tango.io.UnicodeFile, tango.io.FilePath;;

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
	Ihandle* item_compile, item_buildrun, item_run, item_build, item_buildAll, item_quickRun, build_menu;
	Ihandle* item_runDebug, item_withDebug, item_BuildwithDebug, debug_menu;
	Ihandle* misc_menu;
	Ihandle* item_tool, item_preference, item_language, option_menu;
	

	Ihandle* mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Debug, mainMenu_Misc, mainMenu8_Option;

	// File -> New
	item_new = IupItem( GLOBAL.languageItems["new"].toCString, null);
	IupSetAttribute(item_new, "IMAGE", "icon_newfile");
	IupSetCallback(item_new, "ACTION", cast(Icallback)&newFile_cb);

	item_open = IupItem( GLOBAL.languageItems["open"].toCString, null);
	IupSetAttribute(item_open, "IMAGE", "icon_openfile");
	IupSetCallback(item_open, "ACTION", cast(Icallback)&openFile_cb);
	
	item_save = IupItem( GLOBAL.languageItems["save"].toCString, null );
	IupSetAttribute( item_save, "IMAGE", "icon_save" );
	IupSetCallback( item_save, "ACTION", cast(Icallback)&saveFile_cb );

	
	Ihandle* item_saveAs = IupItem( GLOBAL.languageItems["saveas"].toCString, null );
	IupSetAttribute( item_saveAs, "IMAGE", "icon_saveas" );
	IupSetCallback( item_saveAs, "ACTION", cast(Icallback)&saveAsFile_cb );
	

	item_saveAll = IupItem( GLOBAL.languageItems["saveall"].toCString, null );
	IupSetAttribute( item_saveAll, "IMAGE", "icon_saveall" );
	IupSetCallback( item_saveAll, "ACTION", cast(Icallback)&saveAllFile_cb );
 
	Ihandle* item_close = IupItem( GLOBAL.languageItems["close"].toCString, null );
	IupSetAttribute( item_close, "IMAGE", "icon_delete" );
	IupSetCallback( item_close, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
		return IUP_DEFAULT;
	});

	Ihandle* item_closeAll = IupItem( GLOBAL.languageItems["closeall"].toCString, null );
	IupSetAttribute( item_closeAll, "IMAGE", "icon_deleteall" );
	IupSetCallback( item_closeAll, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		actionManager.ScintillaAction.closeAllDocument();
		return IUP_DEFAULT;
	});


	Ihandle* recentFilesSubMenu;
	recentFilesSubMenu = IupMenu( null );
	IupSetHandle( "recentFilesSubMenu", recentFilesSubMenu );

	Ihandle* _clearRecentFiles = IupItem( GLOBAL.languageItems["clearall"].toCString, null );
	IupSetAttribute( _clearRecentFiles, "IMAGE", "icon_deleteall" );
	IupSetCallback( _clearRecentFiles, "ACTION", cast(Icallback) &submenuRecentFilesClear_click_cb );
	IupInsert( recentFilesSubMenu, null, _clearRecentFiles );
	IupInsert( recentFilesSubMenu, null, IupSeparator() );
	IupMap( _clearRecentFiles );

	//Ihandle*[] submenuItem;
	for( int i = 0; i < GLOBAL.recentFiles.length; ++ i )
	{
		Ihandle* _new = IupItem( GLOBAL.recentFiles[i].toCString, null );
		IupSetCallback( _new, "ACTION", cast(Icallback) &submenuRecentFiles_click_cb );
		IupInsert( recentFilesSubMenu, null, _new );
		IupMap( _new );
	}
	IupRefresh( recentFilesSubMenu );
	
	Ihandle* item_recentFiles = IupSubmenu( GLOBAL.languageItems["recentfiles"].toCString, recentFilesSubMenu );
	



	Ihandle* recentPrjsSubMenu;
	recentPrjsSubMenu = IupMenu( null );
	IupSetHandle( "recentPrjsSubMenu", recentPrjsSubMenu );

	Ihandle* _clearRecentPrjs = IupItem( GLOBAL.languageItems["clearall"].toCString, null );
	IupSetAttribute(_clearRecentPrjs, "IMAGE", "icon_clearall");
	IupSetCallback( _clearRecentPrjs, "ACTION", cast(Icallback) &submenuRecentPrjsClear_click_cb );
	IupInsert( recentPrjsSubMenu, null, _clearRecentPrjs );
	IupInsert( recentPrjsSubMenu, null, IupSeparator() );
	IupMap( _clearRecentPrjs );

	//Ihandle*[] submenuItem;
	for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
	{
		Ihandle* _new = IupItem( GLOBAL.recentProjects[i].toCString, null );
		IupSetCallback( _new, "ACTION", cast(Icallback) &submenuRecentProject_click_cb );
		IupInsert( recentPrjsSubMenu, null, _new );
		IupMap( _new );
	}
	IupRefresh( recentPrjsSubMenu );	
	
	Ihandle* item_recent = IupSubmenu( GLOBAL.languageItems["recentprjs"].toCString, recentPrjsSubMenu );

	item_exit = IupItem( GLOBAL.languageItems["exit"].toCString, null);
	IupSetCallback(item_exit, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		return layout.mainDialog_CLOSE_cb( null );
	});

	// Edit
	item_undo = IupItem( GLOBAL.languageItems["undo"].toCString, null);
	IupSetAttribute(item_undo, "IMAGE", "icon_undo");
	IupSetCallback( item_undo, "ACTION", cast(Icallback) &undo_cb );

	item_redo = IupItem( GLOBAL.languageItems["redo"].toCString, null);
	IupSetAttribute(item_redo, "IMAGE", "icon_redo");
	IupSetCallback( item_redo, "ACTION", cast(Icallback) &redo_cb );

	item_cut = IupItem( GLOBAL.languageItems["cut"].toCString, null);
	IupSetAttribute(item_cut, "IMAGE", "icon_cut");
	IupSetCallback( item_cut, "ACTION", cast(Icallback) &cut_cb );


	item_copy = IupItem( GLOBAL.languageItems["copy"].toCString, null);
	IupSetAttribute(item_copy, "IMAGE", "icon_copy");
	IupSetCallback( item_copy, "ACTION", cast(Icallback) &copy_cb );

	item_paste = IupItem( GLOBAL.languageItems["paste"].toCString, null);
	IupSetAttribute(item_paste, "IMAGE", "icon_paste");
	IupSetCallback( item_paste, "ACTION", cast(Icallback) &paste_cb );

	item_selectAll = IupItem( GLOBAL.languageItems["selectall"].toCString, null);
	IupSetAttribute(item_selectAll, "IMAGE", "icon_selectall");
	IupSetCallback( item_selectAll, "ACTION", cast(Icallback) &selectall_cb );

	Ihandle* item_comment = IupItem( GLOBAL.languageItems["commentline"].toCString, null);
	IupSetAttribute(item_comment, "IMAGE", "icon_comment");
	IupSetCallback( item_comment, "ACTION", cast(Icallback) &comment_cb );

	// Search
	item_findReplace = IupItem( GLOBAL.languageItems["findreplace"].toCString, null );
	IupSetAttribute(item_findReplace, "IMAGE", "icon_find");
	IupSetCallback( item_findReplace, "ACTION", cast(Icallback) &findReplace_cb );

	item_findNext = IupItem( GLOBAL.languageItems["findnext"].toCString, null );
	IupSetAttribute(item_findNext, "IMAGE", "icon_findnext");
	IupSetCallback( item_findNext, "ACTION", cast(Icallback) &findNext_cb );

	item_findPrevious = IupItem( GLOBAL.languageItems["findprev"].toCString, null );
	IupSetAttribute(item_findPrevious, "IMAGE", "icon_findprev");
	IupSetCallback( item_findPrevious, "ACTION", cast(Icallback) &findPrev_cb );
	
	item_findReplaceInFiles = IupItem( GLOBAL.languageItems["findreplacefiles"].toCString, null);
	IupSetAttribute(item_findReplaceInFiles, "IMAGE", "icon_findfiles");
	IupSetCallback( item_findReplaceInFiles, "ACTION", cast(Icallback) &findReplaceInFiles );

	item_goto = IupItem( GLOBAL.languageItems["goto"].toCString, null );
	IupSetAttribute(item_goto, "IMAGE", "icon_goto");
	IupSetCallback( item_goto, "ACTION", cast(Icallback) &item_goto_cb );


	// View
	Ihandle* LineMargin = IupItem( GLOBAL.languageItems["lnmargin"].toCString, null);
	IupSetAttribute( LineMargin, "VALUE", toStringz( GLOBAL.editorSetting00.LineMargin.dup ) );
	IupSetAttribute( LineMargin, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuLineMargin", LineMargin );
	IupSetCallback( LineMargin, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.LineMargin == "ON" ) GLOBAL.editorSetting00.LineMargin = "OFF"; else GLOBAL.editorSetting00.LineMargin = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* BookmarkMargin = IupItem( GLOBAL.languageItems["bkmargin"].toCString, null);
	IupSetAttribute( BookmarkMargin, "VALUE", toStringz( GLOBAL.editorSetting00.BookmarkMargin.dup ) );
	IupSetAttribute( BookmarkMargin, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuBookmarkMargin", BookmarkMargin );
	IupSetCallback( BookmarkMargin, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.BookmarkMargin == "ON" ) GLOBAL.editorSetting00.BookmarkMargin = "OFF"; else GLOBAL.editorSetting00.BookmarkMargin = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	
	
	Ihandle* FoldMargin = IupItem( GLOBAL.languageItems["fdmargin"].toCString, null);
	IupSetAttribute( FoldMargin, "VALUE", toStringz( GLOBAL.editorSetting00.FoldMargin.dup ) );
	IupSetAttribute( FoldMargin, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuFoldMargin", FoldMargin );
	IupSetCallback( FoldMargin, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.FoldMargin == "ON" ) GLOBAL.editorSetting00.FoldMargin = "OFF"; else GLOBAL.editorSetting00.FoldMargin = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	
	
	Ihandle* IndentGuide = IupItem( GLOBAL.languageItems["indentguide"].toCString, null);
	IupSetAttribute( IndentGuide, "VALUE", toStringz( GLOBAL.editorSetting00.IndentGuide.dup ) );
	IupSetAttribute( IndentGuide, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuIndentGuide", IndentGuide );
	IupSetCallback( IndentGuide, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.IndentGuide == "ON" ) GLOBAL.editorSetting00.IndentGuide = "OFF"; else GLOBAL.editorSetting00.IndentGuide = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* ShowEOL = IupItem( GLOBAL.languageItems["showeol"].toCString, null);
	IupSetAttribute( ShowEOL, "VALUE", toStringz( GLOBAL.editorSetting00.ShowEOL.dup ) );
	IupSetAttribute( ShowEOL, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuShowEOL", ShowEOL );
	IupSetCallback( ShowEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.ShowEOL == "ON" ) GLOBAL.editorSetting00.ShowEOL = "OFF"; else GLOBAL.editorSetting00.ShowEOL = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});
	
	Ihandle* ShowSpace = IupItem( GLOBAL.languageItems["showspacetab"].toCString, null);
	IupSetAttribute( ShowSpace, "VALUE", toStringz( GLOBAL.editorSetting00.ShowSpace.dup ) );
	IupSetAttribute( ShowSpace, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuShowSpace", ShowSpace );
	IupSetCallback( ShowSpace, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.ShowSpace == "ON" ) GLOBAL.editorSetting00.ShowSpace = "OFF"; else GLOBAL.editorSetting00.ShowSpace = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});		
	
	Ihandle* BraceMatch = IupItem( GLOBAL.languageItems["bracematchhighlight"].toCString, null);
	IupSetAttribute( BraceMatch, "VALUE", toStringz( GLOBAL.editorSetting00.BraceMatchHighlight.dup ) );
	IupSetAttribute( BraceMatch, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuBraceMatch", BraceMatch );
	IupSetCallback( BraceMatch, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" ) GLOBAL.editorSetting00.BraceMatchHighlight = "OFF"; else GLOBAL.editorSetting00.BraceMatchHighlight = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	
	
	Ihandle* BoldKeyword = IupItem( GLOBAL.languageItems["boldkeyword"].toCString, null);
	IupSetAttribute( BoldKeyword, "VALUE", toStringz( GLOBAL.editorSetting00.BoldKeyword.dup ) );
	IupSetAttribute( BoldKeyword, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuBoldKeyword", BoldKeyword );
	IupSetCallback( BoldKeyword, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.BoldKeyword == "ON" ) GLOBAL.editorSetting00.BoldKeyword = "OFF"; else GLOBAL.editorSetting00.BoldKeyword = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* CaretLine = IupItem( GLOBAL.languageItems["showcaretline"].toCString, null);
	IupSetAttribute( CaretLine, "VALUE", toStringz( GLOBAL.editorSetting00.CaretLine.dup ) );
	IupSetAttribute( CaretLine, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuCaretLine", CaretLine );
	IupSetCallback( CaretLine, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.CaretLine == "ON" ) GLOBAL.editorSetting00.CaretLine = "OFF"; else GLOBAL.editorSetting00.CaretLine = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* HighlightCurrentWord = IupItem( GLOBAL.languageItems["hlcurrentword"].toCString, null);
	IupSetAttribute( HighlightCurrentWord, "VALUE", toStringz( GLOBAL.editorSetting00.HighlightCurrentWord.dup ) );
	IupSetAttribute( HighlightCurrentWord, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuHighlightCurrentWord", HighlightCurrentWord );
	IupSetCallback( HighlightCurrentWord, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.HighlightCurrentWord == "ON" ) GLOBAL.editorSetting00.HighlightCurrentWord = "OFF"; else GLOBAL.editorSetting00.HighlightCurrentWord = "ON";
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});

	
	// Project
	item_newProject= IupItem( GLOBAL.languageItems["newprj"].toCString, null);
	IupSetAttribute(item_newProject, "IMAGE", "icon_newprj");
	IupSetCallback(item_newProject, "ACTION", cast(Icallback)&newProject_cb);

	item_openProject = IupItem( GLOBAL.languageItems["openprj"].toCString, null);
	IupSetAttribute(item_openProject, "IMAGE", "icon_openprj");
	IupSetCallback(item_openProject, "ACTION", cast(Icallback)&openProject_cb);

	Ihandle* item_import = IupItem( GLOBAL.languageItems["importprj"].toCString, null);
	IupSetAttribute(item_import, "IMAGE", "icon_importprj");
	IupSetCallback(item_import, "ACTION", cast(Icallback)&importProject_cb);
	

	item_closeProject = IupItem( GLOBAL.languageItems["closeprj"].toCString, null);
	IupSetAttribute(item_closeProject, "IMAGE", "icon_clear");
	IupSetCallback(item_closeProject, "ACTION", cast(Icallback)&closeProject_cb);

	Ihandle* item_closeAllProject = IupItem( GLOBAL.languageItems["closeallprj"].toCString, null);
	IupSetAttribute(item_closeAllProject, "IMAGE", "icon_clearall");
	IupSetCallback(item_closeAllProject, "ACTION", cast(Icallback)&closeAllProject_cb);
	
	item_saveProject = IupItem( GLOBAL.languageItems["saveprj"].toCString, null);
	IupSetCallback(item_saveProject, "ACTION", cast(Icallback)&saveProject_cb);

	Ihandle* item_saveAllProject = IupItem( GLOBAL.languageItems["saveallprj"].toCString, null);
	IupSetCallback(item_saveAllProject, "ACTION", cast(Icallback)&saveAllProject_cb);

	item_projectProperties = IupItem( GLOBAL.languageItems["properties"].toCString, null);
	IupSetAttribute(item_projectProperties, "IMAGE", "icon_properties");
	IupSetCallback(item_projectProperties, "ACTION", cast(Icallback)&projectProperties_cb);

	// Build
	item_compile = IupItem( GLOBAL.languageItems["compile"].toCString, null );
	IupSetAttribute(item_compile, "IMAGE", "icon_compile");
	IupSetCallback( item_compile, "ACTION", cast(Icallback)&compile_cb );

	item_buildrun = IupItem( GLOBAL.languageItems["compilerun"].toCString, null );
	IupSetAttribute(item_buildrun, "IMAGE", "icon_buildrun");
	IupSetCallback( item_buildrun, "ACTION", cast(Icallback)&buildrun_cb );
	
	item_run = IupItem( GLOBAL.languageItems["run"].toCString, null);
	IupSetAttribute(item_run, "IMAGE", "icon_run");
	IupSetCallback( item_run, "ACTION", cast(Icallback)&run_cb );

	// Debug
	item_runDebug = IupItem( GLOBAL.languageItems["rundebug"].toCString, null);
	IupSetAttribute(item_runDebug, "IMAGE", "icon_debugrun");
	IupSetCallback( item_runDebug, "ACTION", cast(Icallback)&runDebug_cb );

	item_withDebug = IupItem( GLOBAL.languageItems["compiledebug"].toCString, null);
	IupSetAttribute(item_withDebug, "IMAGE", "icon_debugbuild");
	IupSetCallback( item_withDebug, "ACTION", cast(Icallback)&compileWithDebug_cb );
	
	item_BuildwithDebug = IupItem( GLOBAL.languageItems["builddebug"].toCString, null);
	IupSetAttribute(item_BuildwithDebug, "IMAGE", "icon_debugbuild");
	IupSetCallback( item_BuildwithDebug, "ACTION", cast(Icallback)&buildAllWithDebug_cb );
	

	item_buildAll = IupItem( GLOBAL.languageItems["buildprj"].toCString, null);
	IupSetAttribute(item_buildAll, "IMAGE", "icon_rebuild");
	IupSetCallback( item_buildAll, "ACTION", cast(Icallback)&buildAll_cb );

	item_quickRun = IupItem( GLOBAL.languageItems["quickrun"].toCString, null);
	IupSetAttribute( item_quickRun, "IMAGE", "icon_quickrun" );
	IupSetCallback( item_quickRun, "ACTION", cast(Icallback)&quickRun_cb );


	// Miscelaneous 
	GLOBAL.menuOutlineWindow = IupItem( GLOBAL.languageItems["outline"].toCString, null);
	IupSetAttribute(GLOBAL.menuOutlineWindow, "VALUE", "ON");
	//IupSetCallback(GLOBAL.menuOutlineWindow, "ACTION", cast(Icallback)&outline_cb);
	IupSetCallback(GLOBAL.menuOutlineWindow, "ACTION", cast(Icallback)&outlineMenuItem_cb);
	
	GLOBAL.menuMessageWindow = IupItem( GLOBAL.languageItems["message"].toCString, null);
	IupSetAttribute(GLOBAL.menuMessageWindow, "VALUE", "ON");
	//IupSetCallback(GLOBAL.menuMessageWindow, "ACTION", cast(Icallback)&message_cb);
	IupSetCallback(GLOBAL.menuMessageWindow, "ACTION", cast(Icallback)&messageMenuItem_cb);

	Ihandle* fullScreenItem = IupItem( GLOBAL.languageItems["fullscreen"].toCString, null);
	IupSetAttribute( fullScreenItem, "VALUE", toStringz( GLOBAL.editorSetting01.USEFULLSCREEN.dup ) );
	IupSetAttribute( fullScreenItem, "IMAGE", "icon_fullscreen" );
	IupSetCallback( fullScreenItem, "ACTION", cast(Icallback) &fullscreenMenuItem_cb);
	
	Ihandle* ideMessage = IupItem( GLOBAL.languageItems["showidemessage"].toCString, null);
	IupSetAttribute( ideMessage, "IMAGE", "icon_idemessage" );
	IupSetCallback( ideMessage, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.IDEMessageDlg !is null )
		{
			IupSetAttribute( GLOBAL.IDEMessageDlg.getIhandle, "TOPMOST", "YES" );
			IupShow( GLOBAL.IDEMessageDlg.getIhandle );
		}
		return IUP_DEFAULT;
	});
	

	// Option
	Ihandle* _windowsEOL = IupItem( toStringz( "Windows" ), null );
	//IupSetAttribute(_windowsEOL, "IMAGE", "icon_windows");
	IupSetCallback( _windowsEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "0";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 0, 0 ); // SCI_SETEOLMODE	= 2031

		StatusBarAction.update();
		return IUP_DEFAULT;
	});	
	
	Ihandle* _macEOL = IupItem( toStringz( "Mac" ), null );
	//IupSetAttribute(_macEOL, "IMAGE", "icon_mac");
	IupSetCallback( _macEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "1";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 1, 0 ); // SCI_SETEOLMODE	= 2031
		
		StatusBarAction.update();
		return IUP_DEFAULT;
	});	
	
	Ihandle* _unixEOL = IupItem( toStringz( "Unix" ), null );
	//IupSetAttribute(_unixEOL, "IMAGE", "icon_linux");
	IupSetCallback( _unixEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "2";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 2, 0 ); // SCI_SETEOLMODE	= 2031

		StatusBarAction.update();
		return IUP_DEFAULT;
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
	Ihandle* setEOL = IupSubmenu( GLOBAL.languageItems["seteol"].toCString, _eolSubMenu );

	Ihandle* windowsEOL = IupItem( toStringz( "Windows" ), null );
	IupSetAttribute(windowsEOL, "IMAGE", "icon_windows");
	IupSetCallback( windowsEOL, "ACTION", cast(Icallback) &SetAndConvertEOL_CB );
	
	Ihandle* macEOL = IupItem( toStringz( "Mac" ), null );
	IupSetAttribute(macEOL, "IMAGE", "icon_mac");
	IupSetCallback( macEOL, "ACTION", cast(Icallback) &SetAndConvertEOL_CB );
	
	Ihandle* unixEOL = IupItem( toStringz( "Unix" ), null );
	IupSetAttribute(unixEOL, "IMAGE", "icon_linux");
	IupSetCallback( unixEOL, "ACTION", cast(Icallback) &SetAndConvertEOL_CB );

	Ihandle* eolSubMenu = IupMenu( windowsEOL, macEOL, unixEOL, null  );
	Ihandle* convertEOL = IupSubmenu( GLOBAL.languageItems["converteol"].toCString, eolSubMenu );
	

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
	Ihandle* convertEncoding = IupSubmenu( GLOBAL.languageItems["convertencoding"].toCString, encodeSubMenu );

	// Convert Keyword
	Ihandle* upperCase = IupItem( GLOBAL.languageItems["uppercase"].toCString, null );
	//IupSetAttribute(upperCase, "IMAGE", "icon_windows");
	IupSetCallback( upperCase, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		_convertKeyWordCase( 2 );
		return IUP_DEFAULT;
	});	
	
	Ihandle* lowerCase = IupItem( GLOBAL.languageItems["lowercase"].toCString, null );
	//IupSetAttribute(lowerCase, "IMAGE", "icon_mac");
	IupSetCallback( lowerCase, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		_convertKeyWordCase( 1 );
		return IUP_DEFAULT;
	});	
	
	Ihandle* mixedCase = IupItem( GLOBAL.languageItems["mixercase"].toCString, null );
	//IupSetAttribute(mixedCase, "IMAGE", "icon_linux");
	IupSetCallback( mixedCase, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		_convertKeyWordCase( 3 );
		return IUP_DEFAULT;
	});	

	Ihandle* caseSubMenu = IupMenu( upperCase, lowerCase, mixedCase, null  );
	Ihandle* convertCase = IupSubmenu( GLOBAL.languageItems["convertcase"].toCString, caseSubMenu );
	
	Ihandle* customTooledit = IupItem( GLOBAL.languageItems["setcustomtool"].toCString, null );
	IupSetAttribute( customTooledit, "IMAGE", "icon_toolitem" );
	//IupSetAttribute( customTooledit, "ACTIVE", "NO" );
	IupSetCallback( customTooledit, "ACTION", cast(Icallback)&coustomTooledit_cb );
	
	Ihandle* markIupSeparator = IupSeparator();
	IupSetAttribute( markIupSeparator, "TITLE", "" );
	Ihandle* toolsSubMenu = IupMenu( setEOL, convertEOL, convertEncoding, convertCase, IupSeparator(), customTooledit, markIupSeparator, null  );
	IupSetHandle( "toolsSubMenu", toolsSubMenu );
	
	item_tool = IupSubmenu( GLOBAL.languageItems["tools"].toCString, toolsSubMenu );
	IupSetAttribute(item_tool, "IMAGE", "icon_tools");

	for( int i = 0; i < GLOBAL.customTools.length - 1; ++ i )
	{
		if( GLOBAL.customTools[i].name.toDString.length )
		{
			Ihandle* _new = IupItem( GLOBAL.customTools[i].name.toCString, null );
			IupSetCallback( _new, "ACTION", cast(Icallback) &customtool_menu_click_cb );
			IupAppend( toolsSubMenu, _new );
			IupMap( _new );
		}
	}
	IupRefresh( toolsSubMenu );	


	item_preference = IupItem( GLOBAL.languageItems["preference"].toCString, null);
	IupSetAttribute(item_preference, "IMAGE", "icon_preference");
	IupSetCallback(item_preference, "ACTION", cast(Icallback)&preference_cb);
	
	
	Ihandle* languageSubMenu;
	languageSubMenu = IupMenu( null );

	Ihandle* _loadLngFiles = IupItem( GLOBAL.languageItems["openlanguage"].toCString, null );
	IupSetAttribute( _loadLngFiles, "IMAGE", "icon_openfile" );
	IupSetCallback( _loadLngFiles, "ACTION", cast(Icallback) &submenuLoadlng_click_cb );
	IupInsert( languageSubMenu, null, _loadLngFiles );
	IupInsert( languageSubMenu, null, IupSeparator() );
	IupMap( _loadLngFiles );
	
	Ihandle* _lng;
	if( GLOBAL.language.length ) _lng = IupItem( toStringz( GLOBAL.language ), null ); else  _lng = IupItem( GLOBAL.languageItems["default"].toCString, null );
	IupInsert( languageSubMenu, null, _lng );
	IupMap( _lng );
	IupSetHandle( "_lng", _lng );
	
	IupRefresh( languageSubMenu );
	
	item_language = IupSubmenu( GLOBAL.languageItems["language"].toCString, languageSubMenu );
	
	
	Ihandle* item_about = IupItem( GLOBAL.languageItems["about"].toCString, null );
	IupSetAttribute(item_about, "IMAGE", "icon_information");
	IupSetCallback( item_about, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		IupMessage( GLOBAL.languageItems["about"].toCString, "FreeBasic IDE\nPoseidonFB Sparta (V0.324)\nBy Kuan Hsu (Taiwan)\n2017.10.24" );
		return IUP_DEFAULT;
	});
	
	Ihandle* item_manual = IupItem( GLOBAL.languageItems["manual"].toCString, null );
	IupSetAttribute( item_manual, "IMAGE", "icon_fbmanual" );
	IupSetCallback( item_manual, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		version(Windows) IupExecute( GLOBAL.manualPath.toCString, "" ); else IupExecute( "kchmviewer", GLOBAL.manualPath.toCString );
		return IUP_DEFAULT;
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
	
	view_menu = IupMenu( 	LineMargin,
							BookmarkMargin,
							FoldMargin,
							IupSeparator(),
							IndentGuide,
							ShowEOL,
							ShowSpace,
							BraceMatch,
							BoldKeyword,
							IupSeparator(),
							CaretLine,
							HighlightCurrentWord,
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
							
	misc_menu= IupMenu( 	GLOBAL.menuOutlineWindow,
							GLOBAL.menuMessageWindow,
							IupSeparator(),
							fullScreenItem,
							IupSeparator(),
							ideMessage,
							null );

	option_menu= IupMenu( 	item_tool,
							item_language,
							item_preference,
							IupSeparator(),
							item_about,
							item_manual,
							null );

	mainMenu1_File = IupSubmenu( GLOBAL.languageItems["file"].toCString, file_menu );
	mainMenu2_Edit = IupSubmenu( GLOBAL.languageItems["edit"].toCString, edit_menu );
	mainMenu3_Search = IupSubmenu( GLOBAL.languageItems["search"].toCString, search_menu );
	mainMenu4_View = IupSubmenu( GLOBAL.languageItems["view"].toCString, view_menu );
	mainMenu5_Project = IupSubmenu( GLOBAL.languageItems["prj"].toCString, project_menu );
	mainMenu6_Build = IupSubmenu( GLOBAL.languageItems["build"].toCString, build_menu );
	mainMenu7_Debug = IupSubmenu( GLOBAL.languageItems["debug"].toCString, debug_menu );
	mainMenu_Misc = IupSubmenu( GLOBAL.languageItems["windows"].toCString, misc_menu );
	mainMenu8_Option = IupSubmenu( GLOBAL.languageItems["options"].toCString, option_menu );

	menu = IupMenu( mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Debug, mainMenu_Misc, mainMenu8_Option, null );
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
		int	documentLength = IupGetInt( iupSci, "COUNT" );

		IupScintillaSendMessage( iupSci, 2198, 2, 0 );						// SCI_SETSEARCHFLAGS = 2198,

		foreach( IupString _s; GLOBAL.KEYWORDS )
		{
			foreach( char[] targetText; Util.split( _s.toDString, " " ) )
			{
				if( targetText.length )
				{
					int		replaceTextLength = targetText.length;
					char[]	replaceText = tools.convertKeyWordCase( type, targetText );

					IupScintillaSendMessage( iupSci, 2190, 0, 0 ); 						// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( iupSci, 2192, documentLength, 0 ); 		// SCI_SETTARGETEND = 2192,

					int posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
					while( posHead >= 0 )
					{
						IupSetAttribute( iupSci, "REPLACETARGET", GLOBAL.cString.convert( replaceText ) );
						IupScintillaSendMessage( iupSci, 2190, posHead + replaceTextLength, 0 );	// SCI_SETTARGETSTART = 2190,
						IupScintillaSendMessage( iupSci, 2192, documentLength, 0 );					// SCI_SETTARGETSTART = 2190,
					
						posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
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

		version(Windows) actionManager.ScintillaAction.newFile( noname, Encoding.UTF_8, null, false ); else actionManager.ScintillaAction.newFile( noname, Encoding.UTF_8N, null, false );

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
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString() ~ "...", GLOBAL.languageItems["basfile"].toDString() ~ "|*.bas|" ~  GLOBAL.languageItems["bifile"].toDString() ~ "|*.bi|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*|", "OPEN", "YES" );
		foreach( char[] s; fileSecectDlg.getFilesName() )
		{
			if( s.length )
			{
				ScintillaAction.openFile( s );
				actionManager.ScintillaAction.updateRecentFiles( s );
			}
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
		actionManager.ScintillaAction.updateRecentFiles( null );
		return IUP_DEFAULT;
	}
	
	int submenuLoadlng_click_cb( Ihandle* ih )
	{
		Ihandle *dlg = IupFileDlg(); 

		IupSetAttribute( dlg, "DIALOGTYPE", "OPEN" );
		IupSetAttribute( dlg, "TITLE", GLOBAL.languageItems["openlanguage"].toCString );
		IupSetAttribute( dlg, "DIRECTORY", "settings/language" );
		IupSetAttribute( dlg, "EXTFILTER", toStringz( GLOBAL.languageItems["lngfile"].toDString() ~ "|*.lng|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*|" ) );
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );
		
		if( IupGetInt( dlg, "STATUS") == 0 )
		{
			char[] fileString = Util.trim( fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup );
			scope _fp = new FilePath( fileString );
			if( _fp.exists() )
			{
				Ihandle* _ih = IupGetHandle( "_lng" );
				if( _ih != null )
				{
					IupSetAttribute( _ih, "TITLE", toStringz( _fp.name ) );
					GLOBAL.language = _fp.name;
					
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION" );
					IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["needrestart"].toCString );
					IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["message"].toCString );
					IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
				}
			}
		}
		
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
				
				IupString[] _recentFiles;
				foreach( IupString s; GLOBAL.recentFiles )
				{
					if( s.toDString != title ) _recentFiles ~= new IupString( s.toDString );
				}
				
				foreach( s; GLOBAL.recentFiles )
					delete s;
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
				IupString[] _recentProjects;
				
				foreach( IupString s; GLOBAL.recentProjects )
				{
					if( s.toDString != title ) _recentProjects ~= new IupString( s.toDString );
				}
				
				foreach( s; GLOBAL.recentProjects )
					delete s;
				GLOBAL.recentProjects.length = 0;
				
				GLOBAL.recentProjects = _recentProjects;
			}
		}

		return IUP_DEFAULT;
	}	

	void undo_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			if( fromStringz(IupGetAttribute( ih, "UNDO" )) == "YES" )
			{
				GLOBAL.bUndoRedoAction = true;
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
				GLOBAL.bUndoRedoAction = true;
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
			int			currentLine = cast(int) IupScintillaSendMessage( iupSci, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
			
			char* _selectText = IupGetAttribute( iupSci, "SELECTION" );
			if( _selectText == null ) // Non Selection
			{
				char[] currentLineText = fromStringz( IupGetAttribute( iupSci, "LINEVALUE" ) ).dup;
				if( currentLineText.length )
				{
					//SCI_POSITIONFROMLINE   2167
					if( currentLineText[0] == '\'' )
					{
						lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
						IupSetAttribute( iupSci, "DELETERANGE", toStringz( Integer.toString( lineheadPos ) ~ "," ~ "1" ) );
					}
					else
					{
						lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
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
					int line2 = Integer.atoi( selectText[headColonPos+1..tailCommaPos] );
					
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
								lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, i, 0 );
								IupSetAttribute( iupSci, "DELETERANGE", toStringz( Integer.toString( lineheadPos ) ~ "," ~ "1" ) );
							}
							else
							{
								lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, i, 0 );
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
			scope gotoLineDlg = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["sc_goto"].toDString() ~ "...", GLOBAL.languageItems["line"].toDString() ~ ":", null, null, false );
			char[] lineNum = gotoLineDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
			
			lineNum = Util.trim( lineNum );
			if( lineNum.length)
			{
				int pos = Util.rindex( lineNum, "x" );
				if( pos >= lineNum.length )	pos = Util.rindex( lineNum, ":" );
				if( pos < lineNum.length )
				{
					try
					{
						int left = Integer.atoi( Util.trim( lineNum[0..pos] ) );
						int right = Integer.atoi( Util.trim( lineNum[pos+1..$] ) );
						
						
						char[] LineCol = Integer.toString( left - 1 )  ~ "," ~ Integer.toString( right - 1 );
						IupSetAttribute( cSci.getIupScintilla, "CARET", toStringz( LineCol.dup ) );
						actionManager.StatusBarAction.update();
						IupSetFocus( cSci.getIupScintilla );
					}
					catch
					{
					}
					return;
				}
				else
				{
					try
					{
						if( lineNum[0] == '-' )
						{
							int value = Integer.atoi( lineNum[1..$] );
							value --;
							
							IupSetAttribute( cSci.getIupScintilla, "CARETPOS", toStringz( Integer.toString(value).dup ) );
							actionManager.StatusBarAction.update();
							IupSetFocus( cSci.getIupScintilla );
							return;
						}
					}
					catch
					{
						return;
					}
				}
				
				GLOBAL.navigation.addCache( cSci.getFullPath, Integer.atoi( lineNum ) );
				actionManager.ScintillaAction.gotoLine( cSci.getFullPath, Integer.atoi( lineNum ) );
				actionManager.StatusBarAction.update();
			}
		}
	}
	
	int outlineMenuItem_cb( Ihandle *ih )
	{
		/*
		Ihandle* buttonHandle = IupGetHandle( "outlineButtonHide" );
		if( buttonHandle != null )
		{
			if( fromStringz( IupGetAttribute( buttonHandle, "VALUE" ) ) == "ON" ) IupSetAttribute( buttonHandle, "VALUE", "OFF" ); else IupSetAttribute( buttonHandle, "VALUE", "ON" );
		}
		*/
		return outline_cb( ih );
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

		if( GLOBAL.fileListTree.getTreeH <= 1 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );

		Ihandle* _activeDocument = ScintillaAction.getActiveIupScintilla();
		if( _activeDocument != null ) IupSetFocus( _activeDocument ); else IupSetFocus( GLOBAL.mainDlg );
		
		return IUP_DEFAULT;
	}
	
	int fullscreenMenuItem_cb( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "OFF" )
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			GLOBAL.editorSetting01.USEFULLSCREEN = "ON";
			IupSetAttribute( GLOBAL.mainDlg, "FULLSCREEN", "YES" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			GLOBAL.editorSetting01.USEFULLSCREEN = "OFF";
			IupSetAttribute( GLOBAL.mainDlg, "FULLSCREEN", "NO" );
			IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
		}
		
		return IUP_DEFAULT;
	}
	
	int messageMenuItem_cb( Ihandle *ih )
	{
		/*
		Ihandle* buttonHandle = IupGetHandle( "messageButtonHide" );
		if( buttonHandle != null )
		{
			if( fromStringz( IupGetAttribute( buttonHandle, "VALUE" ) ) == "ON" ) IupSetAttribute( buttonHandle, "VALUE", "OFF" ); else IupSetAttribute( buttonHandle, "VALUE", "ON" );
		}
		*/
		return message_cb( ih );
	}
	
	int message_cb( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "ON" )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			
			bool bCloseFileListTree;
			if( GLOBAL.fileListTree.getTreeH <= 1 ) bCloseFileListTree = true;

			GLOBAL.messageSplit_value = IupGetInt( GLOBAL.messageSplit, "VALUE" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", 1000 );

			if( bCloseFileListTree ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );

			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* SecondChild = IupGetChild( GLOBAL.messageSplit, 1 );
			IupSetAttribute( SecondChild, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "YES" );
		}
		
		return IUP_DEFAULT;
	}
	
	int coustomTooledit_cb( Ihandle *ih )
	{
		version(Windows)
		{
			scope dlg = new CCustomDialog( 480, 240, GLOBAL.languageItems["setcustomtool"].toDString(), false );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		}
		else
		{
			scope dlg = new CCustomDialog( 492, 250, GLOBAL.languageItems["setcustomtool"].toDString(), false );
			dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
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
		scope dlg = new CPreferenceDialog( -1, 380, GLOBAL.languageItems["caption_preference"].toDString(), true );
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
		scope dlg = new CProjectPropertiesDialog( -1, -1, GLOBAL.languageItems["caption_prjproperties"].toDString(), true, true );
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
			if( GLOBAL.editorSetting00.Message == "ON" ) GLOBAL.IDEMessageDlg.print( "Close Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]" );//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Close Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]"  ) );
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

			if( IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" ) == 1 ) GLOBAL.statusBar.setPrjName( "" );

			// Update Filelist Size
			if( GLOBAL.fileListTree.getTreeH() <= 1 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );			
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

					//IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
					GLOBAL.statusBar.setPrjName( "" );
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

			if( GLOBAL.editorSetting00.Message == "ON" ) GLOBAL.IDEMessageDlg.print( "Close Project: [" ~ p.name ~ "]" );//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Close Project: [" ~ p.name ~ "]"  ) );
		}

		foreach( char[] s; prjsDir )
		{
			GLOBAL.projectManager.remove( s );
			//IupMessage("Remove",toStringz(s) );
		}

		if( IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" ) == 1 ) GLOBAL.statusBar.setPrjName( "" );//IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
		
		// Update Filelist Size
		if( GLOBAL.fileListTree.getTreeH() <= 1 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );

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
		scope dlg = new CProjectPropertiesDialog( -1, -1, GLOBAL.languageItems["caption_prjproperties"].toDString(), true, false );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int compile_cb( Ihandle *ih )
	{
		ExecuterAction.compile( /*Util.trim( GLOBAL.defaultOption.toDString )*/ );
		return IUP_DEFAULT;
	}

	int buildrun_cb( Ihandle *ih )
	{
		if( ExecuterAction.compile( /*Util.trim( GLOBAL.defaultOption.toDString )*/ ) ) ExecuterAction.run();
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
		ExecuterAction.quickRun( /*Util.trim( GLOBAL.defaultOption.toDString )*/ );
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

	int encode_cb( Ihandle *ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			//if( !ScintillaAction.saveFile( cSci ) ) return IUP_DEFAULT;
			
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
			
			scope 	_fp = new FilePath( cSci.getFullPath );
			char[]	fp = _fp.name();
			if( fp.length >= 7 )
			{
				if( fp[0..7] == "NONAME#" )
				{
					actionManager.StatusBarAction.update();
					return IUP_DEFAULT;
				}
			}

			ScintillaAction.saveFile( cSci, true );
			actionManager.StatusBarAction.update();
		}
		return IUP_DEFAULT;
	}
	
	int SetAndConvertEOL_CB( Ihandle *ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			int type;
			switch( fromStringz( IupGetAttribute( ih, "TITLE" ) ) )
			{
				case "Windows":	type = 0; break;
				case "Mac":		type = 1; break;
				case "Unix":	type = 2; break;
				default:		return IUP_DEFAULT;
			}
				
			IupScintillaSendMessage( cSci.getIupScintilla, 2029, type, 0 ); // SCI_CONVERTEOLS 2029
			//IupScintillaSendMessage( cSci.getIupScintilla, 2031, type, 0 ); // SCI_SETEOLMODE 2031
			//actionManager.StatusBarAction.update();
		}
		
		return IUP_DEFAULT;
	}
	
	// Also import by customDlg.d
	int customtool_menu_click_cb( Ihandle* ih )
	{
		char[] title = fromStringz( IupGetAttribute( ih, "TITLE" ) );

		for( int i = 0; i < GLOBAL.customTools.length - 1; ++ i )
		{
			if( GLOBAL.customTools[i].name.toDString.length )
			{
				if( GLOBAL.customTools[i].name.toDString == title )
				{
					if( GLOBAL.customTools[i].dir.toDString.length )
					{
						CustomToolAction.run( GLOBAL.customTools[i] );
						break;
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}
}