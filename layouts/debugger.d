module layouts.debugger;


private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager, menu;
private import dialogs.singleTextDlg, dialogs.fileDlg;
private import parser.ast, tools;


private import tango.stdc.stringz, Integer = tango.text.convert.Integer, tango.core.Thread, tango.io.Stdout;
//private import tango.io.FilePath, tango.io.UnicodeFile, tango.text.Ascii, tango.io.Stdout;


class CDebugger
{
	private:
	import 					tango.io.FilePath;

	Ihandle*				txtConsoleCommand;
	Ihandle* 				mainHandle, consoleHandle, backtraceHandle, tabResultsHandle, bpListHandle, regListHandle;
	Ihandle*				watchTreeHandle, localTreeHandle, argTreeHandle, shareTreeHandle, varTabHandle;
	DebugThread				DebugControl;
	bool					bRunning;
	//int[char[]][char[]]		bpManager;

	void createLayout()
	{
		Ihandle* vBox_LEFT;
		Ihandle* hBox_toolbar;

		Ihandle* btnClear	= IupButton( null, "Clear" );
		Ihandle* btnResume	= IupButton( null, "Resume" );
		Ihandle* btnStop	= IupButton( null, "Stop" );
		Ihandle* btnStep	= IupButton( null, "Step" );
		Ihandle* btnNext	= IupButton( null, "Next" );
		Ihandle* btnReturn	= IupButton( null, "Return" );
		Ihandle* btnUntil	= IupButton( null, "Until" );

		txtConsoleCommand = IupText( null );
		//IupSetAttribute( txtConsoleCommand, "EXPAND", "YES" );
		IupSetAttributes( txtConsoleCommand, "MULTILINE=YES,SCROLLBAR=NO,SIZE=96x12,FONTSIZE=9,READONLY=NO" );
		IupSetCallback( txtConsoleCommand, "ACTION", cast(Icallback) &consoleInput_cb );

		Ihandle* btnTerminate = IupButton( null, "Terminate" );

		Ihandle*[6] labelSEPARATOR;
		for( int i = 0; i < 6; i++ )
		{
			labelSEPARATOR[i] = IupLabel( null ); 
			IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
		}

		IupSetAttributes( btnClear, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_clear,TIP=Clear_Console" );
		IupSetAttributes( btnResume, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_resume,TIP=Run/Continue" );
		IupSetAttributes( btnStop, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_stop,TIP=Stop" );
		IupSetAttributes( btnStep, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_step,TIP=Step" );
		IupSetAttributes( btnNext, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_next,TIP=Next" );
		IupSetAttributes( btnReturn, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_return,TIP=Return" );
		IupSetAttributes( btnUntil, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_until,TIP=Until" );
		IupSetAttributes( btnTerminate, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_delete,TIP=Terminate" );
		

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
		hBox_toolbar = IupHbox( btnClear, IupFill(), btnResume, btnStop, btnStep, btnNext, btnReturn, btnUntil, labelSEPARATOR[0], txtConsoleCommand, labelSEPARATOR[1], btnTerminate, null );
		IupSetAttributes( hBox_toolbar, "ALIGNMENT=ACENTER,GAP=5" );


		consoleHandle = IupText( null );
		IupSetAttributes( consoleHandle, "MULTILINE=YES,SCROLLBAR=YES,EXPAND=YES,READONLY=YES" );
		IupSetAttribute( consoleHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[8].fontString ) );
		IupSetCallback( consoleHandle, "VALUECHANGED_CB", cast(Icallback) &consoleOutputChange_cb );

		vBox_LEFT = IupVbox( hBox_toolbar, consoleHandle, null );
		IupSetAttributes( vBox_LEFT, "GAP=5,EXPAND=YES" );

		Ihandle* leftScrollBox = IupScrollBox( vBox_LEFT );

		//
		backtraceHandle = IupTree();
		IupSetAttributes( backtraceHandle, GLOBAL.cString.convert( "ADDROOT=YES,EXPAND=YES,HIDEBUTTONS=YES" ) );
		IupSetCallback( backtraceHandle, "BUTTON_CB", cast(Icallback) &backtraceBUTTON_CB );


		Ihandle* btnLeft		= IupButton( null, "Left" );
		Ihandle* btnRefresh		= IupButton( null, "Refresh" );
		IupSetAttributes( btnLeft, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_left,TIP=Add_To_Watchlist" );
		IupSetAttributes( btnRefresh, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_refresh,TIP=Refresh" );


		IupSetCallback( btnLeft, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				Ihandle* varsTabHandle = cast(Ihandle*)  IupGetAttribute( GLOBAL.debugPanel.getVarsTabHandle, "VALUE_HANDLE" );
				if( varsTabHandle != null )
				{
					int id = IupGetInt( varsTabHandle, "VALUE" );

					if( id > -1 )
					{
						char[]	title;
						char[]	varName;
						int		parnetID = id, _depth = IupGetIntId( varsTabHandle, "DEPTH", id );;
						while( _depth >= 0 )
						{
							title = fromStringz( IupGetAttributeId( varsTabHandle, "TITLE", parnetID ) ).dup; // Get Tree Title
							int assignPos = Util.index( title, " = " );
							if( assignPos < title.length )
							{
								varName = Util.trim( varName );
								if( varName.length )
								{
									varName = ( ( varName[0] == '[' ) ? (title[0..assignPos] ~ varName ) : ( title[0..assignPos] ~ "." ~ varName ) );
								}
								else
								{
									varName = title[0..assignPos];
								}
							}

							if( _depth <= 0 ) break;
							parnetID = IupGetIntId( varsTabHandle, "PARENT", parnetID );
							_depth = IupGetIntId( varsTabHandle, "DEPTH", parnetID );
						}

						if( varName.length )
						{
							if( varName[length-1] == '.' ) varName = varName[0..length-1];
							GLOBAL.debugPanel.sendCommand( "display " ~ varName ~ "\n", false );
						}
					}
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
						GLOBAL.debugPanel.sendCommand( "info locals\n", false );
						break;
					case 1:
						GLOBAL.debugPanel.sendCommand( "info args\n", false );
						break;
					case 2:
						GLOBAL.debugPanel.sendCommand( "info variables\n", false );
						break;
					default:
				}
			}
			return IUP_DEFAULT;
		});


		Ihandle* hBoxVar0_toolbar = IupHbox( btnLeft, btnRefresh, null );
		IupSetAttributes( hBoxVar0_toolbar, "ALIGNMENT=ACENTER,GAP=5" );

		watchTreeHandle = IupTree();
		IupSetAttributes( watchTreeHandle, "EXPAND=YES,ADDROOT=NO" );//,RASTERSIZE=0x,TITLE=FileList" );
		IupSetCallback( watchTreeHandle, "BUTTON_CB", cast(Icallback) &watchListBUTTON_CB );

		localTreeHandle =IupTree();
		IupSetAttributes( localTreeHandle, "EXPAND=YES,ADDROOT=NO" );//,RASTERSIZE=0x,TITLE=FileList" );
		IupSetCallback( localTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );

		argTreeHandle =IupTree();
		IupSetAttributes( argTreeHandle, "EXPAND=YES,ADDROOT=NO" );//,RASTERSIZE=0x,TITLE=FileList" );
		IupSetCallback( argTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );
		
		shareTreeHandle =IupTree();
		IupSetAttributes( shareTreeHandle, "EXPAND=YES,ADDROOT=NO" );//,RASTERSIZE=0x,TITLE=FileList" );
		IupSetCallback( shareTreeHandle, "BUTTON_CB", cast(Icallback) &treeBUTTON_CB );


		varTabHandle = IupTabs( localTreeHandle, argTreeHandle, shareTreeHandle, null );
		IupSetAttributes( varTabHandle, "TABTYPE=TOP,EXPAND=YES" );
		IupSetCallback( varTabHandle, "TABCHANGEPOS_CB", cast(Icallback) &varTabChange_cb );


		IupSetAttribute( localTreeHandle, "TABTITLE", "Locals" );
		//IupSetAttribute( mainHandle, "TABIMAGE", "icon_debug" );
		IupSetAttribute( argTreeHandle, "TABTITLE", "Args" );
		IupSetAttribute( shareTreeHandle, "TABTITLE", "shared" );


		
		

		Ihandle* vbox_var0 = IupVbox( hBoxVar0_toolbar, varTabHandle, null );
		Ihandle* var0Frame = IupFrame( vbox_var0 );
		IupSetAttribute( var0Frame, "TITLE", "Variables");
		IupSetAttribute( var0Frame, "EXPANDCHILDREN", "YES");
		Ihandle* var0ScrollBox = IupScrollBox( var0Frame );


		
		Ihandle* btnAdd		= IupButton( null, "Add" );
		Ihandle* btnDel		= IupButton( null, "Del" );
		Ihandle* btnDelAll	= IupButton( null, "RemoveAll" );

		IupSetAttributes( btnAdd, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_debug_add,TIP=Add" );
		IupSetAttributes( btnDel, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_delete,TIP=Remove" );
		IupSetAttributes( btnDelAll, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_deleteall,TIP=RemoveAll" );

		Ihandle* hBoxVar1_toolbar = IupHbox( IupFill(), btnAdd, btnDel, /*btnUp, btnDown, */btnDelAll, null );
		IupSetAttributes( hBoxVar1_toolbar, "ALIGNMENT=ACENTER,GAP=5" );

		
		IupSetCallback( btnAdd, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.debugPanel.isRunning )
			{
				scope varDlg = new CVarDlg( 260, 96, "Add Display Variable...", "Var Name:" );
				char[] varName = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

				if( varName == "#_close_#" ) return IUP_DEFAULT;

				GLOBAL.debugPanel.sendCommand( "display " ~ varName ~ "\n", false );
			}
			return IUP_DEFAULT;
		});

		IupSetCallback( btnDel, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			int itemNumber = IupGetInt( GLOBAL.debugPanel.watchTreeHandle, "VALUE" );
			if( itemNumber > -1 )
			{	
				char* idPointer = IupGetAttributeId( GLOBAL.debugPanel.watchTreeHandle, "USERDATA", itemNumber );
				if( idPointer != null )
				{
					GLOBAL.debugPanel.sendCommand( "delete display " ~ Util.trim( fromStringz( idPointer ) ) ~ "\n", false );
					
				}
			}
			return IUP_DEFAULT;
		});

		IupSetCallback( btnDelAll, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.debugPanel.sendCommand( "delete display\n", false );
			return IUP_DEFAULT;
		});

		
		Ihandle* vbox_var1 = IupVbox( hBoxVar1_toolbar, watchTreeHandle, null );
		Ihandle* var1Frame = IupFrame( vbox_var1 );
		IupSetAttribute( var1Frame, "TITLE", "Watchlist");
		IupSetAttribute( var1Frame, "EXPANDCHILDREN", "YES");
		Ihandle* var1ScrollBox = IupScrollBox( var1Frame );
	

		Ihandle* varSplit = IupSplit( var1ScrollBox, var0ScrollBox );
		IupSetAttributes( varSplit, "ORIENTATION=VERTICAL,BARSIZE=5,SHOWGRIP=LINES,VALUE=500,LAYOUTDRAG=NO" );

		//Ihandle* HBoxVar = IupHbox( var1Frame, var0Frame, null );


		// Breakpoint
		bpListHandle = IupList( null );
		IupSetAttributes( bpListHandle, "MULTIPLE=NO,MARGIN=10x10,VISIBLELINES=YES,EXPAND=YES,AUTOHIDE=YES" );
		Ihandle* bpFrame = IupFrame( bpListHandle );
		IupSetAttribute( bpFrame, "TITLE", " ID    Line   File");
		IupSetAttribute( bpFrame, "EXPANDCHILDREN", "YES");

		regListHandle = IupList( null );
		IupSetAttributes( regListHandle, "MULTIPLE=NO,MARGIN=10x10,VISIBLELINES=YES,EXPAND=YES,AUTOHIDE=YES" );
		
		version( Windows )
		{
			//watchTreeHandle, localTreeHandle, argTreeHandle, shareTreeHandle, varTabHandle;
			IupSetAttribute( watchTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( localTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( argTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( shareTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( varTabHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			
			IupSetAttribute( var0Frame, "FONT", "Courier New,10" );
			IupSetAttribute( var1Frame, "FONT", "Courier New,10" );
			IupSetAttribute( bpListHandle, "FONT", "Courier New,10" );
			IupSetAttribute( bpFrame, "FONT", "Courier New,10" );
			IupSetAttribute( regListHandle, "FONT", "Courier New,10" );
		}
		else
		{
			IupSetAttribute( watchTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( localTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( argTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( shareTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
			IupSetAttribute( varTabHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );

			IupSetAttribute( var0Frame, "FONT", "FreeMono,Bold 10" );
			IupSetAttribute( var1Frame, "FONT", "FreeMono,Bold 10" );
			IupSetAttribute( bpListHandle, "FONT", "FreeMono,Bold 10" );
			IupSetAttribute( bpFrame, "FONT", "FreeMono,Bold 10" );
			IupSetAttribute( regListHandle, "FONT", "FreeMono,Bold 10" );
		}
		


		IupSetAttribute( varSplit, "TABTITLE", "Variables" );
		IupSetAttribute( bpFrame, "TABTITLE", "Breakpoints" );
		IupSetAttribute( regListHandle, "TABTITLE", "Registers" );

		tabResultsHandle = IupTabs( bpFrame, varSplit, regListHandle, null );
		IupSetAttribute( tabResultsHandle, "TABTYPE", "TOP" );
		IupSetAttribute( tabResultsHandle, "EXPAND", "YES" );
		IupSetCallback( tabResultsHandle, "TABCHANGEPOS_CB", cast(Icallback) &resultTabChange_cb );
		

		Ihandle* rightSplitHandle = IupSplit( backtraceHandle, tabResultsHandle  );
		IupSetAttributes( rightSplitHandle, "ORIENTATION=HORIZONTAL,SHOWGRIP=LINES,VALUE=300,LAYOUTDRAG=NO" );
		

		Ihandle* mainSplit = IupSplit( leftScrollBox, rightSplitHandle );
		IupSetAttributes( mainSplit, "ORIENTATION=VERTICAL,SHOWGRIP=LINES,VALUE=260,LAYOUTDRAG=NO" );

		mainHandle = IupScrollBox( mainSplit );
		IupSetAttribute( mainHandle, "TABTITLE", "Debug" );
		IupSetAttribute( mainHandle, "TABIMAGE", "icon_debug" );
	}

	char[] getWhatIs( char[] varName )
	{
		char[] type = GLOBAL.debugPanel.sendCommand( "whatis " ~ varName ~ "\n", false );
		if( type.length > 5 )
		{
			type = Util.trim( type[0..length-5] ); // remove (gdb)
		
			int posAssign = Util.index( type, " = " );
			if( posAssign < type.length ) return type[posAssign+3..length].dup;
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
			if( posAssign < value.length ) return value[posAssign+3..length].dup;
		}
		return "?";
	}
	
	char[][] getFrameFullPathandLineNumber()
	{
		if( bRunning )
		{
			char[][] results;
			
			int childrenCount = IupGetInt( backtraceHandle, "COUNT" );
			int id = childrenCount -1;
			
			for( int i = 1; i < IupGetInt( backtraceHandle, "COUNT" ); ++ i )
			{
				if( fromStringz( IupGetAttributeId( backtraceHandle, "COLOR", i ) ).dup == "0 0 255" )
				{
					id = i;
					break;
				}
			}
			
			char[] valueString = fromStringz( IupGetAttributeId( backtraceHandle, "TITLE", id ) ).dup;

			if( valueString.length )
			{
				int fnHead = Util.rindex( valueString, " at " );
				int lnHead = Util.rindex( valueString, ":" );

				if( fnHead < valueString.length )
				{
					if( lnHead < valueString.length )
					{
						if( fnHead < lnHead )
						{
							results ~= valueString[fnHead+4..lnHead];
							results ~= valueString[lnHead+1..length];

							return results;
						}
					}
				}
			}
		}

		return null;
	}

	void updateSYMBOL()
	{
		char[][] results = getFrameFullPathandLineNumber();

		if( results.length ==  2 )
		{
			int			lineNumber = Integer.atoi( results[1] );
			char[]		fullPath = Util.replace( results[0], '\\', '/' );

			if( ScintillaAction.openFile( fullPath, lineNumber ) )
			{	
				//#define SCI_MARKERDELETEALL 2045
				IupScintillaSendMessage( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, 2045, 3, 0 );
				IupScintillaSendMessage( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, 2045, 4, 0 );
			
				IupScintillaSendMessage( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, 2043, lineNumber - 1, 3 ); // #define SCI_MARKERADD 2043
				IupScintillaSendMessage( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, 2043, lineNumber - 1, 4 ); // #define SCI_MARKERADD 2043
			}
		}
	}

	void updateWatchList( char[] result, bool bClean )
	{
		// Check display result
		char[][] results = Util.splitLines( result );

		results.length = results.length - 1; // remove (gdb)

		if( results.length > 0 )
		{
			char[][]	ids, vars, values, types;
			char[]		trueLineData;

			foreach_reverse( char[] s; results )
			{
				trueLineData = s ~ trueLineData;
				
				if( s.length )
				{
					if( s[0] != ' ' )
					{
						int colonPos = Util.index( trueLineData, ": " );
						if( colonPos > 0 && colonPos < trueLineData.length )
						{
							bool bIsNum = true;
							foreach( char c; trueLineData[0..colonPos] )
							{
								if( c > 57 || c < 48 ) 
								{
									bIsNum = false;
									break;
								}
							}

							if( bIsNum )
							{
								char[] _id = trueLineData[0..colonPos];
								trueLineData = trueLineData[colonPos+2..length];
								int assignPos = Util.index( trueLineData, " = " );
								if( assignPos < trueLineData.length )
								{
									ids ~= _id;
									char[] tempVar = Util.trim( trueLineData[0..assignPos] );
									vars ~= tempVar;
									char[] tempValue = Util.trim( trueLineData[assignPos+3..length] );
									values ~= tempValue;

									if( tempValue[0] != '(' ) types ~= ( "(" ~ getWhatIs( tempVar ) ~") " );else types ~= "";
								}
							}
						}
						trueLineData = "";
					}
					else
					{
						trueLineData = " " ~ Util.trim( trueLineData );
					}
				}
			}

			if( bClean ) IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
			for( int i = 0; i < vars.length; ++ i )
			{
				char[] string = vars[i] ~ " = " ~  types[i] ~ values[i];
				IupSetAttributeId( watchTreeHandle, "ADDLEAF", -1, GLOBAL.cString.convert( string.dup ) );
				IupSetAttributeId( watchTreeHandle, "USERDATA", 0, tools.getCString( ids[i] ) );
			}
		}
		else
		{
			IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
		}
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

	void getTypeVarValue( char[] gdbMessage, inout char[][] types, inout char[][] vars, inout char[][] values )
	{
		foreach( char[] s; Util.splitLines( fixGDBMessage( gdbMessage ) ) )
		{
			int assignPos = Util.index( s, " = " );
			if( assignPos < s.length )
			{
				char[] tempVar = Util.trim( s[0..assignPos] );
				vars ~= tempVar;
				values ~= Util.trim( s[assignPos+3..length] );
				types ~= getWhatIs( tempVar );
			}
		}
	}

	void checkErrorOccur( char[] message, char[] errorMessage = null )
	{
		int head = Util.index( message, "Program received signal SIGSEGV, Segmentation fault." );
		if( head < message.length )
		{
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=GDB-Segmentation_fault" );
			if( message.length >5 ) message = message[head..length-5];
			IupSetAttribute( messageDlg, "VALUE", toStringz( message ) );
			IupPopup( messageDlg, IUP_CURRENT, IUP_CURRENT );
		}			
	}
	

	public:
	this()
	{
		createLayout();
	}

	void setFont()
	{
		IupSetAttribute( watchTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
		IupSetAttribute( localTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
		IupSetAttribute( argTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
		IupSetAttribute( shareTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
		IupSetAttribute( varTabHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[9].fontString ) );
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

	Ihandle* getBPListHandle()
	{
		return bpListHandle;
	}

	Ihandle* getConsoleCommandInputHandle()
	{
		return txtConsoleCommand;
	}

	Ihandle* getVarsTabHandle()
	{
		return varTabHandle;
	}

	char[] sendCommand( char[] command, bool bShow = true  )
	{
		if( DebugControl is null ) return null;

		char[] result =  DebugControl.sendCommand( command, bShow );

		// Check GDB reach end
		int gdbEndStringPosTail = Util.rindex( result, "exited normally]" );
		if( gdbEndStringPosTail < result.length )
		{
			int gdbEndStringPosHead = Util.rindex( result, "[Inferior" );
			if( gdbEndStringPosHead < result.length )
			{
			
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=GDB,BUTTONS=OKCANCEL" );
				IupSetAttribute( messageDlg, "VALUE", toStringz( result[gdbEndStringPosHead..gdbEndStringPosTail+16].dup ~ "\nExit debug right now?" ) );

				IupPopup( messageDlg, IUP_CURRENT, IUP_CURRENT );
				if( IupGetInt( messageDlg, "BUTTONRESPONSE" ) == 1 )
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
						updateWatchList( result, true );
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
							if( tail > head + 7 ) _fullPath = Util.replace( result[head+7..tail], '\\', '/' );
							
							head = Util.rindex( result, ", line " );
							tail = Util.rindex( result, "." );
							if( tail > head + 7 ) _lineNumber = result[head+7..tail];

							//bpManager[_fullPath][_lineNumber] = Integer.atoi( _id );
							char[] string = Stdout.layout.convert( "{,-4} {,6} ", _id, _lineNumber ) ~ _fullPath;
							IupSetAttribute( bpListHandle, "APPENDITEM", toStringz( string ) );
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
							char[] _id = splitCommand[1];

							int count = IupGetInt( bpListHandle, "COUNT" );
							
							for( int i = count; i > 0; -- i )
							{
								char[] listValue	= fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ) ) ).dup;
								char[] _listID		= Util.trim( listValue[0..6] );
								char[] _lineNum		= Util.trim( listValue[6..12] );
								char[] _fullPath	= Util.trim( listValue[12..length] );
										

								if( _listID == _id )
								{
									IupSetInt( bpListHandle, "REMOVEITEM", i );
									//bpManager[_fullPath].remove( _lineNum );
									//if( !bpManager[_fullPath].length ) bpManager.remove( _fullPath );
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
										char* _itemID = cast(char*) IupGetAttributeId( watchTreeHandle, "USERDATA", i );
										if( Util.trim( fromStringz(_itemID) ) == _id )
										{
											IupSetAttributeId( watchTreeHandle, "DELNODE", i, "SELECTED" );
											delete _itemID;
										}
									}
								}
							}
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
								char* _itemID = cast(char*) IupGetAttributeId( watchTreeHandle, "USERDATA", i );
								if( Util.trim( fromStringz(_itemID) ) == _id )
								{
									IupSetAttributeId( watchTreeHandle, "DELNODE", i, "SELECTED" );
									delete _itemID;
								}
							}
						}
					}
					break;

				case "select-frame":
					if( bRunning && isExecuting )
					{
						if( splitCommand.length == 2 )
						{
							GLOBAL.debugPanel.updateBackTrace();
							int pos = IupGetInt( tabResultsHandle, "VALUEPOS" );
							if( pos > -1 ) resultTabChange_cb( tabResultsHandle, pos, -1 );

							// Check display result
							sendCommand( "display\n", false );

							char[] selectedFrame = "#" ~ splitCommand[1];

							for( int i = 1; i < IupGetInt( backtraceHandle, "COUNT" ); ++ i )
							{
								char[] title = fromStringz( IupGetAttributeId( backtraceHandle, "TITLE", i ) ).dup;
								if( Util.index( title, selectedFrame ) < title.length )
								{
									IupSetAttributeId( backtraceHandle, "COLOR", i, GLOBAL.cString.convert( "0 0 255" ) );
								}
								else
								{
									IupSetAttributeId( backtraceHandle, "COLOR", i, GLOBAL.cString.convert( "0 0 0" ) );
								}
							}
						}
					}
					break;
					
				case "bt", "backtrace":
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

										IupSetAttributeId( backtraceHandle, "ADDBRANCH", lastID, GLOBAL.cString.convert( branchString.dup ) );
										lastID = IupGetInt( backtraceHandle, "LASTADDNODE" );
										IupSetAttributeId( backtraceHandle, "IMAGE", lastID, GLOBAL.cString.convert( "icon_debug_bt1" ) );
										IupSetAttributeId( backtraceHandle, "IMAGEEXPANDED", lastID, GLOBAL.cString.convert( "icon_debug_bt1" ) );
										if( i == 0 )
										{
											IupSetAttributeId( backtraceHandle, "COLOR", lastID, GLOBAL.cString.convert( "0 0 255" ) );
											version(Windows) IupSetAttributeId( backtraceHandle, "MARKED", lastID, "YES" ); else IupSetInt( backtraceHandle, "VALUE", lastID );
										}
											
										branchString = "";
									}
								}
							}
						}
					}
					break;

				case "kill":
					if( splitCommand.length == 1 )
					{
						bRunning = false;
						
						//IupSetAttribute( varList0Handle, "REMOVEITEM", "ALL" );
						IupSetAttribute( localTreeHandle, "DELNODE", "ALL" );
						IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
						IupSetAttribute( regListHandle, "REMOVEITEM", "ALL" ); 
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
							updateWatchList( result, true );
						}
					}
					checkErrorOccur( result );
					break;

				case "info":
					if( splitCommand.length > 1 )
					{
						switch( splitCommand[1] )
						{
							case "locals":
								if( bRunning )
								{
									char[][]	vars, values, types;
									getTypeVarValue( result, types, vars, values );
									IupSetAttribute( localTreeHandle, "DELNODE", "ALL" );
									for( int i = 0; i < vars.length; ++ i )
									{
										if( values[i].length )
										{
											if( values[i][0] == '{' ) values[i] = "{...}";
										}
										char[] string = vars[i] ~ " = (" ~  types[i] ~ ") " ~ values[i];
										if( values[i] == "{...}" ) IupSetAttributeId( localTreeHandle, "INSERTBRANCH", -1, toStringz( string.dup ) );else IupSetAttributeId( localTreeHandle, "INSERTLEAF", -1, toStringz( string.dup ) );
									}									
								}
								break;

							case "args":
								if( bRunning )
								{
									char[][]	vars, values, types;
									getTypeVarValue( result, types, vars, values );
									IupSetAttribute( argTreeHandle, "DELNODE", "ALL" );
									for( int i = 0; i < vars.length; ++ i )
									{
										if( values[i].length )
										{
											if( values[i][0] == '{' ) values[i] = "{...}";
										}
										char[] string = vars[i] ~ " = (" ~  types[i] ~ ") " ~ values[i];
										//char[] string = Stdout.layout.convert( "{,-" ~ Integer.toString( maxVarLength ) ~ "} = ", vars[i] ) ~ values[i];
										if( values[i] == "{...}" ) IupSetAttributeId( argTreeHandle, "INSERTBRANCH", -1, toStringz( string.dup ) );else IupSetAttributeId( argTreeHandle, "INSERTLEAF", -1, toStringz( string.dup ) );
									}										
								}
								break;

							case "variables":
								if( bRunning )
								{
									char[][] results = Util.splitLines( result );
									results.length = results.length - 1; // remove (gdb)

									if( results.length > 0 )
									{
										char[][]	linesData;
										char[]		trueLineData;
										
										foreach_reverse( char[] s; results )
										{
											trueLineData = s ~ trueLineData;
											
											if( s[0] != ' ' )
											{
												linesData ~= trueLineData;
												trueLineData = "";
											}
											else
											{
												trueLineData = " " ~ Util.trim( trueLineData );
											}
										}

										char[][] frameFullPathandLineNumber = getFrameFullPathandLineNumber();

										if( frameFullPathandLineNumber.length == 2 )
										{
											char[] frameFullPath = frameFullPathandLineNumber[0];

											bool		bBeginGetVar;
											char[][]	varsName, typesName, values;
											//int			maxVarLength;

											foreach_reverse( char[] s; linesData )
											{
												if( !bBeginGetVar )
												{
													if( Util.index( upperCase(s), upperCase(frameFullPath) ) < s.length ) bBeginGetVar = true;
												}
												else
												{
													if( s.length )
													{
														if( s[length-1] == ';' )
														{
															char[][] splitData = Util.split( s[0..length-1], " " );
															if( splitData.length == 2 )
															{
																varsName ~= splitData[1];
																typesName ~= splitData[0];
																values ~= getPrint( splitData[1] );
															}
														}
													}
													else
													{
														break;
													}
												}
											}

											if( varsName.length )
											{
												IupSetAttribute( shareTreeHandle, "DELNODE", "ALL" );
												for( int i = 0; i < varsName.length; ++ i )
												{
													if( values[i].length )
													{
														if( values[i][0] == '{' ) values[i] = "{...}";
													}													
													char[] string = varsName[i] ~ " = (" ~  typesName[i] ~ ") " ~ values[i];
													//char[] string = Stdout.layout.convert( "{,-" ~ Integer.toString( maxVarLength ) ~ "} : ", varsName[i] ) ~ typesName[i];
													if( values[i] == "{...}" ) IupSetAttributeId( shareTreeHandle, "INSERTBRANCH", -1, toStringz( string.dup ) );else IupSetAttributeId( shareTreeHandle, "INSERTLEAF", -1, toStringz( string.dup ) );
												}										
											}
										}
									}
								}
								break;
									
								

							case "reg":
								if( bRunning )
								{
									char[][] results = Util.splitLines( result );
									//results.length = results.length - 1; // remove (gdb)
									IupSetAttribute( regListHandle, "REMOVEITEM", "ALL" ); 
									for( int i = 0; i < results.length - 1; ++i )
									{
										IupSetAttribute( regListHandle, "APPENDITEM", GLOBAL.cString.convert( results[i] ) );
									}
								}
								break;

							default:
						}
					}
					break;

				default:
					if( bRunning )
					{
						if( splitCommand[0].length >= 7 )
						{
							if( lowerCase( splitCommand[0][0..7] ) == "display" )
							{
								if( splitCommand.length == 1 ) updateWatchList( result, true );else updateWatchList( result, false );
							}
						}
					}				
			}
		}

		return result;
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
		
		IupSetAttribute( localTreeHandle, "DELNODE", "ALL" ); 
		IupSetAttribute( argTreeHandle, "DELNODE", "ALL" ); 
		IupSetAttribute( shareTreeHandle, "DELNODE", "ALL" );
		IupSetAttribute( watchTreeHandle, "DELNODE", "ALL" );
		IupSetAttribute( regListHandle, "REMOVEITEM", "ALL" ); 
		//IupSetAttribute( bpListHandle, "REMOVEITEM", "ALL" ); // Remove All LIst Items

		// Set the breakpoint id to -1
		for( int i = IupGetInt( GLOBAL.debugPanel.getBPListHandle, "COUNT" ); i > 0; -- i )
		{
			char[] listValue = fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ) ) ).dup;
			listValue[0..2] = "-1";
			IupSetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ), toStringz( listValue.dup ) );
		}

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
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ).dup == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
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
							IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
							IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Can't Debug Static / Dynamic Library directlly............Debug Error!" ) );
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
					command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name;
				}
			}
		}

		IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
		
		scope f = new FilePath( command );
		if( f.exists() )
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Running " ~ command ~ "......" ) );
			DebugControl = new DebugThread( "\"" ~ command ~ "\"", f.path );
			DebugControl.start();
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Execute file: " ~ command ~ "\nisn't exist......?\n\nRun Error!" ) );
			return false;
		}

		return true;
	}

	bool compileWithDebug()
	{
		return ExecuterAction.compile( null, "-g" );
	}

	bool buildAllWithDebug()
	{
		return ExecuterAction.buildAll( "-g" );
	}	

	void updateBackTrace()
	{
		if( bRunning )
		{
			char[] result = sendCommand( "bt\n", false );

			if( result.length > 5 ) updateSYMBOL();
		}
	}

	void addBP( char[] _fullPath, char[] _lineNum )
	{
		if( isExecuting || isRunning )
		{
			char[] result = sendCommand( "b " ~ _fullPath ~ ":" ~ _lineNum ~ "\n" );
		}
		else
		{
			//bpManager[_fullPath][_lineNum] = -1;
			char[] string = Stdout.layout.convert( "{,-4} {,6} ", "-1", _lineNum ) ~ _fullPath;
			IupSetAttribute( bpListHandle, "APPENDITEM", toStringz( string ) );
		}
	}

	void removeBP( char[] _fullPath, char[] _lineNum )
	{
		if( isExecuting || isRunning )
		{
			for( int i = IupGetInt( GLOBAL.debugPanel.getBPListHandle, "COUNT" ); i > 0; -- i )
			{
				char[] listValue = fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ) ) ).dup;
				char[] id = Util.trim( listValue[0..6] );
				char[] ln = Util.trim( listValue[6..12] );
				char[] fn = Util.trim( listValue[12..length] );

				if( fn == _fullPath && ln == _lineNum )
				{
					int numberID = Integer.atoi( id );
					if( numberID > 0 ) sendCommand( "delete " ~ id ~ "\n" );
				}
			}
		}
		else
		{
			for( int i = IupGetInt( GLOBAL.debugPanel.getBPListHandle, "COUNT" ); i > 0; -- i )
			{
				char[] listValue = fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ) ) ).dup;
				char[] id = Util.trim( listValue[0..6] );
				char[] ln = Util.trim( listValue[6..12] );
				char[] fn = Util.trim( listValue[12..length] );

				if( fn == _fullPath && ln == _lineNum ) IupSetInt( GLOBAL.debugPanel.getBPListHandle, "REMOVEITEM", i );
			}
		}
	}
	
}


