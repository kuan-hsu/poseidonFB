module executer;

struct ExecuterAction
{
	private:
	import iup.iup;

	import global, actionManager, menu;

	import tango.sys.Process, tango.core.Exception, tango.io.stream.Lines, tango.io.stream.Iterator;
	import tango.io.Stdout, tango.stdc.stringz, tango.stdc.stdlib, tango.io.FilePath, Util = tango.text.Util;

	import tango.core.Thread;
	
	// Inner Class
	class ExecuterThread : Thread
	{
		private :
		char[] command;

		public:
		this( char[] _command )
		{
			command = _command;
			super( &run );
		}

		~this()
		{
			//IupMessage("","BYE");
			//Stdout("BYE BYE").newline;
		}

		void run()
		{
			system( GLOBAL.cString.convert( command ) );
		}
	}
	
	public:
	static bool compile()
	{
		IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
		
		char[] command;
		auto cSci = ScintillaAction.getActiveCScintilla();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		if( cSci !is null )
		{
			ScintillaAction.saveFile( cSci.getIupScintilla() );
			command = "\"" ~ GLOBAL.compilerFullPath ~ "\" -c \"" ~ cSci.getFullPath() ~ "\"";
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without any source file has been selected......?\n\nCompile Error!" ) );
			return false;
		}

		try
		{
			Process p = new Process( command, null );
			p.execute;

			char[] outputResult;

			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( command ) );
			
			foreach (line; new Lines!(char)(p.stdout))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( line ) );
				outputResult ~= line;
			}

			foreach (line; new Lines!(char)(p.stderr))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( line ) );
				outputResult ~= line;
			}			

			auto result = p.wait;
			
			IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" ); // Back to top of outputPanel

			if( !outputResult.length )
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Compile Success!" ) );
			}

			return true;
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);

		   return false;
		}
	}
	
	static bool buildAll()
	{
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );

		try
		{
			// Clean outputPanel
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") );

			if( !activePrjName.length )
			{
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert("No Project has been selected......?\n\nBuild Error!") );
				return false;
			}
			else
			{
				char[] txtCommand, txtSources, txtIncludeDirs, txtLibDirs;
				
				foreach( char[] s; GLOBAL.projectManager[activePrjName].sources )
				{
					txtSources = txtSources ~ " -b \"" ~ s ~ "\"" ;
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

				txtCommand = "\"" ~ GLOBAL.compilerFullPath ~ "\"" ~  executeName ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption;

				Process p = new Process( txtCommand, null );
				p.execute;

				bool	bError, bWarning;
				char[] 	outputResult;

				// Compiler Command
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( txtCommand ) );
				
				foreach (line; new Lines!(char)(p.stdout))  
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( line ) );
					outputResult ~= line;

					if( !bError )
					{
						if( Util.index( line, ") error " ) < line.length ) bError = true;
					}

					if( !bWarning )
					{
						if( Util.index( line, ") warning " ) < line.length ) bWarning = true;
					}					
				}

				foreach (line; new Lines!(char)(p.stderr))  
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( line ) );
					if( Util.trim( line ).length ) bError = true;
					outputResult ~= line;
				}				
				auto result = p.wait;

				IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" );

				if( !outputResult.length || !bError )
				{
					if( !bWarning )
						IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert("Build Success!" ) );
					else
						IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success! But got warning..." ) );
				}
				else
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Error!" ) );
				}
			}

			return true;
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);
		   return false;
		}

		return true;
	}

	static bool quickRun()
	{
		IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel

		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) message_cb( GLOBAL.menuMessageWindow );
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "0" );
		
		char[] fileName;
		auto cSci = ScintillaAction.getActiveCScintilla();
		
		if( cSci !is null )
		{
			ScintillaAction.saveFile( cSci.getIupScintilla() );
			fileName = cSci.getFullPath();
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Without any source file has been selected......?\n\nBuild Error!" ) );
			return false;
		}
		
		try
		{
			char[] commandString;
			version( Windows )
			{
				commandString = "\"" ~ GLOBAL.compilerFullPath ~ "\" " ~ "\"" ~ fileName ~ "\"";
			}
			else
			{
				commandString = "\"" ~ GLOBAL.compilerFullPath ~ "\" " ~ "\"" ~ fileName ~ "\"";
				//commandString = "/bin/sh -c " ~ GLOBAL.compilerFullPath ~ " \"" ~ fileName ~ "\"" ~ "\n";
			}


			//Process p = new Process( commandString, null );
			Process p = new Process( commandString, null );
			p.execute;

			bool	bError, bWarning;
			char[]	outputResult;

			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( commandString ) );

			foreach (line; new Lines!(char)(p.stdout))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND",  GLOBAL.cString.convert( line ) );
				outputResult ~= line;

				if( !bError )
				{
					if( Util.index( line, ") error " ) < line.length ) bError = true;
				}

				if( !bWarning )
				{
					if( Util.index( line, ") warning " ) < line.length ) bWarning = true;
				}				
			}

			foreach (line; new Lines!(char)(p.stderr))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( line ) );
				if( Util.trim( line ).length ) bError = true;
				outputResult ~= line;
			}

			auto result = p.wait;
			

			//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(outputResult) );
			// Back to top of outputPanel
			IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" );

			if( !outputResult.length || !bError )
			{
				if( !bWarning )
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success!" ) );
				else
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Success! But got warning..." ) );

				char[] command;
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
				
				auto derived = new ExecuterThread( command );
				derived.start();
				
			}
			else
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Build Error!" ) );
			}
			

			/*
			Stdout.formatln ("Process '{}' ({}) exited with reason {}, status {}",
							 p.programName, p.pid, cast(int) result.reason, result.status);
			*/

			return true;
		}
		catch( ProcessException e )
		{
		  // Stdout.formatln ("Process execution failed: {}", e);

		   return false;
		}
	}

	static bool run()
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
				char[] _cstring = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
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
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "Running " ~ command ~ "......" ) );

			/+
			Process exe = new Process(  "cmd.exe /k " ~ fullPath , null );
			exe.execute;
			+/
			auto derived = new ExecuterThread( command );
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



