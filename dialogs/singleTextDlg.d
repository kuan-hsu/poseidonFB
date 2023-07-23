module dialogs.singleTextDlg;

import iup.iup;
import dialogs.baseDlg;
import std.conv, std.string;

class CSingleTextDialog : CBaseDialog
{
private:
	import		global;
	
	Ihandle*	label, textResult;
	string		labelName;

	void createLayout( string textWH )
	{
		Ihandle* bottom = createDlgButton( "40x12" );

		label = IupLabel( null );
		IupSetStrAttribute( label, "TITLE", toStringz( labelName ) );
		
		textResult = IupText( null );
		if( textWH.length ) IupSetStrAttribute( textResult, "SIZE", toStringz( textWH ) );
		IupSetAttribute( textResult, "EXPAND", "YES" );
		IupSetStrAttribute( textResult, "FONT", toStringz( GLOBAL.fonts[0].fontString ) );
		IupSetHandle( "CSingleTextDialog_text", textResult );
		version(Windows)
		{
			IupSetStrAttribute( textResult, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textResult, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
		Ihandle* hBox = IupHbox( label, textResult, null );
		IupSetAttribute( hBox, "ALIGNMENT", "ACENTER" );

		Ihandle* vBox = IupVbox( hBox, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
	}	

public:
	this( int w, int h, string title, string _labelText = null, string textWH = null, string text = null, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG", string iconName = null, bool bMap = true )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		if( iconName.length ) IupSetStrAttribute( _dlg, "ICON", toStringz( iconName ) );

		labelName = _labelText ;

		createLayout( textWH );

		if( bMap ) IupMap( _dlg );
		
		IupSetStrAttribute( textResult, "VALUE", toStringz( text ) );
		if( text.length) IupSetAttribute( textResult, "SELECTION", "ALL" );
		
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CSingleTextDialog_btnOK_cb );
		IupSetCallback( btnHiddenOK, "ACTION", cast(Icallback) &CSingleTextDialog_btnOK_cb );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CSingleTextDialog_btnCancel_cb );
		IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CSingleTextDialog_btnCancel_cb );
	}

	~this()
	{
		IupSetHandle( "textResult", null );
	}

	override string show( int x, int y ) // Overload form CBaseDialog
	{
		IupMap( _dlg );
		IupPopup( _dlg, x, y );

		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		return fromStringz(IupGetAttribute( textHandle, "VALUE" ) ).dup;
	}
	
	Ihandle* getTextHandle()
	{
		return textResult;
	}
	
	Ihandle* getLabelHandle()
	{
		return label;
	}	
}

extern(C) // Callback for CSingleTextDialog
{
	private int CSingleTextDialog_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		if( textHandle != null ) IupSetAttribute( textHandle, "VALUE", "" );

		return IUP_CLOSE;
	}

	private int CSingleTextDialog_btnOK_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
}