class CVarDlg : CSingleTextDialog
{
	public:
	this( int w, int h, char[] title, char[] _labelText = null, char[] text = null, char[] textWH = null, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, _labelText, text, textWH, bResize, parent );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CConsoleDlg_btnCancel_cb );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CConsoleDlg_btnCancel_cb );
	}

	~this()
	{
		IupSetHandle( "textResult", null );
		IupDestroy( _dlg );
	}		

}


class DebugThread : Thread
{
	private :
	import		tango.io.stream.Data, tango.sys.Process;
	
	char[]		executeFullPath, cwd;
	int			caretPos, splitValue;
	Process		proc;


	char[] getGDBmessage()
	{
		proc.stderr.flush();

		char[] result;

		try
		{
			while( 1 )
			{
				try
				{
					char[1] c;
					version(Windows) proc.stdout.get( c );else proc.stdout.read( c );
					
					result ~= c;

					if( c == ")" )
					{
						if( result.length >= 5 )
						{
							if( result[length-5..length] == "(gdb)" ) break;
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
			//IupMessage( "ERROR", toStringz( e.toString ) );
		}
		return "(gdb)";
	}
	

	public:
	bool		bExecuted;
	
	this( char[] _executeFullPath, char[] _cwd = null )
	{
		executeFullPath = _executeFullPath;
		cwd = _cwd;
		super( &run );
	}

	~this()
	{
		proc.kill();
		delete proc;

		//GLOBAL.messageSplit_value = 800;
		//IupSetInt( GLOBAL.messageSplit, "VALUE", splitValue );
		//menu.message_cb( GLOBAL.menuMessageWindow );

		IupSetAttribute( GLOBAL.menuMessageWindow, "VALUE", "OFF" );
		GLOBAL.messageSplit_value = 800;
		IupSetInt( GLOBAL.messageSplit, "VALUE", 1000 );

		IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "NO" );
		// Since set Split's "ACTIVE" to "NO" will set all Children's "ACTIVE" to "NO", we need correct it......
		Ihandle* SecondChild = IupGetChild( GLOBAL.messageSplit, 1 );
		IupSetAttribute( SecondChild, "ACTIVE", "YES" );

		IupSetAttribute( GLOBAL.outputPanel, "VISIBLE", "NO" );
		IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLE", "NO" );
		

		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			//#define SCI_MARKERDELETEALL 2045
			IupScintillaSendMessage( cSci.getIupScintilla, 2045, 3, 0 );
			IupScintillaSendMessage( cSci.getIupScintilla, 2045, 4, 0 );
		}
	}

	void run()
	{
		try
		{
			auto thisThread = DebugThread.getThis;

			if( bExecuted ) return;

			// Show bottom panel
			IupSetAttribute( GLOBAL.menuMessageWindow, "VALUE", "ON" );
			//IupSetInt( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
			IupSetAttribute( GLOBAL.messageSplit, "ACTIVE", "YES" );
			IupSetAttribute( GLOBAL.outputPanel, "VISIBLE", "YES" );
			IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLE", "YES" );

			// Show the Debug window
			IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "YES" );
			IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 2 );

			proc = new Process( true, "\"" ~ GLOBAL.debuggerFullPath ~ "\" " ~ executeFullPath );
			proc.gui( true );
			if( cwd.length ) proc.workDir( cwd );
			//proc.redirect( Redirect.None );
			proc.execute;

			char[] result = getGDBmessage();
			IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "APPEND", GLOBAL.cString.convert( result ) );

			if( Util.index( result, "(no debugging symbols found)" ) < result.length )
			{
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=GDB" );
				IupSetAttribute( messageDlg, "VALUE", toStringz( "No debugging symbols found!!\nExit Debug!" ) );
				IupPopup( messageDlg, IUP_CURRENT, IUP_CURRENT );

				proc.kill();
				delete proc;
				IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "VALUE", GLOBAL.cString.convert( "" ) );
				IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
				return;
			}

			
			//IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "READONLY", "NO" );
			caretPos = IupGetInt( GLOBAL.debugPanel.getConsoleHandle, GLOBAL.cString.convert( "CARETPOS" ) );

