module dialogs.helpDlg;

import dialogs.baseDlg;

class CCompilerHelpDialog : CBaseDialog
{
	private:
	import iup.iup;	
	import actionManager, global;
	import tango.stdc.stringz;

	void createLayout()
	{
		Ihandle* text = IupText( null );
		IupSetAttributes( text, "EXPAND=YES,MULTILINE=YES" );
		IupSetAttribute( text, "VALUE", toStringz(GLOBAL.txtCompilerOptions.dup) );

		Ihandle* scrollBox = IupScrollBox( text );
		
		Ihandle* vBox = IupVbox( scrollBox, null );
		IupSetAttributes( vBox, "ALIGNMENT=ARIGHT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "TOPMOST", "YES" );

		createLayout();
	}

	char[] show( int x, int y )
	{
		IupShowXY( _dlg, x, y );
		return null;
	}	
}