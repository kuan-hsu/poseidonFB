module dialogs.idemessageDlg;

import dialogs.baseDlg;

class CIDEMessageDialog : CBaseDialog
{
	private:
	import iup.iup;	
	import actionManager, global, tools;
	import tango.stdc.stringz;
	import tango.time.WallClock;

	Ihandle*	text;

	void createLayout()
	{
		text = IupText( null );
		IupSetAttributes( text, "EXPAND=YES,MULTILINE=YES,READONLY=YES,WORDWRAP=YES,APPENDNEWLINE=NO" );
		Ihandle* scrollBox = IupFlatScrollBox( text );
		
		Ihandle* vBox = IupVbox( scrollBox, null );
		IupSetAttributes( vBox, "ALIGNMENT=ARIGHT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttributes( _dlg, "MAXBOX=NO,MINBOX=NO,SIZE=QUARTERxFULL,OPACITY=180" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.IDEMessageDlg !is null ) IupHide( GLOBAL.IDEMessageDlg.getHandle );
			return IUP_DEFAULT;
		});

		createLayout();
	}

	~this()
	{
	}

	char[] show( int x, int y )
	{
		IupShowXY( _dlg, x, y );
		return null;
	}
	
	Ihandle* getHandle()
	{
		return _dlg;
	}
	
	void setFont( char[] _font )
	{
		IupSetAttribute( text, "FONT", toStringz( _font ) );//IupSetAttribute( GLOBAL.outputPanel, "FONT", outputString.toCString );// Output		
	}
	
	void print( char[] txt, bool bClock = true, bool bClear = false )
	{
		if( bClock )
		{
			auto _DateTime = WallClock.toDate();
			char[] _now = Integer.toString( _DateTime.date.year ) ~ "/" ~ Integer.toString( _DateTime.date.month ) ~ "/" ~ Integer.toString( _DateTime.date.day ) ~ " " ~ Integer.toString( _DateTime.time.hours ) ~ ":" ~ Integer.toString( _DateTime.time.minutes ) ~ ":" ~ Integer.toString( _DateTime.time.seconds );
			IupSetAttribute( text, "APPEND", toStringz( _now ~ "  " ) );
		}
		
		if( bClear )
			IupSetAttribute( text, "VALUE", toStringz( txt ~ "\n" ) );
		else
			IupSetAttribute( text, "APPEND", toStringz( txt ~ "\n") );
	}	
}