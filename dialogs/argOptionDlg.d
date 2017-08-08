module dialogs.argOptionDlg;

private import iup.iup;

private import global, project, actionManager;
private import dialogs.baseDlg, dialogs.singleTextDlg, dialogs.fileDlg;

private import tango.stdc.stringz, Util = tango.text.Util;
private import Integer = tango.text.convert.Integer;

class CArgOptionDialog : CBaseDialog
{
	private:
	import				tools;
	Ihandle*			btnQuick;
	Ihandle*			listTools, listOptions, listArgs;
	
	Ihandle*			hBoxOptions, hBoxArgs;
	
	
	Ihandle*			labelStatus;
	int					QuickMode;
	
	IupString[]			_recentOptions, _recentArgs;
	
	static char[][]		tempCustomCompilerOptions;

	Ihandle* createDlgButton( char[] buttonSize = "40x20" )
	{
		btnCANCEL = IupButton( GLOBAL.languageItems["close"].toCString, null );
		IupSetHandle( "btnCANCEL", btnCANCEL );
		IupSetAttributes( btnCANCEL, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel
		
		
		Ihandle* hBox_DlgButton;
		if( !QuickMode )
		{
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
			hBox_DlgButton = IupHbox( IupFill(), btnCANCEL, null );
		}
		else
		{
			btnQuick = IupButton( "QuickExecute", null );
			IupSetAttribute( btnQuick, "SIZE", "60x12" );
			//IupSetAttribute( btnQuick, "VISIBLE", "NO" );
			//IupSetAttribute( btnQuick, "IMAGE", "IUP_NavigateRefresh" );

			btnOK = IupButton( GLOBAL.languageItems["run"].toCString, null );
			IupSetHandle( "btnOK", btnOK );
			IupSetAttributes( btnOK, toStringz( "SIZE=" ~ buttonSize ) );//,IMAGE=IUP_ActionOk" );
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnOK_cb );
			
			IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK" );
			
			hBox_DlgButton = IupHbox( /*btnQuick,*/ IupFill(), btnOK, btnCANCEL, null );
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnCancel_cb );
		}
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );
		
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CCustomCompilerOptionDialog_btnCancel_cb );

		return hBox_DlgButton;
	}


	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		listTools = IupList( null );
		IupSetAttributes( listTools, "MULTIPLE=NO,EXPAND=YES" );
		IupSetHandle( "CCustomCompilerOptionDialog_listTools_Handle", listTools );
		IupSetCallback( listTools, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_ACTION );
		IupSetCallback( listTools, "DBLCLICK_CB", cast(Icallback) &CCustomCompilerOptionDialog_DBLCLICK_CB );
		
		for( int i = 0; i < GLOBAL.customCompilerOptions.length; ++ i )
		{
			CArgOptionDialog.tempCustomCompilerOptions ~= GLOBAL.customCompilerOptions[i].dup;
			int pos = Util.rindex( GLOBAL.customCompilerOptions[i], "%::% " );
			if( pos < GLOBAL.customCompilerOptions[i].length )
			{
				char[] Name = GLOBAL.customCompilerOptions[i][pos+5..$];
				IupSetAttributeId( listTools, "", i+1, toStringz( Name ) );
			}
		}
		
		Ihandle* btnToolsAdd = IupButton( null, null );
		IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES" );
		IupSetAttribute( btnToolsAdd, "TIP", GLOBAL.languageItems["add"].toCString );
		IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnToolsAdd );

		Ihandle* btnToolsErase = IupButton( null, null );
		IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES" );
		IupSetAttribute( btnToolsErase, "TIP", GLOBAL.languageItems["remove"].toCString );
		IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnToolsErase );
		
		Ihandle* btnToolsUp = IupButton( null, null );
		IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES" );
		IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnToolsUp );
		
		Ihandle* btnToolsDown = IupButton( null, null );
		IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES" );
		IupSetCallback( btnToolsDown, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnToolsDown );

		Ihandle* btnToolsApply = IupButton( null, null );
		IupSetAttributes( btnToolsApply, "IMAGE=icon_apply,FLAT=YES" );
		IupSetAttribute( btnToolsApply, "TIP", GLOBAL.languageItems["apply"].toCString );
		IupSetCallback( btnToolsApply, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_btnAPPLY );
		
		Ihandle* vBoxButtonTools = IupVbox( btnToolsAdd, btnToolsErase, btnToolsUp, btnToolsDown, btnToolsApply, null );
		Ihandle* frameList = IupFrame( IupHbox( listTools, vBoxButtonTools, null ) );
		IupSetAttributes( frameList, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		
		Ihandle* labelOptions = IupLabel( GLOBAL.languageItems["prjopts"].toCString );
		IupSetAttributes( labelOptions, "SIZE=60x16" );
		
		/+
		Ihandle* textOptions = IupText( null );
		IupSetAttribute( textOptions, "SIZE", "210x12" );	
		IupSetHandle( "CCustomCompilerOptionDialog_textOptions", textOptions );
		if( IupGetInt( listTools, "COUNT" ) > 0 )
		{
			IupSetAttribute( listTools, "VALUE", "1" ); // Set Focus
			
			char[] Name, Option;
			getCustomCompilerOptionValue( 0, Name, Option );
			IupSetAttribute( textOptions, "VALUE", toStringz( Option ) );
		}
		+/
		listOptions = IupList(null);
		IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=200x12,VISIBLE_ITEMS=5");
		IupSetHandle( "CCustomCompilerOptionDialog_textOptions", listOptions );
		for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
		{
			_recentOptions ~= new IupString( GLOBAL.recentOptions[i] );
			IupSetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ), _recentOptions[i].toCString );
		}		
		/*
		if( IupGetInt( listTools, "COUNT" ) > 0 )
		{
			IupSetAttribute( listTools, "VALUE", "1" ); // Set Focus
			
			char[] Name, Option;
			getCustomCompilerOptionValue( 0, Name, Option );
			IupSetAttribute( listOptions, "VALUE", toStringz( Option ) );
		}
		*/
		if( !QuickMode ) IupSetAttribute( listOptions, "DROPDOWN", "NO" );
		
		hBoxOptions = IupHbox( labelOptions, listOptions, null );
		IupSetAttributes( hBoxOptions, "ALIGNMENT=ACENTER,MARGIN=2x0" );
		
		if( QuickMode )
		{
			listArgs = IupList( null );
			IupSetAttributes( listArgs, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=200x12,VISIBLE_ITEMS=5");
			IupSetHandle( "CCustomCompilerOptionDialog_listArgs", listArgs );
			for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
			{
				_recentArgs ~= new IupString( GLOBAL.recentArgs[i] );
				IupSetAttribute( listArgs, toStringz( Integer.toString( i + 1 ) ), _recentArgs[i].toCString );
			}
			
			Ihandle* labelArgs = IupLabel( GLOBAL.languageItems["prjargs"].toCString );
			IupSetAttribute( labelArgs, "SIZE", "60x16" );
			hBoxArgs = IupHbox( labelArgs, listArgs, null );
			IupSetAttributes( hBoxArgs, "ALIGNMENT=ACENTER,MARGIN=2x0" );	
		}

		
		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");
		
		Ihandle* vBoxLayout;

		switch( QuickMode )
		{
			//case 1:			vBoxLayout = IupVbox( frameList, hBoxOptions, labelSEPARATOR, bottom, null ); break;
			case 2:			vBoxLayout = IupVbox( frameList, hBoxArgs, labelSEPARATOR, bottom, null ); break;
			case 3:			vBoxLayout = IupVbox( frameList, hBoxOptions, hBoxArgs, labelSEPARATOR, bottom, null ); break;
			default:		vBoxLayout = IupVbox( frameList, hBoxOptions, labelSEPARATOR, bottom, null ); break;
		}

		IupAppend( _dlg, vBoxLayout );
	}	

	public:
	
	this( int w, int h, char[] title, int _QuickMode = 0, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		QuickMode = _QuickMode;
		
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_tools" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );
		}
		
		createLayout();
	}

	~this()
	{
		IupSetHandle( "CCustomCompilerOptionDialog_listTools_Handle", null );
		IupSetHandle( "CCustomCompilerOptionDialog_textOptions", null );
		CArgOptionDialog.tempCustomCompilerOptions.length = 0;
		
		Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
		if( selectionHandle != null )
		{
			char[] name = fromStringz( IupGetAttribute( selectionHandle, "TITLE" ) ).dup;
			if( name.length )
			{
				foreach( char[] s; GLOBAL.customCompilerOptions )
				{
					int pos = Util.rindex( s, "%::% " );
					if( pos < s.length )
					{
						if( s[pos+5..$] == name ) return;
					}			
				}			
			}			
			
			IupSetAttribute( selectionHandle, "FGCOLOR", "255 0 0" );
			IupSetAttribute( selectionHandle, "TITLE", GLOBAL.noneCustomCompilerOption.toCString );
			GLOBAL.currentCustomCompilerOption = cast(char[])"";
		}
	}
	
	char[][] show( int x, int y, int dummy = -1 ) // Overload form CBaseDialog
	{
		if( QuickMode > 0 )
		{
			if( QuickMode & 1 )
			{
				IupSetAttribute( hBoxOptions, "ACTIVE", "YES" );
				/*
				IupSetAttribute( listTools, "ACTIVE", "YES" );
				IupSetAttribute( labelOptions, "ACTIVE", "YES" );
				*/
			}
			else
			{
				IupSetAttribute( hBoxOptions, "ACTIVE", "NO" );
				/*
				IupSetAttribute( listOptions, "ACTIVE", "NO" );
				IupSetAttribute( labelOptions, "ACTIVE", "NO" );
				*/
			}

			if( QuickMode & 2 )
			{
				IupSetAttribute( hBoxArgs, "ACTIVE", "YES" );
				/*
				IupSetAttribute( listArgs, "ACTIVE", "YES" );
				IupSetAttribute( labelArgs, "ACTIVE", "YES" );
				*/
			}
			else
			{
				IupSetAttribute( hBoxArgs, "ACTIVE", "NO" );
				/*
				IupSetAttribute( listArgs, "ACTIVE", "NO" );
				IupSetAttribute( labelArgs, "ACTIVE", "NO" );
				*/
			}

			if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" )
			{
				if( IupGetInt( listOptions, "COUNT" ) > 0 )
				{
					if( Util.trim( fromStringz( IupGetAttribute( listOptions, "1" ) ) ).length )
						IupSetAttribute( listOptions, "VALUE", IupGetAttribute( listOptions, "1" ) );
					else
						IupSetAttribute( listOptions, "VALUE", "" );
				}
			}

			if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" )
			{
				if( IupGetInt( listArgs, "COUNT" ) > 0 )
				{
					if( Util.trim( fromStringz( IupGetAttribute( listArgs, "1" ) ) ).length )
						IupSetAttribute( listArgs, "VALUE", IupGetAttribute( listArgs, "1" ) );
					else
						IupSetAttribute( listArgs, "VALUE", "" );
				}
			}
		}
			

		IupPopup( _dlg, x, y );

		if( QuickMode > 0 )
		{
			char[][] results;

			if( listOptions != null )
			{
				if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listOptions, "VALUE" ) ).dup;
			}

			if( listArgs != null )
			{
				if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listArgs, "VALUE" ) ).dup;
			}
			
			return results;
		}
		
		return null;
	}	
}

