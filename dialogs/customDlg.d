module dialogs.customDlg;

private import iup.iup;

private import global, project, actionManager, menu, tools;
private import dialogs.baseDlg, dialogs.singleTextDlg, dialogs.fileDlg;

private import tango.stdc.stringz, Util = tango.text.Util, tango.io.FilePath;
private import Integer = tango.text.convert.Integer;


class CCustomDialog : CBaseDialog
{
	private:
	Ihandle*				listTools, treePluginStatus;
	Ihandle*				labelStatus;
	char[]					paramTip = "Special Parameters:\n%s% = Selected Text\n%f% = Active File Fullpath\n%fn% = Active File Name\n%fdir% = Active File Dir\n%pn% = Active Prj Name\n%p% = Active Prj Files\n%pdir% = Active Prj Dir";
	IupString				_tools, _args;
	
	
	static	CustomTool[13]	editCustomTools;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		listTools = IupList( null );
		IupSetAttributes( listTools, "EXPAND=HORIZONTAL" );
		IupSetHandle( "listTools_Handle", listTools );
		IupSetCallback( listTools, "ACTION", cast(Icallback) &CCustomDialog_ACTION );

		
		Ihandle* btnToolsAdd = IupButton( null, null );
		IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES" );
		IupSetAttribute( btnToolsAdd, "TIP", GLOBAL.languageItems["add"].toCString );
		IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CCustomDialog_btnToolsAdd );

		Ihandle* btnToolsErase = IupButton( null, null );
		IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES" );
		IupSetAttribute( btnToolsErase, "TIP", GLOBAL.languageItems["remove"].toCString );
		IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CCustomDialog_btnToolsErase );
		
		Ihandle* btnToolsUp = IupButton( null, null );
		IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES" );
		IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CCustomDialog_btnToolsUp );
		
		Ihandle* btnToolsDown = IupButton( null, null );
		IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES" );
		IupSetCallback( btnToolsDown, "ACTION", cast(Icallback) &CCustomDialog_btnToolsDown );
		
		Ihandle* vBoxButtonTools = IupVbox( btnToolsAdd, btnToolsErase, btnToolsUp, btnToolsDown, null );
		
		Ihandle* listHbox = IupHbox( listTools, vBoxButtonTools, null );
		IupSetAttributes( listHbox, "NORMALIZESIZE=VERTICAL" );
		
		Ihandle* frameList = IupFrame( listHbox );
		IupSetAttributes( frameList, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		
		
		
		
		_tools = new IupString( " " ~ GLOBAL.languageItems["tools"].toDString ~ ":" );
		Ihandle* labelToolsDir = IupLabel( _tools.toCString );
		IupSetAttributes( labelToolsDir, "SIZE=54x16" );
		
		Ihandle* textToolsDir = IupText( null );
		IupSetAttribute( textToolsDir, "EXPAND", "HORIZONTAL" );
		IupSetHandle( "textToolsDir", textToolsDir );
		IupSetCallback( textToolsDir, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_listOptions_EDIT_CB );
		
		Ihandle* btnToolsDir = IupButton( null, null );
		IupSetAttributes( btnToolsDir, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetAttribute( btnToolsDir, "TIP", GLOBAL.languageItems["open"].toCString );
		IupSetCallback( btnToolsDir, "ACTION", cast(Icallback) &CCustomDialog_OPENDIR );			
		
		
		//IupSetAttribute( textToolsDir, "EXPAND", "YES" );
		Ihandle* hBox00 = IupHbox( labelToolsDir, textToolsDir, btnToolsDir, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		
		_args = new IupString( " " ~ GLOBAL.languageItems["args"].toDString ~ ":" );
		Ihandle* labelToolsArgs = IupLabel( _args.toCString );
		IupSetAttributes( labelToolsArgs, "SIZE=54x16" );
		IupSetAttribute( labelToolsArgs, "TIP", toStringz( paramTip ) );
		
		Ihandle* textToolsArgs = IupText( null );
		//IupSetAttribute( textToolsArgs, "SIZE", "-1x12" );
		IupSetAttribute( textToolsArgs, "EXPAND", "HORIZONTAL" );
		IupSetHandle( "textToolsArgs", textToolsArgs );
		IupSetCallback( textToolsArgs, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_listOptions_EDIT_CB );

		Ihandle* hBox01 = IupHbox( labelToolsArgs, textToolsArgs, null );
		IupSetAttribute( hBox01, "ALIGNMENT", "ACENTER" );
		
		Ihandle* vBoxDescription = IupVbox( hBox00, hBox01, null );

		if( IupGetInt( listTools, "COUNT" ) > 0 )
		{
			if( CCustomDialog.editCustomTools[1].name.toDString.length )
			{
				IupSetAttribute( textToolsDir, "VALUE", CCustomDialog.editCustomTools[1].dir.toCString );
				IupSetAttribute( textToolsArgs, "VALUE", CCustomDialog.editCustomTools[1].args.toCString );
				IupSetAttribute( listTools, "VALUE", "1" ); // Set Focus
			}
		}


		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");
		
		
		// Plugin manager
		treePluginStatus = IupTree();
		IupSetAttributes( treePluginStatus, "ADDROOT=NO" );
		IupSetHandle( "treePluginStatus_Handle", treePluginStatus );

		
		Ihandle* unloadButton = IupButton( GLOBAL.languageItems["unload"].toCString, null );
		IupSetAttribute( unloadButton, "SIZE", "40x12" );
		IupSetCallback( unloadButton, "ACTION", cast(Icallback) function( Ihandle* _ih )
		{
			Ihandle* ih = IupGetHandle( "treePluginStatus_Handle" );
			if( ih != null )
			{
				int id = IupGetInt( ih, "VALUE" );

				if( id > -1 )
				{
					char[] name = fromStringz( IupGetAttributeId( ih, "TITLE", id ) );
					char[] path = fromStringz( IupGetAttributeId( ih, "USERDATA", id ) );
					
					if( name in GLOBAL.pluginMnager )
					{
						auto p = GLOBAL.pluginMnager[name];
						if( p.getPath() == path )
						{
							IupSetAttribute( ih, "DELNODE", "SELECTED" );
							delete p;
							GLOBAL.pluginMnager.remove( name );
						}
					}
				}
			}
		});
		
		Ihandle* vBoxStatus = IupVbox( treePluginStatus, IupHbox( IupFill, unloadButton, null ), null );
		Ihandle* frameListPlugin = IupFrame( vBoxStatus );
		IupSetAttribute( frameListPlugin, "TITLE", GLOBAL.languageItems["pluginstatus"].toCString );

		Ihandle* vBoxLayout = IupVbox( frameList, vBoxDescription, labelSEPARATOR, bottom, frameListPlugin, null );
		
		IupAppend( _dlg, vBoxLayout );

		// Must ADDLEAF after IupMap
		IupMap( _dlg );
		foreach( CPLUGIN p; GLOBAL.pluginMnager )
		{
			auto fp = new IupString( p.getPath );
			IupSetAttributeId( treePluginStatus, "ADDLEAF", IupGetInt( treePluginStatus, "COUNT" ) - 1, toStringz( p.getName ) );
			IupSetAttributeId( treePluginStatus, "USERDATA", IupGetInt( treePluginStatus, "COUNT" ) - 1, fp.toCString );
		}
		
		for( int i = 1; i < 13; ++ i )
		{
			if( !CCustomDialog.editCustomTools[i].name.toDString.length ) break;
			IupSetAttribute( listTools, "APPENDITEM", CCustomDialog.editCustomTools[i].name.toCString );
		}		
	}	

	public:
	
	this( int w, int h, char[] title, bool bResize = false, char[] parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_tools" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		
		for( int i = 1; i < 13; ++ i )
		{	
			if( editCustomTools[i].args is null ) editCustomTools[i].args = new IupString( GLOBAL.customTools[i].args.toDString ); else editCustomTools[i].args = GLOBAL.customTools[i].args.toDString;
			if( editCustomTools[i].dir is null ) editCustomTools[i].dir = new IupString( GLOBAL.customTools[i].dir.toDString ); else editCustomTools[i].dir = GLOBAL.customTools[i].dir.toDString;
			if( editCustomTools[i].name is null ) editCustomTools[i].name = new IupString( GLOBAL.customTools[i].name.toDString ); else editCustomTools[i].name = GLOBAL.customTools[i].name.toDString;
		}

		createLayout();
		
		IupSetAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["ok"].toCString );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CCustomDialog_btnApply );
	}

	~this()
	{
		IupSetHandle( "listTools_Handle", null );
		IupSetHandle( "textToolsDir", null );
		IupSetHandle( "textToolsArgs", null );
		
		delete _tools;
		delete _args;
	}
	
	char[] show( int x, int y )
	{
		IupPopup( _dlg, x, y );
		return null;
	}	
}

