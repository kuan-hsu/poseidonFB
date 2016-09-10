module executer;

struct ExecuterAction
{
	private:
	import iup.iup;//, iup.iup_scintilla;

	import global, actionManager, menu, tools, scintilla;

	import tango.sys.Process, tango.core.Exception, tango.io.stream.Lines, tango.io.stream.Iterator;
	import tango.io.Stdout, tango.stdc.stringz, Util = tango.text.Util, Integer = tango.text.convert.Integer;
	import tango.io.FilePath;

	import tango.core.Thread;
	import tango.time.Time, tango.time.Clock;

	// Inner Class
	class ExecuterThread : Thread
	{
		private :
		char[] command, cwd;

		public:
		this( char[] _command, char[] _cwd = null )
		{
			command = _command;
			cwd = _cwd;
			super( &run );
		}

		void run()
		{
			Process p = new Process( true, command );
			if( cwd.length ) p.workDir( cwd );
			//p.redirect( Redirect.None );
			p.execute;
			
			p.wait;
		}
	}

	class QuickRunThread : Thread
	{
		private:
		char[] command, args, cwd, options;

		public:
		this( char[] _command, char[] _args, char[] _cwd = null, char[] _options = null )
		{
			command = _command;
			args = _args;
			cwd = _cwd;
			options = _options;
			super( &run );
		}

		void run()
		{
			Process p;
			version( Windows )
			{
				p = new Process( true, command ~ args );
			}
			else
			{
				if( Util.index( options, "-s gui" ) < options.length ) p = new Process( true, command ~ args ); else p = new Process( true, GLOBAL.linuxTermName ~ " -e " ~ command ~ args );
			}

			if( cwd.length ) p.workDir( cwd );
			//p.redirect( Redirect.None );
			p.execute;
			
			auto result = p.wait;
			
			switch( result.reason )
			{
				case Process.Result.Exit, Process.Result.Signal, Process.Result.Stop, Process.Result.Error:
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

	static void showAnnotation( char[] message )
	{
		if( GLOBAL.compilerAnootation != "ON" ) return;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONCLEARALL", "YES" );
			
			foreach( char[] s; Util.splitLines( message ) )
			{
				bool bWarning;
				int lineNumberTail = Util.index( s, ") error" );
				if( lineNumberTail >= s.length )
				{
					lineNumberTail = Util.index( s, ") warning" );
					bWarning = true;
				}

				if( lineNumberTail < s.length )
				{
					int lineNumberHead = Util.index( s, "(" );
					if( lineNumberHead < lineNumberTail - 1 )
					{
						char[]	filePath = Util.replace( s[0..lineNumberHead++], '\\', '/' );
						if( filePath == cSci.getFullPath )
						{
							int		lineNumber = Integer.atoi( s[lineNumberHead..lineNumberTail] ) - 1;

							char[]	annotationText = s[lineNumberTail+2..length];
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
	static bool compile( char[] options = null, char[] optionDebug = null )
	{
		IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
		
		char[] command;
		auto cSci = ScintillaAction.getActiveCScintilla();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		if( cSci !is null )
		{
			scope compilePath = new FilePath( GLOBAL.compilerFullPath );
			if( !compilePath.exists() )
			{
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "FBC Compiler isn't existed......?\n\nCompiler Path Error!" ) );
				return false;
			}

			if( !ScintillaAction.saveFile( cSci ) )
			{
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Compile Cancel By User.\n\nCompile Cancel!" ) );
				return false;
			}

			cSci = ScintillaAction.getActiveCScintilla();
			command = "\"" ~ GLOBAL.compilerFullPath ~ "\" -b \"" ~ cSci.getFullPath() ~ "\"" ~ ( options.length ? " " ~ options : null );
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without any source file has been selected......?\n\nCompile Error!" ) );
			return false;
		}

		try
		{
			command = command ~ ( optionDebug.length ? " " ~ optionDebug : "" );
			
			Process p = new Process( true, command );
			p.gui( true );
			p.execute;

			bool	bError, bWarning;
			char[] stdoutMessage, stderrMessage;
			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Compile File: " ~ cSci.getFullPath() ~ "......\n\n" ~ command ~ "\n" ) );

			foreach( line; new Lines!(char)(p.stderr) )  
			{
				if( Util.trim( line ).length ) bError = true;
				stderrMessage ~= ( line ~ "\n" );
			}

			foreach( line; new Lines!(char)(p.stdout) )
			{
				if( !bWarning )
				{
					if( Util.index( line, ") warning " ) < line.length ) bWarning = true;
				}
				if( !bError )
				{
					if( Util.index( line, ") error " ) < line.length ) bError = true;
				}				
				
				stdoutMessage ~= ( line ~ "\n" );
			}

			auto result = p.wait;

			if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
			if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );			
			
			if( bError )
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Error!" ) );

				if( GLOBAL.compilerWindow == "ON" )
				{
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR,TITLE=ERROR,BUTTONDEFAULT=1" );
					IupSetAttribute( messageDlg, "VALUE", toStringz( "Compile Failure!" ) );
					IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
				}
			}
			else
			{
				if( !bWarning )
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success!" ) );

					if( GLOBAL.compilerWindow == "ON" )
					{
						Ihandle* messageDlg = IupMessageDlg();
						IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION,TITLE=Message,BUTTONDEFAULT=1" );
						IupSetAttribute( messageDlg, "VALUE", toStringz( "Compile Success!" ) );
						IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
					}
					
				}
				else
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success! But got warning..." ) );

					if( GLOBAL.compilerWindow == "ON" )
					{
						Ihandle* messageDlg = IupMessageDlg();
						IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=WARNING,BUTTONDEFAULT=1" );
						IupSetAttribute( messageDlg, "VALUE", toStringz( "Compile Done\nBut Got Warnings!" ) );
						IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
					}
				}

				return true;
			}

			IupSetInt( GLOBAL.outputPanel, "SCROLLTOPOS", 0 ); // Back to top of outputPanel

		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);

		   return false;
		}

		return false;
	}
	
