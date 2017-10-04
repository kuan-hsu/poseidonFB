module dialogs.idemessageDlg;

import iup.iup;
import dialogs.baseDlg;
import global;
import tango.stdc.stringz, Integer = tango.text.convert.Integer;

class CIDEMessageDialog : CBaseDialog
{
	private:
	//import actionManager, global, tools;
	import tango.stdc.stringz;
	import tango.time.WallClock;

	Ihandle*	text, val;

	void createLayout()
	{
		text = IupText( null );
		IupSetAttributes( text, "EXPAND=YES,MULTILINE=YES,READONLY=YES,WORDWRAP=YES,APPENDNEWLINE=NO" );

		val = IupVal( null );
		IupSetAttributes( val, "MAX=240,MIN=100,VALUE=180" );
		IupSetCallback( val, "VALUECHANGED_CB", cast(Icallback) &CIDEMessageDialog_VALUECHANGED_CB_cb );
		
		btnOK = IupButton( GLOBAL.languageItems["clear"].toCString, null );
		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CIDEMessageDialog_btnClear_cb );
		
		btnCANCEL = IupButton( GLOBAL.languageItems["close"].toCString, null );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CIDEMessageDialog_btnClose_cb );
		
		
		Ihandle* hBox_DlgButton = IupHbox( IupFill(), val, btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ACENTER,GAP=0,MARGIN=1x0" );

		Ihandle* vBox = IupVbox( text, hBox_DlgButton, null );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
		
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) function( Ihandle* ih )
		{
			return CIDEMessageDialog_btnClose_cb( ih );
		});
	}	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttributes( _dlg, "MAXBOX=NO,MINBOX=NO,SIZE=QUARTERxFULL,OPACITY=180,SHRINK=YES" );

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

			if( bClear )
			{
				IupSetAttribute( text, "VALUE", toStringz( _now ~ "  " ~ txt ) );
				return;
			}
			
			IupSetAttribute( text, "APPEND", toStringz( _now ~ "  " ) );
		}
		
		if( bClear )
			IupSetAttribute( text, "VALUE", toStringz( txt ~ "\n" ) );
		else
			IupSetAttribute( text, "APPEND", toStringz( txt ~ "\n" ) );
	}	
}


extern(C) // Callback for CSingleTextDialog
{
	private int CIDEMessageDialog_VALUECHANGED_CB_cb( Ihandle *ih )
	{
		char[] value = fromStringz( IupGetAttribute( ih, "VALUE" ) );
		IupSetInt( GLOBAL.IDEMessageDlg.getHandle, "OPACITY", Integer.atoi( value ) );
		//IupSetFocus( GLOBAL.IDEMessageDlg.getHandle );
		
		return IUP_DEFAULT;
	}
	
	private int CIDEMessageDialog_btnClose_cb( Ihandle* ih )
	{
		if( GLOBAL.IDEMessageDlg !is null ) IupHide( GLOBAL.IDEMessageDlg.getHandle );
		return IUP_DEFAULT;
	}

	private int CIDEMessageDialog_btnClear_cb( Ihandle* ih )
	{
		if( GLOBAL.IDEMessageDlg !is null )	GLOBAL.IDEMessageDlg.print( "[CLEAR......][done]\n", true, true );
		return IUP_DEFAULT;
	}
}