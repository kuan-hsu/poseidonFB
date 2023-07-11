module executer;

version(Windows) import core.sys.windows.mmsystem;
/*
const SND_SYNC = &h0000
const SND_ASYNC = &h0001
const SND_NODEFAULT = &h0002
const SND_MEMORY = &h0004
const SND_LOOP = &h0008
const SND_NOSTOP = &h0010
const SND_NOWAIT = &h00002000
const SND_ALIAS = &h00010000
const SND_ALIAS_ID = &h00110000
const SND_FILENAME = &h00020000
const SND_RESOURCE = &h00040004
const SND_PURGE = &h0040
const SND_APPLICATION = &h0080
const SND_ALIAS_START = 0
*/

struct ExecuterAction
{
private:
	import iup.iup, iup.iup_scintilla;
	import global, actionManager, menu, tools, scintilla, project, layouts.messagePanel;
	import std.stdio, std.string, std.file, std.process, std.encoding, std.windows.charset, std.datetime;
	import Algorithm = std.algorithm, UTF = std.utf, Uni = std.uni, Path = std.path, Array = std.array, Conv = std.conv;
	import core.thread, core.time;
	version(Windows) import core.sys.windows.winbase, core.sys.windows.windef;
	
	struct BuildDataToTLS
	{
		CMessageAndSearch		messagePanel;
		CScintilla[string]		scintillaManager;
		CompilerSettingUint		compilerSettings;
		string					OutputSci;
		string					poseidonPath, linuxTermName;
		Monitor					consoleWindow;
		Monitor[]				monitors;
	}
	
	static BuildDataToTLS getBuildNeedDataToTLS()
	{
		BuildDataToTLS buildTools = { GLOBAL.messagePanel,
									GLOBAL.scintillaManager,
									GLOBAL.compilerSettings,
									GLOBAL.editorSetting01.OutputSci,
									GLOBAL.poseidonPath, GLOBAL.linuxTermName,
									GLOBAL.consoleWindow,
									GLOBAL.monitors
									};
		return buildTools;
	}
	
	
	static Ihandle* createProcessDlg( string title )
	{
		Ihandle* processLabel = IupLabel( toStringz( title ) );
		IupSetAttribute( processLabel, "SIZE", "96x12" );
		version(Windows) IupSetAttribute( processLabel, "FONT", "Consolas Bold, 14" ); else IupSetAttribute( processLabel, "FONT", "Monospace Bold, 14" );
		IupSetAttribute( processLabel, "ALIGNMENT", "ACENTER:ACENTER" );
		version(DIDE) IupSetAttribute( processLabel, "FGCOLOR", "255 0 0" ); else IupSetAttribute( processLabel, "FGCOLOR", "0 0 255" );
		Ihandle* processDlg = IupDialog( processLabel );
		IupSetAttributes( processDlg, "RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO,BORDER=NO,OPACITY=180,SHRINK=YES" );
		IupSetAttribute( processDlg, "TITLE", null );
		IupSetAttribute( processDlg, "BGCOLOR", "219 238 243" );
		IupSetAttribute( processDlg, "PARENTDIALOG", "POSEIDON_MAIN_DIALOG" );
		IupShowXY( processDlg, IUP_RIGHT, IUP_BOTTOM );	
		return processDlg;
	}
	
	
	static bool isAppExists( string path )
	{
		if( exists( path ) ) return true;
		
		version(linux)
		{
			try
			{
				auto which = executeShell( "which " ~ path );
				if( which.status != 0 ) 
					return false;
				else
				{
					auto ret = which.output;
					if( ret.length > 0 ) return true;
				}
			}
			catch( Exception e ){}
		}
		return false;
	}
	
	version(linux)
	{
		static bool checkTerminalExists()
		{
			if( !isAppExists( GLOBAL.linuxTermName ) )
			{
				if( GLOBAL.compilerSettings.useSFX == "ON" ) IupExecute( "aplay", "settings/sound/warning.wav" );
				GLOBAL.messagePanel.printOutputPanel( "Terminal path isn't existed!\nPlease set in 'Preference Dialog'.", true );
				IupMessageError( null, "Terminal Path isn't Existed!" );
				return false;
			}
			return true;
		}
		
		
		static string getAppPath( string appName )
		{
			if( exists( appName ) ) return appName;

			try
			{
				auto which = executeShell( "which " ~ appName );
				if( which.status != 0 ) 
					return null;
				else
				{
					return strip( which.output ).dup;
				}
			}
			catch( Exception e ){}
			return null;
		}
	}
	
	
	static bool checkCompilerExists( string fbcFullPath )
	{
		if( !isAppExists( fbcFullPath ) )
		{
			GLOBAL.messagePanel.printOutputPanel( "Compiler isn't existed......?\n\nCompiler Path = " ~ fbcFullPath ~ " ?", true );
			IupMessageError( null, "Compiler isn't Existed!" );
			return false;
		}
		
		return true;
	}
	
	
	// Inner Class
	class ExecuterThread : Thread
	{
	private:
		string			command, args, cwd;
		string			x, y, w, h;
		bool			bQuickRun;
		BuildDataToTLS	buildTools;

	public:
		this( string _command, string _args, BuildDataToTLS _buildTools, string _cwd = null, bool _bQuickRun = false )
		{
			command			= strip( _command );
			args			= strip( _args );
			cwd 			= strip( _cwd );
			bQuickRun		= _bQuickRun;
			buildTools		= _buildTools;
			
			if( !cwd.length ) cwd = Path.dirName( _command );
			
			// Becasuse of D2 TLS, copy need Data to Thread
			int _x = buildTools.consoleWindow.x + buildTools.monitors[buildTools.consoleWindow.id].x;
			int _y = buildTools.consoleWindow.y + buildTools.monitors[buildTools.consoleWindow.id].y;
			version(Windows)
			{
				x = Conv.to!(string)( _x );
				y = Conv.to!(string)( _y );
				w = Conv.to!(string)( buildTools.consoleWindow.w );
				h = Conv.to!(string)( buildTools.consoleWindow.h );
			}
			else
			{
				x = Conv.to!(string)(buildTools.consoleWindow.x + buildTools.monitors[buildTools.consoleWindow.id].x);
				y = Conv.to!(string)(buildTools.consoleWindow.y + buildTools.monitors[buildTools.consoleWindow.id].y);
				w = Conv.to!(string)(buildTools.consoleWindow.w < 80 ? 80 : buildTools.consoleWindow.w);
				h = Conv.to!(string)(buildTools.consoleWindow.h < 24 ? 24 : buildTools.consoleWindow.h);
			}
		 	
			super( &go );
		}

