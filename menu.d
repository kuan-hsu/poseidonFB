module menu;

private import iup.iup, iup.iup_scintilla;

private import global, actionManager, scintilla, project, tools, layout;
private import parser.autocompletion;
private import dialogs.singleTextDlg, dialogs.prjPropertyDlg, dialogs.preferenceDlg, dialogs.fileDlg, dialogs.customDlg, dialogs.manualDlg, layouts.customMenu;
private import parser.scanner,  parser.token, parser.parser, parser.ast;
private import std.string, std.conv, std.file, std.encoding, Path = std.path, Array = std.array, Uni = std.uni, std.algorithm;
private import core.memory;

Ihandle* createMenu()
{
	// For Menu
	Ihandle* menu;
	Ihandle* item_new, item_save, item_saveAll, item_exportJson, item_open, item_exit, file_menu;
	Ihandle* item_redo, item_undo, item_cut, item_copy, item_paste, item_selectAll, edit_menu;
	Ihandle* item_findReplace, item_findNext, item_findPrevious, item_findReplaceInFiles, item_goto, search_menu;
	Ihandle* view_menu;
	Ihandle* item_newProject, item_openProject, item_closeProject, item_saveProject, item_projectProperties, project_menu;
	Ihandle* item_compile, item_buildrun, item_run, item_build, item_buildAll, item_reBuild, item_clearBuild, item_quickRun, build_menu;
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
	
	item_exportJson = IupItem( "Export Json...", null );
	IupSetCallback( item_exportJson, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			string _fullPath = cSci.getFullPath();
			if( fullPathByOS( _fullPath ) in GLOBAL.parserManager )
			{
				auto _ast = GLOBAL.parserManager[fullPathByOS( _fullPath )];
				scope dlg = new CFileDlg( GLOBAL.languageItems["saveas"].toDString() ~ "...", "JSON" ~ "|*.json|" ~  GLOBAL.languageItems["allfile"].toDString() ~ "|*.*", "SAVE", "NO", Path.stripExtension( cSci.getFullPath ) );//"Source File|*.bas|Include File|*.bi" );
				_fullPath = tools.normalizeSlash( dlg.getFileName() );
				
				if( _fullPath.length )
				{
					if( _fullPath.length > 5 )
						if( _fullPath[$-5..$] == ".json" ) _fullPath = _fullPath[0..$-5].dup;

					_fullPath ~= ".json";
					FileAction.saveFile( _fullPath, GLOBAL.Parser.ast2Json( cast(CASTnode) _ast ), BOM.utf8, true );
				}
			}
		}
		return IUP_DEFAULT;
	});
	
 
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

	Ihandle* item_closeAllTabs = IupItem( GLOBAL.languageItems["closealltabs"].toCString, null );
	IupSetAttribute( item_closeAllTabs, "IMAGE", "icon_deleteall" );
	IupSetCallback( item_closeAllTabs, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( ScintillaAction.closeAllDocument( GLOBAL.documentTabs_Sub ) == IUP_DEFAULT ) ScintillaAction.closeAllDocument( GLOBAL.documentTabs );
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
	IupSetAttribute(_clearRecentPrjs, "IMAGE", "icon_deleteall");
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
	
	Ihandle* item_uncomment = IupItem( GLOBAL.languageItems["uncommentline"].toCString, null);
	IupSetAttribute(item_uncomment, "IMAGE", "icon_uncomment");
	IupSetCallback( item_uncomment, "ACTION", cast(Icallback) &uncomment_cb );
	

	// Search
	item_findReplace = IupItem( GLOBAL.languageItems["findreplace"].toCString, null );
	IupSetAttribute(item_findReplace, "IMAGE", "icon_search");
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
	IupSetAttribute(item_goto, "IMAGE", "icon_shift_l");
	IupSetCallback( item_goto, "ACTION", cast(Icallback) &item_goto_cb );


	// View
	Ihandle* LineMargin = IupItem( GLOBAL.languageItems["lnmargin"].toCString, null);
	if( GLOBAL.editorSetting00.LineMargin == "ON" ) IupSetAttribute( LineMargin, "VALUE", "ON" ); else IupSetAttribute( LineMargin, "VALUE", "OFF" );
	IupSetAttribute( LineMargin, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuLineMargin", LineMargin );
	IupSetCallback( LineMargin, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.LineMargin == "ON" ) GLOBAL.editorSetting00.LineMargin = "OFF"; else GLOBAL.editorSetting00.LineMargin = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleLineMargin" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE", toStringz( GLOBAL.editorSetting00.LineMargin ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* BookmarkMargin = IupItem( GLOBAL.languageItems["bkmargin"].toCString, null);
	if( GLOBAL.editorSetting00.BookmarkMargin == "ON" ) IupSetAttribute( BookmarkMargin, "VALUE", "ON" ); else IupSetAttribute( BookmarkMargin, "VALUE", "OFF" );
	IupSetAttribute( BookmarkMargin, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuBookmarkMargin", BookmarkMargin );
	IupSetCallback( BookmarkMargin, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.BookmarkMargin == "ON" ) GLOBAL.editorSetting00.BookmarkMargin = "OFF"; else GLOBAL.editorSetting00.BookmarkMargin = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleBookmarkMargin" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE", toStringz( GLOBAL.editorSetting00.BookmarkMargin ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	
	
	Ihandle* FoldMargin = IupItem( GLOBAL.languageItems["fdmargin"].toCString, null);
	if( GLOBAL.editorSetting00.FoldMargin == "ON" ) IupSetAttribute( FoldMargin, "VALUE", "ON" ); else IupSetAttribute( FoldMargin, "VALUE", "OFF" );
	IupSetAttribute( FoldMargin, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuFoldMargin", FoldMargin );
	IupSetCallback( FoldMargin, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.FoldMargin == "ON" ) GLOBAL.editorSetting00.FoldMargin = "OFF"; else GLOBAL.editorSetting00.FoldMargin = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleFoldMargin" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE", toStringz( GLOBAL.editorSetting00.FoldMargin ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	
	
	Ihandle* IndentGuide = IupItem( GLOBAL.languageItems["indentguide"].toCString, null);
	if( GLOBAL.editorSetting00.IndentGuide == "ON" ) IupSetAttribute( IndentGuide, "VALUE", "ON" ); else IupSetAttribute( IndentGuide, "VALUE", "OFF" );
	IupSetAttribute( IndentGuide, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuIndentGuide", IndentGuide );
	IupSetCallback( IndentGuide, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.IndentGuide == "ON" ) GLOBAL.editorSetting00.IndentGuide = "OFF"; else GLOBAL.editorSetting00.IndentGuide = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleIndentGuide" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleIndentGuide" ), "VALUE", toStringz( GLOBAL.editorSetting00.IndentGuide ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* ShowEOL = IupItem( GLOBAL.languageItems["showeol"].toCString, null);
	if( GLOBAL.editorSetting00.ShowEOL == "ON" ) IupSetAttribute( ShowEOL, "VALUE", "ON" ); else IupSetAttribute( ShowEOL, "VALUE", "OFF" );
	IupSetAttribute( ShowEOL, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuShowEOL", ShowEOL );
	IupSetCallback( ShowEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.ShowEOL == "ON" ) GLOBAL.editorSetting00.ShowEOL = "OFF"; else GLOBAL.editorSetting00.ShowEOL = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleShowEOL" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleShowEOL" ), "VALUE", toStringz( GLOBAL.editorSetting00.ShowEOL ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});
	
	Ihandle* ShowSpace = IupItem( GLOBAL.languageItems["showspacetab"].toCString, null);
	if( GLOBAL.editorSetting00.ShowSpace == "ON" ) IupSetAttribute( ShowSpace, "VALUE", "ON" ); else IupSetAttribute( ShowSpace, "VALUE", "OFF" );
	IupSetAttribute( ShowSpace, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuShowSpace", ShowSpace );
	IupSetCallback( ShowSpace, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.ShowSpace == "ON" ) GLOBAL.editorSetting00.ShowSpace = "OFF"; else GLOBAL.editorSetting00.ShowSpace = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleShowSpace" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleShowSpace" ), "VALUE", toStringz( GLOBAL.editorSetting00.ShowSpace ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});		
	
	Ihandle* BraceMatch = IupItem( GLOBAL.languageItems["bracematchhighlight"].toCString, null);
	if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" ) IupSetAttribute( BraceMatch, "VALUE", "ON" ); else IupSetAttribute( BraceMatch, "VALUE", "OFF" );
	IupSetAttribute( BraceMatch, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuBraceMatch", BraceMatch );
	IupSetCallback( BraceMatch, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" ) GLOBAL.editorSetting00.BraceMatchHighlight = "OFF"; else GLOBAL.editorSetting00.BraceMatchHighlight = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleBraceMatch" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleBraceMatch" ), "VALUE", toStringz( GLOBAL.editorSetting00.BraceMatchHighlight ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	
	
	Ihandle* BoldKeyword = IupItem( GLOBAL.languageItems["boldkeyword"].toCString, null);
	if( GLOBAL.editorSetting00.BoldKeyword == "ON" ) IupSetAttribute( BoldKeyword, "VALUE", "ON" ); else IupSetAttribute( BoldKeyword, "VALUE", "OFF" );
	IupSetAttribute( BoldKeyword, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuBoldKeyword", BoldKeyword );
	IupSetCallback( BoldKeyword, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.BoldKeyword == "ON" ) GLOBAL.editorSetting00.BoldKeyword = "OFF"; else GLOBAL.editorSetting00.BoldKeyword = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleBoldKeyword" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleBoldKeyword" ), "VALUE", toStringz( GLOBAL.editorSetting00.BoldKeyword ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* CaretLine = IupItem( GLOBAL.languageItems["showcaretline"].toCString, null);
	if( GLOBAL.editorSetting00.CaretLine == "ON" ) IupSetAttribute( CaretLine, "VALUE", "ON" ); else IupSetAttribute( CaretLine, "VALUE", "OFF" );
	IupSetAttribute( CaretLine, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuCaretLine", CaretLine );
	IupSetCallback( CaretLine, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.CaretLine == "ON" ) GLOBAL.editorSetting00.CaretLine = "OFF"; else GLOBAL.editorSetting00.CaretLine = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleCaretLine" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE", toStringz( GLOBAL.editorSetting00.CaretLine ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});	

	Ihandle* HighlightCurrentWord = IupItem( GLOBAL.languageItems["hlcurrentword"].toCString, null);
	if( GLOBAL.editorSetting00.HighlightCurrentWord == "ON" ) IupSetAttribute( HighlightCurrentWord, "VALUE", "ON" ); else IupSetAttribute( HighlightCurrentWord, "VALUE", "OFF" );
	IupSetAttribute( HighlightCurrentWord, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuHighlightCurrentWord", HighlightCurrentWord );
	IupSetCallback( HighlightCurrentWord, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.HighlightCurrentWord == "ON" ) GLOBAL.editorSetting00.HighlightCurrentWord = "OFF"; else GLOBAL.editorSetting00.HighlightCurrentWord = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleCurrentWord" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleCurrentWord" ), "VALUE", toStringz( GLOBAL.editorSetting00.HighlightCurrentWord ) );
			
		ScintillaAction.applyAllSetting();
		return IUP_DEFAULT;
	});
	
	Ihandle* FunctionTitle = IupItem( GLOBAL.languageItems["showtitle"].toCString, null );
	if( GLOBAL.showFunctionTitle == "ON" ) IupSetAttribute( FunctionTitle, "VALUE", "ON" ); else IupSetAttribute( FunctionTitle, "VALUE", "OFF" );
	IupSetAttribute( FunctionTitle, "AUTOTOGGLE", "YES" );
	IupSetAttribute( FunctionTitle, "NAME", "function_title" );
	IupSetHandle( "menuFunctionTitle", FunctionTitle );	
	IupSetCallback( FunctionTitle, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.showFunctionTitle == "ON" ) GLOBAL.showFunctionTitle = "OFF"; else GLOBAL.showFunctionTitle = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleFunctionTitle" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleFunctionTitle" ), "VALUE", toStringz( GLOBAL.showFunctionTitle ) );

		if( GLOBAL.showFunctionTitle == "ON" )
		{
			IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "YES" );
			IupRefresh( GLOBAL.toolbar.getListHandle() );
		}
		else
			IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "NO" );
		
		
		
		return IUP_DEFAULT;
	});

	Ihandle* UseAnnotation = IupItem( GLOBAL.languageItems["errorannotation"].toCString, null);
	if( GLOBAL.compilerSettings.useAnootation == "ON" ) IupSetInt( UseAnnotation, "VALUE", 1 ); else IupSetInt( UseAnnotation, "VALUE", 0 );
	IupSetAttribute( UseAnnotation, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuUseAnnotation", UseAnnotation );
	IupSetCallback( UseAnnotation, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.compilerSettings.useAnootation == "ON" ) GLOBAL.compilerSettings.useAnootation = "OFF"; else GLOBAL.compilerSettings.useAnootation = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleAnnotation" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE", toStringz( GLOBAL.compilerSettings.useAnootation ) );
			
		return IUP_DEFAULT;
	});
	
	Ihandle* UseConsoleApp = IupItem( GLOBAL.languageItems["consoleexe"].toCString, null);
	if( GLOBAL.compilerSettings.useConsoleLaunch == "ON" ) IupSetInt( UseConsoleApp, "VALUE", 1 ); else IupSetInt( UseConsoleApp, "VALUE", 0 );
	IupSetAttribute( UseConsoleApp, "AUTOTOGGLE", "YES" );
	IupSetHandle( "menuUseConsoleApp", UseConsoleApp );
	IupSetCallback( UseConsoleApp, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.compilerSettings.useConsoleLaunch == "ON" ) GLOBAL.compilerSettings.useConsoleLaunch = "OFF"; else GLOBAL.compilerSettings.useConsoleLaunch = "ON";
		if( GLOBAL.preferenceDlg !is null )
			if( IupGetHandle( "toggleConsoleExe" ) != null ) IupSetStrAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE", toStringz( GLOBAL.compilerSettings.useConsoleLaunch ) );
			
		return IUP_DEFAULT;
	});

	
	// Project
	item_newProject= IupItem( GLOBAL.languageItems["newprj"].toCString, null);
	IupSetAttribute(item_newProject, "IMAGE", "icon_packageexplorer");
	IupSetCallback(item_newProject, "ACTION", cast(Icallback)&newProject_cb);

	item_openProject = IupItem( GLOBAL.languageItems["openprj"].toCString, null);
	IupSetAttribute(item_openProject, "IMAGE", "icon_openprj");
	IupSetCallback(item_openProject, "ACTION", cast(Icallback)&openProject_cb);

	/*
	version(FBIDE)
	{
		Ihandle* item_import = IupItem( GLOBAL.languageItems["importprj"].toCString, null);
		IupSetAttribute(item_import, "IMAGE", "icon_importprj");
		IupSetCallback(item_import, "ACTION", cast(Icallback)&importProject_cb);
	}
	*/
	
	item_closeProject = IupItem( GLOBAL.languageItems["closeprj"].toCString, null);
	IupSetAttribute(item_closeProject, "IMAGE", "icon_delete");
	IupSetCallback(item_closeProject, "ACTION", cast(Icallback)&closeProject_cb);

	Ihandle* item_closeAllProject = IupItem( GLOBAL.languageItems["closeallprj"].toCString, null);
	IupSetAttribute(item_closeAllProject, "IMAGE", "icon_deleteall");
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
	
	item_quickRun = IupItem( GLOBAL.languageItems["quickrun"].toCString, null);
	IupSetAttribute( item_quickRun, "IMAGE", "icon_quickrun" );
	IupSetCallback( item_quickRun, "ACTION", cast(Icallback)&quickRun_cb );	

	// Debug
	bool bWithoutDebug;
	version(DIDE)
	{
		version(Windows) bWithoutDebug = true;
	}
	
	if( !bWithoutDebug )
	{
		item_runDebug = IupItem( GLOBAL.languageItems["rundebug"].toCString, null);
		IupSetAttribute(item_runDebug, "IMAGE", "icon_debugrun");
		IupSetCallback( item_runDebug, "ACTION", cast(Icallback)&runDebug_cb );

		item_withDebug = IupItem( GLOBAL.languageItems["compiledebug"].toCString, null);
		IupSetAttribute(item_withDebug, "IMAGE", "icon_debugbuild");
		IupSetCallback( item_withDebug, "ACTION", cast(Icallback)&compileWithDebug_cb );
		
		item_BuildwithDebug = IupItem( GLOBAL.languageItems["builddebug"].toCString, null);
		IupSetAttribute(item_BuildwithDebug, "IMAGE", "icon_debugbuild");
		IupSetCallback( item_BuildwithDebug, "ACTION", cast(Icallback)&buildAllWithDebug_cb );
	}
	
	item_buildAll = IupItem( GLOBAL.languageItems["buildprj"].toCString, null);
	IupSetAttribute(item_buildAll, "IMAGE", "icon_build");
	IupSetCallback( item_buildAll, "ACTION", cast(Icallback)&buildAll_cb );
	
	item_reBuild = IupItem( GLOBAL.languageItems["rebuildprj"].toCString, null);
	IupSetAttribute( item_reBuild, "IMAGE", "icon_rebuild" );
	IupSetCallback( item_reBuild, "ACTION", cast(Icallback)&reBuild_cb );

	item_clearBuild = IupItem( GLOBAL.languageItems["clearall"].toCString, null);
	IupSetAttribute( item_clearBuild, "IMAGE", "icon_clear" );
	IupSetCallback( item_clearBuild, "ACTION", cast(Icallback)&clearBuild_cb );

	// Miscelaneous
	Ihandle* toolBarItem = IupItem( GLOBAL.languageItems["toolbar"].toCString, null);
	IupSetAttribute( toolBarItem, "VALUE", "ON" );
	IupSetCallback( toolBarItem, "ACTION",  cast(Icallback)&toolbarMenuItem_cb);
	
	GLOBAL.menuOutlineWindow = IupItem( GLOBAL.languageItems["outline"].toCString, null);
	IupSetAttribute(GLOBAL.menuOutlineWindow, "VALUE", "ON");
	IupSetCallback(GLOBAL.menuOutlineWindow, "ACTION", cast(Icallback)&outlineMenuItem_cb);
	
	GLOBAL.menuMessageWindow = IupItem( GLOBAL.languageItems["message"].toCString, null);
	IupSetAttribute(GLOBAL.menuMessageWindow, "VALUE", "ON");
	IupSetCallback(GLOBAL.menuMessageWindow, "ACTION", cast(Icallback)&messageMenuItem_cb);
	
	GLOBAL.menuRotateTabs = IupItem( GLOBAL.languageItems["rotatetabs"].toCString, null);
	IupSetAttribute( GLOBAL.menuRotateTabs, "VALUE", toStringz( GLOBAL.editorSetting01.RotateTabs ) );
	IupSetCallback( GLOBAL.menuRotateTabs, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		if( fromStringz( IupGetAttribute( GLOBAL.menuRotateTabs, "VALUE" ) ) == "OFF" )
		{
			Ihandle* child = IupGetNextChild( GLOBAL.documentSplit, GLOBAL.dndDocumentZBox );
			if( child != null )
			{
				IupReparent( GLOBAL.documentTabs_Sub, GLOBAL.documentSplit2, null );
				IupRefresh( GLOBAL.documentSplit2 );
				if( IupGetChildCount( child ) > 0 )
				{
					IupSetInt( GLOBAL.documentSplit2, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
					IupSetInt( GLOBAL.documentSplit2, "VALUE", GLOBAL.documentSplit2_value );
					IupSetAttributes( GLOBAL.documentSplit, "VALUE=1000,BARSIZE=0" );
				}
			}
			GLOBAL.editorSetting01.RotateTabs = "ON";
			IupSetAttribute( GLOBAL.menuRotateTabs, "VALUE", "ON" );
		}
		else
		{
			Ihandle* child = IupGetNextChild( GLOBAL.documentSplit2, GLOBAL.documentSplit );
			if( child != null )
			{
				IupReparent( GLOBAL.documentTabs_Sub, GLOBAL.documentSplit, null );
				IupRefresh( GLOBAL.documentSplit );
				if( IupGetChildCount( child ) > 0 )
				{
					IupSetInt( GLOBAL.documentSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
					IupSetInt( GLOBAL.documentSplit, "VALUE", GLOBAL.documentSplit_value );
					IupSetAttributes( GLOBAL.documentSplit2, "VALUE=1000,BARSIZE=0" );
				}
			}
			GLOBAL.editorSetting01.RotateTabs = "OFF";
			IupSetAttribute( GLOBAL.menuRotateTabs, "VALUE", "OFF" );
		}
		
		return IUP_DEFAULT;
	});
	
	Ihandle* fullScreenItem = IupItem( GLOBAL.languageItems["fullscreen"].toCString, null);
	IupSetStrAttribute( fullScreenItem, "VALUE", toStringz( GLOBAL.editorSetting01.USEFULLSCREEN ) );
	IupSetAttribute( fullScreenItem, "IMAGE", "icon_fullscreen" );
	IupSetCallback( fullScreenItem, "ACTION", cast(Icallback) &fullscreenMenuItem_cb);
	

	// Option
	Ihandle* _windowsEOL = IupItem( "Windows", null );
	IupSetCallback( _windowsEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "0";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 0, 0 ); // SCI_SETEOLMODE	= 2031

		StatusBarAction.update();
		return IUP_DEFAULT;
	});	
	
	Ihandle* _macEOL = IupItem( "Mac", null );
	IupSetCallback( _macEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		GLOBAL.editorSetting00.EolType = "1";
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 1, 0 ); // SCI_SETEOLMODE	= 2031
		
		StatusBarAction.update();
		return IUP_DEFAULT;
	});	
	
	Ihandle* _unixEOL = IupItem( "Unix", null );
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

	Ihandle* windowsEOL = IupItem( "Windows", null );
	IupSetCallback( windowsEOL, "ACTION", cast(Icallback) &SetAndConvertEOL_CB );
	
	Ihandle* macEOL = IupItem( "Mac", null );
	IupSetCallback( macEOL, "ACTION", cast(Icallback) &SetAndConvertEOL_CB );
	
	Ihandle* unixEOL = IupItem( "Unix", null );
	IupSetCallback( unixEOL, "ACTION", cast(Icallback) &SetAndConvertEOL_CB );

	Ihandle* eolSubMenu = IupMenu( windowsEOL, macEOL, unixEOL, null  );
	Ihandle* convertEOL = IupSubmenu( GLOBAL.languageItems["converteol"].toCString, eolSubMenu );
	

	Ihandle* encodeDefault = IupItem( "Default", null );
	IupSetCallback( encodeDefault, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeUTF8 = IupItem( "UTF8", null );
	IupSetCallback( encodeUTF8, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeUTF8BOM = IupItem( "UTF8.BOM", null );
	IupSetCallback( encodeUTF8BOM, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeUTF16BEBOM = IupItem( "UTF16BE.BOM", null );
	IupSetCallback( encodeUTF16BEBOM, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeUTF16LEBOM = IupItem( "UTF16LE.BOM", null );
	IupSetCallback( encodeUTF16LEBOM, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeUTF32LEBOM = IupItem( "UTF32LE.BOM", null );
	IupSetCallback( encodeUTF32LEBOM, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeUTF32BEBOM = IupItem( "UTF32BE.BOM", null );
	IupSetCallback( encodeUTF32BEBOM, "ACTION", cast(Icallback) &encode_cb );
	
	Ihandle* encodeSubMenu = IupMenu( encodeDefault, encodeUTF8, encodeUTF8BOM, encodeUTF16LEBOM, encodeUTF16BEBOM, encodeUTF32LEBOM, encodeUTF32BEBOM, null  );
	Ihandle* convertEncoding = IupSubmenu( GLOBAL.languageItems["convertencoding"].toCString, encodeSubMenu );

	version(FBIDE)
	{
		// Convert Keyword
		Ihandle* upperCaseHandle = IupItem( GLOBAL.languageItems["uppercase"].toCString, null );
		IupSetCallback( upperCaseHandle, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			_convertKeyWordCase( 2 );
			return IUP_DEFAULT;
		});	
		
		Ihandle* lowerCaseHandle = IupItem( GLOBAL.languageItems["lowercase"].toCString, null );
		IupSetCallback( lowerCaseHandle, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			_convertKeyWordCase( 1 );
			return IUP_DEFAULT;
		});	
		
		Ihandle* mixedCase = IupItem( GLOBAL.languageItems["mixercase"].toCString, null );
		IupSetCallback( mixedCase, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			_convertKeyWordCase( 3 );
			return IUP_DEFAULT;
		});	

		Ihandle* userCase = IupItem( GLOBAL.languageItems["usercase"].toCString, null );
		IupSetCallback( userCase, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			_convertKeyWordCase( 4 );
			return IUP_DEFAULT;
		});
		
		Ihandle* caseSubMenu = IupMenu( upperCaseHandle, lowerCaseHandle, mixedCase, userCase, null  );
		Ihandle* convertCase = IupSubmenu( GLOBAL.languageItems["convertcase"].toCString, caseSubMenu );
	}
	
	Ihandle* customTooledit = IupItem( GLOBAL.languageItems["setcustomtool"].toCString, null );
	IupSetAttribute( customTooledit, "IMAGE", "icon_toolitem" );
	IupSetCallback( customTooledit, "ACTION", cast(Icallback)&coustomTooledit_cb );
	
	/*
	Ihandle* markIupSeparator = IupSeparator();
	IupSetAttribute( markIupSeparator, "TITLE", "" );
	*/
	
	version(FBIDE) Ihandle* toolsSubMenu = IupMenu( setEOL, convertEOL, convertEncoding, convertCase, IupSeparator(), customTooledit, /*markIupSeparator,*/ null  );
	version(DIDE) Ihandle* toolsSubMenu = IupMenu( setEOL, convertEOL, convertEncoding, IupSeparator(), customTooledit, /*markIupSeparator,*/ null  );
		
	IupSetHandle( "toolsSubMenu", toolsSubMenu );
	
	item_tool = IupSubmenu( GLOBAL.languageItems["tools"].toCString, toolsSubMenu );
	IupSetAttribute(item_tool, "IMAGE", "icon_tools");

	for( int i = 0; i < GLOBAL.customTools.length - 1; ++ i )
	{
		if( GLOBAL.customTools[i].name.length )
		{
			Ihandle* _new = IupItem( toStringz( "#" ~ to!(string)( i ) ~ ". " ~ GLOBAL.customTools[i].name ), null );
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
	auto _language = new IupString( GLOBAL.language );
	if( GLOBAL.language.length ) _lng = IupItem( _language.toCString, null ); else  _lng = IupItem( GLOBAL.languageItems["default"].toCString, null );
	IupInsert( languageSubMenu, null, _lng );
	IupMap( _lng );
	IupSetHandle( "_lng", _lng );
	
	IupRefresh( languageSubMenu );
	
	item_language = IupSubmenu( GLOBAL.languageItems["language"].toCString, languageSubMenu );
	
	Ihandle* item_about = IupItem( GLOBAL.languageItems["about"].toCString, null );
	IupSetAttribute(item_about, "IMAGE", "icon_information");
	IupSetCallback( item_about, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		bool _64bit;
		string	C = "DMD";
		version(X86_64) _64bit = true;
		version(LDC) C = "LDC";
		version(GDC) C = "GDC";
		version(FBIDE)	IupMessage( GLOBAL.languageItems["about"].toCString, toStringz( "FreeBasic IDE" ~ (  _64bit ? " (x64)" : " (x86)" ) ~ "_" ~ C ~ "\nPoseidonFB(V0.518)  2023.08.02\nBy Kuan Hsu (Taiwan)\nhttps://bitbucket.org/KuanHsu/poseidonfb\n\nlibreoffice-style-sifr ICONs\nBy Rizal Muttaqin\nhttps://github.com/rizmut/libreoffice-style-sifr\n" ~ ( GLOBAL.linuxHome.length ? "\nAppImage" : "" ) ) );
		version(DIDE)	IupMessage( GLOBAL.languageItems["about"].toCString, toStringz( "D Programming IDE" ~ (  _64bit ? " (x64)" : " (x86)" ) ~ "_" ~ C ~ "\nPoseidonD(V0.089)  2023.08.02\nBy Kuan Hsu (Taiwan)\nhttps://bitbucket.org/KuanHsu/poseidonfb\n\nlibreoffice-style-sifr ICONs\nBy Rizal Muttaqin\nhttps://github.com/rizmut/libreoffice-style-sifr\n" ~ ( GLOBAL.linuxHome.length ? "\nAppImage" : "" ) ) );
		return IUP_DEFAULT;
	});
	
	Ihandle* item_manual = IupItem( GLOBAL.languageItems["manual"].toCString, null );
	IupSetAttribute( item_manual, "IMAGE", "icon_fbmanual" );
	IupSetCallback( item_manual, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		scope dlg = new CManualDialog( 480, -1, GLOBAL.languageItems["manual"].toDString(), false );
		dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );		
		
		return IUP_DEFAULT;
	});	
	
	

	file_menu = IupMenu( 	item_new, 
							item_open, 
							IupSeparator(),
							item_save,
							item_saveAs,
							item_saveAll,
							IupSeparator(),
							item_exportJson,
							IupSeparator(),
							item_close,
							item_closeAllTabs,
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
							item_uncomment,
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
							IupSeparator(),
							FunctionTitle,
							IupSeparator(),
							UseAnnotation,
							UseConsoleApp,
							null );
	
	version(FBIDE)
	{
	project_menu = IupMenu( item_newProject,
							item_openProject,
							IupSeparator(),
							/*item_import,*/
							/*IupSeparator(),*/
							item_saveProject,
							item_saveAllProject,
							IupSeparator(),
							item_closeProject,
							item_closeAllProject,
							IupSeparator(),
							item_projectProperties,
							null );
	}
	version(DIDE)
	{
	project_menu = IupMenu( item_newProject,
							item_openProject,
							IupSeparator(),
							item_saveProject,
							item_saveAllProject,
							IupSeparator(),
							item_closeProject,
							item_closeAllProject,
							IupSeparator(),
							item_projectProperties,
							null );
	}


	build_menu= IupMenu( 	item_compile,
							item_buildrun,
							IupSeparator(),
							item_run,
							item_buildAll,
							item_reBuild,
							item_clearBuild,
							IupSeparator(),
							//item_clean,
							//IupSeparator(),
							item_quickRun,
							null );

	if( !bWithoutDebug )
	{							
	debug_menu= IupMenu( 	item_runDebug,
							item_withDebug,
							item_BuildwithDebug,
							null );
	}
	
	misc_menu= IupMenu( 	toolBarItem,
							GLOBAL.menuOutlineWindow,
							GLOBAL.menuMessageWindow,
							GLOBAL.menuRotateTabs,
							IupSeparator(),
							fullScreenItem,
							null );

	option_menu= IupMenu( 	item_tool,
							item_language,
							item_preference,
							IupSeparator(),
							item_about,
							IupSeparator(),
							item_manual,
							/*IupSeparator(),*/
							null );


	IupSetHandle( "optionsMenu", option_menu );

	for( int i = 0; i < GLOBAL.manuals.length; ++ i )
	{
		string[] splitWords = Array.split( GLOBAL.manuals[i], "," );
		if( splitWords.length == 2 )
		{
			auto _name = new IupString( "#" ~ to!(string)( i + 1 ) ~ ". " ~ splitWords[0] );
			Ihandle* _new = IupItem( _name.toCString, null );
			IupSetCallback( _new, "ACTION", cast(Icallback) &manual_menu_click_cb );
			IupAppend( option_menu, _new );
			IupMap( _new );
		}
	}	

	version(Windows)
	{
		GLOBAL.menubar = new CCustomMenubar( 120 );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["file"].toDString, file_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["edit"].toDString, edit_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["search"].toDString, search_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["view"].toDString, view_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["prj"].toDString, project_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["build"].toDString, build_menu );
		if( !bWithoutDebug ) GLOBAL.menubar.addItem( GLOBAL.languageItems["debug"].toDString, debug_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["windows"].toDString, misc_menu );
		GLOBAL.menubar.addItem( GLOBAL.languageItems["options"].toDString, option_menu );
		GLOBAL.menubar.setFont( GLOBAL.fonts[0].fontString );

		return GLOBAL.menubar.getLayoutHandle;	
	}
	else
	{
		mainMenu1_File = IupSubmenu( GLOBAL.languageItems["file"].toCString, file_menu );
		mainMenu2_Edit = IupSubmenu( GLOBAL.languageItems["edit"].toCString, edit_menu );
		mainMenu3_Search = IupSubmenu( GLOBAL.languageItems["search"].toCString, search_menu );
		mainMenu4_View = IupSubmenu( GLOBAL.languageItems["view"].toCString, view_menu );
		mainMenu5_Project = IupSubmenu( GLOBAL.languageItems["prj"].toCString, project_menu );
		mainMenu6_Build = IupSubmenu( GLOBAL.languageItems["build"].toCString, build_menu );
		if( !bWithoutDebug ) mainMenu7_Debug = IupSubmenu( GLOBAL.languageItems["debug"].toCString, debug_menu );
		mainMenu_Misc = IupSubmenu( GLOBAL.languageItems["windows"].toCString, misc_menu );
		mainMenu8_Option = IupSubmenu( GLOBAL.languageItems["options"].toCString, option_menu );	
	
		if( !bWithoutDebug )
			menu = IupMenu( mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Debug, mainMenu_Misc, mainMenu8_Option, null );
		else
			menu = IupMenu( mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu_Misc, mainMenu8_Option, null );
			
		IupSetAttribute( menu, "GAP", "30" );
		IupSetHandle("mymenu", menu);
	}

	return null;
}

