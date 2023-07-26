module dialogs.fileDlg;

class CFileDlg
{
private:
	import iup.iup;
	import global, tools;
	import std.string, std.file, Array = std.array, Path = std.path;
	
	string[]	filesName;
	string		filterUsed;
	
	void callIupFileDlg( string title, string filter, string DIALOGTYPE = "OPEN", string MULTIPLEFILES = "NO", string _fileName = "" )
	{
		Ihandle *dlg = IupFileDlg(); 
		IupSetStrAttribute( dlg, "DIALOGTYPE",  toStringz( DIALOGTYPE ) );
		IupSetStrAttribute( dlg, "TITLE", toStringz( title ) );
		if( GLOBAL.recentOpenDir.length )
			if( std.file.isDir( GLOBAL.recentOpenDir ) ) IupSetStrAttribute( dlg, "DIRECTORY", toStringz( GLOBAL.recentOpenDir ) );
		
		bool bMultiFiles;
		if( DIALOGTYPE == "OPEN" && MULTIPLEFILES == "YES" )
		{
			bMultiFiles = true;
			IupSetStrAttribute( dlg, "MULTIPLEFILES", toStringz( MULTIPLEFILES ) );
		}
		else if( DIALOGTYPE == "OPEN" || DIALOGTYPE == "DIR" )
		{
			if( std.file.exists( _fileName ) )
			{
				if( std.file.isFile( _fileName ) ) _fileName = Path.dirName( _fileName );
				if( std.file.isDir( _fileName ) ) IupSetStrAttribute( dlg, "DIRECTORY", toStringz( _fileName ) );
			}
		}		
		else if( DIALOGTYPE == "SAVE" )
		{
			if( _fileName.length ) IupSetStrAttribute( dlg, "FILE", toStringz( _fileName ) );
		}

		IupSetStrAttribute( dlg, "EXTFILTER", toStringz( filter ) );
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT ); 

		/*
		"1": New file.
		"0": Normal, existing file or directory.
		"-1": Operation cancelled.
		*/
		if( IupGetInt( dlg, "STATUS") != -1 )
		{
			filterUsed = strip( fSTRz( IupGetAttribute( dlg, "FILTERUSED" ) ) );
			string fileString = strip( fSTRz( IupGetAttribute( dlg, "VALUE" ) ) );

			if( fileString.length )
			{
				if( !bMultiFiles )
				{
					fileString = tools.normalizeSlash( fileString );
					filesName ~= fileString;
				}
				else
				{
					if( fileString[$-1] == '|' ) // > 1 files
					{
						string[] _files = Array.split( fileString, "|" );
						if( _files.length )
						{
							string _path = tools.normalizeSlash( _files[0] ) ~ "/";
							for( int i = 1; i < _files.length; ++ i )
							{
								if( _files[i].length ) filesName ~= ( _path ~ _files[i] );
							}
						}
					}
					else
					{
						fileString = tools.normalizeSlash( fileString );
						filesName ~= fileString;
					}
				}
					
				if( filesName.length )
				{
					if( std.file.exists( filesName[0] ) )
					{
						if( std.file.isDir( filesName[0] ) ) GLOBAL.recentOpenDir = filesName[0]; else GLOBAL.recentOpenDir = Path.dirName( filesName[0] );
					}
				}
			}
		}
		else
		{
			filesName.length = 0;
		}

		IupDestroy( dlg );
	}

	public:
	this( string title, string filefilter = "All Files|*.*", string DIALOGTYPE = "OPEN", string MULTIPLEFILES = "NO", string _fn = "" )
	{
		callIupFileDlg( title, filefilter, DIALOGTYPE, MULTIPLEFILES, _fn );
	}

	string[] open( string title, string filefilter = "All Files|*.*", string DIALOGTYPE = "OPEN", string MULTIPLEFILES = "NO", string _fn = "" )
	{
		callIupFileDlg( title, filefilter, DIALOGTYPE, MULTIPLEFILES, _fn );

		return filesName;
	}

	string[] getFilesName(){ return filesName; }

	string getFileName()
	{
		if( filesName.length ) return filesName[0];

		return null;
	}

	string getFilterUsed(){ return filterUsed; }
}