		void go()
		{
			Pid				pid;
			string			consoleArgs;
			string			oriCommand = command;

			version(Posix)
			{
				command = Array.replace( command, " ", "\\ " ); // For space in path
			}
			
			if( buildTools.compilerSettings.useConsoleLaunch == "ON" )
			{
				version(Windows)
				{
					if( buildTools.consoleWindow.id < buildTools.monitors.length )
					{
						consoleArgs = "0 " ~ x ~ " " ~ y ~ " " ~ w ~ " " ~ h ~ " 0 " ~ command ~ " " ~ args;
					}
					else
					{
						consoleArgs = "0 0 0 0 0 0 " ~ command ~ " " ~ args;
					}
				}
				else
				{
					consoleArgs = Conv.to!(string)( buildTools.consoleWindow.id ) ~ " -1 -1 " ~ w ~ " " ~ h ~ " 0 " ~ command ~ " " ~ args;
				}
				
				args = consoleArgs;
				command = buildTools.poseidonPath ~ "/consoleLauncher";
			}
			
			version(Windows)
			{
				tools.ExecuteWait( command, args, cwd );
			}
			else
			{
				// --hide-menubar
				// --geometry
				// -t poseidonFB_terminal
				string geoString;
				if( buildTools.consoleWindow.id < buildTools.monitors.length )
				{
					geoString = " --geometry=" ~ w ~ "x" ~ h ~ "+" ~ x ~ "+" ~ y;
				}

				if( buildTools.linuxTermName )
				{
					switch( strip( buildTools.linuxTermName ) )
					{
						case "xterm", "uxterm":
							geoString = Array.replace( geoString, "--geometry=", "-geometry " );
							pid = spawnShell( buildTools.linuxTermName ~ " -T poseidon_terminal" ~ geoString ~ " -e " ~ command ~ " " ~ args, null, Config.none, cwd );
							break;
						case "mate-terminal" ,"xfce4-terminal" ,"lxterminal", "gnome-terminal", "tilix":
							pid = spawnShell( buildTools.linuxTermName ~ " --title poseidon_terminal" ~ geoString ~ " -e " ~ command ~ " " ~ args, null, Config.none, cwd );
							break;
						default:
							pid = spawnShell( buildTools.linuxTermName ~ " -e " ~ command ~ " " ~ args, null, Config.none, cwd );
					}
				}
				else
				{
					pid = spawnShell( command ~ " " ~ args, null, Config.none, cwd );
				}
			}
			
			version(Posix) auto ret = wait( pid );
			
			if( bQuickRun )
			{
				if( exists( oriCommand ) )
				{
					string objFullPath = oriCommand;
					if( oriCommand[0] == '"' && oriCommand[$-1] == '"' ) objFullPath = oriCommand[1..$-1].dup;
					std.file.remove( objFullPath );
					version(Windows)
					{
						objFullPath = Path.stripExtension( oriCommand ) ~ ".obj";
						if( exists( objFullPath ) ) std.file.remove( objFullPath );
					}
					else
					{
						objFullPath = Path.stripExtension( oriCommand ) ~ ".o";
						if( exists( objFullPath ) ) std.file.remove( objFullPath );
						objFullPath = Path.stripExtension( oriCommand );
						if( exists( objFullPath ) ) std.file.remove( objFullPath );
					}
					objFullPath = Path.stripExtension( oriCommand ) ~ ".bas";
					if( exists( objFullPath ) ) std.file.remove( objFullPath );
				}
			}
		}
	}
	
	
	class CompileThread : Thread
	{
	private:
		string			cwd, fileFullPath, command, options, args;
		string 			_beCompiledFile, _beRunFile;
		Ihandle*		processDlg;
		BuildDataToTLS	buildTools;
		bool			bRun, bQuickRun;
		bool			bCompileSuccess;
		string			quickFileTemp;
		
	public:
		this( string _command, string _fileFullPath, string _options, string _cwd = null, bool _bRun = false, string _args = "", bool _bQuickRun = false )
		{
			cwd						= _cwd;
			command					= strip( _command );
			fileFullPath			= strip( _fileFullPath );
			options					= _options;
			bRun					= _bRun;
			bQuickRun				= _bQuickRun;
			args					= _args;
			buildTools				= getBuildNeedDataToTLS();
			quickFileTemp			= quickRunFile;
			
			if( fileFullPath.length )
			{
				version(FBIDE)
				{
					// the fileFullPath include the extension, the legth must > 2
					if( fileFullPath[0..2] == "-b" )
					{
						_beCompiledFile = fileFullPath;
						fileFullPath = strip( fileFullPath[2..$] );
						_beRunFile = strip( Path.stripExtension( strip( fileFullPath, "\"" ) ) );
					}
					else
					{
						if( fileFullPath[0] == '"' && fileFullPath[$-1] == '"' )
						{
							_beRunFile = strip( Path.stripExtension( fileFullPath[1..$-1] ) );
							_beCompiledFile = "-b " ~ fileFullPath;
						}
						else
						{
							_beRunFile = strip( Path.stripExtension( fileFullPath ) );
							_beCompiledFile = "-b \"" ~ fileFullPath ~ "\"";
						}
					}
				}
				else
				{
					fileFullPath = strip( fileFullPath, "\"" );
					_beRunFile = Path.stripExtension( strip( fileFullPath ) );
					_beCompiledFile = "\"" ~ fileFullPath ~ "\"";
					if( bRun ) _beCompiledFile = "-run " ~ _beCompiledFile;
				}
			}			

			
			if( GLOBAL.compilerSettings.useDelExistExe == "ON" )
			{
				// Remove the execute file
				string singleExistedExecute = _beRunFile ~ ".exe";
				if( exists( singleExistedExecute ) ) std.file.remove( singleExistedExecute );
			}	
		
			if( GLOBAL.compilerSettings.useThread == "ON" ) processDlg = createProcessDlg( "Compiling......" );
			
			super( &go );
		}		
		
