module executer;

version(Windows)
{
	extern(Windows) bool PlaySound( char*, void*, uint );
}
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

	import global, actionManager, menu, tools, scintilla, project;

	import tango.sys.Process, tango.core.Exception, tango.io.stream.Lines, tango.io.stream.Iterator;
	import tango.io.Stdout, tango.stdc.stringz, Util = tango.text.Util, Integer = tango.text.convert.Integer;
	import tango.io.FilePath, Path = tango.io.Path;

	import tango.core.Thread;
	import tango.time.Time, tango.time.Clock;
	
	version(DIDE)
	{
		import tango.sys.win32.UserGdi, UTF = tango.text.convert.Utf;
	}
	
	// Inner Class
	class ExecuterThread : Thread
	{
		private:
		char[]	command, args, cwd;
		bool	bQuickRun;

		public:
		this( char[] _command, char[] _args, char[] _cwd = null, bool _bQuickRun = false )
		{
			command		= _command;
			args		= _args;
			cwd 		= _cwd;
			bQuickRun	= _bQuickRun;
			
			super( &run );
		}

		void run()
		{
			Process	p;
			char[]		scommand;
			
			if( GLOBAL.consoleExe == "ON" )
			{
				version(Windows)
				{
					//scommand = "consoleLauncher " ~ command ~ args;
					if( GLOBAL.consoleWindow.id < GLOBAL.monitors.length )
					{
						int x = GLOBAL.consoleWindow.x + GLOBAL.monitors[GLOBAL.consoleWindow.id].x;
						int y = GLOBAL.consoleWindow.y + GLOBAL.monitors[GLOBAL.consoleWindow.id].y;
						
						scommand = "consoleLauncher 0 " ~ Integer.toString( x ) ~ " " ~ Integer.toString( y ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.w ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.h ) ~ " " ~ command ~ args;
					}
					else
					{
						scommand = "consoleLauncher 0 0 0 0 0 " ~ command ~ args;
					}
				}
				else
				{
					if( command[0] == '"' && command[$-1] == '"' )
						scommand = "\"" ~ GLOBAL.poseidonPath ~ "./consoleLauncher " ~ Integer.toString( GLOBAL.consoleWindow.id ) ~ " -1 -1 " ~ Integer.toString( GLOBAL.consoleWindow.w ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.h ) ~ " " ~ command[1..$-1] ~ args ~ "\"";
					else
						scommand = "\"" ~ GLOBAL.poseidonPath ~ "./consoleLauncher " ~ Integer.toString( GLOBAL.consoleWindow.id ) ~ " -1 -1 " ~ Integer.toString( GLOBAL.consoleWindow.w ) ~ " " ~ Integer.toString( GLOBAL.consoleWindow.h ) ~ " " ~ command ~ args ~ "\"";
				}
			}
			else
			{
				version(Windows) scommand = command ~ args; else scommand = "\"" ~ command ~ args ~ "\"";
			}
			
			version(Windows)
			{
				p = new Process( true, scommand );
			}
			else
			{
				// --hide-menubar
				// --geometry
				// -t poseidonFB_terminal
				char[] geoString;
				if( GLOBAL.consoleWindow.id < GLOBAL.monitors.length )
				{
					int x = GLOBAL.consoleWindow.x + GLOBAL.monitors[GLOBAL.consoleWindow.id].x;
					int y = GLOBAL.consoleWindow.y + GLOBAL.monitors[GLOBAL.consoleWindow.id].y;
					geoString = " --geometry=80x24+" ~ Integer.toString( x ) ~ "+" ~ Integer.toString( y );
				}
				
				//	p = new Process( true, GLOBAL.linuxTermName ~ geoString ~ " -e " ~ scommand );
				auto terminalExe = new FilePath( GLOBAL.linuxTermName );
				if( terminalExe !is null )
				{
					char[] terminalExeName = lowerCase( terminalExe.file );
					switch( lowerCase( terminalExe.file ) )
					{
						case "xterm", "uxterm":
							p = new Process( true, GLOBAL.linuxTermName ~ " -T poseidon_terminal" ~ geoString ~ " -e " ~ scommand );
							break;
						case "gnome-terminal", "mate-terminal" ,"xfce4-terminal" ,"lxterminal":
							p = new Process( true, GLOBAL.linuxTermName ~ " --title poseidon_terminal" ~ geoString ~ " -e " ~ scommand );
							break;
						default:
							p = new Process( true, GLOBAL.linuxTermName ~ " -e " ~ scommand );
					}
				}
				else
				{
					return;
				}
			}
			
			if( cwd.length ) p.workDir( cwd );
			p.redirect( Redirect.None );
			p.execute;
			
			auto result = p.wait;
			
			if( bQuickRun )
			{
				switch( result.reason )
				{
					case Process.Result.Error, Process.Result.Signal, Process.Result.Exit, Process.Result.Stop:
						if( command.length )
						{
							if( command[0] == '"' && command[length-1] == '"' )
							{
								scope _f = new FilePath( command[1..length-1] );
								_f.remove();
							}
						}
						break;
						
					default:
				}
			}
		}
	}
	
	
	class CompileThread : Thread
	{
		private:
		PROJECT		activePrj;
		char[]		cwd, command;
		FocusUnit	focus;

		public:
		this( char[] _cwd, char[] _command )
		{
			cwd				= _cwd;
			command			= _command;
			
			super( &run );
		}

		void run()
		{
			Process p = new Process( true, command );
			p.gui( true );
			p.workDir( cwd );
			p.execute;

			bool	bError, bWarning;
			char[]	stdoutMessage, stderrMessage;
			version(FBIDE)
			{
				foreach (line; new Lines!(char)(p.stderr))  
				{
					if( !bWarning )
					{
						if( Util.index( line, "warning:" ) < line.length )
						{
							bWarning = true;
							stderrMessage ~= ( line ~ "\n" );
							version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
							continue;
						}
					}
					
					if( !bError )
					{
						if( line.length ) bError = true;
					}				

					stderrMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}

				foreach( line; new Lines!(char)(p.stdout) )
				{
					if( !bWarning )
					{
						if( Util.index( line, "warning " ) < line.length ) bWarning = true;
					}
					if( !bError )
					{
						if( Util.index( line, "error " ) < line.length ) bError = true;
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}
			}
			version(DIDE)
			{
				foreach( line; new Lines!(char)(p.stderr) )  
				{
					if( Util.trim( line ).length ) bError = true;
					stderrMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}

				foreach( line; new Lines!(char)(p.stdout) )
				{
					if( !bError )
					{
						if( Util.index( line, "): " ) < line.length )
							bError = true;
						else if( Util.index( line, "Error " ) < line.length )
							bError = true;
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}
			}

			auto result = p.wait;

			version(FBIDE)
			{
				if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
			}
			version(DIDE)
			{
				if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length )
				{
					showAnnotation( stdoutMessage ~ stderrMessage );
				}
				else
					showAnnotation( null );
			}
			GLOBAL.messagePanel.applyOutputPanelINDICATOR();
			
			if( bError )
			{
				version(Windows) GLOBAL.messagePanel.printOutputPanel( "Compile Error!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Compile Error!" );

				if( GLOBAL.compilerWindow == "ON" )
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
						if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/error.wav", null, 0x0001 );
					}
					else
					{
						if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/error.wav" );
					}
				}
				
				if( GLOBAL.delExistExe == "ON" )
				{
					// Remove the execute file
					scope targetFilePath = new FilePath( ScintillaAction.getActiveCScintilla.getFullPath() );
					version(Windows) targetFilePath.set( targetFilePath.path() ~ targetFilePath.name() ~ ".exe" ); else targetFilePath.set( targetFilePath.path() ~ targetFilePath.name() );
					if( targetFilePath.exists() ) targetFilePath.remove();
				}
			}
			else
			{
				if( !bWarning )
				{
					version(Windows) GLOBAL.messagePanel.printOutputPanel( "Compile Success!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Compile Success!" );

					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/success.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/success.wav" );
						}							
					}
				}
				else
				{
					version(Windows) GLOBAL.messagePanel.printOutputPanel( "Compile Success! But got warning..." ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Compile Success! But got warning..." );

					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/warning.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/warning.wav" );
						}							
					}
				}
			}
		}
	}		
	
	
	class BuildThread : Thread
	{
		private:
		PROJECT		activePrj;
		char[]		command, extraOptions, optionDebug, compilePath, executeName;
		FocusUnit	focus;

		public:
		this( PROJECT _prj, char[] _command, char[] _extraOptions, char[] _optionDebug, char[] _compilePath, char[] _executeName )
		{
			activePrj		= _prj;
			command			= _command;
			extraOptions	= _extraOptions;
			optionDebug		= _optionDebug;
			compilePath		= _compilePath;
			executeName		= _executeName;
			
			// Set Multiple Focus Project
			focus.Compiler	= _prj.compilerPath;
			focus.Option	= _prj.compilerOption;
			focus.Target	= _prj.targetName;
			focus.IncDir	= _prj.includeDirs;
			focus.LibDir	= _prj.libDirs;
			if( _prj.focusOn.length )
				if( _prj.focusOn in _prj.focusUnit ) focus = _prj.focusUnit[_prj.focusOn];
			
			
			super( &run );
		}

		void run()
		{
			bool	bError, bWarning;
			char[]	stdoutMessage, stderrMessage;			
			
			if( command.length )
			{
				Process p = new Process( true, command );
				p.workDir( activePrj.dir );
				p.gui( true );
				p.execute;


				version(FBIDE)
				{
					foreach (line; new Lines!(char)(p.stderr))  
					{
						if( !bWarning )
						{
							if( Util.index( line, "warning:" ) < line.length )
							{
								bWarning = true;
								stderrMessage ~= ( line ~ "\n" );
								version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
								continue;
							}
						}
						
						if( !bError )
						{
							if( line.length ) bError = true;
						}				

						stderrMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}

					foreach (line; new Lines!(char)(p.stdout))  
					{
						if( !bWarning )
						{
							if( Util.index( line, "warning " ) < line.length ) bWarning = true;
						}
						if( !bError )
						{
							if( Util.index( line, "error " ) < line.length )
								bError = true;
							else if( Util.index( line, "Error!" ) < line.length )
								bError = true;
						}				
						
						stdoutMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}
				}
				version(DIDE)
				{
					foreach (line; new Lines!(char)(p.stderr))  
					{
						if( Util.trim( line ).length ) bError = true;
						stderrMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}

					foreach (line; new Lines!(char)(p.stdout))  
					{
						if( !bError )
						{
							if( Util.index( line, "): " ) < line.length )
								bError = true;
							else if( Util.index( line, "Error " ) < line.length )
								bError = true;
							
						}				
						
						stdoutMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}
				}
		
				auto result = p.wait;

				version(FBIDE)
				{
					if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
				}
				version(DIDE)
				{
					if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length )
					{
						showAnnotation( stdoutMessage ~ stderrMessage );
					}
					else
						showAnnotation( null );
				}
				GLOBAL.messagePanel.applyOutputPanelINDICATOR();

				if( bError )
				{
					version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Error!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Error!" );

					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/error.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/error.wav" );
						}							
					}
					
					if( GLOBAL.delExistExe == "ON" )
					{
						// Remove the execute file
						char[] _targetName = activePrj.dir ~ "/" ~ focus.Target;
						
						version(Windows) _targetName ~= ".exe";

						scope targetFilePath = new FilePath( _targetName );
						if( targetFilePath.exists() ) targetFilePath.remove();
					}					
				}
				else
				{
					if( !bWarning )
					{
						version(Windows) GLOBAL.messagePanel.printOutputPanel( "Compile Objs Success!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Compile Objs Success!" );
					}
					else
					{
						version(Windows) GLOBAL.messagePanel.printOutputPanel( "Compile Objs Success! But got warning..." ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Compile Objs Success! But got warning..." );
					}
				}
			}

			if( !bError )
			{
				char[] txtSources, txtLibDirs; 
				
				bWarning = bError = false;
				stdoutMessage = stderrMessage = "";
				
				foreach( char[] s; activePrj.others )
				{
					txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
				}				

				version(FBIDE)
				{
					foreach( char[] s; focus.LibDir )
					{
						txtLibDirs = txtLibDirs ~ " -p \"" ~ s ~ "\"";
					}
				}
				version(DIDE)
				{
					foreach( char[] s; focus.LibDir )
					{
						if( s.length )
						{
							version(Windows)
							{
								if( s[$-1] != '/' ) s ~= '/';
								s = Util.replace( s.dup, '/', '\\' );

								if( Util.contains( s, ' ' ) )
								{
									wchar[] ws = ( UTF.toString16( s ) ).dup;
									wchar[] shortName;
									shortName.length = ws.length + 1;
									shortName[] = ' ';

									DWORD len = GetShortPathNameW( toString16z( ws ), shortName.ptr, ws.length + 1  );
									if( len > 0 && len <= ws.length )
									{
										s = Util.trim( UTF.toString( shortName[0..len] ) );
									}
									else
									{
										Ihandle* messageDlg = IupMessageDlg();
										IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION,TITLE=Message,BUTTONDEFAULT=1" );
										IupSetAttribute( messageDlg, "VALUE", toStringz( "Libraries Path Error!" ) );
										IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );	
										return;
									}
								}
								
								if( !txtLibDirs.length ) txtLibDirs = " -L-L+" ~ s; else txtLibDirs = txtLibDirs ~ "+" ~ s;
							}
							else
							{
								txtLibDirs = " -L-L\"" ~ s ~ "\"";
							}
						}
					}
				}
				
				foreach( char[] s; activePrj.sources )
				{
					scope fPath = new FilePath( s );
					if( fPath.exists() )
					{
						version(FBIDE)
						{
							scope oPath = new FilePath( fPath.path ~ fPath.name ~ ".o" );
							if( oPath.exists() ) txtSources = txtSources ~ " -a \"" ~ oPath.toString ~ "\"" ; 
						}
						version(DIDE)
						{
							char[]		objPath = activePrj.dir ~ "/";
							char[] 		_totalOptions = focus.Option ~ " " ~ extraOptions;
							FilePath	oPath;
							
							int ofPos = Util.index( _totalOptions, "-od" );
							if( ofPos < _totalOptions.length )
							{
								char[] outputName;
								for( int i = ofPos + 3; i < _totalOptions.length; ++ i )
								{
									if( _totalOptions[i] == '\t' || _totalOptions[i] == ' ' ) break;
									outputName ~= _totalOptions[i];
								}
								
								// Got Obj Path -od
								if( outputName.length ) objPath ~= ( outputName ~ "/" );
							}

							version(Windows) oPath = new FilePath( objPath ~ fPath.name ~ ".obj" ); else oPath = new FilePath( objPath ~ fPath.name ~ ".o" );
							if( oPath.exists() ) txtSources = txtSources ~ " \"" ~ oPath.toString ~ "\"" ;
							
							delete oPath;
						}
					}
				}
				
				version(FBIDE)
				{
					command = "\"" ~ compilePath ~ "\"" ~ executeName ~ txtSources ~ txtLibDirs ~ ( focus.Option.length ? " " ~	focus.Option : "" ) ~ 
					( extraOptions.length ? " " ~ extraOptions : "" ) ~ ( optionDebug.length ? " " ~ optionDebug : "" );
				}
				version(DIDE)
				{
					command = "\"" ~ compilePath ~ "\"" ~ executeName ~ ( GLOBAL.toolbar.checkBitButtonStatus != 32 ? " -m64" : "" ) ~ txtSources ~ txtLibDirs ~ ( focus.Option.length ? " " ~
								focus.Option : "" ) ~ ( extraOptions.length ? " " ~ extraOptions : "" );
				}
				
				version(FBIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) command ~= " -s gui";// else txtCommand ~= " -s console";
				version(DIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) command ~= " -L/SUBSYSTEM:windows:4";
				
				scope fp = new FilePath( activePrj.dir ~ "/" ~ activePrj.targetName );
				fp.set( fp.path );
				if( !fp.exists ) fp.create;

				
				Process p2 = new Process( true, command );
				p2.workDir( activePrj.dir );
				p2.gui( true );
				p2.execute;

				// Compiler Command
				version(Windows)
					GLOBAL.messagePanel.printOutputPanel( "\n\nContinue Link Project: " ~ activePrj.name ~ "......\n\n" ~ command ~ "\n" );
				else
					IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( "\n\nContinue Link Project: " ~ activePrj.name ~ "......\n\n" ~ command ~ "\n" ) );
					
				version(FBIDE)
				{
					foreach (line; new Lines!(char)(p2.stderr))  
					{
						if( !bWarning )
						{
							if( Util.index( line, "warning:" ) < line.length )
							{
								bWarning = true;
								stderrMessage ~= ( line ~ "\n" );
								version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
								continue;
							}
						}
						
						if( !bError )
						{
							if( line.length ) bError = true;
						}				

						stderrMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}

					foreach (line; new Lines!(char)(p2.stdout))  
					{
						if( !bWarning )
						{
							if( Util.index( line, "warning " ) < line.length ) bWarning = true;
						}
						if( !bError )
						{
							if( Util.index( line, "error " ) < line.length )
								bError = true;
							else if( Util.index( line, "Error!" ) < line.length )
								bError = true;
						}				
						
						stdoutMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}
				}
				version(DIDE)
				{
					foreach (line; new Lines!(char)(p2.stderr))  
					{
						if( Util.trim( line ).length ) bError = true;
						stderrMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}

					foreach (line; new Lines!(char)(p2.stdout))  
					{
						if( !bError )
						{
							if( Util.index( line, "): " ) < line.length )
								bError = true;
							else if( Util.index( line, "Error " ) < line.length )
								bError = true;
							
						}				
						
						stdoutMessage ~= ( line ~ "\n" );
						version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
					}
				}
		
				auto result2 = p2.wait;

				version(FBIDE)
				{
					if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
				}
				version(DIDE)
				{
					if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length )
						showAnnotation( stdoutMessage ~ stderrMessage );
					else
						showAnnotation( null );
				}
				GLOBAL.messagePanel.applyOutputPanelINDICATOR();

				if( bError )
				{
					version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Error!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Error!" );

					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/error.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/error.wav" );
						}							
					}
					
					if( GLOBAL.delExistExe == "ON" )
					{
						// Remove the execute file
						char[] _targetName = activePrj.dir ~ "/" ~ focus.Target;
						
						version(Windows) _targetName ~= ".exe";

						scope targetFilePath = new FilePath( _targetName );
						if( targetFilePath.exists() ) targetFilePath.remove();
					}
				}
				else
				{
					if( !bWarning )
					{
						version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Success!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Success!" );

						if( GLOBAL.compilerWindow == "ON" )
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
								if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/success.wav", null, 0x0001 );
							}
							else
							{
								if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/success.wav" );
							}							
						}
					}
					else
					{
						version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Success! But got warning..." ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Success! But got warning..." );

						if( GLOBAL.compilerWindow == "ON" )
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
								if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/warning.wav", null, 0x0001 );
							}
							else
							{
								if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/warning.wav" );
							}							
						}				
					}
				}
			}
		}
	}
	
	
	class ReBuildThread : Thread
	{
		private:
		PROJECT		activePrj;
		char[]		command, extraOptions;
		FocusUnit	focus;

		public:
		this( PROJECT _prj, char[] _command, char[] _extraOptions )
		{
			activePrj		= _prj;
			command			= _command;
			extraOptions	= _extraOptions;
			
			// Set Multiple Focus Project
			focus.Compiler	= _prj.compilerPath;
			focus.Option	= _prj.compilerOption;
			focus.Target	= _prj.targetName;
			focus.IncDir	= _prj.includeDirs;
			focus.LibDir	= _prj.libDirs;
			if( _prj.focusOn.length )
				if( _prj.focusOn in _prj.focusUnit ) focus = _prj.focusUnit[_prj.focusOn];
			
			
			super( &run );
		}

		void run()
		{
			Process p = new Process( true, command );
			p.workDir( activePrj.dir );
			p.redirect( Redirect.All );
			p.gui( true );
			p.execute;
			
			
			bool	bError, bWarning;
			char[]	stdoutMessage, stderrMessage;
			version(FBIDE)
			{
				foreach (line; new Lines!(char)(p.stderr))  
				{
					if( !bWarning )
					{
						if( Util.index( line, "warning:" ) < line.length )
						{
							bWarning = true;
							stderrMessage ~= ( line ~ "\n" );
							continue;
						}
					}
					
					if( !bError )
					{
						if( line.length ) bError = true;
					}				

					stderrMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}

				foreach (line; new Lines!(char)(p.stdout))  
				{
					if( !bWarning )
					{
						if( Util.index( line, "warning " ) < line.length ) bWarning = true;
					}
					if( !bError )
					{
						if( Util.index( line, "error " ) < line.length )
							bError = true;
						else if( Util.index( line, "Error!" ) < line.length )
							bError = true;
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}
				
			}
			version(DIDE)
			{
				foreach (line; new Lines!(char)(p.stderr))  
				{
					if( Util.trim( line ).length ) bError = true;
					stderrMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}

				foreach (line; new Lines!(char)(p.stdout))  
				{
					if( !bError )
					{
						if( Util.index( line, "): " ) < line.length )
							bError = true;
						else if( Util.index( line, "Error " ) < line.length )
							bError = true;
						
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
					version(Windows) GLOBAL.messagePanel.printOutputPanel( line ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", toStringz( line ) );
				}
			}				
	
			auto result = p.wait;

			version(FBIDE)
			{
				if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
			}
			version(DIDE)
			{
				if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length )
				{
					showAnnotation( stdoutMessage ~ stderrMessage );
				}
				else
					showAnnotation( null );
			}
			GLOBAL.messagePanel.applyOutputPanelINDICATOR();

			if( bError )
			{
				version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Error!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Error!" );

				if( GLOBAL.compilerWindow == "ON" )
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
						if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/error.wav", null, 0x0001 );
					}
					else
					{
						if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/error.wav" );
					}							
				}
				
				if( GLOBAL.delExistExe == "ON" )
				{
					// Remove the execute file
					char[] _targetName = activePrj.dir ~ "/" ~ focus.Target;
					
					version(Windows) _targetName ~= ".exe";

					scope targetFilePath = new FilePath( _targetName );
					if( targetFilePath.exists() ) targetFilePath.remove();
				}
			}
			else
			{
				if( !bWarning )
				{
					version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Success!" ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Success!" );

					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/success.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/success.wav" );
						}						
					}
				}
				else
				{
					version(Windows) GLOBAL.messagePanel.printOutputPanel( "Build Success! But got warning..." ); else IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "APPEND", "Build Success! But got warning..." );

					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/warning.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/warning.wav" );
						}							
					}				
				}
				
				
				char[]		objPath = activePrj.dir ~ "/";
				char[] 		_totalOptions = focus.Option ~ " " ~ extraOptions;
			
				int ofPos = Util.index( _totalOptions, "-od" );
				if( ofPos < _totalOptions.length )
				{
					char[] outputName;
					for( int i = ofPos + 3; i < _totalOptions.length; ++ i )
					{
						if( _totalOptions[i] == '\t' || _totalOptions[i] == ' ' ) break;
						outputName ~= _totalOptions[i];
					}
					
					// Got Obj Path -od
					if( outputName.length ) objPath ~= ( outputName ~ "/" );
				}
				
				char[] _targetName = activePrj.dir ~ "/" ~ focus.Target;

				version(Windows) objPath ~= ( _targetName ~ ".obj" ); else objPath ~= ( _targetName ~ ".o" );
				
				scope oFilePath = new FilePath( objPath );
				if( oFilePath.exists ) oFilePath.remove;
			}
		}
	}	
	
	
	
	
	
	static void showAnnotation( char[] message )
	{
		if( GLOBAL.compilerAnootation != "ON" ) return;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONCLEARALL", "YES" );
			
			int prevLineNumber, prevLineNumberCount;
			
			foreach( char[] s; Util.splitLines( message ) )
			{
				bool bWarning;
				
				version(FBIDE)
				{
					int lineNumberTail = Util.index( s, ") error" );
					if( lineNumberTail >= s.length )
					{
						lineNumberTail = Util.index( s, ") warning" );
						bWarning = true;
					}
				}
				version(DIDE)
				{
					if( Util.index( s, "warning - " ) == 0 ) bWarning = true;
					int lineNumberTail = Util.index( s, "): " );
				}

				if( lineNumberTail < s.length )
				{
					int lineNumberHead = Util.index( s, "(" );
					if( lineNumberHead < lineNumberTail - 1 )
					{
						char[]	filePath = Path.normalize( s[0..lineNumberHead++] );

						if( quickRunFile.length ) filePath = quickRunFile;
						
						if( filePath == cSci.getFullPath )
						{
							int		lineNumber = Integer.atoi( s[lineNumberHead..lineNumberTail] ) - 1;

							char[]	annotationText = s[lineNumberTail+2..length];
							
							if( lineNumber != prevLineNumber )
							{
								prevLineNumber = lineNumber;
								prevLineNumberCount = 1;
								annotationText = "[" ~ Integer.toString( prevLineNumberCount ) ~ "]" ~ annotationText;
								prevLineNumberCount ++;
							}
							else
							{
								annotationText = "[" ~ Integer.toString( prevLineNumberCount ) ~ "]" ~ annotationText;
								prevLineNumberCount ++;
							}
							
							char[]	getText = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", lineNumber ) );
							if( getText.length ) annotationText = getText ~ "\n" ~ annotationText;
							IupSetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", lineNumber, toStringz( annotationText ) );
							if( bWarning ) IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", lineNumber, 41 ); else IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", lineNumber, 40 );
							IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
							//IupScintillaSendMessage( cSci.getIupScintilla, 2548, 3, 0 );
						}
					}
				}
			}
		}
	}
	
	public:
	static char[]		quickRunFile;

	static char[] getCustomCompilerOption()
	{
		if( GLOBAL.currentCustomCompilerOption.toDString.length )
		{
			foreach( char[] s; GLOBAL.customCompilerOptions )
			{
				int pos = Util.rindex( s, "%::% " );
				if( pos < s.length )
				{
					if( s[pos+5..$] == GLOBAL.currentCustomCompilerOption.toDString ) return s[0..pos];
				}			
			}
		}
		
		return null;
	}
	
	static bool compile( char[] options = null, char[] optionDebug = null )
	{
		quickRunFile ="";
		
		GLOBAL.messagePanel.printOutputPanel( "", true );
		
		char[] command;
		auto cSci = ScintillaAction.getActiveCScintilla();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		if( cSci !is null )
		{
			char[] fbcFullPath = ( GLOBAL.toolbar.checkBitButtonStatus == 32 ? GLOBAL.compilerFullPath.toDString : GLOBAL.x64compilerFullPath.toDString );
			version(Windows)
			{
				foreach( char[] s; GLOBAL.EnvironmentVars.keys )
				{
					fbcFullPath = Util.substitute( lowerCase( fbcFullPath ), lowerCase( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
				}
			}
			else
			{
				fbcFullPath = GLOBAL.compilerFullPath.toDString;
			}
			
			scope compilePath = new FilePath( fbcFullPath );
			if( !compilePath.exists() )
			{
				GLOBAL.messagePanel.printOutputPanel( "Compiler isn't existed......?\n\nCompiler Path Error!", true );
				return false;
			}

			if( !ScintillaAction.saveFile( cSci ) )
			{
				GLOBAL.messagePanel.printOutputPanel( "Compile Cancel By User.\n\nCompile Cancel!", true );
				return false;
			}

			if( !options.length ) options = getCustomCompilerOption();
			cSci = ScintillaAction.getActiveCScintilla();
			version(FBIDE) command = "\"" ~ compilePath.toString ~ "\" -b \"" ~ cSci.getFullPath() ~ "\"" ~ ( options.length ? " " ~ options : null );
			version(DIDE) command = "\"" ~ compilePath.toString ~ "\" " ~ ( GLOBAL.toolbar.checkBitButtonStatus != 32 ? "-m64 " : "" ) ~ "\"" ~ cSci.getFullPath() ~ "\"" ~ ( options.length ? " " ~ options : null );
		}
		else
		{
			GLOBAL.messagePanel.printOutputPanel( "Without any source file has been selected......?\n\nCompile Error!", true );
			return false;
		}

		try
		{
			command = command ~ ( optionDebug.length ? " " ~ optionDebug : "" );
			
			version(FBIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) command ~= " -s gui";
			version(DIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) command ~= " -L/SUBSYSTEM:windows:4";
			
			// Compiler Command
			GLOBAL.messagePanel.printOutputPanel( "Compile File: " ~ cSci.getFullPath() ~ "......\n\n" ~ command ~ "\n", true );
			scope _filePath = new FilePath( cSci.getFullPath() );

			auto _compileThread = new CompileThread( _filePath.path.dup, command );
			_compileThread.start();
			if( GLOBAL.toggleCompileAtBackThread != "ON" ) _compileThread.join();

			if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);

		   return false;
		}

		return false;
	}
	
	static bool build( char[] options = null, char[] optionDebug = null )
	{
		quickRunFile ="";
		
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );

		try
		{
			// Clean outputPanel
			GLOBAL.messagePanel.printOutputPanel( "", true );
			
			if( !activePrjName.length )
			{
				GLOBAL.messagePanel.printOutputPanel( "No Project has been selected......?\n\nBuild Error!", true );
				if( GLOBAL.compilerSFX == "ON" )
				{
					version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); else IupExecute( "aplay", "settings/sound/error.wav" );
				}				
				return false;
			}
			
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
			
			
			char[] fbcFullPath = _focus.Compiler.length ?  _focus.Compiler : ( GLOBAL.toolbar.checkBitButtonStatus == 32 ? GLOBAL.compilerFullPath.toDString : GLOBAL.x64compilerFullPath.toDString );
			version(Windows)
			{
				foreach( char[] s; GLOBAL.EnvironmentVars.keys )
				{
					fbcFullPath = Util.substitute( lowerCase( fbcFullPath ), lowerCase( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
				}				
			}
			else
			{
				fbcFullPath = GLOBAL.compilerFullPath.toDString;
			}
			
			scope compilePath = new FilePath( fbcFullPath );
			
			if( !compilePath.exists() )
			{
				GLOBAL.messagePanel.printOutputPanel( "Compiler isn't existed......?\n\nCompiler Path Error!", true );
				if( GLOBAL.compilerSFX == "ON" )
				{
					version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); else IupExecute( "aplay", "settings/sound/error.wav" );
				}
				return false;
			}
			
			version(FBIDE)
			{
				if( !GLOBAL.projectManager[activePrjName].mainFile.length )
				{
					GLOBAL.messagePanel.printOutputPanel( "Please Set Main File Without Extension, The Entry Point.( -m option )", true );
					if( GLOBAL.compilerSFX == "ON" )
					{
						version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); else IupExecute( "aplay", "settings/sound/error.wav" );
					}
					return false;
				}
				else
				{
					if( GLOBAL.projectManager[activePrjName].passOneFile == "ON" ) return buildAll( options, optionDebug );
				}
			}


			char[] txtCommand, txtSources, txtIncludeDirs, txtLibDirs;
			
			foreach( char[] s; GLOBAL.projectManager[activePrjName].includes )
			{
				if( upperCase(s) in GLOBAL.scintillaManager )
				{
					if( ScintillaAction.getModifyByTitle( GLOBAL.scintillaManager[upperCase(s)] ) ) GLOBAL.scintillaManager[upperCase(s)].saveFile();
					GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[upperCase(s)] ); //Update Parser
				}
			}

			foreach( char[] s; GLOBAL.projectManager[activePrjName].sources )
			{
				if( upperCase(s) in GLOBAL.scintillaManager )
				{
					if( ScintillaAction.getModifyByTitle( GLOBAL.scintillaManager[upperCase(s)] ) ) GLOBAL.scintillaManager[upperCase(s)].saveFile();
					GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[upperCase(s)] ); //Update Parser
				}
				
				version(FBIDE)
				{
					scope fPath = new FilePath( s );
					scope oPath = new FilePath( fPath.path ~ fPath.name ~ ".o" );
					if( oPath.exists() )
					{
						if( fPath.modified > oPath.modified ) txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
					}
					else
					{
						txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
					}
				}
				version(DIDE)
				{
					scope fPath = new FilePath( s );
					
					char[]		objPath = GLOBAL.projectManager[activePrjName].dir ~ "/";
					char[] 		_totalOptions = _focus.Option ~ " " ~ options;
					FilePath	oPath;
					
					int ofPos = Util.index( _totalOptions, "-od" );
					if( ofPos < _totalOptions.length )
					{
						char[] outputName;
						for( int i = ofPos + 3; i < _totalOptions.length; ++ i )
						{
							if( _totalOptions[i] == '\t' || _totalOptions[i] == ' ' ) break;
							outputName ~= _totalOptions[i];
						}
						
						// Got Obj Path -od
						if( outputName.length ) objPath ~= ( outputName ~ "/" );
					}

					version(Windows) oPath = new FilePath( objPath ~ fPath.name ~ ".obj" ); else oPath = new FilePath( objPath ~ fPath.name ~ ".o" );
					if( oPath.exists() )
					{
						if( fPath.modified > oPath.modified ) txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
					}
					else
					{
						txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
					}
					
					delete oPath;
				}
			}

			// Set Include( Import ) Path......
			version(FBIDE)
			{
				foreach( char[] s; _focus.IncDir )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -i \"" ~ s ~ "\"";
				}
			}			
			version(DIDE)
			{
				foreach( char[] s; _focus.IncDir )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -I\"" ~ s ~ "\"";
				}
			}


			if( !txtSources.length )
			{
				if( !GLOBAL.projectManager[activePrjName].sources.length )
				{
					GLOBAL.messagePanel.printOutputPanel( "Without source files......?\n\nBuild Error!", true );
					if( GLOBAL.compilerSFX == "ON" )
					{
						version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); else IupExecute( "aplay", "settings/sound/error.wav" );
					}					
					return false;
				}
				else
				{
					GLOBAL.messagePanel.printOutputPanel( "Buinding Project: " ~ GLOBAL.projectManager[activePrjName].name ~ "......\n\nDirectly Link Objs......", true );
				}
			}

			char[] executeName, _targetName;

			if( _focus.Target.length ) _targetName = _focus.Target; else _targetName = GLOBAL.projectManager[activePrjName].name;
			version(Windows)
			{
				switch( GLOBAL.projectManager[activePrjName].type )
				{
					case "2":
						executeName = " -lib -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						break;
					case "3":
						executeName = " -dll -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".dll\"";
						break;
					default:
						version(FBIDE)	executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".exe\"";
						version(DIDE)	executeName = " -of\"" ~ _targetName ~ "\"";
				}
			}
			else
			{
				switch( GLOBAL.projectManager[activePrjName].type )
				{
					case "2":
						executeName = " -lib -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						break;
					case "3":
						executeName = " -dll -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".so\"";
						break;
					default:
						version(FBIDE)	executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ "\"";
						version(DIDE)	executeName = " -of\"" ~ _targetName ~ "\"";
						
				}
			}

			if( !options.length )
			{
				if( !_focus.Option.length ) options = getCustomCompilerOption();
			}


			// Compiler Command
			if( txtSources.length )
			{
				GLOBAL.messagePanel.printOutputPanel( "Buinding Project: " ~ GLOBAL.projectManager[activePrjName].name ~ "......\n\n" ~ txtCommand ~ "\n", true );
				
				version(FBIDE)
				{
					txtCommand = "\"" ~ compilePath.toString ~ "\" -c" ~ ( GLOBAL.projectManager[activePrjName].mainFile.length ? ( " -m \"" ~ GLOBAL.projectManager[activePrjName].mainFile ) ~ "\"" : "" ) ~ txtSources ~ ( _focus.Option.length ? " " ~ _focus.Option : "" ) ~ ( options.length ? " " ~ options : "" ) ~ ( optionDebug.length ? " " ~ optionDebug : "" ) ~ txtIncludeDirs;
				}
				version(DIDE)
				{
					txtCommand = "\"" ~ compilePath.toString ~ "\" -c" ~ ( GLOBAL.toolbar.checkBitButtonStatus != 32 ? " -m64" : "" ) ~ txtSources ~ ( _focus.Option.length ? " " ~ _focus.Option: "" ) ~ ( options.length ? " " ~ options : "" ) ~ txtIncludeDirs;
				}
			}
			
			// Compiler Command
			GLOBAL.messagePanel.printOutputPanel( "Buinding Project: " ~ GLOBAL.projectManager[activePrjName].name ~ "......\n\n" ~ txtCommand ~ "\n", true );			
			
			// Start Thread this( PROJECT _prj, char[] _command, char[] _extraOptions, char[] _optionDebug, char[] _compilePath, char[] _executeName )
			auto _buildThread = new BuildThread( GLOBAL.projectManager[activePrjName], txtCommand, options, optionDebug, compilePath.toString, executeName );
			_buildThread.start();
			if( GLOBAL.toggleCompileAtBackThread != "ON" ) _buildThread.join();

			if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );
			
			return true;
		}
		catch( Exception e )
		{
			IupMessage( "",toStringz( e.toString ) );
			return false;
		}

		return true;
	}	
	
	static bool buildAll( char[] options = null, char[] optionDebug = null )
	{
		quickRunFile ="";
		
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );

		try
		{
			// Clean outputPanel
			GLOBAL.messagePanel.printOutputPanel( "", true );
			
			if( !activePrjName.length )
			{
				GLOBAL.messagePanel.printOutputPanel( "No Project has been selected......?\n\nBuild Error!", true );
				return false;
			}
			
			
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
			
			
			char[] fbcFullPath = _focus.Compiler.length ? _focus.Compiler : ( GLOBAL.toolbar.checkBitButtonStatus == 32 ? GLOBAL.compilerFullPath.toDString : GLOBAL.x64compilerFullPath.toDString );
			version(Windows)
			{
				foreach( char[] s; GLOBAL.EnvironmentVars.keys )
				{
					fbcFullPath = Util.substitute( lowerCase( fbcFullPath ), lowerCase( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
				}				
			}
			else
			{
				fbcFullPath = GLOBAL.compilerFullPath.toDString;
			}
			
			scope compilePath = new FilePath( fbcFullPath );
			
			if( !compilePath.exists() )
			{
				GLOBAL.messagePanel.printOutputPanel( "Compiler isn't existed......?\n\nCompiler Path Error!", true );
				return false;
			}			


			char[] txtCommand, txtSources, txtIncludeDirs, txtLibDirs;
			
			foreach( char[] s; GLOBAL.projectManager[activePrjName].includes )
			{
				if( upperCase(s) in GLOBAL.scintillaManager )
				{
					if( ScintillaAction.getModifyByTitle( GLOBAL.scintillaManager[upperCase(s)] ) ) GLOBAL.scintillaManager[upperCase(s)].saveFile();
					GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[upperCase(s)] ); //Update Parser
				}
			}

			bool bGotOneFileBuildSuccess;
			foreach( char[] s; GLOBAL.projectManager[activePrjName].sources )
			{
				version(FBIDE)	txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
				version(DIDE)	txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
				if( upperCase(s) in GLOBAL.scintillaManager )
				{
					if( ScintillaAction.getModifyByTitle( GLOBAL.scintillaManager[upperCase(s)] ) ) GLOBAL.scintillaManager[upperCase(s)].saveFile();
					GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[upperCase(s)] ); //Update Parser
				}
			}
			
			version(FBIDE)
			{
				if( GLOBAL.projectManager[activePrjName].passOneFile == "ON" )
				{
					if( GLOBAL.projectManager[activePrjName].mainFile.length )
					{
						scope mainFilePath = new FilePath( GLOBAL.projectManager[activePrjName].mainFile );
						mainFilePath.standard();
					
						foreach( char[] s; GLOBAL.projectManager[activePrjName].sources )
						{
							if( s.length > 4 )
							{
								if( lowerCase( s[$-3..$] ) == "bas" )
								{
									if( mainFilePath.isAbsolute() )
									{
										if( lowerCase( s[0..$-4] ) == lowerCase( mainFilePath.toString ) )
										{
											txtSources = " -b \"" ~ s ~ "\"";
											bGotOneFileBuildSuccess = true;
											break;
										}
									}
									else
									{
										char[] relativePath = Util.substitute( s[0..$-4], GLOBAL.projectManager[activePrjName].dir ~ "/", "" );
										if( lowerCase( relativePath ) == lowerCase( mainFilePath.toString ) ) 
										{
											txtSources = " -b \"" ~ s ~ "\"";
											bGotOneFileBuildSuccess = true;
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
						if( GLOBAL.compilerSFX == "ON" )
						{
							version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); else IupExecute( "aplay", "settings/sound/error.wav" );
						}
						return false;
					}
				}
			}
			
			

			if( !txtSources.length )
			{
				GLOBAL.messagePanel.printOutputPanel( "Without source files......?\n\nBuild Error!", true );
				return false;
			}

			foreach( char[] s; GLOBAL.projectManager[activePrjName].others )
			{
				txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
			}				

			version(FBIDE)
			{
				foreach( char[] s; _focus.IncDir )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -i \"" ~ s ~ "\"";
				}

				foreach( char[] s; _focus.LibDir )
				{
					txtLibDirs = txtLibDirs ~ " -p \"" ~ s ~ "\"";
				}
			}
			version(DIDE)
			{
				foreach( char[] s; _focus.IncDir )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -I\"" ~ s ~ "\"";
				}
				
				foreach( char[] s; _focus.LibDir )
				{
					if( s.length )
					{
						version(Windows)
						{
							if( s[$-1] != '/' ) s ~= '/';
							s = Util.replace( s.dup, '/', '\\' );

							if( Util.contains( s, ' ' ) )
							{
								wchar[] ws = ( UTF.toString16( s ) ).dup;
								wchar[] shortName;
								shortName.length = ws.length + 1;
								shortName[] = ' ';

								DWORD len = GetShortPathNameW( toString16z( ws ), shortName.ptr, ws.length + 1  );
								if( len > 0 && len <= ws.length )
								{
									s = Util.trim( UTF.toString( shortName[0..len] ) );
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
							
							if( !txtLibDirs.length ) txtLibDirs = " -L-L+" ~ s; else txtLibDirs = txtLibDirs ~ "+" ~ s;
						}
						else
						{
							txtLibDirs = " -L-L\"" ~ s ~ "\"";
						}
					}
				}
			}

			char[] executeName, _targetName;
			
			if( _focus.Target.length ) _targetName = _focus.Target; else _targetName = GLOBAL.projectManager[activePrjName].name;
			version(Windows)
			{
				switch( GLOBAL.projectManager[activePrjName].type )
				{
					case "2":
						executeName = " -lib -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						break;
					case "3":
						executeName = " -dll -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".dll\"";
						break;
					default:
						version(FBIDE)	executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".exe\"";
						version(DIDE)	executeName = " -of\"" ~ _targetName ~ "\"";
				}
			}
			else
			{
				switch( GLOBAL.projectManager[activePrjName].type )
				{
					case "2":
						executeName = " -lib -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ "lib" ~ _targetName ~ ".a\"";
						break;
					case "3":
						executeName = " -dll -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".so\"";
						break;
					default:
						version(FBIDE)	executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ "\"";
						version(DIDE)	executeName = " -of\"" ~ _targetName ~ "\"";
						
				}
			}

			if( !options.length )
			{
				if( !_focus.Option.length ) options = getCustomCompilerOption();
			}

			version(FBIDE)
			{
				txtCommand = "\"" ~ compilePath.toString ~ "\"" ~ executeName ~ ( bGotOneFileBuildSuccess ? "" : ( GLOBAL.projectManager[activePrjName].mainFile.length ? ( " -m \"" ~ GLOBAL.projectManager[activePrjName].mainFile ) ~ "\"" : "" ) ) ~
							txtSources ~ txtIncludeDirs ~ txtLibDirs ~ ( _focus.Option.length ? " " ~ _focus.Option : "" ) ~ ( options.length ? " " ~ options : "" ) ~ ( optionDebug.length ? " " ~ optionDebug : "" );
			}
			version(DIDE)
			{
				txtCommand = "\"" ~ compilePath.toString ~ "\"" ~ executeName ~ ( GLOBAL.toolbar.checkBitButtonStatus != 32 ? " -m64" : "" ) ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ ( _focus.Option.length ? " " ~
							_focus.Option : "" ) ~ ( options.length ? " " ~ options : "" );
			}
			
			version(FBIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) txtCommand ~= " -s gui";
			version(DIDE)	if( GLOBAL.toolbar.checkGuiButtonStatus ) txtCommand ~= " -L/SUBSYSTEM:windows:4";

			
			// Using Thread
			GLOBAL.messagePanel.printOutputPanel( "Buinding Project: " ~ GLOBAL.projectManager[activePrjName].name ~ "......\n\n" ~ txtCommand ~ "\n", true );

			// Create Dir for Target
			scope fp = new FilePath( GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName );
			fp.set( fp.path );
			if( !fp.exists ) fp.create;
			
			// Start Thread
			auto _reBuildThread = new ReBuildThread( GLOBAL.projectManager[activePrjName], txtCommand, options );
			_reBuildThread.start();
			if( GLOBAL.toggleCompileAtBackThread != "ON" ) _reBuildThread.join();

			if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );

			return true;
		}
		catch( Exception e )
		{
			IupMessage( "",toStringz( e.toString ) );
			return false;
		}

		return true;
	}

	static bool quickRun( char[] options = null, char[] args = null )
	{
		quickRunFile = "";
		
		GLOBAL.messagePanel.printOutputPanel( "", true );

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		char[] fbcFullPath = ( GLOBAL.toolbar.checkBitButtonStatus == 32 ? GLOBAL.compilerFullPath.toDString : GLOBAL.x64compilerFullPath.toDString );
		version(Windows)
		{
			foreach( char[] s; GLOBAL.EnvironmentVars.keys )
			{
				fbcFullPath = Util.substitute( lowerCase( fbcFullPath ), lowerCase( "%"~s~"%" ), GLOBAL.EnvironmentVars[s] );
			}
		}
		else
		{
			fbcFullPath = GLOBAL.compilerFullPath.toDString;
		}

		scope compilePath = new FilePath( fbcFullPath );
		if( !compilePath.exists() )
		{
			//IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "FBC Compiler isn't existed......?\n\nCompiler Path Error!" ) );
			GLOBAL.messagePanel.printOutputPanel( "Compiler isn't existed......?\n\nCompiler Path Error!", true );
			return false;
		}
		
		char[] fileName;
		auto cSci = ScintillaAction.getActiveCScintilla();
		
		if( cSci !is null )
		{
			scope _f = new FilePath( cSci.getFullPath() );
			scope time = Clock.now.unix;
			
			version(FBIDE) fileName = _f.path() ~ Integer.toString( time.seconds ) ~ ".bas";
			version(DIDE) fileName = _f.path() ~ Integer.toString( time.seconds ) ~ ".d";
			
			FileAction.saveFile( fileName, cSci.getText(), cSci.encoding ); // Create a file with UTF8 With Bom
		}
		else
		{
			//IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without any source file has been selected......?\n\nBuild Error!" ) );
			GLOBAL.messagePanel.printOutputPanel( "Without any source file has been selected......?\n\nBuild Error!", true );
			return false;
		}
		
		try
		{
			if( !options.length ) options = getCustomCompilerOption();
			version(FBIDE)
			{
				char[] commandString = "\"" ~ compilePath.toString ~ "\" " ~ "\"" ~ fileName ~ "\"" ~ ( options.length ? " " ~ options : null );
				if( GLOBAL.toolbar.checkGuiButtonStatus ) commandString ~= " -s gui";
			}
			version(DIDE)
			{
				char[] commandString = "\"" ~ compilePath.toString ~ "\" " ~ ( GLOBAL.toolbar.checkBitButtonStatus != 32 ? "-m64 " : "" ) ~ "\"" ~ fileName ~ "\"" ~ ( options.length ? " " ~ options : null );
				if( GLOBAL.toolbar.checkGuiButtonStatus ) commandString ~= " -L/SUBSYSTEM:windows:4";
			}
			
			scope _filePath = new FilePath( cSci.getFullPath() );
			
			Process p = new Process( true, commandString );
			p.gui( true );
			p.workDir( _filePath.path() );
			p.execute;

			char[]	stdoutMessage, stderrMessage;
			bool	bError, bWarning;
			// Compiler Command
			GLOBAL.messagePanel.printOutputPanel( "Quick Run......\n\n" ~ commandString ~ "\n", true );

			version(FBIDE)
			{
				foreach (line; new Lines!(char)(p.stderr))  
				{
					if( !bWarning )
					{
						if( Util.index( line, "warning:" ) < line.length )
						{
							bWarning = true;
							stderrMessage ~= ( line ~ "\n" );
							continue;
						}
					}
					
					if( !bError )
					{
						if( line.length ) bError = true;
					}				

					stderrMessage ~= ( line ~ "\n" );
				}
				
				foreach( line; new Lines!(char)(p.stdout) )
				{
					if( !bWarning )
					{
						if( Util.index( line, "warning " ) < line.length ) bWarning = true;
					}
					if( !bError )
					{
						if( Util.index( line, "error " ) < line.length ) bError = true;
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
				}
			}
			version(DIDE)
			{
				foreach (line; new Lines!(char)(p.stderr))  
				{
					if( Util.trim( line ).length ) bError = true;
					stderrMessage ~= ( line ~ "\n" );
				}
				
				foreach (line; new Lines!(char)(p.stdout))  
				{
					if( !bError )
					{
						if( Util.index( line, "): " ) < line.length )
							bError = true;
						else if( Util.index( line, "Error " ) < line.length )
							bError = true;						
					}

					stdoutMessage ~= ( line ~ "\n" );
				}
			}

			auto result = p.wait;

			// Set quickRunFile to active document fullpath
			quickRunFile = cSci.getFullPath;
			
			version(FBIDE)
			{
				if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
				if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length ) GLOBAL.messagePanel.printOutputPanel( stdoutMessage ~ stderrMessage ); //IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );
			}
			version(DIDE)
			{
				if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length )
				{
					GLOBAL.messagePanel.printOutputPanel( stdoutMessage ~ stderrMessage );
					showAnnotation( stdoutMessage ~ stderrMessage );
				}
				else
					showAnnotation( null );
			}
			GLOBAL.messagePanel.applyOutputPanelINDICATOR();

			if( !bError )
			{
				if( !bWarning )
				{
					GLOBAL.messagePanel.printOutputPanel( "Compile Success!" );
					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/success.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/success.wav" );
						}							
					}					
				}
				else
				{
					GLOBAL.messagePanel.printOutputPanel( "Compile Success! But got warning..." );
					if( GLOBAL.compilerWindow == "ON" )
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
							if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/warning.wav", null, 0x0001 );
						}
						else
						{
							if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/warning.wav" );
						}							
					}					
				}

				char[] command;
				scope _f = new FilePath( fileName );
				version( Windows ) command = _f.path ~ _f.name ~ ".exe"; else command = _f.path ~ "./" ~ _f.name;
				_f.remove();
				
				if( args.length ) args = " " ~ args; else args = "";
				
				ExecuterThread derived = new ExecuterThread( "\"" ~ command ~ "\"", args, _f.path, true );
				derived.start();

				GLOBAL.messagePanel.printOutputPanel( "\nRunning " ~ command ~ args ~ "......" );
			}
			else
			{
				GLOBAL.messagePanel.printOutputPanel( "Compile Error!" );

				if( GLOBAL.compilerWindow == "ON" )
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
						if( GLOBAL.compilerSFX == "ON" ) PlaySound( "settings/sound/error.wav", null, 0x0001 );
					}
					else
					{
						if( GLOBAL.compilerSFX == "ON" ) IupExecute( "aplay", "settings/sound/error.wav" );
					}							
				}
				
				scope _f = new FilePath( fileName );
				_f.remove();				
			}

			if( ScintillaAction.getActiveIupScintilla != null ) IupSetFocus( ScintillaAction.getActiveIupScintilla );

			return true;
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);

		   return false;
		}
	}

	static bool run( char[] args = null, bool bForceCompileOne = false )
	{
		bool	bRunProject;
		char[]	command;
		char[]	activePrjName	= actionManager.ProjectAction.getActiveProjectName();
		
		// Set Multiple Focus Project
		FocusUnit _focus;
		
		if( activePrjName.length )
		{
			_focus.Target = GLOBAL.projectManager[activePrjName].targetName;
			if( GLOBAL.projectManager[activePrjName].focusOn.length )
			{
				if( GLOBAL.projectManager[activePrjName].focusOn in GLOBAL.projectManager[activePrjName].focusUnit ) _focus = GLOBAL.projectManager[activePrjName].focusUnit[GLOBAL.projectManager[activePrjName].focusOn];
			}
		}

		auto activeCScintilla = actionManager.ScintillaAction.getActiveCScintilla();
		if( activeCScintilla !is null )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
			IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
			
			if( !bForceCompileOne )
			{
				int nodeCount = IupGetInt( GLOBAL.projectTree.getTreeHandle, "COUNT" );
				for( int id = 1; id <= nodeCount; id++ )
				{
					char[] _cstring = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ); //fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ); // shadow
					if( _cstring == activeCScintilla.getFullPath() )
					{
						version(Windows) IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" ); else IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );
						bRunProject = true;

						if( GLOBAL.projectManager[activePrjName].type.length )
						{
							if( GLOBAL.projectManager[activePrjName].type != "1" )
							{
								GLOBAL.messagePanel.printOutputPanel( "Can't Run Static / Dynamic Library............Run Error!", true );
								return false;
							}
						}
						
						version(Windows)
						{
							if( _focus.Target.length )
								command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _focus.Target ~ ".exe";
							else
								command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe";
						}
						else
						{
							if( _focus.Target.length )
								command = GLOBAL.projectManager[activePrjName].dir ~ "/./" ~ _focus.Target;
							else
								command = GLOBAL.projectManager[activePrjName].dir ~ "/./" ~ GLOBAL.projectManager[activePrjName].name;
						}
						break;
					}
				}
			}
			else
			{
				bRunProject = false;
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
					command = _f.path ~ "./" ~ _f.name;
				}
			}
		}
		else
		{
			if( activePrjName.length )
			{
				version(Windows)
				{
					if( _focus.Target.length )
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _focus.Target ~ ".exe";
					else
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe";
				}
				else
				{
					if( _focus.Target.length )
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _focus.Target;
					else
						command = GLOBAL.projectManager[activePrjName].dir ~ "/" ~ GLOBAL.projectManager[activePrjName].name;
				}
			}
		}

		GLOBAL.messagePanel.printOutputPanel( "", true );
		
		scope f = new FilePath( command );
		if( f.exists() )
		{
			if( args.length ) args = " " ~ args; else args = "";
			
			GLOBAL.messagePanel.printOutputPanel( "Running " ~ command ~ args ~ "......", true );

			ExecuterThread derived;
			version(Windows) derived = new ExecuterThread( "\"" ~ command ~ "\"", args, f.path ); else derived = new ExecuterThread( "\"" ~ command ~ "\"", args, f.path );
			derived.start();
		}
		else
		{
			GLOBAL.messagePanel.printOutputPanel( "Execute file: " ~ command ~ "\nisn't exist......?\n\nRun Error!", true );
			return false;
		}

		return true;
	}
}