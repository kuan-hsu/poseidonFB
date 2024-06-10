module dialogs.customMessageDlg;

private import iup.iup;

class CCustomMessageDialog
{
private:
	import global, tools;
	import std.string, Conv = std.conv;
	version(Windows) private import core.sys.windows.mmsystem;
	
	const int			labelminW = 80, labelminH = 24;
	
	Ihandle*			_dlg, labelMessage;
	Ihandle*			btnNO, btnOK, btnCANCEL;
	
	/*
	bottons = "OK", "OKCANCEL", "RETRYCANCEL", "YESNO", or "YESNOCANCEL"
	*/
	Ihandle* createDlgButton( string buttonSize = "40x12", string buttons = "OK" )
	{
		if( !buttonSize.length ) buttonSize = "40x12";
		
		bool		yesEqualno;
		Ihandle*	hBox_DlgButton;
		if( buttons == "OKCANCEL" )
		{
			btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
			IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_OK", btnOK );
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomMessageDialog_btnYES_cb );
			
			btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
			IupSetStrAttribute( btnCANCEL, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_CANCEL", btnCANCEL );
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CCustomMessageDialog_btnCANCEL_cb );
			
			hBox_DlgButton = IupHbox( btnOK, btnCANCEL, null );
		}
		else if( buttons == "YESNO" )
		{
			btnOK = IupButton( GLOBAL.languageItems["yes"].toCString, null );
			IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_OK", btnOK );
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomMessageDialog_btnYES_cb );
			
			btnCANCEL = IupButton( GLOBAL.languageItems["no"].toCString, null );
			IupSetStrAttribute( btnCANCEL, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_CANCEL", btnCANCEL );
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CCustomMessageDialog_btnNO_cb );
			
			hBox_DlgButton = IupHbox( btnOK, btnCANCEL, null );
		}
		else if( buttons == "YESNOCANCEL" )
		{
			btnOK = IupButton( GLOBAL.languageItems["yes"].toCString, null );
			IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_OK", btnOK );
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomMessageDialog_btnYES_cb );
			
			btnNO = IupButton( GLOBAL.languageItems["no"].toCString, null );
			IupSetStrAttribute( btnNO, "SIZE", toStringz( buttonSize ) );
			IupSetCallback( btnNO, "ACTION", cast(Icallback) &CCustomMessageDialog_btnNO_cb );
			
			btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
			IupSetStrAttribute( btnCANCEL, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_CANCEL", btnCANCEL );
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CCustomMessageDialog_btnCANCEL_cb );
			
			hBox_DlgButton = IupHbox( btnOK, btnNO, btnCANCEL, null );
		}
		else
		{
			btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
			IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
			IupSetHandle( "CCustomMessageDialog_OK", btnOK );
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomMessageDialog_btnCANCEL_cb );
			
			hBox_DlgButton = IupHbox( btnOK, null );
			yesEqualno = true;
		}

		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES,GAP=5,MARGIN=2x2" );
		IupSetAttribute( _dlg, "DEFAULTENTER", "CCustomMessageDialog_OK" );
		if( !yesEqualno ) IupSetAttribute( _dlg, "DEFAULTESC", "CCustomMessageDialog_CANCEL" ); else IupSetAttribute( _dlg, "DEFAULTESC", "CCustomMessageDialog_OK" );
		//IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CBaseDialog_btnCancel_cb );		
		
		return hBox_DlgButton;
	}
	
	
	Ihandle* createMessage( string message, string iconName = "" )
	{
		labelMessage = IupLabel( null );
		IupSetStrAttribute( labelMessage, "TITLE", toStringz( message ) );
		IupSetAttributes( labelMessage, "ALIGNMENT=ALEFT,EXPAND=YES" );
		
		if( iconName.length )
		{
			Ihandle* labelICON = IupLabel( null );
			if( iconName == "ERROR" )
				GLOBAL.editorSetting00.IconInvert != "ALL" ? IupSetStrAttribute( labelICON, "IMAGE", "errorbox" ) : IupSetStrAttribute( labelICON, "IMAGE", "errorbox_invert" );
			else if( iconName == "WARNING" )
				GLOBAL.editorSetting00.IconInvert != "ALL" ? IupSetStrAttribute( labelICON, "IMAGE", "warningbox" ) : IupSetStrAttribute( labelICON, "IMAGE", "warningbox_invert" );
			else if( iconName == "QUESTION" )
				GLOBAL.editorSetting00.IconInvert != "ALL" ? IupSetStrAttribute( labelICON, "IMAGE", "querybox" ) : IupSetStrAttribute( labelICON, "IMAGE", "querybox_invert" );
			else if( iconName == "INFORMATION" )
				GLOBAL.editorSetting00.IconInvert != "ALL" ? IupSetStrAttribute( labelICON, "IMAGE", "infobox" ) : IupSetStrAttribute( labelICON, "IMAGE", "infobox_invert" );
			else
			{
				IupDestroy( labelICON );
				return labelMessage;
			}
				
			Ihandle* labelhBox = IupHbox( labelICON, labelMessage, null );
			IupSetAttributes( labelhBox, "ALIGNMENT=ACENTER" );

			return labelhBox;
		}
		
		return labelMessage;
	}