		void go()
		{
			quickRunFile = quickFileTemp;
			options = _beCompiledFile ~ ( options.length ? " " ~ options : "" );
			bCompileSuccess = CompilerProcess( "\"" ~ strip( command, "\"" ) ~ "\"", strip( options ), buildTools, cwd, true, true );
			if( processDlg != null )
				if( IupGetInt( processDlg, "VISIBLE" ) == 1 ) IupDestroy( processDlg );
			
			if( bCompileSuccess )
			{
				version(FBIDE)
				{
					debug writefln( "COMPILE OK!!" );
					if( bRun )
					{
						version(Windows) _beRunFile ~= ".exe";
						auto _thread = new ExecuterThread( _beRunFile, args, buildTools, cwd, bQuickRun );						
						_thread.start;
						//_thread.join;
					}
				}
			}
			else
			{
				version(FBIDE)
				{
					if( bQuickRun )
					{
						if( exists( fileFullPath ) )
						{
							string objFullPath = fileFullPath;
							if( objFullPath[0] == '"' && objFullPath[$-1] == '"' ) objFullPath = fileFullPath[1..$-1].dup;
							if( exists( objFullPath ) ) std.file.remove( objFullPath );
							objFullPath = Path.stripExtension( objFullPath ) ~ ".o";
							if( exists( objFullPath ) ) std.file.remove( objFullPath );
							objFullPath = Path.stripExtension( objFullPath ) ~ ".bas";
							if( exists( objFullPath ) ) std.file.remove( objFullPath );
						}
					}
				}
			}
		}
		
