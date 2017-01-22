module layouts.tabDocument;

private import iup.iup;
import iup.iup_scintilla;
private import global, actionManager, scintilla, menu;

import tango.stdc.stringz;

void createTabs()
{
	//GLOBAL.documentTabs = IupTabs( null );
	GLOBAL.documentTabs = IupTabs( null );
	version(Windows)
	{
		IupSetAttributes( GLOBAL.documentTabs, "CHILDOFFSET=0x3" );
		
		/+
		//IupSetAttribute( GLOBAL.documentTabs, "CLOSEIMAGE", "icon_clear" );
		//IupSetAttribute( GLOBAL.documentTabs, "TABSIMAGESPACING", "0" );
		IupSetAttribute( GLOBAL.documentTabs, "TABSFONT",GLOBAL.cString.convert( GLOBAL.fonts[0].fontString ) );
		IupSetAttribute( GLOBAL.documentTabs, "FORECOLOR", "0 0 0" );
		IupSetAttribute( GLOBAL.documentTabs, "TABSFORECOLOR", "100 100 100" );
		
		IupSetInt( GLOBAL.documentTabs, "TABSFONTSIZE", 9 );
		+/
	}
	
	//IupSetAttribute( GLOBAL.documentTabs, "PADDING", "10x10" );

	version( linux )
	{
		IupSetAttribute( GLOBAL.documentTabs, "SHOWCLOSE", "YES" );
		IupSetCallback( GLOBAL.documentTabs, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	}
	IupSetCallback( GLOBAL.documentTabs, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	IupSetCallback( GLOBAL.documentTabs, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
	//IupSetCallback( GLOBAL.documentTabs, "FLAT_BUTTON_CB", cast(Icallback) &tabFocus_cb );
}

extern(C)
{
	private int tabchangePos_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		return actionManager.DocumentTabAction.tabChangePOS( ih, new_pos );
	}

	version( linux )
	{
		// Close the document Iuptab......
		private int tabClose_cb( Ihandle* ih, int pos )
		{
			Ihandle* _child = IupGetChild( ih, pos );
			CScintilla cSci = ScintillaAction.getCScintilla( _child );
			if( cSci !is null )
			{
				IupSetInt( GLOBAL.documentTabs, "VALUEPOS", pos );
				return actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
			}

			return IUP_DEFAULT;
		}
	}

	private int tabRightClick_cb( Ihandle* ih, int pos )
	{
		// ih = GLOBAL.documentTabs
		// Get Focus
		IupSetInt( ih, "VALUEPOS" , pos ); 
		
		actionManager.DocumentTabAction.tabChangePOS( ih, pos );

		Ihandle* _save = IupItem( toStringz( GLOBAL.languageItems["save"] ), null );
		IupSetAttribute( _save, "IMAGE", "icon_save" );
		IupSetCallback( _save, "ACTION", cast(Icallback) &menu.saveFile_cb ); // from menu.d

		Ihandle* _close = IupItem( toStringz( GLOBAL.languageItems["close"] ), null );
		IupSetAttribute( _close, "IMAGE", "icon_delete" );
		IupSetCallback( _close, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
		});

		Ihandle* _closeothers = IupItem( toStringz( GLOBAL.languageItems["closeothers"] ), null );
		IupSetAttribute( _closeothers, "IMAGE", "icon_deleteothers" );
		IupSetCallback( _closeothers, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeOthersDocument( cSci.getFullPath() );
		});

		Ihandle* _closeall = IupItem( toStringz( GLOBAL.languageItems["closeall"] ), null );
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
	
	/*
	private int tabFocus_cb(Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON2 )
		{
			IupMessage("MID","");
			for( int i = 0; i < IupGetInt( ih, "COUNT" ); i ++ )
				IupMessage( "", IupGetAttribute( IupGetChild( ih, i ), "SCREENPOSITION" ) );
			
		}
		return IUP_DEFAULT;
	}
	*/
}