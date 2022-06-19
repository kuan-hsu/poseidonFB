module project;

struct FocusUnit
{
	char[]		Target, Option, Compiler;
	char[][]	IncDir, LibDir;
}
	
struct PROJECT
{
	private:
	import global, actionManager, tools;
	
	import tango.text.xml.Document;
	import tango.text.xml.DocPrinter;
	import tango.io.UnicodeFile;
	import tango.io.FilePath;//tango.io.Stdout;
	import tango.stdc.stringz;
	
	import iup.iup;


	public:
	// General
	char[]		name;
	char[]		type;
	char[]		dir;
	char[]		mainFile;
	char[]		passOneFile;
	char[]		targetName;
	char[]		args;
	char[]		compilerOption;
	char[]		comment;
	char[]		compilerPath;

	// Extra
	char[][]	includeDirs;
	char[][]	libDirs;
	char[][]	sources;
	char[][]	includes;
	char[][]	others;
	char[][]	misc;
	
	//version(DIDE) char[][]	defaultImportPaths;
	
	// Focus
	char[]					focusOn;
	FocusUnit[char[]]		focusUnit;
	

	bool saveFile()
	{
		char[] _replaceDir( char[] _fullPath, char[] _dir )
		{
			int pos;
			
			version(Windows)
			{
				pos = Util.index( tools.lowerCase( _fullPath ), tools.lowerCase( _dir ) );
				if( pos == 0 ) return _fullPath[_dir.length..$].dup;
			}
			else
			{
				pos = Util.index( _fullPath, _dir );
				if( pos == 0 ) return _fullPath[_dir.length..$].dup;
			}

			return _fullPath;
		}
		
		scope destPath = new FilePath( dir );
		if( !destPath.exists() )
		{	
			Ihandle* prjPropertyDialog = IupGetHandle( "PRJPROPERTY_DIALOG" );
			if( prjPropertyDialog == null ) prjPropertyDialog = GLOBAL.mainDlg;
			try
			{
				int result = tools.questMessage( GLOBAL.languageItems["alarm"].toDString, destPath.toString ~ "\n" ~ GLOBAL.languageItems["nodirandcreate"].toDString, "WARNING", IUP_CENTER, IUP_CENTER );
				if( result == 1 ) destPath.create(); else return false;
			}
			catch( Exception e )
			{
				IupMessageError( prjPropertyDialog, toStringz( e.toString ) );
				return false;
			}
		}
		
		char[]	PATH = dir ~ "/";
		char[]	doc;
		
		// Editor
		doc ~= setINILineData( "[Project]");
		
		doc ~= setINILineData( "ProjectName", name );
		doc ~= setINILineData( "Type", type );
		doc ~= setINILineData( "MainFile", mainFile );
		doc ~= setINILineData( "PassOneFile", passOneFile );
		doc ~= setINILineData( "TargetName", targetName );
		doc ~= setINILineData( "FocusOn", focusOn );
		doc ~= setINILineData( "CompilerArgs", args );
		doc ~= setINILineData( "CompilerOption", compilerOption );
		doc ~= setINILineData( "Comment", comment );
		doc ~= setINILineData( "CompilerPath", compilerPath );
		
		doc ~= setINILineData( "[IncludeDirs]");
		foreach( char[] s; includeDirs )
			doc ~= setINILineData( "name",  _replaceDir( s, PATH ) );

		doc ~= setINILineData( "[LibDirs]");
		foreach( char[] s; libDirs ) 
			doc ~= setINILineData( "name",  _replaceDir( s, PATH ) );

		doc ~= setINILineData( "[Sources]");
		foreach( char[] s; sources ) 
			doc ~= setINILineData( "name",  _replaceDir( s, PATH ) );

		doc ~= setINILineData( "[Includes]");
		foreach( char[] s; includes ) 
			doc ~= setINILineData( "name",  _replaceDir( s, PATH ) );

		doc ~= setINILineData( "[Others]");
		foreach( char[] s; others ) 
			doc ~= setINILineData( "name",  _replaceDir( s, PATH ) );

		doc ~= setINILineData( "[Misc]");
		foreach( char[] s; misc ) 
			doc ~= setINILineData( "name",  _replaceDir( s, PATH ) );
			
			
		doc ~= setINILineData( "[Focus]");
		foreach( char[] key; focusUnit.keys )
		{
			doc ~= setINILineData( "title",  key );
			doc ~= setINILineData( "target",  focusUnit[key].Target );
			doc ~= setINILineData( "option",  focusUnit[key].Option );
			doc ~= setINILineData( "compiler",  focusUnit[key].Compiler );

			char[] joined = Util.join( focusUnit[key].IncDir, ";" );
			if( joined.length ) doc ~= setINILineData( "incdir", joined );

			joined = Util.join( focusUnit[key].LibDir, ";" );
			if( joined.length ) doc ~= setINILineData( "libdir", joined );
		}
		
		version(FBIDE) actionManager.FileAction.saveFile( dir ~ "/FB.poseidon", doc );
		version(DIDE) actionManager.FileAction.saveFile( dir ~ "/D.poseidon", doc );
		
		return true;
	}
	
	
	PROJECT loadFile( char[] settingFileName )
	{
		char[] _replaceDir( char[] _fullPath, char[] _dir )
		{
			scope _fp = new FilePath( _fullPath  );
			if( !_fp.isAbsolute() ) return _dir ~ "/" ~ _fullPath;			
			
			return _fullPath;
		}
		
		PROJECT s;
		char[]	left, right;
		
		try
		{
			scope file = new UnicodeFile!(char)( settingFileName, Encoding.Unknown );
			char[] doc = file.read();
			
			scope _dir = new FilePath( settingFileName );
			s.dir = _dir.path[0..$-1];			
			
			char[]	blockText, focusName;
			foreach( char[] lineData; Util.splitLines( doc ) )
			{
				lineData = Util.trim( lineData );
				if( lineData.length )
				{
					// If .poseidon is xml format......
					if( lineData[0] == '<' )
					{
						return loadXMLFile( settingFileName );
					}
					else
					{
						// Get Line Data
						int _result = getINILineData( lineData, left, right );
						
						if( _result == 1 )
						{
							blockText = left;
							continue;
						}
						else if( _result == 0 )
						{
							continue;
						}
						else
						{
							if( !right.length ) continue;
						}
					}
				}
				else
				{
					continue;
				}
				
				switch( blockText )
				{
					case "[Project]":
						switch( left )
						{
							case "ProjectName":		s.name = right;							break;
							case "Type":			s.type = right;							break;
							case "MainFile":		s.mainFile = right;						break;
							case "PassOneFile":		s.passOneFile = right;					break;
							case "TargetName":		s.targetName = right;					break;
							case "FocusOn":			s.focusOn = right;						break;
							case "CompilerArgs":	s.args = right;							break;
							case "CompilerOption":	s.compilerOption = right;				break;
							case "Comment":			s.comment = right;						break;
							case "CompilerPath":	s.compilerPath = right;					
								//version(DIDE) if( right.length ) s.defaultImportPaths = tools.getImportPath( right );
								break;
							default:
						}
						break;
					
					case "[IncludeDirs]":
						if( left == "name" ) s.includeDirs ~= _replaceDir( right, s.dir );	break;

					case "[LibDirs]":	
						if( left == "name" ) s.libDirs ~= _replaceDir( right, s.dir );		break;
					
					case "[Sources]":
						if( left == "name" ) s.sources ~= _replaceDir( right, s.dir );		break;

					case "[Includes]":
						if( left == "name" ) s.includes ~= _replaceDir( right, s.dir );		break;
						
					case "[Others]":
						if( left == "name" ) s.others ~= _replaceDir( right, s.dir );		break;

					case "[Misc]":
						if( left == "name" ) s.misc ~= _replaceDir( right, s.dir );		break;

					case "[Focus]":
						switch( left )
						{
							case "title":
								focusName = right;
								FocusUnit _fs;
								s.focusUnit[focusName] = _fs;
								break;
							case "target":
								if( focusName.length )	s.focusUnit[focusName].Target = right;
								break;
							case "option":
								if( focusName.length )	s.focusUnit[focusName].Option = right;
								break;
							case "compiler":
								if( focusName.length )	s.focusUnit[focusName].Compiler = right;
								break;
							case "incdir":
								if( focusName.length )
								{
									foreach( char[] dir; Util.split( right, ";" ) )
										s.focusUnit[focusName].IncDir ~= _replaceDir( dir, s.dir );
								}
								break;
							case "libdir":
								if( focusName.length )
								{
									foreach( char[] dir; Util.split( right, ";" ) )
										s.focusUnit[focusName].LibDir ~= _replaceDir( dir, s.dir );
								}
								break;
							default:
						}
					
					default:
				}
			}
			
			s.sources.sort;
			s.includes.sort;
			s.others.sort;
			s.misc.sort;
		}
		catch( Exception e )
		{
			IupMessageError( null, "loadFile() in project.d Error!" );
		}
		
		return s;			
	}

