module layouts.toolbar;

private import iup.iup, iup.iup_scintilla;
private import global, actionManager, menu, executer, dialogs.argOptionDlg, tools;
private import std.string, Array = std.array;


class CToolBar
{
private:
	import 				iup.iup_scintilla;
	import 				menu, parser.ast, tools;
	
	Ihandle*			handle, listHandle, guiButton, bitButton;
	Ihandle* 			btnNew, btnOpen;
	Ihandle* 			btnSave, btnSaveAll;
	Ihandle* 			btnUndo, btnRedo, btnClearUndoBuffer;
	Ihandle* 			btnCut, btnCopy, btnPaste;
	Ihandle* 			btnBackNav, btnForwardNav, btnClearNav;
	Ihandle* 			btnMark, btnMarkPrev, btnMarkNext, btnMarkClean;
	Ihandle* 			btnCompile, btnBuildRun, btnRun, btnBuildAll, btnReBuild, btnQuickRun;
	Ihandle*[7]			labelSEPARATOR;

	void createToolBar()
	{
		btnNew				= IupButton( null, null );
		btnOpen				= IupButton( null, "Open" );

		btnSave				= IupButton( null, "Save" );
		btnSaveAll			= IupButton( null, "SaveAll" );	

		btnUndo				= IupButton( null, "Undo" );
		btnRedo				= IupButton( null, "Redo" );
		btnClearUndoBuffer	= IupButton( null, "Clear" );
		
		btnCut				= IupButton( null, "Cut" );
		btnCopy				= IupButton( null, "Copy" );
		btnPaste			= IupButton( null, "Paste" );

		btnBackNav			= IupButton( null, "Back" );
		btnForwardNav		= IupButton( null, "Forward" );
		btnClearNav			= IupButton( null, "Clear" );

		btnMark				= IupButton( null, "Mark" );
		btnMarkPrev			= IupButton( null, "MarkPrev" );
		btnMarkNext			= IupButton( null, "MarkNext" );
		btnMarkClean		= IupButton( null, "MarkClean" );
		
		btnCompile			= IupButton( null, "Compile" );
		btnBuildRun 		= IupButton( null, "BuildRun" );
		btnRun				= IupButton( null, "Run" );
		btnBuildAll			= IupButton( null, "BuildAll" );
		btnReBuild			= IupButton( null, "ReBuild" );
		btnQuickRun			= IupButton( null, "QuickRun" );


		IupSetAttributes( btnNew, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_newfile,NAME=POSEIDON_TOOLBAR_New" );
		IupSetStrAttribute( btnNew, "TIP", GLOBAL.languageItems["caption_new"].toCString );
		IupSetCallback( btnNew, "ACTION", cast(Icallback) &menu.newFile_cb ); // From menu.d
		
		IupSetAttributes( btnOpen, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_openfile,NAME=POSEIDON_TOOLBAR_Open" );
		IupSetStrAttribute( btnOpen, "TIP", GLOBAL.languageItems["caption_open"].toCString );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &menu.openFile_cb ); // From menu.d

		IupSetAttributes( btnSave, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_save,NAME=POSEIDON_TOOLBAR_Save" );
		IupSetStrAttribute( btnSave, "TIP", GLOBAL.languageItems["sc_save"].toCString );
		IupSetCallback( btnSave, "ACTION", cast(Icallback) &menu.saveFile_cb ); // From menu.d

		IupSetAttributes( btnSaveAll, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_saveall,NAME=POSEIDON_TOOLBAR_SaveAll" );
		IupSetStrAttribute( btnSaveAll, "TIP", GLOBAL.languageItems["sc_saveall"].toCString );
		IupSetCallback( btnSaveAll, "ACTION", cast(Icallback) &menu.saveAllFile_cb ); // From menu.d

		IupSetAttributes( btnUndo, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_undo,ACTIVE=NO,NAME=POSEIDON_TOOLBAR_Undo" );
		IupSetStrAttribute( btnUndo, "TIP", GLOBAL.languageItems["sc_undo"].toCString );
		IupSetCallback( btnUndo, "ACTION", cast(Icallback) &menu.undo_cb ); // From menu.d
		
		IupSetAttributes( btnRedo, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_redo,ACTIVE=NO,NAME=POSEIDON_TOOLBAR_Redo" );
		IupSetStrAttribute( btnRedo, "TIP", GLOBAL.languageItems["sc_redo"].toCString );
		IupSetCallback( btnRedo, "ACTION", cast(Icallback) &menu.redo_cb ); // From menu.d
		
		IupSetAttributes( btnClearUndoBuffer, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_clear,NAME=POSEIDON_TOOLBAR_ClearUndoBuffer" );
		IupSetStrAttribute( btnClearUndoBuffer, "TIP", GLOBAL.languageItems["clear"].toCString );
		IupSetCallback( btnClearUndoBuffer, "ACTION", cast(Icallback) function()
		{
			auto sci = ScintillaAction.getActiveIupScintilla;
			if( sci != null ) IupScintillaSendMessage( sci, 2175, 0, 0 ); // SCI_EMPTYUNDOBUFFER 2175
			
			Ihandle* _undo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Undo" );
			if( _undo != null ) IupSetAttribute( _undo, "ACTIVE", "NO" ); // SCI_CANUNDO 2174

			Ihandle* _redo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Redo" );
			if( _redo != null ) IupSetAttribute( _redo, "ACTIVE", "NO" ); // SCI_CANREDO 2016
			
			DocumentTabAction.setFocus( sci );
			return IUP_DEFAULT;
		});		
		

		IupSetAttributes( btnCut, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_cut,NAME=POSEIDON_TOOLBAR_Cut" );
		IupSetStrAttribute( btnCut, "TIP", GLOBAL.languageItems["caption_cut"].toCString );
		IupSetCallback( btnCut, "ACTION", cast(Icallback) &menu.cut_cb ); // From menu.d
		
		IupSetAttributes( btnCopy, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_copy,NAME=POSEIDON_TOOLBAR_Copy" );
		IupSetStrAttribute( btnCopy, "TIP", GLOBAL.languageItems["caption_copy"].toCString );
		IupSetCallback( btnCopy, "ACTION", cast(Icallback) &menu.copy_cb ); // From menu.d
		
		IupSetAttributes( btnPaste, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_paste,NAME=POSEIDON_TOOLBAR_Paste" );
		IupSetStrAttribute( btnPaste, "TIP", GLOBAL.languageItems["caption_paste"].toCString );
		IupSetCallback( btnPaste, "ACTION", cast(Icallback) &menu.paste_cb ); // From menu.d



		// Nav
		IupSetAttributes( btnBackNav, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_left,ACTIVE=NO,NAME=POSEIDON_TOOLBAR_BackwardNav" );
		IupSetStrAttribute( btnBackNav, "TIP", GLOBAL.languageItems["sc_backnav"].toCString );
		IupSetHandle( "toolbar_BackNav", btnBackNav );
		IupSetCallback( btnBackNav, "ACTION", cast(Icallback) function()
		{
			auto cacheUnit = GLOBAL.navigation.back();
			if( cacheUnit._line != -1 ) ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
			return IUP_DEFAULT;
		});		
		
		IupSetAttributes( btnForwardNav, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_right,ACTIVE=NO,NAME=POSEIDON_TOOLBAR_ForwardNav" );
		IupSetStrAttribute( btnForwardNav, "TIP", GLOBAL.languageItems["sc_forwardnav"].toCString );
		IupSetHandle( "toolbar_ForwardNav", btnForwardNav );
		IupSetCallback( btnForwardNav, "ACTION", cast(Icallback) function()
		{
			auto cacheUnit = GLOBAL.navigation.forward();
			if( cacheUnit._line != -1 ) ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
			return IUP_DEFAULT;
		});			
		
		IupSetAttributes( btnClearNav, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_clear,NAME=POSEIDON_TOOLBAR_ClearNav" );
		IupSetStrAttribute( btnClearNav, "TIP", GLOBAL.languageItems["clear"].toCString );
		IupSetHandle( "toolbar_ClearNav", btnClearNav );
		IupSetCallback( btnClearNav, "ACTION", cast(Icallback) function()
		{
			GLOBAL.navigation.clear();
			return IUP_DEFAULT;
		});


		IupSetAttributes( btnMark, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_mark,NAME=POSEIDON_TOOLBAR_Mark" );
		IupSetStrAttribute( btnMark, "TIP", GLOBAL.languageItems["bookmark"].toCString );
		IupSetCallback( btnMark, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null )
			{
				int currentPos			= cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
				int currentLine  		= cast(int) IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166
				
				if( IupGetIntId( ih, "MARKERGET", currentLine ) & 2 )
				{
					IupSetIntId( ih, "MARKERDELETE", currentLine, 1 );
				}
				else
				{
					IupSetIntId( ih, "MARKERADD", currentLine, 1 );
				}
			}
			return IUP_DEFAULT;
		});
		
		IupSetAttributes( btnMarkPrev, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markprev,NAME=POSEIDON_TOOLBAR_MarkPrev" );
		IupSetStrAttribute( btnMarkPrev, "TIP", GLOBAL.languageItems["bookmarkprev"].toCString );
		IupSetCallback( btnMarkPrev, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null )
			{
				int currentPos			= cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
				int currentLine  		= cast(int) IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

				IupSetIntId( ih, "MARKERPREVIOUS", --currentLine, 2 );
				
				int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

				if( markLineNumber < 0 )
				{
					int count = IupGetInt( ih, "LINECOUNT" );
					IupSetIntId( ih, "MARKERPREVIOUS", count, 2 );
					markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
					if( markLineNumber < 0 ) return IUP_DEFAULT;
				}			
				
				IupSetFocus( ih );
				if( markLineNumber > -1 )
				{
					IupSetAttributeId( ih, "ENSUREVISIBLE", markLineNumber, "ENFORCEPOLICY" );
					IupSetInt( ih, "CARET", markLineNumber );				
				}
				StatusBarAction.update();
			}
			
			return IUP_DEFAULT;
		});
		
		IupSetAttributes( btnMarkNext, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_marknext,NAME=POSEIDON_TOOLBAR_MarkNext" );
		IupSetStrAttribute( btnMarkNext, "TIP", GLOBAL.languageItems["bookmarknext"].toCString );
		IupSetCallback( btnMarkNext, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null )
			{
				int currentPos			= cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
				int currentLine  		= cast(int) IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

				IupSetIntId( ih, "MARKERNEXT", ++currentLine, 2 );
				
				int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

				if( markLineNumber < 0 )
				{
					IupSetIntId( ih, "MARKERNEXT", 0, 2 );
					markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
					if( markLineNumber < 0 ) return IUP_DEFAULT;
				}

				IupSetFocus( ih );
				IupSetAttributeId( ih, "ENSUREVISIBLE", markLineNumber, "ENFORCEPOLICY" );
				IupSetInt( ih, "CARET", markLineNumber );
				StatusBarAction.update();
			}
			
			return IUP_DEFAULT;
		});
		
		IupSetAttributes( btnMarkClean, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markclear,NAME=POSEIDON_TOOLBAR_MarkClear" );
		IupSetStrAttribute( btnMarkClean, "TIP", GLOBAL.languageItems["bookmarkclear"].toCString );
		IupSetCallback( btnMarkClean, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null ) IupSetInt( ih, "MARKERDELETEALL", 1 );
			return IUP_DEFAULT;
		});


		IupSetAttributes( btnCompile, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_compile,NAME=POSEIDON_TOOLBAR_Compile" );
		IupSetStrAttribute( btnCompile, "TIP", GLOBAL.languageItems["sc_compile"].toCString );
		IupSetCallback( btnCompile, "BUTTON_CB", cast(Icallback) &compile_button_cb );

		IupSetAttributes( btnBuildRun, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_buildrun,NAME=POSEIDON_TOOLBAR_CompileRun" );
		IupSetStrAttribute( btnBuildRun, "TIP", GLOBAL.languageItems["sc_compilerun"].toCString );
		IupSetCallback( btnBuildRun, "BUTTON_CB", cast(Icallback) &buildrun_button_cb );

		IupSetAttributes( btnRun, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_run,NAME=POSEIDON_TOOLBAR_Run" );
		IupSetStrAttribute( btnRun, "TIP", GLOBAL.languageItems["sc_run"].toCString );
		IupSetCallback( btnRun, "BUTTON_CB", cast(Icallback) &run_button_cb );

		IupSetAttributes( btnBuildAll, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_build,NAME=POSEIDON_TOOLBAR_Build" );
		IupSetStrAttribute( btnBuildAll, "TIP", GLOBAL.languageItems["sc_build"].toCString );
		IupSetCallback( btnBuildAll, "BUTTON_CB", cast(Icallback) &build_button_cb );
		IupSetHandle( "toolbar_BuildAll", btnBuildAll );
		
		IupSetAttributes( btnReBuild, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_rebuild,NAME=POSEIDON_TOOLBAR_ReBuild" );
		IupSetStrAttribute( btnReBuild, "TIP", GLOBAL.languageItems["rebuildprj"].toCString );
		IupSetCallback( btnReBuild, "BUTTON_CB", cast(Icallback) &buildall_button_cb );
		IupSetHandle( "toolbar_ReBuild", btnReBuild );

		IupSetAttributes( btnQuickRun, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_quickrun,NAME=POSEIDON_TOOLBAR_QuickRun" );
		IupSetStrAttribute( btnQuickRun, "TIP", GLOBAL.languageItems["sc_quickrun"].toCString );
		IupSetCallback( btnQuickRun, "BUTTON_CB", cast(Icallback) &quickRun_button_cb );


		
		for( int i = 0; i < 7; i++ )
		{
			labelSEPARATOR[i] = IupFlatSeparator(); 
			IupSetAttributes( labelSEPARATOR[i], "STYLE=EMPTY" );
		}

		version(Windows)
		{
			guiButton = IupToggle( null, "GUI" );
			IupSetAttributes( guiButton, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_console,IMPRESS=icon_gui,NAME=POSEIDON_TOOLBAR_Gui" );
			IupSetStrAttribute( guiButton, "TIP", "Console / GUI" );
			if( GLOBAL.editorSetting00.GUI == "OFF" ) IupSetAttribute( guiButton, "VALUE", "OFF" ); else IupSetAttribute( guiButton, "VALUE", "ON" );
			IupSetCallback( guiButton, "ACTION", cast(Icallback) function( Ihandle* ih )
			{
				if( GLOBAL.editorSetting00.GUI == "ON" ) GLOBAL.editorSetting00.GUI = "OFF"; else GLOBAL.editorSetting00.GUI = "ON";
				return IUP_DEFAULT;
			});			
			
			bitButton = IupToggle( null, "bit" );
			IupSetAttributes( bitButton, "CANFOCUS=NO,ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_32,IMPRESS=icon_64,NAME=POSEIDON_TOOLBAR_Bit" );
			IupSetStrAttribute( bitButton, "TIP", "32 / 64 bit" );
			if( GLOBAL.compilerSettings.Bit64 == "OFF" ) IupSetAttribute( bitButton, "VALUE", "OFF" ); else IupSetAttribute( bitButton, "VALUE", "ON" );
			IupSetCallback( bitButton, "ACTION", cast(Icallback) function( Ihandle* ih )
			{
				if( GLOBAL.compilerSettings.Bit64 == "ON" ) GLOBAL.compilerSettings.Bit64 = "OFF"; else GLOBAL.compilerSettings.Bit64 = "ON";
				return IUP_DEFAULT;
			});
		}
		
		listHandle = IupFlatList();
		IupSetAttributes( listHandle, "CPADDING=0x0,SIZE=x5,ACTIVE=YES,SHOWIMAGE=YES,SCROLLBAR=NO,NAME=POSEIDON_TOOLBAR_FunctionList" );
		version(Windows) IupSetStrAttribute( listHandle, "FONT", toStringz( GLOBAL.fonts[0].fontString ) ); else IupSetStrAttribute( listHandle, "FONTFACE", toStringz( GLOBAL.fonts[0].fontString ) );
		IupSetAttribute( listHandle, "EXPAND", "HORIZONTAL" );
		IupSetStrAttribute( listHandle, "FGCOLOR", toStringz ( GLOBAL.editColor.txtFore ) );
		IupSetAttribute( listHandle, "HLCOLORALPHA", "0" );
		IupSetStrAttribute( listHandle, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		if( GLOBAL.parserSettings.showFunctionTitle == "ON" ) IupSetAttribute( listHandle, "VISIBLE", "YES" ); else IupSetAttribute( listHandle, "VISIBLE", "NO" );
		
		Ihandle* commandText = IupScintilla();
		IupSetAttributes( commandText, "ACTIVE=YES,NAME=POSEIDON_COMMANDLINE,VISIBLE=NO,SIZE=1x8" );
		IupSetCallback( commandText, "SAVEPOINT_CB", cast(Icallback) &command_SAVEPOINT_CB );
		
		
		// IUP Container to put buttons on~
		version(Windows)
		{
			handle = IupHbox( btnNew, btnOpen, labelSEPARATOR[0], btnSave, btnSaveAll, labelSEPARATOR[3], btnUndo, btnRedo, btnClearUndoBuffer, labelSEPARATOR[1], btnCut, btnCopy, btnPaste, labelSEPARATOR[6], btnBackNav, btnForwardNav, btnClearNav, labelSEPARATOR[2], btnMark, btnMarkPrev,
					btnMarkNext, btnMarkClean, labelSEPARATOR[4], btnCompile, btnBuildRun, btnRun, btnBuildAll, btnReBuild, btnQuickRun, labelSEPARATOR[5], bitButton, guiButton, listHandle, commandText, null );
		}
		else
		{
			handle = IupHbox( btnNew, btnOpen, labelSEPARATOR[0], btnSave, btnSaveAll, labelSEPARATOR[3], btnUndo, btnRedo, btnClearUndoBuffer, labelSEPARATOR[1], btnCut, btnCopy, btnPaste, labelSEPARATOR[6], btnBackNav, btnForwardNav, btnClearNav, labelSEPARATOR[2], btnMark, btnMarkPrev,
					btnMarkNext, btnMarkClean, labelSEPARATOR[4], btnCompile, btnBuildRun, btnRun, btnBuildAll, btnReBuild, btnQuickRun, listHandle, commandText, null );
		}

		IupSetAttribute( handle, "NORMALIZESIZE", "VERTICAL" );
		handle = IupBackgroundBox( handle );
		version(Windows) IupSetStrAttribute( handle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) ); // linux get IupFlatSeparator wrong color

		IupSetAttributes( handle, "ALIGNMENT=ACENTER,NAME=POSEIDON_TOOLBAR" );
		IupSetHandle( "POSEIDON_MAIN_TOOLBAR", handle );
		version(Posix) IupSetAttributes( handle, "MARGIN=0x2" );
		
		changeIcons();
	}
	
	void changeIcons()
	{
		string tail;
		if( GLOBAL.editorSetting00.IconInvert != "OFF" ) tail = "_invert";

		IupSetStrAttribute( btnNew, "IMAGE", toStringz( tail.length ? "icon_newfile" : "icon_newfile" ~ tail ) );
		IupSetStrAttribute( btnOpen, "IMAGE", toStringz( tail.length ? "icon_openfile" : "icon_openfile" ~ tail ) );
		IupSetStrAttribute( btnSave, "IMAGE", toStringz( tail.length ? "icon_save" : "icon_save" ~ tail ) );
		IupSetStrAttribute( btnSaveAll, "IMAGE", toStringz( tail.length ? "icon_saveall" : "icon_saveall" ~ tail ) );
		IupSetStrAttribute( btnUndo, "IMAGE", toStringz( tail.length ? "icon_undo" : "icon_undo" ~ tail ) );
		IupSetStrAttribute( btnRedo, "IMAGE", toStringz( tail.length ? "icon_redo" : "icon_redo" ~ tail ) );
		IupSetStrAttribute( btnClearUndoBuffer, "IMAGE", toStringz( tail.length ? "icon_clear" : "icon_clear" ~ tail ) );

		IupSetStrAttribute( btnCut, "IMAGE", toStringz( tail.length ? "icon_cut" : "icon_cut" ~ tail ) );
		IupSetStrAttribute( btnCopy, "IMAGE", toStringz( tail.length ? "icon_copy" : "icon_copy" ~ tail ) );
		IupSetStrAttribute( btnPaste, "IMAGE", toStringz( tail.length ? "icon_paste" : "icon_paste" ~ tail ) );

		IupSetStrAttribute( btnBackNav, "IMAGE", toStringz( tail.length ? "icon_debug_left" : "icon_debug_left" ~ tail ) );
		IupSetStrAttribute( btnForwardNav, "IMAGE", toStringz( tail.length ? "icon_debug_right" : "icon_debug_right" ~ tail ) );
		IupSetStrAttribute( btnClearNav, "IMAGE", toStringz( tail.length ? "icon_clear" : "icon_clear" ~ tail ) );

		IupSetStrAttribute( btnMark, "IMAGE", toStringz( tail.length ? "icon_mark" : "icon_mark" ~ tail ) );
		IupSetStrAttribute( btnMarkPrev, "IMAGE", toStringz( tail.length ? "icon_markprev" : "icon_markprev" ~ tail ) );
		IupSetStrAttribute( btnMarkNext, "IMAGE", toStringz( tail.length ? "icon_marknext" : "icon_marknext" ~ tail ) );
		IupSetStrAttribute( btnMarkClean, "IMAGE", toStringz( tail.length ? "icon_markclear" : "icon_markclear" ~ tail ) );

		IupSetStrAttribute( btnCompile, "IMAGE", toStringz( tail.length ? "icon_compile" : "icon_compile" ~ tail ) );
		IupSetStrAttribute( btnBuildRun, "IMAGE", toStringz( tail.length ? "icon_buildrun" : "icon_buildrun" ~ tail ) );
		IupSetStrAttribute( btnRun, "IMAGE", toStringz( tail.length ? "icon_run" : "icon_run" ~ tail ) );
		IupSetStrAttribute( btnBuildAll, "IMAGE", toStringz( tail.length ? "icon_build" : "icon_build" ~ tail ) );
		IupSetStrAttribute( btnReBuild, "IMAGE", toStringz( tail.length ? "icon_rebuild" : "icon_rebuild" ~ tail ) );
		IupSetStrAttribute( btnQuickRun, "IMAGE", toStringz( tail.length ? "icon_quickrun" : "icon_quickrun" ~ tail ) );

		IupSetStrAttribute( guiButton, "IMAGE", toStringz( tail.length ? "icon_console" : "icon_console" ~ tail ) );
		IupSetStrAttribute( guiButton, "IMPRESS", toStringz( "icon_gui" ~ tail ) );
		IupSetStrAttribute( bitButton, "IMAGE", toStringz( tail.length ? "icon_32" : "icon_32" ~ tail ) );
		IupSetStrAttribute( bitButton, "IMPRESS", toStringz( "icon_64" ~ tail ) );
	}

public:
	this()
	{
		createToolBar();
	}
	
	~this()
	{
	}

	Ihandle* getHandle()
	{
		return handle;
	}

	Ihandle* getListHandle()
	{
		return listHandle;
	}

	Ihandle* getGuiButtonHandle()
	{
		return guiButton;
	}

	Ihandle* getBitButtonHandle()
	{
		return bitButton;
	}

	bool checkGuiButtonStatus()
	{
		if( fromStringz( IupGetAttribute( guiButton, "VALUE" ) ) == "ON" ) return true;
		return false;
	}
	
	void showList( bool status )
	{
		if( status ) IupSetAttribute( listHandle, "VISIBLE", "YES" ); else IupSetAttribute( listHandle, "VISIBLE", "NO" );
	}

	void changeColor()
	{
		version(Windows) IupSetStrAttribute( handle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		
		IupSetStrAttribute( listHandle, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( listHandle, "HLCOLORALPHA", "0" );
		IupSetStrAttribute( listHandle, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
	}
}


extern( C )
{
	private int compile_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				ExecuterAction.compile();
			}
			else if( button == IUP_BUTTON3 ) // Right Click
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					auto dlg = new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString(), 1 );
					string[] result = dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS, 1  );
					if( result.length == 3 ) ExecuterAction.compile( result[0], null, result[2] );
					destroy( dlg );
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int build_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				ExecuterAction.build();
			}
			else if( button == IUP_BUTTON3 ) // Right Click
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					auto dlg = new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString(), 1 );
					string[] result = dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS, 1  );
					if( result.length == 3 ) ExecuterAction.build( result[0], null, result[2] );
					destroy( dlg );
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int buildall_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				ExecuterAction.buildAll();
			}
			else if( button == IUP_BUTTON3 ) // Right Click
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					auto dlg = new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString(), 1 );
					string[] result = dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS, 1  );
					if( result.length == 3 ) ExecuterAction.buildAll( result[0], result[2], null );
					destroy( dlg );
				} 
			}
		}
		return IUP_DEFAULT;
	}
	
	private int buildrun_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				ExecuterAction.compile( null, null, null, null, true );
			}
			else if( button == IUP_BUTTON3 ) // Right Click
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					auto dlg = new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString(), 3 );
					string[] result = dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS, 3  ).dup;
					if( result.length == 3 ) ExecuterAction.compile( result[0], result[1], result[2], null, true ); // 3rd parameter = " " is compile & run
					destroy( dlg );
				}
			}
		}
		return IUP_DEFAULT;
	}	
	
	private int run_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				ExecuterAction.run();
			}
			else if( button == IUP_BUTTON3 ) // Right Click
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					auto dlg = new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString(), 2 );
					string[] result = dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS, 2  );
					if( result.length == 3 ) ExecuterAction.run( result[1] );
					destroy( dlg );
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int quickRun_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				ExecuterAction.quickRun( /*Util.trim( GLOBAL.defaultOption.toDString )*/ );
			}
			else if( button == IUP_BUTTON3 ) // Right Click
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					auto dlg = new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString(), 3 );
					string[] result = dlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS, 3  );
					if( result.length == 3 ) ExecuterAction.quickRun( result[0], result[1], result[2] );
					destroy( dlg );
				}
			}
		}
		return IUP_DEFAULT;
	}

	/*
	For plugins......
	*/
	private int command_SAVEPOINT_CB( Ihandle *ih, int status )
	{
		if( status == 0 )
		{
			IupScintillaSendMessage( ih, 2175, 0, 0 ); // SCI_EMPTYUNDOBUFFER = 2175
			
			string command = fSTRz( IupGetAttribute( ih, "VALUE" ) );
			if( command.length )
			{
				string[] splitCommand = Array.split( command, "," );
				
				if( splitCommand.length == 1 )
				{
					auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
					if( cSci !is null )
					{
						switch( command )
						{
							case "NewFile":
								return menu.newFile_cb( cSci.getIupScintilla );
								
							case "OpenFile":
								return menu.openFile_cb( cSci.getIupScintilla );
							
							case "SaveFile":
								return menu.saveFile_cb( cSci.getIupScintilla );
								
							case "SaveAs":
								return menu.saveAsFile_cb( cSci.getIupScintilla );
								
							case "CloseFile":
								actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
								return IUP_DEFAULT;	
								
							case "NewProject":
								return menu.newProject_cb( cSci.getIupScintilla );

							case "OpenProject":
								return menu.openProject_cb( cSci.getIupScintilla );
								
							case "CloseProject":
								return menu.closeProject_cb( cSci.getIupScintilla );
								
							case "CloseAllProject":
								return menu.closeAllProject_cb( cSci.getIupScintilla );

							case "SaveProject":
								return menu.saveProject_cb( cSci.getIupScintilla );

							case "SaveAllProject":
								return menu.saveAllProject_cb( cSci.getIupScintilla );
								
							case "ProjectProperties":
								return menu.projectProperties_cb( cSci.getIupScintilla );
								
							case "Compile":
								return menu.compile_cb( cSci.getIupScintilla );

							case "CompileRun":
								return menu.buildrun_cb( cSci.getIupScintilla );

							case "Run":
								return menu.run_cb( cSci.getIupScintilla );

							case "Build":
								return menu.buildAll_cb( cSci.getIupScintilla );

							case "ReBuild":
								return menu.reBuild_cb( cSci.getIupScintilla );

							case "QuickRun":
								return menu.quickRun_cb( cSci.getIupScintilla );
								
							case "Comment":
								return menu.comment_cb( null );

							case "UnComment":
								return menu.uncomment_cb( null );
								
							default:
						}
					}
				}
				else if( splitCommand.length == 2 )
				{
					switch( strip( splitCommand[0] ) )
					{
						case "FBCx32":
							GLOBAL.compilerSettings.compilerFullPath = strip( splitCommand[1] );
							if( GLOBAL.preferenceDlg !is null ) IupSetStrAttribute( IupGetHandle( "compilerPath_Handle" ), "VALUE", toStringz( GLOBAL.compilerSettings.compilerFullPath ) );
							break;

						case "FBCx64":
							version(Windows)
							{
								GLOBAL.compilerSettings.x64compilerFullPath = strip( splitCommand[1] );
								if( GLOBAL.preferenceDlg !is null ) IupSetStrAttribute( IupGetHandle( "x64compilerPath_Handle" ), "VALUE", toStringz( GLOBAL.compilerSettings.x64compilerFullPath ) );
							}
							break;
						default:
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}	
}