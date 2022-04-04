module layouts.debugger;


private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager, menu;
private import dialogs.singleTextDlg, layouts.table;
private import parser.ast, tools;

private import tango.stdc.stringz, Integer = tango.text.convert.Integer, tango.io.Stdout, Path = tango.io.Path, Util = tango.text.Util;


struct VarObject
{
	char[]	type;
	char[]	name;//, name64;
	char[]	value;
}


class CDebugger
{
	private:
	import 					tango.io.FilePath;

	Ihandle*				txtConsoleCommand;
	Ihandle* 				mainHandle, consoleHandle, backtraceHandle, tabResultsHandle, disasHandle;
	Ihandle*				watchTreeHandle, localTreeHandle, argTreeHandle, shareTreeHandle, varTabHandle;
	Ihandle*				bpScrollBox, regScrollBox;
	Ihandle*				varSplit, rightSplitHandle, mainSplit;
	CTable					bpTable, regTable;
	DebugThread				DebugControl;
	bool					bRunning;
	char[]					localTreeFrame, argTreeFrame, shareTreeFrame, regFrame, disasFrame;

	void createLayout()
	{
		Ihandle* vBox_LEFT;
		

		Ihandle* btnClear	= IupButton( null, "Clear" );
		Ihandle* btnResume	= IupButton( null, "Resume" );
		Ihandle* btnStop	= IupButton( null, "Stop" );
		Ihandle* btnStep	= IupButton( null, "Step" );
		Ihandle* btnNext	= IupButton( null, "Next" );
		Ihandle* btnReturn	= IupButton( null, "Return" );
		Ihandle* btnUntil	= IupButton( null, "Until" );

		txtConsoleCommand = IupText( null );
		IupSetAttributes( txtConsoleCommand, "EXPAND=HORIZONTAL,MULTILINE=YES,SCROLLBAR=NO,SIZE=x12,FONTSIZE=9,READONLY=NO" );
		IupSetCallback( txtConsoleCommand, "ACTION", cast(Icallback) &consoleInput_cb );

		Ihandle* btnTerminate = IupButton( null, "Terminate" );

		Ihandle*[6] labelSEPARATOR;
		for( int i = 0; i < 6; i++ )
		{
			labelSEPARATOR[i] = IupFlatSeparator();
			IupSetAttributes( labelSEPARATOR[i], "STYLE=EMPTY" );
		}
		
		
		IupSetAttributes( btnClear, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_clear" );				IupSetAttribute( btnClear, "TIP", GLOBAL.languageItems["clear"].toCString );
		IupSetAttributes( btnResume, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_resume" );			IupSetAttribute( btnResume, "TIP", GLOBAL.languageItems["runcontinue"].toCString );
		IupSetAttributes( btnStop, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_stop" );				IupSetAttribute( btnStop, "TIP", GLOBAL.languageItems["stop"].toCString );
		IupSetAttributes( btnStep, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_step" );				IupSetAttribute( btnStep, "TIP", GLOBAL.languageItems["step"].toCString );
		IupSetAttributes( btnNext, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_next" );				IupSetAttribute( btnNext, "TIP", GLOBAL.languageItems["next"].toCString );
		IupSetAttributes( btnReturn, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_return" );			IupSetAttribute( btnReturn, "TIP", GLOBAL.languageItems["return"].toCString );
		IupSetAttributes( btnUntil, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_until" );				IupSetAttribute( btnUntil, "TIP", GLOBAL.languageItems["until"].toCString );
		IupSetAttributes( btnTerminate, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_delete" );				IupSetAttribute( btnTerminate, "TIP", GLOBAL.languageItems["terminate"].toCString );
		

		IupSetCallback( btnClear, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isExecuting )	IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "VALUE", "(gdb)" );
			return IUP_DEFAULT;
		});
		IupSetCallback( btnResume, "BUTTON_CB", cast(Icallback) &CDebugger_resume );
		IupSetCallback( btnStop, "ACTION", cast(Icallback) &CDebugger_stop );
		IupSetCallback( btnStep, "ACTION", cast(Icallback) &CDebugger_step );
		IupSetCallback( btnNext, "ACTION", cast(Icallback) &CDebugger_next );
		IupSetCallback( btnReturn, "ACTION", cast(Icallback) &CDebugger_return );
		IupSetCallback( btnUntil, "ACTION", cast(Icallback) &CDebugger_until );

		IupSetCallback( btnTerminate, "ACTION", cast(Icallback) &CDebugger_terminate );
		
		
		// IUP Container to put buttons on~
		Ihandle* hBox_toolbar = IupHbox( labelSEPARATOR[0], btnResume, btnStop, btnStep, btnNext, btnReturn, btnUntil, labelSEPARATOR[1], IupFill(), btnClear, btnTerminate, null );
		IupSetAttributes( hBox_toolbar, "ALIGNMENT=ALEFT,GAP=2" );


		consoleHandle = IupText( null );
		IupSetAttributes( consoleHandle, "MULTILINE=YES,SCROLLBAR=YES,EXPAND=YES,READONLY=YES,WORDWRAP=YES" );
		IupSetStrAttribute( consoleHandle, "FONT", toStringz( GLOBAL.fonts[9].fontString ) );
		IupSetCallback( consoleHandle, "VALUECHANGED_CB", cast(Icallback) &consoleOutputChange_cb );

		vBox_LEFT = IupVbox( hBox_toolbar, txtConsoleCommand, consoleHandle, null );
		IupSetAttributes( vBox_LEFT, "GAP=2,EXPAND=YES,ALIGNMENT=ACENTER" );

		Ihandle* leftScrollBox = IupScrollBox( vBox_LEFT );

		//
		backtraceHandle = IupTree();
		version(Windows)
		{
			IupSetAttributes( backtraceHandle, "ADDROOT=YES,EXPAND=YES,HIDEBUTTONS=YES" );
		}
		else
		{
			IupSetAttributes( backtraceHandle, "ADDROOT=YES,EXPAND=YES,HIDEBUTTONS=NO" );
			IupSetCallback( backtraceHandle, "BRANCHCLOSE_CB", cast(Icallback) function( Ihandle* __ih )
			{
				return IUP_IGNORE;
			});
		}
		IupSetCallback( backtraceHandle, "BUTTON_CB", cast(Icallback) &backtraceBUTTON_CB );


		Ihandle* btnLeft		= IupButton( null, "Left" );
		Ihandle* btnRefresh		= IupButton( null, "Refresh" );
		
		IupSetAttributes( btnLeft, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_left" );	IupSetAttribute( btnLeft, "TIP", GLOBAL.languageItems["addtowatch"].toCString );
		IupSetAttributes( btnRefresh, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_refresh" );	IupSetAttribute( btnRefresh, "TIP", GLOBAL.languageItems["refresh"].toCString );
		
		IupSetCallback( btnLeft, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				Ihandle* varsTabHandle = cast(Ihandle*) IupGetAttribute( GLOBAL.debugPanel.getVarsTabHandle, "VALUE_HANDLE" );
				if( varsTabHandle != null )
				{
					int id = IupGetInt( varsTabHandle, "VALUE" );
					char[]	originTitle = fromStringz( IupGetAttributeId( varsTabHandle, "TITLE", id ) );
					char[]	varName = GLOBAL.debugPanel.getFullVarNameInTree( varsTabHandle, -99, true );
					if( originTitle.length )
					{
						if( originTitle[0] == '*' ) varName = '*' ~ varName;
					}
					
					if( varName.length ) GLOBAL.debugPanel.sendCommand( "display " ~ varName ~ "\n", false );
				}
			}

			return IUP_DEFAULT;	
		});

		IupSetCallback( btnRefresh, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				int tabPos =  IupGetInt( GLOBAL.debugPanel.getVarsTabHandle, "VALUEPOS" );
				switch( tabPos )
				{
					case 0:
						IupSetAttribute( GLOBAL.debugPanel.localTreeHandle, "DELNODE", "ALL" );
						GLOBAL.debugPanel.sendCommand( "info locals\n", false );
						break;
					case 1:
						IupSetAttribute( GLOBAL.debugPanel.argTreeHandle, "DELNODE", "ALL" );
						GLOBAL.debugPanel.sendCommand( "info args\n", false );
						break;
					case 2:
						IupSetAttribute( GLOBAL.debugPanel.shareTreeHandle, "DELNODE", "ALL" );
						GLOBAL.debugPanel.sendCommand( "info variables\n", false );
						break;
					default:
				}
			}
			return IUP_DEFAULT;
		});


		Ihandle* hBoxVar0_toolbar = IupHbox( btnLeft, btnRefresh, null );
		IupSetAttributes( hBoxVar0_toolbar, "ALIGNMENT=ACENTER,GAP=2" );

		watchTreeHandle = IupTree();
		IupSetAttributes( watchTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( watchTreeHandle, "COLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( watchTreeHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( watchTreeHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetCallback( watchTreeHandle, "BUTTON_CB", cast(Icallback) &watchListBUTTON_CB );

		localTreeHandle =IupTree();
		IupSetAttributes( localTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( localTreeHandle, "COLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( localTreeHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( localTreeHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetCallback( localTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );

		argTreeHandle =IupTree();
		IupSetAttributes( argTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( argTreeHandle, "COLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( argTreeHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( argTreeHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetCallback( argTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );
		
		shareTreeHandle =IupTree();
		IupSetAttributes( shareTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( shareTreeHandle, "COLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( shareTreeHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( shareTreeHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetCallback( shareTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );


		varTabHandle = IupFlatTabs( localTreeHandle, argTreeHandle, shareTreeHandle, null );
		IupSetAttributes( varTabHandle, "TABTYPE=RIGHT,TABORIENTATION=VERTICAL,TABSPADDING=2x6" );
		//IupSetAttribute( varTabHandle, "HIGHCOLOR", "0 0 255" );
		//IupSetAttribute( varTabHandle, "TABSHIGHCOLOR", "240 255 240" );
		IupSetCallback( varTabHandle, "TABCHANGEPOS_CB", cast(Icallback) &varTabChange_cb );
		IupSetAttribute( varTabHandle, "TABTITLE0", GLOBAL.languageItems["locals"].toCString() );
		IupSetAttribute( varTabHandle, "TABTITLE1", GLOBAL.languageItems["args"].toCString() );
		IupSetAttribute( varTabHandle, "TABTITLE2", GLOBAL.languageItems["shared"].toCString() );
		IupSetAttribute( varTabHandle, "HIGHCOLOR", "255 0 0" );
		IupSetStrAttribute( varTabHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( varTabHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetAttribute( varTabHandle, "SHOWLINES", "NO" );
		



		Ihandle* vbox_var0 = IupVbox( hBoxVar0_toolbar, varTabHandle, null );
		Ihandle* var0Frame = IupFrame( vbox_var0 );
		IupSetAttribute( var0Frame, "TITLE", GLOBAL.languageItems["variable"].toCString );
		IupSetAttribute( var0Frame, "EXPANDCHILDREN", "YES");
		Ihandle* var0ScrollBox = IupFlatScrollBox( var0Frame );


		
		Ihandle* btnAdd				= IupButton( null, "Add" );
		Ihandle* btnDel				= IupButton( null, "Del" );
		Ihandle* btnDelAll			= IupButton( null, "RemoveAll" );
		Ihandle* btnWatchRefresh	= IupButton( null, "WatchRefresh" );
		
		IupSetAttributes( btnAdd, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_add" );			IupSetAttribute( btnAdd, "TIP", GLOBAL.languageItems["add"].toCString );
		IupSetAttributes( btnDel, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_delete" );				IupSetAttribute( btnDel, "TIP", GLOBAL.languageItems["remove"].toCString );
		IupSetAttributes( btnDelAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_deleteall" );		IupSetAttribute( btnDelAll, "TIP", GLOBAL.languageItems["removeall"].toCString );
		IupSetAttributes( btnWatchRefresh, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_refresh" );	IupSetAttribute( btnWatchRefresh, "TIP", GLOBAL.languageItems["refresh"].toCString );			

		Ihandle* hBoxVar1_toolbar = IupHbox( IupFill(), btnAdd, btnDel, /*btnUp, btnDown, */btnDelAll, btnWatchRefresh, null );
		IupSetAttributes( hBoxVar1_toolbar, "ALIGNMENT=ACENTER,GAP=2" );

		
		IupSetCallback( btnAdd, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				scope varDlg = new CVarDlg( 260, -1, "Add Display Variable...", "Var Name:" );
				char[] varName = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

				if( varName == "#_close_#" ) return IUP_DEFAULT;

				GLOBAL.debugPanel.sendCommand( "display " ~ upperCase( Util.trim( varName ) ) ~ "\n", false );
				return IUP_IGNORE;
			}
			return IUP_DEFAULT;
		});

		IupSetCallback( btnDel, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			int itemNumber = IupGetInt( GLOBAL.debugPanel.watchTreeHandle, "VALUE" );
			char[] numID = GLOBAL.debugPanel.getWatchItemID( itemNumber );
			if( numID.length ) GLOBAL.debugPanel.sendCommand( "delete display " ~ Util.trim( numID ) ~ "\n", false );

			return IUP_DEFAULT;
		});

		IupSetCallback( btnDelAll, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.debugPanel.sendCommand( "delete display\n", false );
			return IUP_DEFAULT;
		});
		
		IupSetCallback( btnWatchRefresh, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				IupSetAttribute( GLOBAL.debugPanel.watchTreeHandle, "DELNODE", "ALL" );
				GLOBAL.debugPanel.sendCommand( "display\n", false ); // Check display result
			}
			return IUP_DEFAULT;
		});			

		
		Ihandle* vbox_var1 = IupVbox( hBoxVar1_toolbar, watchTreeHandle, null );
		Ihandle* var1Frame = IupFrame( vbox_var1 );
		IupSetAttribute( var1Frame, "TITLE", GLOBAL.languageItems["watchlist"].toCString );
		IupSetAttribute( var1Frame, "EXPANDCHILDREN", "YES");
		Ihandle* var1ScrollBox = IupFlatScrollBox( var1Frame );
	

		varSplit = IupSplit( var1ScrollBox, var0ScrollBox );
		IupSetAttributes( varSplit, "ORIENTATION=VERTICAL,VALUE=500,LAYOUTDRAG=NO" );
		IupSetAttribute( varSplit, "COLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetInt( varSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
		
		Ihandle* WatchVarBackground = IupBackgroundBox( varSplit );

		//Ihandle* HBoxVar = IupHbox( var1Frame, var0Frame, null );


		// Breakpoint
		bpTable = new CTable();
		bpTable.setDBLCLICK_CB( &CDebugger_breakpoint_doubleClick );
		//bpTable.setAction( &CDebugger_memberSelect );
		//version(Windows) bpTable.setBUTTON_CB( &CDebugger_memberButton );
		
		
		bpTable.addColumn( GLOBAL.languageItems["id"].toDString );
		bpTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		bpTable.addColumn( GLOBAL.languageItems["line"].toDString );
		bpTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		bpTable.setSplitAttribute( "VALUE", "500" );
		bpTable.addColumn( GLOBAL.languageItems["fullpath"].toDString );
		bpTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		bpTable.setSplitAttribute( "VALUE", "100" );
		//bpTable.setItemAttribute( "BGCOLOR", "204 255 255", 0 );
		//bpTable.setItemAttribute( "BGCOLOR", "255 255 204", 1 );
		bpScrollBox = IupFlatScrollBox( bpTable.getMainHandle );
		
		regTable = new CTable();
		//regTable.setAction( &CDebugger_memberSelect );
		//version(Windows) regTable.setBUTTON_CB( &CDebugger_memberButton );
		regTable.setDBLCLICK_CB( &CDebugger_register_doubleClick );
		
		regTable.addColumn( GLOBAL.languageItems["id"].toDString );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.addColumn( GLOBAL.languageItems["name"].toDString );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.setSplitAttribute( "VALUE", "500" );
		regTable.addColumn( GLOBAL.languageItems["value"].toDString );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.setSplitAttribute( "VALUE", "400" );
		regTable.addColumn( GLOBAL.languageItems["value"].toDString );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.setSplitAttribute( "VALUE", "300" );
		/*
		regTable.setItemAttribute( "FGCOLOR", "0 102 0", 1 );
		regTable.setItemAttribute( "FGCOLOR", "0 0 255", 2 );
		regTable.setItemAttribute( "FGCOLOR", "90 90 90", 3 );
		*/
		regScrollBox = IupFlatScrollBox( regTable.getMainHandle );
		
		
		disasHandle = IupText( null );
		IupSetStrAttribute( disasHandle, "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( disasHandle, "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetAttributes( disasHandle, "EXPAND=YES,MULTILINE=YES,READONLY=YES,FORMATTING=YES" );

		setFont();

		tabResultsHandle = IupFlatTabs( bpScrollBox, WatchVarBackground, regScrollBox, disasHandle, null );
		IupSetAttributes( tabResultsHandle, "TABTYPE=BOTTOM,EXPAND=YES,TABSPADDING=6x2" );
		IupSetCallback( tabResultsHandle, "TABCHANGEPOS_CB", cast(Icallback) &resultTabChange_cb );
		IupSetAttribute( tabResultsHandle, "TABTITLE0", GLOBAL.languageItems["bp"].toCString );
		IupSetAttribute( tabResultsHandle, "TABTITLE1", GLOBAL.languageItems["variable"].toCString );
		IupSetAttribute( tabResultsHandle, "TABTITLE2", GLOBAL.languageItems["register"].toCString );
		IupSetAttribute( tabResultsHandle, "TABTITLE3", GLOBAL.languageItems["disassemble"].toCString );
		IupSetAttribute( tabResultsHandle, "HIGHCOLOR", "255 0 0" );
		IupSetStrAttribute( tabResultsHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( tabResultsHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetAttribute( tabResultsHandle, "SHOWLINES", "NO" );
		
		

		rightSplitHandle = IupSplit( backtraceHandle, tabResultsHandle  );
		IupSetAttributes( rightSplitHandle, "ORIENTATION=HORIZONTAL,VALUE=150,LAYOUTDRAG=NO" );
		IupSetAttribute( rightSplitHandle, "COLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetInt( rightSplitHandle, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
		
		mainSplit = IupSplit( leftScrollBox, rightSplitHandle );
		IupSetAttributes( mainSplit, "ORIENTATION=VERTICAL,VALUE=220,LAYOUTDRAG=NO" );
		IupSetAttribute( mainSplit, "COLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetInt( mainSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
		

		mainHandle = IupFlatScrollBox( mainSplit );
		IupSetAttribute( mainHandle, "TABTITLE", GLOBAL.languageItems["caption_debug"].toCString );
		IupSetAttribute( mainHandle, "TABIMAGE", "icon_debug" );
	}

	char[] getWhatIs( char[] varName )
	{
		int colonspacePos = Util.index( varName, ": " );
		if( colonspacePos < varName.length ) varName = varName[colonspacePos+2..$];
	
		char[] type = GLOBAL.debugPanel.sendCommand( "whatis " ~ varName ~ "\n", false );
		if( type.length > 5 )
		{
			type = Util.trim( type[0..length-5] ); // remove (gdb)
		
			int posAssign = Util.index( type, " = " );
			if( posAssign < type.length ) return type[posAssign+3..$].dup;
		}
		return "?";
	}

	char[] getPrint( char[] varName )
	{
		char[] value = GLOBAL.debugPanel.sendCommand( "print " ~ varName ~ "\n", false );

		if( value.length > 5 )
		{
			value = value[0..length-5]; // remove (gdb)
			
			int posAssign = Util.index( value, " = " );
			if( posAssign < value.length ) return value[posAssign+3..$].dup;
		}
		return "?";
	}
	
	
	/*
		BackTrace Function
	*/
	int getRealActiveFrameTreeID()
	{
		for( int i = IupGetInt( backtraceHandle, "COUNT" ) - 1; i > 0; -- i )
		{
			if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ) == "0 0 255" ) return i;
		}
		
		return -1;
	}
	
	
	char[] getRealFrameIDFromTreeID( int treeID )
	{
		if( treeID > 0 )
		{
			char[] _title = fromStringz( IupGetAttributeId( backtraceHandle, "TITLE", treeID ) ).dup;
			if( _title.length )
			{
				if( _title[0] == '#' )
				{
					int doublespacePos = Util.index( _title, "  " );
					if( doublespacePos < _title.length ) return _title[1..doublespacePos];
				}
			}				
		}
		
		return null;
	}		
	
	
	/*
	0 = File Fullpath
	1 = Line Number
	2 = ID ( NO # )
	3 = Function 
	*/
	char[][] getFrameInformation( char[] title = "" )
	{
		if( bRunning )
		{
			char[][] results;
			
			if( !title.length )
			{
				int treeID = getRealActiveFrameTreeID();
				if( treeID > 0 ) title = fromStringz( IupGetAttributeId( backtraceHandle, "TITLE", treeID ) ).dup;
			}
			
			int atPos = Util.rindex( title, " at " );
			if( atPos < title.length )
			{
				int colonPos = Util.rindex( title, ":" );
				if( colonPos < title.length && colonPos > atPos )
				{
					int doubleSpacePos = Util.index( title, "  " );
					if( doubleSpacePos < title.length )
					{
						results ~= title[atPos+4..colonPos].dup;
						results ~= title[colonPos+1..$].dup;
						results ~= title[1..doubleSpacePos].dup;
						results ~= title[doubleSpacePos+2..atPos].dup;
						
						return results;
					}
				}
			}
		}

		return null;
	}


	void updateSYMBOL()
	{
		char[][] results = getFrameInformation();

		if( results.length == 4 )
		{
			int			lineNumber = Integer.atoi( results[1] );
			scope		fp = new FilePath( results[0] );
			
			if( !fp.folder.length ) fp.set( DebugControl.cwd ~ fp.toString );

			if( ScintillaAction.openFile( fp.toString, lineNumber ) )
			{	
				//#define SCI_MARKERDELETEALL 2045
				int dummy = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPathByOS(fp.toString)].getIupScintilla, 2045, 3, 0 );
				dummy = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPathByOS(fp.toString)].getIupScintilla, 2045, 4, 0 );
			
				dummy = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPathByOS(fp.toString)].getIupScintilla, 2043, lineNumber - 1, 3 ); // #define SCI_MARKERADD 2043
				dummy = IupScintillaSendMessage( GLOBAL.scintillaManager[fullPathByOS(fp.toString)].getIupScintilla, 2043, lineNumber - 1, 4 ); // #define SCI_MARKERADD 2043
			}
		}
	}
	
	
	// No parameter = get active node( Blue word )
	char[] getFrameNodeTitle( bool bFull = false )
	{
		int treeID = getRealActiveFrameTreeID();
		if( treeID > 0 )
		{
			char[] _title = fromStringz( IupGetAttributeId( backtraceHandle, "TITLE", treeID ) ).dup;
			if( !bFull )
			{
				int colonPos = Util.rindex( _title, ":" );
				if( colonPos < _title.length ) return _title[0..colonPos].dup;
			}
			else
			{
				return _title;
			}
		}
		
		return null;
	}
	
	
	char[] fixGDBMessage( char[] _result )
	{
		char[][] results = Util.splitLines( _result );
		results.length = results.length - 1; // remove (gdb)

		_result = "";

		if( results.length > 0 )
		{
			char[]		trueLineData;

			foreach_reverse( char[] s; results )
			{
				trueLineData = s ~ trueLineData;
				
				if( s.length )
				{
					if( s[0] != ' ' )
					{
						_result = _result.length ? _result ~ "\n" ~ trueLineData : trueLineData;
						trueLineData = "";
					}
					else
					{
						trueLineData = " " ~ Util.trim( trueLineData );
					}
				}
			}
		}

		return  _result;
	}
	
	
	VarObject transformNodeToVarObject( char[] title )
	{
		VarObject _vo;
		
		int assignPos = Util.index( title, " = " );
		if( assignPos < title.length )
		{
			_vo.name = title[0..assignPos].dup;
			if( _vo.name.length )
			{
				int colonspacePos = Util.index( _vo.name, ": " );
				if( colonspacePos < assignPos ) _vo.name = _vo.name[colonspacePos+2..$].dup;
			}
			
			int openPos = Util.index( title, " (" );
			if( openPos < title.length )
			{
				int closePos = Util.rindex( title, ") " );
				if( closePos < title.length )
				{
					_vo.type = title[openPos+2..closePos].dup;
					_vo.value = title[closePos+2..$].dup;
				}
			}
			else
			{
				_vo.value = Util.trim( title[assignPos+3..$].dup );
			}
		}
		
		return _vo;
	}


	VarObject getTypeVarValueByName( char[] name )
	{
		VarObject result;
		
		result.name = name;

		char[] value = getPrint( name );
		if( value != "?" )
		{
			result.value = value;
			
			if( value[0] == '(' )
			{
				int closePos = Util.rindex( value, ") " );
				if( closePos < value.length )
				{
					result.value = value[closePos+2..$].dup;
					result.type = value[1..closePos].dup;
				}
			}
		}
		
		if( result.type.length )
		{
			char[] type = getWhatIs( name );
			if( type != "?" ) result.type = type;	
		}
		
		return result;
	}
	
	
	VarObject[] getTypeVarValueByLinesFromInfo( char[] gdbMessage )
	{
		if( !isRunning ) return null;
		
		VarObject[] results;
		
		foreach( char[] s; Util.splitLines( fixGDBMessage( gdbMessage ) ) )
		{
			int closePos = s.length;
			int assignPos = Util.index( s, " = " );
			if( assignPos < s.length )
			{
				VarObject _vo;
				_vo.name = Util.trim( s[0..assignPos] );
				
				// <gdb>display, sometimes we got type of vars
				if( Util.index( s, " = (" ) == assignPos ) closePos = Util.rindex( s, ") " );
				
				if( closePos < s.length )
				{
					_vo.value = Util.trim( s[closePos+2..$].dup );
					_vo.type = s[assignPos+4..closePos].dup;
				}
				else
				{
					_vo.value = Util.trim( s[assignPos+3..$].dup );
					_vo.type = getWhatIs( _vo.name );
				}
					
				if( _vo.value.length)
				{
					if( _vo.value[0] == '{' ) _vo.value = "{...}";
				}

				results ~= _vo;
			}
		}			
		
		return results;
	}
	
	
	VarObject[] getTypeVarValueByLinesFromPrint( char[] gdbMessage, char[] motherName )
	{
		if( !isRunning )		return null;
		if( gdbMessage == "?" )	return null;
		
		gdbMessage = fixGDBMessage( gdbMessage );

		char[]			data;
		VarObject[]		vos;

		/*
		{SCI = 0x2ab2bb0, _P = {X = 100, Y = 200}, P = 0x1eaf584}						
		*/
		for( int i = 1; i < gdbMessage.length; ++ i )
		{
			char[] _type, _var, _value;
			
			if( i == gdbMessage.length - 1 )
			{
				if( data.length )
				{
					int assignPos = Util.index( data, " = " );
					if( assignPos < data.length )
					{
						if( Util.index( data, "[" ) < data.length  )
						{
							_var = Util.trim( data[0..assignPos] );
							_value = data[assignPos+3..$];
							VarObject _vo = { "", _var, _value };
							vos = _vo ~ vos;
						}
						else
						{
							_type = GLOBAL.debugPanel.getWhatIs( motherName ~ "." ~ data[0..assignPos] );
							_var = Util.trim( data[0..assignPos] );
							_value = data[assignPos+3..$];
							VarObject _vo = { _type, _var, _value };
							vos = _vo ~ vos;
						}
					}
					else
					{
						VarObject _vo = { "", "", Util.trim( data ) };
						vos = _vo ~ vos;
					}
				}
			}
			else if( gdbMessage[i] == ','  )
			{
				char[] type;
				int assignPos = Util.index( data, " = " );
				if( assignPos < data.length )
				{
					if( Util.index( data, "[" ) < data.length  )
					{
						//results ~= Util.trim( data );
						_var = Util.trim( data[0..assignPos] );
						_value = data[assignPos+3..$];
						VarObject _vo = { "", _var, _value };
						vos = _vo ~ vos;
					}
					else
					{
						_type = GLOBAL.debugPanel.getWhatIs( motherName ~ "." ~ data[0..assignPos] );
						_var = Util.trim( data[0..assignPos] );
						_value = data[assignPos+3..$];
						VarObject _vo = { _type, _var, _value };
						vos = _vo ~ vos;
					}
				}
				else
				{
					VarObject _vo = { "", "", Util.trim( data ) };
					vos = _vo ~ vos;
				}
				data = "";
			}
			else if( gdbMessage[i] == '{' )
			{
				int		open = 0;

				for( int j = i; j < gdbMessage.length -1; ++ j )
				{
					if( gdbMessage[j] == '{' )
					{
						open ++;
					}
					else if( gdbMessage[j] == '}' )
					{
						open --;

						if( open == 0 )
						{
							int assignPos = Util.index( data, " = " );
							if( assignPos < data.length )
							{
								if( Util.index( data, "[" ) < data.length ) _type = ""; else _type = GLOBAL.debugPanel.getWhatIs( motherName ~ "." ~ data[0..assignPos] );
								_var = Util.trim( data[0..assignPos] );
							}
							else
							{
								_var = data;
							}

							VarObject _vo = { _type, _var, "{...}" };
							vos = _vo ~ vos;
							i = j + 1;
							data = "";
							break;
						}
					}
				}
			}
			else
			{
				data ~= gdbMessage[i];
			}
		}
	
		return vos;
	}
	
	
	void checkErrorOccur( char[] message, char[] errorMessage = null )
	{
		//int head = Util.index( message, "Program received signal SIGSEGV, Segmentation fault." );
		//int head = Util.index( message, "Segmentation fault." );
		int head = Util.index( message, "signal SIGSEGV," );
		if( head < message.length )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..length-5].dup ) );
			return;
		}

		//int head = Util.index( message, "Floating point exception" );
		head = Util.index( message, "signal SIGFPE," );
		if( head < message.length )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..length-5].dup ) );
			return;
		}
		
		head = Util.index( message, "signal SIGABRT," );
		if( head < message.length )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..length-5].dup ) );
			return;
		}
		
		
		head = Util.index( message, "The program is not being run." );
		if( head < message.length )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..length-5].dup ) );
			return;
		}
	}
	
	
	char[] removeIDTitle( char[] s )
	{
		int assignPos = Util.index( s, " = " );
		if( assignPos < s.length )
		{
			int colonspacePos = Util.index( s, ": " );
			if( colonspacePos < assignPos ) return s[colonspacePos+2..$].dup;
		}
		
		return s;
	}
	
	
	char[] getWatchItemID( char[] s )
	{
		if( s.length )
		{
			if( s[0] > 47 && s[0] < 58 )
			{
				int colonSpacePos = Util.index( s, ": " );
				if( colonSpacePos < s.length ) return s[0..colonSpacePos];
			}
		}
		
		return null;
	}
	
	
	char[] getWatchItemID( int id )
	{
		if( id > -1 )
		{
			char[] title = fromStringz( IupGetAttributeId( watchTreeHandle, "TITLE", id ) ).dup;
			return getWatchItemID( title);
		}
		
		return null;
	}
	
	
	// Update locals tree
	void updateInfoTree( VarObject[] variables, Ihandle* treeHandle, int motherID )
	{
		if( bRunning )
		{
			bool	bNoSameDeepNode = false;
			
			for( int i = variables.length - 1; i >= 0; -- i )
			{
				if( !bNoSameDeepNode )
				{
					char[]	numID;
					int		colonspacePos = Util.index( variables[i].name, ": " );
					if( colonspacePos < variables[i].name.length )
					{
						numID = variables[i].name[0..colonspacePos+2].dup;
						variables[i].name = variables[i].name[colonspacePos+2..$].dup;
					}
					
					auto _voFromNode = transformNodeToVarObject( fromStringz( IupGetAttributeId( treeHandle, "TITLE", motherID ) ).dup );
					
					if( variables[i].name == _voFromNode.name && variables[i].type == _voFromNode.type )//&& _vo.file = _voFromNode.file && _vo.frame == _voFromNode.frame )
					{
						char[] _title = numID ~ variables[i].name ~ " = " ~ ( variables[i].type.length ? "(" ~  variables[i].type ~ ") " : "" ) ~ variables[i].value;
						IupSetAttributeId( treeHandle, "TITLE", motherID, toStringz( _title ) );
						if( variables[i].value != _voFromNode.value ) IupSetAttributeId( treeHandle, "COLOR", motherID, "255 0 0" ); else IupSetStrAttributeId( treeHandle, "COLOR", motherID, GLOBAL.editColor.dlgFore.toCString );
						if( treeHandle == watchTreeHandle && numID.length )
						{
							char[] fontString = Util.substitute( GLOBAL.fonts[9].fontString.dup, ",", ",Bold " );
							IupSetStrAttributeId( treeHandle, "TITLEFONT", motherID, toStringz( fontString ) );
						}
						else
						{
							IupSetStrAttributeId( treeHandle, "TITLEFONT", motherID, toStringz( GLOBAL.fonts[9].fontString ) );
						}
					}
					else
					{
						// Insert same deep
						char[] _title = numID ~ variables[i].name ~ " = " ~ ( variables[i].type.length ? "(" ~  variables[i].type ~ ") " : "" ) ~ variables[i].value;
						if( variables[i].value == "{...}" ) IupSetAttributeId( treeHandle, "INSERTBRANCH", motherID, toStringz( _title.dup ) ); else IupSetAttributeId( treeHandle, "INSERTLEAF", motherID, toStringz( _title.dup ) );
						if( treeHandle == watchTreeHandle && numID.length )
						{
							char[] fontString = Util.substitute( GLOBAL.fonts[9].fontString.dup, ",", ",Bold " );
							IupSetStrAttributeId( treeHandle, "TITLEFONT", motherID, toStringz( fontString ) );
						}
						else
						{
							IupSetStrAttributeId( treeHandle, "TITLEFONT", motherID, toStringz( GLOBAL.fonts[9].fontString ) );
						}
						
						// Remove old node 
						IupSetAttributeId( treeHandle, "DELNODE", motherID, "SELECTED" );
					}
					
					// No EXPANDED, No check
					if( fromStringz( IupGetAttributeId( treeHandle, "KIND", motherID ) ) == "BRANCH" )
					{
						if( fromStringz( IupGetAttributeId( treeHandle, "STATE", motherID ) ) == "EXPANDED" )
						{
							char[] fullVarName = getFullVarNameInTree( treeHandle, motherID );
							//if( variables[i].name[0] == '*' ) fullVarName = "*" ~ fullVarName;
							
							VarObject[] _vos = getTypeVarValueByLinesFromPrint( getPrint( variables[i].name[0] == '*' ? "*" ~ fullVarName : fullVarName ), fullVarName );
							if( _vos.length ) updateInfoTree( _vos, treeHandle, motherID + 1 );
						}
					}


					if( IupGetAttributeId( treeHandle, "NEXT", motherID ) == null )
						bNoSameDeepNode = true;
					else
					{
						if( i > 0 ) motherID = IupGetIntId( treeHandle, "NEXT", motherID );
					}
				}
				else
				{
					char[] _title = variables[i].name ~ " = " ~ ( variables[i].type.length ? "(" ~  variables[i].type ~ ") " : "" ) ~ variables[i].value;
					if( variables[i].value == "{...}" ) IupSetAttributeId( treeHandle, "INSERTBRANCH", motherID, toStringz( _title ) ); else IupSetAttributeId( treeHandle, "INSERTLEAF", motherID, toStringz( _title ) );
					IupSetStrAttributeId( treeHandle, "TITLEFONT", motherID, toStringz( GLOBAL.fonts[9].fontString ) );
				}
			}
			
			if( !bNoSameDeepNode )
			{
				// Remove Additive nodes...
				while( IupGetAttributeId( treeHandle, "NEXT", motherID ) != null )
				{
					int beKillNodeId = IupGetIntId( treeHandle, "NEXT", motherID );
					IupSetAttributeId( treeHandle, "DELNODE", beKillNodeId, "SELECTED" );
				}
			}
		}
	}


	void showDisassemble()
	{
		if( GLOBAL.debugPanel.isRunning && GLOBAL.debugPanel.isExecuting )
		{
			char[][] frameInformation = getFrameInformation();
			if( frameInformation.length == 4 )
			{
				char[][] results = Util.splitLines( GLOBAL.debugPanel.fixGDBMessage( GLOBAL.debugPanel.sendCommand( "info line " ~ frameInformation[1] ~ "\n", false ) ) );

				if( results.length == 1 ) // NO ERROR
				{
					char[] startAddress, endAddress;
					
					//IupSetAttribute( GLOBAL.debugPanel.disasHandle, "VALUE", toStringz( results[0] ~ "\n" ) );
					
					int startPos = Util.index( results[0], "starts at address " );
					int endPos = Util.index( results[0], "ends at " );
					if( endPos > startPos && startPos < results[0].length )
					{
						int startSpacePos = Util.index( results[0], " ", startPos + 18 );
						if( startSpacePos < results[0].length ) startAddress = results[0][startPos+18..startSpacePos].dup;
						
						int endSpacePos = Util.index( results[0], " ", endPos + 8 );
						if( endSpacePos < results[0].length ) endAddress = results[0][endPos+8..endSpacePos].dup;
						
						if( startAddress.length && endAddress.length )
						{
							char[] result = GLOBAL.debugPanel.sendCommand( "disassemble /m " ~ startAddress ~ "," ~ endAddress ~ "\n", false );
							if( result.length > 5 )
							{
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "VALUE", toStringz( results[0] ~ "\n\n" ~ result[0..$-5] ) );
								IupSetInt( GLOBAL.debugPanel.disasHandle, "SCROLLTOPOS", 0 );

								Ihandle* formattag0;
								formattag0 = IupUser();
								IupSetStrAttribute( formattag0, "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
								IupSetAttribute( formattag0, "SELECTION", "ALL" );
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "ADDFORMATTAG_HANDLE", cast(char*)formattag0);
								
								Ihandle* formattag;
								formattag = IupUser();
								IupSetAttribute( formattag, "FGCOLOR", "99 37 35" );
								IupSetAttribute( formattag, "UNDERLINE", "SINGLE" );
								IupSetAttribute( formattag, "WEIGHT", "SEMIBOLD" );
								IupSetAttribute( formattag, "SELECTION", "1,1:1,500" );
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "ADDFORMATTAG_HANDLE", cast(char*)formattag);

								Ihandle* formattag1;
								formattag1 = IupUser();
								IupSetAttribute( formattag1, "FGCOLOR", "45 117 27" );
								IupSetAttribute( formattag1, "WEIGHT", "SEMIBOLD" );
								IupSetAttribute( formattag1, "SELECTION", "4,1:4,500" );
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "ADDFORMATTAG_HANDLE", cast(char*)formattag1);
							}
						}
					}
				}
			}
		}
	}
	
	void changeTreeNodeColor( Ihandle* TREE )
	{
		for( int i = 0; i < IupGetInt( TREE, "COUNT" ); ++ i )	
			if( fromStringz( IupGetAttributeId( TREE, "COLOR", i ) ) != "255 0 0" ) IupSetStrAttributeId( TREE, "COLOR", i, GLOBAL.editColor.dlgFore.toCString );
	}

	public:
	this()
	{
		createLayout();
	}
	
	void changeColor()
	{
		IupSetStrAttribute( varTabHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( varTabHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetStrAttribute( tabResultsHandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( tabResultsHandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		
		IupSetAttribute( varSplit, "COLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetAttribute( rightSplitHandle, "COLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetAttribute( mainSplit, "COLOR", GLOBAL.editColor.linenumBack.toCString );
		
		changeTreeNodeColor( watchTreeHandle );
		changeTreeNodeColor( localTreeHandle );
		changeTreeNodeColor( argTreeHandle );
		changeTreeNodeColor( shareTreeHandle );
		
		for( int i = 0; i < IupGetInt( backtraceHandle, "COUNT" ); ++ i )	
			if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ) != "0 0 255" ) IupSetStrAttributeId( backtraceHandle, "COLOR", i, GLOBAL.editColor.dlgFore.toCString );
		
	}

	void setFont()
	{
		char* _font = toStringz( GLOBAL.fonts[9].fontString );
		IupSetStrAttribute( consoleHandle, "FONT", _font );
		IupSetStrAttribute( watchTreeHandle, "FONT",  _font );
		IupSetStrAttribute( localTreeHandle, "FONT",  _font );
		IupSetStrAttribute( argTreeHandle, "FONT",  _font );
		IupSetStrAttribute( shareTreeHandle, "FONT",  _font );
		//IupSetAttribute( varTabHandle, "FONT",  _font );
		//IupSetStrAttribute( disasHandle, "FONT",  _font );
		
		for( int i = 0; i < IupGetInt( watchTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( watchTreeHandle, "TITLEFONT", i, _font );

		for( int i = 0; i < IupGetInt( localTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( localTreeHandle, "TITLEFONT", i, _font );

		for( int i = 0; i < IupGetInt( argTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( argTreeHandle, "TITLEFONT", i, _font );

		for( int i = 0; i < IupGetInt( shareTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( shareTreeHandle, "TITLEFONT", i, _font );
	}		

	Ihandle* getMainHandle()
	{
		return mainHandle;
	}

	Ihandle* getConsoleHandle()
	{
		return consoleHandle;
	}


	Ihandle* getBacktraceHandle()
	{
		return backtraceHandle;
	}


	CTable getBPTable()
	{
		return bpTable;
	}


	Ihandle* getConsoleCommandInputHandle()
	{
		return txtConsoleCommand;
	}


	Ihandle* getVarsTabHandle()
	{
		return varTabHandle;
	}

	
	char[] getTypeValueByName( char[] varName, char[] originTitle, ref char[] type, ref char[] value )
	{
		char[] nodeTitle, THIS;
		
		
		int assignPos = Util.index( originTitle, "=" );
		if( assignPos < originTitle.length ) originTitle = Util.trim( originTitle[0..assignPos] ).dup;
		
		/*
		(gdb)p SCINTILLA
		$12 = (CSCINTILLA *) 0x1e7f580
		(gdb)p *SCINTILLA
		$13 = {SCI = 0x2a82bb0, _P = {X = 100, Y = 200}, P = 0x1e7f584}
		(gdb)		
		*/
		value = GLOBAL.debugPanel.getPrint( varName ); // No result, return '?'
		if( value == "?" )
		{
			value = GLOBAL.debugPanel.getPrint( "THIS." ~ varName );
			THIS = "THIS.";
		}
		
		if( value != "?" )
		{
			type = GLOBAL.debugPanel.getWhatIs( THIS ~ varName );
			int dotPos = Util.rindex( varName, "." );
			if( value[0] == '{' )
			{
				//value = "{...}";
				if( Util.contains( originTitle, '.' ) )
				{
					//nodeTitle = originTitle ~ " = (" ~  type ~ ") {...}";
					nodeTitle = originTitle ~ " = (" ~  type ~ ") " ~ value;
				}
				else
				{
					//if( dotPos < varName.length ) nodeTitle = varName[dotPos+1..$] ~ " = (" ~  type ~ ") {...}"; else nodeTitle = varName ~ " = (" ~  type ~ ") {...}";
					if( dotPos < varName.length ) nodeTitle = varName[dotPos+1..$] ~ " = (" ~  type ~ ") " ~ value; else nodeTitle = varName ~ " = (" ~  type ~ ") " ~ value;
				}
			}
			else
			{
				if( Util.contains( value, ')' ) )
				{
					if( Util.contains( originTitle, '.' ) )
						nodeTitle = originTitle ~ " = " ~ value;
					else
					{
						if( dotPos < varName.length ) nodeTitle = varName[dotPos+1..$] ~ " = " ~ value; else nodeTitle = varName ~ " = " ~ value;
					}
				}
				else
				{
					if( Util.contains( originTitle, '.' ) )
						nodeTitle = originTitle ~ " = (" ~  type ~ ") " ~ value;
					else
					{
						if( dotPos < varName.length ) nodeTitle = varName[dotPos+1..$] ~ " = (" ~  type ~ ") " ~ value; else nodeTitle = varName ~ " = (" ~  type ~ ") " ~ value;
					}
				}
				
				int closeParenPos = Util.rindex( value, ")" );
				if( closeParenPos < value.length ) value = Util.trim( value[closeParenPos+1..$] ).dup;
			}
			
			return Util.trim( nodeTitle );
		}
		
		value = type = "";
		return null;
	}
	
	char[] getFullVarNameInTree( Ihandle* _tree, int id = -99, bool bNoStar = false )
	{
		if( GLOBAL.debugPanel.isRunning )
		{
			if( _tree != null )
			{
				if( id < 0 ) id = IupGetInt( _tree, "VALUE" );

				if( id > -1 )
				{
					bNoStar = true;
					
					char[]	title;
					char[]	varName;
					int		parnetID = id, _depth = IupGetIntId( _tree, "DEPTH", id );
					while( _depth >= 0 )
					{
						title = fromStringz( IupGetAttributeId( _tree, "TITLE", parnetID ) ).dup; // Get Tree Title
						int assignPos = Util.index( title, " = " );
						if( assignPos < title.length )
						{
							// Remove ID
							int colonspacePos = Util.index( title, ": " );
							if( colonspacePos < assignPos )
							{
								title = title[colonspacePos+2..$].dup;
								assignPos = Util.index( title, " = " );
							}
						
							varName = Util.trim( varName );
							if( varName.length )
							{
								varName = ( ( varName[0] == '[' ) ? (title[0..assignPos] ~ varName ) : ( title[0..assignPos] ~ "." ~ varName ) );
							}
							else
							{
								varName = title[0..assignPos];
							}
							
							if( bNoStar )
							{
								varName = Util.stripl( varName, '*' );
								varName = Util.stripl( varName, '&' );
							}
						}

						if( _depth <= 0 ) break;
						parnetID = IupGetIntId( _tree, "PARENT", parnetID );
						_depth = IupGetIntId( _tree, "DEPTH", parnetID );
					}

					if( varName.length )
					{
						if( varName[$-1] == '.' ) varName = varName[0..$-1];
						
						/*
						if( bNoStar )
							if( title.length )
								if( title[0] == '*' || title[0] == '&' ) varName = title[0] ~ varName;
						*/
						
						return varName;
					}
				}
			}
		}
		
		return null;
	}
	

	char[] sendCommand( char[] command, bool bShow = true  )
	{
		if( DebugControl is null ) return null;

		char[] result = DebugControl.sendCommand( command, bShow );

		// Check GDB reach end
		int gdbEndStringPosTail = Util.rindex( result, "exited normally]" );
		if( gdbEndStringPosTail < result.length )
		{
			int gdbEndStringPosHead = Util.rindex( result, "[Inferior" );
			if( gdbEndStringPosHead < result.length )
			{
				int _result = IupMessageAlarm( null, "GDB", toStringz( result[gdbEndStringPosHead..gdbEndStringPosTail+16].dup ~ "\n" ~ GLOBAL.languageItems["exitdebug1"].toDString ), "OKCANCEL" );
				if( _result == 1 )
				{
					terminal();
					return null;
				}					
			}
		}
		
		char[][] splitCommand;
		foreach( char[] s; Util.split( Util.trim( command ), " " ) ) // Util.trim() remove \n
		{
			if( s.length ) splitCommand ~= s;
		}


		if( splitCommand.length )
		{
			switch( lowerCase( splitCommand[0] ) )
			{
				case "r", "run":
					bRunning = true;
					GLOBAL.debugPanel.updateBackTrace();

					int pos = IupGetInt( tabResultsHandle, "VALUEPOS" );
					if( pos > -1 ) resultTabChange_cb( tabResultsHandle, pos, -1 );

					checkErrorOccur( result );
					break;

				case "c", "continue":
					if( bRunning && isExecuting )
					{
						GLOBAL.debugPanel.updateBackTrace();
						int pos = IupGetInt( tabResultsHandle, "VALUEPOS" );
						if( pos > -1 ) resultTabChange_cb( tabResultsHandle, pos, -1 );

						// Check display result
						sendCommand( "display\n", false );
					}
					checkErrorOccur( result );
					break;				
				
				case "b", "bre", "break":
					if( result.length > 5 ) // result.length = 5 => result = (gdb)
					{
						if( splitCommand.length == 2 )
						{
							char[] _id, _fullPath, _lineNumber;
							
							int tail = Util.index( result, " at" );
							int head = Util.index( result, "Breakpoint " );
							if( tail > head + 11 ) _id = result[head+11..tail];

							head = Util.rindex( result, ": file " );
							tail = Util.rindex( result, ", line " );
							if( tail > head + 7 ) _fullPath = Path.normalize( result[head+7..tail] );
							
							head = Util.rindex( result, ", line " );
							tail = Util.rindex( result, "." );
							if( tail > head + 7 ) _lineNumber = result[head+7..tail];
							
							bpTable.addItem( [ _id, _lineNumber, _fullPath ] );
							IupRefresh( bpScrollBox );
						}
					}
					break;

				case "d", "del", "delete":
					if( splitCommand.length == 2 )
					{
						if( lowerCase( splitCommand[1] ) == "display" )
						{
							IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
						}
						else
						{
							for( int i = bpTable.getItemCount(); i > 0; -- i )
							{
								char[][] values = bpTable.getSelection( i );
								if( values.length > 0 )
								{
									if( values[0] == splitCommand[1] )
									{
										bpTable.removeItem( i );
										IupRefresh( bpScrollBox );
										break;
									}
								}
							}
						}
					}
					else if( splitCommand.length > 2 )
					{
						if( lowerCase( splitCommand[1] ) == "display" )
						{
							if( bRunning )
							{
								char[][] results = Util.splitLines( result );

								results.length = results.length - 1; // remove (gdb)
								if( results.length == 0 ) // NO ERROR
								{
									char[] _id = Util.trim( splitCommand[2] );

									for( int i = IupGetInt( watchTreeHandle, "COUNT" ) - 1; i >= 0; -- i )
									{
										if( _id == getWatchItemID( i ) ) IupSetAttributeId( watchTreeHandle, "DELNODE", i, "SELECTED" );
									}
								}
							}
						}
					}
					break;
					
				case "display":
					VarObject[] variables;
					
					variables = getTypeVarValueByLinesFromInfo( result );
					
					if( splitCommand.length == 1 ) // just display
					{
						if( !variables.length )
						{
							IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
						}
						else if( IupGetInt( watchTreeHandle, "COUNT" ) == 0 )
						{
							char[] fontString = Util.substitute( GLOBAL.fonts[9].fontString.dup, ",", ",Bold " );
							foreach( VarObject _vo; variables )
							{
								char[] _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~  _vo.type ~ ") " : "" ) ~ _vo.value;
								if( _vo.value == "{...}" ) IupSetAttributeId( watchTreeHandle, "INSERTBRANCH", -1, toStringz( _title ) ); else IupSetAttributeId( watchTreeHandle, "INSERTLEAF", -1, toStringz( _title ) );
								IupSetStrAttributeId( watchTreeHandle, "TITLEFONT", 0, toStringz( fontString ) );
							}
						}
						else
						{
							updateInfoTree( variables, watchTreeHandle, 0 );
						}
					}
					else // Add
					{
						char[] fontString = Util.substitute( GLOBAL.fonts[9].fontString.dup, ",", ",Bold " );
						foreach( VarObject _vo; variables )
						{
							char[] _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~  _vo.type ~ ") " : "" ) ~ _vo.value;
							if( _vo.value == "{...}" ) IupSetAttributeId( watchTreeHandle, "INSERTBRANCH", -1, toStringz( _title ) ); else IupSetAttributeId( watchTreeHandle, "INSERTLEAF", -1, toStringz( _title ) );
							IupSetStrAttributeId( watchTreeHandle, "TITLEFONT", 0, toStringz( fontString ) );
						}
					}
					break;

				case "undisplay":
					if( bRunning )
					{
						char[][] results = Util.splitLines( result );

						results.length = results.length - 1; // remove (gdb)
						if( results.length == 0 ) // NO ERROR
						{
							char[] _id = Util.trim( splitCommand[2] );

							for( int i = IupGetInt( watchTreeHandle, "COUNT" ) - 1; i >= 0; -- i )
							{
								if( _id == getWatchItemID( i ) ) IupSetAttributeId( watchTreeHandle, "DELNODE", i, "SELECTED" );
							}
						}
					}
					break;
				
				case "frame", "select-frame":
					if( bRunning && isExecuting )
					{
						if( splitCommand.length == 2 )
						{
							bool bChange;
							
							for( int i = 1; i < IupGetInt( backtraceHandle, "COUNT" ); ++ i )
							{
								char[][] _information = getFrameInformation( fromStringz( IupGetAttributeId( backtraceHandle, "TITLE", i ) ).dup );
								if( _information.length == 4 )
								{
									if( _information[2] == splitCommand[1] )
									{
										if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ).dup != "0 0 255" )
										{
											IupSetAttributeId( backtraceHandle, "COLOR", i, "0 0 255" );
											version(Windows) IupSetAttributeId( backtraceHandle, "MARKED", i, "YES" ); else IupSetInt( backtraceHandle, "VALUE", i );
											bChange = true;
											continue;
										}
										else
										{
											break;
										}
									}
								}
								
								IupSetAttributeId( backtraceHandle, "COLOR", i, "0 0 0" );
							}
							
							if( bChange )
							{
								int pos = IupGetInt( tabResultsHandle, "VALUEPOS" );
								if( pos > -1 ) resultTabChange_cb( tabResultsHandle, pos, -1 );
								sendCommand( "display\n", false ); // Check display result
								updateSYMBOL();
							}
						}
					}
					break;
					
				case "up":
					if( bRunning && isExecuting )
					{
						if( splitCommand.length == 1 ) splitCommand ~= "1";
						if( splitCommand.length == 2 )
						{
							int treeID = getRealActiveFrameTreeID();
							int TargetID = treeID - Integer.toInt( splitCommand[1] );
							if( TargetID > 0 )
							{
								char[] frame = getRealFrameIDFromTreeID( TargetID );
								sendCommand(  "select-frame " ~ frame ~ "\n", false );
							}
						}
					}
					break;
					
				case "down":
					if( bRunning && isExecuting )
					{
						if( splitCommand.length == 1 ) splitCommand ~= "1";
						if( splitCommand.length == 2 )
						{
							int treeID = getRealActiveFrameTreeID();
							int TargetID = treeID + Integer.toInt( splitCommand[1] );
							if( TargetID < IupGetInt( backtraceHandle, "COUNT" ) )
							{
								char[] frame = getRealFrameIDFromTreeID( TargetID );
								sendCommand(  "select-frame " ~ frame ~ "\n", false );
							}
						}
					}
					break;
					
				case "bt", "backtrace", "where":
					if( bRunning )
					{
						char[][] results = Util.splitLines( result );

						results.length = results.length - 1; // remove (gdb)

						if( results.length > 0 )
						{
							IupSetAttributeId( backtraceHandle, "DELNODE", 0, "CHILDREN" );

							bool	bFirstInsert = true;
							char[]	branchString;

							for( int i = results.length - 1; i >= 0;  -- i )
							{
								if( results[i].length )
								{
									if( Util.trim( results[i] )[0] != '#' )
									{
										branchString = " " ~ Util.trim( results[i] ) ~ branchString;
									}
									else
									{
										branchString = results[i] ~ branchString;
										int lastID = IupGetInt( backtraceHandle, "LASTADDNODE" );
										if( bFirstInsert )
										{
											lastID = 0;
											bFirstInsert = false;
										}

										IupSetStrAttributeId( backtraceHandle, "ADDBRANCH", lastID, toStringz( branchString ) );
										lastID = IupGetInt( backtraceHandle, "LASTADDNODE" );
										IupSetAttributeId( backtraceHandle, "IMAGE", lastID, "icon_debug_bt1" );
										IupSetAttributeId( backtraceHandle, "IMAGEEXPANDED", lastID, "icon_debug_bt1" );
										if( i == 0 )
										{
											IupSetAttributeId( backtraceHandle, "COLOR", lastID, "0 0 255" );
											version(Windows) IupSetAttributeId( backtraceHandle, "MARKED", lastID, "YES" ); else IupSetInt( backtraceHandle, "VALUE", lastID );
										}
											
										branchString = "";
									}
								}
							}
						}
					}
					break;

				case "k", "kill":
					if( splitCommand.length == 1 )
					{
						if( result == "#_NO_#" ) break;
						
						bRunning = false;
						
						IupSetAttributeId( backtraceHandle, "DELNODE", 0, "CHILDREN" );
						IupSetAttribute( localTreeHandle, "DELNODE", "ALL" );
						IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
						regTable.removeAllItem();
						IupSetAttribute( disasHandle, "VALUE", "" );
						localTreeFrame = argTreeFrame = shareTreeFrame = regFrame = disasFrame = "";
						foreach( CScintilla cSci; GLOBAL.scintillaManager )
						{
							int dummy = IupScintillaSendMessage( cSci.getIupScintilla, 2045, 3, 0 ); //#define SCI_MARKERDELETEALL 2045
							dummy = IupScintillaSendMessage( cSci.getIupScintilla, 2045, 4, 0 ); //#define SCI_MARKERDELETEALL 2045
						}
					}					
					break;

				case "s", "step", "n", "next", "return", "until":
					if( splitCommand.length == 1 )
					{
						if( bRunning && isExecuting )
						{
							GLOBAL.debugPanel.updateBackTrace();
							int pos = IupGetInt( tabResultsHandle, "VALUEPOS" );
							if( pos > -1 ) resultTabChange_cb( tabResultsHandle, pos, -1 );

							// Check display result
							sendCommand( "display\n", false );
						}
					}
					checkErrorOccur( result );
					break;

				case "i", "info":
					if( splitCommand.length > 1 )
					{
						Ihandle* _treeHandle = null;
						
						switch( splitCommand[1] )
						{
							case "locals":
								_treeHandle = localTreeHandle;
								
							case "args": 
								if( _treeHandle == null ) _treeHandle = argTreeHandle;
								
								if( bRunning )
								{
									VarObject[] variables = getTypeVarValueByLinesFromInfo( result );
									
									if( !variables.length )
									{
										IupSetAttribute( _treeHandle, "DELNODE", "ALL" );
									}
									else if( IupGetInt( _treeHandle, "COUNT" ) == 0 )
									{
										foreach( VarObject _vo; variables )
										{
											char[] _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~  _vo.type ~ ") " : "" ) ~ _vo.value;
											if( _vo.value == "{...}" ) IupSetAttributeId( _treeHandle, "INSERTBRANCH", -1, toStringz( _title ) ); else IupSetAttributeId( _treeHandle, "INSERTLEAF", -1, toStringz( _title ) );
											IupSetStrAttributeId( _treeHandle, "TITLEFONT", 0, toStringz( GLOBAL.fonts[9].fontString ) );
										}
									}
									else
									{
										updateInfoTree( variables, _treeHandle, 0 );
									}
								}
								break;
								
								
							case "variables":
								if( bRunning )
								{
									char[][] results = Util.splitLines( result );
									if( results.length )
										results.length = results.length - 1; // remove (gdb)
									/*
									else
										GLOBAL.messagePanel.printOutputPanel( "LENGTH = 0" );
										
									GLOBAL.messagePanel.printOutputPanel( result );
									*/
									bool		bGlobal;
									char[]		fileFullPath;
									int			fileID = -1, id;
									
									IupSetAttribute( shareTreeHandle, "DELNODE", "ALL" );
									
									foreach( char[] lineData; results )
									{
										if( lineData == "All defined variables:" )
										{
											bGlobal = true;
											continue;
										}
										else if( lineData == "Non-debugging symbols:" )
										{
											break;
										}
										
										if( bGlobal )
										{
											if( lineData.length > 4 )
											{
												if( lineData[0..4] == "File" && lineData[$-1] == ':' )
												{
													fileFullPath = lineData[4..$-1];
													IupSetAttributeId( shareTreeHandle, "INSERTBRANCH", fileID, toStringz( fileFullPath.dup ) );
													fileID = id = IupGetInt( shareTreeHandle, "LASTADDNODE" );
													IupSetAttributeId( shareTreeHandle, "IMAGE", fileID, "icon_txt" );
													IupSetAttributeId( shareTreeHandle, "IMAGEEXPANDED", fileID, "icon_txt" );
													continue;
												}
											}
											
											if( lineData.length > 0 )
											{
												if( lineData[$-1] == ';' )
												{
													char[][] splitData = Util.split( lineData[0..$-1], " " );
													char[] varName, typeName, value;
													if( splitData.length >= 2 )
													{
														varName = splitData[$-1];
														typeName = splitData[$-2];
														
														typeName ~= " ";
														int i;
														for( i = 0; i < varName.length; ++ i )
														{
															if( varName[i] == '*' ) typeName ~= '*'; else break;
														}
														if( i > 0 ) varName = varName[i..$]; else typeName = typeName[0..$-1];

														value = getPrint( varName );
													}
													
													if( varName.length )
													{
														char[] string = varName ~ " = " ~ value;
														if( value.length )
														{
															if( value[0] == '{' )
															{
																value = "{...}";
																string = varName ~ " = (" ~  typeName ~ ") " ~ value;
															}
														}
														
														if( IupGetIntId( shareTreeHandle, "DEPTH", id ) == 0 )
														{
															if( value == "{...}" ) IupSetAttributeId( shareTreeHandle, "ADDBRANCH", id, toStringz( string.dup ) );else IupSetAttributeId( shareTreeHandle, "ADDLEAF", id, toStringz( string.dup ) );
														}
														else
														{
															if( value == "{...}" ) IupSetAttributeId( shareTreeHandle, "INSERTBRANCH", id, toStringz( string.dup ) );else IupSetAttributeId( shareTreeHandle, "INSERTLEAF", id, toStringz( string.dup ) );
														}

														id = IupGetInt( shareTreeHandle, "LASTADDNODE" );
													}														
												}
											}
										}
									}
								}
								break;

							case "r", "register", "registers", "reg":
								if( bRunning )
								{
									char[][] results = Util.splitLines( result );
									if( results.length ) results.length = results.length - 1; // remove (gdb)
									
									if( results.length)
									{
										if( splitCommand.length == 2 )
										{
											bool bFirst = true;
											if( regTable.getItemCount > 0 ) bFirst = false;
											
											char[][] oldValues;
											for( int i = 0; i < regTable.getItemCount; ++ i )
											{
												auto _values = regTable.getSelection( i + 1 );
												oldValues ~= _values[2];
											}
											regTable.removeAllItem();
											
											
											for( int i = 0; i < results.length; ++i )
											{
												char[][] values;
												int spacePos = Util.index( results[i], " " );
												if( spacePos < results[i].length )
												{
													values ~= Integer.toString( i );
													values ~= results[i][0..spacePos].dup;
													
													char[]		valueString = Util.trim( results[i][spacePos..$] ).dup;
													char[][]	splitValue = Util.split( valueString, "\t" );
													
													if( splitValue.length == 2 )
													{
														values ~= splitValue;
													}
													else
													{
														spacePos = Util.index( valueString, " " );
														if( spacePos < valueString.length )
														{
															values ~= valueString[0..spacePos].dup;
															values ~= Util.trim( valueString[spacePos..$] ).dup;
														}
													}
													
													if( values.length == 4 ) 
													{
														regTable.addItem( values );
														
														if( !bFirst )
														{
															if( oldValues[i] != values[2] ) regTable.setImageId( "icon_debug_change", i + 1, 4 );
														}
													}
												}
											}
											
											if( bFirst )
											{
												IupRefresh( regScrollBox );
												bFirst = false;
											}
										}
										else if( splitCommand.length == 3 )
										{
											if( results.length == 1 )
											{
												result = results[0];
												int spacePos = Util.index( result, " " );
												if( spacePos < result.length )
												{
													char[]		name = result[0..spacePos].dup;
													char[][]	values = ( Util.split( Util.trim( result[spacePos..$] ), "\t" ) );
													if( values.length == 2 && name.length )
													{
														for( int i = regTable.getItemCount; i > 0; -- i )
														{
															char[][] _values = regTable.getSelection( i );
															if( _values.length == 4 )
															{
																if( name == _values[1] )
																{
																	regTable.setItem( [ _values[0], name, values[0], values[1] ], i );
																	break;
																}
															}
														}
													}
												}
											}
										}
									}
									else
									{
										regTable.removeAllItem();
									}
								}
								break;

							default:
						}
					}
					break;

				default:
			}
		}

		return result;
	}
	
	bool is64Bit()
	{
		if( DebugControl !is null ) return DebugControl.b64Bit;
		return false;
	}

	bool isExecuting()
	{
		if( DebugControl !is null ) return DebugControl.bExecuted;

		return false;
	}

	bool isRunning()
	{
		return bRunning;
	}

	void Running( bool bGo )
	{
		bRunning = bGo;
	}

	void Executing( bool bGo )
	{
		DebugControl.bExecuted = bGo;
	}

	void terminal()
	{
		bRunning = false;
		DebugControl.bExecuted = false;
		
		if( DebugControl !is null ) delete DebugControl;
		IupSetAttribute( consoleHandle, "VALUE", "" );
		IupSetAttribute( GLOBAL.debugPanel.getConsoleCommandInputHandle, "VALUE", "" ); // Clear Input Text
		
		localTreeFrame = argTreeFrame = shareTreeFrame = regFrame = disasFrame = "";
		
		IupSetAttribute( localTreeHandle, "DELNODE", "ALL" ); 
		IupSetAttribute( argTreeHandle, "DELNODE", "ALL" ); 
		IupSetAttribute( shareTreeHandle, "DELNODE", "ALL" );
		IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
		IupSetAttributeId( backtraceHandle, "DELNODE", 0, "CHILDREN" );
		regTable.removeAllItem();
		IupSetAttribute( disasHandle, "VALUE", "" );
		bpTable.removeAllItem();
		/+
		// Set the breakpoint id to -1
		for( int i = bpTable.getItemCount(); i > 0; -- i )
		{
			char[][] values = bpTable.getSelection( i );
			if( values.length == 3 ) bpTable.setItem( [ "-1", values[1], values[2] ], i );
		}
		+/

		IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
	}

	bool runDebug()
	{
		bool	bRunProject;
		char[]	command;
		char[]	activePrjName	= actionManager.ProjectAction.getActiveProjectName();

		auto activeCScintilla = actionManager.ScintillaAction.getActiveCScintilla();
		if( activeCScintilla !is null )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ).dup == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
			IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
			
			int nodeCount = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
			for( int id = 1; id <= nodeCount; id++ )
			{
				char[] _cstring = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;//fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup; // Shadow
				if( _cstring == activeCScintilla.getFullPath() )
				{
					version(Windows) IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" ); else IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );

					bRunProject = true;

					if( GLOBAL.projectManager[activePrjName].type.length )
					{
						//IupMessage( "", toStringz(GLOBAL.projectManager[activePrjName].type ) );
						if( GLOBAL.projectManager[activePrjName].type != "1" )
						{
							//IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
							//IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Can't Debug Static / Dynamic Library directlly............Debug Error!" ) );
							GLOBAL.messagePanel.printOutputPanel( "Can't Debug Static / Dynamic Library directlly............Debug Error!", true );
							return false;
						}
					}
					
					version(Windows)
					{
						if( GLOBAL.projectManager[activePrjName].targetName.length )
							command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].targetName ~ ".exe";
						else
							command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe";
					}
					else
					{
						if( GLOBAL.projectManager[activePrjName].targetName.length )
							command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].targetName;
						else
							command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name;
					}
					break;
				}
			}

			if( !bRunProject ) 
			{
				scope _f = new FilePath( activeCScintilla.getFullPath() );
				version(Windows)
				{
					command = _f.path ~ _f.name ~ ".exe";
				}
				else
				{
					command = _f.path ~ _f.name;
				}
			}
		}
		else
		{
			if( activePrjName.length )
			{
				version(Windows)
				{
					if( GLOBAL.projectManager[activePrjName].targetName.length )
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].targetName ~ ".exe";
					else
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe";
				}
				else
				{
					if( GLOBAL.projectManager[activePrjName].targetName.length )
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].targetName;
					else
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name;
				}
			}
		}

		//IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
		GLOBAL.messagePanel.printOutputPanel( "", true );
		
		scope f = new FilePath( command );
		if( f.exists() )
		{
			//IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Running " ~ command ~ "......" ) );
			GLOBAL.messagePanel.printOutputPanel( "Running " ~ command ~ "......", true );
			
			scope debuggerEXE = new FilePath( GLOBAL.debuggerFullPath );
			if( debuggerEXE.exists() )
			{
				if( lowerCase( debuggerEXE.file() ) == "fbdebugger.exe" )
				{
					IupExecute( toStringz( "\"" ~ GLOBAL.debuggerFullPath ~ "\"" ), toStringz( command ) );
				}
				else
				{
					DebugControl = new DebugThread( "\"" ~ command ~ "\"", f.path );
					//version(Windows) DebugControl.start();
				}
			}
			else
			{
				version(linux) DebugControl = new DebugThread( "\"" ~ command ~ "\"", f.path );
			}
		}
		else
		{
			//IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Execute file: " ~ command ~ "\nisn't exist......?\n\nRun Error!" ) );
			GLOBAL.messagePanel.printOutputPanel( "Execute file: " ~ command ~ "\nisn't exist......?\n\nRun Error!", true );
			return false;
		}

		return true;
	}

	int compileWithDebug()
	{
		return ExecuterAction.compile( null, null, null, "-g" );
	}

	bool buildAllWithDebug()
	{
		return ExecuterAction.buildAll( null, null, "-g" );
	}	

	void updateBackTrace()
	{
		if( bRunning )
		{
			char[] oriBTName = getFrameNodeTitle();
			
			char[] result = sendCommand( "bt\n", false );

			if( result.length > 5 ) updateSYMBOL();
			
			if( oriBTName != getFrameNodeTitle() )
			{
				// Clear variables trees
				IupSetAttribute( GLOBAL.debugPanel.localTreeHandle, "DELNODE", "ALL" );
				IupSetAttribute( GLOBAL.debugPanel.argTreeHandle, "DELNODE", "ALL" );
				IupSetAttribute( GLOBAL.debugPanel.shareTreeHandle, "DELNODE", "ALL" );
			}				
		}
	}

	void addBP( char[] _fullPath, char[] _lineNum )
	{
		_fullPath = tools.fullPathByOS( _fullPath );
		
		if( isExecuting || isRunning )
		{
			char[] result = sendCommand( "b " ~ _fullPath ~ ":" ~ _lineNum ~ "\n" );
		}
		else
		{
			bpTable.addItem( [ "-1", _lineNum, _fullPath ] );
		}
	}

	void removeBP( char[] _fullPath, char[] _lineNum )
	{
		_fullPath = tools.fullPathByOS( _fullPath );
		
		if( isExecuting || isRunning )
		{
			for( int i = bpTable.getItemCount(); i > 0; -- i )
			{
				char[][] values = bpTable.getSelection( i );
				if( values.length == 3 )
				{
					if( values[1] == _lineNum && tools.fullPathByOS( values[2] ) == _fullPath )
					{
						if( Integer.atoi( values[0] ) > 0 ) 
						{
							sendCommand( "delete " ~ values[0] ~ "\n" );
							bpTable.removeItem( i );
							break;
						}
					}
				}
			}
		}
		else
		{
			for( int i = bpTable.getItemCount(); i > 0; -- i )
			{
				char[][] values = bpTable.getSelection( i );
				if( values.length == 3 )
				{
					if( values[1] == _lineNum && tools.fullPathByOS( values[2] ) == _fullPath )
					{
						bpTable.removeItem( i );
						break;
					}
				}
			}
		}
	}
	
}


