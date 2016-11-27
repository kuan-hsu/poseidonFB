module dialogs.fileDlg;

class CFileDlg
{
	private:
	import global, tools;
	
	import iup.iup;

	import tango.io.FilePath;
	import Util = tango.text.Util, tango.stdc.stringz;

	char[][]	filesName;
	char[]		filterUsed;
	
	void callIupFileDlg( char[] title, char[] filter, char[] DIALOGTYPE = "OPEN", char[] MULTIPLEFILES = "NO" )
	{
		Ihandle *dlg = IupFileDlg(); 

		IupSetAttribute( dlg, "DIALOGTYPE",  toStringz( DIALOGTYPE.dup ) );
		IupSetAttribute( dlg, "TITLE", toStringz( title.dup ) );
		if( GLOBAL.recentOpenDir.length ) IupSetAttribute( dlg, "DIRECTORY", toStringz( GLOBAL.recentOpenDir ) );

		bool bMultiFiles;
		if( DIALOGTYPE == "OPEN" && MULTIPLEFILES == "YES" )
		{
			bMultiFiles = true;
			IupSetAttribute( dlg, "MULTIPLEFILES", GLOBAL.cString.convert( MULTIPLEFILES ) );
		}

		//char[] txtIupFilterAttribute = "FILTER = \"" ~ filter ~ "\", FILTERINFO = \"" ~  fileInfo ~ "\"";
		//IupSetAttributes(dlg, txtIupFilterAttribute.ptr );
		IupSetAttribute( dlg, "EXTFILTER", GLOBAL.cString.convert( filter ) );
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT ); 

		/*
		"1": New file.
		"0": Normal, existing file or directory.
		"-1": Operation cancelled.
		*/
		if( IupGetInt( dlg, "STATUS") != -1 )
		{
			filterUsed = Util.trim( fromStringz( IupGetAttribute( dlg, "FILTERUSED" ) ).dup );
			char[] fileString = Util.trim( fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup );

			if( fileString.length )
			{
				if( !bMultiFiles )
				{
					fileString = Util.substitute( fileString, "\\", "/" );
					filesName ~= fileString;
				}
				else
				{
					if( fileString[length-1] == '|' ) // > 1 files
					{
						char[][] _files = Util.split( fileString, "|" );
						if( _files.length )
						{
							char[] _path = Util.substitute( _files[0], "\\", "/" ) ~ "/";
							for( int i = 1; i < _files.length; ++ i )
							{
								if( _files[i].length ) filesName ~= ( _path ~ _files[i] );
							}
						}
					}
					else
					{
						fileString = Util.substitute( fileString, "\\", "/" );
						filesName ~= fileString;
					}
				}
				
				scope _fp = new FilePath( fileString );
				if( _fp.isFolder() ) GLOBAL.recentOpenDir = _fp.toString; else GLOBAL.recentOpenDir = _fp.path;
			}
		}
		else
		{
			filesName.length = 0;
		}

		IupDestroy( dlg );
	}

	public:
	this( char[] title, char[] filefilter = "All Files|*.*", char[] DIALOGTYPE = "OPEN", char[] MULTIPLEFILES = "NO" )
	{
		callIupFileDlg( title, filefilter, DIALOGTYPE, MULTIPLEFILES );
	}

	char[][] open( char[] title, char[] filefilter = "All Files|*.*", char[] DIALOGTYPE = "OPEN", char[] MULTIPLEFILES = "NO" )
	{
		callIupFileDlg( title, filefilter, DIALOGTYPE, MULTIPLEFILES );

		return filesName;
	}

	char[][] getFilesName(){ return filesName; }

	char[] getFileName()
	{
		if( filesName.length ) return filesName[0];

		return null;
	}

	char[] getFilterUsed(){ return filterUsed; }
}