		bool getCompileResult()
		{
			return bCompileSuccess;
		}
	}
	
	
	static void showAnnotation( string message, BuildDataToTLS buildTools )
	{
		if( buildTools.compilerSettings.useAnootation != "ON" ) return;
		
		foreach( CScintilla cSci; buildTools.scintillaManager )
		{
			IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONCLEARALL", "YES" );
			
			int prevLineNumber, prevLineNumberCount;
			
			foreach( s; splitLines( message ) )
			{
				bool bWarning;
				
				version(FBIDE)
				{
					auto lineNumberTail = indexOf( s, ") error" );
					if( lineNumberTail == -1 )
					{
						lineNumberTail = indexOf( s, ") warning" );
						bWarning = true;
					}
				}
				else //version(DIDE)
				{
					if( indexOf( s, "warning - " ) == 0 ) bWarning = true;
					auto lineNumberTail = indexOf( s, "): " );
				}

				if( lineNumberTail > -1 )
				{
					auto lineNumberHead = indexOf( s, "(" );
					if( lineNumberHead < lineNumberTail - 1 && lineNumberHead > -1 )
					{
						string filePath = tools.normalizeSlash( s[0..lineNumberHead++] );

						if( quickRunFile.length ) filePath = quickRunFile;
						if( filePath == cSci.getFullPath )
						{
							int	lineNumber = Conv.to!(int)( s[lineNumberHead..lineNumberTail] ) - 1;
							string	annotationText = s[lineNumberTail+2..$];
							if( lineNumber != prevLineNumber )
							{
								prevLineNumber = lineNumber;
								prevLineNumberCount = 1;
								annotationText = "[" ~ Conv.to!(string)( prevLineNumberCount ) ~ "]" ~ annotationText;
								prevLineNumberCount ++;
							}
							else
							{
								annotationText = "[" ~ Conv.to!(string)( prevLineNumberCount ) ~ "]" ~ annotationText;
								prevLineNumberCount ++;
							}
							
							string getText = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", lineNumber ) );
							if( getText.length ) annotationText = getText ~ "\n" ~ annotationText;
							IupSetStrAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", lineNumber, toStringz( annotationText ) );
							if( bWarning ) IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", lineNumber, 41 ); else IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", lineNumber, 40 );
							IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
						}
					}
				}
			}
		}
	}

	static bool CompilerProcess( string command, string args, BuildDataToTLS buildTools, string workDir = "", bool bGUI = true, bool bShowMessage = true )
	{
		/+
		ProcessPipes pipes;
		if( bGUI )
			pipes = pipeShell( command ~ " " ~ args, Redirect.stdout | Redirect.stderr, null, Config.suppressConsole, workDir );
		else
			pipes = pipeShell( command ~ " " ~ args, Redirect.stdout | Redirect.stderr, null, Config.none, workDir );
		+/
		scope DaNodeProcess = new tools.Process( command ~ " " ~ args, workDir );
		DaNodeProcess.start();
		while(!DaNodeProcess.finished){ Thread.sleep( msecs( 5 ) ); }
		
		string theMessage = DaNodeProcess.output( 0 ).dup;
		int		_state = DaNodeProcess.getMessageState();
		bool	bError, bWarning;
		version(FBIDE)
		{
			foreach( line; splitLines( theMessage ) )
			{
				line = strip( line );
				if( !bWarning )
				{
					if( indexOf( line, "warning " ) > -1 ) bWarning = true;
				}
				if( !bError )
				{
					if( indexOf( line, "error " ) > -1 ) bError = true;
				}
				if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
			}
		}
		else //version(DIDE)
		{
			foreach( line; splitLines( theMessage ) )  
			{
				version(Windows) line = fromMBSz( toStringz( strip( line ) ~ "\0" ) ); else	line = strip( line );
				if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
			}
		}
		
		bool bBuildSuccess;
		if( _state == 0 ) bBuildSuccess = true; 
		/+
		bool	bError, bWarning;
		string	stdoutMessage, stderrMessage;
		version(FBIDE)
		{
			foreach( line; pipes.stdout.byLine )
			{
				if( !bWarning )
				{
					if( indexOf( line, "warning " ) > -1 ) bWarning = true;
				}
				if( !bError )
				{
					if( indexOf( line, "error " ) > -1 ) bError = true;
				}
				
				line = strip( line );
				stdoutMessage ~= ( line ~ "\n" );
				if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
			}
			
			foreach( line; pipes.stderr.byLine )  
			{
				if( !bWarning )
				{
					if( indexOf( line, "warning:" ) > -1 )
					{
						bWarning = true;
						stderrMessage ~= ( line ~ "\n" );
						if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
						continue;
					}
				}
				
				if( !bError )
					if( line.length ) bError = true;

				line = strip( line );
				stderrMessage ~= ( line ~ "\n" );
				if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
			}
		}
		else //version(DIDE)
		{
			foreach( line; pipes.stderr.byLine )  
			{
				if( strip( line ).length ) bError = true;
				version(Windows) line = fromMBSz( line );

				line = strip( line );
				stderrMessage ~= ( line ~ "\n" );
				if( bShowMessage && buildTools.MessageHanDle != null ) IupSetStrAttribute( buildTools.MessageHanDle, "APPEND", toStringz( line ) );
			}

			foreach( line; pipes.stdout.byLine )
			{
				if( !bError )
				{
					if( indexOf( line, "): " ) > -1 )
						bError = true;
					else if( indexOf( line, "Error " ) > -1 )
						bError = true;
				}				
				version(Windows) line = fromMBSz( line );
				
				line = strip( line );
				stdoutMessage ~= ( line ~ "\n" );
				if( bShowMessage && buildTools.MessageHanDle != null ) IupSetStrAttribute( buildTools.MessageHanDle, "APPEND", toStringz( line ) );
			}
		}
		
		
		bool bBuildSuccess;
		if( wait( pipes.pid ) == 0 ) bBuildSuccess = true;
		+/

		version(FBIDE)
		{
			if( _state > 0 ) showAnnotation( theMessage, buildTools ); else showAnnotation( null, buildTools );
		}
		else //version(DIDE)
		{
			if( _state > 0 )
			{
				showAnnotation( theMessage, buildTools );
			}
			else
				showAnnotation( null, buildTools );
		}

		if( !bBuildSuccess )
		{
			if( !bWarning || _state > 1 || bError )
			{
				if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", "\nCompile Error!!" );

				if( buildTools.compilerSettings.useResultDlg == "ON" )
				{
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
					IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["compilefailure"].toCString() );
					IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString() );
					IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
				}
				else
				{
					version(Windows) 
					{
						if( buildTools.compilerSettings.useSFX == "ON" ) PlaySound( "settings/sound/error.wav", null, 0x0001 );
					}
					else
					{
						if( buildTools.compilerSettings.useSFX == "ON" ) IupExecute( "aplay", "settings/sound/error.wav" );
					}
				}
			}
			else
			{
				if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", "\nCompile Success! But got warning..." );
				if( buildTools.compilerSettings.useResultDlg == "ON" )
				{
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING" );
					IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["compilewarning"].toCString() );
					IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString() );
					IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
				}
				else
				{
					version(Windows)
					{
						if( buildTools.compilerSettings.useSFX == "ON" ) PlaySound( "settings/sound/warning.wav", null, 0x0001 );
					}
					else
					{
						if( buildTools.compilerSettings.useSFX == "ON" ) IupExecute( "aplay", "settings/sound/warning.wav" );
					}							
				}
			}
		}
		else
		{
			if( bShowMessage && buildTools.messagePanel !is null ) IupSetStrAttribute( buildTools.messagePanel.getOutputPanelHandle, "APPEND", "Compile Success!!" );
			if( buildTools.compilerSettings.useResultDlg == "ON" )
			{
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION" );
				IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["compileok"].toCString() );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["message"].toCString() );
				IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
			}
			else
			{
				version(Windows)
				{
					if( buildTools.compilerSettings.useSFX == "ON" ) PlaySound( "settings/sound/success.wav", null, 0x0001 );
				}
				else
				{
					if( buildTools.compilerSettings.useSFX == "ON" ) IupExecute( "aplay", "settings/sound/success.wav" );
				}							
			}
		}

		if( buildTools.OutputSci == "ON" ) 
		{
			buildTools.messagePanel.applyOutputPanelINDICATOR();
			IupSetInt( buildTools.messagePanel.getOutputPanelHandle, "CARETPOS", 99999999 );
		}
		
		return bBuildSuccess;
	}


	/*
	SourceType = 0	return all *.bas / *.d
	SourceType = 1	return need compile *.bas / *.d after check *.obj / *.o
	SourceType = 2	return all *.obj / *.o
	*/
	static bool getBuildNeedData( ref string compiler, ref string filesANDargs, string options, string optionDebug, int SourceType = 0 )
	{
		version(linux)
		{
			if( !checkTerminalExists() ) 
			{
				int dummy = tools.questMessage( "Error", "The linux terminal path isn't set.", "ERROR", "OK" );
				return false;
			}
		}
	
		string activePrjName = ProjectAction.getActiveProjectName();
		try
		{
			if( !activePrjName.length )
			{
				GLOBAL.messagePanel.printOutputPanel( "No Project has been selected......?\n\nBuild Error!", true );
				return false;
			}
			if( !( activePrjName in GLOBAL.projectManager ) )
			{
				GLOBAL.messagePanel.printOutputPanel( "No Project has been selected......?\n\nBuild Error!", true );
				return false;
			}
			
			// Get Custom Compiler
			string customOpt, customCompiler;
			CustomToolAction.getCustomCompilers( customOpt, customCompiler );	
			
			// Set Multiple Focus Project
			FocusUnit _focus;
			_focus.Compiler = GLOBAL.projectManager[activePrjName].compilerPath;
			_focus.Option = GLOBAL.projectManager[activePrjName].compilerOption;
			_focus.Target = GLOBAL.projectManager[activePrjName].targetName;
			_focus.IncDir = GLOBAL.projectManager[activePrjName].includeDirs;
			_focus.LibDir = GLOBAL.projectManager[activePrjName].libDirs;
			if( GLOBAL.projectManager[activePrjName].focusOn.length )
			{
				if( GLOBAL.projectManager[activePrjName].focusOn in GLOBAL.projectManager[activePrjName].focusUnit ) _focus = GLOBAL.projectManager[activePrjName].focusUnit[GLOBAL.projectManager[activePrjName].focusOn];
			}			
			
			string fbcFullPath = compiler;
			if( !fbcFullPath.length ) fbcFullPath = _focus.Compiler;
			if( !fbcFullPath.length ) fbcFullPath = customCompiler;
			if( !fbcFullPath.length )
			{
				fbcFullPath = GLOBAL.compilerSettings.Bit64 == "OFF" ? GLOBAL.compilerSettings.compilerFullPath : GLOBAL.compilerSettings.x64compilerFullPath;
			}
			compiler = fbcFullPath;
			
			version(Windows)
			{
				foreach( s; GLOBAL.EnvironmentVars.keys )
				{
					compiler = Array.replace( Uni.toLower( fbcFullPath ), Uni.toLower( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
				}				
			}
			
			if( !checkCompilerExists( fbcFullPath ) )
			{
				int dummy = tools.questMessage( "Error", "The Compiler Path isn't set!", "ERROR", "OK" );
				return false;
			}
			

			
			if( !options.length ) options = _focus.Option; // Notice: Do not use custom options

			string txtCommand, txtSources, txtIncludeDirs, txtLibDirs;

			// Save All Scintilla Tabs Files
			if( GLOBAL.editorSetting00.SaveAllModified == "ON" )
			{
				foreach( CScintilla _cSci; GLOBAL.scintillaManager )
					if( ScintillaAction.getModifyByTitle( _cSci ) ) ScintillaAction.saveFile( _cSci );
			}
			else
			{
				foreach( s; GLOBAL.projectManager[activePrjName].sources ~ GLOBAL.projectManager[activePrjName].includes ~ GLOBAL.projectManager[activePrjName].others )
				{
					if( fullPathByOS(s) in GLOBAL.scintillaManager )
					{
						if( ScintillaAction.getModifyByTitle( GLOBAL.scintillaManager[fullPathByOS(s)] ) ) GLOBAL.scintillaManager[fullPathByOS(s)].saveFile();
					}
				}
			}

			bool bGotOneFileToBuild, bNoSourceNeedBeCompiled;
			foreach( s; GLOBAL.projectManager[activePrjName].sources )
			{
				switch( SourceType )
				{
					case 0:
						version(FBIDE)	txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
						version(DIDE)	txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
						break;
						
					case 1:
						SysTime _accessTimeF, _modifiedTimeF, _accessTimeO, _modifiedTimeO;
						bool	bObjIsNew;
						
						version(FBIDE)
						{
							auto objFullPath = Path.stripExtension( s ) ~ ".o";
							if( exists( objFullPath ) )
							{
								std.file.getTimes( objFullPath, _accessTimeO, _modifiedTimeO );
								std.file.getTimes( s, _accessTimeF, _modifiedTimeF );
								if( _modifiedTimeF < _modifiedTimeO ) bObjIsNew = true;
							}
							if( !bObjIsNew ) txtSources = txtSources ~ " -b \"" ~ s ~ "\"";
						}
						else //version(DIDE)
						{
							string objFullPathWithoutExt;
							if( indexOf( options, "-op" ) > -1 )
							{
								objFullPathWithoutExt = Path.stripExtension( s );
							}
							else
							{
								auto optionPos = indexOf( options, "-od=" );
								if( optionPos > -1 )
								{
									string _pathname;
									for( int i = cast(int) optionPos + 4; i < options.length; ++ i )
									{
										if( options[i] == '\t' || options[i] == ' ' ) break;
										_pathname ~= options[i];
									}
									objFullPathWithoutExt = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _pathname ~ "/" ~ Path.stripExtension( Path.baseName( s ) );
								}
								else
								{
									optionPos = indexOf( options, "-od" );
									if( optionPos > -1 )
									{
										string _pathname;
										for( int i = cast(int) optionPos + 3; i < options.length; ++ i )
										{
											if( options[i] == '\t' || options[i] == ' ' ) break;
											_pathname ~= options[i];
										}
										objFullPathWithoutExt = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _pathname ~ "/" ~ Path.stripExtension( Path.baseName( s ) );
									}
									else
									{
										objFullPathWithoutExt = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ Path.stripExtension( Path.baseName( s ) );
									}
								}
							}
							
							version(Windows) objFullPathWithoutExt ~= ".obj"; else objFullPathWithoutExt ~= ".o";
							if( exists( objFullPathWithoutExt ) )
							{
								std.file.getTimes( objFullPathWithoutExt, _accessTimeO, _modifiedTimeO );
								std.file.getTimes( s, _accessTimeF, _modifiedTimeF );
								if( _modifiedTimeF < _modifiedTimeO ) bObjIsNew = true;
							}
							
							if( !bObjIsNew ) txtSources = txtSources ~ " \"" ~ s ~ "\"";
						}
						break;
						
					case 2:
						version(FBIDE)
						{
							txtSources = txtSources ~ " -a \"" ~ Path.stripExtension( s ) ~ ".o\"" ;
						}
						else //version(DIDE)
						{
							string objFullPathWithoutExt;
							if( indexOf( options, "-op" ) > -1 )
							{
								objFullPathWithoutExt = Path.stripExtension( s );
							}
							else
							{
								string objPath;
								auto optionPos = indexOf( options, "-od=" );
								if( optionPos > -1 )
								{
									string _pathname;
									for( int i = cast(int) optionPos + 4; i < options.length; ++ i )
									{
										if( options[i] == '\t' || options[i] == ' ' ) break;
										_pathname ~= options[i];
									}
									objFullPathWithoutExt = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _pathname ~ "/" ~ Path.stripExtension( Path.baseName( s ) );
								}
								else
								{
									optionPos = indexOf( options, "-od" );
									if( optionPos > -1 )
									{
										string _pathname;
										for( int i = cast(int) optionPos + 3; i < options.length; ++ i )
										{
											if( options[i] == '\t' || options[i] == ' ' ) break;
											_pathname ~= options[i];
										}
										objFullPathWithoutExt = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _pathname ~ "/" ~ Path.stripExtension( Path.baseName( s ) );
									}
									else
									{
										objFullPathWithoutExt = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ Path.stripExtension( Path.baseName( s ) );
									}
								}
							}						
						
							version(Windows) objFullPathWithoutExt ~= ".obj"; else objFullPathWithoutExt ~= ".o";
							if( exists( objFullPathWithoutExt ) ) txtSources = txtSources ~ " \"" ~ objFullPathWithoutExt ~ "\"" ;			
						}
						break;
						
					default:
				}
			}
			
			if( SourceType == 1 && !txtSources.length ) bNoSourceNeedBeCompiled = true;
			
			version(FBIDE)
			{
				if( GLOBAL.projectManager[activePrjName].passOneFile == "ON" )
				{
					if( GLOBAL.projectManager[activePrjName].mainFile.length )
					{
						string mainFilePath = GLOBAL.projectManager[activePrjName].mainFile;
						foreach( s; GLOBAL.projectManager[activePrjName].sources )
						{
							if( s.length > 4 )
							{
								if( Uni.toLower( s[$-3..$] ) == "bas" )
								{
									string name = Path.stripExtension( Path.baseName( mainFilePath ) );
									if( Path.isAbsolute( mainFilePath ) )
									{
										if( Uni.toLower( s[0..$-4] ) == Uni.toLower( name ) )
										{
											txtSources = " -b \"" ~ s ~ "\"";
											bGotOneFileToBuild = true;
											break;
										}
									}
									else
									{
										string relativePath = Array.replace( s[0..$-4], GLOBAL.projectManager[activePrjName].dir ~ "/", "" );
										if( Uni.toLower( relativePath ) == Uni.toLower( name ) ) 
										{
											txtSources = " -b \"" ~ s ~ "\"";
											bGotOneFileToBuild = true;
											break;
										}
									}
								}
							}
						}
					}
					else
					{
						GLOBAL.messagePanel.printOutputPanel( "Please Set Main File Without Extension, The Project is set One File Mode.", true );
						if( GLOBAL.compilerSettings.useSFX == "ON" )
						{
							version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); else IupExecute( "aplay", "settings/sound/error.wav" );
						}
						return false;
					}
				}
			}
			
			if( !txtSources.length && SourceType != 1 )
			{
				GLOBAL.messagePanel.printOutputPanel( "Without source files......?\n\nBuild Error!", true );
				return false;
			}

			foreach( s; GLOBAL.projectManager[activePrjName].others )
			{
				txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
			}				

			version(FBIDE)
			{
				foreach( s; _focus.IncDir )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -i \"" ~ s ~ "\"";
				}

				foreach( s; _focus.LibDir )
				{
					txtLibDirs = txtLibDirs ~ " -p \"" ~ s ~ "\"";
				}
			}
			version(DIDE)
			{
				version(Windows)
				{
					int _COMPILERVER = DMDversion( compiler );
					if( indexOf( _focus.Option, "-m32omf" ) > -1 ) _COMPILERVER = 1;
				}
				
				foreach( s; _focus.IncDir )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -I\"" ~ s ~ "\"";
				}
				
				// SourceType = 1 mean compile all sources to object, no need pass the libraries
				if( SourceType != 1 )
				{
					foreach( s; _focus.LibDir )
					{
						if( s.length )
						{
							version(Windows)
							{
								s = Array.replace( s.dup, '/', '\\' );

								if( indexOf( s, " " ) > -1 )
								{
									wstring ws = ( UTF.toUTF16( s ) );
									wstring shortName;
									shortName.length = ws.length + 1;

									DWORD len = GetShortPathNameW( UTF.toUTF16z( ws ), cast(wchar*) shortName.ptr, cast(int) ws.length + 1  );
									if( len > 0 && len <= ws.length )
									{
										s = strip( UTF.toUTF8( shortName[0..len] ) );
									}
									else
									{
										Ihandle* messageDlg = IupMessageDlg();
										IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION,TITLE=Message,BUTTONDEFAULT=1" );
										IupSetAttribute( messageDlg, "VALUE", toStringz( "Libraries Path Error!" ) );
										IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );	
										return false;
									}
								}
								
								if( _COMPILERVER > 1 )
									txtLibDirs = txtLibDirs ~ " -L/LIBPATH:\"" ~ s ~ "\"";
								else
								{
									if( !txtLibDirs.length ) txtLibDirs = " -L-L+" ~ s ~ "\\"; else txtLibDirs = txtLibDirs ~ "+" ~ s ~ "\\";
								}
							}
							else
							{
								txtLibDirs = " -L-L\"" ~ s ~ "\"";
							}
						}
					}
				}

				string bits;
				if( _COMPILERVER == 4 )
					if( GLOBAL.compilerSettings.Bit64 == "ON" ) bits = "--m64 "; else bits = "--m32 ";
			}
			

			if( SourceType == 1 )
			{
				if( bNoSourceNeedBeCompiled ) return true;
				
				version(FBIDE)
				{
					string _m = Path.stripExtension( Path.baseName ( GLOBAL.projectManager[activePrjName].mainFile ) );
					filesANDargs = "-c" ~ ( _m.length ? ( " -m \"" ~ _m ) ~ "\"" : "" ) ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ ( options.length ? " " ~ options : "" ) ~ ( optionDebug.length ? " " ~ optionDebug : "" );
					
				}
				version(DIDE)
				{
					filesANDargs = bits ~ "-c " ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ ( options.length ? " " ~ options : "" );
				}

				return true;
			}


			string executeName, _targetName;
			if( _focus.Target.length ) _targetName = Path.stripExtension( _focus.Target ); else _targetName = GLOBAL.projectManager[activePrjName].name;
			_targetName = strip( _targetName );
			version(Windows)
			{
				switch( GLOBAL.projectManager[activePrjName].type )
				{
					case "2":
						version(FBIDE)	executeName = " -lib -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						version(DIDE)	executeName = " -lib -of\"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".lib\"";
						break;
					case "3":
						version(FBIDE)	executeName = " -dll -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".dll\"";
						version(DIDE)	executeName = " -shared -of\"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".dll\"";
						break;
					default:
						version(FBIDE)	executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".exe\"";
						version(DIDE)	if( _COMPILERVER > 1 ) executeName = " -of\"" ~ _targetName ~ ".exe\""; else executeName = " -of\"" ~ _targetName ~ "\"";
				}
			}
			else
			{
				switch( GLOBAL.projectManager[activePrjName].type )
				{
					case "2":
						version(FBIDE)	executeName = " -lib -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						version(DIDE)	executeName = " -lib -of\"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						break;
					case "3":
						version(FBIDE)	executeName = " -dll -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".so\"";
						version(DIDE)	executeName = " -shared -of\"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".so\"";
						break;
					default:
						version(FBIDE)	executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ "\"";
						version(DIDE)	executeName = " -of\"" ~ _targetName ~ "\"";
				}
			}

	
			version(FBIDE)
			{
				bool 	bWithExt;
				string	mainFile;
				if( GLOBAL.projectManager[activePrjName].mainFile.length )
				{
					string mainFilePath = GLOBAL.projectManager[activePrjName].mainFile;
					if( Path.extension( mainFilePath ).length )
					{
						mainFile = Path.dirName( mainFilePath ) ~ "/ " ~ Path.stripExtension( Path.baseName( mainFilePath ) );
						bWithExt = true;
					}
					else
						mainFile = mainFilePath;
				}
			
				filesANDargs = executeName ~ ( bGotOneFileToBuild ? "" : ( mainFile.length ? ( " -m \"" ~ mainFile ) ~ "\"" : "" ) ) ~
							txtSources ~ txtIncludeDirs ~ txtLibDirs ~ ( options.length ? " " ~ options : "" ) ~ ( optionDebug.length ? " " ~ optionDebug : "" );
				
			}
			version(DIDE)
			{
				filesANDargs = executeName ~ " " ~ bits ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ ( options.length ? " " ~ options : "" );
			}
			
			version(FBIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) filesANDargs ~= " -s gui";
			version(DIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) filesANDargs ~= " -L/SUBSYSTEM:WINDOWS";
			
			version(FBIDE) if( bWithExt ) GLOBAL.messagePanel.printOutputPanel( "****** Warnning! Main File Should Withould Extension! ******\n", false );

			// Create Dir for Target
			string _targetPath = Path.dirName( GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName );
			if( !exists( _targetPath ) ) std.file.mkdir( _targetPath );			
		}
		catch( Exception e )
		{
			return false;
		}	
		
		return true;
	}