class CVarDlg : CSingleTextDialog
{
	public:
	this( int w, int h, char[] title, char[] _labelText = null,  char[] textWH = null, char[] text = null, bool bResize = false, char[] parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, _labelText, textWH, text, bResize, parent );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CConsoleDlg_btnCancel_cb );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CConsoleDlg_btnCancel_cb );
	}

	~this()
	{
		IupSetHandle( "textResult", null );
		IupDestroy( _dlg );
	}		
}


class DebugThread //: Thread
{
	private :
	import		tango.io.stream.Data, tango.sys.Process;
	import		tango.sys.win32.Types, tango.sys.win32.UserGdi;

	
	char[]		executeFullPath, cwd;
	bool		b64Bit;
	int			caretPos, splitValue;
	Process		proc;


	char[] getGDBmessage()
	{
		proc.stdin.flush();
		proc.stdout.flush();
		proc.stderr.flush();
		
		char[] result;
		
		try
		{
			while( 1 )
			{
				try
				{
					char[1] c;
					//if( proc.stderr is null ) 
					if( proc.stdout.read( c ) <= 0 ) break;
					
					result ~= c;

					if( c == ")" )
					{
						if( result.length >= 5 )
						{
							if( result[$-5..$] == "(gdb)" ) break;
						}
					}
				}
				catch( Exception e )
				{
					throw( e );
				}
			}

			return Util.trim( result );
		}
		catch( Exception e )
		{
			IupMessage("","ERROR" );
			debug GLOBAL.IDEMessageDlg.print( "getGDBmessage() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
		}
		/*
		try
		{
			
			char[5000] _buffer;
			int r = proc.stdout.read( _buffer );

			if( r > 5 )
			{
				//if( _buffer[r-5..r] == "(gdb)" ) 
				return Util.trim( _buffer[0..r] ).dup;
			}
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "getGDBmessage() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			IupMessage( "Bug", toStringz( "getGDBmessage() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
		}
		*/
		return "(gdb)";
	}
	

	public:
	bool		bExecuted;
	HANDLE		dupWriteHandle;
	
	this( char[] _executeFullPath, char[] _cwd = null )
	{
		executeFullPath = _executeFullPath;
		cwd = _cwd;
		run();
	}

	~this()
	{
		proc.close();
		proc.kill();
		delete proc;

		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			//#define SCI_MARKERDELETEALL 2045
			IupScintillaSendMessage( cSci.getIupScintilla, 2045, 2, 0 );
			IupScintillaSendMessage( cSci.getIupScintilla, 2045, 3, 0 );
			IupScintillaSendMessage( cSci.getIupScintilla, 2045, 4, 0 );
		}
	}

