module executer;

struct ExecuterAction
{
	private:
	import iup.iup;

	import global, actionManager, menu, tools;

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
			Process p = new Process( command, null );
			if( cwd.length ) p.workDir( cwd );
			p.redirect( Redirect.None );
			p.execute;

			p.wait;
		}
	}

	class QuickRunThread : Thread
	{
		private:
		char[] command, args, cwd;

		public:
		this( char[] _command, char[] _args, char[] _cwd = null )
		{
			command = _command;
			args = _args;
			cwd = _cwd;
			super( &run );
		}

		void run()
		{
			Process p = new Process( command ~ args, null );
			if( cwd.length ) p.workDir( cwd );
			p.redirect( Redirect.None );
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
			
			version( Windows )
			{
				//command = "\"" ~ GLOBAL.compilerFullPath ~ "\" -c \"" ~ cSci.getFullPath() ~ "\"";
				command = "\"" ~ GLOBAL.compilerFullPath ~ "\" -b \"" ~ cSci.getFullPath() ~ "\"" ~ ( options.length ? " " ~ options : null );
			}
			else
			{
				//command = "\"" ~ GLOBAL.compilerFullPath ~ "\" -c \"" ~ cSci.getFullPath() ~ "\"";
				command = "\"" ~ GLOBAL.compilerFullPath ~ "\" -b \"" ~ cSci.getFullPath() ~ "\"" ~ ( options.length ? " " ~ options : null );
			}
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without any source file has been selected......?\n\nCompile Error!" ) );
			return false;
		}

		try
		{
			command = command ~ ( optionDebug.length ? " " ~ optionDebug : "" );
			
			Process p = new Process( command, null );
			p.gui( true );
			p.execute;

			bool	bError, bWarning;
			char[] stdoutMessage, stderrMessage;
			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( command ~ "\n" ) );

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
					if( Util.index( line, ") error " ) < line.length ) bError = true;
				}				
				
				stdoutMessage ~= ( line ~ "\n" );
			}

			auto result = p.wait;

			IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );
			
			if( bError )
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Error!" ) );
			}
			else
			{
				if( !bWarning )
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success!" ) );
				else
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success! But got warning..." ) );

				return true;
			}

			IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" ); // Back to top of outputPanel

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

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );

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
					if( upperCase(s) in GLOBAL.scintillaManager )  GLOBAL.scintillaManager[upperCase(s)].saveFile();
				}

				foreach( char[] s; GLOBAL.projectManager[activePrjName].sources )
				{
					txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
					if( upperCase(s) in GLOBAL.scintillaManager )  GLOBAL.scintillaManager[upperCase(s)].saveFile();
				}

				if( !txtSources.length )
				{
					IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without source files......?\n\nBuild Error!" ) );
					return false;
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

				txtCommand = "\"" ~ GLOBAL.compilerFullPath ~ "\"" ~  executeName ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption ~ ( optionDebug.length ? " " ~ optionDebug : "" );

				Process p = new Process( txtCommand, null );
				p.gui( true );
				p.execute;

				bool	bError, bWarning;
				char[] stdoutMessage, stderrMessage;
				// Compiler Command
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( txtCommand ~ "\n" ) );

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
						if( Util.index( line, ") error " ) < line.length ) bError = true;
					}				
					
					stdoutMessage ~= ( line ~ "\n" );
				}				
		
				auto result = p.wait;

				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );

				if( bError )
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Error!" ) );
				}
				else
				{
					if( !bWarning )
						IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert("Build Success!" ) );
					else
						IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success! But got warning..." ) );
				}

				IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" );
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
			char[] commandString;
			Process p;

			version( Windows )
			{
				commandString = "\"" ~ GLOBAL.compilerFullPath ~ "\" " ~ "\"" ~ fileName ~ "\"" ~ ( options.length ? " " ~ options : null );
				p = new Process( commandString, null );
			}
			else
			{
				commandString = "\"" ~ GLOBAL.compilerFullPath ~ "\" -w 2 " ~ "\"" ~ fileName ~ "\"" ~ ( options.length ? " " ~ options : null );
				//commandString = "/bin/sh -c \"" ~ GLOBAL.compilerFullPath ~ " -b " ~ fileName ~ "\"";
				char[][char[]] env;
				
				//env["PATH"] = "/user/bin/";
				env["PATH"] = "/usr/local/FreeBASIC-1.03.0-linux-x86_64/bin";
				p = new Process( commandString, env );
			}
			p.gui( true );
			p.execute;


			char[]	stdoutMessage, stderrMessage;
			bool	bError, bWarning;
			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( commandString ~ "\n" ) );

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

			IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( stdoutMessage ~ stderrMessage ) );
			if( !bError )
			{
				if( !bWarning )
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success!" ) );
				else
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success! But got warning..." ) );

				char[] command;

				scope _f = new FilePath( fileName );
				_f.remove();
				
				int dotIndex = Util.rindex( fileName, "." );
				if( dotIndex < fileName.length )
				{
					version(Windows)
					{
						command = fileName[0..dotIndex] ~ ".exe";
					}
					else
					{
						command = fileName[0..dotIndex];
					}
				}

				/+
				Process exe = new Process(  "cmd.exe /k " ~ command , null );
				exe.execute;
				+/

				if( args.length ) args = " " ~ args; else args = "";
				
				auto derived = new QuickRunThread( "\"" ~ command ~ "\"", args, _f.path );
				derived.start();

				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "\nRunning " ~ command ~ args ~ "......" ) );
				
			}
			else
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Error!" ) );
				scope _f = new FilePath( fileName );
				_f.remove();				
			}

			// Back to top of outputPanel
			IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" );
		

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
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
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

			/+
			Process exe = new Process(  "cmd.exe /k " ~ fullPath , null );
			exe.execute;
			+/
			auto derived = new ExecuterThread( "\"" ~ command ~ "\"" ~ args, f.path );
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