version(FBIDE)
{
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
			IupScintillaSendMessage( iupSci, 2198, 2, 0 );						// SCI_SETSEARCHFLAGS = 2198,
			
			foreach(  _s; GLOBAL.KEYWORDS )
			{
				foreach( targetText; Array.split( _s, " " ) )
				{
					if( targetText.length )
					{
						int		replaceTextLength = cast(int) targetText.length;
						string	replaceText = tools.convertKeyWordCase( type, targetText );

						IupSetInt( iupSci, "TARGETSTART", 0 );
						IupSetInt( iupSci, "TARGETEND", -1 );
						
						scope _t = new IupString( targetText );

						int posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
						while( posHead >= 0 )
						{
							IupSetAttribute( iupSci, "REPLACETARGET", toStringz( replaceText ) );
							IupSetInt( iupSci, "TARGETSTART", posHead + replaceTextLength );
							IupSetInt( iupSci, "TARGETEND", -1 );
							posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
						}					
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
		
		foreach( s; GLOBAL.scintillaManager.keys )
		{
			// NONAME#....bas
			if( s.length >= 7 )
			{
				if( s[0..7] == fullPathByOS( "NONAME#" ) )
				{
					version(FBIDE)	existedID ~= to!(int)( s[7..$-4] );
					version(DIDE)	existedID ~= to!(int)( s[7..$-2] );
				}
			}
		}

		existedID.sort;

		string noname;
		if( !existedID.length )
		{
			version(FBIDE)	noname = "NONAME#0.bas";
			version(DIDE)	noname = "NONAME#0.d";
		}
		else
		{
			for( int i = 0; i < existedID.length; ++ i )
			{
				if( i < existedID[i] )
				{
					version(FBIDE)	noname = "NONAME#" ~ to!(string)( i ) ~ ".bas";
					version(DIDE)	noname = "NONAME#" ~ to!(string)( i ) ~ ".d";
					break;
				}
			}
		}

		if( !noname.length )
		{
			version(FBIDE)	noname = "NONAME#" ~ to!(string)( existedID.length ) ~ ".bas";
			version(DIDE)	noname = "NONAME#" ~ to!(string)( existedID.length ) ~ ".d";
		}

		version(Windows)
		{
			if( GLOBAL.editorSetting00.NewDocBOM == "ON" ) actionManager.ScintillaAction.newFile( noname, BOM.utf8, true, null, false ); else actionManager.ScintillaAction.newFile( noname, BOM.utf8, false, null, false );
		}
		else
			actionManager.ScintillaAction.newFile( noname, BOM.utf8, false, null, false );

		return IUP_DEFAULT;
	}

	
	int openFile_cb( Ihandle* ih )
	{
		version(FBIDE)	scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString() ~ "...", GLOBAL.languageItems["supportfile"].toDString() ~ "|*.bas;*.bi|" ~ GLOBAL.languageItems["basfile"].toDString() ~ "|*.bas|" ~  GLOBAL.languageItems["bifile"].toDString() ~ "|*.bi|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*", "OPEN", "YES" );
		version(DIDE)	scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString() ~ "...", GLOBAL.languageItems["supportfile"].toDString() ~ "|*.d;*.di|" ~ GLOBAL.languageItems["basfile"].toDString() ~ "|*.d|" ~  GLOBAL.languageItems["bifile"].toDString() ~ "|*.di|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*", "OPEN", "YES" );
		
		string[] files = fileSecectDlg.getFilesName();
		if( files.length == 1 )
		{
			if( files[0].length )
			{
				if( ScintillaAction.openFile( files[0], -1 ) ) actionManager.ScintillaAction.updateRecentFiles( files[0] );
			}
		}
		else
		{
			foreach( s; files )
			{
				if( s.length )
				{
					if( ScintillaAction.openFile( s ) )	actionManager.ScintillaAction.updateRecentFiles( s );
				}
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

	int saveTabs_cb( Ihandle* ih )
	{
		actionManager.ScintillaAction.saveTabs();
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
		IupSetAttribute( dlg, "EXTFILTER", toStringz( GLOBAL.languageItems["lngfile"].toDString() ~ "|*.lng|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*" ) );
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );
		
		if( IupGetInt( dlg, "STATUS") == 0 )
		{
			string fileString = strip( fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup );
			if( std.file.exists( fileString ) )
			{
				Ihandle* _ih = IupGetHandle( "_lng" );
				if( _ih != null )
				{
					IupSetStrAttribute( _ih, "TITLE", toStringz( Path.stripExtension( Path.baseName( fileString ) ) ) );
					GLOBAL.language = Path.stripExtension( Path.baseName( fileString ) );
					
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
		string title = fromStringz( IupGetAttribute( ih, "TITLE" ) ).dup;
		if( title.length )
		{
			if( !ScintillaAction.openFile( title, -1 ) )
			{
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
				IupSetStrAttribute( messageDlg, "VALUE", toStringz( "\"" ~ title ~ "\"\n" ~ GLOBAL.languageItems["filelost"].toDString ) );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
				IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );			
				
				IupDestroy( ih );
				
				IupString[] _recentFiles;
				foreach( s; GLOBAL.recentFiles )
					if( s.toDString != title ) _recentFiles ~= new IupString( s.toDString );
					
				foreach( s; GLOBAL.recentFiles )
					destroy( s );					
				
				GLOBAL.recentFiles.length = 0;
				GLOBAL.recentFiles = _recentFiles;
			}
			else
				actionManager.ScintillaAction.updateRecentFiles( title );
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
		string title = fromStringz( IupGetAttribute( ih, "TITLE" ) ).dup;
		auto pos = indexOf( title, " : " );
		if( pos > 0 )
		{
			if( !GLOBAL.projectTree.openProject( strip( title[0..pos].dup ) ) )
			{
				IupDestroy( ih );
				IupString[] _recentProjects;
				
				foreach( s; GLOBAL.recentProjects )
				{
					if( s.toDString != title ) _recentProjects ~= new IupString( s.toDString );
				}
				
				foreach( s; GLOBAL.recentProjects )
					destroy( s );
				
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
				AutoComplete.bSkipAutoComplete = true;
				IupSetAttribute( ih, "UNDO", "YES" );
			}
			IupSetFocus( ih );
		}
	}

	void redo_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			if( fromStringz(IupGetAttribute( ih, "REDO" )) == "YES" )
			{
				AutoComplete.bSkipAutoComplete = true;
				IupSetAttribute( ih, "REDO", "YES" );
			}
			IupSetFocus( ih );
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
	
	int comment_cb( Ihandle* ih )
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
				string currentLineText = fSTRz( IupGetAttribute( iupSci, "LINEVALUE" ) );
				if( currentLineText.length )
				{
					version(FBIDE)
					{
						lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
						IupSetAttributeId( iupSci, "INSERT", lineheadPos, "'" );
					}
					version(DIDE)
					{
						lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
						IupSetAttributeId( iupSci, "INSERT", lineheadPos, "//" );
					}
				}
			}
			else
			{
				string selectText = fSTRz( _selectText );
				auto headCommaPos = indexOf( selectText, "," );
				auto headColonPos = indexOf( selectText, ":" );
				auto tailCommaPos = lastIndexOf( selectText, "," );
				if( tailCommaPos > headCommaPos )
				{
					int line1 = to!(int)( selectText[0..headCommaPos] );
					int line2 = to!(int)( selectText[headColonPos+1..tailCommaPos] );
					
					if( line1 > line2 )
					{
						int temp = line1;
						line1 = line2;
						line2 = temp;
					}
					
					for( int i = line1; i <= line2; ++ i )
					{
						string currentLineText = strip( fromStringz( IupGetAttributeId( iupSci, "LINE", i ) ) ).dup;
						if( currentLineText.length )
						{
							version(FBIDE)
							{
								lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, i, 0 );
								IupSetAttributeId( iupSci, "INSERT", lineheadPos, "'" );
							}
							version(DIDE)
							{
								lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, i, 0 );
								IupSetAttributeId( iupSci, "INSERT", lineheadPos, "//" );
							}
						}					
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}

	int uncomment_cb( Ihandle* ih )
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
				string currentLineText = fromStringz( IupGetAttribute( iupSci, "LINEVALUE" ) ).dup;
				if( currentLineText.length )
				{
					version(FBIDE)
					{
						//SCI_POSITIONFROMLINE   2167
						if( currentLineText[0] == '\'' )
						{
							lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
							IupSetStrAttribute( iupSci, "DELETERANGE", toStringz( to!(string)( lineheadPos ) ~ "," ~ "1" ) );
						}
					}
					version(DIDE)
					{
						if( currentLineText.length > 1 )
						{
							if( currentLineText[0..2] == "//" )
							{
								lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, currentLine - 1, 0 );
								IupSetStrAttribute( iupSci, "DELETERANGE", toStringz( to!(string)( lineheadPos ) ~ "," ~ "2" ) );
							}
						}
					}
				}
			}
			else
			{
				string selectText = fSTRz( _selectText );
				auto headCommaPos = indexOf( selectText, "," );
				auto headColonPos = indexOf( selectText, ":" );
				auto tailCommaPos = lastIndexOf( selectText, "," );
				if( tailCommaPos > headCommaPos )
				{
					int line1 = to!(int)( selectText[0..headCommaPos] );
					int line2 = to!(int)( selectText[headColonPos+1..tailCommaPos] );
					
					if( line1 > line2 )
					{
						int temp = line1;
						line1 = line2;
						line2 = temp;
					}
					
					for( int i = line1; i <= line2; ++ i )
					{
						string currentLineText = fromStringz( IupGetAttributeId( iupSci, "LINE", i ) ).dup;
						if( currentLineText.length )
						{
							version(FBIDE)
							{
								//SCI_POSITIONFROMLINE   2167
								if( currentLineText[0] == '\'' )
								{
									lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, i, 0 );
									IupSetStrAttribute( iupSci, "DELETERANGE", toStringz( to!(string)( lineheadPos ) ~ "," ~ "1" ) );
								}
							}						
							version(DIDE)
							{
								if( currentLineText.length > 1 )
								{
									if( currentLineText[0..2] == "//" )
									{
										lineheadPos = cast(int) IupScintillaSendMessage( iupSci, 2167, i, 0 );
										IupSetStrAttribute( iupSci, "DELETERANGE", toStringz( to!(string)( lineheadPos ) ~ "," ~ "2" ) );
									}
								}
							}						
						}					
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}
	
	int findReplace_cb( Ihandle* _iHandle )
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			string targetText = fSTRz( IupGetAttribute( ih, toStringz( "SELECTEDTEXT" ) ) );		
			if( targetText.length ) GLOBAL.searchExpander.show( targetText.dup ); else GLOBAL.searchExpander.show( null );
		}
		
		return IUP_DEFAULT;
	}

	int findReplaceInFiles( Ihandle* _iHandle )
	{
		if( GLOBAL.serachInFilesDlg !is null )
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih !is null ) 
			{
				string targetText = fSTRz( IupGetAttribute( ih, toStringz( "SELECTEDTEXT" ) ) );
				if( targetText.length) GLOBAL.serachInFilesDlg.show( targetText.dup ); else GLOBAL.serachInFilesDlg.show( null );
			}
			else
			{
				GLOBAL.serachInFilesDlg.show( null );
			}
		}
		return IUP_DEFAULT;
	}

	
	/*
    SCFIND_WHOLEWORD = 2,
    SCFIND_MATCHCASE = 4,
    SCFIND_WORDSTART = 0x00100000,
    SCFIND_REGEXP = 0x00200000,
    SCFIND_POSIX = 0x00400000,
	*/
	int findNext_cb( Ihandle* _iHandle )
	{
		Ihandle* ih	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			string targetText = fSTRz( IupGetAttribute( ih, "SELECTEDTEXT" ) );
			if( targetText.length )
			{
				IupSetAttribute( ih, "SELECTIONPOS", IupGetAttribute( ih, "SELECTIONPOS" ) );
				actionManager.SearchAction.search( ih, targetText, GLOBAL.searchExpander.searchRule, true );
			}
		}
		return IUP_DEFAULT;
	}

	int findPrev_cb( Ihandle* _iHandle )
	{
		Ihandle* ih	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			string targetText = fSTRz(IupGetAttribute( ih, "SELECTEDTEXT" ));
			if( targetText.length )
			{
				char[] beginEndPos = fromStringz( IupGetAttribute( ih, "SELECTIONPOS" ) );
				if( beginEndPos.length )
				{
					auto colonPos = indexOf( beginEndPos, ":" );
					if( colonPos > -1 )
					{
						string newBeginEndPos = ( beginEndPos[colonPos+1..$] ~ ":" ~ beginEndPos[0..colonPos] ).dup;
						IupSetStrAttribute( ih, "SELECTIONPOS", toStringz( newBeginEndPos.dup ) );
						actionManager.SearchAction.search( ih, targetText, GLOBAL.searchExpander.searchRule, false );
					}
				}
			}
		}
		return IUP_DEFAULT;
	}

	int item_goto_cb( Ihandle* _iHandle )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			// Open Dialog Window
			scope gotoLineDlg = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["sc_goto"].toDString() ~ "...", GLOBAL.languageItems["line"].toDString() ~ ":", null, null, false, "POSEIDON_MAIN_DIALOG", "icon_shift_l", false );
			IupSetStrAttribute( gotoLineDlg.getIhandle, "OPACITY", toStringz( GLOBAL.editorSetting02.gotoDlg ) );
			string lineNum = gotoLineDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
			
			lineNum = strip( lineNum );
			if( lineNum.length)
			{
				auto pos = lastIndexOf( lineNum, "x" );
				if( pos == -1 )	pos = lastIndexOf( lineNum, ":" );
				if( pos > 0 )
				{
					try
					{
						int left = to!(int)( strip( lineNum[0..pos] ) );
						int right = to!(int)( strip( lineNum[pos+1..$] ) );
						
						
						string LineCol = to!(string)( left - 1 )  ~ "," ~ to!(string)( right - 1 );
						IupScintillaSendMessage( cSci.getIupScintilla, 2234, left - 1, 0 );	// SCI_ENSUREVISIBLEENFORCEPOLICY 2234
						IupSetStrAttribute( cSci.getIupScintilla, "CARET", toStringz( LineCol ) );
						actionManager.StatusBarAction.update();
						IupSetFocus( cSci.getIupScintilla );
					}
					catch( Exception e )
					{
					}
					return IUP_DEFAULT;
				}
				else
				{
					try
					{
						if( lineNum[0] == '-' )
						{
							int value = to!(int)( lineNum[1..$] );
							value --;
							IupScintillaSendMessage( cSci.getIupScintilla, 2234, ScintillaAction.getLinefromPos( cSci.getIupScintilla, value ), 0 );	// SCI_ENSUREVISIBLEENFORCEPOLICY 2234
							IupSetInt( cSci.getIupScintilla, "CARETPOS", value );
							actionManager.StatusBarAction.update();
							IupSetFocus( cSci.getIupScintilla );
							return IUP_DEFAULT;
						}
					}
					catch( Exception e )
					{
						return IUP_DEFAULT;
					}
				}
				
				GLOBAL.navigation.addCache( cSci.getFullPath, to!(int)( lineNum ) );
				actionManager.ScintillaAction.gotoLine( cSci.getFullPath, to!(int)( lineNum ) );
				actionManager.StatusBarAction.update();
				
				return IUP_DEFAULT;
			}
		}
		return IUP_DEFAULT;
	}

	int toolbarMenuItem_cb( Ihandle *ih )
	{
		Ihandle* _expandHandle = IupGetDialogChild( GLOBAL.mainDlg, "POSEIDON_TOOLBAR_EXPANDER" );
		if( _expandHandle != null )
		{
			if( fromStringz( IupGetAttribute( _expandHandle, "STATE" ) ) == "OPEN" )
			{
				IupSetAttribute( _expandHandle, "STATE", "CLOSE" );
				Ihandle* _backgroundbox = IupGetChild( _expandHandle, 1 ); // Get toolbar Ihandle
				if( _backgroundbox != null ) IupSetAttributes( _backgroundbox, "VISIBLE=NO,ACTIVE=NO" ); // Make toolbar to hide
				IupSetInt( ih, "VALUE", 0 );
			}
			else
			{
				IupSetAttribute( _expandHandle, "STATE", "OPEN" );
				Ihandle* _backgroundbox = IupGetChild( _expandHandle, 1 );
				if( _backgroundbox != null ) IupSetAttributes( _backgroundbox, "VISIBLE=YES,ACTIVE=YES" ); // Make toolbar to show
				IupSetInt( ih, "VALUE", 1 );
			}
		}
		return IUP_DEFAULT;
	
	}
	
	int outlineMenuItem_cb( Ihandle *ih )
	{
		return outline_cb( ih );
	}

	int outline_cb( Ihandle *ih )
	{
		if( IupGetInt( ih, "VALUE" ) == 1 )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			GLOBAL.explorerSplit_value = IupGetInt( GLOBAL.explorerSplit, "VALUE" );
			IupSetInt( GLOBAL.explorerSplit, "VALUE", 0 );
			//IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 0 );

			IupSetAttribute( GLOBAL.explorerSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* SecondChild = IupGetChild( GLOBAL.explorerSplit, 1 );
			IupSetAttribute( SecondChild, "ACTIVE", "YES" );			
			Ihandle* thirdChild = IupGetChild( GLOBAL.explorerSplit, 2 );
			IupSetAttribute( thirdChild, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			IupSetInt( GLOBAL.explorerSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
			IupSetInt( GLOBAL.explorerSplit, "VALUE", GLOBAL.explorerSplit_value );
			IupSetAttribute( GLOBAL.explorerSplit, "ACTIVE", "YES" );
		}

		Ihandle* _activeDocument = ScintillaAction.getActiveIupScintilla();
		if( _activeDocument != null ) IupSetFocus( _activeDocument ); else IupSetFocus( GLOBAL.mainDlg );
		
		return IUP_DEFAULT;
	}
	
	int fullscreenMenuItem_cb( Ihandle *ih )
	{
		if( GLOBAL.editorSetting01.USEFULLSCREEN == "ON" )
		{
			GLOBAL.editorSetting01.USEFULLSCREEN = "OFF";
			IupSetAttribute( GLOBAL.mainDlg, "FULLSCREEN", "NO" );
			version(FBIDE)
				IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
			else
				IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonD - D Programming Language IDE" );
		}
		else
		{
			GLOBAL.editorSetting01.USEFULLSCREEN = "ON";
			IupSetAttribute( GLOBAL.mainDlg, "FULLSCREEN", "YES" );
		}
		
		return IUP_DEFAULT;
	}
	
	int messageMenuItem_cb( Ihandle *ih )
	{
		return message_cb( ih );
	}
	
	int message_cb( Ihandle *ih )
	{
		if( IupGetInt( ih, "VALUE" ) == 1 )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			
			GLOBAL.messageSplit_value = IupGetInt( GLOBAL.messageSplit, "VALUE" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", 1000 );

			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* SecondChild = IupGetChild( GLOBAL.messageSplit, 1 );
			IupSetAttribute( SecondChild, "ACTIVE", "YES" );
			Ihandle* thirdChild = IupGetChild( GLOBAL.messageSplit, 2 );
			IupSetAttribute( thirdChild, "ACTIVE", "YES" );
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
			scope dlg = new CCustomDialog( 480, -1, GLOBAL.languageItems["setcustomtool"].toDString(), false );
			dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
		}
		else
		{
			scope dlg = new CCustomDialog( 492, -1, GLOBAL.languageItems["setcustomtool"].toDString(), false );
			dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
		}
		

		return IUP_DEFAULT;
	}

	int preference_cb( Ihandle *ih )
	{
		if( GLOBAL.preferenceDlg is null )
		{
			GLOBAL.preferenceDlg = new CPreferenceDialog( -1, -1, GLOBAL.languageItems["caption_preference"].toDString(), false, "POSEIDON_MAIN_DIALOG" );
			version(Windows) GLOBAL.preferenceDlg.show( IUP_RIGHTPARENT, IUP_TOPPARENT ); else GLOBAL.preferenceDlg.show( IUP_CENTER, IUP_CENTER );
		}
		else
		{
			IupShow( GLOBAL.preferenceDlg.getIhandle );
			/+
			destroy( GLOBAL.preferenceDlg );
			GC.free( cast(void*) GLOBAL.preferenceDlg );
			GLOBAL.preferenceDlg = null;
			GLOBAL.preferenceDlg = new CPreferenceDialog( -1, -1, GLOBAL.languageItems["caption_preference"].toDString(), false, "POSEIDON_MAIN_DIALOG" );
			+/
		}
		

		return IUP_DEFAULT;
	}

	int newProject_cb( Ihandle *ih )
	{
		scope dlg = new CProjectPropertiesDialog( -1, -1, GLOBAL.languageItems["caption_prjproperties"].toDString(), false, true );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int openProject_cb( Ihandle *ih )
	{
		GLOBAL.projectTree.openProject( null, true );
		return IUP_DEFAULT;
	}

	/*
	version(FBIDE)
	{
		int importProject_cb( Ihandle *ih )
		{
			GLOBAL.projectTree.importFbEditProject();
			return IUP_DEFAULT;
		}
	}
	*/
	
	int closeProject_cb( Ihandle* ih )
	{
		GLOBAL.projectTree.closeProject();
		return IUP_DEFAULT;
	}

	int closeAllProject_cb( Ihandle* ih )
	{
		GLOBAL.projectTree.closeAllProjects();
		return IUP_DEFAULT;
	}	

	int saveProject_cb( Ihandle *ih )
	{
		string activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( activePrjName.length )
		{
			GLOBAL.projectManager[activePrjName].saveFile();
		}

		return IUP_DEFAULT;
	}

	int saveAllProject_cb( Ihandle *ih )
	{
		foreach( PROJECT p; GLOBAL.projectManager )
			p.saveFile();
		
		return IUP_DEFAULT;
	}

	int projectProperties_cb( Ihandle *ih )
	{
		if( !actionManager.ProjectAction.getActiveProjectName.length ) return IUP_DEFAULT;

		scope dlg = new CProjectPropertiesDialog( -1, -1, GLOBAL.languageItems["caption_prjproperties"].toDString(), false, false );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int compile_cb( Ihandle *ih )
	{
		ExecuterAction.compile();
		return IUP_DEFAULT;
	}

	int buildrun_cb( Ihandle *ih )
	{
		ExecuterAction.compile( null, null, null, null, true );
		return IUP_DEFAULT;
	}	

	int buildAll_cb( Ihandle *ih )
	{
		ExecuterAction.build();
		return IUP_DEFAULT;
	}
	
	int reBuild_cb( Ihandle *ih )
	{
		ExecuterAction.buildAll();
		return IUP_DEFAULT;
	}
	
	int clearBuild_cb( Ihandle *ih )
	{
		GLOBAL.messagePanel.printOutputPanel( "Clean All Objs & Target In Project......", true );
		
		string activePrjName = actionManager.ProjectAction.getActiveProjectName();
		if( activePrjName.length )
		{
			if( activePrjName in GLOBAL.projectManager )
			{
				foreach( s; GLOBAL.projectManager[activePrjName].sources )
				{
					version(FBIDE)
					{
						auto oPath = Path.stripExtension( s ) ~ ".o";
						if( std.file.exists( oPath ) ) std.file.remove( oPath );
					}
					else
					{
						version(Windows)
						{
							auto oPath = Path.stripExtension( s ) ~ ".obj";
							if( std.file.exists( oPath ) ) std.file.remove( oPath );
							
							oPath = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ Path.stripExtension( Path.baseName( s ) ) ~ ".obj";
							if( std.file.exists( oPath ) ) std.file.remove( oPath );
						}
						else
						{
							auto oPath = Path.stripExtension( s ) ~ ".o";
							if( std.file.exists( oPath ) ) std.file.remove( oPath );
							
							oPath = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ Path.stripExtension( Path.baseName( s ) ) ~ ".o";
							if( std.file.exists( oPath ) ) std.file.remove( oPath );
						}
					}
				}
				
				version(DIDE)
				{
					version(Windows)
					{
						auto oPath = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ Path.stripExtension( GLOBAL.projectManager[activePrjName].targetName ) ~ ".obj";
						if( std.file.exists( oPath ) ) std.file.remove( oPath );
					}
					else
					{
						auto oPath = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ Path.stripExtension( GLOBAL.projectManager[activePrjName].targetName ) ~ ".o";
						if( std.file.exists( oPath ) ) std.file.remove( oPath );
					}

					string activeCompilerOption = GLOBAL.projectManager[activePrjName].compilerOption;
					if( GLOBAL.projectManager[activePrjName].focusOn.length )
						if( GLOBAL.projectManager[activePrjName].focusOn in GLOBAL.projectManager[activePrjName].focusUnit ) activeCompilerOption = GLOBAL.projectManager[activePrjName].focusUnit[GLOBAL.projectManager[activePrjName].focusOn].Option;
					
					auto odPos = indexOf( GLOBAL.projectManager[activePrjName].compilerOption, "-od" );
					if( odPos > -1 )
					{
						auto odTail = indexOf( GLOBAL.projectManager[activePrjName].compilerOption, " ", odPos + 3 );
						if( odTail == -1 ) odTail = indexOf( GLOBAL.projectManager[activePrjName].compilerOption, "\t", odPos + 3 );
						if( odTail > odPos + 3 )
						{
							string pathName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].compilerOption[odPos+3..odTail];
							if( std.file.exists( pathName ) )
								if( std.file.isDir( pathName ) )
								{
									foreach( string filename; dirEntries( pathName, "*.{obj,o}", SpanMode.depth) )
										std.file.remove( filename );
									//std.file.rmdirRecurse( pathName ); 
								}
						}
					}
				}
				
				string executeName;
				string _targetName = GLOBAL.projectManager[activePrjName].targetName;
				if( GLOBAL.projectManager[activePrjName].focusOn.length )
				{
					if( GLOBAL.projectManager[activePrjName].focusOn in GLOBAL.projectManager[activePrjName].focusUnit ) _targetName = GLOBAL.projectManager[activePrjName].focusUnit[GLOBAL.projectManager[activePrjName].focusOn].Target;
				}
				if( !_targetName.length ) _targetName = Path.stripExtension( GLOBAL.projectManager[activePrjName].name );
				version(Windows)
				{
					switch( GLOBAL.projectManager[activePrjName].type )
					{
						case "2":
							executeName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a";
							break;
						case "3":
							executeName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".dll";
							break;
						default:
							executeName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".exe";
					}
				}
				else
				{
					switch( GLOBAL.projectManager[activePrjName].type )
					{
						case "2":
							executeName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a";
							break;
						case "3":
							executeName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".so";
							break;
						default:
							executeName = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName;
					}
				}				
				
				if( std.file.exists( executeName ) ) std.file.remove( executeName );

				GLOBAL.messagePanel.printOutputPanel( "Done." );
			}
		}
		else
		{
			GLOBAL.messagePanel.printOutputPanel( "No Project has been selected......?" );
		}		
		
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
			switch( fromStringz( IupGetAttribute( ih, "TITLE" ) ) )
			{
				case "Default"		: cSci.setEncoding( BOM.none ); 								break;
				case "UTF8"			: cSci.setEncoding( BOM.utf8 ); 		cSci.withBOM = false;	break;
				case "UTF8.BOM"		: cSci.setEncoding( BOM.utf8 );			cSci.withBOM = true;	break;
				case "UTF16LE.BOM"	: cSci.setEncoding( BOM.utf16le );		cSci.withBOM = true;	break;
				case "UTF16BE.BOM"	: cSci.setEncoding( BOM.utf16be ); 		cSci.withBOM = true;	break;
				case "UTF32LE.BOM"	: cSci.setEncoding( BOM.utf32le ); 		cSci.withBOM = true;	break;
				case "UTF32BE.BOM"	: cSci.setEncoding( BOM.utf32be ); 		cSci.withBOM = true;	break;
				default: return IUP_DEFAULT;
			}
			
			string _baseName = Path.baseName( cSci.getFullPath );
			if( _baseName.length >= 7 )
			{
				if( _baseName[0..7] == "NONAME#" )
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
		string title = fSTRz( IupGetAttribute( ih, "TITLE" ) );
		auto dotPos = indexOf( title, ". " );
		if( dotPos > -1 && dotPos < title.length ) title = title[dotPos+2..$].dup;

		for( int i = 0; i < GLOBAL.customTools.length - 1; ++ i )
		{
			if( GLOBAL.customTools[i].name.length )
			{
				if( GLOBAL.customTools[i].name == title )
				{
					if( GLOBAL.customTools[i].dir.length )
					{
						CustomToolAction.run( GLOBAL.customTools[i] );
						break;
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}
	
	int manual_menu_click_cb( Ihandle* ih )
	{
		string title = fSTRz( IupGetAttribute( ih, "TITLE" ) );
		auto dotPos = indexOf( title, ". " );
		if( dotPos > -1 && dotPos < title.length - 2 ) title = title[dotPos+2..$].dup;

		for( int i = 0; i < GLOBAL.manuals.length; ++ i )
		{
			string[] splitWords = Array.split( GLOBAL.manuals[i], "," );
			if( splitWords.length == 2 )
			{
				if( title == splitWords[0] )
				{
					if( std.file.exists( splitWords[1] ) )
					{
						if( Uni.toLower( Path.extension( splitWords[1] ) ) == ".chm" )
						{
							version(Windows) 
								IupExecute( toStringz( splitWords[1] ), "" );
							else
							{
								string htmlappPath = Path.baseName( GLOBAL.linuxHtmlAppName );
								switch( htmlappPath )
								{
									case "xchm":
										IupExecute( toStringz( GLOBAL.linuxHtmlAppName ), toStringz( "\"" ~ splitWords[1] ~ "\"" ) );	// xchm "file:/home/username/freebasic/FB-manual-1.05.0.chm#xchm:/KeyPg%s.html"
										break;
									case "kchmviewer":
									case "CHMVIEW":
										IupExecute( toStringz( GLOBAL.linuxHtmlAppName ), toStringz( splitWords[1] ) );
										break;
									default:
										IupExecute( "./CHMVIEW", toStringz( splitWords[1] ) );
								}							
							}
						}
					}
					break;
				}
			}
		}
		
		return IUP_DEFAULT;
	}
}