	static bool buildAll( char[] optionDebug = null )
	{
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.message_cb( GLOBAL.menuMessageWindow );
		IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );

		try
		{
			// Clean outputPanel
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") );

			scope compilePath = new FilePath( GLOBAL.compilerFullPath );
			if( !compilePath.exists() )
			{
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "FBC Compiler isn't existed......?\n\nCompiler Path Error!" ) );
				return false;
			}			

			if( !activePrjName.length )
			{
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert("No Project has been selected......?\n\nBuild Error!") );
				return false;
			}
			else
			{
				char[] txtCommand, txtSources, txtIncludeDirs, txtLibDirs;
				
				foreach( char[] s; GLOBAL.projectManager[activePrjName].includes )
				{
					if( upperCase(s) in GLOBAL.scintillaManager )
					{
						GLOBAL.scintillaManager[upperCase(s)].saveFile();
						GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[upperCase(s)] ); //Update Parser
					}
				}

				foreach( char[] s; GLOBAL.projectManager[activePrjName].sources )
				{
					txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
					if( upperCase(s) in GLOBAL.scintillaManager )
					{
						GLOBAL.scintillaManager[upperCase(s)].saveFile();
						GLOBAL.outlineTree.refresh( GLOBAL.scintillaManager[upperCase(s)] ); //Update Parser
					}
				}

				if( !txtSources.length )
				{
					IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without source files......?\n\nBuild Error!" ) );
					return false;
				}

				foreach( char[] s; GLOBAL.projectManager[activePrjName].others )
				{
					txtSources = txtSources ~ " \"" ~ s ~ "\"" ;
				}				

				foreach( char[] s; GLOBAL.projectManager[activePrjName].includeDirs )
				{
					txtIncludeDirs = txtIncludeDirs ~ " -i \"" ~ s ~ "\"";
				}

				foreach( char[] s; GLOBAL.projectManager[activePrjName].libDirs )
				{
					txtLibDirs = txtLibDirs ~ " -p \"" ~ s ~ "\"";
				}

				char[] executeName, _targetName;

				if( GLOBAL.projectManager[activePrjName].targetName.length ) _targetName = GLOBAL.projectManager[activePrjName].targetName; else _targetName = GLOBAL.projectManager[activePrjName].name;
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
							executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ ".exe\"";
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
							executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "/" ~ _targetName ~ "\"";
					}
				}

				char[] fbcFullPath = GLOBAL.projectManager[activePrjName].compilerPath.length ? GLOBAL.projectManager[activePrjName].compilerPath : GLOBAL.compilerFullPath;
				txtCommand = "\"" ~ fbcFullPath ~ "\"" ~  executeName ~  ( GLOBAL.projectManager[activePrjName].mainFile.length ? ( " -m \"" ~ GLOBAL.projectManager[activePrjName].mainFile ) ~ "\"" : "" ) ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption ~ ( optionDebug.length ? " " ~ optionDebug : "" );

				Process p = new Process( true, txtCommand );
				p.workDir( GLOBAL.projectManager[activePrjName].dir );
				p.gui( true );
				p.execute;

				bool	bError, bWarning;
				char[] stdoutMessage, stderrMessage;
				// Compiler Command
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Buinding Project: " ~ GLOBAL.projectManager[activePrjName].name ~ "......\n\n" ~ txtCommand ~ "\n" ) );

				foreach (line; new Lines!(char)(p.stderr))  
				{
					if( Util.trim( line ).length ) bError = true;
					stderrMessage ~= ( line ~ "\n" );
				}

				foreach (line; new Lines!(char)(p.stdout))  
				{
					if( !bWarning )
					{
						if( Util.index( line, ") warning " ) < line.length ) bWarning = true;
					}
					if( !bError )
					{
						if( Util.index( line, ") error " ) < line.length )
							bError = true;
						else if( Util.index( line, "Error!" ) < line.length )
							bError = true;
						else if( Util.index( line, "error " ) < line.length )
							bError = true;
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
				}				
		
				auto result = p.wait;

				if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
				if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );			


				if( bError )
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Error!" ) );

					if( GLOBAL.compilerWindow == "ON" )
					{
						Ihandle* messageDlg = IupMessageDlg();
						IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR,TITLE=ERROR,BUTTONDEFAULT=1" );
						IupSetAttribute( messageDlg, "VALUE", toStringz( "Build Failure!" ) );
						IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
					}
				}
				else
				{
					if( !bWarning )
					{
						IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert("Build Success!" ) );

						if( GLOBAL.compilerWindow == "ON" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION,TITLE=Message,BUTTONDEFAULT=1" );
							IupSetAttribute( messageDlg, "VALUE", toStringz( "Build Success!" ) );
							IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
						}
					}
					else
					{
						IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success! But got warning..." ) );

						if( GLOBAL.compilerWindow == "ON" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=WARNING,BUTTONDEFAULT=1" );
							IupSetAttribute( messageDlg, "VALUE", toStringz( "Build Done\nBut Got Warnings!" ) );
							IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
						}
					}
				}

				IupSetInt( GLOBAL.outputPanel, "SCROLLTOPOS", 0 );
			}

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
		IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );

		scope compilePath = new FilePath( GLOBAL.compilerFullPath );
		if( !compilePath.exists() )
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "FBC Compiler isn't existed......?\n\nCompiler Path Error!" ) );
			return false;
		}
		
		char[] fileName;
		auto cSci = ScintillaAction.getActiveCScintilla();
		
		if( cSci !is null )
		{
			/*
			ScintillaAction.saveFile( cSci.getIupScintilla() );
			fileName = cSci.getFullPath();
			*/
			scope _f = new FilePath( cSci.getFullPath() );
			scope time = Clock.now.unix;
			
			fileName = _f.path() ~ Integer.toString( time.seconds ) ~ ".bas";
			FileAction.saveFile( fileName, cSci.getText() );
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without any source file has been selected......?\n\nBuild Error!" ) );
			return false;
		}
		
		try
		{
			char[] commandString = "\"" ~ GLOBAL.compilerFullPath ~ "\" " ~ "\"" ~ fileName ~ "\"" ~ ( options.length ? " " ~ options : null );
			Process p = new Process( true, commandString );
			p.gui( true );
			p.execute;

			char[]	stdoutMessage, stderrMessage;
			bool	bError, bWarning;
			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Quick Run......\n\n" ~ commandString ~ "\n" ) );

			foreach (line; new Lines!(char)(p.stderr))  
			{
				if( Util.trim( line ).length ) bError = true;
				stderrMessage ~= ( line ~ "\n" );
			}
			
			foreach (line; new Lines!(char)(p.stdout))  
			{
				int openPos = Util.index( line, "(" );
				if( openPos < line.length )
				{
					line = ( cSci.getFullPath() ~ line[openPos..length] ).dup;
				}
				
				stdoutMessage ~= ( line ~ "\n" );

				if( !bError )
				{
					if( Util.index( line, ") error " ) < line.length ) bError = true;
				}

				if( !bWarning )
				{
					if( Util.index( line, ") warning " ) < line.length ) bWarning = true;
				}				
			}

			auto result = p.wait;

			if( Util.trim( stdoutMessage ).length ) showAnnotation( stdoutMessage ); else showAnnotation( null );
			if( Util.trim( stdoutMessage ).length || Util.trim( stderrMessage ).length ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );			

			if( !bError )
			{
				if( !bWarning )
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success!" ) );
				else
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success! But got warning..." ) );

				char[] command;

				scope _f = new FilePath( fileName );
				version( Windows ) command = _f.path ~ _f.name ~ ".exe"; else command = _f.path ~ "./" ~ _f.name;
				_f.remove();

				QuickRunThread	derived = new QuickRunThread( "\"" ~ command ~ "\"", args, _f.path, options );
				derived.start();

				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "\nRunning " ~ command ~ args ~ "......" ) );
				
			}
			else
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Error!" ) );

				if( GLOBAL.compilerWindow == "ON" )
				{
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR,TITLE=ERROR,BUTTONDEFAULT=1" );
					IupSetAttribute( messageDlg, "VALUE", toStringz( "Compile Failure!" ) );
					IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
				}
				
				scope _f = new FilePath( fileName );
				_f.remove();				
			}

			// Back to top of outputPanel
			IupSetInt( GLOBAL.outputPanel, "SCROLLTOPOS", 0 );
		

			return true;
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);

		   return false;
		}
	}

	static bool run( char[] args = null )
	{
		bool	bRunProject;
		char[]	command;
		char[]	activePrjName	= actionManager.ProjectAction.getActiveProjectName();

		auto activeCScintilla = actionManager.ScintillaAction.getActiveCScintilla();
		if( activeCScintilla !is null )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
			IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
			
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
						//IupMessage( "", toStringz(GLOBAL.projectManager[activePrjName].type ) );
						if( GLOBAL.projectManager[activePrjName].type != "1" )
						{
							IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
							IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Can't Run Static / Dynamic Library............Run Error!" ) );
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
						command = GLOBAL.projectManager[activePrjName].dir ~ "/./" ~ GLOBAL.projectManager[activePrjName].name;
					}
					break;
				}
			}

			if( !bRunProject ) 
			{
				scope _f = new FilePath( activeCScintilla.getFullPath() );
				version( Windows )
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
				version( Windows )
				{
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
			if( args.length ) args = " " ~ args; else args = "";
			
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Running " ~ command ~ args ~ "......" ) );

			ExecuterThread derived;
			version( Windows ) derived = new ExecuterThread( "\"" ~ command ~ "\"" ~ args, f.path ); else derived = new ExecuterThread( GLOBAL.linuxTermName ~ " -e " ~ "\"" ~ command ~ "\"" ~ args, f.path );
			derived.start();
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Execute file: " ~ command ~ "\nisn't exist......?\n\nRun Error!" ) );
			return false;
		}

		return true;
	}
}