public:
	static string		quickRunFile;
	
	static int compile( string options = null, string args = null, string compiler = null, string optionDebug = null, bool bRun = false )
	{
		version(linux) if( bRun && !checkTerminalExists() ) return false;

		GLOBAL.messagePanel.printOutputPanel( "", true );
		
		string files;
		auto cSci = ScintillaAction.getActiveCScintilla();

		// Show the message panel
		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		if( cSci !is null )
		{
			// Get Custom Compiler
			string customOpt, customCompiler;
			CustomToolAction.getCustomCompilers( customOpt, customCompiler );
			
			// Set The Using Compiler Path
			if( !compiler.length ) compiler = ( customCompiler.length ? customCompiler : ( GLOBAL.compilerSettings.Bit64 == "OFF" ? GLOBAL.compilerSettings.compilerFullPath : GLOBAL.compilerSettings.x64compilerFullPath ) );
			
			version(Windows)
			{
				foreach( s; GLOBAL.EnvironmentVars.keys )
				{
					compiler = Array.replace( Uni.toLower( compiler ), Uni.toLower( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
				}
			}
			
			// Check the compiler existed?
			if( !checkCompilerExists( compiler ) ) return false;

			if( !ScintillaAction.saveFile( cSci ) )
			{
				GLOBAL.messagePanel.printOutputPanel( "Compile Cancel By User.\n\nCompile Cancel!", true );
				return false;
			}
			else
			{
				if( GLOBAL.editorSetting00.SaveAllModified == "ON" )
				{
					foreach( CScintilla _cSci; GLOBAL.scintillaManager )
					{
						if( ScintillaAction.getModifyByTitle( _cSci ) ) ScintillaAction.saveFile( _cSci );
					}
				}
			}
			
			version(DIDE)
			{
				string bits;
				if( tools.DMDversion( compiler ) == 4 )
					if( GLOBAL.compilerSettings.Bit64 == "ON" ) bits = "--m64 "; else bits = "--m32 ";
			}			

			// Set The Using Opts
			options = strip( options );
			if( !options.length ) options = strip( customOpt );
			options = options ~ ( optionDebug.length ? " " ~ optionDebug : "" );
			version(Windows)
			{
				version(FBIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) options ~= " -s gui";
				version(DIDE)
				{
					if( GLOBAL.toolbar.checkGuiButtonStatus ) options ~= " -L/SUBSYSTEM:WINDOWS";
					options = bits ~ options;
				}
			}

			string _beCompiledFile = "\"" ~ cSci.getFullPath ~ "\"";
			GLOBAL.messagePanel.printOutputPanel( "Compile " ~ _beCompiledFile ~ "......" , true );
			GLOBAL.messagePanel.printOutputPanel( compiler ~ " " ~ _beCompiledFile ~ " " ~ options ~ "\n", false );
			// Pass compiler, files, options to Thread
			
			auto _thread = new CompileThread( compiler, cSci.getFullPath, options, Path.dirName( cSci.getFullPath ), bRun, args );
			_thread.start;
			if( GLOBAL.compilerSettings.useThread != "ON" )
				_thread.join;
			else
				version(Posix) _thread.join;
		}
		else
		{
			GLOBAL.messagePanel.printOutputPanel( "Without any source file has been selected......?\n\nCompile Error!", true );
			return false;
		}

		
		try
		{
			if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);
		   return false;
		}

		return false;
	}
	
	static bool build( string options = null, string args = null, string compiler = null, string optionDebug = null )
	{
		try
		{
			// Keep Message panel open
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
			IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );
			GLOBAL.messagePanel.printOutputPanel( "", true ); // Clean outputPanel
		
			string finalArgsString;
			string activePrjName = ProjectAction.getActiveProjectName();
			if( getBuildNeedData( compiler, finalArgsString, options, optionDebug, 1 ) )
			{
				// Start Thread
				if( finalArgsString.length )
				{
					GLOBAL.messagePanel.printOutputPanel( "Buinding Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]......\n\n" ~ compiler ~ " " ~ finalArgsString ~ "\n\n", true );
					auto _thread = new CompileThread( compiler, "", finalArgsString, GLOBAL.projectManager[activePrjName].dir );
					_thread.go;
					if( !_thread.getCompileResult ) return false;
				}
				
				if( finalArgsString.length ) GLOBAL.messagePanel.printOutputPanel( "\n************************************\n", false );
				
				auto bLinkResult = getBuildNeedData( compiler, finalArgsString, options, optionDebug, 2 );
				GLOBAL.messagePanel.printOutputPanel( "Continue Link Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]......\n\n" ~ compiler ~ finalArgsString ~ "\n", false );
				if( bLinkResult )
				{
					auto _thread = new CompileThread( compiler, "", finalArgsString, GLOBAL.projectManager[activePrjName].dir );
					_thread.start;
					if( GLOBAL.compilerSettings.useThread != "ON" )
						_thread.join;
					else
						version(Posix) _thread.join;					
				}
				else
				{
					return false;
				}
				
				if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );
				return true;
			}
		}
		catch( Exception e )
		{
			IupMessage( "",toStringz( e.toString ) );
		}

		return false;
	}	
	
	static bool buildAll( string options = null, string compiler = null, string optionDebug = null )
	{
		try
		{
			// Keep Message panel open
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
			IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );
			GLOBAL.messagePanel.printOutputPanel( "", true ); // Clean outputPanel
		
			string activePrjName = ProjectAction.getActiveProjectName();
			string finalArgsString;
			if( getBuildNeedData( compiler, finalArgsString, options, optionDebug, 0 ) )
			{
				GLOBAL.messagePanel.printOutputPanel( "Building Project: " ~ GLOBAL.projectManager[activePrjName].name ~ "......\n\n" ~ compiler ~ finalArgsString ~ "\n", true );

				// Start Thread
				auto _thread = new CompileThread( compiler, "", finalArgsString, GLOBAL.projectManager[activePrjName].dir );
				_thread.start;
				if( GLOBAL.compilerSettings.useThread != "ON" )
					_thread.join;
				else
					version(Posix) _thread.join;				
				
				if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );
				return true;
			}
		}
		catch( Exception e )
		{
			IupMessage( "",toStringz( e.toString ) );
		}

		return false;
	}

	
	static bool quickRun( string options = null, string args = null, string compiler = null )
	{
		version(linux)
		{
			if( !checkTerminalExists() ) 
			{
				int dummy = tools.questMessage( "Error", "The linux terminal path isn't set.", "ERROR", "OK" );
				return false;
			}
		}
		
		GLOBAL.messagePanel.printOutputPanel( "", true );
		
		quickRunFile = "";
		
		string files;
		auto cSci = ScintillaAction.getActiveCScintilla();

		// Show the message panel
		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		if( cSci !is null )
		{
			// Get Custom Compiler
			string customOpt, customCompiler;
			CustomToolAction.getCustomCompilers( customOpt, customCompiler );
			
			// Set The Using Compiler Path
			if( !compiler.length ) compiler = ( customCompiler.length ? customCompiler : ( GLOBAL.compilerSettings.Bit64 == "OFF" ? GLOBAL.compilerSettings.compilerFullPath : GLOBAL.compilerSettings.x64compilerFullPath ) );
			
			version(Windows)
			{
				foreach( s; GLOBAL.EnvironmentVars.keys )
				{
					compiler = Array.replace( Uni.toLower( compiler ), Uni.toLower( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
				}
			}

			// Set The Using Opts
			options = strip( options );
			if( !options.length ) options = strip( customOpt );
			version(Windows)
			{
				version(FBIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) options ~= " -s gui";
				version(DIDE)
				{
					if( GLOBAL.toolbar.checkGuiButtonStatus ) options ~= " -L/SUBSYSTEM:WINDOWS";
					if( tools.DMDversion( compiler ) == 4 )
						if( GLOBAL.compilerSettings.Bit64 == "ON" ) options = "--m64 " ~ options; else options = "--m32 " ~ options;
				}
			}
		
			string fileName = "poseidonTemp" ~ Conv.to!(string)(MonoTime.currTime.ticks)[$-4..$];
			
			if( GLOBAL.linuxHome.length )
			{
				version(FBIDE) fileName = GLOBAL.linuxHome ~ "/" ~ fileName ~ ".bas"; else fileName =GLOBAL.linuxHome ~ "/" ~ fileName ~ ".d";
			}
			else
			{
				version(FBIDE) fileName = Path.dirName( cSci.getFullPath ) ~ "/" ~ fileName ~ ".bas"; else fileName = Path.dirName( cSci.getFullPath ) ~ "/" ~ fileName ~ ".d";
			}
			FileAction.saveFile( fileName, cSci.getText, BOM.utf8, true );
			quickRunFile = cSci.getFullPath;
		
			GLOBAL.messagePanel.printOutputPanel( "Quick Run " ~ cSci.getFullPath ~ "......\n", true );
			// Pass compiler, files, options to Thread
			auto _thread = new CompileThread( compiler, fileName, options, Path.dirName( fileName ), true, args, true );
			_thread.start;
			if( GLOBAL.compilerSettings.useThread != "ON" )
				_thread.join;
			else
				version(Posix) _thread.join;			
			
			return true;
		}
		else
		{
			GLOBAL.messagePanel.printOutputPanel( "Without any source file has been selected......?\n\nQuick Run Error!", true );
		}
		return false;
	}

	static bool run( string args = null, bool bForceCompileOne = false )
	{
		version(linux)
		{
			if( !checkTerminalExists() ) 
			{
				int dummy = tools.questMessage( "Error", "The linux terminal path isn't set.", "ERROR", "OK" );
				return false;
			}
		}
		// Keep Message panel open
		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );

		
		bool	bRunProject;
		string	activePrjName	= actionManager.ProjectAction.getActiveProjectName();
		
		// Set Multiple Focus Project
		FocusUnit	_beRunfocus;
		string		_beRunFile;
		string		_bePassArgs;
		
		if( activePrjName.length )
		{
			if( activePrjName in GLOBAL.projectManager )
			{
				bRunProject = true;
				if( GLOBAL.projectManager[activePrjName].focusOn.length )
				{
					if( GLOBAL.projectManager[activePrjName].focusOn in GLOBAL.projectManager[activePrjName].focusUnit ) _beRunfocus = GLOBAL.projectManager[activePrjName].focusUnit[GLOBAL.projectManager[activePrjName].focusOn];
				}
			}
			
			if( _beRunfocus.Target.length ) _beRunFile = Path.stripExtension( _beRunfocus.Target );
			if( !_beRunFile.length ) _beRunFile = Path.stripExtension( GLOBAL.projectManager[activePrjName].targetName );
			if( !_beRunFile.length ) _beRunFile = Path.stripExtension( GLOBAL.projectManager[activePrjName].name );
			if( _beRunFile.length )
			{
				_beRunFile = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _beRunFile;
				_bePassArgs = strip( GLOBAL.projectManager[activePrjName].args );
			}
			
			if( GLOBAL.projectManager[activePrjName].type != "1" )
			{
				GLOBAL.messagePanel.printOutputPanel( "Can't Run Static / Dynamic Library............Run Error!", true );
				return false;
			}			
		}
		// Not in project! try single exe
		if( !bRunProject )
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			if( cSci !is null ) _beRunFile = Path.stripExtension( cSci.getFullPath() );
		}
		
		if( args.length ) _bePassArgs = args;
		version(Windows) if( _beRunFile.length ) _beRunFile = _beRunFile ~ ".exe";
		GLOBAL.messagePanel.printOutputPanel( "Run " ~ _beRunFile ~ "......\n", true );
		if( exists( _beRunFile ) )
		{
			auto _thread = new ExecuterThread( _beRunFile, _bePassArgs, getBuildNeedDataToTLS, Path.dirName( _beRunFile ) );
			_thread.start;
			/+
			auto pid = spawnShell( _beRunFile ~ " " ~ _bePassArgs, null, Config.none, Path.dirName( _beRunFile ) );
			tryWait(pid);
			+/
		}
		else
		{
			GLOBAL.messagePanel.printOutputPanel( "Execute file: " ~ _beRunFile ~ "\nisn't exist......?\n\nRun Error!", true );
			return false;
		}
	
		return true;
	}
}