module layouts.toolbar;

private import iup.iup;
private import global, actionManager, menu, executer;
private import Util = tango.text.Util, tango.stdc.stringz;;


class CToolBar
{
	private:
	import 				iup.iup_scintilla;
	import 				menu, parser.ast, tools;
	
	Ihandle*			handle, listHandle, guiButton, bitButton;
	Ihandle* 			btnNew, btnOpen;
	Ihandle* 			btnSave, btnSaveAll;
	Ihandle* 			btnUndo, btnRedo;
	Ihandle* 			btnCut, btnCopy, btnPaste;
	Ihandle* 			btnMark, btnMarkPrev, btnMarkNext, btnMarkClean;
	Ihandle* 			btnCompile, btnBuildRun, btnRun, btnBuildAll, btnQuickRun;
	Ihandle*			outlineButtonHide, messageButtonHide;
	Ihandle*[7]			labelSEPARATOR;

	void createToolBar()
	{
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


		IupSetAttributes( btnNew, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_newfile" );
		
		IupSetAttribute( btnNew, "TIP", GLOBAL.languageItems["caption_new"].toCString );
		IupSetCallback( btnNew, "ACTION", cast(Icallback) &menu.newFile_cb ); // From menu.d

		IupSetAttributes( btnOpen, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_openfile" );
		IupSetAttribute( btnOpen, "TIP", GLOBAL.languageItems["caption_open"].toCString );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &menu.openFile_cb ); // From menu.d

		IupSetAttributes( btnSave, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_save" );
		IupSetAttribute( btnSave, "TIP", GLOBAL.languageItems["sc_save"].toCString );
		IupSetCallback( btnSave, "ACTION", cast(Icallback) &menu.saveFile_cb ); // From menu.d

		IupSetAttributes( btnSaveAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_saveall" );
		IupSetAttribute( btnSaveAll, "TIP", GLOBAL.languageItems["sc_saveall"].toCString );
		IupSetCallback( btnSaveAll, "ACTION", cast(Icallback) &menu.saveAllFile_cb ); // From menu.d

		IupSetAttributes( btnUndo, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_undo" );
		IupSetAttribute( btnUndo, "TIP", GLOBAL.languageItems["sc_undo"].toCString );
		IupSetCallback( btnUndo, "ACTION", cast(Icallback) &menu.undo_cb ); // From menu.d
		
		IupSetAttributes( btnRedo, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_redo" );
		IupSetAttribute( btnRedo, "TIP", GLOBAL.languageItems["sc_redo"].toCString );
		IupSetCallback( btnRedo, "ACTION", cast(Icallback) &menu.redo_cb ); // From menu.d
		

		IupSetAttributes( btnCut, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_cut" );
		IupSetAttribute( btnCut, "TIP", GLOBAL.languageItems["caption_cut"].toCString );
		IupSetCallback( btnCut, "ACTION", cast(Icallback) &menu.cut_cb ); // From menu.d
		
		IupSetAttributes( btnCopy, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_copy" );
		IupSetAttribute( btnCopy, "TIP", GLOBAL.languageItems["caption_copy"].toCString );
		IupSetCallback( btnCopy, "ACTION", cast(Icallback) &menu.copy_cb ); // From menu.d
		
		IupSetAttributes( btnPaste, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_paste" );
		IupSetAttribute( btnPaste, "TIP", GLOBAL.languageItems["caption_paste"].toCString );
		IupSetCallback( btnPaste, "ACTION", cast(Icallback) &menu.paste_cb ); // From menu.d

		IupSetAttributes( btnMark, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_mark" );
		IupSetAttribute( btnMark, "TIP", GLOBAL.languageItems["bookmark"].toCString );
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
		
		IupSetAttributes( btnMarkPrev, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markprev" );
		IupSetAttribute( btnMarkPrev, "TIP", GLOBAL.languageItems["bookmarkprev"].toCString );
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
					if( markLineNumber < 0 ) return;
				}			
				
				IupSetFocus( ih );
				if( markLineNumber > -1 ) IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
				StatusBarAction.update();
			}
		});
		
		IupSetAttributes( btnMarkNext, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_marknext" );
		IupSetAttribute( btnMarkNext, "TIP", GLOBAL.languageItems["bookmarknext"].toCString );
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
					if( markLineNumber < 0 ) return;
				}

				IupSetFocus( ih );
				IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
				StatusBarAction.update();
			}
		});
		
		IupSetAttributes( btnMarkClean, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_markclear" );
		IupSetAttribute( btnMarkClean, "TIP", GLOBAL.languageItems["bookmarkclear"].toCString );
		IupSetCallback( btnMarkClean, "ACTION", cast(Icallback) function()
		{
			Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
			if( ih != null ) IupSetInt( ih, "MARKERDELETEALL", 1 );
			return IUP_DEFAULT;
		});


		IupSetAttributes( btnCompile, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_compile" );
		IupSetAttribute( btnCompile, "TIP", GLOBAL.languageItems["sc_compile"].toCString );
		IupSetCallback( btnCompile, "BUTTON_CB", cast(Icallback) &compile_button_cb );

		IupSetAttributes( btnBuildRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_buildrun" );
		IupSetAttribute( btnBuildRun, "TIP", GLOBAL.languageItems["sc_compilerun"].toCString );
		IupSetCallback( btnBuildRun, "BUTTON_CB", cast(Icallback) &buildrun_button_cb );

		IupSetAttributes( btnRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_run" );
		IupSetAttribute( btnRun, "TIP", GLOBAL.languageItems["sc_run"].toCString );
		IupSetCallback( btnRun, "BUTTON_CB", cast(Icallback) &run_button_cb );

		IupSetAttributes( btnBuildAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_rebuild" );
		IupSetAttribute( btnBuildAll, "TIP", GLOBAL.languageItems["sc_build"].toCString );
		IupSetCallback( btnBuildAll, "BUTTON_CB", cast(Icallback) &buildall_button_cb );

		IupSetAttributes( btnQuickRun, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_quickrun" );
		IupSetAttribute( btnQuickRun, "TIP", GLOBAL.languageItems["sc_quickrun"].toCString );
		IupSetCallback( btnQuickRun, "BUTTON_CB", cast(Icallback) &quickRun_button_cb );


		
		for( int i = 0; i < 7; i++ )
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
		
		outlineButtonHide = IupToggle( null, "Hide" );
		IupSetAttributes( outlineButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_r,IMPRESS=icon_shift_l" );
		IupSetAttribute( outlineButtonHide, "TIP", GLOBAL.languageItems["sc_leftwindow"].toCString );
		IupSetHandle( "outlineButtonHide", outlineButtonHide );
		IupSetCallback( outlineButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outline_cb( GLOBAL.menuOutlineWindow );
			return IUP_DEFAULT;
		});		

		messageButtonHide = IupToggle( null, "HideMessage" );
		IupSetAttributes( messageButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_t,IMPRESS=icon_shift_b" );
		IupSetAttribute( messageButtonHide, "TIP", GLOBAL.languageItems["sc_bottomwindow"].toCString );
		IupSetHandle( "messageButtonHide", messageButtonHide );
		IupSetCallback( messageButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.message_cb( GLOBAL.menuMessageWindow );
			return IUP_DEFAULT;
		});		
		
		
		guiButton = IupToggle( null, "GUI" );
		IupSetAttributes( guiButton, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_console,IMPRESS=icon_gui,VALUE=OFF" );
		IupSetAttribute( guiButton, "TIP", "Console / GUI" );
		
		bitButton = IupToggle( null, "bit" );
		version(Windows) IupSetAttributes( bitButton, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_32,IMPRESS=icon_64,VALUE=OFF" ); else IupSetAttributes( bitButton, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_32,IMPRESS=icon_64,VALUE=ON" );
		IupSetAttribute( bitButton, "TIP", "32 / 64 bit" );
		
		listHandle = IupList( null );
		IupSetAttributes( listHandle, "ACTIVE=YES,SHOWIMAGE=YES,SCROLLBAR=NO" );
		IupSetAttribute( listHandle, "SIZE", GLOBAL.widthFunctionTitle.toCString );
		IupSetAttribute( listHandle, "FONT", toStringz( GLOBAL.fonts[0].fontString ) );
		if( GLOBAL.showFunctionTitle == "ON" ) IupSetAttribute( listHandle, "VISIBLE", "YES" ); else IupSetAttribute( listHandle, "VISIBLE", "NO" );
		
		// IUP Container to put buttons on~
		handle = IupHbox( btnNew, btnOpen, labelSEPARATOR[0], btnSave, btnSaveAll, labelSEPARATOR[3], btnUndo, btnRedo, labelSEPARATOR[1], btnCut, btnCopy, btnPaste, labelSEPARATOR[2], btnMark, btnMarkPrev,
						btnMarkNext, btnMarkClean, labelSEPARATOR[4], btnCompile, btnBuildRun, btnRun, btnBuildAll, btnQuickRun, labelSEPARATOR[5], outlineButtonHide, messageButtonHide, labelSEPARATOR[6], guiButton, bitButton, listHandle, null );/* labelSEPARATOR[5],
						btnResume, btnStop, btnStep, btnNext, btnReturn, null );*/
		IupSetAttributes( handle, "GAP=3,ALIGNMENT=ACENTER" );
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
	
	int checkBitButtonStatus()
	{
		if( fromStringz( IupGetAttribute( bitButton, "VALUE" ) ) == "ON" ) return 64;
		return 32;
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
				ExecuterAction.compile( /*Util.trim( GLOBAL.defaultOption.toDString )*/ );
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
				if( ExecuterAction.compile( /*Util.trim( GLOBAL.defaultOption.toDString )*/ ) ) ExecuterAction.run();
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
				ExecuterAction.quickRun( /*Util.trim( GLOBAL.defaultOption.toDString )*/ );
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