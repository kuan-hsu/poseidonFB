module layouts.debugger;

debug import Conv = std.conv;

private import iup.iup, iup.iup_scintilla;
private import global, scintilla, actionManager, menu;
private import dialogs.singleTextDlg, layouts.table;
private import parser.ast, tools;
private import std.string, std.file, std.conv, Array = std.array, Path = std.path, Uni = std.uni;
private import core.thread;


struct VarObject
{
	string	type;
	string	name;//, name64;
	string	value;
}


class CDebugger
{
private:
	import					std.process;
	
	Ihandle*				txtConsoleCommand;
	Ihandle* 				mainHandle, consoleHandle, backtraceHandle, tabResultsHandle, disasHandle;
	Ihandle*				watchTreeHandle, localTreeHandle, argTreeHandle, shareTreeHandle, varTabHandle;
	Ihandle*				leftScrollBox, bpScrollBox, regScrollBox;
	Ihandle*				varSplit, rightSplitHandle, mainSplit;
	CTable					bpTable, regTable;
	Ihandle*				btnClear, btnResume, btnStop, btnStep, btnNext, btnReturn, btnUntil, btnTerminate, btnLeft, btnRefresh, btnAdd, btnDel, btnDelAll, btnWatchRefresh;
	DebugThread				DebugControl;
	bool					bRunning;
	string					localTreeFrame, argTreeFrame, shareTreeFrame, regFrame, disasFrame;