extern(C) // Callback for CFindInFilesDialog
{
	private void getCustomCompilerOptionValue( int index, inout char[] Name, inout char[] Option )
	{
		if( index < CArgOptionDialog.tempCustomCompilerOptions.length )
		{
			char[] s = CArgOptionDialog.tempCustomCompilerOptions[index];
			int pos = Util.rindex( s, "%::% " );
			if( pos < s.length )
			{
				Option	= Util.trim( s[0..pos] );
				Name	= Util.trim( s[pos+5..$] );
			}
		}
	}
	
	private int CCustomCompilerOptionDialog_btnAPPLY( Ihandle* ih )
	{
		Ihandle* toolsHandle = IupGetHandle( "CCustomCompilerOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		Ihandle* textHandle = IupGetHandle( "CCustomCompilerOptionDialog_textOptions" );
		int id = IupGetInt( toolsHandle, "VALUE" );
		
		if( textHandle != null )
		{
			if( IupGetInt( toolsHandle, "VALUE" ) > 0 )
			{
				char[] optionText = Util.trim( fromStringz( IupGetAttribute( textHandle, "VALUE" ) ) ).dup;
				/*
				if( optionText.length )
				{
				*/
					if( id > 0 ) CArgOptionDialog.tempCustomCompilerOptions[id-1] = optionText ~ "%::% " ~ fromStringz( IupGetAttributeId( toolsHandle, "", id ) ).dup;

					GLOBAL.customCompilerOptions.length = 0;
					foreach( char[] s; CArgOptionDialog.tempCustomCompilerOptions )
					{
						GLOBAL.customCompilerOptions ~= s.dup;
					}
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=INFORMATION" );
					IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["ok"].toCString() );
					IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["apply"].toCString() );
					IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );
				/*
				}
				else
				{
					IupMessageError( null, GLOBAL.languageItems["nulloption"].toCString() );
				}
				*/
			}
			else
			{
				IupMessageError( null, GLOBAL.languageItems["noselect"].toCString() );
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomCompilerOptionDialog_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* listOptions = IupGetHandle( "CCustomCompilerOptionDialog_textOptions" );
		if( listOptions != null ) IupSetAttribute( listOptions, "ACTIVE", "NO" );

		Ihandle* listArgs = IupGetHandle( "CCustomCompilerOptionDialog_listArgs" );
		if( listArgs != null ) IupSetAttribute( listArgs, "ACTIVE", "NO" );

		return IUP_CLOSE;
	}	
	
	private int CCustomCompilerOptionDialog_btnOK_cb( Ihandle* ih )
	{
		Ihandle* _listOptions = IupGetHandle( "CCustomCompilerOptionDialog_textOptions" );
		if( _listOptions != null )
		{
			if( fromStringz( IupGetAttribute( _listOptions, "ACTIVE" ) ) == "YES" )
			{
				char[] text = Util.trim( fromStringz( IupGetAttribute( _listOptions, "VALUE" ) ).dup );
				
				if( !text.length ) text = " ";

				if( text.length )
				{
					actionManager.SearchAction.addListItem( _listOptions, text, GLOBAL.maxRecentOptions );
					
					GLOBAL.recentOptions.length = 0;
					for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
					{
						GLOBAL.recentOptions ~= fromStringz( IupGetAttribute( _listOptions, toStringz( Integer.toString( i ) ) ) ).dup;
					}
					if( GLOBAL.recentOptions.length ) IupSetAttribute( _listOptions, "VALUE", toStringz( GLOBAL.recentOptions[0] ) );
				}
				/+
				else
				{
					IupSetAttribute( _listOptions, "VALUE", "" );
				}
				+/
			}
		}

		Ihandle* _listArgs = IupGetHandle( "CCustomCompilerOptionDialog_listArgs" );
		if( _listArgs != null )
		{
			if( fromStringz( IupGetAttribute( _listArgs, "ACTIVE" ) ) == "YES" )
			{
				char[] text = Util.trim( fromStringz( IupGetAttribute( _listArgs, "VALUE" ) ).dup );
				
				if( !text.length ) text = " ";
				
				if( text.length )
				{
					actionManager.SearchAction.addListItem( _listArgs, text, GLOBAL.maxRecentArgs );

					GLOBAL.recentArgs.length = 0;
					for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
					{
						GLOBAL.recentArgs ~= fromStringz( IupGetAttribute( _listArgs, toStringz( Integer.toString( i ) ) ) ).dup;
					}
					if( GLOBAL.recentArgs.length ) IupSetAttribute( _listArgs, "VALUE", toStringz( GLOBAL.recentArgs[0] ) );
				}
				/+
				else
				{
					IupSetAttribute( _listArgs, "VALUE", "" );
				}
				+/
			}
		}
		//IupHide( GLOBAL.argsDlg._dlg );
		
		return IUP_CLOSE;
	}	
	
	private int CCustomCompilerOptionDialog_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		Ihandle* textHandle = IupGetHandle( "CCustomCompilerOptionDialog_textOptions" );
		
		if( textHandle != null )
		{
			char[]	Name, Option;
			getCustomCompilerOptionValue( item-1, Name, Option );
			if( Name.length ) IupSetAttribute( textHandle, "VALUE", toStringz( Option ) ); else IupSetAttribute( textHandle, "VALUE", "" );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomCompilerOptionDialog_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		if( GLOBAL.statusBar !is null )
		{
			char[] name = fromStringz( text ).dup;
			foreach( char[] s; GLOBAL.customCompilerOptions )
			{
				int pos = Util.rindex( s, "%::% " );
				if( pos < s.length )
				{
					if( s[pos+5..$] == name )
					{
						Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
						if( selectionHandle != null )
						{
							GLOBAL.currentCustomCompilerOption = name;
							IupSetAttribute( selectionHandle, "FGCOLOR", "0 0 255" );
							IupSetAttribute( selectionHandle, "TITLE", GLOBAL.currentCustomCompilerOption.toCString );
							GLOBAL.statusBar.setTip( GLOBAL.currentCustomCompilerOption.toDString );
							break;
						}
					}
				}			
			}			
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomCompilerOptionDialog_btnToolsAdd( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CCustomCompilerOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomoption"].toDString(), GLOBAL.languageItems["prjtarget"].toDString() ~":", "120x" );
		char[] newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			IupSetAttribute( toolsHandle, "APPENDITEM", toStringz( newFileName ) );
			IupSetInt( toolsHandle, "VALUE", IupGetInt( toolsHandle, "COUNT" ) );
			
			CArgOptionDialog.tempCustomCompilerOptions.length = CArgOptionDialog.tempCustomCompilerOptions.length + 1;
			CArgOptionDialog.tempCustomCompilerOptions[$-1] = "%::% " ~ newFileName;
			
			Ihandle* textHandle = IupGetHandle( "CCustomCompilerOptionDialog_textOptions" );
			if( textHandle != null ) IupSetAttribute( textHandle, "VALUE", "" );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomCompilerOptionDialog_btnToolsErase( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CCustomCompilerOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		Ihandle* textHandle = IupGetHandle( "CCustomCompilerOptionDialog_textOptions" );
		if( textHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "VALUE" ); // Get current item #no
		if( index < 1 ) return IUP_DEFAULT;
		
		IupSetAttribute( toolsHandle, "REMOVEITEM", IupGetAttribute( toolsHandle, "VALUE" ) );
		IupSetAttribute( textHandle, "VALUE", "" );
		
		if( IupGetInt( toolsHandle, "COUNT" ) > 0 )
		{
			if( index > 1 ) IupSetInt( toolsHandle, "VALUE", index - 1 );// else IupSetInt( toolsHandle, "VALUE", 1 ); // Set Focus
		}
		else
		{
			CArgOptionDialog.tempCustomCompilerOptions.length = 0;
			return IUP_DEFAULT;
		}
		
		for( int i = index - 1; i < CArgOptionDialog.tempCustomCompilerOptions.length - 1; ++ i )
		{
			CArgOptionDialog.tempCustomCompilerOptions[i] = CArgOptionDialog.tempCustomCompilerOptions[i+1];
		}
		
		CArgOptionDialog.tempCustomCompilerOptions.length = CArgOptionDialog.tempCustomCompilerOptions.length - 1;

		int id = IupGetInt( toolsHandle, "VALUE" ); // Get current item #no
		if( id > 0 )
		{
			if( textHandle != null )
			{
				char[] Name, Option;
				getCustomCompilerOptionValue( id-1, Name, Option );
				if( Name.length ) IupSetAttribute( textHandle, "VALUE", toStringz( Option ) );
			}
		}
		

		return IUP_DEFAULT;
	}	

	private int CCustomCompilerOptionDialog_btnToolsUp( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CCustomCompilerOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );

		if( itemNumber > 1 )
		{
			char* prevItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber-1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber-1) ), nowItemText );
			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ), prevItemText );

			IupSetAttribute( toolsHandle, "VALUE", toStringz( Integer.toString(itemNumber-1) ) ); // Set Foucs
			
			// IupList item start from 1, CCustomCompilerOptionDialog.tempCustomCompilerOptions start from 0
			itemNumber--;
			
			char[] temp = CArgOptionDialog.tempCustomCompilerOptions[itemNumber-1];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber-1] = CArgOptionDialog.tempCustomCompilerOptions[itemNumber];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber] = temp;
		}

		return IUP_DEFAULT;
	}
	
	private int CCustomCompilerOptionDialog_btnToolsDown( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CCustomCompilerOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );
		int itemCount = IupGetInt( toolsHandle, "COUNT" );

		if( itemNumber < itemCount )
		{
			char* nextItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber+1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber+1) ), nowItemText );
			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ), nextItemText );

			IupSetAttribute( toolsHandle, "VALUE", toStringz( Integer.toString(itemNumber+1) ) );  // Set Foucs
			
			// IupList item start from 1, CCustomCompilerOptionDialog.tempCustomCompilerOptions start from 0
			itemNumber--;
			
			char[] temp = CArgOptionDialog.tempCustomCompilerOptions[itemNumber+1];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber+1] = CArgOptionDialog.tempCustomCompilerOptions[itemNumber];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber] = temp;
		}

		return IUP_DEFAULT;
	}
}
/+
class CArgOptionDialog : CBaseDialog
{
	private:
	Ihandle*			labelOptions, labelArgs, listOptions, listArgs, btnAPPLY, btnERASE;
	IupString[2]		cStrings;
	IupString[20]		_recentOptions, _recentArgs;
	