class CSingleTextInput
{
private:
	import		global;	
	Ihandle*	inputText, inputDlg;

public:
	this( int w, int h, string text = null, string color = "255 255 255", int opacity = 198, bool border = true )
	{
		inputText = IupText( null );
		IupSetStrAttribute( inputText, "SIZE", toStringz( to!(string)(w) ~ "x" ~ to!(string)(h) ) );
		IupSetStrAttribute( inputText, "BGCOLOR", toStringz( color ) );
		IupSetCallback( inputText, "K_ANY", cast(Icallback) &CSingleTextInput_K_ANY );
		version(Windows)
		{
			IupSetStrAttribute( inputText, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( inputText, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
		
		inputDlg = IupDialog( inputText );
		IupSetAttributes( inputDlg, "RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO" );
		IupSetAttribute( inputDlg, "TITLE", null );
		IupSetInt( inputDlg, "BORDER", border );
		IupSetInt( inputDlg, "OPACITY", opacity );

		IupSetStrAttribute( inputText, "VALUE", toStringz( text ) );
		IupSetAttribute( inputText, "SELECTION", "ALL" );
		
		IupSetHandle( "CSingleTextInput_dlg", inputDlg );
	}

	~this()
	{
		IupSetHandle( "CSingleTextInput_dlg", null );
	}

	string show( int x, int y )
	{
		IupMap( inputDlg );
		IupPopup( inputDlg, x, y );
		
		if( IupGetInt( inputDlg, "ACTIVE" ) == 0 ) return null;
		
		return fromStringz( IupGetAttribute( inputText, "VALUE" ) ).dup;
	}
}

extern(C) // Callback for CSingleTextDialogWithoutButton
{
	private int CSingleTextInput_K_ANY( Ihandle* ih, int c )
	{
		Ihandle* dlgHandle = IupGetHandle( "CSingleTextInput_dlg" );
		if( dlgHandle != null )
		{
			if( c == 13 ) return IUP_CLOSE;
			if( c == 65307 )
			{
				IupSetInt( dlgHandle, "ACTIVE", 0 );
				return IUP_CLOSE;
			}
		}

		return IUP_DEFAULT;
	}
}


class CSingleTextOpen : CBaseDialog
{
private:
	import		global, tools;
	import		dialogs.fileDlg;
	
	Ihandle*	labelORframe, hBox, vBox, textResult, openButton;
	IupString	labelName;

	void createLayout( string textWH, bool bFrame )
	{
		Ihandle* bottom = createDlgButton( "40x12" );

		textResult = IupText( null );
		if( textWH.length ) IupSetStrAttribute( textResult, "SIZE", toStringz( textWH ) );
		IupSetAttribute( textResult, "EXPAND", "YES" );
		IupSetStrAttribute( textResult, "FONT", toStringz( GLOBAL.fonts[0].fontString ) );
		IupSetHandle( "CSingleTextOpen_text", textResult );
		version(Windows)
		{
			IupSetStrAttribute( textResult, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textResult, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
		
		openButton = IupButton( null, null );
		IupSetAttributes( openButton, "IMAGE=icon_openfile,FLAT=YES,CANFOCUS=NO" );

		if( !bFrame )
		{
			labelORframe = IupLabel( labelName.toCString );
			hBox = IupHbox( labelORframe, textResult, openButton, null );
			vBox = IupVbox( hBox, bottom, null );
		}
		else
		{
			hBox = IupHbox( textResult, openButton, null );
			labelORframe = IupFrame( hBox );
			IupSetAttribute( labelORframe, "TITLE", labelName.toCString );
			vBox = IupVbox( labelORframe, bottom, null );
		}

		IupSetAttribute( hBox, "ALIGNMENT", "ACENTER" );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );
		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );

		IupAppend( _dlg, vBox );
	}	

public:
	this( int w, int h, string title, string _labelText = null, string textWH = null, string text = null, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG", string iconName = null, bool bFrame = true )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetStrAttribute( _dlg, "ICON", toStringz( iconName ) );

		labelName = new IupString( _labelText );

		createLayout( textWH, bFrame );

		IupSetStrAttribute( textResult, "VALUE", toStringz( text ) );
		IupSetAttribute( textResult, "SELECTION", "ALL" );
		
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CSingleTextOpen_btnOK_cb );
		IupSetCallback( btnHiddenOK, "ACTION", cast(Icallback) &CSingleTextOpen_btnOK_cb );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CSingleTextOpen_btnCancel_cb );
		IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CSingleTextOpen_btnCancel_cb );
		
		IupSetCallback( openButton, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* textHandle = IupGetHandle( "CSingleTextOpen_text" );
			if( textHandle != null )
			{
				scope fileSelectDlg = new CFileDlg( null, null, "DIR", null, fSTRz( IupGetAttribute( textHandle, "VALUE" ) ) );
				string fileName = fileSelectDlg.getFileName();

				if( fileName.length )
				{
					IupSetStrAttribute( textHandle, "VALUE", toStringz( fileName ) );
					IupSetAttribute( textHandle, "SELECTIONPOS", "ALL" );
				}
			}
			return IUP_DEFAULT;
		});
	}

	~this()
	{
		IupSetHandle( "textResult", null );
		if( labelName !is null ) destroy( labelName );
	}

	override string show( int x, int y ) // Overload form CBaseDialog
	{
		IupMap( _dlg );
		IupPopup( _dlg, x, y );

		Ihandle* textHandle = IupGetHandle( "CSingleTextOpen_text" );
		return fromStringz( IupGetAttribute( textHandle, "VALUE" ) ).dup;
	}
	
	Ihandle* getTextHandle()
	{
		return textResult;
	}
	
	Ihandle* getLabelHandle()
	{
		return labelORframe;
	}	
}

extern(C) // Callback for CSingleTextOpen
{
	private int CSingleTextOpen_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CSingleTextOpen_text" );
		if( textHandle != null ) IupSetAttribute( textHandle, "VALUE", "" );

		return IUP_CLOSE;
	}

	private int CSingleTextOpen_btnOK_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
}