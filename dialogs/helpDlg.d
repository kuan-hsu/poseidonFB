module dialogs.helpDlg;

import dialogs.baseDlg;

class CCompilerHelpDialog : CBaseDialog
{
	private:
	import iup.iup;	
	import global;
	import tango.stdc.stringz;
	import tango.io.UnicodeFile;

	void createLayout()
	{
		Ihandle* text = IupText( null );
		IupSetAttributes( text, "EXPAND=YES,MULTILINE=YES,READONLY=YES" );

		try
		{
			scope fileCompilerOptions = new UnicodeFile!(char)( "settings/compilerOptions.txt", Encoding.Unknown );
			IupSetStrAttribute( text, "VALUE", toStringz( fileCompilerOptions.read ) );
		}
		catch( Exception e )
		{
			IupMessage( "Error", toStringz( e.toString ) ); 
		}
		

		Ihandle* scrollBox = IupScrollBox( text );
		
		Ihandle* vBox = IupVbox( scrollBox, null );
		IupSetAttributes( vBox, "ALIGNMENT=ARIGHT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "TOPMOST", "YES" );
		createLayout();
	}

	~this()
	{
		IupDestroy( _dlg );
	}

	char[] show( int x, int y )
	{
		IupShowXY( _dlg, x, y );
		return null;
	}	
}