	Ihandle* createDlgButton( char[] buttonSize = "40x20" )
	{
		btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
		IupSetAttributes( btnOK, toStringz( "SIZE=" ~ buttonSize ) );//,IMAGE=IUP_ActionOk" );
		
		btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
		IupSetAttributes( btnCANCEL, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );

		btnAPPLY = IupButton( GLOBAL.languageItems["add"].toCString, null );
		IupSetAttributes( btnAPPLY, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel

		btnERASE = IupButton( GLOBAL.languageItems["delete"].toCString, null );
		IupSetAttributes( btnERASE, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel

		Ihandle* hBox_DlgButton = IupHbox( btnERASE, btnAPPLY, IupFill(), btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );

		return hBox_DlgButton;
	}	

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		cStrings[0] = new IupString( GLOBAL.languageItems["prjopts"].toDString() ~ ":" );
		cStrings[1] = new IupString( GLOBAL.languageItems["prjargs"].toDString() ~ ":" );		

		listOptions = IupList( null );
		IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5");
		for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
		{
			_recentOptions[i] = new IupString( GLOBAL.recentOptions[i] );
			IupSetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ), _recentOptions[i].toCString );
		}
			
		IupSetHandle( "CArgOptionDialog_listOptions", listOptions );

		labelOptions = IupLabel( cStrings[0].toCString );
		IupSetAttribute( labelOptions, "SIZE", "60x16" );
		Ihandle* hBox00 = IupHbox( labelOptions, listOptions, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );

