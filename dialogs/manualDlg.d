module dialogs.manualDlg;

private import iup.iup;

private import global, project, actionManager, menu, tools;
private import dialogs.baseDlg, dialogs.singleTextDlg, dialogs.fileDlg;
private import std.string, std.conv, Array = std.array;

class CManualDialog : CBaseDialog
{
private:
	Ihandle*			listManuals;
	Ihandle*			labelStatus;
	IupString			manualpathString;
	
	static	string[]	tempManuals;
	
	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		listManuals = IupList( null );
		IupSetAttributes( listManuals, "EXPAND=HORIZONTAL" );
		IupSetHandle( "listManuals_Handle", listManuals );
		IupSetCallback( listManuals, "ACTION", cast(Icallback) &CManualDialog_listManuals_ACTION );

		Ihandle* btnToolsAdd = IupButton( null, null );
		IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES" );
		IupSetAttribute( btnToolsAdd, "TIP", GLOBAL.languageItems["add"].toCString );
		IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CManualDialog_btnToolsAdd_ACTION );

		Ihandle* btnToolsErase = IupButton( null, null );
		IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES" );
		IupSetAttribute( btnToolsErase, "TIP", GLOBAL.languageItems["remove"].toCString );
		IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CManualDialog_btnToolsErase_ACTION );
		
		Ihandle* btnToolsUp = IupButton( null, null );
		IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES" );
		IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CManualDialog_btnToolsUp_ACTION );
		
		Ihandle* btnToolsDown = IupButton( null, null );
		IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES" );
		IupSetCallback( btnToolsDown, "ACTION", cast(Icallback) &CManualDialog_btnToolsDown_ACTION );
		
		Ihandle* vBoxButtonTools = IupVbox( btnToolsAdd, btnToolsErase, btnToolsUp, btnToolsDown, null );

		Ihandle* listHbox = IupHbox( listManuals, vBoxButtonTools, null );
		IupSetAttributes( listHbox, "NORMALIZESIZE=VERTICAL" );
		
		Ihandle* frameList = IupFrame( listHbox );
		IupSetAttributes( frameList, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		
		manualpathString = new IupString( " " ~ GLOBAL.languageItems["manualpath"].toDString ~ ":" );
		Ihandle* labelManualDir = IupLabel( manualpathString.toCString );
		IupSetAttributes( labelManualDir, "ALIGNMENT=ARIGHT" );

		Ihandle* textManualDir = IupText( null );
		IupSetAttribute( textManualDir, "EXPAND", "HORIZONTAL" );
		IupSetHandle( "textManualDir", textManualDir );
		IupSetCallback( textManualDir, "ACTION", cast(Icallback) &CManualDialog_textManualDir_ACTION );
		
		Ihandle* btnManualDir = IupButton( null, null );
		IupSetAttributes( btnManualDir, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetAttribute( btnManualDir, "TIP", GLOBAL.languageItems["open"].toCString );
		IupSetCallback( btnManualDir, "ACTION", cast(Icallback) &CManualDialog_btnManualDir_ACTION );			
		
		
		Ihandle* hBox00 = IupHbox( labelManualDir, textManualDir, btnManualDir, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");

	
		Ihandle* vBoxLayout = IupVbox( frameList, hBox00, labelSEPARATOR, bottom, null );
		
		IupAppend( _dlg, vBoxLayout );
		IupMap( _dlg );
		foreach( s; GLOBAL.manuals )
		{
			string[] splitWord = Array.split( s, "," );
			if( splitWord.length == 2 ) IupSetStrAttribute( listManuals, "APPENDITEM", toStringz( splitWord[0] ) );
		}
		CManualDialog.tempManuals = GLOBAL.manuals;
	}	

public:
	
	this( int w, int h, string title, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_fbmanual" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );

		createLayout();
		
		IupSetAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["ok"].toCString );
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CManualDialog_btnApply_ACTION );
	}

	~this()
	{
		IupSetHandle( "listManuals_Handle", null );
		IupSetHandle( "textManualDir", null );
		
		CManualDialog.tempManuals.length = 0;
		destroy( manualpathString );
	}
	
	override string show( int x, int y )
	{
		IupPopup( _dlg, x, y );
		return null;
	}	
}