	PROJECT loadXMLFile( char[] settingFileName )
	{
		PROJECT s;
		
		try
		{
			// Read xml
			// Loading Key Word...
			scope file = new UnicodeFile!(char)( settingFileName, Encoding.Unknown );

			scope xmlDoc = new Document!( char );
			xmlDoc.parse( file.read );

			auto root = xmlDoc.elements;
			auto result = root.query.descendant( "ProjectName" );
			foreach( e; result ){ s.name = e.value; }

			result = root.query.descendant( "Type" );
			foreach( e; result ){ s.type = e.value;	}

			/*
			result = root.query.descendant( "Dir" );
			foreach( e; result ){ s.dir = e.value; }
			*/
			
			scope _dir = new FilePath( settingFileName );
			s.dir = _dir.path[0..$-1];
			
			result = root.query.descendant( "MainFile" );
			foreach( e; result ){ s.mainFile = e.value;	}

			result = root.query.descendant( "TargetName" );
			foreach( e; result ){ s.targetName = e.value; }

			result = root.query.descendant( "CompilerArgs" );
			foreach( e; result ){ s.args = e.value.dup;	}

			result = root.query.descendant( "CompilerOption" );
			foreach( e; result ){ s.compilerOption = e.value; }

			result = root.query.descendant( "Comment" );
			foreach( e; result ){ s.comment = e.value;	}

			result = root.query.descendant( "CompilerPath" );
			foreach( e; result ){ s.compilerPath = e.value; }

			result = root.query["IncludeDirs"]["Name"];
			foreach( e; result )
			{ 
				s.includeDirs ~= e.value;
				scope _fp = new FilePath( s.includeDirs[$-1]  );
				if( !_fp.isAbsolute() ) s.includeDirs[$-1] = s.dir ~ "/" ~ s.includeDirs[$-1];
			}
			
			result = root.query["LibDirs"]["Name"];
			foreach( e; result )
			{
				s.libDirs ~= e.value;
				scope _fp = new FilePath( s.libDirs[$-1]  );
				if( !_fp.isAbsolute() ) s.libDirs[$-1] = s.dir ~ "/" ~ s.libDirs[$-1];
			}

			result = root.query["Sources"]["Name"];
			foreach( e; result )
			{
				s.sources ~= e.value;
				scope _fp = new FilePath( s.sources[$-1]  );
				if( !_fp.isAbsolute() ) s.sources[$-1] = s.dir ~ "/" ~ s.sources[$-1];
			}
		
			result = root.query["Includes"]["Name"];
			foreach( e; result )
			{
				s.includes ~= e.value;
				scope _fp = new FilePath( s.includes[$-1]  );
				if( !_fp.isAbsolute() ) s.includes[$-1] = s.dir ~ "/" ~ s.includes[$-1];
			}

			result = root.query["Others"]["Name"];
			foreach( e; result )
			{
				s.others ~= e.value;
				scope _fp = new FilePath( s.others[$-1]  );
				if( !_fp.isAbsolute() ) s.others[$-1] = s.dir ~ "/" ~ s.others[$-1];
			}

			s.sources.sort;
			s.includes.sort;
			s.others.sort;
			
			return s;
		}
		catch( Exception e )
		{
		}

		return s;
	}
}