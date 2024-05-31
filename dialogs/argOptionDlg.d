module dialogs.argOptionDlg;

private import iup.iup;
private import global, project, actionManager, tools;
private import dialogs.baseDlg, dialogs.singleTextDlg, dialogs.fileDlg;
private import std.string, std.conv;

class CArgOptionDialog : CBaseDialog
{
	private:
	Ihandle*			listTools, listCompiler, listOptions, listArgs, btnCompilerPath;
	Ihandle*			hBoxCompiler, hBoxOptions, hBoxArgs;
	Ihandle*			labelStatus;
	int					QuickMode;
	string[]			_recentOptions, _recentArgs, _recentCompilers;
	
	static string[]		tempCustomCompilerOptions;
	
	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		if( QuickMode )
		{
			IupSetStrAttribute( btnOK, "TITLE", GLOBAL.languageItems["go"].toCString );
			IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
			IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
			IupSetCallback( btnHiddenOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
			IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
			IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
		}
		else
		{
			IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CArgOptionDialog_btnOKtoApply_cb );
			IupSetCallback( btnHiddenOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOKtoApply_cb );
		}
		
		version(Windows) listTools = IupFlatList(); else listTools = IupList( null );
		IupSetAttributes( listTools, "MULTIPLE=NO,EXPAND=YES" );
		IupSetHandle( "CArgOptionDialog_listTools_Handle", listTools );
		version(Windows) IupSetCallback( listTools, "FLAT_ACTION", cast(Icallback) &CArgOptionDialog_ACTION ); else IupSetCallback( listTools, "ACTION", cast(Icallback) &CArgOptionDialog_ACTION );
		
		for( int i = 0; i < GLOBAL.compilerSettings.customCompilerOptions.length; ++ i )
		{
			CArgOptionDialog.tempCustomCompilerOptions ~= GLOBAL.compilerSettings.customCompilerOptions[i];
			auto pos = lastIndexOf( GLOBAL.compilerSettings.customCompilerOptions[i], "%::% " );
			if( pos > 0 )
			{
				string Name = GLOBAL.compilerSettings.customCompilerOptions[i][pos+5..$];
				IupSetStrAttributeId( listTools, "", i+1, toStringz( Name ) );
			}
		}
		
		Ihandle* frameList;
		if( !QuickMode )
		{
			IupSetCallback( listTools, "DBLCLICK_CB", cast(Icallback) &CArgOptionDialog_DBLCLICK_CB );
			
			Ihandle* btnToolsAdd = IupButton( null, null );
			IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES,CANFOCUS=NO" );
			IupSetStrAttribute( btnToolsAdd, "TIP", GLOBAL.languageItems["add"].toCString );
			IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsAdd );

