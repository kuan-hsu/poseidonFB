module project;

struct PROJECT
{
	private:
	import actionManager;
	
	import tango.text.xml.Document;
	import tango.text.xml.DocPrinter;
	import tango.io.UnicodeFile;
	import tango.io.FilePath;//tango.io.Stdout;


	public:
	// General
	char[]		name;
	char[]		type;
	char[]		dir;
	char[]		mainFile;
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

	void saveFile()
	{
		auto doc = new Document!(char);
		
		// attach an xml header
		doc.header;

		auto prjNode = doc.tree.element( null, "Project" );

		prjNode.element( null, "ProjectName", name );
		prjNode.element( null, "Type", type );
		//prjNode.element( null, "Dir", dir );
		prjNode.element( null, "MainFile", mainFile );
		prjNode.element( null, "TargetName", targetName );
		prjNode.element( null, "CompilerArgs", args );
		prjNode.element( null, "CompilerOption", compilerOption );
		prjNode.element( null, "Comment", comment );
		prjNode.element( null, "CompilerPath", compilerPath );

		auto prjIncludeNode = prjNode.element( null, "IncludeDirs" );
		foreach( char[] s; includeDirs )
		{
			if( Util.index( s, dir ~ "/" ) < s.length ) s = Util.substitute( s, dir ~ "/", "" );
			prjIncludeNode.element( null, "Name", s );
		}

		auto prjLibNode = prjNode.element( null, "LibDirs" );
		foreach( char[] s; libDirs ) 
		{
			if( Util.index( s, dir ~ "/" ) < s.length ) s = Util.substitute( s, dir ~ "/", "" );
			prjLibNode.element( null, "Name", s );
		}

		auto prjSourceNode = prjNode.element( null, "Sources" );
		foreach( char[] s; sources )
		{
			if( Util.index( s, dir ~ "/" ) < s.length ) s = Util.substitute( s, dir ~ "/", "" );
			prjSourceNode.element( null, "Name", s );
		}

		auto prjIncludeFileNode = prjNode.element( null, "Includes" );
		foreach( char[] s; includes ) 
		{
			if( Util.index( s, dir ~ "/" ) < s.length ) s = Util.substitute( s, dir ~ "/", "" );
			prjIncludeFileNode.element( null, "Name", s );
		}

		auto prjOthersNode = prjNode.element( null, "Others" );
		foreach( char[] s; others ) 
		{
			if( Util.index( s, dir ~ "/" ) < s.length ) s = Util.substitute( s, dir ~ "/", "" );
			prjOthersNode.element( null, "Name", s );
		}


		// Save File
		scope print = new DocPrinter!(char);
		FileAction.saveFile( dir ~ "/.poseidon", print.print( doc ) );
	}

	PROJECT loadFile( char[] settingFileName )
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
			s.dir = _dir.path[0..length-1];
			
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
				scope _fp = new FilePath( s.includeDirs[length-1]  );
				if( !_fp.isAbsolute() ) s.includeDirs[length-1] = s.dir ~ "/" ~ s.includeDirs[length-1];
			}
			
			result = root.query["LibDirs"]["Name"];
			foreach( e; result )
			{
				s.libDirs ~= e.value;
				scope _fp = new FilePath( s.libDirs[length-1]  );
				if( !_fp.isAbsolute() ) s.libDirs[length-1] = s.dir ~ "/" ~ s.libDirs[length-1];
			}

			result = root.query["Sources"]["Name"];
			foreach( e; result )
			{
				s.sources ~= e.value;
				scope _fp = new FilePath( s.sources[length-1]  );
				if( !_fp.isAbsolute() ) s.sources[length-1] = s.dir ~ "/" ~ s.sources[length-1];
			}
		
			result = root.query["Includes"]["Name"];
			foreach( e; result )
			{
				s.includes ~= e.value;
				scope _fp = new FilePath( s.includes[length-1]  );
				if( !_fp.isAbsolute() ) s.includes[length-1] = s.dir ~ "/" ~ s.includes[length-1];
			}

			result = root.query["Others"]["Name"];
			foreach( e; result )
			{
				s.others ~= e.value;
				scope _fp = new FilePath( s.others[length-1]  );
				if( !_fp.isAbsolute() ) s.others[length-1] = s.dir ~ "/" ~ s.others[length-1];
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