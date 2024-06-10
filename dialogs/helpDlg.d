module dialogs.helpDlg;

import dialogs.baseDlg;

class CCompilerHelpDialog : CBaseDialog
{
private:
	import iup.iup;	
	import global;
	import std.string, std.file;
	
	Ihandle* text;

	void createLayout()
	{
		text = IupText( null );
		IupSetAttributes( text, "EXPAND=YES,MULTILINE=YES,READONLY=YES" );

		try
		{
			version(FBIDE)
			{
				auto d = cast(string) std.file.read( GLOBAL.poseidonPath ~ "/settings/compilerOptionsFB.txt" );
				IupSetStrAttribute( text, "VALUE", toStringz( d ) );
			}
			else
			{
				auto d = cast(string) std.file.read( GLOBAL.poseidonPath ~ "/settings/compilerOptionsD.txt" );
				IupSetStrAttribute( text, "VALUE", toStringz( d ) );
			}
		}
		catch( Exception e )
		{
			IupMessage( "Error", toStringz( e.toString ) ); 
		}

		Ihandle* scrollBox = IupScrollBox( text );
		Ihandle* vBox = IupVbox( scrollBox, null );
		IupSetAttributes( vBox, "ALIGNMENT=ARIGHT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
		IupMap( _dlg );
	}	

public:
	this( int w, int h, string title, bool bResize = true, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_selectall" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "TOPMOST", "YES" );
		createLayout();
	}

	~this()
	{
		IupDestroy( _dlg );
	}

	override string show( int x, int y )
	{
		version(Windows)
		{
			IupSetStrAttribute( _dlg, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( _dlg, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
			IupMap( _dlg );
			tools.setCaptionTheme( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
			tools.setWinTheme( text, "Explorer", GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
		}
		IupShowXY( _dlg, x, y );
		return null;
	}	
}