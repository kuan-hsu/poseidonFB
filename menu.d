module menu;

import iup.iup;
import iup.iupcontrols;
import iup.iup_scintilla;

import global, actionManager, scintilla, project;
import dialogs.singleTextDlg, dialogs.prjPropertyDlg, dialogs.preferenceDlg, dialogs.fileDlg;

import tango.io.Stdout;
import tango.stdc.stringz;
import Integer = tango.text.convert.Integer;
import Util = tango.text.Util;

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
	Ihandle* item_compile, item_run, item_build, item_buildAll, item_clean, item_quickRun, build_menu;
	Ihandle* item_tool, item_preference, option_menu;
	

	Ihandle* mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Option;

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
	IupSetHandle( "recentFilesMenu", recentFilesSubMenu );

	//Ihandle*[] submenuItem;
	for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
	{
		Ihandle* _new = IupItem( toStringz(GLOBAL.recentProjects[i]), null );
		IupSetCallback( _new, "ACTION", cast(Icallback)&submenu_click_cb );
		IupInsert( recentFilesSubMenu, null, _new );
		IupMap( _new );
	}
	IupRefresh( recentFilesSubMenu );	
	
	Ihandle* item_recent = IupSubmenu( "Recent Projects", recentFilesSubMenu );

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

	// Search
	item_findReplace = IupItem( "Find / Replace", null );
	IupSetAttribute( item_findReplace, "KEY", "F" );
	IupSetCallback( item_findReplace, "ACTION", cast(Icallback) &findReplace_cb );

	item_findNext = IupItem( "Find Next", null );
	IupSetAttribute( item_findNext, "KEY", "N" );
	IupSetCallback( item_findNext, "ACTION", cast(Icallback) &findNext_cb );

	item_findPrevious = IupItem( "Find Previous", null );
	IupSetAttribute( item_findPrevious, "KEY", "P" );
	IupSetCallback( item_findPrevious, "ACTION", cast(Icallback) &findPrev_cb );
	
	item_findReplaceInFiles = IupItem ("Find / Replace In Files", null);
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
	//IupSetAttribute(item_undo, "IMAGE", "IUP_EditUndo");
	IupSetAttribute(GLOBAL.menuMessageWindow, "VALUE", "ON");
	//IupSetHandle( "menuMessageWindow", GLOBAL.menuMessageWindow );
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

	item_closeProject = IupItem ("Close Project", null);
	IupSetAttribute(item_closeProject, "KEY", "C");
	IupSetCallback(item_closeProject, "ACTION", cast(Icallback)&closeProject_cb);

	Ihandle* item_closeAllProject = IupItem ("Close All Project", null);
	IupSetAttribute(item_closeAllProject, "KEY", "j");
	IupSetCallback(item_closeAllProject, "ACTION", cast(Icallback)&closeAllProject_cb);
	
	item_saveProject = IupItem ("Save Project", null);
	IupSetAttribute(item_saveProject, "KEY", "M");
	IupSetCallback(item_saveProject, "ACTION", cast(Icallback)&saveProject_cb);

	Ihandle* item_saveAllProject = IupItem ("Save All Project", null);
	IupSetAttribute(item_saveAllProject, "KEY", "M");
	IupSetCallback(item_saveAllProject, "ACTION", cast(Icallback)&saveAllProject_cb);

	item_projectProperties = IupItem("Properties...", null);
	IupSetAttribute(item_projectProperties, "KEY", "P");
	IupSetCallback(item_projectProperties, "ACTION", cast(Icallback)&projectProperties_cb);

	// Build
	item_compile= IupItem( "Compile File", null );
	IupSetAttribute( item_compile, "KEY", "N" );
	IupSetAttribute(item_compile, "IMAGE", "icon_compile");
	IupSetCallback( item_compile, "ACTION", cast(Icallback)&compile_cb );

	item_run = IupItem ("Run", null);
	IupSetAttribute(item_run, "KEY", "O");
	IupSetAttribute(item_run, "IMAGE", "icon_run");
	IupSetCallback( item_run, "ACTION", cast(Icallback)&run_cb );

	/*
	item_build = IupItem ("Build", null);
	IupSetAttribute(item_build, "KEY", "C");
	*/

	item_buildAll = IupItem ("Build All", null);
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
	item_tool= IupItem ("Tools", null);
	IupSetAttribute(item_tool, "KEY", "T");
	IupSetCallback(item_tool, "ACTION", cast(Icallback)&tool_cb);
	

	item_preference = IupItem ("Preference", null);
	IupSetAttribute(item_preference, "KEY", "P");
	IupSetCallback(item_preference, "ACTION", cast(Icallback)&preference_cb);

	Ihandle* item_about = IupItem ("About", null);
	IupSetCallback( item_about, "ACTION", cast(Icallback) function( Ihandle* ih )
	{
		IupMessage( "About", "FreeBasic IDE\nPoseidonFB V0.101\nBy Kuan Hsu (Taiwan)\n2015.09.13" );
	});

	file_menu = IupMenu( 	item_new, 
							item_open, 
							IupSeparator(),
							item_save,
							item_saveAll,
							IupSeparator(),
							item_close,
							item_closeAll,
							IupSeparator(),
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
							item_saveProject,
							item_saveAllProject,
							IupSeparator(),
							item_closeProject,
							item_closeAllProject,
							IupSeparator(),
							item_projectProperties,
							null );							

	build_menu= IupMenu( 	item_compile,
							item_run,
							//item_build,
							item_buildAll,
							IupSeparator(),
							//item_clean,
							//IupSeparator(),
							item_quickRun,
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
	mainMenu7_Option = IupSubmenu( "Option", option_menu );
	IupSetAttribute( mainMenu7_Option, "KEY" ,"O" );	

	menu = IupMenu( mainMenu1_File, mainMenu2_Edit, mainMenu3_Search, mainMenu4_View, mainMenu5_Project, mainMenu6_Build, mainMenu7_Option, null );
	IupSetAttribute( menu, "GAP", "30" );
	
	IupSetHandle("mymenu", menu);
}


