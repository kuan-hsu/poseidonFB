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
	Ihandle*			listTools, listCompiler, listOptions, listArgs, btnCompilerPath;
	
	Ihandle*			hBoxCompiler, hBoxOptions, hBoxArgs;
	
	
	Ihandle*			labelStatus;
	int					QuickMode;
	
	IupString[]			_recentOptions, _recentArgs, _recentCompilers;
	
	static char[][]		tempCustomCompilerOptions;

	Ihandle* createDlgButton( char[] buttonSize = "40x20" )
	{
		btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
		IupSetHandle( "btnCANCEL_Args", btnCANCEL );
		IupSetAttributes( btnCANCEL, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel
		
		Ihandle* hBox_DlgButton;
		if( !QuickMode )
		{
			btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
			IupSetHandle( "btnOK_Args", btnOK );
			IupSetAttributes( btnOK, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOKtoApply_cb );
			
			IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK_Args" );
			
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
			hBox_DlgButton = IupHbox( IupFill(), btnCANCEL, btnOK, null );
		}
		else
		{
			btnOK = IupButton( GLOBAL.languageItems["go"].toCString, null );
			IupSetHandle( "btnOK_Args", btnOK );
			IupSetAttributes( btnOK, toStringz( "SIZE=" ~ buttonSize ) );//,IMAGE=IUP_ActionOk" );
			IupSetCallback( btnOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
			
			IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK_Args" );
			
			hBox_DlgButton = IupHbox( IupFill(), btnCANCEL, btnOK, null );
			IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
		}
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );
		
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_Args" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CArgOptionDialog_btnCancel_cb );

		return hBox_DlgButton;
	}


	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		listTools = IupList( null );
		IupSetAttributes( listTools, "MULTIPLE=NO,EXPAND=YES" );
		IupSetHandle( "CArgOptionDialog_listTools_Handle", listTools );
		IupSetCallback( listTools, "ACTION", cast(Icallback) &CArgOptionDialog_ACTION );
		
		
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
		
		Ihandle* frameList;
		if( !QuickMode )
		{
			IupSetCallback( listTools, "DBLCLICK_CB", cast(Icallback) &CArgOptionDialog_DBLCLICK_CB );
			
			Ihandle* btnToolsAdd = IupButton( null, null );
			IupSetAttributes( btnToolsAdd, "IMAGE=icon_debug_add,FLAT=YES" );
			IupSetAttribute( btnToolsAdd, "TIP", GLOBAL.languageItems["add"].toCString );
			IupSetCallback( btnToolsAdd, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsAdd );

			Ihandle* btnToolsErase = IupButton( null, null );
			IupSetAttributes( btnToolsErase, "IMAGE=icon_delete,FLAT=YES" );
			IupSetAttribute( btnToolsErase, "TIP", GLOBAL.languageItems["remove"].toCString );
			IupSetCallback( btnToolsErase, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsErase );
			
			/*
			Ihandle* btnToolsEdit = IupButton( null, null );
			IupSetAttributes( btnToolsEdit, "IMAGE=icon_Write,FLAT=YES" );
			IupSetAttribute( btnToolsEdit, "TIP", GLOBAL.languageItems["edit"].toCString );
			IupSetCallback( btnToolsEdit, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsEdit );
			*/
			
			Ihandle* btnToolsUp = IupButton( null, null );
			IupSetAttributes( btnToolsUp, "IMAGE=icon_uparrow,FLAT=YES" );
			IupSetCallback( btnToolsUp, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsUp );
			
			Ihandle* btnToolsDown = IupButton( null, null );
			IupSetAttributes( btnToolsDown, "IMAGE=icon_downarrow,FLAT=YES" );
			IupSetCallback( btnToolsDown, "ACTION", cast(Icallback) &CArgOptionDialog_btnToolsDown );
			
			Ihandle* vBoxButtonTools = IupVbox( btnToolsAdd, btnToolsErase, /*btnToolsEdit,*/ btnToolsUp, btnToolsDown, null );
			frameList = IupFrame( IupHbox( listTools, vBoxButtonTools, null ) );
		}
		else
		{
			IupSetAttributes( listTools, "VISIBLELINES=5" );
			frameList = IupFrame( listTools );
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
				_recentCompilers ~= new IupString( GLOBAL.recentCompilers[i] );
				IupSetAttribute( listCompiler, toStringz( Integer.toString( i + 1 ) ), _recentCompilers[i].toCString );
			}
		
			listOptions = IupList(null);
			IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5,EXPAND=HORIZONTAL");
			IupSetHandle( "CArgOptionDialog_textOptions", listOptions );
			for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
			{
				_recentOptions ~= new IupString( GLOBAL.recentOptions[i] );
				IupSetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ), _recentOptions[i].toCString );
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
		IupSetAttributes( btnCompilerPath, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnCompilerPath, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe" );
			char[] fileName = fileSecectDlg.getFileName();

			if( fileName.length )
			{
				Ihandle* _handle = IupGetHandle( "CArgOptionDialog_textCompiler" );
				if( _handle != null )
				{
					IupSetAttribute( _handle, "VALUE", toStringz( fileName ) );
					return CArgOptionDialog_listOptions_EDIT_CB( _handle, 0, toStringz( fileName ) );
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
			case 1:			vBoxLayout = IupVbox( frameList, hBoxCompiler, hBoxOptions, labelSEPARATOR, bottom, null ); break;
			case 2:			vBoxLayout = IupVbox( frameList, hBoxArgs, labelSEPARATOR, bottom, null ); break;
			case 3:			vBoxLayout = IupVbox( frameList, hBoxCompiler, hBoxOptions, hBoxArgs, labelSEPARATOR, bottom, null ); break;
			default:		vBoxLayout = IupVbox( frameList, hBoxCompiler, hBoxOptions, labelSEPARATOR, bottom, null ); break;
		}

		IupAppend( _dlg, vBoxLayout );
	}	

	public:
	
	this( int w, int h, char[] title, int _QuickMode = 0, bool bResize = false, char[] parent = "POSEIDON_MAIN_DIALOG" )
	{
		QuickMode = _QuickMode;
		
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_tools" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );

		createLayout();
	}

	~this()
	{
		IupSetHandle( "CArgOptionDialog_listTools_Handle", null );
		IupSetHandle( "CArgOptionDialog_textOptions", null );
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
			
			IupSetAttribute( selectionHandle, "FGCOLOR", "0 0 0" );
			IupSetAttribute( selectionHandle, "TITLE", GLOBAL.noneCustomCompilerOption.toCString );
			GLOBAL.currentCustomCompilerOption = cast(char[])"";
		}
		
		IupDestroy( _dlg );
	}
	
	char[][] show( int x, int y, int dummy = -1 ) // Overload form CBaseDialog
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
			
			if( fromStringz( IupGetAttribute( listCompiler, "ACTIVE" ) ) == "YES" )
			{
				if( IupGetInt( listCompiler, "COUNT" ) > 0 )
				{
					if( Util.trim( fromStringz( IupGetAttribute( listCompiler, "1" ) ) ).length )
						IupSetAttribute( listCompiler, "VALUE", IupGetAttribute( listCompiler, "1" ) );
					else
						IupSetAttribute( listCompiler, "VALUE", "" );
				}
			}			
		}
			

		IupPopup( _dlg, x, y );
		
		// Cancel to Quit!
		if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "NO" && fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "NO" && fromStringz( IupGetAttribute( listCompiler, "ACTIVE" ) ) == "NO" ) return null;
		
		if( QuickMode > 0 )
		{
			char[][] results;

			results ~= Util.trim( fromStringz( IupGetAttribute( listOptions, "VALUE" ) ) ).dup;
			results ~= Util.trim( fromStringz( IupGetAttribute( listArgs, "VALUE" ) ) ).dup;
			results ~= Util.trim( fromStringz( IupGetAttribute( listCompiler, "VALUE" ) ) ).dup;
			
			return results;
		}
		
		return null;
	}	
}