	void createLayout()
	{
		Ihandle* vBox_LEFT;
		

		btnClear	= IupButton( null, "Clear" );
		btnResume	= IupButton( null, "Resume" );
		btnStop		= IupButton( null, "Stop" );
		btnStep		= IupButton( null, "Step" );
		btnNext		= IupButton( null, "Next" );
		btnReturn	= IupButton( null, "Return" );
		btnUntil	= IupButton( null, "Until" );

		txtConsoleCommand = IupText( null );
		IupSetAttributes( txtConsoleCommand, "EXPAND=HORIZONTAL,MULTILINE=YES,SCROLLBAR=NO,SIZE=x12,FONTSIZE=9,READONLY=NO" );
		IupSetCallback( txtConsoleCommand, "ACTION", cast(Icallback) &consoleInput_cb );

		btnTerminate = IupButton( null, "Terminate" );

		Ihandle*[6] labelSEPARATOR;
		for( int i = 0; i < 6; i++ )
		{
			labelSEPARATOR[i] = IupFlatSeparator();
			IupSetAttributes( labelSEPARATOR[i], "STYLE=EMPTY" );
		}
		
		IupSetAttributes( btnClear, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_clear" );				IupSetStrAttribute( btnClear, "TIP", GLOBAL.languageItems["clear"].toCString );
		IupSetAttributes( btnResume, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_resume" );			IupSetStrAttribute( btnResume, "TIP", GLOBAL.languageItems["runcontinue"].toCString );
		IupSetAttributes( btnStop, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_stop" );				IupSetStrAttribute( btnStop, "TIP", GLOBAL.languageItems["stop"].toCString );
		IupSetAttributes( btnStep, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_step" );				IupSetStrAttribute( btnStep, "TIP", GLOBAL.languageItems["step"].toCString );
		IupSetAttributes( btnNext, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_next" );				IupSetStrAttribute( btnNext, "TIP", GLOBAL.languageItems["next"].toCString );
		IupSetAttributes( btnReturn, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_return" );			IupSetStrAttribute( btnReturn, "TIP", GLOBAL.languageItems["return"].toCString );
		IupSetAttributes( btnUntil, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_until" );				IupSetStrAttribute( btnUntil, "TIP", GLOBAL.languageItems["until"].toCString );
		IupSetAttributes( btnTerminate, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_clear" );				IupSetStrAttribute( btnTerminate, "TIP", GLOBAL.languageItems["terminate"].toCString );
		
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

		vBox_LEFT = IupVbox( IupBackgroundBox( hBox_toolbar ), IupBackgroundBox( txtConsoleCommand ), consoleHandle, null );
		IupSetAttributes( vBox_LEFT, "GAP=2,EXPAND=YES,ALIGNMENT=ACENTER" );

		leftScrollBox = IupScrollBox( vBox_LEFT );

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

		btnLeft		= IupButton( null, "Left" );
		btnRefresh	= IupButton( null, "Refresh" );
		IupSetAttributes( btnLeft, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_left" );	IupSetStrAttribute( btnLeft, "TIP", GLOBAL.languageItems["addtowatch"].toCString );
		IupSetAttributes( btnRefresh, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_refresh" );	IupSetStrAttribute( btnRefresh, "TIP", GLOBAL.languageItems["refresh"].toCString );
		IupSetCallback( btnLeft, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				Ihandle* varsTabHandle = cast(Ihandle*) IupGetAttribute( GLOBAL.debugPanel.getVarsTabHandle, "VALUE_HANDLE" );
				if( varsTabHandle != null )
				{
					int id = IupGetInt( varsTabHandle, "VALUE" );
					string	originTitle = fSTRz( IupGetAttributeId( varsTabHandle, "TITLE", id ) );
					string	varName = GLOBAL.debugPanel.getFullVarNameInTree( varsTabHandle, -99, true );
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
		IupSetStrAttribute( watchTreeHandle, "COLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( watchTreeHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( watchTreeHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetCallback( watchTreeHandle, "BUTTON_CB", cast(Icallback) &watchListBUTTON_CB );

		localTreeHandle =IupTree();
		IupSetAttributes( localTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( localTreeHandle, "COLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( localTreeHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( localTreeHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetCallback( localTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );

		argTreeHandle =IupTree();
		IupSetAttributes( argTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( argTreeHandle, "COLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( argTreeHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( argTreeHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetCallback( argTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );
		
		shareTreeHandle =IupTree();
		IupSetAttributes( shareTreeHandle, "EXPAND=YES,ADDROOT=NO" );
		IupSetStrAttribute( shareTreeHandle, "COLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( shareTreeHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( shareTreeHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetCallback( shareTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );


		varTabHandle = IupFlatTabs( localTreeHandle, argTreeHandle, shareTreeHandle, null );
		IupSetAttributes( varTabHandle, "TABTYPE=RIGHT,TABORIENTATION=VERTICAL,TABSPADDING=2x6" );
		//IupSetAttribute( varTabHandle, "HIGHCOLOR", "0 128 0" );
		//IupSetAttribute( varTabHandle, "TABSHIGHCOLOR", "240 255 240" );
		IupSetCallback( varTabHandle, "TABCHANGEPOS_CB", cast(Icallback) &varTabChange_cb );
		IupSetStrAttribute( varTabHandle, "TABTITLE0", GLOBAL.languageItems["locals"].toCString() );
		IupSetStrAttribute( varTabHandle, "TABTITLE1", GLOBAL.languageItems["args"].toCString() );
		IupSetStrAttribute( varTabHandle, "TABTITLE2", GLOBAL.languageItems["shared"].toCString() );
		IupSetAttribute( varTabHandle, "HIGHCOLOR", "255 0 0" );
		IupSetStrAttribute( varTabHandle, "TABSFORECOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( varTabHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( varTabHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetAttribute( varTabHandle, "SHOWLINES", "NO" );
		

		Ihandle* vbox_var0 = IupVbox( hBoxVar0_toolbar, varTabHandle, null );
		Ihandle* var0Frame = IupFrame( vbox_var0 );
		IupSetStrAttribute( var0Frame, "TITLE", GLOBAL.languageItems["variable"].toCString );
		IupSetAttribute( var0Frame, "EXPANDCHILDREN", "YES");
		Ihandle* var0ScrollBox = IupFlatScrollBox( var0Frame );
		
		btnAdd				= IupButton( null, "Add" );
		btnDel				= IupButton( null, "Del" );
		btnDelAll			= IupButton( null, "RemoveAll" );
		btnWatchRefresh		= IupButton( null, "WatchRefresh" );
		
		IupSetAttributes( btnAdd, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_debug_add" );			IupSetStrAttribute( btnAdd, "TIP", GLOBAL.languageItems["add"].toCString );
		IupSetAttributes( btnDel, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_delete" );				IupSetStrAttribute( btnDel, "TIP", GLOBAL.languageItems["remove"].toCString );
		IupSetAttributes( btnDelAll, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_deleteall" );		IupSetStrAttribute( btnDelAll, "TIP", GLOBAL.languageItems["removeall"].toCString );
		IupSetAttributes( btnWatchRefresh, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_refresh" );	IupSetStrAttribute( btnWatchRefresh, "TIP", GLOBAL.languageItems["refresh"].toCString );			

		Ihandle* hBoxVar1_toolbar = IupHbox( IupFill(), btnAdd, btnDel, btnDelAll, btnWatchRefresh, null );
		IupSetAttributes( hBoxVar1_toolbar, "ALIGNMENT=ACENTER,GAP=2" );

		IupSetCallback( btnAdd, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				scope varDlg = new CVarDlg( 260, -1, "Add Display Variable...", "Var Name:" );
				string varName = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

				if( varName == "#_close_#" ) return IUP_DEFAULT;

				GLOBAL.debugPanel.sendCommand( "display " ~ Uni.toUpper( strip( varName ) ) ~ "\n", false );
				return IUP_IGNORE;
			}
			return IUP_DEFAULT;
		});

		IupSetCallback( btnDel, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			int itemNumber = IupGetInt( GLOBAL.debugPanel.watchTreeHandle, "VALUE" );
			string numID = GLOBAL.debugPanel.getWatchItemID( itemNumber );
			if( numID.length ) GLOBAL.debugPanel.sendCommand( "delete display " ~ strip( numID ) ~ "\n", false );

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
		IupSetStrAttribute( var1Frame, "TITLE", GLOBAL.languageItems["watchlist"].toCString );
		IupSetAttribute( var1Frame, "EXPANDCHILDREN", "YES");
		Ihandle* var1ScrollBox = IupFlatScrollBox( var1Frame );
	

		varSplit = IupSplit( var1ScrollBox, var0ScrollBox );
		IupSetAttributes( varSplit, "ORIENTATION=VERTICAL,VALUE=500,LAYOUTDRAG=NO" );
		IupSetStrAttribute( varSplit, "COLOR", toStringz( GLOBAL.editColor.linenumBack ) );
		IupSetInt( varSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
		Ihandle* WatchVarBackground = IupBackgroundBox( varSplit );

		// Breakpoint
		bpTable = new CTable();
		bpTable.setDBLCLICK_CB( &CDebugger_breakpoint_doubleClick );
		
		string BARLINECOLOR;
		if( GLOBAL.editorSetting00.ColorBarLine == "ON" ) BARLINECOLOR = GLOBAL.editColor.fold;
		
		bpTable.addColumn( GLOBAL.languageItems["id"].toDString, GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		bpTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		bpTable.addColumn( GLOBAL.languageItems["line"].toDString, GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		bpTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		bpTable.setSplitAttribute( "VALUE", "500" );
		bpTable.addColumn( GLOBAL.languageItems["fullpath"].toDString, GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		bpTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		bpTable.setSplitAttribute( "VALUE", "100" );
		bpScrollBox = IupFlatScrollBox( bpTable.getMainHandle );
		
		regTable = new CTable();
		regTable.setDBLCLICK_CB( &CDebugger_register_doubleClick );
		
		regTable.addColumn( GLOBAL.languageItems["id"].toDString, GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.addColumn( GLOBAL.languageItems["name"].toDString, GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.setSplitAttribute( "VALUE", "500" );
		regTable.addColumn( GLOBAL.languageItems["value"].toDString,GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.setSplitAttribute( "VALUE", "400" );
		regTable.addColumn( GLOBAL.languageItems["value"].toDString, GLOBAL.editColor.txtFore, "", BARLINECOLOR );
		regTable.setColumnAttribute( "TITLEALIGNMENT", "ALEFT" );
		regTable.setSplitAttribute( "VALUE", "300" );
		regScrollBox = IupFlatScrollBox( regTable.getMainHandle );
		
		
		disasHandle = IupText( null );
		IupSetStrAttribute( disasHandle, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( disasHandle, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetAttributes( disasHandle, "EXPAND=YES,MULTILINE=YES,READONLY=YES,FORMATTING=YES" );

		setFont();

		tabResultsHandle = IupFlatTabs( bpScrollBox, WatchVarBackground, regScrollBox, disasHandle, null );
		IupSetAttributes( tabResultsHandle, "TABTYPE=BOTTOM,EXPAND=YES,TABSPADDING=6x2" );
		IupSetCallback( tabResultsHandle, "TABCHANGEPOS_CB", cast(Icallback) &resultTabChange_cb );
		IupSetStrAttribute( tabResultsHandle, "TABTITLE0", GLOBAL.languageItems["bp"].toCString );
		IupSetStrAttribute( tabResultsHandle, "TABTITLE1", GLOBAL.languageItems["variable"].toCString );
		IupSetStrAttribute( tabResultsHandle, "TABTITLE2", GLOBAL.languageItems["register"].toCString );
		IupSetStrAttribute( tabResultsHandle, "TABTITLE3", GLOBAL.languageItems["disassemble"].toCString );
		IupSetAttribute( tabResultsHandle, "HIGHCOLOR", "255 0 0" );
		IupSetStrAttribute( tabResultsHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( tabResultsHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( tabResultsHandle, "TABSFORECOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetAttribute( tabResultsHandle, "SHOWLINES", "NO" );
		
		rightSplitHandle = IupSplit( backtraceHandle, tabResultsHandle  );
		IupSetAttributes( rightSplitHandle, "ORIENTATION=HORIZONTAL,VALUE=150,LAYOUTDRAG=NO" );
		IupSetStrAttribute( rightSplitHandle, "COLOR", toStringz( GLOBAL.editColor.linenumBack ) );
		IupSetInt( rightSplitHandle, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
		
		mainSplit = IupSplit( leftScrollBox, rightSplitHandle );
		IupSetAttributes( mainSplit, "ORIENTATION=VERTICAL,VALUE=220,LAYOUTDRAG=NO" );
		IupSetAttribute( mainSplit, "COLOR", toStringz( GLOBAL.editColor.linenumBack ) );
		IupSetInt( mainSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
		

		mainHandle = IupScrollBox( mainSplit );
		IupSetStrAttribute( mainHandle, "TABTITLE", GLOBAL.languageItems["caption_debug"].toCString );
		IupSetAttribute( mainHandle, "TABIMAGE", "icon_debug" );
		
		
		changeIcons();
	}

	string getWhatIs( string varName )
	{
		auto colonspacePos = indexOf( varName, ": " );
		if( colonspacePos > 0 ) varName = varName[colonspacePos+2..$].dup;
	
		string type = GLOBAL.debugPanel.sendCommand( "whatis " ~ varName ~ "\n", false );
		if( type.length > 5 )
		{
			if( type[$-5..$] == "(gdb)" ) type = strip( type[0..$-5] ).dup; // remove (gdb)
			auto posAssign = indexOf( type, " = " );
			if( posAssign > 0 ) return type[posAssign+3..$].dup;
		}
		return "?";
	}

	string getPrint( string varName )
	{
		string value = GLOBAL.debugPanel.sendCommand( "print " ~ varName ~ "\n", false );

		if( value.length > 5 )
		{
			if( value[$-5..$] == "(gdb)" ) value = strip( value[0..$-5] ).dup; // remove (gdb)
			auto posAssign = indexOf( value, " = " );
			if( posAssign > 0 ) return value[posAssign+3..$].dup;
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
			if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ) == "0 128 0" ) return i;
		}
		
		return -1;
	}
	
	
	string getRealFrameIDFromTreeID( int treeID )
	{
		if( treeID > 0 )
		{
			string _title = fSTRz( IupGetAttributeId( backtraceHandle, "TITLE", treeID ) );
			if( _title.length )
			{
				if( _title[0] == '#' )
				{
					auto doublespacePos = indexOf( _title, "  " );
					if( doublespacePos > 0 ) return _title[1..doublespacePos].dup;
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
	string[] getFrameInformation( string title = "" )
	{
		if( bRunning )
		{
			string[] results;
			
			if( !title.length )
			{
				int treeID = getRealActiveFrameTreeID();
				if( treeID > 0 ) title = fSTRz( IupGetAttributeId( backtraceHandle, "TITLE", treeID ) );
			}
			
			auto atPos = lastIndexOf( title, " at " );
			if( atPos > 0 )
			{
				auto colonPos = lastIndexOf( title, ":" );
				if( colonPos > 0 && colonPos > atPos )
				{
					auto doubleSpacePos = indexOf( title, "  " );
					if( doubleSpacePos > 0 )
					{
						results ~= tools.normalizeSlash( title[atPos+4..colonPos].dup );
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
		string[] results = getFrameInformation();

		if( results.length == 4 )
		{
			int			lineNumber = to!(int)( results[1] );
			string		fp = tools.normalizeSlash( fullPathByOS( results[0] ) );
			
			if( !Path.dirName( fp ).length ) fp = DebugControl.cwd ~ fp;

			if( ScintillaAction.openFile( fp, lineNumber ) )
			{
				if( fp in GLOBAL.scintillaManager )
				{
					//#define SCI_MARKERDELETEALL 2045
					IupScintillaSendMessage( GLOBAL.scintillaManager[fp].getIupScintilla, 2045, 3, 0 );
					IupScintillaSendMessage( GLOBAL.scintillaManager[fp].getIupScintilla, 2045, 4, 0 );
				
					IupScintillaSendMessage( GLOBAL.scintillaManager[fp].getIupScintilla, 2043, lineNumber - 1, 3 ); // #define SCI_MARKERADD 2043
					IupScintillaSendMessage( GLOBAL.scintillaManager[fp].getIupScintilla, 2043, lineNumber - 1, 4 ); // #define SCI_MARKERADD 2043
				}
			}
		}
	}
	
	
	// No parameter = get active node( Blue word )
	string getFrameNodeTitle( bool bFull = false )
	{
		int treeID = getRealActiveFrameTreeID();
		if( treeID > 0 )
		{
			string _title = fSTRz( IupGetAttributeId( backtraceHandle, "TITLE", treeID ) );
			if( !bFull )
			{
				auto colonPos = lastIndexOf( _title, ":" );
				if( colonPos > 0 ) return _title[0..colonPos].dup;
			}
			else
			{
				return _title;
			}
		}
		
		return null;
	}
	
	
	string fixGDBMessage( string _result )
	{
		string[] results = splitLines( _result );
		if( results.length > 1 )
			if( results[$-1] == "(gdb)" ) results.length = results.length - 1; // remove (gdb)

		_result = "";

		if( results.length > 0 )
		{
			string trueLineData;
			foreach_reverse( s; results )
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
						trueLineData = " " ~ strip( trueLineData );
					}
				}
			}
		}

		return  _result;
	}
	
	
	VarObject transformNodeToVarObject( string title )
	{
		VarObject _vo;
		
		auto assignPos = indexOf( title, " = " );
		if( assignPos > 0 )
		{
			_vo.name = title[0..assignPos].dup;
			if( _vo.name.length )
			{
				auto colonspacePos = indexOf( _vo.name, ": " );
				if( colonspacePos < assignPos && colonspacePos > 0 ) _vo.name = _vo.name[colonspacePos+2..$].dup;
			}
			
			auto openPos = indexOf( title, " (" );
			if( openPos > 0 )
			{
				auto closePos = lastIndexOf( title, ") " );
				if( closePos > 0 && closePos > openPos + 2 )
				{
					_vo.type = title[openPos+2..closePos].dup;
					_vo.value = title[closePos+2..$].dup;
				}
			}
			else
			{
				_vo.value = strip( title[assignPos+3..$].dup );
			}
		}
		
		return _vo;
	}


	VarObject getTypeVarValueByName( string name )
	{
		VarObject result;
		
		result.name = name;

		string value = getPrint( name );
		if( value != "?" )
		{
			result.value = value;
			if( value[0] == '(' )
			{
				auto closePos = lastIndexOf( value, ") " );
				if( closePos > 0 )
				{
					result.value = value[closePos+2..$].dup;
					result.type = value[1..closePos].dup;
				}
			}
		}
		
		if( result.type.length )
		{
			string type = getWhatIs( name );
			if( type != "?" ) result.type = type;	
		}
		
		return result;
	}
	
	
	VarObject[] getTypeVarValueByLinesFromInfo( string gdbMessage )
	{
		if( !isRunning ) return null;
		
		VarObject[] results;
		
		foreach( s; splitLines( fixGDBMessage( gdbMessage ) ) )
		{
			auto closePos = s.length;
			auto assignPos = indexOf( s, " = " );
			if( assignPos > 0 )
			{
				VarObject _vo;
				_vo.name = strip( s[0..assignPos] );
				
				// <gdb>display, sometimes we got type of vars
				if( indexOf( s, " = (" ) == assignPos ) closePos = lastIndexOf( s, ") " );
				
				if( closePos > -1 && closePos < s.length )
				{
					_vo.value = strip( s[closePos+2..$].dup );
					_vo.type = s[assignPos+4..closePos].dup;
				}
				else
				{
					_vo.value = strip( s[assignPos+3..$].dup );
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
	
	
	VarObject[] getTypeVarValueByLinesFromPrint( string gdbMessage, string motherName )
	{
		if( !isRunning )		return null;
		if( gdbMessage == "?" )	return null;
		
		gdbMessage = fixGDBMessage( gdbMessage );

		string			data;
		VarObject[]		vos;

		/*
		{SCI = 0x2ab2bb0, _P = {X = 100, Y = 200}, P = 0x1eaf584}						
		*/
		for( int i = 1; i < gdbMessage.length; ++ i )
		{
			string _type, _var, _value;
			
			if( i == gdbMessage.length - 1 )
			{
				if( data.length )
				{
					auto assignPos = indexOf( data, " = " );
					if( assignPos > -1 )
					{
						if( indexOf( data, "[" ) > -1  )
						{
							_var = strip( data[0..assignPos] );
							_value = data[assignPos+3..$];
							VarObject _vo = { "", _var, _value };
							vos = _vo ~ vos;
						}
						else
						{
							_type = GLOBAL.debugPanel.getWhatIs( motherName ~ "." ~ data[0..assignPos] );
							_var = strip( data[0..assignPos] );
							_value = data[assignPos+3..$];
							VarObject _vo = { _type, _var, _value };
							vos = _vo ~ vos;
						}
					}
					else
					{
						VarObject _vo = { "", "", strip( data ) };
						vos = _vo ~ vos;
					}
				}
			}
			else if( gdbMessage[i] == ','  )
			{
				string type;
				auto assignPos = indexOf( data, " = " );
				if( assignPos > -1 )
				{
					if( indexOf( data, "[" ) > -1  )
					{
						_var = strip( data[0..assignPos] );
						_value = data[assignPos+3..$];
						VarObject _vo = { "", _var, _value };
						vos = _vo ~ vos;
					}
					else
					{
						_type = GLOBAL.debugPanel.getWhatIs( motherName ~ "." ~ data[0..assignPos] );
						_var = strip( data[0..assignPos] );
						_value = data[assignPos+3..$];
						VarObject _vo = { _type, _var, _value };
						vos = _vo ~ vos;
					}
				}
				else
				{
					VarObject _vo = { "", "", strip( data ) };
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
							auto assignPos = indexOf( data, " = " );
							if( assignPos > -1 )
							{
								if( indexOf( data, "[" ) > 0 ) _type = ""; else _type = GLOBAL.debugPanel.getWhatIs( motherName ~ "." ~ data[0..assignPos] );
								_var = strip( data[0..assignPos] );
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
	
	
	void checkErrorOccur( string message, string errorMessage = null )
	{
		//int head = Util.index( message, "Program received signal SIGSEGV, Segmentation fault." );
		//int head = Util.index( message, "Segmentation fault." );
		auto head = indexOf( message, "signal SIGSEGV," );
		if( head > -1 )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..$-5].dup ) );
			return;
		}

		//int head = Util.index( message, "Floating point exception" );
		head = indexOf( message, "signal SIGFPE," );
		if( head > -1 )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..$-5].dup ) );
			return;
		}
		
		head = indexOf( message, "signal SIGABRT," );
		if( head > -1 )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..$-5].dup ) );
			return;
		}
		
		
		head = indexOf( message, "The program is not being run." );
		if( head > -1 )
		{
			IupMessageError( GLOBAL.mainDlg, toStringz( message[head..$-5].dup ) );
			return;
		}
	}
	
	
	string removeIDTitle( string s )
	{
		auto assignPos = indexOf( s, " = " );
		if( assignPos > 0 )
		{
			auto colonspacePos = indexOf( s, ": " );
			if( colonspacePos > 0 ) return s[colonspacePos+2..$].dup;
		}
		
		return s;
	}
	
	
	string getWatchItemID( string s )
	{
		if( s.length )
		{
			if( s[0] > 47 && s[0] < 58 )
			{
				auto colonSpacePos = indexOf( s, ": " );
				if( colonSpacePos > 0 ) return s[0..colonSpacePos].dup;
			}
		}
		
		return null;
	}
	
	
	string getWatchItemID( int id )
	{
		if( id > -1 )
		{
			string title = fSTRz( IupGetAttributeId( watchTreeHandle, "TITLE", id ) );
			return getWatchItemID( title );
		}
		
		return null;
	}
	
	
	// Update locals tree
	void updateInfoTree( VarObject[] variables, Ihandle* treeHandle, int motherID )
	{
		if( bRunning )
		{
			bool	bNoSameDeepNode = false;
			
			for( int i = cast(int) variables.length - 1; i >= 0; -- i )
			{
				if( !bNoSameDeepNode )
				{
					string	numID;
					auto		colonspacePos = indexOf( variables[i].name, ": " );
					if( colonspacePos > 0 )
					{
						numID = variables[i].name[0..colonspacePos+2].dup;
						variables[i].name = variables[i].name[colonspacePos+2..$].dup;
					}
					
					auto _voFromNode = transformNodeToVarObject( fSTRz( IupGetAttributeId( treeHandle, "TITLE", motherID ) ) );
					
					if( variables[i].name == _voFromNode.name && variables[i].type == _voFromNode.type )//&& _vo.file = _voFromNode.file && _vo.frame == _voFromNode.frame )
					{
						string _title = numID ~ variables[i].name ~ " = " ~ ( variables[i].type.length ? "(" ~  variables[i].type ~ ") " : "" ) ~ variables[i].value;
						IupSetStrAttributeId( treeHandle, "TITLE", motherID, toStringz( _title ) );
						if( variables[i].value != _voFromNode.value ) IupSetAttributeId( treeHandle, "COLOR", motherID, "255 0 0" ); else IupSetStrAttributeId( treeHandle, "COLOR", motherID, toStringz( GLOBAL.editColor.dlgFore ) );
						if( treeHandle == watchTreeHandle && numID.length )
						{
							string fontString = Array.replace( GLOBAL.fonts[9].fontString.dup, ",", ",Bold " );
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
						string _title = numID ~ variables[i].name ~ " = " ~ ( variables[i].type.length ? "(" ~  variables[i].type ~ ") " : "" ) ~ variables[i].value;
						if( variables[i].value == "{...}" ) IupSetStrAttributeId( treeHandle, "INSERTBRANCH", motherID, toStringz( _title ) ); else IupSetAttributeId( treeHandle, "INSERTLEAF", motherID, toStringz( _title ) );
						if( treeHandle == watchTreeHandle && numID.length )
						{
							string fontString = Array.replace( GLOBAL.fonts[9].fontString.dup, ",", ",Bold " );
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
							string fullVarName = getFullVarNameInTree( treeHandle, motherID );
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
					string _title = variables[i].name ~ " = " ~ ( variables[i].type.length ? "(" ~  variables[i].type ~ ") " : "" ) ~ variables[i].value;
					if( variables[i].value == "{...}" ) IupSetStrAttributeId( treeHandle, "INSERTBRANCH", motherID, toStringz( _title ) ); else IupSetStrAttributeId( treeHandle, "INSERTLEAF", motherID, toStringz( _title ) );
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
			string[] frameInformation = getFrameInformation();
			if( frameInformation.length == 4 )
			{
				string[] results = splitLines( GLOBAL.debugPanel.fixGDBMessage( GLOBAL.debugPanel.sendCommand( "info line " ~ frameInformation[1] ~ "\n", false ) ) );

				if( results.length == 1 ) // NO ERROR
				{
					string startAddress, endAddress;
					
					auto startPos = indexOf( results[0], "starts at address " );
					auto endPos = indexOf( results[0], "ends at " );
					if( endPos > startPos && startPos > -1 )
					{
						auto startSpacePos = indexOf( results[0], " ", startPos + 18 );
						if( startSpacePos > 0 ) startAddress = results[0][startPos+18..startSpacePos].dup;
						
						auto endSpacePos = indexOf( results[0], " ", endPos + 8 );
						if( endSpacePos > 0 ) endAddress = results[0][endPos+8..endSpacePos].dup;
						
						if( startAddress.length && endAddress.length )
						{
							string result = GLOBAL.debugPanel.sendCommand( "disassemble /m " ~ startAddress ~ "," ~ endAddress ~ "\n", false );
							if( result.length > 5 )
							{
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "VALUE", toStringz( results[0] ~ "\n\n" ~ result[0..$-5] ) );
								IupSetInt( GLOBAL.debugPanel.disasHandle, "SCROLLTOPOS", 0 );

								Ihandle* formattag0;
								formattag0 = IupUser();
								IupSetStrAttribute( formattag0, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
								IupSetAttribute( formattag0, "SELECTION", "ALL" );
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "ADDFORMATTAG_HANDLE", cast(char*)formattag0 );
								
								Ihandle* formattag;
								formattag = IupUser();
								IupSetAttribute( formattag, "FGCOLOR", "99 37 35" );
								IupSetAttribute( formattag, "UNDERLINE", "SINGLE" );
								IupSetAttribute( formattag, "WEIGHT", "SEMIBOLD" );
								IupSetAttribute( formattag, "SELECTION", "1,1:1,500" );
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "ADDFORMATTAG_HANDLE", cast(char*)formattag );

								Ihandle* formattag1;
								formattag1 = IupUser();
								IupSetAttribute( formattag1, "FGCOLOR", "45 117 27" );
								IupSetAttribute( formattag1, "WEIGHT", "SEMIBOLD" );
								IupSetAttribute( formattag1, "SELECTION", "4,1:4,500" );
								IupSetAttribute( GLOBAL.debugPanel.disasHandle, "ADDFORMATTAG_HANDLE", cast(char*)formattag1 );
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
			if( fromStringz( IupGetAttributeId( TREE, "COLOR", i ) ) != "255 0 0" ) IupSetStrAttributeId( TREE, "COLOR", i, toStringz( GLOBAL.editColor.dlgFore ) );
	}
	
	void changeIcons()
	{
		string tail;
		if( GLOBAL.editorSetting00.IconInvert == "ON" ) tail = "_invert";

		IupSetStrAttribute( btnClear, "IMAGE", toStringz( "icon_debug_clear" ~ tail ) );
		IupSetStrAttribute( btnResume, "IMAGE", toStringz( "icon_debug_resume" ~ tail ) );
		IupSetStrAttribute( btnStop, "IMAGE", toStringz( "icon_debug_stop" ~ tail ) );
		IupSetStrAttribute( btnStep, "IMAGE", toStringz( "icon_debug_step" ~ tail ) );
		IupSetStrAttribute( btnNext, "IMAGE", toStringz( "icon_debug_next" ~ tail ) );
		IupSetStrAttribute( btnReturn, "IMAGE", toStringz( "icon_debug_return" ~ tail ) );
		IupSetStrAttribute( btnUntil, "IMAGE", toStringz( "icon_debug_until" ~ tail ) );
		IupSetStrAttribute( btnTerminate, "IMAGE", toStringz( "icon_clear" ~ tail ) );
		
		IupSetStrAttribute( btnLeft, "IMAGE", toStringz( "icon_debug_left" ~ tail ) );
		IupSetStrAttribute( btnRefresh, "IMAGE", toStringz( "icon_refresh" ~ tail ) );

		IupSetStrAttribute( btnAdd, "IMAGE", toStringz( "icon_debug_add" ~ tail ) );
		IupSetStrAttribute( btnWatchRefresh, "IMAGE", toStringz( "icon_refresh" ~ tail ) );
	}	

public:
	this()
	{
		createLayout();
	}
	
	~this()
	{
		if( isExecuting || isRunning ) terminal();
	}
	
	void adjustColor()
	{
		IupSetStrAttribute( mainHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		//IupSetStrAttribute( IupGetParent( txtConsoleCommand ), "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		//IupRedraw( mainHandle, 1 );
	}
	
	void changeColor()
	{
		IupSetStrAttribute( varTabHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( varTabHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( varTabHandle, "TABSFORECOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( tabResultsHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( tabResultsHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( tabResultsHandle, "TABSFORECOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		
		if( GLOBAL.editorSetting00.ColorBarLine == "ON" )
		{
			bpTable.setGlobalColor( GLOBAL.editColor.txtFore, GLOBAL.editColor.fold, GLOBAL.editColor.fold );
			regTable.setGlobalColor( GLOBAL.editColor.txtFore, GLOBAL.editColor.fold, GLOBAL.editColor.fold );
			IupSetStrAttribute( varSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
			IupSetStrAttribute( rightSplitHandle, "COLOR", toStringz( GLOBAL.editColor.fold ) );
			IupSetStrAttribute( mainSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );			
		}
		else
		{
			bpTable.setGlobalColor( GLOBAL.editColor.txtFore, "", "-1" );
			regTable.setGlobalColor( GLOBAL.editColor.txtFore, "", "-1" );
			IupSetAttribute( varSplit, "SHOWGRIP", "LINES" );
			IupSetAttribute( rightSplitHandle, "SHOWGRIP", "LINES" );
			IupSetAttribute( mainSplit, "SHOWGRIP", "LINES" );
		}
		

		changeTreeNodeColor( watchTreeHandle );
		changeTreeNodeColor( localTreeHandle );
		changeTreeNodeColor( argTreeHandle );
		changeTreeNodeColor( shareTreeHandle );
		
		for( int i = 0; i < IupGetInt( backtraceHandle, "COUNT" ); ++ i )	
			if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ) != "0 128 0" ) IupSetStrAttributeId( backtraceHandle, "COLOR", i, toStringz( GLOBAL.editColor.dlgFore ) );
		
	}

	void setFont()
	{
		IupSetStrAttribute( consoleHandle, "FONT", toStringz( GLOBAL.fonts[9].fontString ) );
		IupSetStrAttribute( watchTreeHandle, "FONT",  toStringz( GLOBAL.fonts[9].fontString ) );
		IupSetStrAttribute( localTreeHandle, "FONT",  toStringz( GLOBAL.fonts[9].fontString ) );
		IupSetStrAttribute( argTreeHandle, "FONT",  toStringz( GLOBAL.fonts[9].fontString ) );
		IupSetStrAttribute( shareTreeHandle, "FONT",  toStringz( GLOBAL.fonts[9].fontString ) );
		//IupSetAttribute( varTabHandle, "FONT",  _font );
		//IupSetStrAttribute( disasHandle, "FONT",  _font );
		
		for( int i = 0; i < IupGetInt( watchTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( watchTreeHandle, "TITLEFONT", i, toStringz( GLOBAL.fonts[9].fontString ) );

		for( int i = 0; i < IupGetInt( localTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( localTreeHandle, "TITLEFONT", i, toStringz( GLOBAL.fonts[9].fontString ) );

		for( int i = 0; i < IupGetInt( argTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( argTreeHandle, "TITLEFONT", i, toStringz( GLOBAL.fonts[9].fontString ) );

		for( int i = 0; i < IupGetInt( shareTreeHandle, "COUNT" ); ++ i )
			IupSetStrAttributeId( shareTreeHandle, "TITLEFONT", i, toStringz( GLOBAL.fonts[9].fontString ) );
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

	
	string getTypeValueByName( string varName, string originTitle, ref string type, ref string value )
	{
		string nodeTitle, THIS;
		
		auto assignPos = indexOf( originTitle, "=" );
		if( assignPos > 0 ) originTitle = strip( originTitle[0..assignPos].dup );
		
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
			auto dotPos = lastIndexOf( varName, "." );
			if( value[0] == '{' )
			{
				//value = "{...}";
				if( indexOf( originTitle, '.' ) > 0 )
				{
					//nodeTitle = originTitle ~ " = (" ~  type ~ ") {...}";
					nodeTitle = originTitle ~ " = (" ~  type ~ ") " ~ value;
				}
				else
				{
					//if( dotPos < varName.length ) nodeTitle = varName[dotPos+1..$] ~ " = (" ~  type ~ ") {...}"; else nodeTitle = varName ~ " = (" ~  type ~ ") {...}";
					if( dotPos > 0 ) nodeTitle = varName[dotPos+1..$] ~ " = (" ~  type ~ ") " ~ value; else nodeTitle = varName ~ " = (" ~  type ~ ") " ~ value;
				}
			}
			else
			{
				if( indexOf( value, ')' ) > -1 ) // contain ) 
				{
					if( indexOf( originTitle, '.' ) > -1 ) // contain .
						nodeTitle = originTitle ~ " = " ~ value;
					else
					{
						if( dotPos > 0 ) nodeTitle = varName[dotPos+1..$] ~ " = " ~ value; else nodeTitle = varName ~ " = " ~ value;
					}
				}
				else
				{
					if( indexOf( originTitle, '.' ) > -1 ) // contain .
						nodeTitle = originTitle ~ " = (" ~  type ~ ") " ~ value;
					else
					{
						if( dotPos > 0 ) nodeTitle = varName[dotPos+1..$] ~ " = (" ~  type ~ ") " ~ value; else nodeTitle = varName ~ " = (" ~  type ~ ") " ~ value;
					}
				}
				
				auto closeParenPos = lastIndexOf( value, ")" );
				if( closeParenPos > 0 ) value = strip( value[closeParenPos+1..$].dup );
			}
			
			return strip( nodeTitle );
		}
		
		value = type = "";
		return null;
	}
	
	string getFullVarNameInTree( Ihandle* _tree, int id = -99, bool bNoStar = false )
	{
		if( GLOBAL.debugPanel.isRunning )
		{
			if( _tree != null )
			{
				if( id < 0 ) id = IupGetInt( _tree, "VALUE" );

				if( id > -1 )
				{
					bNoStar = true;
					
					string	title;
					string	varName;
					int		parnetID = id, _depth = IupGetIntId( _tree, "DEPTH", id );
					while( _depth >= 0 )
					{
						title = fSTRz( IupGetAttributeId( _tree, "TITLE", parnetID ) ); // Get Tree Title
						auto assignPos = indexOf( title, " = " );
						if( assignPos > 0 )
						{
							// Remove ID
							auto colonspacePos = indexOf( title, ": " );
							if( colonspacePos > 0 )
							{
								title = title[colonspacePos+2..$].dup;
								assignPos = indexOf( title, " = " );
							}
						
							varName = strip( varName );
							if( varName.length )
							{
								varName = ( ( varName[0] == '[' ) ? (title[0..assignPos] ~ varName ) : ( title[0..assignPos] ~ "." ~ varName ) );
							}
							else
							{
								varName = title[0..assignPos].dup;
							}
							
							if( bNoStar )
							{
								varName = stripLeft( varName, "*" );
								varName = stripLeft( varName, "&" );
							}
						}

						if( _depth <= 0 ) break;
						parnetID = IupGetIntId( _tree, "PARENT", parnetID );
						_depth = IupGetIntId( _tree, "DEPTH", parnetID );
					}

					if( varName.length )
					{
						if( varName[$-1] == '.' ) varName = varName[0..$-1].dup;
						return varName;
					}
				}
			}
		}
		
		return null;
	}
	

	string sendCommand( string command, bool bShow = true  )
	{
		if( DebugControl is null ) return null;

		string result = DebugControl.sendCommand( command, bShow );

		// Check GDB reach end
		auto gdbEndStringPosTail = lastIndexOf( result, "exited normally]" );
		if( gdbEndStringPosTail > 0 )
		{
			auto gdbEndStringPosHead = lastIndexOf( result, "[Inferior" );
			if( gdbEndStringPosHead > 0 )
			{
				int _result = tools.questMessage( "GDB", result[gdbEndStringPosHead..gdbEndStringPosTail+16] ~ "\n" ~ GLOBAL.languageItems["exitdebug1"].toDString );
				if( _result == 1 )
				{
					terminal();
					return null;
				}					
			}
		}
		
		string[] splitCommand;
		foreach( s; Array.split( strip( command ), " " ) ) // Util.trim() remove \n
		{
			if( s.length ) splitCommand ~= s;
		}


		if( splitCommand.length )
		{
			switch( Uni.toLower( splitCommand[0] ) )
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
							string _id, _fullPath, _lineNumber;
							
							auto tail = indexOf( result, " at" );
							auto head = indexOf( result, "Breakpoint " );
							if( tail > head + 11 ) _id = result[head+11..tail].dup;

							head = lastIndexOf( result, ": file " );
							tail = lastIndexOf( result, ", line " );
							if( tail > head + 7 && head > 0 ) _fullPath = tools.normalizeSlash( result[head+7..tail] );
							
							head = lastIndexOf( result, ", line " );
							tail = lastIndexOf( result, "." );
							if( tail > head + 7 && head > 0 ) _lineNumber = result[head+7..tail].dup;
							
							bpTable.addItem( [ _id, _lineNumber, _fullPath ] );
							IupRefresh( bpScrollBox );
						}
					}
					break;

				case "d", "del", "delete":
					if( splitCommand.length == 2 )
					{
						if( Uni.toLower( splitCommand[1] ) == "display" )
						{
							IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
						}
						else
						{
							for( int i = bpTable.getItemCount(); i > 0; -- i )
							{
								string[] values = bpTable.getSelection( i );
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
						if( Uni.toLower( splitCommand[1] ) == "display" )
						{
							if( bRunning )
							{
								string[] results = splitLines( fixGDBMessage( result ) ); // remove (gdb)
								if( results.length == 0 ) // NO ERROR
								{
									string _id = strip( splitCommand[2] );
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
							string fontString = Array.replace( GLOBAL.fonts[9].fontString, ",", ",Bold " );
							foreach( VarObject _vo; variables )
							{
								string _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~  _vo.type ~ ") " : "" ) ~ _vo.value;
								if( _vo.value == "{...}" ) IupSetStrAttributeId( watchTreeHandle, "INSERTBRANCH", -1, toStringz( _title ) ); else IupSetStrAttributeId( watchTreeHandle, "INSERTLEAF", -1, toStringz( _title ) );
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
						string fontString = Array.replace( GLOBAL.fonts[9].fontString, ",", ",Bold " );
						foreach( VarObject _vo; variables )
						{
							string _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~  _vo.type ~ ") " : "" ) ~ _vo.value;
							if( _vo.value == "{...}" ) IupSetStrAttributeId( watchTreeHandle, "INSERTBRANCH", -1, toStringz( _title ) ); else IupSetStrAttributeId( watchTreeHandle, "INSERTLEAF", -1, toStringz( _title ) );
							IupSetStrAttributeId( watchTreeHandle, "TITLEFONT", 0, toStringz( fontString ) );
						}
					}
					break;

				case "undisplay":
					if( bRunning )
					{
						string[] results = splitLines( fixGDBMessage( result ) ); // remove (gdb)
						if( results.length == 0 ) // NO ERROR
						{
							string _id = strip( splitCommand[2] );

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
								string[] _information = getFrameInformation( fSTRz( IupGetAttributeId( backtraceHandle, "TITLE", i ) ) );
								if( _information.length == 4 )
								{
									if( _information[2] == splitCommand[1] )
									{
										if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ) != "0 128 0" )
										{
											IupSetAttributeId( backtraceHandle, "COLOR", i, "0 128 0" );
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
							int TargetID = treeID - to!(int)( splitCommand[1] );
							if( TargetID > 0 )
							{
								string frame = getRealFrameIDFromTreeID( TargetID );
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
							int TargetID = treeID + to!(int)( splitCommand[1] );
							if( TargetID < IupGetInt( backtraceHandle, "COUNT" ) )
							{
								string frame = getRealFrameIDFromTreeID( TargetID );
								sendCommand(  "select-frame " ~ frame ~ "\n", false );
							}
						}
					}
					break;
					
				case "bt", "backtrace", "where":
					if( bRunning )
					{
						string[] results = splitLines( fixGDBMessage( result ) ); // remove (gdb)
						if( results.length > 0 )
						{
							IupSetAttributeId( backtraceHandle, "DELNODE", 0, "CHILDREN" );

							bool	bFirstInsert = true;
							string	branchString;

							for( int i = cast(int) results.length - 1; i >= 0;  -- i )
							{
								if( results[i].length )
								{
									if( strip( results[i] )[0] != '#' )
									{
										branchString = " " ~ strip( results[i] ) ~ branchString;
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
										if( GLOBAL.editorSetting00.IconInvert == "ON" )
										{
											IupSetAttributeId( backtraceHandle, "IMAGE", lastID, "icon_debug_bt1_invert" );
											IupSetAttributeId( backtraceHandle, "IMAGEEXPANDED", lastID, "icon_debug_bt1_invert" );
										}
										else
										{
											IupSetAttributeId( backtraceHandle, "IMAGE", lastID, "icon_debug_bt1" );
											IupSetAttributeId( backtraceHandle, "IMAGEEXPANDED", lastID, "icon_debug_bt1" );
										}
										if( i == 0 )
										{
											IupSetAttributeId( backtraceHandle, "COLOR", lastID, "0 128 0" );
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
							IupScintillaSendMessage( cSci.getIupScintilla, 2045, 3, 0 ); //#define SCI_MARKERDELETEALL 2045
							IupScintillaSendMessage( cSci.getIupScintilla, 2045, 4, 0 ); //#define SCI_MARKERDELETEALL 2045
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
								goto case;
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
											string _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~  _vo.type ~ ") " : "" ) ~ _vo.value;
											if( _vo.value == "{...}" ) IupSetStrAttributeId( _treeHandle, "INSERTBRANCH", -1, toStringz( _title ) ); else IupSetStrAttributeId( _treeHandle, "INSERTLEAF", -1, toStringz( _title ) );
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
									string[] results = splitLines( fixGDBMessage( result ) ); // remove (gdb)

									bool		bGlobal;
									string		fileFullPath;
									int			fileID = -1, id;
									
									IupSetAttribute( shareTreeHandle, "DELNODE", "ALL" );
									
									foreach( lineData; results )
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
													fileFullPath = lineData[4..$-1].dup;
													IupSetStrAttributeId( shareTreeHandle, "INSERTBRANCH", fileID, toStringz( fileFullPath ) );
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
													string[]	splitData = Array.split( lineData[0..$-1], " " );
													string		varName, typeName, value;
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
														if( i > 0 ) varName = varName[i..$].dup; else typeName = typeName[0..$-1].dup;

														value = getPrint( varName );
													}
													
													if( varName.length )
													{
														string _string = varName ~ " = " ~ value;
														if( value.length )
														{
															if( value[0] == '{' )
															{
																value = "{...}";
																_string = varName ~ " = (" ~  typeName ~ ") " ~ value;
															}
														}
														
														if( IupGetIntId( shareTreeHandle, "DEPTH", id ) == 0 )
														{
															if( value == "{...}" ) IupSetStrAttributeId( shareTreeHandle, "ADDBRANCH", id, toStringz( _string ) );else IupSetStrAttributeId( shareTreeHandle, "ADDLEAF", id, toStringz( _string ) );
														}
														else
														{
															if( value == "{...}" ) IupSetStrAttributeId( shareTreeHandle, "INSERTBRANCH", id, toStringz( _string ) );else IupSetStrAttributeId( shareTreeHandle, "INSERTLEAF", id, toStringz( _string ) );
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
									string[] results = splitLines( fixGDBMessage( result ) ); // remove (gdb)
									if( results.length)
									{
										if( splitCommand.length == 2 )
										{
											bool bFirst = true;
											if( regTable.getItemCount > 0 ) bFirst = false;
											
											string[] oldValues;
											for( int i = 0; i < regTable.getItemCount; ++ i )
											{
												auto _values = regTable.getSelection( i + 1 );
												oldValues ~= _values[2];
											}
											regTable.removeAllItem();
											
											for( int i = 0; i < results.length; ++i )
											{
												string[] values;
												auto spacePos = indexOf( results[i], " " );
												if( spacePos > 0 )
												{
													values ~= to!(string)( i );
													values ~= results[i][0..spacePos].dup;
													
													string		valueString = strip( results[i][spacePos..$].dup );
													string[]	splitValue = Array.split( valueString, "\t" );
													
													if( splitValue.length == 2 )
													{
														values ~= splitValue;
													}
													else
													{
														spacePos = indexOf( valueString, " " );
														if( spacePos > 0 )
														{
															values ~= valueString[0..spacePos].dup;
															values ~= strip( valueString[spacePos..$].dup );
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
												auto spacePos = indexOf( result, " " );
												if( spacePos > 0 )
												{
													string		name = result[0..spacePos].dup;
													string[]	values = ( Array.split( strip( result[spacePos..$] ), "\t" ) );
													if( values.length == 2 && name.length )
													{
														for( int i = regTable.getItemCount; i > 0; -- i )
														{
															string[] _values = regTable.getSelection( i );
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
		if( DebugControl !is null )
		{
			DebugControl.bExecuted = false;
			destroy( DebugControl );
			DebugControl = null;
		}
		IupSetAttribute( consoleHandle, "VALUE", "" );
		IupSetAttribute( getConsoleCommandInputHandle, "VALUE", "" ); // Clear Input Text
		
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
		string	command;
		string	activePrjName = actionManager.ProjectAction.getActiveProjectName();

		auto activeCScintilla = actionManager.ScintillaAction.getActiveCScintilla();
		if( activeCScintilla !is null )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
			IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
			
			int nodeCount = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
			for( int id = 1; id <= nodeCount; id++ )
			{
				string _cstring = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
				if( _cstring == activeCScintilla.getFullPath() )
				{
					version(Windows) IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" ); else IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );

					bRunProject = true;

					if( GLOBAL.projectManager[activePrjName].type.length )
					{
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
				string _f = Path.stripExtension( activeCScintilla.getFullPath );
				version(Windows)
				{
					command = _f ~ ".exe";
				}
				else
				{
					command = _f;
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
		
		if( std.file.exists( command ) )
		{
			bool b64Bit = GLOBAL.compilerSettings.Bit64 == "OFF" ? false : true;
			string debuggerExe = !b64Bit ? GLOBAL.compilerSettings.debuggerFullPath : GLOBAL.compilerSettings.x64debuggerFullPath;
			version(Posix) debuggerExe = GLOBAL.compilerSettings.debuggerFullPath;
			foreach( s; environment.toAA.keys )
			{
				debuggerExe = Array.replace( debuggerExe, "%"~s~"%", GLOBAL.EnvironmentVars[s] );
			}

			GLOBAL.messagePanel.printOutputPanel( "Running " ~ command ~ "......", true );
			if( std.file.exists( debuggerExe ) )
			{
				if( Uni.toLower( Path.baseName( debuggerExe ) ) == "fbdebugger.exe" )
				{
					IupExecute( toStringz( tools.normalizeSlash( debuggerExe, ) ), toStringz( command ) );
				}
				else
				{
					DebugControl = new DebugThread( debuggerExe, "\"" ~ command ~ "\"", Path.dirName( GLOBAL.compilerSettings.debuggerFullPath ) );
				}
			}
			else
			{
				version(linux)
					DebugControl = new DebugThread( debuggerExe, "\"" ~ command ~ "\"", Path.dirName( GLOBAL.compilerSettings.debuggerFullPath ) );
				else
				{
					GLOBAL.messagePanel.printOutputPanel( "\nDebugger: " ~ GLOBAL.compilerSettings.debuggerFullPath ~ " isn't existed!\nRun Error!", false );
					IupMessageError( null, "Debugger isn't existed!" );
					return false;
				}
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
			string oriBTName = getFrameNodeTitle();
			
			string result = sendCommand( "bt\n", false );
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

	void addBP( string _fullPath, string _lineNum )
	{
		_fullPath = tools.fullPathByOS( _fullPath ).dup;
		
		if( isExecuting || isRunning )
		{
			string result = sendCommand( "b " ~ _fullPath ~ ":" ~ _lineNum ~ "\n" );
		}
		else
		{
			bpTable.addItem( [ "-1", _lineNum, _fullPath ] );
		}
	}

	void removeBP( string _fullPath, string _lineNum )
	{
		_fullPath = tools.fullPathByOS( _fullPath );
		
		if( isExecuting || isRunning )
		{
			for( int i = bpTable.getItemCount(); i > 0; -- i )
			{
				string[] values = bpTable.getSelection( i );
				if( values.length == 3 )
				{
					if( values[1] == _lineNum && tools.fullPathByOS( values[2] ) == _fullPath )
					{
						if( to!(int)(values[0]) > 0 ) 
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
				string[] values = bpTable.getSelection( i );
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
	this( int w, int h, string title, string _labelText = null,  string textWH = null, string text = null, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, _labelText, textWH, text, bResize, parent );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CConsoleDlg_btnCancel_cb );
		IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CConsoleDlg_btnCancel_cb );
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
	import						std.stdio, std.process, core.thread, std.file, std.windows.charset;
	version(Windows)	import	core.sys.windows.winbase, core.sys.windows.windef;
	version(Posix)		import	core.sys.posix.fcntl : fcntl, F_SETFL, O_NONBLOCK;
	
	string			debuggerExe, executeFullPath, cwd, stderrMessage;
	bool			b64Bit;
	int				caretPos, splitValue;
	ProcessPipes	proc;
	bool			bStdoutNOBLOCK, bStderrNOBLOCK;

	string getGDBmessage( int deleyms = 100 )
	{
		try
		{
			char c;
			string stdoutString, stderrString;
			
			while( 1 )
			{
				if( proc.stdout.readf( "%c", c ) <= 0 ) break;
				stdoutString ~= c;
				if( c == ')' )
				{
					if( stdoutString.length > 4 )
					{
						if( stdoutString[$-5..$] == "(gdb)" ) break;
					}
				}
			}
			
			// Check Stderr message.
			// Prevent Windows hanging.......
			int ch;
			if( bStderrNOBLOCK )
			{
				auto fp = proc.stderr.getFP();
				while( ( ch = fgetc(fp)) != EOF )
				{ 
					stderrString ~= cast(char) ch;
				}
				
				version(Windows) stderrString = fromMBSz( toStringz( strip( stderrString ) ~ "\0" ) );
			}
			else
			{
				version(Windows)
				{
					uint iTotalBytesAvail, iNumberOfBytesWritten;
					char[4096] sBuf;

					PeekNamedPipe( proc.stderr.windowsHandle, null, 0, null, &iTotalBytesAvail, null);
					if( iTotalBytesAvail > 0 )
					{
						while( iTotalBytesAvail > 0  )
						{
							if( iTotalBytesAvail > 4096 ) iTotalBytesAvail = 4096;
							ReadFile( proc.stderr.windowsHandle, sBuf.ptr, iTotalBytesAvail, &iNumberOfBytesWritten, null );
							stderrString ~= sBuf[0..iNumberOfBytesWritten];
							PeekNamedPipe( proc.stderr.windowsHandle, null, 0, null, &iTotalBytesAvail, null);
						}
					}
				}
			}
			
			if( stderrString.length )
			{
				tools.questMessage( "Alarm", stderrString, "WARNING", "OK" );
				stderrMessage = stderrString;
			}
			else
				stderrMessage = "";
			
			return strip( stdoutString );
		}
		catch( Exception e )
		{
			debug writefln( "getGDBmessage() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Conv.to!(string)( e.line ) );
		}

		return "(gdb)";
	}
	

public:
	bool		bExecuted;

	this( string _debuggerExe, string _executeFullPath, string _cwd = null )
	{
		debuggerExe = _debuggerExe;
		executeFullPath = _executeFullPath;
		cwd = _cwd;
		run();
	}

	~this()
	{
		auto s = tryWait( proc.pid );
		if( !s.terminated && s.status == 0 ) kill( proc.pid );
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
			
			proc = pipeShell( "\"" ~ debuggerExe ~ "\" " ~ executeFullPath, Redirect.all, environment.toAA, Config.suppressConsole, cwd );
			version(Windows)
			{
				auto x = PIPE_NOWAIT;
				if( SetNamedPipeHandleState( proc.stderr.windowsHandle(), &x, null, null ) ) bStderrNOBLOCK = true;
			}
			else
			{
				if( fcntl( fileno( proc.stderr.getFP() ), F_SETFL, O_NONBLOCK ) != -1 ) bStderrNOBLOCK = true;
			}
			
			string result = getGDBmessage();
			
			if( stderrMessage.length )
			{
				IupMessageError( null, "Debugger running fail, exit!" );
				auto s = tryWait( proc.pid );
				if( !s.terminated && s.status == 0 ) kill( proc.pid );
				IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "VALUE", "" );
				IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
				return;
			}
			
			IupSetStrAttribute( GLOBAL.debugPanel.getConsoleHandle, "APPEND", toStringz( result ) );

			if( indexOf( result, "(no debugging symbols found)" ) > -1 )
			{
				IupMessageError( null, GLOBAL.languageItems["exitdebug2"].toCString() );
				kill( proc.pid );
				IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "VALUE", "" );
				IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
				return;
			}

			
			//IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "READONLY", "NO" );
			caretPos = IupGetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS" );

			bExecuted = true;
			IupSetStrAttributeId( GLOBAL.debugPanel.getBacktraceHandle, "TITLE", 0, toStringz( executeFullPath ) );
			if( GLOBAL.editorSetting00.IconInvert == "ON" )
			{
				IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGE", 0, "icon_debug_bt0_invert" );
				IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGEEXPANDED", 0, "icon_debug_bt0_invert" );
			}
			else
			{
				IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGE", 0, "icon_debug_bt0" );
				IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGEEXPANDED", 0, "icon_debug_bt0" );
			}
			splitValue = IupGetInt( GLOBAL.messageSplit, "VALUE" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", 500 );

			
			sendCommand( "set confirm off\n", false );
			sendCommand( "set print array-indexes on\n", false );
			sendCommand( "set width 0\n", false );
			/*
			sendCommand( "set logging overwrite on\n", false );
			sendCommand( "set logging on\n", false );
			*/
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

	string sendCommand( string command, bool bShow = true )
	{
		switch( command )
		{
			case "kill\n", "k\n":
				int result = tools.questMessage( "GDB", "Kill the program being debugged?" );
				if( result == 2 ) return "#_NO_#";
				break;
				
			default:
		}
	
	
		proc.stdin.write( command );
		proc.stdin.flush();
		
		if( bShow )
		{
			IupSetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS", caretPos );
			IupSetStrAttribute( GLOBAL.debugPanel.getConsoleHandle, "INSERT", toStringz( command ) );
		}
		
		string result = getGDBmessage();
		if( bShow )
		{
			IupSetStrAttribute( GLOBAL.debugPanel.getConsoleHandle, "INSERT", toStringz( result.dup ) );
			caretPos = IupGetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS" );
		}

		return result;
	}
}


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

	private int consoleInput_cb( Ihandle *ih, int c, char *new_value )
	{
		static string prevCommand;
		
		if( c == '\n' )
		{
			string _command;
			
			foreach( s; splitLines( strip( fromStringz( new_value ) ) ) )
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
						string args = argDialog.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
						
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
						string[] _information = GLOBAL.debugPanel.getFrameInformation( fSTRz( IupGetAttributeId( ih, "TITLE", id ) ) );
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
					string		fullVarName = GLOBAL.debugPanel.getFullVarNameInTree( ih, id, true );
					
					if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ).dup == "LEAF" )
					{
						string		numID; // Remove ID
						string		title = fSTRz( IupGetAttributeId( ih, "TITLE", id ) ); // Get Tree Title
						
						if( title[0] > 47 && title[0] < 58 )
						{
							auto	colonspacePos = indexOf( title, ": " );
							if( colonspacePos > 0 )
							{
								numID = title[0..colonspacePos+2].dup;
								title = title[colonspacePos+2..$].dup;
							}
						}
						
						if( title[0] == '*' ) fullVarName = "*" ~ fullVarName;
						
						scope varDlg = new CVarDlg( 360, -1, "Evaluate " ~ fullVarName, "Value = " );
						string value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

						if( value == "#_close_#" ) return IUP_DEFAULT;
						
						auto assignPos = indexOf( title, " = " );
						GLOBAL.debugPanel.sendCommand( "set var " ~ fullVarName ~ " = " ~  value ~ "\n", false );

						auto posCloseParen = indexOf( title, ") " );
						if( posCloseParen > 0 ) IupSetAttributeId( ih, "TITLE", id, toStringz( numID ~ title[0..posCloseParen+2] ~ value ) );else IupSetStrAttributeId( ih, "TITLE", id, toStringz( numID ~ title[0..assignPos+3] ~ value ) );
						return IUP_IGNORE;
					}
					else
					{
						if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ) == "BRANCH" )
						{
							if( IupGetIntId( ih, "TOTALCHILDCOUNT", id ) == 0 )
							{
								string title = fSTRz( IupGetAttributeId( ih, "TITLE",id ) );
								title = GLOBAL.debugPanel.removeIDTitle( title );
							
								VarObject[] variables = GLOBAL.debugPanel.getTypeVarValueByLinesFromPrint( GLOBAL.debugPanel.getPrint( title[0] == '*' ? "*" ~ fullVarName : fullVarName ), fullVarName );
								
								if( variables.length )
								{
									foreach( VarObject _vo; variables )
									{
										string _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~ _vo.type ~ ") " : "" ) ~ _vo.value;
										if( _vo.value == "{...}" ) IupSetStrAttributeId( ih, "ADDBRANCH", id, toStringz( _title ) ); else IupSetStrAttributeId( ih, "ADDLEAF", id, toStringz( _title ) );
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
				
				string title = fSTRz( IupGetAttributeId( GLOBAL.debugPanel.watchTreeHandle, "TITLE", id ) );
				if( indexOf( title, '=' ) == -1 ) return IUP_DEFAULT; // No Contain '='

				Ihandle* itemVALUE = IupItem( GLOBAL.languageItems["showvalue"].toCString, null );
				IupSetAttributes( itemVALUE, "NAME=WATCHLIST_VALUE,IMAGE=icon_debug_star" );
				IupSetCallback( itemVALUE, "ACTION", cast(Icallback) &itemRightClick_ACTION );

				Ihandle* itemADDRESS = IupItem( GLOBAL.languageItems["showaddress"].toCString, null );
				IupSetAttributes( itemADDRESS, "NAME=WATCHLIST_ADDRESS,IMAGE=icon_debug_at" );
				IupSetCallback( itemADDRESS, "ACTION", cast(Icallback) &itemRightClick_ACTION );

				Ihandle* itemADDLIST = IupItem( GLOBAL.languageItems["addtowatch"].toCString, null );
				IupSetAttribute( itemADDLIST, "IMAGE", "icon_debug_add" );
				IupSetCallback( itemADDLIST, "ACTION", cast(Icallback) function( Ihandle* __ih )
				{
					int _id = IupGetInt( GLOBAL.debugPanel.watchTreeHandle, "VALUE" );
					string title = fSTRz( IupGetAttributeId( GLOBAL.debugPanel.watchTreeHandle, "TITLE", _id ) );
					string varName = GLOBAL.debugPanel.getFullVarNameInTree( GLOBAL.debugPanel.watchTreeHandle, _id, true );						

					if( title.length )
						if( title[0] == '*' ) varName = "*" ~ varName;

						
					if( varName.length ) GLOBAL.debugPanel.sendCommand( "display " ~ varName ~ "\n", false );

					return IUP_DEFAULT;
				});


				// Check with ID
				if( title[0] > 47 && title[0] < 58 )
				{
					IupSetAttribute( itemADDLIST, "ACTIVE", "NO" );
					auto	colonspacePos = indexOf( title, ": " );
					if( colonspacePos > 0 ) title = title[colonspacePos+2..$].dup;
				}

				if( title[0] == '&' ) IupSetAttribute( itemADDRESS, "ACTIVE", "NO" );
				
				auto closeParenPos = lastIndexOf( title, ")" );
				if( closeParenPos > 0 )
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
						string title = fSTRz( IupGetAttributeId( ih, "TITLE",id ) );
						string fullVarName = GLOBAL.debugPanel.getFullVarNameInTree( ih, id );
						VarObject[] variables = GLOBAL.debugPanel.getTypeVarValueByLinesFromPrint( GLOBAL.debugPanel.getPrint( title[0] == '*' ? "*" ~ fullVarName : fullVarName ), fullVarName );
						if( variables.length )
						{
							foreach( VarObject _vo; variables )
							{
								string _title = _vo.name ~ " = " ~ ( _vo.type.length ? "(" ~ _vo.type ~ ") " : "" ) ~ _vo.value;
								if( _vo.value == "{...}" ) IupSetStrAttributeId( ih, "ADDBRANCH", id, toStringz( _title ) ); else IupSetStrAttributeId( ih, "ADDLEAF", id, toStringz( _title ) );
								IupSetStrAttributeId( ih, "TITLEFONT", id + 1, toStringz( GLOBAL.fonts[9].fontString ) );
							}							
						}

						return IUP_IGNORE;
					}
				}
				else // LEAF
				{
					string		title = fSTRz( IupGetAttributeId( ih, "TITLE", id ) ); // Get Tree Title
					string		fullVarName = GLOBAL.debugPanel.getFullVarNameInTree( ih, id, true );
					
					if( title[0] == '*' ) fullVarName = "*" ~ fullVarName;
					
					scope varDlg = new CVarDlg( 360, -1, "Evaluate " ~ fullVarName, "Value = " );
					string value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

					if( value == "#_close_#" ) return IUP_DEFAULT;
					
					auto assignPos = indexOf( title, " = " );
					GLOBAL.debugPanel.sendCommand( "set var " ~ fullVarName ~ " = " ~  value ~ "\n", false );

					auto posCloseParen = indexOf( title, ") " );
					if( posCloseParen > 0 ) IupSetStrAttributeId( ih, "TITLE", id, toStringz( title[0..posCloseParen+2] ~ value ) );else IupSetStrAttributeId( ih, "TITLE", id, toStringz( title[0..assignPos+3] ~ value ) );
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
				
				string title = fSTRz( IupGetAttributeId( ih, "TITLE", id ) );
				
				if( indexOf( title, '=' ) == -1 ) return IUP_DEFAULT; // contain =
				
				Ihandle* itemVALUE = IupItem( GLOBAL.languageItems["showvalue"].toCString, null );
				IupSetAttributes( itemVALUE, "NAME=VARIABLES_VALUE,IMAGE=icon_debug_star" );
				IupSetCallback( itemVALUE, "ACTION", cast(Icallback) &itemRightClick_ACTION );
				
				Ihandle* itemADDRESS = IupItem( GLOBAL.languageItems["showaddress"].toCString, null );
				IupSetAttributes( itemADDRESS, "NAME=VARIABLES_ADDRESS,IMAGE=icon_debug_at" );
				IupSetCallback( itemADDRESS, "ACTION", cast(Icallback) &itemRightClick_ACTION );
				
				auto closeParenPos = lastIndexOf( title, ")" );
				if( closeParenPos > 0 )
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
				string nowFrameFullTitle = GLOBAL.debugPanel.getFrameNodeTitle( true ); // -1 = Get Active; true = Get Full Title
				if( nowFrameFullTitle != GLOBAL.debugPanel.regFrame )
				{
					GLOBAL.debugPanel.regFrame = nowFrameFullTitle;
					GLOBAL.debugPanel.sendCommand( "info reg\n", false );
				}
				break;
			
			case 3:
				string nowFrameFullTitle = GLOBAL.debugPanel.getFrameNodeTitle( true ); // -1 = Get Active; true = Get Full Title
				if( nowFrameFullTitle != GLOBAL.debugPanel.disasFrame )
				{
					GLOBAL.debugPanel.disasFrame = nowFrameFullTitle;
					GLOBAL.debugPanel.showDisassemble();
				}
				break;
				
			default:
		}
		return IUP_DEFAULT;
	}	

	private int varTabChange_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		string nowFrameFullTitle = GLOBAL.debugPanel.getFrameNodeTitle( true ); // -1 = Get Active; true = Get Full Title
		
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
		string		name = fSTRz( IupGetAttribute( ih, "NAME" ) );
		
		if( indexOf( name, "VARIABLES" ) > -1 ) _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.debugPanel.getVarsTabHandle, "VALUE_HANDLE" ); else _ih = GLOBAL.debugPanel.watchTreeHandle;
		if( indexOf( name, "ADDRESS" )  > -1 ) bGetADDRESS = true;
		

		if( _ih != null )
		{
			bool	bHasMember, bHasStar;
			string	varFullName;
			int		_id = IupGetInt( _ih, "VALUE" );
			string	title = fSTRz( IupGetAttributeId( _ih, "TITLE", _id ) );
			
			auto closeParenPos = lastIndexOf( title, ") " );
			if( closeParenPos > 0 )
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
			
				string	gdbMessage = GLOBAL.debugPanel.getPrint( varFullName );
				if( gdbMessage == "?" ) return IUP_DEFAULT;
				
				
				auto	openPos = indexOf( gdbMessage, "{" );
				if( openPos > -1 )
				{
					bHasMember = true;
					gdbMessage = ( gdbMessage[0..openPos] ~ "{...}" ).dup;
				}
				
				// Insert type if need....
				auto closePos = lastIndexOf( gdbMessage, ") " );
				if( closePos == -1 )
				{
					string type = GLOBAL.debugPanel.getWhatIs( varFullName );
					if( type != "?" ) gdbMessage = "(" ~ type ~ ") " ~ gdbMessage;
				
				}
				
				title = varFullName ~ " = " ~ gdbMessage;
				
				if( bHasMember )
				{
					IupSetStrAttributeId( _ih, "INSERTBRANCH", _id, toStringz( title ) );
					IupSetAttributeId( _ih, "COLOR", IupGetIntId( _ih, "NEXT", _id ), "0 128 0" );
					IupSetStrAttributeId( _ih, "TITLEFONT", IupGetIntId( _ih, "NEXT", _id ), toStringz( GLOBAL.fonts[9].fontString ) );
					//if( _ih != GLOBAL.debugPanel.watchTreeHandle ) IupSetAttributeId( _ih, "DELNODE", _id, "SELECTED" );
				}
				else
				{
					IupSetStrAttributeId( _ih, "INSERTLEAF", _id, toStringz( title ) );
					IupSetAttributeId( _ih, "COLOR", IupGetIntId( _ih, "NEXT", _id ), "0 128 0" );
					IupSetStrAttributeId( _ih, "TITLEFONT", IupGetIntId( _ih, "NEXT", _id ), toStringz( GLOBAL.fonts[9].fontString ) );
					//if( _ih != GLOBAL.debugPanel.watchTreeHandle ) IupSetAttributeId( _ih, "DELNODE", _id, "SELECTED" );
				}
				
				if( _ih == GLOBAL.debugPanel.watchTreeHandle )
				{
					int _result = tools.questMessage( "GDB", GLOBAL.languageItems["addtowatch"].toDString ~ "?", "QUESTION", "YESNO", IUP_MOUSEPOS, IUP_MOUSEPOS );
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

	private int CDebugger_register_doubleClick( Ihandle* ih, int item, char* text )
	{
		string[] results = GLOBAL.debugPanel.regTable.getSelection( item );
		if( results.length == 4 )
		{
			scope varDlg = new CVarDlg( 360, -1, "Evaluate " ~ results[1], "Value = " );
			string value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
			
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
			string[] results = GLOBAL.debugPanel.bpTable.getSelection( item );
			if( results.length == 3 )
			{
				ScintillaAction.openFile( results[2], to!(int)( results[1] ) );
			}
		}
		catch( Exception e )
		{
		}
		return IUP_DEFAULT;
	}	
}