	void run()
	{
		try
		{
			if( bExecuted ) return;
			
			// Show the Debug window
			IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "YES" );
			IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 2 );
			
			char[] debuggerExe = GLOBAL.debuggerFullPath;
			
			version(Windows)
			{
				b64Bit = GLOBAL.editorSetting00.Bit64 == "OFF" ? false : true;
				debuggerExe = !b64Bit ? GLOBAL.debuggerFullPath : GLOBAL.x64debuggerFullPath;
				foreach( char[] s; GLOBAL.EnvironmentVars.keys )
				{
					debuggerExe = Util.substitute( debuggerExe, "%"~s~"%", GLOBAL.EnvironmentVars[s] );
				}
			}
			else
			{
				b64Bit = true;
			}
			
			

			proc = new Process( true, "\"" ~ debuggerExe ~ "\" " ~ executeFullPath );
			proc.gui( true );
			if( cwd.length ) proc.workDir( cwd );
			//proc.redirect( Redirect.All );
			proc.execute;
			//auto proc_result = proc.wait;

			char[] result = getGDBmessage();
			IupSetStrAttribute( GLOBAL.debugPanel.getConsoleHandle, "APPEND", toStringz( result ) );

			if( Util.index( result, "(no debugging symbols found)" ) < result.length )
			{
				IupMessageError( null, GLOBAL.languageItems["exitdebug2"].toCString() );
				proc.close();
				proc.kill();
				delete proc;
				IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "VALUE", "" );
				IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
				return;
			}

			
			//IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "READONLY", "NO" );
			caretPos = IupGetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS" );

			bExecuted = true;
			IupSetStrAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "TITLE", 0, toStringz( executeFullPath ) );
			IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGE", 0, "icon_debug_bt0" );
			IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGEEXPANDED", 0, "icon_debug_bt0" );
			splitValue = IupGetInt( GLOBAL.messageSplit, "VALUE" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", 500 );

			
			sendCommand( "set confirm off\n", false );
			sendCommand( "set print array-indexes on\n", false );
			sendCommand( "set width 0\n", false );
			
			sendCommand( "set logging overwrite on\n", false );
			sendCommand( "set logging on\n", false );
			
			//sendCommand( "set breakpoint pending on\n", false );
			//sendCommand( "set print elements 1\n", false );
			
			version( Windows )
			{
				sendCommand( "set new-console on\n", false );
			}
			else
			{
				/*
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION,BUTTONS=OK");
				IupSetAttribute( messageDlg, "TITLE", "GDB" );
				IupSetAttribute( messageDlg, "VALUE", "Use \"tty\" Command To Specifies The Terminal Device." );
				IupPopup( messageDlg, IUP_CURRENT, IUP_CURRENT );
				*/
				/+
				//auto termProc = new Process( true, GLOBAL.linuxTermName);
				auto termProc = new Process( true, GLOBAL.linuxTermName ~ " -e \"bash -c 'tty;$SHELL'\"" );
				
				//auto termProc = new Process( true, GLOBAL.linuxTermName ~ " -x sh -c \"ls\"" );
				
				
				//termProc.redirect( Redirect.All );
				//termProc.gui( true );
				termProc.execute;
				
				termProc.stdin.write( "ls" );
				
				char[1024] ttyResult;
				int size = termProc.stdout.read( ttyResult );
				
				
				size = termProc.stdout.read( ttyResult );
				
				termProc.wait;
				+/
			}			
		}
		catch( Exception e )
		{
		}
	}

	char[] sendCommand( char[] command, bool bShow = true )
	{
		switch( command )
		{
			case "kill\n", "k\n":
				int result = IupMessageAlarm( null, "GDB", "Kill the program being debugged?", "YESNO" );
				if( result == 2 ) return "#_NO_#";
				break;
				
			default:
		}
	
	
		proc.stdin.write( command );
		
		if( bShow )
		{
			IupSetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS", caretPos );
			IupSetStrAttribute( GLOBAL.debugPanel.getConsoleHandle, "INSERT", toStringz( command ) );
		}
		
		char[] result = getGDBmessage();
		if( bShow )
		{
			IupSetStrAttribute( GLOBAL.debugPanel.getConsoleHandle, "INSERT", toStringz( result.dup ) );
			caretPos = IupGetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS" );
		}

		proc.stdout.flush();
		return result;
	}
}

