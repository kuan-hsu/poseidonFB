module layouts.tabDocument;

private import iup.iup;
import iup.iup_scintilla;
private import global, actionManager, scintilla, menu;

import tango.stdc.stringz;

void createTabs()
{
	GLOBAL.documentTabs = IupTabs( null );
	version(Windows) IupSetAttribute( GLOBAL.documentTabs, "CHILDOFFSET", "0x4" );
	//IupSetAttribute( GLOBAL.documentTabs, "PADDING", "10x10" );

	 
	version( linux )
	{
		IupSetAttribute( GLOBAL.documentTabs, "SHOWCLOSE", "YES" );
		IupSetCallback( GLOBAL.documentTabs, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	}
	IupSetCallback( GLOBAL.documentTabs, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	IupSetCallback( GLOBAL.documentTabs, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
	//IupSetCallback( GLOBAL.documentTabs, "GETFOCUS_CB", cast(Icallback) &tabFocus_cb );
}

extern(C)
{
	private int tabchangePos_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		return actionManager.DocumentTabAction.tabChangePOS( ih, new_pos, old_pos );
	}
	
	// Close the document Iuptab......
	private int tabClose_cb( Ihandle* ih, int pos )
	{
		CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )	return actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
		/*
		Ihandle* _child = IupGetChild( ih, pos );
		CScintilla cSci = ScintillaAction.getCScintilla( _child );
		*/
		return IUP_DEFAULT;
	}

	private int tabRightClick_cb( Ihandle* ih, int pos )
	{
		// ih = GLOBAL.documentTabs
		// So we need get the child's Ihandle( Iupscintilla )
		Ihandle* _child = IupGetChild( ih, pos );

		// Get Focus
		IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)_child );

		Ihandle* _save = IupItem( "Save", null );
		IupSetAttribute( _save, "IMAGE", "icon_save" );
		IupSetCallback( _save, "ACTION", cast(Icallback) &menu.saveFile_cb ); // from menu.d

		Ihandle* _close = IupItem( "Close", null );
		IupSetAttribute( _close, "IMAGE", "icon_delete" );
		IupSetCallback( _close, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
		});

		Ihandle* _closeothers = IupItem( "Close Others", null );
		IupSetAttribute( _closeothers, "IMAGE", "icon_deleteothers" );
		IupSetCallback( _closeothers, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeOthersDocument( cSci.getFullPath() );
		});

		Ihandle* _closeall = IupItem( "Close All", null );
		IupSetAttribute( _closeall, "IMAGE", "icon_deleteall" );
		IupSetCallback( _closeall, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			actionManager.ScintillaAction.closeAllDocument();
		});

		// Annotation
		Ihandle* _showAnnotation = IupItem( "Show Annotation", null );
		IupSetAttribute( _showAnnotation, "IMAGE", "icon_annotation" );
		IupSetCallback( _showAnnotation, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
			//IupScintillaSendMessage( cSci.getIupScintilla, 2548, 3, 0 );
		});
		
		Ihandle* _hideAnnotation = IupItem( "Hide Annotation", null );
		IupSetAttribute( _hideAnnotation, "IMAGE", "icon_annotation_hide" );
		IupSetCallback( _hideAnnotation, "ACTION", cast(Icallback)function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONVISIBLE", "HIDDEN" );
		});

		Ihandle* _removeAllAnnotation = IupItem( "Remove All Annotation", null );
		IupSetAttribute( _removeAllAnnotation, "IMAGE", "icon_annotation_remove" );
		IupSetCallback( _removeAllAnnotation, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONCLEARALL", "YES" );
		});

		Ihandle* _refresh = IupItem( "Refresh Parser", null );
		IupSetAttribute( _refresh, "IMAGE", "icon_refresh" );
		IupSetCallback( _refresh, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			actionManager.OutlineAction.refresh( cSci.getFullPath() );
		});
		
		
		Ihandle* popupMenu = IupMenu( 
										_close,
										_closeothers,
										_closeall,
										IupSeparator(),
										_save,
										IupSeparator(),
										_showAnnotation,
										_hideAnnotation,
										_removeAllAnnotation,
										IupSeparator(),
										_refresh,
										null
									);


		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );		

		return IUP_DEFAULT;
	}
}

