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
			system( toStringz( command ) );
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
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("Without any source file has been selected......?\n\nCompile Error!") );
			return false;
		}

		try
		{
			Process p = new Process( command, null );
			p.execute;

			char[] outputResult;

			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz(command) );

			foreach (line; new Lines!(char)(p.stdout))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(line) );
				outputResult ~= line;
			}

			foreach (line; new Lines!(char)(p.stderr))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(line) );
				outputResult ~= line;
			}			

			auto result = p.wait;
			
			IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" ); // Back to top of outputPanel

			if( !outputResult.length ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz("Compile Success!") );

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
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("No Project has been selected......?\n\nBuild Error!") );
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
					IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("Without source files......?\n\nBuild Error!") );
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

				char[] executeName;
				version(Windows)
				{
					executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "\\" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe\"";
				}
				else
				{
					executeName = " -x \"" ~ GLOBAL.projectManager[activePrjName].dir ~ "\\" ~ GLOBAL.projectManager[activePrjName].name ~ "\"";
				}

				txtCommand = "\"" ~ GLOBAL.compilerFullPath ~ "\"" ~  executeName ~ txtSources ~ txtIncludeDirs ~ txtLibDirs ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption;

				Process p = new Process( txtCommand, null );
				p.execute;

				char[] outputResult;

				// Compiler Command
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz(txtCommand) );

				foreach (line; new Lines!(char)(p.stdout))  
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(line) );
					outputResult ~= line;
				}

				foreach (line; new Lines!(char)(p.stderr))  
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(line) );
					outputResult ~= line;
				}				
				auto result = p.wait;

				IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" );

				if( outputResult.length )
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz("Build Error!") );
				}
				else
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz("Build Success!") );
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
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("Without any source file has been selected......?\n\nBuild Error!") );
			return false;
		}
		
		try
		{
			Process p = new Process( "\"" ~ GLOBAL.compilerFullPath ~ "\" \"" ~ fileName ~ "\"", null );
			p.execute;

			char[] outputResult;

			// Compiler Command
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz(GLOBAL.compilerFullPath ~ " \"" ~ fileName ~ "\"") );

			foreach (line; new Lines!(char)(p.stdout))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(line) );
				outputResult ~= line;
			}

			foreach (line; new Lines!(char)(p.stderr))  
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(line) );
				outputResult ~= line;
			}

			auto result = p.wait;
			

			//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz(outputResult) );
			// Back to top of outputPanel
			IupSetAttribute( GLOBAL.outputPanel, "SCROLLTOPOS", "0" );

			if( !outputResult.length )
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz("Build Success!") );

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
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz("Build Error!") );
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
					version(Windows)
					{
						command = GLOBAL.projectManager[activePrjName].dir ~ "\\" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe";
					}
					else
					{
						command = GLOBAL.projectManager[activePrjName].dir ~ "\\" ~ GLOBAL.projectManager[activePrjName].name;
					}
					break;
				}
			}

			if( !bRunProject ) 
			{
				scope _f = new FilePath( activeCScintilla.getFullPath() );
				version(Windows)
				{
					command = _f.path ~ "\\" ~ _f.name ~ ".exe";
				}
				else
				{
					command = _f.path ~ "\\" ~ _f.name;
				}
			}
		}
		else
		{
			if( activePrjName.length )
			{
				version(Windows)
				{
					command = GLOBAL.projectManager[activePrjName].dir ~ "\\" ~ GLOBAL.projectManager[activePrjName].name ~ ".exe";
				}
				else
				{
					command = GLOBAL.projectManager[activePrjName].dir ~ "\\" ~ GLOBAL.projectManager[activePrjName].name;
				}
			}
		}

		IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("") ); // Clean outputPanel
		
		scope f = new FilePath( Util.substitute( command, "\\", "/" ) );
		if( f.exists() )
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz("Running " ~ command ~ "......") );

			/+
			Process exe = new Process(  "cmd.exe /k " ~ fullPath , null );
			exe.execute;
			+/
			auto derived = new ExecuterThread( command );
			derived.start();
		}
		else
		{
			IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz( "Execute file: " ~ command ~ "\nisn't exist......?\n\nRun Error!") );
			return false;
		}

		return true;
	}


}



