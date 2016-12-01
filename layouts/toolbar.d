module layouts.toolbar;

private import iup.iup;
private import global, actionManager, menu, executer;
private import Util = tango.text.Util, tango.stdc.stringz;;


class CToolBar
{
	private:
	import iup.iup_scintilla;
	import menu, parser.ast;
	
	Ihandle*	handle, listHandle, guiButton;

	void createToolBar()
	{
		Ihandle* btnNew, btnOpen;
		Ihandle* btnSave, btnSaveAll;
		Ihandle* btnUndo, btnRedo;
		Ihandle* btnCut, btnCopy, btnPaste;
		Ihandle* btnMark, btnMarkPrev, btnMarkNext, btnMarkClean;
		Ihandle* btnCompile, btnBuildRun, btnRun, btnBuildAll, btnQuickRun;

		btnNew		= IupButton( null, "New" );
		btnOpen		= IupButton( null, "Open" );

		btnSave		= IupButton( null, "Save" );
		btnSaveAll	= IupButton( null, "SaveAll" );	

		btnUndo		= IupButton( null, "Undo" );
		btnRedo		= IupButton( null, "Redo" );
		
		btnCut		= IupButton( null, "Cut" );
		btnCopy		= IupButton( null, "Copy" );
		btnPaste	= IupButton( null, "Paste" );

		btnMark		= IupButton( null, "Mark" );
		btnMarkPrev	= IupButton( null, "MarkPrev" );
		btnMarkNext	= IupButton( null, "MarkNext" );
		btnMarkClean= IupButton( null, "MarkClean" );
		
		btnCompile	= IupButton( null, "Compile" );
		btnBuildRun = IupButton( null, "BuildRun" );
		btnRun		= IupButton( null, "Run" );
		btnBuildAll	= IupButton( null, "BuildAll" );
		btnQuickRun = IupButton( null, "QuickRun" );


		IupSetAttributes( btnNew, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_newfile,TIP=New_File" );
		IupSetCallback( btnNew, "ACTION", cast(Icallback) &menu.newFile_cb ); // From menu.d

		IupSetAttributes( btnOpen, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_openfile,TIP=OPEN" );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &menu.openFile_cb ); // From menu.d

		IupSetAttributes( btnSave, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_save,TIP=Save" );
		IupSetCallback( btnSave, "ACTION", cast(Icallback) &menu.saveFile_cb ); // From menu.d

		IupSetAttributes( btnSaveAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_saveall,TIP=Save_All" );
		IupSetCallback( btnSaveAll, "ACTION", cast(Icallback) &menu.saveAllFile_cb ); // From menu.d


		IupSetAttributes( btnUndo, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_undo,TIP=Undo" );
		IupSetCallback( btnUndo, "ACTION", cast(Icallback) &menu.undo_cb ); // From menu.d
		
		IupSetAttributes( btnRedo, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_redo,TIP=Redo" );
		IupSetCallback( btnRedo, "ACTION", cast(Icallback) &menu.redo_cb ); // From menu.d
		
		IupSetAttributes( btnCut, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_cut,TIP=Cut" );
		IupSetCallback( btnCut, "ACTION", cast(Icallback) &menu.cut_cb ); // From menu.d
		
		IupSetAttributes( btnCopy, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_copy,TIP=Copy" );
		IupSetCallback( btnCopy, "ACTION", cast(Icallback) &menu.copy_cb ); // From menu.d
		
		IupSetAttributes( btnPaste, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_paste,TIP=Paste" );
		IupSetCallback( btnPaste, "ACTION", cast(Icallback) &menu.paste_cb ); // From menu.d

		IupSetAttributes( btnMark, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_mark,TIP=Mark_Bookmark" );
		IupSetCallback( btnMark, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null )
			{
				int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
				int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166
				
				if( IupGetIntId( ih, "MARKERGET", currentLine ) & 2 )
				{
					IupSetIntId( ih, "MARKERDELETE", currentLine, 1 );
				}
				else
				{
					IupSetIntId( ih, "MARKERADD", currentLine, 1 );
				}
			}		
		});
		
		IupSetAttributes( btnMarkPrev, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markprev,TIP=Prev_Bookmark" );
		IupSetCallback( btnMarkPrev, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null )
			{
				int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
				int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

				IupSetIntId( ih, "MARKERPREVIOUS", --currentLine, 2 );
				
				int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

				if( markLineNumber < 0 )
				{
					int count = IupGetInt( ih, "LINECOUNT" );
					IupSetIntId( ih, "MARKERPREVIOUS", count, 2 );
					markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
					if( markLineNumber < 0 ) return;
				}			
				
				IupSetFocus( ih );
				if( markLineNumber > -1 ) IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
				StatusBarAction.update();
			}		
		});
		
		IupSetAttributes( btnMarkNext, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_marknext,TIP=Next_Bookmark" );
		IupSetCallback( btnMarkNext, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null )
			{
				int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
				int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

				IupSetIntId( ih, "MARKERNEXT", ++currentLine, 2 );
				
				int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

				if( markLineNumber < 0 )
				{
					IupSetIntId( ih, "MARKERNEXT", 0, 2 );
					markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
					if( markLineNumber < 0 ) return;
				}

				IupSetFocus( ih );
				IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
				StatusBarAction.update();
			}
		});
		
		IupSetAttributes( btnMarkClean, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markclear,TIP=Clear_Bookmark" );
		IupSetCallback( btnMarkClean, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null ) IupSetInt( ih, "MARKERDELETEALL", 1 );
		});


		IupSetAttributes( btnCompile, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_compile,TIP=Compile" );
		IupSetCallback( btnCompile, "BUTTON_CB", cast(Icallback) &compile_button_cb );

		IupSetAttributes( btnBuildRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_buildrun,TIP=CompileRun" );
		IupSetCallback( btnBuildRun, "BUTTON_CB", cast(Icallback) &buildrun_button_cb );

		IupSetAttributes( btnRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_run,TIP=Run" );
		IupSetCallback( btnRun, "BUTTON_CB", cast(Icallback) &run_button_cb );

		IupSetAttributes( btnBuildAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_rebuild,TIP=Rebuild_All" );
		IupSetAttribute( btnBuildAll, "TIP", "Build Project" );
		IupSetCallback( btnBuildAll, "BUTTON_CB", cast(Icallback) &buildall_button_cb );

		IupSetAttributes( btnQuickRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_quickrun,TIP=Quick Run" );
		IupSetAttribute( btnQuickRun, "TIP", "Quick Run" );
		IupSetCallback( btnQuickRun, "BUTTON_CB", cast(Icallback) &quickRun_button_cb );


		Ihandle*[7] labelSEPARATOR;
		for( int i = 0; i < 8; i++ )
		{
			labelSEPARATOR[i] = IupLabel( null ); 
			IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
		}

		/+
		listGUIHandle = IupList( null );
		IupSetAttributes( listGUIHandle, "ACTIVE=YES,SIZE=50x12,SCROLLBAR=NO" );
		IupSetAttribute( listGUIHandle, "FONT", toStringz( GLOBAL.fonts[0].fontString ) );
		IupSetAttributes( listGUIHandle, "1=\"Console\",2=\"GUI\",SHOWIMAGE=NO,VALUE=1,DROPDOWN=YES,VISIBLE_ITEMS=2");
		+/
		
		Ihandle* outlineButtonHide = IupToggle( null, "Hide" );
		IupSetAttributes( outlineButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_r,IMPRESS=icon_shift_l" );
		IupSetAttribute( outlineButtonHide, "TIP", "Show / Hide Left-Window" );
		IupSetHandle( "outlineButtonHide", outlineButtonHide );
		IupSetCallback( outlineButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outline_cb( GLOBAL.menuOutlineWindow );
		});		

		Ihandle* messageButtonHide = IupToggle( null, "HideMessage" );
		IupSetAttributes( messageButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_t,IMPRESS=icon_shift_b" );
		IupSetAttribute( messageButtonHide, "TIP", "Show / Hide Bottom-Window" );
		IupSetHandle( "messageButtonHide", messageButtonHide );
		IupSetCallback( messageButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.message_cb( GLOBAL.menuMessageWindow );
		});		
		
		
		guiButton = IupToggle( null, "GUI" );
		IupSetAttributes( guiButton, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_console,IMPRESS=icon_gui,VALUE=OFF" );
		IupSetAttribute( guiButton, "TIP", "Console / GUI" );

		listHandle = IupList( null );
		IupSetAttributes( listHandle, "ACTIVE=YES,SIZE=180x12,SHOWIMAGE=YES,SCROLLBAR=NO" );
		IupSetAttribute( listHandle, "FONT", toStringz( GLOBAL.fonts[0].fontString ) );
		if( GLOBAL.showFunctionTitle == "ON" ) IupSetAttribute( listHandle, "VISIBLE", "YES" ); else IupSetAttribute( listHandle, "VISIBLE", "NO" );
		
		
		// IUP Container to put buttons on~
		handle = IupHbox( btnNew, btnOpen, labelSEPARATOR[0], btnSave, btnSaveAll, labelSEPARATOR[3], btnUndo, btnRedo, labelSEPARATOR[1], btnCut, btnCopy, btnPaste, labelSEPARATOR[2], btnMark, btnMarkPrev,
						btnMarkNext, btnMarkClean, labelSEPARATOR[4], btnCompile, btnBuildRun, btnRun, btnBuildAll, btnQuickRun, labelSEPARATOR[5], outlineButtonHide, messageButtonHide, labelSEPARATOR[6], guiButton, listHandle, null );/* labelSEPARATOR[5],
						btnResume, btnStop, btnStep, btnNext, btnReturn, null );*/
		IupSetAttributes( handle, "GAP=5,ALIGNMENT=ACENTER" );
	}


	public:
	this()
	{
		createToolBar();
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

	void showList( bool status )
	{
		if( status ) IupSetAttribute( listHandle, "VISIBLE", "YES" ); else IupSetAttribute( listHandle, "VISIBLE", "NO" );
	}

	void appendItem( CASTnode rootAST )
	{

	}
}


extern( C )
{
	private int compile_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == 49 ) // IUP_BUTTON1 = '1' = 49
			{
				ExecuterAction.compile( Util.trim( GLOBAL.defaultOption ) );
			}
			else if( button == 51 ) // IUP_BUTTON1 = '3' = 51
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					if( GLOBAL.argsDlg !is null )
					{
						char[][] result = GLOBAL.argsDlg.show( 1 );
						if( result.length == 1 ) ExecuterAction.compile( result[0] );
					}
				}
			}
		}
		return IUP_DEFAULT;
	}

	private int buildall_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == 49 ) // IUP_BUTTON1 = '1' = 49
			{
				ExecuterAction.buildAll();
			}
			else if( button == 51 ) // IUP_BUTTON1 = '3' = 51
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					if( GLOBAL.argsDlg !is null )
					{
						char[][] result = GLOBAL.argsDlg.show( 1 );
						if( result.length == 1 ) ExecuterAction.buildAll( result[0] );
					}
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int buildrun_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == 49 ) // IUP_BUTTON1 = '1' = 49
			{
				if( ExecuterAction.compile( Util.trim( GLOBAL.defaultOption ) ) ) ExecuterAction.run();
			}
			else if( button == 51 ) // IUP_BUTTON1 = '3' = 51
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					if( GLOBAL.argsDlg !is null )
					{
						char[][] result = GLOBAL.argsDlg.show( 3 );
						if( result.length == 2 )
						{
							if( ExecuterAction.compile( result[0] ) ) ExecuterAction.run( result[1] );
						}
					}
				}
			}
		}
		return IUP_DEFAULT;
	}	
	
	private int run_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == 49 ) // IUP_BUTTON1 = '1' = 49
			{
				ExecuterAction.run();
			}
			else if( button == 51 ) // IUP_BUTTON1 = '3' = 51
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					if( GLOBAL.argsDlg !is null )
					{
						char[][] result = GLOBAL.argsDlg.show( 2 );
						if( result.length == 1 ) ExecuterAction.run( result[0] );
					}
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int quickRun_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( button == 49 ) // IUP_BUTTON1 = '1' = 49
			{
				ExecuterAction.quickRun( Util.trim( GLOBAL.defaultOption ) );
			}
			else if( button == 51 ) // IUP_BUTTON1 = '3' = 51
			{
				if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) > 0 ) // No document, exit
				{
					if( GLOBAL.argsDlg !is null )
					{
						char[][] result = GLOBAL.argsDlg.show( 3 );
						if( result.length == 2 ) ExecuterAction.quickRun( result[0], result[1] );
					}
				}
			}
		}
		return IUP_DEFAULT;
	}
}