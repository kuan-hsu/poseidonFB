module dialogs.fileDlg;

class CFileDlg
{
	private:
	import global;
	
	import iup.iup;

	import tango.text.Util, tango.stdc.stringz;

	char[]	fileName;
	
	void callIupFileDlg( char[] title, char[] filter, char[] DIALOGTYPE = "OPEN" )
	{
		Ihandle *dlg = IupFileDlg(); 

		IupSetAttribute( dlg, "DIALOGTYPE", toStringz( DIALOGTYPE, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;
		IupSetAttribute( dlg, "TITLE", toStringz( title, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;

		//char[] txtIupFilterAttribute = "FILTER = \"" ~ filter ~ "\", FILTERINFO = \"" ~  fileInfo ~ "\"";
		//IupSetAttributes(dlg, txtIupFilterAttribute.ptr );
		IupSetAttribute( dlg, "EXTFILTER", toStringz( filter, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT ); 

		if( IupGetInt( dlg, "STATUS") != -1 )
		{
			char[] _fileName = trim( fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup );
			fileName = _fileName.dup;
		}
		else
		{
			fileName = "";
		}

		IupDestroy( dlg );
	}

	public:
	this( char[] title, char[] filefilter = "All Files|*.*", char[] DIALOGTYPE = "OPEN" )
	{
		callIupFileDlg( title, filefilter, DIALOGTYPE );
	}

	char[] open( char[] title, char[] filefilter = "All Files|*.*", char[] DIALOGTYPE = "OPEN" )
	{
		callIupFileDlg( title, filefilter, DIALOGTYPE );

		return fileName;
	}

	char[] getFileName(){ return fileName; }
}