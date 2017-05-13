module dialogs.customDlg;

private import iup.iup;

private import global, project;
private import dialogs.baseDlg, dialogs.singleTextDlg, dialogs.fileDlg;

private import tango.stdc.stringz, Util = tango.text.Util;
private import Integer = tango.text.convert.Integer;


class CCustomDialog : CBaseDialog
{
	private:
	import				tools;
	Ihandle*			listTools;
	Ihandle*			labelStatus;
	char[]				paramTip = "Special Parameters:\n%s = Selected Text\n%f = Active File Fullpath";

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();


		listTools = IupList( null );
		IupSetAttributes( listTools, "MULTIPLE=NO,EXPAND=YES" );
		IupSetHandle( "listTools_Handle", listTools );
		IupSetCallback( listTools, "ACTION", cast(Icallback) &CCustomDialog_ACTION );
		
		for( int i = 1; i < 10; ++ i )
		{
			if( !GLOBAL.customTools[i].name.toDString.length ) break;
			IupSetAttribute( listTools, toStringz( Integer.toString( i ) ), GLOBAL.customTools[i].name.toCString );
		}
		
		Ihandle* btnToolsAdd = IupButton( null, null );
		IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES" );
		//IupSetHandle( "btnIncludePathAdd_Handle", btnIncludePathAdd );
		IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CCustomDialog_btnToolsAdd );

		Ihandle* btnToolsErase = IupButton( null, null );
		IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES" );
		IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CCustomDialog_btnToolsErase );
		
		Ihandle* btnToolsUp = IupButton( null, null );
		IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES" );
		IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CCustomDialog_btnToolsUp );
		
		Ihandle* btnToolsDown = IupButton( null, null );
		IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES" );
		IupSetCallback( btnToolsDown, "ACTION", cast(Icallback) &CCustomDialog_btnToolsDown );
		
		Ihandle* vBoxButtonTools = IupVbox( btnToolsAdd, btnToolsErase, btnToolsUp, btnToolsDown, null );
		Ihandle* frameList = IupFrame( IupHbox( listTools, vBoxButtonTools, null ) );
		IupSetAttributes( frameList, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		
		
		Ihandle* labelToolsDir = IupLabel( toStringz( GLOBAL.languageItems["tools"].toDString ~ ":" ) );
		IupSetAttributes( labelToolsDir, "SIZE=54x16" );
		Ihandle* textToolsDir = IupText( null );
		IupSetAttribute( textToolsDir, "SIZE", "200x12" );
		IupSetHandle( "textToolsDir", textToolsDir );
		
		Ihandle* btnToolsDir = IupButton( null, null );
		IupSetAttributes( btnToolsDir, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnToolsDir, "ACTION", cast(Icallback) &CCustomDialog_OPENDIR );			
		
		
		//IupSetAttribute( textToolsDir, "EXPAND", "YES" );
		Ihandle* hBox00 = IupHbox( labelToolsDir, textToolsDir, btnToolsDir, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelToolsArgs = IupLabel( toStringz( GLOBAL.languageItems["args"].toDString ~ ":" ) );
		IupSetAttributes( labelToolsArgs, "SIZE=54x16" );
		IupSetAttribute( labelToolsArgs, "TIP", toStringz( paramTip ) );
		
		Ihandle* textToolsArgs = IupText( null );
		IupSetAttribute( textToolsArgs, "SIZE", "210x12" );	
		IupSetHandle( "textToolsArgs", textToolsArgs );

		Ihandle* hBox01 = IupHbox( labelToolsArgs, textToolsArgs, null );
		IupSetAttribute( hBox01, "ALIGNMENT", "ACENTER" );
		
		Ihandle* vBoxDescription = IupVbox( hBox00, hBox01, null );

		if( IupGetInt( listTools, "COUNT" ) > 0 )
		{
			if( GLOBAL.customTools[1].name.toDString.length )
			{
				IupSetAttribute( textToolsDir, "VALUE", GLOBAL.customTools[1].dir.toCString );
				IupSetAttribute( textToolsArgs, "VALUE", GLOBAL.customTools[1].args.toCString );
				IupSetAttribute( listTools, "VALUE", "1" ); // Set Focus
			}
		}


		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");
		Ihandle* vBoxLayout = IupVbox( frameList, vBoxDescription, labelSEPARATOR, bottom, null );
		
		
		IupAppend( _dlg, vBoxLayout );
	}	

	public:
	
	this( int w, int h, char[] title, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
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
		
		IupSetAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["apply"].toCString );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomDialog_btnOK );
	}

	~this()
	{
		IupSetHandle( "listTools_Handle", null );
		IupSetHandle( "textToolsDir", null );
		IupSetHandle( "textToolsArgs", null );
	}
}