extern(C) // Callback for CFindInFilesDialog
{
	private void getCustomCompilerOptionValue( int index, ref char[] Name, ref char[] Option, ref char[] Compiler )
	{
		if( index < CArgOptionDialog.tempCustomCompilerOptions.length )
		{
			char[] s = CArgOptionDialog.tempCustomCompilerOptions[index];
			int bpos = Util.rindex( s, "%::% " );
			int fpos = Util.index( s, "%::% " );
			
			if( bpos < s.length )
			{
				Name	= Util.trim( s[bpos+5..$] );
				
				if( fpos < bpos )
				{
					Compiler = Util.trim( s[0..fpos] );
					Option	= Util.trim( s[fpos+5..bpos] );
				}
				else
				{
					Option	= Util.trim( s[0..fpos] );
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
			char[] option = fromStringz( IupGetAttribute( optionTextHandle, "VALUE" ) ).dup;
			char[] compiler = fromStringz( IupGetAttribute( compilerTextHandle, "VALUE" ) ).dup;
		
			if( IupGetInt( toolsHandle, "VALUE" ) > 0 )
			{
				/*
				if( id > 0 ) CArgOptionDialog.tempCustomCompilerOptions[id-1] = compiler ~ "%::% " ~ option ~ "%::% " ~ fromStringz( IupGetAttributeId( toolsHandle, "", id ) ).dup;
				*/
				
				if( ih == optionTextHandle )
				{
					char[] optionText = Util.trim( fromStringz( new_value ) ).dup;
					if( id > 0 ) CArgOptionDialog.tempCustomCompilerOptions[id-1] = compiler ~ "%::% " ~ optionText ~ "%::% " ~ fromStringz( IupGetAttributeId( toolsHandle, "", id ) ).dup;
				}
				else if( ih == compilerTextHandle )
				{
					char[] optionText = Util.trim( fromStringz( new_value ) ).dup;
					if( id > 0 ) CArgOptionDialog.tempCustomCompilerOptions[id-1] = optionText ~ "%::% " ~ option ~ "%::% " ~ fromStringz( IupGetAttributeId( toolsHandle, "", id ) ).dup;
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
		GLOBAL.customCompilerOptions.length = 0;
		foreach( char[] s; CArgOptionDialog.tempCustomCompilerOptions )
			GLOBAL.customCompilerOptions ~= s.dup;
		
		return IUP_CLOSE;
	}		
	
	private int CArgOptionDialog_btnOK_cb( Ihandle* ih )
	{
		Ihandle* _listOptions = IupGetHandle( "CArgOptionDialog_textOptions" );
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

		Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
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

		Ihandle* _listCompilers = IupGetHandle( "CArgOptionDialog_textCompiler" );
		if( _listCompilers != null )
		{
			if( fromStringz( IupGetAttribute( _listCompilers, "ACTIVE" ) ) == "YES" )
			{
				char[] text = Util.trim( fromStringz( IupGetAttribute( _listCompilers, "VALUE" ) ).dup );
				
				if( !text.length ) text = " ";
				
				if( text.length )
				{
					actionManager.SearchAction.addListItem( _listCompilers, text, GLOBAL.maxRecentCompilers );

					GLOBAL.recentCompilers.length = 0;
					for( int i = 1; i <= IupGetInt( _listCompilers, "COUNT" ); ++ i )
					{
						GLOBAL.recentCompilers ~= fromStringz( IupGetAttribute( _listCompilers, toStringz( Integer.toString( i ) ) ) ).dup;
					}
					if( GLOBAL.recentCompilers.length ) IupSetAttribute( _listCompilers, "VALUE", toStringz( GLOBAL.recentCompilers[0] ) );
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
			char[]	Name, Option, Compiler;
			getCustomCompilerOptionValue( item-1, Name, Option, Compiler );
			if( Name.length )		IupSetAttribute( optionTextHandle, "VALUE", toStringz( Option ) ); else IupSetAttribute( optionTextHandle, "VALUE", "" );
			if( Compiler.length )	IupSetAttribute( compilerTextHandle, "VALUE", toStringz( Compiler ) ); else IupSetAttribute( compilerTextHandle, "VALUE", "" );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		char[] oldName = fromStringz( text ).dup;
	
		scope reNameDlg = new CSingleTextInput( 200, -1, oldName, "255 255 204", 220 );
		
		char[] newFileName = reNameDlg.show( IupGetInt( ih, "X" ) + 30, IUP_MOUSEPOS );
		if( newFileName.length )
		{
			IupSetAttributeId( ih, "", item, toStringz( newFileName.dup ) );
			IupSetInt( ih, "VALUE", item ); // Set Focus
			
			int bpos = Util.rindex( CArgOptionDialog.tempCustomCompilerOptions[item-1], "%::% " );
			if( bpos < CArgOptionDialog.tempCustomCompilerOptions[item-1].length )	CArgOptionDialog.tempCustomCompilerOptions[item-1] = CArgOptionDialog.tempCustomCompilerOptions[item-1][0..bpos] ~ "%::% " ~ newFileName;
		}		
		
		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_btnToolsAdd( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomoption"].toDString(), GLOBAL.languageItems["prjtarget"].toDString() ~":", "120x" );
		char[] newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			IupSetAttribute( toolsHandle, "APPENDITEM", toStringz( newFileName ) );
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
				char[] Name, Option, Compiler;
				getCustomCompilerOptionValue( id - 1, Name, Option, Compiler );
				if( Name.length )
				{
					IupSetAttribute( optionTextHandle, "VALUE", toStringz( Option ) );
					IupSetAttribute( compilerTextHandle, "VALUE", toStringz( Compiler ) );
				}
			}
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}
	
	/+
	private int CArgOptionDialog_btnToolsEdit( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;
		
		int index = IupGetInt( toolsHandle, "VALUE" ); // Get current item #no
		if( index < 1 ) return IUP_DEFAULT;
		
		char[] oldName = fromStringz( IupGetAttributeId( toolsHandle, "", index ) ).dup;
		
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["setcustomoption"].toDString(), GLOBAL.languageItems["prjtarget"].toDString() ~":", "120x", oldName );
		char[] newFileName = Util.trim( test.show( IUP_MOUSEPOS, IUP_MOUSEPOS ) );

		if( newFileName.length )
		{
			IupSetAttributeId( toolsHandle, "", index, toStringz( newFileName.dup ) );
			IupSetInt( toolsHandle, "VALUE", index );
			
			int bpos = Util.rindex( CArgOptionDialog.tempCustomCompilerOptions[index-1], "%::% " );
			if( bpos < CArgOptionDialog.tempCustomCompilerOptions[index-1].length )
			{
				CArgOptionDialog.tempCustomCompilerOptions[index-1] = CArgOptionDialog.tempCustomCompilerOptions[index-1][0..bpos] ~ "%::% " ~ newFileName;
				/*
				Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
				if( selectionHandle != null )
				{
					char[] name = fromStringz( IupGetAttribute( selectionHandle, "TITLE" ) ).dup;
					if( name.length )
					{
						if( name == oldName )
						{
							GLOBAL.currentCustomCompilerOption = newFileName;
							IupSetAttribute( selectionHandle, "FGCOLOR", "0 0 255" );
							IupSetAttribute( selectionHandle, "TITLE", GLOBAL.currentCustomCompilerOption.toCString );
							GLOBAL.statusBar.setTip( GLOBAL.currentCustomCompilerOption.toDString );
						}
					}			
				}
				*/
			}
		}
		
		IupSetFocus( IupGetParent( toolsHandle ) );
		
		return IUP_DEFAULT;
	}
	+/

	private int CArgOptionDialog_btnToolsUp( Ihandle* ih ) 
	{
		Ihandle* toolsHandle = IupGetHandle( "CArgOptionDialog_listTools_Handle" );
		if( toolsHandle == null ) return IUP_DEFAULT;

		int itemNumber = IupGetInt( toolsHandle, "VALUE" );

		if( itemNumber > 1 )
		{
			char* prevItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber-1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber-1) ), nowItemText );
			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ), prevItemText );

			IupSetAttribute( toolsHandle, "VALUE", toStringz( Integer.toString(itemNumber-1) ) ); // Set Foucs
			
			// IupList item start from 1, CArgOptionDialog.tempCustomCompilerOptions start from 0
			itemNumber--;
			
			char[] temp = CArgOptionDialog.tempCustomCompilerOptions[itemNumber-1];
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
			char* nextItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber+1) ) );
			char* nowItemText = IupGetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber+1) ), nowItemText );
			IupSetAttribute( toolsHandle, toStringz( Integer.toString(itemNumber) ), nextItemText );

			IupSetAttribute( toolsHandle, "VALUE", toStringz( Integer.toString(itemNumber+1) ) );  // Set Foucs
			
			// IupList item start from 1, CArgOptionDialog.tempCustomCompilerOptions start from 0
			itemNumber--;
			
			char[] temp = CArgOptionDialog.tempCustomCompilerOptions[itemNumber+1];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber+1] = CArgOptionDialog.tempCustomCompilerOptions[itemNumber];
			CArgOptionDialog.tempCustomCompilerOptions[itemNumber] = temp;
		}
		
		IupSetFocus( toolsHandle );

		return IUP_DEFAULT;
	}
}