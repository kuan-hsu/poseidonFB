module layouts.toolbar;

private import iup.iup;
private import global, actionManager, menu, executer;
private import Util = tango.text.Util, tango.stdc.stringz;;


class CToolBar
{
	private:
	import 				iup.iup_scintilla;
	import 				menu, parser.ast, tools;
	
	Ihandle*			handle, listHandle, guiButton;
	CstringConvert[20]	cStrings;

	void createToolBar()
	{
		Ihandle* btnNew, btnOpen;
		Ihandle* btnSave, btnSaveAll;
		Ihandle* btnUndo, btnRedo;
		Ihandle* btnCut, btnCopy, btnPaste;
		Ihandle* btnMark, btnMarkPrev, btnMarkNext, btnMarkClean;
		Ihandle* btnCompile, btnBuildRun, btnRun, btnBuildAll, btnQuickRun;

		btnNew		= IupButton( null, null );
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


		cStrings[0] = new CstringConvert( GLOBAL.languageItems["new"] );
		cStrings[1] = new CstringConvert( GLOBAL.languageItems["open"] );
		cStrings[2] = new CstringConvert( GLOBAL.languageItems["save"] );
		cStrings[3] = new CstringConvert( GLOBAL.languageItems["saveall"] );
		cStrings[4] = new CstringConvert( GLOBAL.languageItems["undo"] );
		cStrings[5] = new CstringConvert( GLOBAL.languageItems["redo"] );

		IupSetAttributes( btnNew, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_newfile" );
		
		IupSetAttribute( btnNew, "TIP", cStrings[0].toStringz );
		IupSetCallback( btnNew, "ACTION", cast(Icallback) &menu.newFile_cb ); // From menu.d

		IupSetAttributes( btnOpen, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_openfile" );
		IupSetAttribute( btnOpen, "TIP", cStrings[1].toStringz );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &menu.openFile_cb ); // From menu.d

		IupSetAttributes( btnSave, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_save" );
		IupSetAttribute( btnSave, "TIP", cStrings[2].toStringz );
		IupSetCallback( btnSave, "ACTION", cast(Icallback) &menu.saveFile_cb ); // From menu.d

		IupSetAttributes( btnSaveAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_saveall" );
		IupSetAttribute( btnSaveAll, "TIP", cStrings[3].toStringz );
		IupSetCallback( btnSaveAll, "ACTION", cast(Icallback) &menu.saveAllFile_cb ); // From menu.d

		IupSetAttributes( btnUndo, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_undo" );
		IupSetAttribute( btnUndo, "TIP", cStrings[4].toStringz );
		IupSetCallback( btnUndo, "ACTION", cast(Icallback) &menu.undo_cb ); // From menu.d
		
		IupSetAttributes( btnRedo, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_redo" );
		IupSetAttribute( btnRedo, "TIP", cStrings[5].toStringz );
		IupSetCallback( btnRedo, "ACTION", cast(Icallback) &menu.redo_cb ); // From menu.d
		

		cStrings[6] = new CstringConvert( GLOBAL.languageItems["cut"] );
		cStrings[7] = new CstringConvert( GLOBAL.languageItems["copy"] );
		cStrings[8] = new CstringConvert( GLOBAL.languageItems["paste"] );
		cStrings[9] = new CstringConvert( GLOBAL.languageItems["bookmark"] );
		cStrings[10] = new CstringConvert( GLOBAL.languageItems["bookmarkprev"] );
		cStrings[11] = new CstringConvert( GLOBAL.languageItems["bookmarknext"] );
		cStrings[12] = new CstringConvert( GLOBAL.languageItems["bookmarkclear"] );		
		
		
		IupSetAttributes( btnCut, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_cut" );
		IupSetAttribute( btnCut, "TIP", cStrings[6].toStringz );
		IupSetCallback( btnCut, "ACTION", cast(Icallback) &menu.cut_cb ); // From menu.d
		
		IupSetAttributes( btnCopy, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_copy" );
		IupSetAttribute( btnCopy, "TIP", cStrings[7].toStringz );
		IupSetCallback( btnCopy, "ACTION", cast(Icallback) &menu.copy_cb ); // From menu.d
		
		IupSetAttributes( btnPaste, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_paste" );
		IupSetAttribute( btnPaste, "TIP", cStrings[8].toStringz );
		IupSetCallback( btnPaste, "ACTION", cast(Icallback) &menu.paste_cb ); // From menu.d

		IupSetAttributes( btnMark, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_mark" );
		IupSetAttribute( btnMark, "TIP", cStrings[9].toStringz );
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
		
		IupSetAttributes( btnMarkPrev, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markprev" );
		IupSetAttribute( btnMarkPrev, "TIP", cStrings[10].toStringz );
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
		
		IupSetAttributes( btnMarkNext, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_marknext" );
		IupSetAttribute( btnMarkNext, "TIP", cStrings[11].toStringz );
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
		
		IupSetAttributes( btnMarkClean, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markclear" );
		IupSetAttribute( btnMarkClean, "TIP", cStrings[12].toStringz );
		IupSetCallback( btnMarkClean, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null ) IupSetInt( ih, "MARKERDELETEALL", 1 );
		});


		cStrings[13] = new CstringConvert( GLOBAL.languageItems["compile"] );
		cStrings[14] = new CstringConvert( GLOBAL.languageItems["compilerun"] );
		cStrings[15] = new CstringConvert( GLOBAL.languageItems["run"] );
		cStrings[16] = new CstringConvert( GLOBAL.languageItems["build"] );
		cStrings[17] = new CstringConvert( GLOBAL.languageItems["quickrun"] );
		cStrings[18] = new CstringConvert( GLOBAL.languageItems["leftwindow"] );
		cStrings[19] = new CstringConvert( GLOBAL.languageItems["bottomwindow"] );	



		IupSetAttributes( btnCompile, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_compile" );
		IupSetAttribute( btnCompile, "TIP", cStrings[13].toStringz );
		IupSetCallback( btnCompile, "BUTTON_CB", cast(Icallback) &compile_button_cb );

		IupSetAttributes( btnBuildRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_buildrun" );
		IupSetAttribute( btnBuildRun, "TIP", cStrings[14].toStringz );
		IupSetCallback( btnBuildRun, "BUTTON_CB", cast(Icallback) &buildrun_button_cb );

		IupSetAttributes( btnRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_run" );
		IupSetAttribute( btnRun, "TIP", cStrings[15].toStringz );
		IupSetCallback( btnRun, "BUTTON_CB", cast(Icallback) &run_button_cb );

		IupSetAttributes( btnBuildAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_rebuild" );
		IupSetAttribute( btnBuildAll, "TIP", cStrings[16].toStringz );
		IupSetCallback( btnBuildAll, "BUTTON_CB", cast(Icallback) &buildall_button_cb );

		IupSetAttributes( btnQuickRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_quickrun" );
		IupSetAttribute( btnQuickRun, "TIP", cStrings[17].toStringz );
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
		IupSetAttribute( outlineButtonHide, "TIP", cStrings[18].toStringz );
		IupSetHandle( "outlineButtonHide", outlineButtonHide );
		IupSetCallback( outlineButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outline_cb( GLOBAL.menuOutlineWindow );
		});		

		Ihandle* messageButtonHide = IupToggle( null, "HideMessage" );
		IupSetAttributes( messageButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_t,IMPRESS=icon_shift_b" );
		IupSetAttribute( messageButtonHide, "TIP", cStrings[19].toStringz );
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