extern(C)
{
	private int CManualDialog_btnApply_ACTION( Ihandle* ih )
	{
		GLOBAL.manuals = CManualDialog.tempManuals;
		
		Ihandle* optionsMenuHandle = IupGetHandle( "optionsMenu" );
		if( optionsMenuHandle != null )
		{
			for( int i = IupGetChildCount( optionsMenuHandle ); i > 0; --i )
			{
				Ihandle* menuItemHandle = IupGetChild( optionsMenuHandle, i );
				if( menuItemHandle != null )
				{
					string menuItenTitle = fSTRz( IupGetAttribute( menuItemHandle, "TITLE" ) );
					if( menuItenTitle.length )
					{
						if( menuItenTitle[0] == '#' ) IupDestroy( menuItemHandle ); else break;
					}
					else
						break;
				}
			}

			for( int i = 0; i < GLOBAL.manuals.length; ++ i )
			{
				string[] splitWords = Array.split( GLOBAL.manuals[i], "," );
				if( splitWords.length == 2 )
				{
					auto itemTitle = new IupString( "#" ~ to!(string)( i + 1 ) ~ ". " ~ splitWords[0] );
					Ihandle* _new = IupItem( itemTitle.toCString, null );
					IupSetCallback( _new, "ACTION", cast(Icallback) &menu.manual_menu_click_cb );
					IupAppend( optionsMenuHandle, _new );
					IupMap( _new );
				}
			}
		}		
	
		return IUP_CLOSE;
	}
	

	private int CManualDialog_btnManualDir_ACTION( Ihandle* ih ) 
	{
		Ihandle* listHandle = IupGetHandle( "listManuals_Handle" );
		
		if( listHandle != null )
		{
			if( IupGetInt( listHandle, "COUNT" ) > 0 )
			{
				scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", "CHM Files|*.chm|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*" );
				string fileName = fileSecectDlg.getFileName();

				if( fileName.length )
				{
					Ihandle* dirHandle = IupGetHandle( "textManualDir" );
					if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", toStringz( fileName ) );
					
					int id = IupGetInt( listHandle, "VALUE" );
					if( id > 0 && id <= CManualDialog.tempManuals.length )
					{
						string[] splitWord = Array.split( CManualDialog.tempManuals[id-1], "," );
						if( splitWord.length == 2 )
						{
							// Double Check
							if( splitWord[0] == fromStringz( IupGetAttributeId( listHandle, "", id ) ) ) CManualDialog.tempManuals[id-1] = splitWord[0] ~ "," ~ fileName;
						}				
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}

	
	private int CManualDialog_listManuals_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		Ihandle* dirHandle = IupGetHandle( "textManualDir" );
		
		if( dirHandle != null )
		{
			if( item <= CManualDialog.tempManuals.length )
			{
				string[] splitWord = Array.split( CManualDialog.tempManuals[item-1], "," );
				if( splitWord.length == 2 )
				{
					// Double Check
					if( splitWord[0] == fromStringz( text ) ) IupSetStrAttribute( dirHandle, "VALUE", toStringz( splitWord[1] ) );
				}
			}
		}
		
		return IUP_DEFAULT;
	}
	
	
	private int CManualDialog_textManualDir_ACTION( Ihandle *ih, int c, char *new_value )
	{
		Ihandle* listHandle = IupGetHandle( "listManuals_Handle" );
		if( listHandle != null )
		{
			int id = IupGetInt( listHandle, "VALUE" );
			if( id > 0 )
			{
				string dirText = strip( fromStringz( new_value ) ).dup;
				
				string[] splitWord = Array.split( CManualDialog.tempManuals[id-1], "," );
				if( splitWord.length == 2 )	CManualDialog.tempManuals[id-1] = splitWord[0] ~ "," ~ dirText;
			}
		}
		
		return IUP_DEFAULT;
	}	
	
	
	private int CManualDialog_btnToolsAdd_ACTION( Ihandle* ih ) 
	{
		scope description = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["manual"].toDString(), GLOBAL.languageItems["name"].toDString() ~ ":", "120x", null, false, "POSEIDON_MAIN_DIALOG", "icon_newfile" );
		string fileName = description.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
		
		if( fileName.length )
		{
			Ihandle* listHandle = IupGetHandle( "listManuals_Handle" );
			
			IupSetAttribute( listHandle, "APPENDITEM", toStringz( fileName ) );
			CManualDialog.tempManuals ~= ( fileName ~ "," );
			
			IupSetInt( listHandle, "VALUE", cast(int) CManualDialog.tempManuals.length ); // Set Focus
			
			Ihandle* dirHandle = IupGetHandle( "textManualDir" );
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", "" );
		}
		
		return IUP_DEFAULT;
	}
	

	private int CManualDialog_btnToolsErase_ACTION( Ihandle* ih ) 
	{
		Ihandle* listHandle = IupGetHandle( "listManuals_Handle" );
		
		if( listHandle != null )
		{		
			int id = IupGetInt( listHandle, "VALUE" );
			if( id < 1 || id > CManualDialog.tempManuals.length ) return IUP_DEFAULT;
		
			string name = fromStringz( IupGetAttributeId( listHandle, "", id ) ).dup;
			
			// Double Check
			string[] splitWord = Array.split( CManualDialog.tempManuals[id-1], "," );
			if( splitWord.length == 2 )
			{
				// Double Check
				if( splitWord[0] == name )
				{
					IupSetInt( listHandle, "REMOVEITEM", id );
					id --;
				
					string[] _tempManuals;
					for( int i = 0; i < CManualDialog.tempManuals.length; ++ i )
					{
						if( i != id ) _tempManuals ~= CManualDialog.tempManuals[i];
					}
					
					CManualDialog.tempManuals = _tempManuals;
					
					Ihandle* dirHandle = IupGetHandle( "textManualDir" );
					if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", "" );
				}
			}
		}

		return IUP_DEFAULT;
	}	


	private int CManualDialog_btnToolsUp_ACTION( Ihandle* ih ) 
	{
		Ihandle* listHandle = IupGetHandle( "listManuals_Handle" );
		if( listHandle != null )
		{
			int itemNumber = IupGetInt( listHandle, "VALUE" );

			if( itemNumber > 1 )
			{
				char* prevItemText = IupGetAttributeId( listHandle, "", itemNumber -1 );
				char* nowItemText = IupGetAttributeId( listHandle, "", itemNumber );

				IupSetStrAttributeId( listHandle, "", itemNumber - 1, nowItemText );
				IupSetStrAttributeId( listHandle, "", itemNumber, prevItemText );

				IupSetInt( listHandle, "VALUE", itemNumber - 1 ); // Set Foucs
				
				string temp = CManualDialog.tempManuals[itemNumber-2];
				CManualDialog.tempManuals[itemNumber-2] = CManualDialog.tempManuals[itemNumber-1];
				CManualDialog.tempManuals[itemNumber-1] = temp;
			}
		}

		return IUP_DEFAULT;
	}
	
	
	private int CManualDialog_btnToolsDown_ACTION( Ihandle* ih ) 
	{
		Ihandle* listHandle = IupGetHandle( "listManuals_Handle" );
		if( listHandle != null )
		{
			int itemNumber = IupGetInt( listHandle, "VALUE" );
			int itemCount = IupGetInt( listHandle, "COUNT" );

			if( itemNumber < itemCount )
			{
				char* nextItemText = IupGetAttributeId( listHandle, "", itemNumber + 1 );
				char* nowItemText = IupGetAttributeId( listHandle, "", itemNumber );

				IupSetStrAttributeId( listHandle, "", itemNumber + 1, nowItemText );
				IupSetStrAttributeId( listHandle, "", itemNumber, nextItemText );

				IupSetInt( listHandle, "VALUE", itemNumber + 1 );  // Set Foucs
				

				string temp = CManualDialog.tempManuals[itemNumber];
				CManualDialog.tempManuals[itemNumber] = CManualDialog.tempManuals[itemNumber-1];
				CManualDialog.tempManuals[itemNumber-1] = temp;
			}
		}

		return IUP_DEFAULT;
	}
}