extern(C) // Callback for CFindInFilesDialog
{
	int CCustomDialog_btnOK( Ihandle* ih )
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int id = IupGetInt( toolsHandle, "VALUE" );
		if( id > 0 && id < 10 )
		{
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );
			
			GLOBAL.customTools[id].name = IupGetAttribute( toolsHandle, IupGetAttribute( toolsHandle, "VALUE" ) );
			GLOBAL.customTools[id].dir = IupGetAttribute( dirHandle, "VALUE" );
			GLOBAL.customTools[id].args = IupGetAttribute( argsHandle, "VALUE" );
		}
		
		return IUP_DEFAULT;
	}
	
	int CCustomDialog_OPENDIR( Ihandle* ih ) 
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["allfile"].toDString() ~ "|*.*|" );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", toStringz( fileName ) );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomDialog_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
		Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );
		
		/+
		if( CCustomDialog.prevIndex > 0 && CCustomDialog.prevIndex < 6 && CCustomDialog.prevIndex != item )
		{
			GLOBAL.customTools[CCustomDialog.prevIndex].name = fromStringz( IupGetAttribute( ih, toStringz( Integer.toString( CCustomDialog.prevIndex ) ) ) );
			if( dirHandle != null ) GLOBAL.customTools[CCustomDialog.prevIndex].dir = fromStringz( IupGetAttribute( dirHandle, "VALUE" ) );
			if( argsHandle != null ) GLOBAL.customTools[CCustomDialog.prevIndex].args = fromStringz( IupGetAttribute( argsHandle, "VALUE" ) );
		}
		+/
		
		if( GLOBAL.customTools[item].name.toDString.length )
		{
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", GLOBAL.customTools[item].dir.toCString );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", GLOBAL.customTools[item].args.toCString );
		}
		else
		{
			return IUP_DEFAULT;
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomDialog_btnToolsAdd( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "COUNT" );
		if( index >= 5 ) return IUP_DEFAULT;
		
		scope description = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomtool"].toDString(), GLOBAL.languageItems["tools"].toDString() ~ ":", "120x", null, false, "MAIN_DIALOG", "icon_newfile" );
		char[] fileName = description.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
		
		if( fileName.length )
		{
			IupSetAttribute( toolsHandle, "APPENDITEM", toStringz( fileName ) );
			GLOBAL.customTools[++index].name = fileName;
			IupSetAttribute( toolsHandle, "VALUE", toStringz( Integer.toString( index ) ) ); // Set Focus
			
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );
			
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", "" );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", "" );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomDialog_btnToolsErase( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "VALUE" );
		if( index < 1 ) return IUP_DEFAULT;
		
		IupSetAttribute( toolsHandle, "REMOVEITEM", IupGetAttribute( toolsHandle, "VALUE" ) );
		
		Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
		Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );		
		
		if( IupGetInt( toolsHandle, "COUNT" ) > 0 )
		{
			if( index > 1 ) IupSetInt( toolsHandle, "VALUE", index - 1 ); else IupSetInt( toolsHandle, "VALUE", 1 ); // Set Focus
		}
		else
		{
			for( int i = 1; i < 10; ++ i )
			{
				GLOBAL.customTools[i].name = cast(char[]) "";
				GLOBAL.customTools[i].dir = cast(char[]) "";
				GLOBAL.customTools[i].args = cast(char[]) "";
			}
			
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", null );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", null );
			
			return IUP_DEFAULT;
		}
		
		for( int i = index; i < 9; ++ i )
		{
			GLOBAL.customTools[i] = GLOBAL.customTools[i+1];
		}
		
		GLOBAL.customTools[9].name = cast(char[]) "";
		GLOBAL.customTools[9].dir = cast(char[]) "";
		GLOBAL.customTools[9].args = cast(char[]) "";
		
		int id = IupGetInt( toolsHandle, "VALUE" );
		if( id > 0 && id < 10 )
		{
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", GLOBAL.customTools[id].dir.toCString );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", GLOBAL.customTools[id].args.toCString );
		}	

		return IUP_DEFAULT;
	}	

	private int CCustomDialog_btnToolsUp( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );

		if( itemNumber > 1 )
		{
			char* prevItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber-1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber-1) ), nowItemText );
			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ), prevItemText );

			IupSetAttribute( toolsHandle, "VALUE", toStringz( Integer.toString(itemNumber-1) ) ); // Set Foucs
			
			CustomTool temp;
			temp.name = GLOBAL.customTools[itemNumber-1].name;
			temp.dir = GLOBAL.customTools[itemNumber-1].dir;
			temp.args = GLOBAL.customTools[itemNumber-1].args;
			
			GLOBAL.customTools[itemNumber-1].name = GLOBAL.customTools[itemNumber].name;
			GLOBAL.customTools[itemNumber-1].dir = GLOBAL.customTools[itemNumber].dir;
			GLOBAL.customTools[itemNumber-1].args = GLOBAL.customTools[itemNumber].args;
			
			GLOBAL.customTools[itemNumber].name = temp.name;
			GLOBAL.customTools[itemNumber].dir = temp.dir;
			GLOBAL.customTools[itemNumber].args = temp.args;
			
			/*
			CustomTool temp = GLOBAL.customTools[index-1];
			GLOBAL.customTools[index-1] = GLOBAL.customTools[index];
			GLOBAL.customTools[index] = temp;
			*/
		}

		return IUP_DEFAULT;
	}
	
	private int CCustomDialog_btnToolsDown( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
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
			
			CustomTool temp;
			temp.name = GLOBAL.customTools[itemNumber+1].name;
			temp.dir = GLOBAL.customTools[itemNumber+1].dir;
			temp.args = GLOBAL.customTools[itemNumber+1].args;
			
			GLOBAL.customTools[itemNumber+1].name = GLOBAL.customTools[itemNumber].name;
			GLOBAL.customTools[itemNumber+1].dir = GLOBAL.customTools[itemNumber].dir;
			GLOBAL.customTools[itemNumber+1].args = GLOBAL.customTools[itemNumber].args;
			
			GLOBAL.customTools[itemNumber].name = temp.name;
			GLOBAL.customTools[itemNumber].dir = temp.dir;
			GLOBAL.customTools[itemNumber].args = temp.args;
		}

		return IUP_DEFAULT;
	}	
}