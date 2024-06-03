module project;

struct FocusUnit
{
	string		Target, Option, Compiler;
	string[]	IncDir, LibDir;
}
	
struct PROJECT
{
private:
	import iup.iup;
	import global, actionManager, tools;
	import std.string, std.file, std.encoding, Path = std.path, Uni = std.uni, Array = std.array, Algorithm = std.algorithm;

public:
	// General
	string		name;
	string		type;
	string		dir;
	string		mainFile;
	string		passOneFile;
	string		targetName;
	string		args;
	string		compilerOption;
	string		comment;
	string		compilerPath;

	// Extra
	string[]	includeDirs;
	string[]	libDirs;
	string[]	sources;
	string[]	includes;
	string[]	others;
	string[]	misc;
	
	// Focus
	string					focusOn;
	FocusUnit[string]		focusUnit;
	

	bool saveFile()
	{
		string _replaceDir( string _fullPath, string _dir )
		{
			auto pos = indexOf( tools.fullPathByOS( _fullPath ), tools.fullPathByOS( _dir ) );
			if( pos == 0 ) return _fullPath[_dir.length..$].dup;

			return _fullPath;
		}
		
		if( !std.file.exists( dir ) )
		{	
			Ihandle* prjPropertyDialog = IupGetHandle( "PRJPROPERTY_DIALOG" );
			if( prjPropertyDialog == null ) prjPropertyDialog = GLOBAL.mainDlg;
			try
			{
				int result = tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, dir ~ "\n" ~ GLOBAL.languageItems["nodirandcreate"].toDString, "WARNING" );
				if( result == 1 ) std.file.mkdir( dir ); else return false;
			}
			catch( Exception e )
			{
				IupMessageError( prjPropertyDialog, toStringz( e.toString ) );
				return false;
			}
		}
		
		string	PATH = dir ~ "/";
		string	doc;
		
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
		foreach( s; includeDirs )
			doc ~= setINILineData( "name",  tools.normalizeSlash( _replaceDir( s, PATH ) ) );

		doc ~= setINILineData( "[LibDirs]");
		foreach( s; libDirs ) 
			doc ~= setINILineData( "name",  tools.normalizeSlash( _replaceDir( s, PATH ) ) );

		doc ~= setINILineData( "[Sources]");
		foreach( s; sources ) 
			doc ~= setINILineData( "name",  tools.normalizeSlash( _replaceDir( s, PATH ) ) );

		doc ~= setINILineData( "[Includes]");
		foreach( s; includes ) 
			doc ~= setINILineData( "name",  tools.normalizeSlash( _replaceDir( s, PATH ) ) );

		doc ~= setINILineData( "[Others]");
		foreach( s; others ) 
			doc ~= setINILineData( "name",  tools.normalizeSlash( _replaceDir( s, PATH ) ) );

		doc ~= setINILineData( "[Misc]");
		foreach( s; misc ) 
			doc ~= setINILineData( "name",  tools.normalizeSlash( _replaceDir( s, PATH ) ) );
			
			
		doc ~= setINILineData( "[Focus]");
		foreach( key; focusUnit.keys )
		{
			doc ~= setINILineData( "title",  key );
			doc ~= setINILineData( "target",  focusUnit[key].Target );
			doc ~= setINILineData( "option",  focusUnit[key].Option );
			doc ~= setINILineData( "compiler",  focusUnit[key].Compiler );

			string joined = Array.join( focusUnit[key].IncDir, ";" );
			if( joined.length ) doc ~= setINILineData( "incdir", joined );

			joined = Array.join( focusUnit[key].LibDir, ";" );
			if( joined.length ) doc ~= setINILineData( "libdir", joined );
		}
		
		version(FBIDE) actionManager.FileAction.saveFile( dir ~ "/FB.poseidon", doc, BOM.utf8, true );
		version(DIDE) actionManager.FileAction.saveFile( dir ~ "/D.poseidon", doc, BOM.utf8, true );
		
		return true;
	}
	
	
	PROJECT loadFile( string settingFileFullPath )
	{
		string _replaceDir( string _fullPath, string _dir )
		{
			if( !Path.isAbsolute( _fullPath ) ) return tools.normalizeSlash( _dir ~ "/" ~ _fullPath );
			return _fullPath;
		}
		
		PROJECT s;
		try
		{
			int _encoding, _withBom;
			auto doc = FileAction.loadFile( settingFileFullPath, _encoding, _withBom );
			string _dir = tools.normalizeSlash( Path.dirName( settingFileFullPath ) );
			s.dir = _dir;
			
			string	blockText, focusName, left, right;
			foreach( lineData; splitLines( doc ) )
			{
				lineData = strip( lineData );
				if( lineData.length )
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
						if( left == "name" ) s.includeDirs ~= _replaceDir( right, _dir );	break;

					case "[LibDirs]":	
						if( left == "name" ) s.libDirs ~= _replaceDir( right, _dir );		break;
					
					case "[Sources]":
						if( left == "name" ) s.sources ~= _replaceDir( right, _dir );		break;

					case "[Includes]":
						if( left == "name" ) s.includes ~= _replaceDir( right, _dir );		break;
						
					case "[Others]":
						if( left == "name" ) s.others ~= _replaceDir( right, _dir );		break;

					case "[Misc]":
						if( left == "name" ) s.misc ~= _replaceDir( right, _dir );		break;

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
								if( focusName.length )	s.focusUnit[focusName].Compiler = tools.normalizeSlash( right );
								break;
							case "incdir":
								if( focusName.length )
								{
									foreach( dir; Array.split( right, ";" ) )
										s.focusUnit[focusName].IncDir ~= _replaceDir( dir, _dir );
								}
								break;
							case "libdir":
								if( focusName.length )
								{
									foreach( dir; Array.split( right, ";" ) )
										s.focusUnit[focusName].LibDir ~= _replaceDir( dir, _dir );
								}
								break;
							default:
						}
						break;
					default:
				}
			}
			
			Algorithm.sort( s.sources );
			Algorithm.sort( s.includes );
			Algorithm.sort( s.others );
			Algorithm.sort( s.misc );
		}
		catch( Exception e )
		{
			IupMessageError( null, "loadFile() in project.d Error!" );
		}

		return s;			
	}
}