import tango.time.Clock;


extern( C )
{
	private int CConsoleDlg_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		if( textHandle != null )
		{
			IupSetAttribute( textHandle, "VALUE", "#_close_#" );
		}

		return IUP_CLOSE;
	}

	private int consoleOutputChange_cb( Ihandle* ih )
	{
		return IUP_IGNORE;
	}
	
	import tango.sys.Process, tango.core.Exception, tango.io.stream.Lines, tango.io.stream.Iterator;
	import tango.sys.win32.Types, tango.sys.win32.UserGdi;
	
	private int consoleInput_cb( Ihandle *ih, int c, char *new_value )
	{
		static char[] prevCommand;
		
		if( c == '\n' )
		{
			char[] _command;
			
			foreach( char[] s; Util.splitLines( Util.trim( fromStringz( new_value ) ) ) )
				_command ~= s;

			if( !_command.length ) _command = prevCommand; else prevCommand = _command;
			
			if( _command == "q" || _command == "quit" )
			{
				GLOBAL.debugPanel.terminal();
				return IUP_IGNORE;
			}
			else
			{
				GLOBAL.debugPanel.sendCommand( _command ~ "\n" );
			}

			IupSetAttribute( GLOBAL.debugPanel.getConsoleCommandInputHandle, "VALUE", "" );
			//IupSetInt( GLOBAL.debugPanel.getConsoleCommandInputHandle, "CARETPOS", IupGetInt( GLOBAL.debugPanel.getConsoleCommandInputHandle, "COUNT" ) );
			IupSetFocus( GLOBAL.debugPanel.getConsoleCommandInputHandle );
			return IUP_IGNORE;
		}
		
		return IUP_DEFAULT;
	}

	private int CDebugger_resume( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 )
		{
			if( GLOBAL.debugPanel.isExecuting() )
			{
				if( button == IUP_BUTTON1 ) // Left Click
				{
					if( !GLOBAL.debugPanel.isRunning() ) GLOBAL.debugPanel.sendCommand( "r\n" ); else GLOBAL.debugPanel.sendCommand( "continue\n" );
				}
				else if( button == IUP_BUTTON3 ) // Right Click
				{
					if( !GLOBAL.debugPanel.isRunning() )
					{
						scope argDialog = new CSingleTextDialog( 300, -1, "Args To Debugger Run", "Args:", null, null, false );
						char[] args = argDialog.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
						
						if( args.length ) GLOBAL.debugPanel.sendCommand( "r " ~ args ~ "\n" );
					}
				}
			}
		}
		return IUP_DEFAULT;
	}

	private int CDebugger_stop( Ihandle* ih )
	{
		if( GLOBAL.debugPanel.isExecuting() && GLOBAL.debugPanel.isRunning() )	GLOBAL.debugPanel.sendCommand( "kill\n" );
		return IUP_DEFAULT;
	}

	private int CDebugger_step( Ihandle* ih )
	{
		if( GLOBAL.debugPanel.isExecuting() && GLOBAL.debugPanel.isRunning() ) GLOBAL.debugPanel.sendCommand( "step\n" );
		return IUP_DEFAULT;
	}

	private int CDebugger_next( Ihandle* ih )
	{
		if( GLOBAL.debugPanel.isExecuting() && GLOBAL.debugPanel.isRunning() ) GLOBAL.debugPanel.sendCommand( "next\n" );
		return IUP_DEFAULT;
	}

	private int CDebugger_return( Ihandle* ih )
	{
		if( GLOBAL.debugPanel.isExecuting() && GLOBAL.debugPanel.isRunning() ) GLOBAL.debugPanel.sendCommand( "return\n" );
		return IUP_DEFAULT;
	}

	private int CDebugger_until( Ihandle* ih )
	{
		if( GLOBAL.debugPanel.isExecuting() && GLOBAL.debugPanel.isRunning() ) GLOBAL.debugPanel.sendCommand( "until\n" );
		return IUP_DEFAULT;
	}

	private int CDebugger_terminate( Ihandle* ih )
	{
		GLOBAL.debugPanel.terminal();
		return IUP_DEFAULT;
	}

	private int backtraceBUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 ) // IUP_BUTTON1 = '1' = 49
		{
			if( DocumentTabAction.isDoubleClick( status ) )
			{
				if( GLOBAL.debugPanel.isRunning )
				{
					int id = IupConvertXYToPos( ih, x, y );
					if( id > 0 )
					{
						char[][] _information = GLOBAL.debugPanel.getFrameInformation( fromStringz( IupGetAttributeId( ih, "TITLE", id ) ).dup );
						if( _information.length == 4 ) GLOBAL.debugPanel.sendCommand( "select-frame " ~ _information[2] ~ "\n", false );
					}
					return IUP_IGNORE;
				}
			}
		}

		return IUP_DEFAULT;
	}
	
	private int watchListBUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 ) // IUP_BUTTON1 = '1' = 49
		{
			if( DocumentTabAction.isDoubleClick( status ) )
			{
				if( GLOBAL.debugPanel.isRunning )
				{
					int			id = IupConvertXYToPos( ih, x, y );
					char[]		fullVarName = GLOBAL.debugPanel.getFullVarNameInTree( ih, id, true );
					
					if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ).dup == "LEAF" )
					{
						char[]		numID; // Remove ID
						char[]		title = fromStringz( IupGetAttributeId( ih, "TITLE", id ) ).dup; // Get Tree Title
						
						if( title[0] > 47 && title[0] < 58 )
						{
							int	colonspacePos = Util.index( title, ": " );
							if( colonspacePos < title.length )
							{
								numID = title[0..colonspacePos+2].dup;
								title = title[colonspacePos+2..$].dup;
							}
						}
						
						if( title[0] == '*' ) fullVarName = "*" ~ fullVarName;
						
						scope varDlg = new CVarDlg( 360, -1, "Evaluate " ~ fullVarName, "Value = " );
						char[] value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

						if( value == "#_close_#" ) return IUP_DEFAULT;
						
						int assignPos = Util.index( title, " = " );
						GLOBAL.debugPanel.sendCommand( "set var " ~ fullVarName ~ " = " ~  value ~ "\n", false );

						int posCloseParen = Util.index( title, ") " );
						if( posCloseParen < title.length ) IupSetAttributeId( ih, "TITLE", id, toStringz( numID ~ title[0..posCloseParen+2] ~ value ) );else IupSetAttributeId( ih, "TITLE", id, toStringz( numID ~ title[0..assignPos+3] ~ value ) );
						return IUP_IGNORE;
					}
					else
					{
						if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ) == "BRANCH" )
						{
							if( IupGetIntId( ih, "TOTALCHILDCOUNT", id ) == 0 )
							{
								char[] title = fromStringz( IupGetAttributeId( ih, "TITLE",id ) ).dup;
								title = GLOBAL.debugPanel.removeIDTitle( title );
								//if( title[0] == '*' ) fullVarName = "*" ~ fullVarName;
							
								VarObject[] variables = GLOBAL.debugPanel.getTypeVarValueByLinesFromPrint( GLOBAL.debugPanel.getPrint( title[0] == '*' ? "*" ~ fullVarName : fullVarName ), fullVarName );
								
								if( variables.length )
								{
									foreach( VarObject _vo; variables )
									{
										char[] _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~ _vo.type ~ ") " : "" ) ~ _vo.value;
										if( _vo.value == "{...}" ) IupSetAttributeId( ih, "ADDBRANCH", id, toStringz( _title ) ); else IupSetAttributeId( ih, "ADDLEAF", id, toStringz( _title ) );
										IupSetStrAttributeId( ih, "TITLEFONT", id + 1, toStringz( GLOBAL.fonts[9].fontString ) );
									}
								}

								return IUP_IGNORE;
							}
						}
					}
				}
			}
		}
		else if( button == IUP_BUTTON3 )
		{
			if( pressed == 0 )
			{
				int id = IupConvertXYToPos( ih, x, y );
				version(Windows) IupSetAttributeId( GLOBAL.debugPanel.watchTreeHandle, "MARKED", id, "YES" ); else IupSetInt( GLOBAL.debugPanel.watchTreeHandle, "VALUE", id );
				
				char[] title = fromStringz( IupGetAttributeId( GLOBAL.debugPanel.watchTreeHandle, "TITLE", id ) );
				if( !Util.contains( title, '=' ) ) return IUP_DEFAULT;

				Ihandle* itemVALUE = IupItem( GLOBAL.languageItems["showvalue"].toCString, null );//IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttributes( itemVALUE, "NAME=WATCHLIST_VALUE,IMAGE=icon_debug_star" );
				IupSetCallback( itemVALUE, "ACTION", cast(Icallback) &itemRightClick_ACTION );

				Ihandle* itemADDRESS = IupItem( GLOBAL.languageItems["showaddress"].toCString, null );//IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttributes( itemADDRESS, "NAME=WATCHLIST_ADDRESS,IMAGE=icon_debug_at" );
				IupSetCallback( itemADDRESS, "ACTION", cast(Icallback) &itemRightClick_ACTION );

				Ihandle* itemADDLIST = IupItem( GLOBAL.languageItems["addtowatch"].toCString, null );//IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttribute( itemADDLIST, "IMAGE", "icon_debug_add" );
				IupSetCallback( itemADDLIST, "ACTION", cast(Icallback) function( Ihandle* __ih )
				{
					int _id = IupGetInt( GLOBAL.debugPanel.watchTreeHandle, "VALUE" );
					char[] title = fromStringz( IupGetAttributeId( GLOBAL.debugPanel.watchTreeHandle, "TITLE", _id ) );
					char[] varName = GLOBAL.debugPanel.getFullVarNameInTree( GLOBAL.debugPanel.watchTreeHandle, _id, true );						

					if( title.length )
						if( title[0] == '*' ) varName = "*" ~ varName;

						
					if( varName.length ) GLOBAL.debugPanel.sendCommand( "display " ~ varName ~ "\n", false );

					return IUP_DEFAULT;
				});


				// Check with ID
				if( title[0] > 47 && title[0] < 58 )
				{
					IupSetAttribute( itemADDLIST, "ACTIVE", "NO" );
					int	colonspacePos = Util.index( title, ": " );
					if( colonspacePos < title.length ) title = title[colonspacePos+2..$].dup;
				}

				if( title[0] == '&' ) IupSetAttribute( itemADDRESS, "ACTIVE", "NO" );
				
				int closeParenPos = Util.rindex( title, ")" );
				if( closeParenPos < title.length && closeParenPos > 0 )
				{
					if( title[closeParenPos-1] != '*' ) IupSetAttribute( itemVALUE, "ACTIVE", "NO" ); else IupSetAttribute( itemADDRESS, "ACTIVE", "NO" );
				}
				
				
				if( fromStringz( IupGetAttribute( itemADDLIST, "ACTIVE" ) ) == "NO" &&
					fromStringz( IupGetAttribute( itemADDRESS, "ACTIVE" ) ) == "NO" &&
					fromStringz( IupGetAttribute( itemVALUE, "ACTIVE" ) ) == "NO" )	return IUP_DEFAULT;

				Ihandle* popupMenu = IupMenu( 	
											itemVALUE,
											itemADDRESS,
											IupSeparator,
											itemADDLIST,
											null
											);
											
				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
			}
		}

		return IUP_DEFAULT;
	}
	

	private int treeBUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 ) // IUP_BUTTON1 = '1' = 49
		{
			if( DocumentTabAction.isDoubleClick( status ) )
			{
				int id = IupConvertXYToPos( ih, x, y );
				if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ) == "BRANCH" )
				{
					if( IupGetIntId( ih, "TOTALCHILDCOUNT", id ) == 0 )
					{
						char[] title = fromStringz( IupGetAttributeId( ih, "TITLE",id ) ).dup;
						char[] fullVarName = GLOBAL.debugPanel.getFullVarNameInTree( ih, id );
						//if( title[0] == '*' ) fullVarName = "*" ~ fullVarName;
						
						VarObject[] variables = GLOBAL.debugPanel.getTypeVarValueByLinesFromPrint( GLOBAL.debugPanel.getPrint( title[0] == '*' ? "*" ~ fullVarName : fullVarName ), fullVarName );
						
						if( variables.length )
						{
							foreach( VarObject _vo; variables )
							{
								char[] _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~ _vo.type ~ ") " : "" ) ~ _vo.value;
								if( _vo.value == "{...}" ) IupSetAttributeId( ih, "ADDBRANCH", id, toStringz( _title ) ); else IupSetAttributeId( ih, "ADDLEAF", id, toStringz( _title ) );
								IupSetStrAttributeId( ih, "TITLEFONT", id + 1, toStringz( GLOBAL.fonts[9].fontString ) );
							}							
						}

						return IUP_IGNORE;
					}
				}
				else // LEAF
				{
					char[]		title = fromStringz( IupGetAttributeId( ih, "TITLE", id ) ).dup; // Get Tree Title
					char[]		fullVarName = GLOBAL.debugPanel.getFullVarNameInTree( ih, id, true );
					
					if( title[0] == '*' ) fullVarName = "*" ~ fullVarName;
					
					scope varDlg = new CVarDlg( 360, -1, "Evaluate " ~ fullVarName, "Value = " );
					char[] value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

					if( value == "#_close_#" ) return IUP_DEFAULT;
					
					int assignPos = Util.index( title, " = " );
					GLOBAL.debugPanel.sendCommand( "set var " ~ fullVarName ~ " = " ~  value ~ "\n", false );

					int posCloseParen = Util.index( title, ") " );
					if( posCloseParen < title.length ) IupSetAttributeId( ih, "TITLE", id, toStringz( title[0..posCloseParen+2] ~ value ) );else IupSetAttributeId( ih, "TITLE", id, toStringz( title[0..assignPos+3] ~ value ) );
					return IUP_IGNORE;
				}					
			}
		}
		else if( button == IUP_BUTTON3 )
		{
			if( pressed == 0 )
			{
				int id = IupConvertXYToPos( ih, x, y );
				version(Windows) IupSetAttributeId( ih, "MARKED", id, "YES" ); else IupSetInt( ih, "VALUE", id );
				
				char[] title = fromStringz( IupGetAttributeId( ih, "TITLE", id ) );
				
				if( !Util.contains( title, '=' ) ) return IUP_DEFAULT;
				
				Ihandle* itemVALUE = IupItem( GLOBAL.languageItems["showvalue"].toCString, null );//IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttributes( itemVALUE, "NAME=VARIABLES_VALUE,IMAGE=icon_debug_star" );
				IupSetCallback( itemVALUE, "ACTION", cast(Icallback) &itemRightClick_ACTION );
				
				Ihandle* itemADDRESS = IupItem( GLOBAL.languageItems["showaddress"].toCString, null );//IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttributes( itemADDRESS, "NAME=VARIABLES_ADDRESS,IMAGE=icon_debug_at" );
				IupSetCallback( itemADDRESS, "ACTION", cast(Icallback) &itemRightClick_ACTION );
				
				int closeParenPos = Util.rindex( title, ")" );
				if( closeParenPos < title.length && closeParenPos > 0 )
				{
					if( title[closeParenPos-1] != '*' ) IupSetAttribute( itemVALUE, "ACTIVE", "NO" ); else IupSetAttribute( itemADDRESS, "ACTIVE", "NO" );
				}
				
				if( title.length )
					if( title[0] == '@' ) IupSetAttribute( itemADDRESS, "ACTIVE", "NO" );

			
				Ihandle* popupMenu = IupMenu( 	
												itemVALUE,
												itemADDRESS,
												null
											);
											
				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
			}
			
		}
		
		return IUP_DEFAULT;
	}

	private int resultTabChange_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		switch( new_pos )
		{
			case 1:
				int varsTabPos =  IupGetInt( GLOBAL.debugPanel.getVarsTabHandle, "VALUEPOS" );
				return varTabChange_cb( GLOBAL.debugPanel.getVarsTabHandle, varsTabPos, -1 );

			case 2:
				char[] nowFrameFullTitle = GLOBAL.debugPanel.getFrameNodeTitle( true ); // -1 = Get Active; true = Get Full Title
				if( nowFrameFullTitle != GLOBAL.debugPanel.regFrame )
				{
					GLOBAL.debugPanel.regFrame = nowFrameFullTitle;
					GLOBAL.debugPanel.sendCommand( "info reg\n", false );
				}
				break;
			
			case 3:
				char[] nowFrameFullTitle = GLOBAL.debugPanel.getFrameNodeTitle( true ); // -1 = Get Active; true = Get Full Title
				if( nowFrameFullTitle != GLOBAL.debugPanel.disasFrame )
				{
					GLOBAL.debugPanel.disasFrame = nowFrameFullTitle;;
					GLOBAL.debugPanel.showDisassemble();
				}
				break;
				
			default:
		}
		return IUP_DEFAULT;
	}	

	private int varTabChange_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		char[] nowFrameFullTitle = GLOBAL.debugPanel.getFrameNodeTitle( true ); // -1 = Get Active; true = Get Full Title
		
		switch( new_pos )
		{
			case 0:
				if( nowFrameFullTitle != GLOBAL.debugPanel.localTreeFrame )
				{
					GLOBAL.debugPanel.localTreeFrame = nowFrameFullTitle;
					GLOBAL.debugPanel.sendCommand( "info locals\n", false );
				}
				break;
				
			case 1:
				if( nowFrameFullTitle != GLOBAL.debugPanel.argTreeFrame )
				{
					GLOBAL.debugPanel.argTreeFrame = nowFrameFullTitle;
					GLOBAL.debugPanel.sendCommand( "info args\n", false );
				}
				break;
				
			case 2:
				if( nowFrameFullTitle != GLOBAL.debugPanel.shareTreeFrame )
				{
					GLOBAL.debugPanel.shareTreeFrame = nowFrameFullTitle;
					GLOBAL.debugPanel.sendCommand( "info variables\n", false );
				}
				break;
				
			default:
		}
		return IUP_DEFAULT;
	}

	
	private int itemRightClick_ACTION( Ihandle* ih )
	{
		Ihandle*	_ih;
		bool		bGetADDRESS;
		char[]		name = fromStringz( IupGetAttribute( ih, "NAME" ) ).dup;
		
		if( Util.containsPattern( name, "VARIABLES" ) ) _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.debugPanel.getVarsTabHandle, "VALUE_HANDLE" ); else _ih = GLOBAL.debugPanel.watchTreeHandle;
		if( Util.containsPattern( name, "ADDRESS" ) ) bGetADDRESS = true;
		

		if( _ih != null )
		{
			bool	bHasMember, bHasStar;
			char[]	varFullName;
			int		_id = IupGetInt( _ih, "VALUE" );
			char[]	title = fromStringz( IupGetAttributeId( _ih, "TITLE", _id ) ).dup;
			
			
			int closeParenPos = Util.rindex( title, ") " );
			if( closeParenPos < title.length)
				if( title[closeParenPos-1] == '*' ) bHasStar = true;
			
			
			title = GLOBAL.debugPanel.removeIDTitle( title );
			if( title.length )
			{
				if( bGetADDRESS )
				{
					if( title[0] == '*' || title[0] == '&' || bHasStar ) varFullName = GLOBAL.debugPanel.getFullVarNameInTree( _ih, _id, true ); else varFullName = "&" ~ GLOBAL.debugPanel.getFullVarNameInTree( _ih, _id, true );
				}
				else
				{
					if( title[0] == '*' || title[0] == '&' ) varFullName = GLOBAL.debugPanel.getFullVarNameInTree( _ih, _id, true ); else varFullName = "*" ~ GLOBAL.debugPanel.getFullVarNameInTree( _ih, _id, true );
				}
			
				char[]	gdbMessage = GLOBAL.debugPanel.getPrint( varFullName );
				if( gdbMessage == "?" ) return IUP_DEFAULT;
				
				
				int		openPos = Util.index( gdbMessage, "{" );
				if( openPos < gdbMessage.length )
				{
					bHasMember = true;
					gdbMessage = ( gdbMessage[0..openPos] ~ "{...}" ).dup;
				}
				
				// Insert type if need....
				int closePos = Util.rindex( gdbMessage, ") " );
				if( closePos >= gdbMessage.length )
				{
					char[] type = GLOBAL.debugPanel.getWhatIs( varFullName );
					if( type != "?" ) gdbMessage = "(" ~ type ~ ") " ~ gdbMessage;
				
				}
				
				title = varFullName ~ " = " ~ gdbMessage;
				
				if( bHasMember )
				{
					IupSetAttributeId( _ih, "INSERTBRANCH", _id, toStringz( title ) );
					IupSetAttributeId( _ih, "COLOR", IupGetIntId( _ih, "NEXT", _id ), "0 0 255" );
					IupSetStrAttributeId( _ih, "TITLEFONT", IupGetIntId( _ih, "NEXT", _id ), toStringz( GLOBAL.fonts[9].fontString ) );
					//if( _ih != GLOBAL.debugPanel.watchTreeHandle ) IupSetAttributeId( _ih, "DELNODE", _id, "SELECTED" );
				}
				else
				{
					IupSetAttributeId( _ih, "INSERTLEAF", _id, toStringz( title ) );
					IupSetAttributeId( _ih, "COLOR", IupGetIntId( _ih, "NEXT", _id ), "0 0 255" );
					IupSetStrAttributeId( _ih, "TITLEFONT", IupGetIntId( _ih, "NEXT", _id ), toStringz( GLOBAL.fonts[9].fontString ) );
					//if( _ih != GLOBAL.debugPanel.watchTreeHandle ) IupSetAttributeId( _ih, "DELNODE", _id, "SELECTED" );
				}
				
				if( _ih == GLOBAL.debugPanel.watchTreeHandle )
				{
					int _result = IupMessageAlarm( null, "GDB", toStringz( GLOBAL.languageItems["addtowatch"].toDString ~ "?" ), "YESNO" );
					if( _result == 1 )
					{
						IupSetAttributeId( _ih, "DELNODE", IupGetIntId( _ih, "NEXT", _id ), "SELECTED" );
						GLOBAL.debugPanel.sendCommand( "display " ~ varFullName ~ "\n", false );
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}

	/*
	version(Windows)
	{
		private int CDebugger_memberButton( Ihandle* ih, int button, int pressed, int x, int y, char* status )//( Ihandle *ih, char *text, int item, int state )
		{
			int item = IupConvertXYToPos( ih, x, y );

			switch( IupGetInt( GLOBAL.debugPanel.tabResultsHandle, "VALUEPOS" ) )
			{
				case 0:		GLOBAL.debugPanel.bpTable.setSelectionID( item );	break;
				case 2:		GLOBAL.debugPanel.regTable.setSelectionID( item );	break;
				default:
			}
			
			return IUP_DEFAULT;
		}
	}
	
	
	private int CDebugger_memberSelect( Ihandle *ih, char *text, int item, int state )
	{
		switch( IupGetInt( GLOBAL.debugPanel.tabResultsHandle, "VALUEPOS" ) )
		{
			case 0:		GLOBAL.debugPanel.bpTable.setSelectionID( item );	break;
			case 2:		GLOBAL.debugPanel.regTable.setSelectionID( item );	break;
			default:
		}
		
		return IUP_DEFAULT;
	}
	*/
	
	private int CDebugger_register_doubleClick( Ihandle* ih, int item, char* text )
	{
		char[][] results = GLOBAL.debugPanel.regTable.getSelection( item );
		if( results.length == 4 )
		{
			scope varDlg = new CVarDlg( 360, -1, "Evaluate " ~ results[1], "Value = " );
			char[] value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
			
			if( value == "#_close_#" ) return IUP_DEFAULT;
			GLOBAL.debugPanel.sendCommand( "set $" ~ results[1] ~ "=" ~ value ~ "\n", false );
			GLOBAL.debugPanel.sendCommand( "info registers " ~ results[1] ~ "\n", false );
			return IUP_IGNORE;
		}
		return IUP_DEFAULT;
	}
	
	private int CDebugger_breakpoint_doubleClick( Ihandle* ih, int item, char* text )
	{
		try
		{
			char[][] results = GLOBAL.debugPanel.bpTable.getSelection( item );
			if( results.length == 3 )
			{
				ScintillaAction.openFile( results[2], Integer.toInt( results[1] ) );
			}
		}
		catch
		{
		}
		return IUP_DEFAULT;
	}	
}