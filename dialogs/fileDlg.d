module dialogs.fileDlg;

class CFileDlg
{
	private:
	import global, tools;
	
	import iup.iup;

	import Util = tango.text.Util, tango.stdc.stringz;

	char[]	fileName, filterUsed;
	
	void callIupFileDlg( char[] title, char[] filter, char[] DIALOGTYPE = "OPEN" )
	{
		Ihandle *dlg = IupFileDlg(); 

		scope _dialogType =  new CstringConvert( DIALOGTYPE );
		IupSetAttribute( dlg, "DIALOGTYPE", _dialogType.toStringz );
		IupSetAttribute( dlg, "TITLE", GLOBAL.cString.convert( title ) );

		//char[] txtIupFilterAttribute = "FILTER = \"" ~ filter ~ "\", FILTERINFO = \"" ~  fileInfo ~ "\"";
		//IupSetAttributes(dlg, txtIupFilterAttribute.ptr );
		IupSetAttribute( dlg, "EXTFILTER", GLOBAL.cString.convert( filter ) );
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT ); 

		if( IupGetInt( dlg, "STATUS") != -1 )
		{
			fileName = Util.trim( fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup );
			filterUsed = Util.trim( fromStringz( IupGetAttribute( dlg, "FILTERUSED" ) ).dup );
			fileName = Util.substitute( fileName, "\\", "/" );
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

	char[] getFilterUsed(){ return filterUsed; }
	
}