			bExecuted = true;
			IupSetAttribute( GLOBAL.debugPanel.getBacktraceHandle(), "TITLE", GLOBAL.cString.convert( executeFullPath ) );
			IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGE", 0, GLOBAL.cString.convert( "icon_debug_bt0" ) );
			IupSetAttributeId( GLOBAL.debugPanel.getBacktraceHandle(), "IMAGEEXPANDED", 0, GLOBAL.cString.convert( "icon_debug_bt0" ) );
			splitValue = IupGetInt( GLOBAL.messageSplit, "VALUE" );
			IupSetInt( GLOBAL.messageSplit, "VALUE", 400 );
			int count = IupGetInt( GLOBAL.debugPanel.getBPListHandle, "COUNT" );
			for( int i = count; i > 0; -- i )
			{
				char[] listValue = fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ) ) ).dup;
				if( listValue.length > 12 )
				{
					char[] id = Util.trim( listValue[0..6] );
					char[] ln = Util.trim( listValue[6..12] );
					char[] fn = Util.trim( listValue[12..length] );

					if( id == "-1" )
					{
						GLOBAL.debugPanel.sendCommand( "b " ~ fn ~ ":" ~ ln ~ "\n", false );
						IupSetInt( GLOBAL.debugPanel.getBPListHandle, "REMOVEITEM", i );
					}
				}
			}

			version( Windows )
			{
				sendCommand( "set new-console on\n", false );
			}
			else
			{/+
				auto termProc = new Process( GLOBAL.linuxTermName,null );
				//termProc.redirect( Redirect.All );
				termProc.execute;
				termProc.stdin.write( "tty\n" );
				char[] ttyResult;
				while( 1 )
				{
					try
					{
						char[1] c;
						termProc.stdout.get( c );
						if( c == "\n" ) break;

						ttyResult ~= c;
					}
					catch( Exception e )
					{
						throw( e );
					}
				}

				sendCommand( "tty " ~ ttyResult ~ "\n", true );+/
			}
			sendCommand( "set print array-indexes on\n", false );
			//sendCommand( "set print elements 1\n", false );
		}
		catch( Exception e )
		{
		}
	}

	char[] sendCommand( char[] command, bool bShow = true )
	{
		proc.stdin.write( command );

		if( bShow )
		{
			IupSetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS", caretPos );
			IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "INSERT", GLOBAL.cString.convert( command ) );
		}
		
		char[] result = getGDBmessage();
		if( bShow )
		{
			IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "INSERT", GLOBAL.cString.convert( result.dup ) );
			caretPos = IupGetInt( GLOBAL.debugPanel.getConsoleHandle, "CARETPOS" );
		}

		proc.stdout.flush();
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
			IupSetAttribute( textHandle, "VALUE", GLOBAL.cString.convert( "#_close_#" ) );
		}

		return IUP_CLOSE;
	}

	private int consoleOutputChange_cb( Ihandle* ih )
	{
		return IUP_IGNORE;
	}

	private int consoleInput_cb( Ihandle *ih, int c, char *new_value )
	{
		static char[] prevCommand;
		
		if( c == '\n' )
		{
			char[] _command = Util.trim( fromStringz( new_value ).dup );

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
				if( button == 49 ) // IUP_BUTTON1 = '1' = 49
				{
					if( !GLOBAL.debugPanel.isRunning() ) GLOBAL.debugPanel.sendCommand( "r\n" ); else GLOBAL.debugPanel.sendCommand( "continue\n" );
				}
				else if( button == 51 ) // IUP_BUTTON1 = '3' = 51
				{
					if( !GLOBAL.debugPanel.isRunning() )
					{
						scope argDialog = new CSingleTextDialog( -1, -1, "Args To Debugger Run", "Args:", null, null, false );
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
			char[] _s = fromStringz( status ).dup;
			
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					if( GLOBAL.debugPanel.isRunning )
					{
						int id = IupConvertXYToPos( ih, x, y );
						if( id > 0 )
						{
							if( fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBacktraceHandle, "COLOR" ) ).dup != "0 0 255" )
							{
								char[] title = fromStringz( IupGetAttributeId( GLOBAL.debugPanel.getBacktraceHandle, "TITLE", id ) ).dup;
								char[] selectedFrame;
								for( int i = 0; i < title.length; ++ i )
								{
									if( title[i] != ' ' ) 
									{
										if( title[i] != '#' ) selectedFrame ~= title[i];
									}
									else
									{
										break;
									}
								}

								if( selectedFrame.length )
								{
									GLOBAL.debugPanel.sendCommand( "select-frame " ~ selectedFrame ~ "\n", false );
									version(Windows) IupSetAttributeId( GLOBAL.debugPanel.backtraceHandle, "MARKED", id, "YES" ); else IupSetInt( GLOBAL.debugPanel.backtraceHandle, "VALUE", id );

									char[][]	frameFullPathandLineNumber = GLOBAL.debugPanel.getFrameFullPathandLineNumber();
									if( frameFullPathandLineNumber.length == 2 )
									{
										char[]		fullPath = Util.replace( frameFullPathandLineNumber[0], '\\', '/' );
										actionManager.ScintillaAction.openFile( fullPath );
									}

									return IUP_IGNORE;
								}
							}
						}
						return IUP_IGNORE;
						/*
						else
						{
							return IUP_IGNORE;
						}
						*/
					}
				}
			}
		}

		return IUP_DEFAULT;
	}

	private int watchListBUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 ) // IUP_BUTTON1 = '1' = 49
		{
			char[] _s = fromStringz( status ).dup;
			
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					if( GLOBAL.debugPanel.isRunning )
					{
						int id = IupConvertXYToPos( ih, x, y );

						char[] title = fromStringz( IupGetAttributeId( ih, "TITLE", id ) ).dup; // Get Tree Title
						char[] varName = title;
						int assignPos = Util.index( title, " = " );
						{
							if( assignPos < title.length ) varName = Util.trim( title[0..assignPos] );
						}
						
						scope varDlg = new CVarDlg( 360, 96, "Evaluate " ~ varName, "Value = " );
						char[] value = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

						if( value == "#_close_#" ) return IUP_DEFAULT;

						GLOBAL.debugPanel.sendCommand( "set var " ~ varName ~ " = " ~  value ~ "\n", false );

						int posCloseParen = Util.index( title, ") " );
						if( posCloseParen < title.length ) IupSetAttributeId( ih, "TITLE", id, GLOBAL.cString.convert( title[0..posCloseParen+2] ~ value ) );else IupSetAttributeId( ih, "TITLE", id, GLOBAL.cString.convert( title[0..assignPos+3] ~ value ) );
					}
				}
			}
		}

		return IUP_DEFAULT;
	}

	private int treeBUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 ) // IUP_BUTTON1 = '1' = 49
		{
			char[] _s = fromStringz( status ).dup;
			
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					int id = IupConvertXYToPos( ih, x, y );

					if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ).dup == "BRANCH" )
					{
						if( IupGetIntId( ih, "TOTALCHILDCOUNT", id ) > 0 ) return IUP_DEFAULT;
						
						char[]	title;
						char[]	varName;
						int		parnetID = id, _depth = IupGetIntId( ih, "DEPTH", id );;
						
						
						while( _depth >= 0 )
						{
							title = fromStringz( IupGetAttributeId( ih, "TITLE", parnetID ) ).dup; // Get Tree Title
							int assignPos = Util.index( title, " = " );
							{
								if( assignPos < title.length )
								{
									if( varName.length )
									{
										if( varName[0] == '[' ) varName = title[0..assignPos] ~ varName; else varName = title[0..assignPos] ~ "." ~ varName;
									}
									else
									{
										varName = title[0..assignPos];
									}
								}
							}

							if( _depth <= 0 ) break;
							parnetID = IupGetIntId( ih, "PARENT", parnetID );
							_depth = IupGetIntId( ih, "DEPTH", parnetID );
						}

						if( varName.length )
						{
							if( varName[length-1] == '.' ) varName = varName[0..length-1];
							//IupMessage("VarNAme",toStringz( varName ) );

							char[] result = GLOBAL.debugPanel.getPrint( varName );

							if( GLOBAL.debugPanel.bRunning )
							{
								char[][] results = Util.splitLines( result );

								results.length = results.length - 1; // remove (gdb)
								if( results.length > 0 )
								{
									char[]		trueLineData;
									result		= "";

									foreach_reverse( char[] s; results )
									{
										trueLineData = s ~ trueLineData;
										
										if( s.length )
										{
											if( s[0] != ' ' )
											{
												result = trueLineData ~ result;
												trueLineData = "";
											}
											else
											{
												trueLineData = " " ~ Util.trim( trueLineData );
											}
										}
									}

									char[] 	data;
									results.length = 0;
									
									
									for( int i = 1; i < result.length; ++ i )
									{
										if( i == result.length - 1 )
										{
											if( data.length )
											{
												char[] type;
												int assignPos = Util.index( data, " = " );
												if( assignPos < data.length )
												{
													if( Util.index( data, "[" ) < data.length  )
													{
														results ~= Util.trim( data );
													}
													else
													{
														type = " = (" ~ GLOBAL.debugPanel.getWhatIs( varName ~ "." ~ data[0..assignPos] ) ~ ")";
														results ~= Util.trim( data[0..assignPos]  ~ type ~ " " ~ data[assignPos+3..length] );
													}
												}
												else
												{
													results ~= Util.trim( data );
												}
											}
										}
										else if( result[i] == ','  )
										{
											//IupSetAttributeId( ih, "ADDLEAF", id + IupGetIntId( ih,"TOTALCHILDCOUNT", id ), toStringz( Util.trim( data ) ) );
											//IupSetAttributeId( ih, "ADDLEAF", id, toStringz( Util.trim( data ) ) );
											char[] type;
											int assignPos = Util.index( data, " = " );
											if( assignPos < data.length )
											{
												if( Util.index( data, "[" ) < data.length  )
												{
													results ~= Util.trim( data );
												}
												else
												{
													type = " = (" ~ GLOBAL.debugPanel.getWhatIs( varName ~ "." ~ data[0..assignPos] ) ~ ")";
													results ~= Util.trim( data[0..assignPos]  ~ type ~ " " ~ data[assignPos+3..length] );
												}
											}
											else
											{
												results ~= Util.trim( data );
											}
											data = "";
										}
										else if( result[i] == '{' )
										{
											int		open = 0;

											for( int j = i; j < result.length-1; ++ j )
											{
												if( result[j] == '{' )
												{
												//	IupMessage("{",toStringz(Integer.toString( j ) ) );
													open ++;
												}
												else if( result[j] == '}' )
												{
													//IupMessage("}",toStringz(Integer.toString( j ) ) );
													open --;

													if( open == 0 )
													{
														char[] type;
														int assignPos = Util.index( data, " = " );
														if( assignPos < data.length )
														{
															if( Util.index( data, "[" ) < data.length ) type = ""; else type = "(" ~ GLOBAL.debugPanel.getWhatIs( varName ~ "." ~ data[0..assignPos] ) ~ ")";
														}

														results ~= Util.trim( data ~ type ~ " {...}" );
														i = j + 1;
														//IupMessage("",toStringz(Integer.toString( i ) ) );
														//IupMessage("length",toStringz(Integer.toString( result[length-1] ) ) );
														data = "";
														break;
													}
												}
											}
										}
										else
										{
											data ~= result[i];
										}
									}

									foreach_reverse( char[] s; results )
									{
										if( Util.index( s, "{...}" ) < s.length ) IupSetAttributeId( ih, "ADDBRANCH", id, toStringz( s.dup ) );else IupSetAttributeId( ih, "ADDLEAF", id, toStringz( s.dup ) );
									}
									
									return IUP_IGNORE;
									
								}
							}
						}
					}
				}
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
				GLOBAL.debugPanel.sendCommand( "info reg\n", false );
				break;
			default:
		}
		return IUP_DEFAULT;
	}	

	private int varTabChange_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		switch( new_pos )
		{
			case 0:
				GLOBAL.debugPanel.sendCommand( "info locals\n", false );
				break;
			case 1:
				GLOBAL.debugPanel.sendCommand( "info args\n", false );
				break;
			case 2:
				GLOBAL.debugPanel.sendCommand( "info variables\n", false );
				break;
			default:
		}
		return IUP_DEFAULT;
	}
}