extern(C)
{
	int newFile_cb( Ihandle* ih )
	{
		scope dlg = new CFileDlg( "Create New File", "Source File|*.bas|Inculde File|*.bi|All Files|*.*", "SAVE" );//"Source File|*.bas|Include File|*.bi" );
		char[] fullPath = dlg.getFileName();

		if( fullPath.length )
		{
			actionManager.ScintillaAction.newFile( fullPath );
		}

		return IUP_DEFAULT;
	}

	
	int openFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( "Open File..." );
		char[] fileName = fileSecectDlg.getFileName();

		//Util.substitute( fileName, "\\", "/" );
		if( fileName.length )
		{
			//Stdout( fileName ).newline;
			ScintillaAction.openFile( fileName );
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
		auto cSci = ScintillaAction.getActiveCScintilla();
		if( cSci !is null )	ScintillaAction.saveFile( cSci.getIupScintilla() );
		
		return IUP_DEFAULT;
	}	

	int saveAllFile_cb( Ihandle* ih )
	{
		actionManager.ScintillaAction.saveAllFile();

		return IUP_DEFAULT;
	}

	int submenu_click_cb( Ihandle* ih )
	{
		char[] title = fromStringz( IupGetAttribute( ih, "TITLE" ) );
		int pos = Util.index( title, " : " );
		if( pos < title.length )
		{
			GLOBAL.projectTree.openProject( Util.trim( title[0..pos].dup ) );
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
			char[] targetText = fromStringz(IupGetAttribute( ih, "SELECTEDTEXT" ));
			 actionManager.SearchAction.findNext( ih, targetText, GLOBAL.searchDlg.searchRule );
		}
	}

	void findPrev_cb()
	{
		Ihandle* ih	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			char[] targetText = fromStringz(IupGetAttribute( ih, "SELECTEDTEXT" ));
			if( targetText.length ) actionManager.SearchAction.findPrev( ih, targetText, GLOBAL.searchDlg.searchRule );
		}
	}

	void item_goto_cb()
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			// Open Dialog Window
			scope gotoLineDlg = new CSingleTextDialog( 240, 120, "Goto Line...", "Line:", null, false );
			char[] lineNum = gotoLineDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
			
			if( lineNum.length) actionManager.ScintillaAction.gotoLine( cSci.getFullPath, Integer.atoi( lineNum )  );
		}
	}
	

	int outline_cb( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "ON" )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			GLOBAL.explorerSplit_value = IupGetAttribute( GLOBAL.explorerSplit, "VALUE" );
			IupSetAttribute( GLOBAL.explorerSplit, "VALUE", "0" );

			IupSetAttribute( GLOBAL.explorerSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* thirdChild = IupGetChild( GLOBAL.explorerSplit, 2 );
			IupSetAttribute( thirdChild, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			IupSetAttribute( GLOBAL.explorerSplit, "VALUE", GLOBAL.explorerSplit_value );
			IupSetAttribute( GLOBAL.explorerSplit, "ACTIVE", "YES" );
		}
		
		return IUP_DEFAULT;
	}

	int message_cb( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "ON" )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
			GLOBAL.messageSplit_value = IupGetAttribute( GLOBAL.messageSplit, "VALUE" );
			IupSetAttribute( GLOBAL.messageSplit, "VALUE", "1000" );

			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "NO" );
			// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
			Ihandle* SecondChild = IupGetChild( GLOBAL.messageSplit, 1 );
			IupSetAttribute( SecondChild, "ACTIVE", "YES" );

			IupSetAttribute( GLOBAL.outputPanel, "VISIBLE", "NO" );
			IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLE", "NO" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
			IupSetAttribute( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "YES" );
			IupSetAttribute( GLOBAL.outputPanel, "VISIBLE", "YES" );
			IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLE", "YES" );
			
		}
		
		return IUP_DEFAULT;
	}

	int tool_cb()
	{
		scope scanner = new CScanner;

		auto cSci = ScintillaAction.getActiveCScintilla();
		
		if( cSci !is null )
		{
			char[] document = cSci.getText();
			TokenUnit[] tokens = scanner.scan( document );

			scope _parser = new CParser( tokens );
			_parser.parse( cSci.getFullPath );
			
 		}		

		
		/+
		auto doc = new Document!(char);

		// attach an xml header
		doc.header;

		auto configNode = doc.tree.element( null, "config" );


		auto editorNode = configNode.element( null, "editor" );

		for( int i = 0; i < GLOBAL.KEYWORDS.length; ++i )
		{
			editorNode.element( null, "keywords" )
			.attribute( null, "id", Integer.toString( i ) ).attribute( null, "value", GLOBAL.KEYWORDS[i] );
		}
		
		editorNode.element( null, "toggle00" )
		.attribute( null, "LineMargin", GLOBAL.editorSetting00.LineMargin )
		.attribute( null, "BookmarkMargin", GLOBAL.editorSetting00.BookmarkMargin )
		.attribute( null, "FoldMargin", GLOBAL.editorSetting00.FoldMargin )
		.attribute( null, "IndentGuide", GLOBAL.editorSetting00.IndentGuide )
		.attribute( null, "CaretLine", GLOBAL.editorSetting00.CaretLine )
		.attribute( null, "WordWrap", GLOBAL.editorSetting00.WordWrap )
		.attribute( null, "TabUseingSpace", GLOBAL.editorSetting00.TabUseingSpace )
		.attribute( null, "AutoIndent", GLOBAL.editorSetting00.AutoIndent )	
		.attribute( null, "TabWidth", GLOBAL.editorSetting00.TabWidth );

		//<font name="Consolas" size="11" bold="OFF" italic="OFF" underline="OFF" forecolor="0 0 0" backcolor="255 255 255"></font>
		editorNode.element( null, "font" )
		.attribute( null, "name", GLOBAL.editFont.name )
		.attribute( null, "size", GLOBAL.editFont.size )
		.attribute( null, "bold", GLOBAL.editFont.bold )
		.attribute( null, "italic", GLOBAL.editFont.italic )
		.attribute( null, "underline", GLOBAL.editFont.underline )
		.attribute( null, "forecolor", GLOBAL.editFont.foreColor )
		.attribute( null, "backcolor", GLOBAL.editFont.backColor );

		//<color caretLine="255 255 0" cursor="0 0 0" selectionFore="255 255 255" selectionBack="0 0 255" linenumFore="0 0 0" linenumBack="200 200 200" fold="200 208 208"></color>
		editorNode.element( null, "color" )
		.attribute( null, "caretLine", GLOBAL.editColor.caretLine )
		.attribute( null, "cursor", GLOBAL.editColor.cursor )
		.attribute( null, "selectionFore", GLOBAL.editColor.selectionFore )
		.attribute( null, "selectionBack", GLOBAL.editColor.selectionBack )
		.attribute( null, "linenumFore", GLOBAL.editColor.linenumFore )
		.attribute( null, "linenumBack", GLOBAL.editColor.linenumBack )
		.attribute( null, "fold", GLOBAL.editColor.fold );

		/*
		<buildtools>
			<compilerpath>D:\CodingPark\FreeBASIC-1.02.1-win32\fbc.exe</compilerpath>
			<debuggerpath>D:\CodingPark\FreeBASIC-1.02.1-win32\bin\win32\gdb.exe</debuggerpath>
			<maxerror>30</maxerror>
		</buildtools>  
		*/
		auto buildtoolsNode = configNode.element( null, "buildtools" );
		buildtoolsNode.element( null, "compilerpath", GLOBAL.compilerFullPath );
		buildtoolsNode.element( null, "debuggerpath", GLOBAL.debuggerFullPath );
		buildtoolsNode.element( null, "maxerror", GLOBAL.maxError );
		
		

		auto print = new DocPrinter!(char);
		Stdout(print.print( doc )).newline;
		+/

		return IUP_DEFAULT;
	}

	

	int preference_cb( Ihandle *ih )
	{
		scope dlg = new CPreferenceDialog( 534, 460, "Preference", false );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int newProject_cb( Ihandle *ih )
	{
		scope dlg = new CProjectPropertiesDialog( 640, 414, "Project Properties", false, true );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int openProject_cb( Ihandle *ih )
	{
		GLOBAL.projectTree.openProject();
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
			GLOBAL.projectManager.remove( activePrjName );

			int countChild = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
			for( int i = 1; i <= countChild; ++ i )
			{
				int depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", i );
				if( depth == 1 )
				{
					if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", i )) == activePrjName )
					{
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", i, "SELECTED" );
						// Shadow
						IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "DELNODE", i, "SELECTED" );
						break;
					}
				}
			}
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
					/+
					foreach( char[] _s; prjsDir )
					{
						GLOBAL.projectManager.remove( _s );
						int countChild = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
						for( int i = 1; i < countChild; ++ i )
						{
							int depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", i );
							if( depth == 1 )
							{
								if( fromStringz(IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i )) == _s )
								{
									IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", i, "SELECTED" );
									break;
								}
							}
						}
					}
					+/
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
						char[] _cstring = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", i ) );
						if( _cstring == p.dir )
						{
							IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", i, "SELECTED" );
							// Shadow
							IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "DELNODE", i, "SELECTED" );

							break;
						}
					}
					catch( Exception e )
					{
						//IupMessage( "", toStringz( e.toString ) );
					}
				}
			}			
		}

		foreach( char[] s; prjsDir )
		{
			GLOBAL.projectManager.remove( s );
			//IupMessage("Remove",toStringz(s) );
		}

		//IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", 0, "CHILDREN" );

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
		
		scope dlg = new CProjectPropertiesDialog( 640, 414, "Project Properties", false, false );
		dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int compile_cb( Ihandle *ih )
	{
		ExecuterAction.compile();
		return IUP_DEFAULT;
	}

	int buildAll_cb( Ihandle *ih )
	{
		saveAllFile_cb( ih );
		ExecuterAction.buildAll();
		return IUP_DEFAULT;
	}

	int quickRun_cb( Ihandle *ih )
	{
		ExecuterAction.quickRun();
		return IUP_DEFAULT;
	}

	int run_cb( Ihandle *ih )
	{
		ExecuterAction.run();
		return IUP_DEFAULT;
	}
}