extern(C) // Callback for CFindInFilesDialog
{
	private int CCustomDialog_btnApply( Ihandle* ih )
	{
		for( int i = 1; i < 13; ++ i )
		{
			GLOBAL.customTools[i].args = CCustomDialog.editCustomTools[i].args.toDString;
			GLOBAL.customTools[i].dir = CCustomDialog.editCustomTools[i].dir.toDString;
			GLOBAL.customTools[i].name = CCustomDialog.editCustomTools[i].name.toDString;
		}
		
		Ihandle* toolsSubMenuHandle = IupGetHandle( "toolsSubMenu" );
		if( toolsSubMenuHandle != null )
		{
			for( int i = IupGetChildCount( toolsSubMenuHandle ); i > 0; --i )
			{
				Ihandle* menuItemHandle = IupGetChild( toolsSubMenuHandle, i );
				if( menuItemHandle != null )
				{
					//if( fromStringz( IupGetAttribute( menuItemHandle, "TITLE" ) ).length )
					if( IupGetAttribute( menuItemHandle, "TITLE" ) != null && IupGetAttribute( menuItemHandle, "TITLE" ) != IupGetAttribute( toolsSubMenuHandle, "TITLE" ) && IupGetAttribute( menuItemHandle, "IMAGE" ) == null )
						IupDestroy( menuItemHandle );
					else
						break;
				}
			}
		}
		
		if( toolsSubMenuHandle != null )
		{
			for( int i = 1; i < GLOBAL.customTools.length; ++ i )
			{
				if( GLOBAL.customTools[i].name.toDString.length )
				{
					Ihandle* _new = IupItem( toStringz( Integer.toString( i ) ~ ". " ~ GLOBAL.customTools[i].name.toDString ), null );
					IupSetCallback( _new, "ACTION", cast(Icallback) &menu.customtool_menu_click_cb );
					IupAppend( toolsSubMenuHandle, _new );
					IupMap( _new );
				}
			}
		}		
		
		return IUP_CLOSE;	
	}
	
	private int CCustomDialog_OPENDIR( Ihandle* ih ) 
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["allfile"].toDString() ~ "|*.*" );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", toStringz( fileName ) );
			
			Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
			if( toolsHandle != null )
			{
				int id = IupGetInt( toolsHandle, "VALUE" );
				if( IupGetInt( toolsHandle, "VALUE" ) > 0 )	CCustomDialog.editCustomTools[id].dir = fileName;
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomDialog_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
		Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );
		
		if( CCustomDialog.editCustomTools[item].name.toDString.length )
		{
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", CCustomDialog.editCustomTools[item].dir.toCString );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", CCustomDialog.editCustomTools[item].args.toCString );
		}
		else
		{
			return IUP_DEFAULT;
		}
		
		return IUP_DEFAULT;
	}
	
	private int CCustomCompilerOptionDialog_listOptions_EDIT_CB( Ihandle *ih, int c, char *new_value )
	{
		Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
		Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );
		
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle != null )
		{
			int id = IupGetInt( toolsHandle, "VALUE" );
			
			if( IupGetInt( toolsHandle, "VALUE" ) > 0 )
			{
				char[] optionText = Util.trim( fromStringz( new_value ) ).dup;
				if(id > 0 )
				{
					if( ih == dirHandle )
						CCustomDialog.editCustomTools[id].dir = optionText;
					else
						CCustomDialog.editCustomTools[id].args = optionText;
				}
			}
		}
		
		return IUP_DEFAULT;
	}	
	

	private int CCustomDialog_btnToolsAdd( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "COUNT" );
		if( index >= 5 ) return IUP_DEFAULT;
		
		scope description = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomtool"].toDString(), GLOBAL.languageItems["tools"].toDString() ~ ":", "120x", null, false, "POSEIDON_MAIN_DIALOG", "icon_newfile" );
		char[] fileName = description.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
		
		if( fileName.length )
		{
			IupSetAttribute( toolsHandle, "APPENDITEM", toStringz( fileName ) );
			CCustomDialog.editCustomTools[++index].name = fileName;
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
		
		
		char[] name = fromStringz( IupGetAttribute( toolsHandle, IupGetAttribute( toolsHandle, "VALUE" ) ) ).dup;
		if( name in GLOBAL.pluginMnager )
		{
			auto p = GLOBAL.pluginMnager[name];
	
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			char[] dir = fromStringz( IupGetAttribute( dirHandle, "VALUE" ) ).dup;
					
			// Double Confirm......
			if( p.getPath == dir )
			{
				int result = IupMessageAlarm( null, GLOBAL.languageItems["alarm"].toCString, GLOBAL.languageItems["pluginrunningunload"].toCString, "YESNO" );
				if( result == 1 )
				{
					Ihandle* treeHandle = IupGetHandle( "treePluginStatus_Handle" );
					if( treeHandle != null )
					{
						for( int i = 0; i < IupGetInt( treeHandle, "COUNT" ); ++ i )
						{
							char[] _name = fromStringz( IupGetAttributeId( treeHandle, "TITLE", i ) );
							char[] _path = fromStringz( IupGetAttributeId( treeHandle, "USERDATA", i ) );
							
							if( name == _name && dir == _path )
							{
								IupSetInt( treeHandle, "VALUE", i );
								IupSetAttributeId( treeHandle, "DELNODE", i, "SELECTED" );
								delete p;
								GLOBAL.pluginMnager.remove( name );
								break;
							}
						}
					}				
				}
			}
		}
		
		
		IupSetAttribute( toolsHandle, "REMOVEITEM", IupGetAttribute( toolsHandle, "VALUE" ) );
		
		Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
		Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );		
		
		if( IupGetInt( toolsHandle, "COUNT" ) > 0 )
		{
			if( index > 1 ) IupSetInt( toolsHandle, "VALUE", index - 1 ); else IupSetInt( toolsHandle, "VALUE", 1 ); // Set Focus
		}
		else
		{
			for( int i = 1; i < 13; ++ i )
			{
				CCustomDialog.editCustomTools[i].name = cast(char[]) "";
				CCustomDialog.editCustomTools[i].dir = cast(char[]) "";
				CCustomDialog.editCustomTools[i].args = cast(char[]) "";
			}
			
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", null );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", null );
			
			return IUP_DEFAULT;
		}
		
		for( int i = index; i < 12; ++ i )
		{
			CCustomDialog.editCustomTools[i].name = CCustomDialog.editCustomTools[i+1].name.toDString;
			CCustomDialog.editCustomTools[i].dir = CCustomDialog.editCustomTools[i+1].dir.toDString;
			CCustomDialog.editCustomTools[i].args = CCustomDialog.editCustomTools[i+1].args.toDString;
		}
		
		CCustomDialog.editCustomTools[12].name = cast(char[]) "";
		CCustomDialog.editCustomTools[12].dir = cast(char[]) "";
		CCustomDialog.editCustomTools[12].args = cast(char[]) "";
		
		int id = IupGetInt( toolsHandle, "VALUE" );
		if( id > 0 && id < 13 )
		{
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", CCustomDialog.editCustomTools[id].dir.toCString );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", CCustomDialog.editCustomTools[id].args.toCString );
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
			temp.name = CCustomDialog.editCustomTools[itemNumber-1].name;
			temp.dir = CCustomDialog.editCustomTools[itemNumber-1].dir;
			temp.args = CCustomDialog.editCustomTools[itemNumber-1].args;
			
			CCustomDialog.editCustomTools[itemNumber-1].name = CCustomDialog.editCustomTools[itemNumber].name;
			CCustomDialog.editCustomTools[itemNumber-1].dir = CCustomDialog.editCustomTools[itemNumber].dir;
			CCustomDialog.editCustomTools[itemNumber-1].args = CCustomDialog.editCustomTools[itemNumber].args;
			
			CCustomDialog.editCustomTools[itemNumber].name = temp.name;
			CCustomDialog.editCustomTools[itemNumber].dir = temp.dir;
			CCustomDialog.editCustomTools[itemNumber].args = temp.args;
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
			temp.name = CCustomDialog.editCustomTools[itemNumber+1].name;
			temp.dir = CCustomDialog.editCustomTools[itemNumber+1].dir;
			temp.args = CCustomDialog.editCustomTools[itemNumber+1].args;
			
			CCustomDialog.editCustomTools[itemNumber+1].name = CCustomDialog.editCustomTools[itemNumber].name;
			CCustomDialog.editCustomTools[itemNumber+1].dir = CCustomDialog.editCustomTools[itemNumber].dir;
			CCustomDialog.editCustomTools[itemNumber+1].args = CCustomDialog.editCustomTools[itemNumber].args;
			
			CCustomDialog.editCustomTools[itemNumber].name = temp.name;
			CCustomDialog.editCustomTools[itemNumber].dir = temp.dir;
			CCustomDialog.editCustomTools[itemNumber].args = temp.args;
		}

		return IUP_DEFAULT;
	}	
}