		listArgs = IupList( null );
		IupSetAttributes( listArgs, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5");
		for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
		{
			_recentArgs[i] = new IupString( GLOBAL.recentArgs[i] );
			IupSetAttribute( listArgs, toStringz( Integer.toString( i + 1 ) ), _recentArgs[i].toCString );
		}
		
		IupSetHandle( "CArgOptionDialog_listArgs", listArgs );

		labelArgs = IupLabel( cStrings[1].toCString );
		IupSetAttribute( labelArgs, "SIZE", "60x16" );
		Ihandle* hBox01 = IupHbox( labelArgs, listArgs, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );

		Ihandle* vBox = IupVbox( hBox00, hBox01, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=2,EXPAND=YES,EXPANDCHILDREN=YES" );
		version( Windows ) IupSetAttribute( vBox, "FONTFACE", "Courier New" ); else IupSetAttribute( vBox, "FONTFACE", "FreeMono,Bold 9" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "TOPMOST", "YES" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );;
		}		

		createLayout();

		IupSetHandle( "btnAPPLY_argOption", btnAPPLY );
		IupSetHandle( "btnCANCEL_argOption", btnCANCEL );
		IupSetHandle( "btnOK_argOption", btnOK );

		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
		IupSetCallback( btnAPPLY, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
		IupSetCallback( btnERASE, "ACTION", cast(Icallback) &CArgOptionDialog_btnERASE_cb );
		
		
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["run"].toCString );

		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_argOption" );
		IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK_argOption" );

		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CArgOptionDialog_CLOSE_cb );
	}

	~this()
	{
		//IupSetHandle( "CArgOptionDialog_listOptions", null );
		IupSetHandle( "CArgOptionDialog_listArgs", null );
		IupSetHandle( "btnCANCEL_argOption", null );
		for( int i =0; i < 20; ++ i )
		{
			if( _recentArgs[i] !is null ) delete _recentArgs[i];
			if( _recentOptions[i] !is null ) delete _recentOptions[i];
		}
		
		if( cStrings[0] !is null ) delete cStrings[0];
		if( cStrings[1] !is null ) delete cStrings[1];
	}

	char[][] show( int showWhat ) // Overload form CBaseDialog
	{
		//IupShow( _dlg );
		if( showWhat & 1 )
		{
			IupSetAttribute( listOptions, "ACTIVE", "YES" );
			IupSetAttribute( labelOptions, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( listOptions, "ACTIVE", "NO" );
			IupSetAttribute( labelOptions, "ACTIVE", "NO" );
		}

		if( showWhat & 2 )
		{
			IupSetAttribute( listArgs, "ACTIVE", "YES" );
			IupSetAttribute( labelArgs, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( listArgs, "ACTIVE", "NO" );
			IupSetAttribute( labelArgs, "ACTIVE", "NO" );
		}

		if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" )
			if( IupGetInt( listOptions, "COUNT" ) > 0 ) IupSetAttribute( listOptions, "VALUE", IupGetAttribute( listOptions, "1" ) );

		if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" )
			if( IupGetInt( listArgs, "COUNT" ) > 0 ) IupSetAttribute( listArgs, "VALUE", IupGetAttribute( listArgs, "1" ) );
			

		IupPopup( _dlg, IUP_MOUSEPOS, IUP_MOUSEPOS );

		char[][] results;

		if( listOptions != null )
		{
			if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listOptions, "VALUE" ) ).dup;
		}

		if( listArgs != null )
		{
			if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listArgs, "VALUE" ) ).dup;
		}
		
		return results;
	}	
}