			Ihandle* btnToolsErase = IupButton( null, null );
			IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES,CANFOCUS=NO" );
			IupSetStrAttribute( btnToolsErase, "TIP", GLOBAL.languageItems["remove"].toCString );
			IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsErase );
			
			Ihandle* btnToolsUp = IupButton( null, null );
			IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES,CANFOCUS=NO" );
			IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsUp );
			
			Ihandle* btnToolsDown = IupButton( null, null );
			IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES,CANFOCUS=NO" );
			IupSetCallback( btnToolsDown, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsDown );
			
			Ihandle* vBoxButtonTools = IupVbox( btnToolsAdd, btnToolsErase, btnToolsUp, btnToolsDown, null );
			version(Windows) frameList = IupFlatFrame( IupHbox( listTools, vBoxButtonTools, null ) ); else frameList = IupFrame( IupHbox( listTools, vBoxButtonTools, null ) );
		}
		else
		{
			IupSetAttributes( listTools, "VISIBLELINES=5" );
			version(Windows) frameList = IupFlatFrame( listTools ); else frameList = IupFrame( listTools );
		}
		IupSetAttributes( frameList, "ALIGNMENT=ACENTER,MARGIN=2x2" );

		
		Ihandle* labelOptions = IupLabel( GLOBAL.languageItems["prjopts"].toCString );
		IupSetAttributes( labelOptions, "SIZE=60x16" );
		
		Ihandle* labelCompiler = IupLabel( GLOBAL.languageItems["compiler"].toCString );
		IupSetAttributes( labelCompiler, "SIZE=60x16" );

		if( QuickMode )
		{
			listCompiler = IupList( null );
			IupSetAttributes( listCompiler, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5,EXPAND=HORIZONTAL");
			IupSetHandle( "CArgOptionDialog_textCompiler", listCompiler );
			for( int i = 0; i < GLOBAL.recentCompilers.length; ++i )
			{
				_recentCompilers ~= GLOBAL.recentCompilers[i];
				IupSetStrAttributeId( listCompiler, "", i + 1, toStringz( _recentCompilers[i] ) );
			}
		
			listOptions = IupList(null);
			IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5,EXPAND=HORIZONTAL" );
			IupSetHandle( "CArgOptionDialog_textOptions", listOptions );
			for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
			{
				_recentOptions ~= GLOBAL.recentOptions[i];
				IupSetStrAttributeId( listOptions, "", i + 1, toStringz( _recentOptions[i] ) );
			}
		}
		else	
		{
			listCompiler = IupText( null );
			IupSetAttribute( listCompiler, "EXPAND", "HORIZONTAL" );
			IupSetHandle( "CArgOptionDialog_textCompiler", listCompiler );
			IupSetCallback( listCompiler, "ACTION", cast(Icallback) &CArgOptionDialog_listOptions_EDIT_CB );
			
			listOptions = IupText(null);
			IupSetAttribute( listOptions, "EXPAND", "HORIZONTAL" );
			IupSetHandle( "CArgOptionDialog_textOptions", listOptions );
			IupSetCallback( listOptions, "ACTION", cast(Icallback) &CArgOptionDialog_listOptions_EDIT_CB );
		}
		
		btnCompilerPath = IupButton( null, null );
		IupSetAttributes( btnCompilerPath, "IMAGE=icon_openfile,FLAT=YES,CANFOCUS=NO" );
		IupSetCallback( btnCompilerPath, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe" );
			string fileName = fileSecectDlg.getFileName();

			if( fileName.length )
			{
				Ihandle* _handle = IupGetHandle( "CArgOptionDialog_textCompiler" );
				if( _handle != null )
				{
					IupSetStrAttribute( _handle, "VALUE", toStringz( fileName ) );
					return CArgOptionDialog_listOptions_EDIT_CB( _handle, 0, cast(char*) toStringz( fileName ) );
				}
			}
			
			return IUP_DEFAULT;
		});		
		
		hBoxCompiler = IupHbox( labelCompiler, listCompiler, btnCompilerPath, null );
		IupSetAttributes( hBoxCompiler, "ALIGNMENT=ACENTER,MARGIN=2x0" );

		hBoxOptions = IupHbox( labelOptions, listOptions, null );
		IupSetAttributes( hBoxOptions, "ALIGNMENT=ACENTER,MARGIN=2x0" );

		
		if( QuickMode )
		{
			listArgs = IupList( null );
			IupSetAttributes( listArgs, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5,EXPAND=HORIZONTAL");
			IupSetHandle( "CArgOptionDialog_listArgs", listArgs );
			for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
			{
				_recentArgs ~= GLOBAL.recentArgs[i];
				IupSetStrAttributeId( listArgs, "", i + 1, toStringz( _recentArgs[i] ) );
			}
			
			Ihandle* labelArgs = IupLabel( GLOBAL.languageItems["prjargs"].toCString );
			IupSetAttribute( labelArgs, "SIZE", "60x16" );
			hBoxArgs = IupHbox( labelArgs, listArgs, null );
			IupSetAttributes( hBoxArgs, "ALIGNMENT=ACENTER,MARGIN=2x0" );	
		}

		/*
		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");
		*/
		Ihandle* vBoxLayout;
		switch( QuickMode )
		{
			case 1:			vBoxLayout = IupVbox( frameList, hBoxCompiler, hBoxOptions, /*labelSEPARATOR,*/ bottom, null ); break;
			case 2:			vBoxLayout = IupVbox( frameList, hBoxArgs, /*labelSEPARATOR,*/ bottom, null ); break;
			case 3:			vBoxLayout = IupVbox( frameList, hBoxCompiler, hBoxOptions, hBoxArgs, /*labelSEPARATOR,*/ bottom, null ); break;
			default:		vBoxLayout = IupVbox( frameList, hBoxCompiler, hBoxOptions, /*labelSEPARATOR,*/ bottom, null ); break;
		}
		IupSetAttributes( vBoxLayout, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=0" );

		IupAppend( _dlg, vBoxLayout );
	}	

	public:
	
	this( int w, int h, string title, int _QuickMode = 0, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		QuickMode = _QuickMode;
		
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_tools" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );

		createLayout();
		
		IupSetStrAttribute( listTools, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( listTools, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		version(Windows)
		{
			IupSetStrAttribute( listCompiler, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listCompiler, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listOptions, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listOptions, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listArgs, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listArgs, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
	}

	~this()
	{
		IupSetHandle( "CArgOptionDialog_listTools_Handle", null );
		IupSetHandle( "CArgOptionDialog_textOptions", null );
		CArgOptionDialog.tempCustomCompilerOptions.length = 0;
		
		Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
		if( selectionHandle != null )
		{
			string name = fSTRz( IupGetAttribute( selectionHandle, "TITLE" ) );
			if( name.length )
			{
				foreach( string s; GLOBAL.compilerSettings.customCompilerOptions )
				{
					auto pos = lastIndexOf( s, "%::% " );
					if( pos > 0 )
					{
						if( s[pos+5..$] == name ) return;
					}			
				}			
			}			
			
			IupSetStrAttribute( selectionHandle, "TITLE", toStringz( GLOBAL.compilerSettings.noneCustomCompilerOption ) );
			GLOBAL.compilerSettings.currentCustomCompilerOption = "";
		}
		
		IupDestroy( _dlg );
	}
	
	override string[] show( int x, int y, int dummy  ) // Overload form CBaseDialog
	{
		if( QuickMode > 0 )
		{
			if( QuickMode & 1 )
			{
				IupSetAttribute( hBoxOptions, "ACTIVE", "YES" );
				IupSetAttribute( hBoxCompiler, "ACTIVE", "YES" );
			}
			else
			{
				IupSetAttribute( hBoxOptions, "ACTIVE", "NO" );
				IupSetAttribute( hBoxCompiler, "ACTIVE", "NO" );
			}

			if( QuickMode & 2 )
			{
				IupSetAttribute( hBoxArgs, "ACTIVE", "YES" );
			}
			else
			{
				IupSetAttribute( hBoxArgs, "ACTIVE", "NO" );
			}

			if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" )
			{
				if( IupGetInt( listOptions, "COUNT" ) > 0 )
				{
					if( strip( fromStringz( IupGetAttribute( listOptions, "1" ) ) ).length )
						IupSetStrAttribute( listOptions, "VALUE", IupGetAttribute( listOptions, "1" ) );
					else
						IupSetAttribute( listOptions, "VALUE", "" );
				}
			}

			if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" )
			{
				if( IupGetInt( listArgs, "COUNT" ) > 0 )
				{
					if( strip( fromStringz( IupGetAttribute( listArgs, "1" ) ) ).length )
						IupSetStrAttribute( listArgs, "VALUE", IupGetAttribute( listArgs, "1" ) );
					else
						IupSetAttribute( listArgs, "VALUE", "" );
				}
			}
			
			if( fromStringz( IupGetAttribute( listCompiler, "ACTIVE" ) ) == "YES" )
			{
				if( IupGetInt( listCompiler, "COUNT" ) > 0 )
				{
					if( strip( fromStringz( IupGetAttribute( listCompiler, "1" ) ) ).length )
						IupSetStrAttribute( listCompiler, "VALUE", IupGetAttribute( listCompiler, "1" ) );
					else
						IupSetAttribute( listCompiler, "VALUE", "" );
				}
			}
			
			
		}

		version(Windows)
		{
			if( GLOBAL.bCanUseDarkMode )
			{
				if( GLOBAL.editorSetting00.UseDarkMode == "ON" )
				{
					IupMap( _dlg );
					tools.setCaptionTheme( _dlg, true );
					if( listArgs ) tools.setWinTheme( listArgs, "CFD", true );
					if( listCompiler ) tools.setWinTheme( listCompiler, "CFD", true );
					if( listOptions ) tools.setWinTheme( listOptions, "CFD", true );
				}
				else
				{
					if( listArgs ) tools.setWinTheme( listArgs, "CFD", false );
					if( listCompiler ) tools.setWinTheme( listCompiler, "CFD", false );
					if( listOptions ) tools.setWinTheme( listOptions, "CFD", false );
				}
			}
		}
		
		if( !QuickMode )
		{
			IupMap( _dlg );
			int screenX, screenY, width, height;
			tools.splitBySign( fSTRz( IupGetAttribute( _dlg, "NATURALSIZE" ) ), "x", width, height );
			tools.splitBySign( fSTRz( IupGetAttribute( GLOBAL.statusBar.getLayoutHandle, "SCREENPOSITION" ) ), ",", screenX, screenY );
			x = screenX;
			y = screenY - height;
		}

		IupPopup( _dlg, x, y );
		
		// Cancel to Quit!
		if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "NO" && fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "NO" && fromStringz( IupGetAttribute( listCompiler, "ACTIVE" ) ) == "NO" ) return null;
		
		if( QuickMode > 0 )
		{
			string[] results;

			results ~= strip( fSTRz( IupGetAttribute( listOptions, "VALUE" ) ) );
			results ~= strip( fSTRz( IupGetAttribute( listArgs, "VALUE" ) ) );
			results ~= strip( fSTRz( IupGetAttribute( listCompiler, "VALUE" ) ) );
			
			return results;
		}
		
		return null;
	}	
}

extern(C) // Callback for CFindInFilesDialog
{
	private void getCustomCompilerOptionValue( int index, ref string Name, ref string Option, ref string Compiler )
	{
		if( index < CArgOptionDialog.tempCustomCompilerOptions.length )
		{
			string s = CArgOptionDialog.tempCustomCompilerOptions[index];
			auto bpos = lastIndexOf( s, "%::% " );
			auto fpos = indexOf( s, "%::% " );
			
			if( bpos > 0 )
			{
				Name	= strip( s[bpos+5..$] );
				
				if( fpos < bpos && fpos > -1 )
				{
					Compiler = strip( s[0..fpos] );
					Option	= strip( s[fpos+5..bpos] );
				}
				else
				{
					Option	= strip( s[0..fpos] );
				}
			}
		}
	}
	
	private int CArgOptionDialog_listOptions_EDIT_CB( Ihandle *ih, int c, char *new_value )
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		Ihandle* optionTextHandle = IupGetHandle( "CArgOptionDialog_textOptions" );
		Ihandle* compilerTextHandle = IupGetHandle( "CArgOptionDialog_textCompiler" );
		
		int id = IupGetInt( toolsHandle, "VALUE" );
		
		if( optionTextHandle != null && compilerTextHandle != null )
		{
			string option = fromStringz( IupGetAttribute( optionTextHandle, "VALUE" ) ).dup;
			string compiler = fromStringz( IupGetAttribute( compilerTextHandle, "VALUE" ) ).dup;
		
			if( IupGetInt( toolsHandle, "VALUE" ) > 0 )
			{
				if( ih == optionTextHandle )
				{
					string optionText = strip( fromStringz( new_value ) ).dup;
					if( id > 0 ) CArgOptionDialog.tempCustomCompilerOptions[id-1] = compiler ~ "%::% " ~ optionText ~ "%::% " ~ fSTRz( IupGetAttributeId( toolsHandle, "", id ) );
				}
				else if( ih == compilerTextHandle )
				{
					string optionText = strip( fromStringz( new_value ) ).dup;
					if( id > 0 ) CArgOptionDialog.tempCustomCompilerOptions[id-1] = optionText ~ "%::% " ~ option ~ "%::% " ~ fSTRz( IupGetAttributeId( toolsHandle, "", id ) );
				}
				
			}
			else // No Select
			{
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* listOptions = IupGetHandle( "CArgOptionDialog_textOptions" );
		if( listOptions != null ) IupSetAttribute( listOptions, "ACTIVE", "NO" );

		Ihandle* listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
		if( listArgs != null ) IupSetAttribute( listArgs, "ACTIVE", "NO" );
		
		Ihandle* listCompilers = IupGetHandle( "CArgOptionDialog_textCompiler" );
		if( listCompilers != null ) IupSetAttribute( listCompilers, "ACTIVE", "NO" );

		return IUP_CLOSE;
	}
	
	private int CArgOptionDialog_btnOKtoApply_cb( Ihandle* ih )
	{
		GLOBAL.compilerSettings.customCompilerOptions.length = 0;
		foreach( string s; CArgOptionDialog.tempCustomCompilerOptions )
			GLOBAL.compilerSettings.customCompilerOptions ~= s.dup;
		
		// Ask if apply
		Ihandle* toolHabdle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolHabdle != null )
		{
			int itemID = IupGetInt( toolHabdle, "VALUE" );
			if( itemID > 0 )
			{
				Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" ); // From status panel
				if( selectionHandle != null )
				{
					string itemTitle = fromStringz( IupGetAttributeId( toolHabdle, "", itemID ) ).dup;
					int result = tools.questMessage( "Quest", GLOBAL.languageItems["applythisone"].toDString ~ "\n" ~ itemTitle, "QUESTION", "YESNO", IUP_MOUSEPOS, IUP_MOUSEPOS );
					if( result == 1 )
					{
						GLOBAL.compilerSettings.currentCustomCompilerOption = itemTitle;
						IupSetStrAttribute( selectionHandle, "TITLE", toStringz( GLOBAL.compilerSettings.currentCustomCompilerOption ) );
						GLOBAL.statusBar.setTip( GLOBAL.compilerSettings.currentCustomCompilerOption );
					}
				}
			}
		}
		
		return IUP_CLOSE;
	}		
	
	private int CArgOptionDialog_btnOK_cb( Ihandle* ih )
	{
		Ihandle* _listOptions = IupGetHandle( "CArgOptionDialog_textOptions" );
		if( _listOptions != null )
		{
			if( fromStringz( IupGetAttribute( _listOptions, "ACTIVE" ) ) == "YES" )
			{
				string text = strip( fSTRz( IupGetAttribute( _listOptions, "VALUE" ) ) );
				
				if( !text.length ) text = " ";

				if( text.length )
				{
					actionManager.SearchAction.addListItem( _listOptions, text, GLOBAL.maxRecentOptions );
					
					GLOBAL.recentOptions.length = 0;
					for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
					{
						GLOBAL.recentOptions ~= fromStringz( IupGetAttributeId( _listOptions, "", i ) ).dup;
					}
					if( GLOBAL.recentOptions.length ) IupSetStrAttribute( _listOptions, "VALUE", toStringz( GLOBAL.recentOptions[0] ) );
				}
			}
		}

		Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
		if( _listArgs != null )
		{
			if( fromStringz( IupGetAttribute( _listArgs, "ACTIVE" ) ) == "YES" )
			{
				string text = strip( fSTRz( IupGetAttribute( _listArgs, "VALUE" ) ) );
				
				if( !text.length ) text = " ";
				
				if( text.length )
				{
					actionManager.SearchAction.addListItem( _listArgs, text, GLOBAL.maxRecentArgs );

					GLOBAL.recentArgs.length = 0;
					for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
					{
						GLOBAL.recentArgs ~= fromStringz( IupGetAttributeId( _listArgs, "",  i ) ).dup;
					}
					if( GLOBAL.recentArgs.length ) IupSetStrAttribute( _listArgs, "VALUE", toStringz( GLOBAL.recentArgs[0] ) );
				}
			}
		}

		Ihandle* _listCompilers = IupGetHandle( "CArgOptionDialog_textCompiler" );
		if( _listCompilers != null )
		{
			if( fromStringz( IupGetAttribute( _listCompilers, "ACTIVE" ) ) == "YES" )
			{
				string text = strip( fSTRz( IupGetAttribute( _listCompilers, "VALUE" ) ) );
				
				if( !text.length ) text = " ";
				
				if( text.length )
				{
					actionManager.SearchAction.addListItem( _listCompilers, text, GLOBAL.maxRecentCompilers );

					GLOBAL.recentCompilers.length = 0;
					for( int i = 1; i <= IupGetInt( _listCompilers, "COUNT" ); ++ i )
					{
						GLOBAL.recentCompilers ~= fromStringz( IupGetAttributeId( _listCompilers, "", i ) ).dup;
					}
					if( GLOBAL.recentCompilers.length ) IupSetStrAttribute( _listCompilers, "VALUE", toStringz( GLOBAL.recentCompilers[0] ) );
				}
			}
		}
		
		return IUP_CLOSE;
	}	
	
	private int CArgOptionDialog_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		Ihandle* optionTextHandle	= IupGetHandle( "CArgOptionDialog_textOptions" );
		Ihandle* compilerTextHandle	= IupGetHandle( "CArgOptionDialog_textCompiler" );
		
		if( optionTextHandle != null && compilerTextHandle != null )
		{
			string	Name, Option, Compiler;
			getCustomCompilerOptionValue( item-1, Name, Option, Compiler );
			if( Name.length )		IupSetStrAttribute( optionTextHandle, "VALUE", toStringz( Option ) ); else IupSetAttribute( optionTextHandle, "VALUE", "" );
			if( Compiler.length )	IupSetStrAttribute( compilerTextHandle, "VALUE", toStringz( Compiler ) ); else IupSetAttribute( compilerTextHandle, "VALUE", "" );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		string oldName = fromStringz( text ).dup;
	
		scope reNameDlg = new CSingleTextInput( 200, -1, oldName, "255 255 204", 220 );
		
		string newFileName = reNameDlg.show( IupGetInt( ih, "X" ) + 30, IUP_MOUSEPOS );
		if( newFileName.length )
		{
			IupSetStrAttributeId( ih, "", item, toStringz( newFileName ) );
			IupSetInt( ih, "VALUE", item ); // Set Focus
			
			auto bpos = lastIndexOf( CArgOptionDialog.tempCustomCompilerOptions[item-1], "%::% " );
			if( bpos > 0 ) CArgOptionDialog.tempCustomCompilerOptions[item-1] = CArgOptionDialog.tempCustomCompilerOptions[item-1][0..bpos] ~ "%::% " ~ newFileName;
		}		
		
		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_btnToolsAdd( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomoption"].toDString(), GLOBAL.languageItems["prjtarget"].toDString() ~":", "120x" );
		string newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			IupSetStrAttribute( toolsHandle, "APPENDITEM", toStringz( newFileName ) );
			IupSetInt( toolsHandle, "VALUE", IupGetInt( toolsHandle, "COUNT" ) );
			
			CArgOptionDialog.tempCustomCompilerOptions.length = CArgOptionDialog.tempCustomCompilerOptions.length + 1;
			CArgOptionDialog.tempCustomCompilerOptions[$-1] = "%::% " ~ newFileName;
			
			Ihandle* textHandle = IupGetHandle( "CArgOptionDialog_textOptions" );
			if( textHandle != null ) IupSetAttribute( textHandle, "VALUE", "" );
			
			textHandle = IupGetHandle( "CArgOptionDialog_textCompiler" );
			if( textHandle != null ) IupSetAttribute( textHandle, "VALUE", "" );
		}
		
		IupSetFocus( toolsHandle );
		
		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_btnToolsErase( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		Ihandle* optionTextHandle = IupGetHandle( "CArgOptionDialog_textOptions" );
		if( optionTextHandle == null ) return IUP_DEFAULT;
		
		Ihandle* compilerTextHandle = IupGetHandle( "CArgOptionDialog_textCompiler" );
		if( compilerTextHandle == null ) return IUP_DEFAULT;
		
		
		int index = IupGetInt( toolsHandle, "VALUE" ); // Get current item #no
		if( index < 1 ) return IUP_DEFAULT;
		
		IupSetAttribute( toolsHandle, "REMOVEITEM", IupGetAttribute( toolsHandle, "VALUE" ) );
		IupSetAttribute( optionTextHandle, "VALUE", "" );
		IupSetAttribute( compilerTextHandle, "VALUE", "" );
		
		int count = IupGetInt( toolsHandle, "COUNT" );
		if( count > 0 )
		{
			if( count >= index ) IupSetInt( toolsHandle, "VALUE", index ); else	IupSetInt( toolsHandle, "VALUE", index - 1 ); // Set Focus
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
			if( optionTextHandle != null && compilerTextHandle != null  )
			{
				string Name, Option, Compiler;
				getCustomCompilerOptionValue( id - 1, Name, Option, Compiler );
				if( Name.length )
				{
					IupSetStrAttribute( optionTextHandle, "VALUE", toStringz( Option ) );
					IupSetStrAttribute( compilerTextHandle, "VALUE", toStringz( Compiler ) );
				}
			}
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_btnToolsUp( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );

		if( itemNumber > 1 )
		{
			char* prevItemText = IupGetAttribute( toolsHandle, toStringz( to!(string)(itemNumber-1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( to!(string)(itemNumber) ) );

			IupSetStrAttributeId( toolsHandle, "", itemNumber-1, nowItemText );
			IupSetStrAttributeId( toolsHandle, "", itemNumber, prevItemText );

			IupSetInt( toolsHandle, "VALUE", itemNumber-1 ); // Set Foucs
			
			// IupList item start from 1, CArgOptionDialog.tempCustomCompilerOptions start from 0
			itemNumber--;
			
			string temp = CArgOptionDialog.tempCustomCompilerOptions[itemNumber-1];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber-1] = CArgOptionDialog.tempCustomCompilerOptions[itemNumber];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber] = temp;
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_btnToolsDown( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );
		int itemCount = IupGetInt( toolsHandle, "COUNT" );

		if( itemNumber < itemCount )
		{
			char* nextItemText = IupGetAttributeId( toolsHandle, "", itemNumber + 1 );
			char* nowItemText = IupGetAttributeId( toolsHandle, "", itemNumber );

			IupSetStrAttributeId( toolsHandle, "", itemNumber + 1, nowItemText );
			IupSetStrAttributeId( toolsHandle, "", itemNumber + 1, nextItemText );

			IupSetInt( toolsHandle, "VALUE", itemNumber+1 );  // Set Foucs
			
			// IupList item start from 1, CArgOptionDialog.tempCustomCompilerOptions start from 0
			itemNumber--;
			
			string temp = CArgOptionDialog.tempCustomCompilerOptions[itemNumber+1];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber+1] = CArgOptionDialog.tempCustomCompilerOptions[itemNumber];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber] = temp;
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}
}