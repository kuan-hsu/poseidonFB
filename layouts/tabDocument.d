module layouts.tabDocument;

private import iup.iup;
private import iup.iup_scintilla;
private import global, actionManager, scintilla, menu, tools;

import tango.stdc.stringz;

void createTabs()
{
	version(FLATTAB)
	{
		GLOBAL.documentTabs = IupFlatTabs( null );
		
		IupSetAttribute( GLOBAL.documentTabs, "SHOWCLOSE", "YES" );
		IupSetAttribute( GLOBAL.documentTabs, "TABSIMAGESPACING", "1" );
		IupSetAttribute( GLOBAL.documentTabs, "CLOSEIMAGE", "icon_clear" );
		IupSetAttribute( GLOBAL.documentTabs, "CLOSEIMAGEPRESS", "icon_clear" );
		IupSetAttribute( GLOBAL.documentTabs, "TABSPADDING", "5x5" );
		IupSetAttribute( GLOBAL.documentTabs, "SIZE", "NULL" );
		//IupSetAttribute( GLOBAL.documentTabs, "FORECOLOR", "0 0 255" );
		IupSetAttribute( GLOBAL.documentTabs, "HIGHCOLOR", "0 0 255" );
	}
	else
	{
		GLOBAL.documentTabs = IupTabs( null );
		IupSetAttributes( GLOBAL.documentTabs, "CHILDOFFSET=0x3" );
		version( linux ) IupSetAttribute( GLOBAL.documentTabs, "SHOWCLOSE", "YES" );
	}

	IupSetCallback( GLOBAL.documentTabs, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	IupSetCallback( GLOBAL.documentTabs, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
	//IupSetCallback( GLOBAL.documentTabs, "FLAT_BUTTON_CB", cast(Icallback) &tabbutton_cb );
}

extern(C)
{
	private int tabchangePos_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		return actionManager.DocumentTabAction.tabChangePOS( ih, new_pos );
	}

	// Close the document Iuptab......
	private int tabClose_cb( Ihandle* ih, int pos )
	{
		Ihandle* _child = IupGetChild( ih, pos );
		CScintilla cSci = ScintillaAction.getCScintilla( _child );
		if( cSci !is null )
		{
			int result;
			
			Ihandle* oldHandle = cast(Ihandle*) IupGetAttribute( ih, "VALUE_HANDLE" );
			
			if( oldHandle != cSci.getIupScintilla )
			{
				result = actionManager.ScintillaAction.closeDocument( cSci.getFullPath(), pos );
				if( IupGetInt( ih, "COUNT" ) > 0 && oldHandle != null )
				{
					int oldPos = IupGetChildPos( ih, oldHandle );
					DocumentTabAction.tabChangePOS( ih, oldPos );
					IupRefresh( GLOBAL.documentTabs );
				}
			}
			else
			{
				result = actionManager.ScintillaAction.closeDocument( cSci.getFullPath(), pos );
			}
			
			if( result == IUP_IGNORE ) return IUP_IGNORE;
		}

		version(FLATTAB) return IUP_CONTINUE;
		
		return IUP_DEFAULT;
	}

	private int tabRightClick_cb( Ihandle* ih, int pos )
	{
		// ih = GLOBAL.documentTabs
		// Get Focus
		IupSetInt( ih, "VALUEPOS" , pos ); 
		
		actionManager.DocumentTabAction.tabChangePOS( ih, pos );

		Ihandle* _save = IupItem( GLOBAL.languageItems["save"].toCString, null );
		IupSetAttribute( _save, "IMAGE", "icon_save" );
		IupSetCallback( _save, "ACTION", cast(Icallback) &menu.saveFile_cb ); // from menu.d

		Ihandle* _close = IupItem( GLOBAL.languageItems["close"].toCString, null );
		IupSetAttribute( _close, "IMAGE", "icon_delete" );
		IupSetCallback( _close, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
		});

		Ihandle* _closeothers = IupItem( GLOBAL.languageItems["closeothers"].toCString, null );
		IupSetAttribute( _closeothers, "IMAGE", "icon_deleteothers" );
		IupSetCallback( _closeothers, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeOthersDocument( cSci.getFullPath() );
		});

		Ihandle* _closeall = IupItem( GLOBAL.languageItems["closeall"].toCString, null );
		IupSetAttribute( _closeall, "IMAGE", "icon_deleteall" );
		IupSetCallback( _closeall, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			actionManager.ScintillaAction.closeAllDocument();
		});
		
		Ihandle* popupMenu = IupMenu( 
										_close,
										_closeothers,
										_closeall,
										IupSeparator(),
										_save,
										null
									);


		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );		

		return IUP_DEFAULT;
	}
	
	/+
	private int tabbutton_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		IupMessage( "CLIENTSIZE", IupGetAttribute( ih, "CLIENTSIZE" ) );
		IupMessage( "POSITION", IupGetAttribute( ih, "POSITION" ) );
		IupMessage( "MINSIZE", IupGetAttribute( ih, "MINSIZE" ) );
		
		/+
		if( pressed == 0 )
		{
			if( button == '2' ) // IUP_BUTTON1 = '2' = 50
			{
				char* ScreenPos = IupGetGlobal( "CURSORPOS" );
				
				scope mouse = new IupString( Integer.toString(x) ~ "x" ~ Integer.toString(y) ~ " 1 1" );
				IupSetGlobal( "MOUSEBUTTON", mouse.toCString );
				mouse = Integer.toString(x) ~ "x" ~ Integer.toString(y) ~ " 1 0";
				IupSetGlobal( "MOUSEBUTTON", mouse.toCString );
				
				IupSetGlobal( "CURSORPOS", ScreenPos );
				
				
				int pos = IupGetInt( ih, "VALUEPOS" );
				
				
				IupMessage( "", toStringz(Integer.toString(pos) ) );
				

			}
		}+/
		return IUP_DEFAULT;
	}
	+/
}