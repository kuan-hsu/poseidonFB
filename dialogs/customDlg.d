module dialogs.customDlg;

private import iup.iup;

private import global, project, actionManager, menu, tools;
private import dialogs.baseDlg, dialogs.singleTextDlg, dialogs.fileDlg;
private import std.string, std.conv;

class CCustomDialog : CBaseDialog
{
private:
	Ihandle*				listTools, treePluginStatus;
	Ihandle*				labelStatus;
	string					paramTip = "Special Parameters:\n%s% = Selected Text\n%f% = Active File Fullpath\n%fn% = Active File Name\n%fdir% = Active File Dir\n%pn% = Active Prj Name\n%p% = Active Prj Files\n%pdir% = Active Prj Dir";
	IupString				_tools, _args;
	IupString[13]			IupItemTitle;
	
	static	CustomTool[13]	editCustomTools;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		listTools = IupList( null );
		IupSetAttributes( listTools, "EXPAND=HORIZONTAL" );
		IupSetStrAttribute( listTools, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( listTools, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetHandle( "listTools_Handle", listTools );
		IupSetCallback( listTools, "ACTION", cast(Icallback) &CCustomDialog_ACTION );
		IupSetCallback( listTools, "DBLCLICK_CB", cast(Icallback) &CCustomDialog_DBLCLICK_CB );
		
		Ihandle* btnToolsAdd = IupButton( null, null );
		IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES,CANFOCUS=NO" );
		IupSetStrAttribute( btnToolsAdd, "TIP", GLOBAL.languageItems["add"].toCString );
		IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CCustomDialog_btnToolsAdd );

		Ihandle* btnToolsErase = IupButton( null, null );
		IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES,CANFOCUS=NO" );
		IupSetStrAttribute( btnToolsErase, "TIP", GLOBAL.languageItems["remove"].toCString );
		IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CCustomDialog_btnToolsErase );
		