public:
	static int _result;
	
	this( string title, string message, string buttonType, string iconName = "" )
	{	
		_dlg = IupDialog( null );
		if( title.length ) IupSetStrAttribute( _dlg, "TITLE", toStringz( title ) );
		version(Windows)
		{
			IupSetStrAttribute( _dlg, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( _dlg, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		}
		IupSetStrAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.messageDlg ) );
		
		Ihandle* vBox = IupVbox( IupFill, createMessage( message, iconName ), IupFill, createDlgButton( "", buttonType ), null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,EXPANDCHILDREN=YES,GAP=10,MARGIN=10x2" );
		if( !iconName.length ) IupSetAttribute( vBox, "MARGIN", "30x2" );
		
		IupAppend( _dlg, vBox );
		
		IupSetAttributes( _dlg, "RESIZE=NO,MINBOX=NO,SHRINK=YES,MENUBOX=NO" );
		IupSetAttribute( _dlg, "PARENTDIALOG", "POSEIDON_MAIN_DIALOG" );
		IupSetStrAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
		/*
		version(Windows)
		{
			switch( iconName )
			{
				case "ERROR":	version(Windows) PlaySound( "settings/sound/error.wav", null, 0x0001 ); break;
				case "WARRING":	version(Windows) PlaySound( "settings/sound/warning.wav", null, 0x0001 ); break;
				default:		
			}
		}
		*/
	}

	~this()
	{
		IupDestroy( _dlg );
	}

	int show( int x, int y )
	{
		IupMap(_dlg);
		
		/*
		Width in 1/4's of the average width of a character for the current FONT of each control.
		Height in 1/8's of the average height of a character for the current FONT of each control.		
		*/
		int w, h, dialogW, dialogH;
		tools.splitBySign( fSTRz( IupGetAttribute( labelMessage, "SIZE" ) ), "x", w, h );
		tools.splitBySign( fSTRz( IupGetAttribute( _dlg, "SIZE" ) ), "x", dialogW, dialogH );
		
		if( h < labelminH && w < labelminW )
		{
			IupSetStrAttribute( labelMessage, "SIZE", toStringz( Conv.to!(string)(labelminW) ~ "x" ~ Conv.to!(string)(labelminH) ) );
			IupSetStrAttribute( _dlg, "SIZE", toStringz( Conv.to!(string)(dialogW + labelminW - w) ~ "x" ~ Conv.to!(string)(dialogH + labelminH - h) ) );
		}
		else if( h < labelminH )
		{
			IupSetStrAttribute( labelMessage, "SIZE", toStringz( "x" ~ Conv.to!(string)(labelminH) ) );
			IupSetStrAttribute( _dlg, "SIZE", toStringz( Conv.to!(string)(dialogW) ~ "x" ~ Conv.to!(string)(dialogH + labelminH - h) ) );
		}
		else if( w < labelminW )
		{
			IupSetStrAttribute( labelMessage, "SIZE", toStringz( Conv.to!(string)(labelminW) ~ "x" ) );
			IupSetStrAttribute( _dlg, "SIZE", toStringz( Conv.to!(string)(dialogW + labelminW - w) ~ "x" ~ Conv.to!(string)(dialogH) ) );
		}
		else
		{
			IupSetStrAttribute( _dlg, "SIZE", toStringz( Conv.to!(string)(dialogW + 4) ~ "x" ~ Conv.to!(string)(dialogH) ) );
		}
		
		version(Windows)
		{
			bool bUseDark = GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false;
			tools.setCaptionTheme( _dlg, bUseDark );
			tools.setWinTheme( btnNO, "Explorer", bUseDark );
			tools.setWinTheme( btnOK, "Explorer", bUseDark );
			tools.setWinTheme( btnCANCEL, "Explorer", bUseDark );
		}
		
		IupPopup( _dlg, x, y );
		
		return _result;
	}
	
	Ihandle* getIhandle()
	{
		return _dlg;
	}
}

extern(C) // Callback for CCustomMessageDialog
{
	private int CCustomMessageDialog_btnYES_cb( Ihandle* ih )
	{
		CCustomMessageDialog._result = 1;
		return IUP_CLOSE;
	}
	
	private int CCustomMessageDialog_btnNO_cb( Ihandle* ih )
	{
		CCustomMessageDialog._result = 2;
		return IUP_CLOSE;
	}	

	private int CCustomMessageDialog_btnCANCEL_cb( Ihandle* ih )
	{
		CCustomMessageDialog._result = 3;
		return IUP_CLOSE;
	}
}