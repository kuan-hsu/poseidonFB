module dialogs.idemessageDlg;

import iup.iup;
import dialogs.baseDlg;
import global;
import tango.stdc.stringz, Integer = tango.text.convert.Integer;

class CIDEMessageDialog : CBaseDialog
{
	private:
	import tools;
	import tango.time.WallClock;
	import Util = tango.text.Util;

	Ihandle*	text, val;
	bool		bCanRestore;
	IupString	fontString;

	void createLayout()
	{
		text = IupText( null );
		IupSetAttributes( text, "EXPAND=YES,MULTILINE=YES,READONLY=YES,WORDWRAP=YES,APPENDNEWLINE=NO,NAME=IDEMESSAGETEXT" );

		val = IupVal( null );
		IupSetAttributes( val, "MAX=240,MIN=100,VALUE=180" );
		IupSetCallback( val, "VALUECHANGED_CB", cast(Icallback) &dialogs.idemessageDlg.val_VALUECHANGED_CB );
		
		btnOK = IupButton( GLOBAL.languageItems["clear"].toCString, null );
		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &dialogs.idemessageDlg.btnClear_ACTION_CB );
		
		btnCANCEL = IupButton( GLOBAL.languageItems["close"].toCString, null );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &dialogs.idemessageDlg.btnClose_ACTION_CB );
		
		
		Ihandle* hBox_DlgButton = IupHbox( IupFill(), val, btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ACENTER,GAP=0,MARGIN=1x0" );

		Ihandle* vBox = IupVbox( text, hBox_DlgButton, null );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
		
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) function( Ihandle* ih )
		{
			return dialogs.idemessageDlg.btnClose_ACTION_CB( ih );
		});
	}
	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		
		IupSetAttribute( _dlg, "TITLE", null );
		//IupSetAttribute( _dlg, "MENUBOX", "NO" );
		
		IupSetAttributes( _dlg, "MAXBOX=NO,MINBOX=NO,BORDER=NO,SIZE=QUARTERxFULL,OPACITY=180,SHRINK=YES" );
		IupSetAttribute( _dlg, "ICON", "icon_idemessage" );

		createLayout();
		
		try
		{
			char[] _size = fromStringz( IupGetAttribute( _dlg, "SIZE" ) );
			if( _size.length )
			{
				int crossPos = Util.rindex( _size, "x" );
				if( crossPos < _size.length )
				{
					int _sizeINT = Integer.atoi( _size[crossPos+1..$] );
					if( _sizeINT > 24 )
					{
						_sizeINT -= 24;
						_size = _size[0..crossPos] ~ "x" ~ Integer.toString( _sizeINT );
						IupSetAttribute( _dlg, "SIZE", toStringz( _size ) );
					}
				}
			}
		}
		catch{}
		
		fontString = new IupString();
	}

	~this()
	{
		delete fontString;
	}

	char[] show( int x, int y )
	{
		IupShowXY( _dlg, x, y );
		return null;
	}
	
	void setFont( char[] _font )
	{
		fontString = _font;
		IupSetAttribute( text, "FONT", fontString.toCString );
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
	
	void setLocalization()
	{
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["clear"].toCString );
		IupSetAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		//titleString = GLOBAL.languageItems["message"].toDString;
		//IupSetAttribute( _dlg, "TITLE", titleString.toCString );
	}
}


extern(C) // Callback for CSingleTextDialog
{
	private int val_VALUECHANGED_CB( Ihandle *ih )
	{
		char[] value = fromStringz( IupGetAttribute( ih, "VALUE" ) );
		IupSetInt( GLOBAL.IDEMessageDlg.getIhandle, "OPACITY", Integer.atoi( value ) );
		
		return IUP_DEFAULT;
	}
	
	private int btnClose_ACTION_CB( Ihandle* ih )
	{
		if( GLOBAL.IDEMessageDlg !is null )	IupHide( GLOBAL.IDEMessageDlg.getIhandle );
		
		return IUP_DEFAULT;
	}

	private int btnClear_ACTION_CB( Ihandle* ih )
	{
		if( GLOBAL.IDEMessageDlg !is null )	GLOBAL.IDEMessageDlg.print( "[CLEAR......][done]\n", true, true );
		return IUP_DEFAULT;
	}
}