extern(C) // Callback for CArgOptionDialog
{
	private int CArgOptionDialog_btnCancel_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
			if( listOptions != null ) IupSetAttribute( listOptions, "ACTIVE", "NO" );

			Ihandle* listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( listArgs != null ) IupSetAttribute( listArgs, "ACTIVE", "NO" );

			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOptionDialog_btnOK_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* _listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
			if( _listOptions != null )
			{
				if( fromStringz( IupGetAttribute( _listOptions, "ACTIVE" ) ) == "YES" )
				{
					char[] text = Util.trim( fromStringz( IupGetAttribute( _listOptions, "VALUE" ) ).dup );
					if( text.length )
					{
						actionManager.SearchAction.addListItem( _listOptions, text, GLOBAL.maxRecentOptions );
						
						GLOBAL.recentOptions.length = 0;
						for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
						{
							GLOBAL.recentOptions ~= fromStringz( IupGetAttribute( _listOptions, toStringz( Integer.toString( i ) ) ) ).dup;
						}
						if( GLOBAL.recentOptions.length ) IupSetAttribute( _listOptions, "VALUE", toStringz( GLOBAL.recentOptions[0] ) );
					}
					else
					{
						IupSetAttribute( _listOptions, "VALUE", "" );
					}
				}
			}

			Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( _listArgs != null )
			{
				if( fromStringz( IupGetAttribute( _listArgs, "ACTIVE" ) ) == "YES" )
				{
					char[] text = Util.trim( fromStringz( IupGetAttribute( _listArgs, "VALUE" ) ).dup );
					if( text.length )
					{
						actionManager.SearchAction.addListItem( _listArgs, text, GLOBAL.maxRecentArgs );

						GLOBAL.recentArgs.length = 0;
						for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
						{
							GLOBAL.recentArgs ~= fromStringz( IupGetAttribute( _listArgs, toStringz( Integer.toString( i ) ) ) ).dup;
						}
						if( GLOBAL.recentArgs.length ) IupSetAttribute( _listArgs, "VALUE", toStringz( GLOBAL.recentArgs[0] ) );
					}
					else
					{
						IupSetAttribute( _listArgs, "VALUE", "" );
					}
				}
			}
			
			if( ih == IupGetHandle( "btnAPPLY_argOption" ) ) return IUP_DEFAULT;
			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOptionDialog_btnERASE_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* _listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
			if( _listOptions != null )
			{
				if( fromStringz( IupGetAttribute( _listOptions, "ACTIVE" ) ) == "YES" )
				{
					char[] text = fromStringz( IupGetAttribute( _listOptions, "VALUE" ) ).dup;
					for( int i = IupGetInt( _listOptions, "COUNT" ); i > 0; -- i )
					{
						char[] itemText = Util.trim( fromStringz( IupGetAttributeId( _listOptions, "", i ) ) ).dup;
						if( itemText.length )
						{
							if( fromStringz( IupGetAttributeId( _listOptions, "", i ) ) == text )
							{
								IupSetAttribute( _listOptions, "VALUE", "" );
								IupSetInt( _listOptions, "REMOVEITEM", i );
							}
						}
						else
						{
							IupSetInt( _listOptions, "REMOVEITEM", i );							
						}
					}
					GLOBAL.recentOptions.length = 0;
					for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
					{
						GLOBAL.recentOptions ~= fromStringz( IupGetAttributeId( _listOptions, "", i ) ).dup;
					}					
				}
			}

			Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( _listArgs != null )
			{
				char[] text = fromStringz( IupGetAttribute( _listArgs, "VALUE" ) ).dup;
				for( int i = IupGetInt( _listArgs, "COUNT" ); i > 0; -- i )
				{
					char[] itemText = Util.trim( fromStringz( IupGetAttributeId( _listArgs, "", i ) ) ).dup;
					if( itemText.length )
					{
						if( fromStringz( IupGetAttributeId( _listArgs, "", i ) ) == text )
						{
							IupSetAttribute( _listArgs, "VALUE", "" );
							IupSetInt( _listArgs, "REMOVEITEM", i );
						}
					}
					else
					{
						IupSetInt( _listArgs, "REMOVEITEM", i );							
					}
				}
				GLOBAL.recentArgs.length = 0;
				for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
				{
					GLOBAL.recentArgs ~= fromStringz( IupGetAttributeId( _listArgs, "", i ) ).dup;
				}
			}
		}

		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_CLOSE_cb( Ihandle *ih )
	{
		return CArgOptionDialog_btnCancel_cb( ih );
	}	
}
+/