		Ihandle* btnToolsUp = IupButton( null, null );
		IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES,CANFOCUS=NO" );
		IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CCustomDialog_btnToolsUp );
		
		Ihandle* btnToolsDown = IupButton( null, null );
		IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES,CANFOCUS=NO" );
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
		version(Windows)
		{
			IupSetStrAttribute( textToolsDir, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textToolsDir, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
		IupSetHandle( "textToolsDir", textToolsDir );
		IupSetCallback( textToolsDir, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_listOptions_EDIT_CB );
		
		Ihandle* btnToolsDir = IupButton( null, null );
		IupSetAttributes( btnToolsDir, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetStrAttribute( btnToolsDir, "TIP", GLOBAL.languageItems["open"].toCString );
		IupSetCallback( btnToolsDir, "ACTION", cast(Icallback) &CCustomDialog_OPENDIR );			

		Ihandle* hBox00 = IupHbox( labelToolsDir, textToolsDir, btnToolsDir, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		
		_args = new IupString( " " ~ GLOBAL.languageItems["args"].toDString ~ ":" );
		Ihandle* labelToolsArgs = IupLabel( _args.toCString );
		IupSetAttributes( labelToolsArgs, "SIZE=54x16" );
		IupSetStrAttribute( labelToolsArgs, "TIP", toStringz( paramTip ) );
		
		Ihandle* textToolsArgs = IupText( null );
		IupSetAttribute( textToolsArgs, "EXPAND", "HORIZONTAL" );
		version(Windows)
		{
			IupSetStrAttribute( textToolsArgs, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textToolsArgs, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
		IupSetHandle( "textToolsArgs", textToolsArgs );
		IupSetCallback( textToolsArgs, "ACTION", cast(Icallback) &CCustomCompilerOptionDialog_listOptions_EDIT_CB );

		Ihandle* hBox01 = IupHbox( labelToolsArgs, textToolsArgs, null );
		IupSetAttribute( hBox01, "ALIGNMENT", "ACENTER" );
		
		
		Ihandle* toggleUseConsole = IupFlatToggle( GLOBAL.languageItems["consoleexe"].toCString );
		IupSetHandle( "toggleUseConsole", toggleUseConsole );
		IupSetCallback( toggleUseConsole, "VALUECHANGED_CB", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
			if( toolsHandle != null )
			{
				int id = IupGetInt( toolsHandle, "VALUE" );
				
				if( IupGetInt( toolsHandle, "VALUE" ) > 0 )
				{
					if(id > 0 )
					{
						Ihandle* useConsoleHandle = IupGetHandle( "toggleUseConsole" );
						if( useConsoleHandle != null )
						{
							CCustomDialog.editCustomTools[id].toggleShowConsole = fSTRz( IupGetAttribute( useConsoleHandle, "VALUE" ) );
						
						}
					}
				}
			}
			
			return IUP_DEFAULT;
		});
	
		
		Ihandle* vBoxDescription = IupVbox( hBox00, hBox01, toggleUseConsole, null );

		if( IupGetInt( listTools, "COUNT" ) > 0 )
		{
			if( CCustomDialog.editCustomTools[1].name.length )
			{
				IupSetStrAttribute( textToolsDir, "VALUE", toStringz( CCustomDialog.editCustomTools[1].dir ) );
				IupSetStrAttribute( textToolsArgs, "VALUE", toStringz( CCustomDialog.editCustomTools[1].args ) );
				IupSetAttribute( listTools, "VALUE", "1" ); // Set Focus
			}
		}


		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");
		
		
		// Plugin manager
		treePluginStatus = IupTree();
		IupSetAttributes( treePluginStatus, "ADDROOT=NO" );
		IupSetStrAttribute( treePluginStatus, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( treePluginStatus, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		
		IupSetHandle( "treePluginStatus_Handle", treePluginStatus );

		
		Ihandle* unloadButton = IupFlatButton( GLOBAL.languageItems["unload"].toCString );
		IupSetAttribute( unloadButton, "SIZE", "40x12" );
		IupSetStrAttribute( unloadButton, "HLCOLOR", null );		
		IupSetCallback( unloadButton, "FLAT_ACTION", cast(Icallback) function( Ihandle* _ih )
		{
			Ihandle* ih = IupGetHandle( "treePluginStatus_Handle" );
			if( ih != null )
			{
				int id = IupGetInt( ih, "VALUE" );

				if( id > -1 )
				{
					string name = fSTRz( IupGetAttributeId( ih, "TITLE", id ) );
					string path = fSTRz( IupGetAttributeId( ih, "USERDATA", id ) );
					
					if( name in GLOBAL.pluginMnager )
					{
						auto p = GLOBAL.pluginMnager[name];
						if( p !is null )
						{
							if( p.getPath() == path )
							{
								IupSetAttribute( ih, "DELNODE", "SELECTED" );
								destroy( p );
								GLOBAL.pluginMnager.remove( name );
							}
						}
						else
						{
							IupSetAttribute( ih, "DELNODE", "SELECTED" );
							GLOBAL.pluginMnager.remove( name );
						}
					}
				}
			}
			
			return IUP_DEFAULT;
		});
		
		Ihandle* vBoxStatus = IupVbox( treePluginStatus, IupHbox( IupFill, unloadButton, null ), null );
		Ihandle* frameListPlugin = IupFrame( vBoxStatus );
		IupSetAttribute( frameListPlugin, "TITLE", GLOBAL.languageItems["pluginstatus"].toCString );

		Ihandle* vBoxLayout = IupVbox( frameList, vBoxDescription, labelSEPARATOR, bottom, frameListPlugin, null );
		IupSetAttributes( vBoxLayout, "ALIGNMENT=ACENTER,MARGIN=5x,GAP=0" );
		
		IupAppend( _dlg, vBoxLayout );

		// Must ADDLEAF after IupMap
		IupMap( _dlg );
		foreach( CPLUGIN p; GLOBAL.pluginMnager )
		{
			if( p !is null )
			{
				IupSetStrAttributeId( treePluginStatus, "ADDLEAF", IupGetInt( treePluginStatus, "COUNT" ) - 1, toStringz( p.getName ) );
				IupSetStrAttributeId( treePluginStatus, "USERDATA", IupGetInt( treePluginStatus, "COUNT" ) - 1, toStringz( p.getPath ) );
			}
		}
		
		for( int i = 1; i < 13; ++ i )
		{
			if( !CCustomDialog.editCustomTools[i].name.length ) break;
			IupSetStrAttribute( listTools, "APPENDITEM", toStringz( CCustomDialog.editCustomTools[i].name ) );
		}
		
		version(Windows) tools.setCaptionTheme( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
	}	

	public:
	
	this( int w, int h, string title, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_tools" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		
		for( int i = 1; i < 13; ++ i )
		{	
			editCustomTools[i].args = GLOBAL.customTools[i].args;
			editCustomTools[i].dir = GLOBAL.customTools[i].dir;
			editCustomTools[i].name = GLOBAL.customTools[i].name;
			editCustomTools[i].toggleShowConsole = GLOBAL.customTools[i].toggleShowConsole;
		}

		createLayout();
		
		IupSetAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["ok"].toCString );
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CCustomDialog_btnApply );
	}

	~this()
	{
		IupSetHandle( "listTools_Handle", null );
		IupSetHandle( "textToolsDir", null );
		IupSetHandle( "textToolsArgs", null );
		IupSetHandle( "toggleUseConsole", null );
		
		destroy( _tools );
		destroy( _args );
		for( int i = 0; i < 13; ++ i )
			if( IupItemTitle[i] !is null ) destroy( IupItemTitle[i] );
	}
	
	override string show( int x, int y )
	{
		IupPopup( _dlg, x, y );
		return null;
	}	
}

extern(C)
{
	private int CCustomDialog_btnApply( Ihandle* ih )
	{
		for( int i = 1; i < 13; ++ i )
		{
			GLOBAL.customTools[i].args = CCustomDialog.editCustomTools[i].args;
			GLOBAL.customTools[i].dir = CCustomDialog.editCustomTools[i].dir;
			GLOBAL.customTools[i].name = CCustomDialog.editCustomTools[i].name;
			GLOBAL.customTools[i].toggleShowConsole = CCustomDialog.editCustomTools[i].toggleShowConsole;
		}
		
		Ihandle* toolsSubMenuHandle = IupGetHandle( "toolsSubMenu" );
		if( toolsSubMenuHandle != null )
		{
			for( int i = IupGetChildCount( toolsSubMenuHandle ); i > 0; --i )
			{
				Ihandle* menuItemHandle = IupGetChild( toolsSubMenuHandle, i );
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
		}
		
		if( toolsSubMenuHandle != null )
		{
			for( int i = 1; i < GLOBAL.customTools.length; ++ i )
			{
				if( GLOBAL.customTools[i].name.length )
				{
					auto IupItemTitle = new IupString( "#" ~ to!(string)( i ) ~ ". " ~ GLOBAL.customTools[i].name );
					Ihandle* _new = IupItem( IupItemTitle.toCString, null );
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
		string fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			if( dirHandle != null ) IupSetStrAttribute( dirHandle, "VALUE", toStringz( fileName ) );
			
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
		Ihandle* useConsoleHandle = IupGetHandle( "toggleUseConsole" );
		
		if( CCustomDialog.editCustomTools[item].name.length )
		{
			if( dirHandle != null ) IupSetStrAttribute( dirHandle, "VALUE", toStringz( CCustomDialog.editCustomTools[item].dir ) );
			if( argsHandle != null ) IupSetStrAttribute( argsHandle, "VALUE", toStringz( CCustomDialog.editCustomTools[item].args ) );
			if( useConsoleHandle != null ) IupSetStrAttribute( useConsoleHandle, "VALUE", toStringz( CCustomDialog.editCustomTools[item].toggleShowConsole ) );
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
				string optionText = strip( fSTRz( new_value ) );
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
	
	private int CCustomDialog_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		string oldName = fromStringz( text ).dup;
	
		scope reNameDlg = new CSingleTextInput( 200, -1, oldName, "255 255 204", 220 );
		
		string newFileName = reNameDlg.show( IupGetInt( ih, "X" ) + 30, IUP_MOUSEPOS );
		if( newFileName.length )
		{
			IupSetStrAttributeId( ih, "", item, toStringz( newFileName ) );
			IupSetInt( ih, "VALUE", item ); // Set Focus
			
			CCustomDialog.editCustomTools[item].name = newFileName;
		}		
		
		return IUP_DEFAULT;
	}

	private int CCustomDialog_btnToolsAdd( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "COUNT" );
		if( index >= 12 )
		{
			IupMessageError( toolsHandle, GLOBAL.languageItems["onlytools"].toCString );
			return IUP_DEFAULT;
		}
		
		scope description = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomtool"].toDString(), GLOBAL.languageItems["tools"].toDString() ~ ":", "120x", null, false, "POSEIDON_MAIN_DIALOG", "icon_newfile" );
		string fileName = description.show( IupGetInt( toolsHandle, "X" ), IUP_MOUSEPOS );
		
		if( fileName.length )
		{
			IupSetStrAttribute( toolsHandle, "APPENDITEM", toStringz( fileName ) );
			CCustomDialog.editCustomTools[++index].name = fileName;
			IupSetInt( toolsHandle, "VALUE", index ); // Set Focus
			
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			Ihandle* argsHandle = IupGetHandle( "textToolsArgs" );
			Ihandle* useConsoleHandle = IupGetHandle( "toggleUseConsole" );
			
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", "" );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", "" );
			if( useConsoleHandle != null ) IupSetAttribute( useConsoleHandle, "VALUE", "OFF" );
		}
		
		IupSetFocus( toolsHandle );
		
		return IUP_DEFAULT;
	}
	
	private int CCustomDialog_btnToolsErase( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "VALUE" );
		if( index < 1 ) return IUP_DEFAULT;
		
		
		string name = fSTRz( IupGetAttribute( toolsHandle, IupGetAttribute( toolsHandle, "VALUE" ) ) );
		if( name in GLOBAL.pluginMnager )
		{
			auto p = GLOBAL.pluginMnager[name];
	
			Ihandle* dirHandle = IupGetHandle( "textToolsDir" );
			string dir = fSTRz( IupGetAttribute( dirHandle, "VALUE" ) );
					
			// Double Confirm......
			if( p.getPath == dir )
			{
				int result = tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, GLOBAL.languageItems["pluginrunningunload"].toDString, "QUESTION", "YESNO", IUP_MOUSEPOS, IUP_MOUSEPOS );
				if( result == 1 )
				{
					Ihandle* treeHandle = IupGetHandle( "treePluginStatus_Handle" );
					if( treeHandle != null )
					{
						for( int i = 0; i < IupGetInt( treeHandle, "COUNT" ); ++ i )
						{
							string _name = fSTRz( IupGetAttributeId( treeHandle, "TITLE", i ) );
							string _path = fSTRz( IupGetAttributeId( treeHandle, "USERDATA", i ) );
							if( name == _name && dir == _path )
							{
								IupSetInt( treeHandle, "VALUE", i );
								IupSetAttributeId( treeHandle, "DELNODE", i, "SELECTED" );
								destroy( p );
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
		Ihandle* useConsoleHandle = IupGetHandle( "toggleUseConsole" );

		int count = IupGetInt( toolsHandle, "COUNT" );
		if( count > 0 )
		{
			if( count >= index ) IupSetInt( toolsHandle, "VALUE", index ); else	IupSetInt( toolsHandle, "VALUE", index - 1 ); // Set Focus
		}
		else
		{
			for( int i = 1; i < 13; ++ i )
			{
				CCustomDialog.editCustomTools[i].name = "";
				CCustomDialog.editCustomTools[i].dir = "";
				CCustomDialog.editCustomTools[i].args = "";
				CCustomDialog.editCustomTools[i].toggleShowConsole = "OFF";
			}
			
			if( dirHandle != null ) IupSetAttribute( dirHandle, "VALUE", null );
			if( argsHandle != null ) IupSetAttribute( argsHandle, "VALUE", null );
			if( useConsoleHandle != null ) IupSetAttribute( useConsoleHandle, "VALUE", "OFF" );
			
			return IUP_DEFAULT;
		}
		
		for( int i = index; i < 12; ++ i )
		{
			CCustomDialog.editCustomTools[i].name = CCustomDialog.editCustomTools[i+1].name;
			CCustomDialog.editCustomTools[i].dir = CCustomDialog.editCustomTools[i+1].dir;
			CCustomDialog.editCustomTools[i].args = CCustomDialog.editCustomTools[i+1].args;
			CCustomDialog.editCustomTools[i].toggleShowConsole = CCustomDialog.editCustomTools[i+1].toggleShowConsole;
		}
		
		CCustomDialog.editCustomTools[12].name = "";
		CCustomDialog.editCustomTools[12].dir = "";
		CCustomDialog.editCustomTools[12].args = "";
		CCustomDialog.editCustomTools[12].toggleShowConsole = "OFF";
		
		int id = IupGetInt( toolsHandle, "VALUE" );
		if( id > 0 && id < 13 )
		{
			if( dirHandle != null ) IupSetStrAttribute( dirHandle, "VALUE", toStringz( CCustomDialog.editCustomTools[id].dir ) );
			if( argsHandle != null ) IupSetStrAttribute( argsHandle, "VALUE", toStringz( CCustomDialog.editCustomTools[id].args ) );
			if( useConsoleHandle != null ) IupSetStrAttribute( useConsoleHandle, "VALUE", toStringz( CCustomDialog.editCustomTools[id].toggleShowConsole ) );
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}	

	private int CCustomDialog_btnToolsUp( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );

		if( itemNumber > 1 )
		{
			char* prevItemText = IupGetAttribute( toolsHandle, toStringz( to!(string)(itemNumber-1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( to!(string)(itemNumber) ) );

			IupSetStrAttribute( toolsHandle, toStringz( to!(string)(itemNumber-1) ), nowItemText );
			IupSetStrAttribute( toolsHandle, toStringz( to!(string)(itemNumber) ), prevItemText );

			IupSetInt( toolsHandle, "VALUE", itemNumber - 1 ); // Set Foucs
			
			CustomTool temp;
			temp.name = CCustomDialog.editCustomTools[itemNumber-1].name;
			temp.dir = CCustomDialog.editCustomTools[itemNumber-1].dir;
			temp.args = CCustomDialog.editCustomTools[itemNumber-1].args;
			temp.toggleShowConsole = CCustomDialog.editCustomTools[itemNumber-1].toggleShowConsole;
			
			CCustomDialog.editCustomTools[itemNumber-1].name = CCustomDialog.editCustomTools[itemNumber].name;
			CCustomDialog.editCustomTools[itemNumber-1].dir = CCustomDialog.editCustomTools[itemNumber].dir;
			CCustomDialog.editCustomTools[itemNumber-1].args = CCustomDialog.editCustomTools[itemNumber].args;
			CCustomDialog.editCustomTools[itemNumber-1].toggleShowConsole = CCustomDialog.editCustomTools[itemNumber].toggleShowConsole;
			
			CCustomDialog.editCustomTools[itemNumber].name = temp.name;
			CCustomDialog.editCustomTools[itemNumber].dir = temp.dir;
			CCustomDialog.editCustomTools[itemNumber].args = temp.args;
			CCustomDialog.editCustomTools[itemNumber].toggleShowConsole = temp.toggleShowConsole;
		}
		
		IupSetFocus( toolsHandle );

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
			char* nextItemText = IupGetAttribute( toolsHandle, toStringz( to!(string)(itemNumber+1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( to!(string)(itemNumber) ) );

			IupSetStrAttribute( toolsHandle, toStringz( to!(string)(itemNumber+1) ), nowItemText );
			IupSetStrAttribute( toolsHandle, toStringz( to!(string)(itemNumber) ), nextItemText );

			IupSetInt( toolsHandle, "VALUE", itemNumber + 1 );  // Set Foucs
			
			CustomTool temp;
			temp.name = CCustomDialog.editCustomTools[itemNumber+1].name;
			temp.dir = CCustomDialog.editCustomTools[itemNumber+1].dir;
			temp.args = CCustomDialog.editCustomTools[itemNumber+1].args;
			temp.toggleShowConsole = CCustomDialog.editCustomTools[itemNumber+1].toggleShowConsole;
			
			CCustomDialog.editCustomTools[itemNumber+1].name = CCustomDialog.editCustomTools[itemNumber].name;
			CCustomDialog.editCustomTools[itemNumber+1].dir = CCustomDialog.editCustomTools[itemNumber].dir;
			CCustomDialog.editCustomTools[itemNumber+1].args = CCustomDialog.editCustomTools[itemNumber].args;
			CCustomDialog.editCustomTools[itemNumber+1].toggleShowConsole = CCustomDialog.editCustomTools[itemNumber].toggleShowConsole;
			
			CCustomDialog.editCustomTools[itemNumber].name = temp.name;
			CCustomDialog.editCustomTools[itemNumber].dir = temp.dir;
			CCustomDialog.editCustomTools[itemNumber].args = temp.args;
			CCustomDialog.editCustomTools[itemNumber].toggleShowConsole = temp.toggleShowConsole;
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}	
}