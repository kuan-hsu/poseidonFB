module layouts.tabDocument;

private import iup.iup;
private import global, actionManager, scintilla, menu;

import tango.stdc.stringz;

void createTabs()
{
	GLOBAL.documentTabs = IupTabs( null, null );
	//IupSetAttribute( GLOBAL.documentTabs, "SHOWCLOSE", "YES" );
	IupSetCallback( GLOBAL.documentTabs, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	IupSetCallback( GLOBAL.documentTabs, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );

	
	//IupSetCallback( GLOBAL.documentTabs, "GETFOCUS_CB", cast(Icallback) &tabFocus_cb );
}

extern(C)
{
	int tabchangePos_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		Ihandle* _child = IupGetChild( ih, new_pos );
		CScintilla cSci = actionManager.ScintillaAction.getCScintilla( _child );
		
		if( cSci !is null )
		{
			IupSetFocus( _child );
			StatusBarAction.update();

			// Marked the trees( FileList & ProjectTree )
			actionManager.ScintillaAction.toTreeMarked( cSci.getFullPath() );
			GLOBAL.outlineTree.changeTree( cSci.getFullPath() );
		}

		return IUP_DEFAULT;
	}
	
	// Close the document Iuptab......
	int tabClose_cb( Ihandle* ih, int pos )
	{
		// ih = GLOBAL.documentTabs
		// So we need get the child's Ihandle( Iupscintilla )
		Ihandle* _child = IupGetChild( ih, pos );

		CScintilla cSci = ScintillaAction.getCScintilla( _child );
		if( cSci !is null )
		{
			if( fromStringz( IupGetAttribute( _child, "SAVEDSTATE" ) ) == "YES" )
			{
				int button = IupAlarm( "Quest", toStringz("\"" ~ cSci.getFullPath ~ "\"\nhas been changed, save it now?"), "Yes", "No", "Cancel" );
				if( button == 3 ) return IUP_IGNORE;
				if( button == 1 ) cSci.saveFile();
			}

			// Remove the fileListTree's node
			int nodeCount = IupGetInt( GLOBAL.fileListTree, "COUNT" );
		
			for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
			{
				CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree, "USERDATA", id );
				if( _sci_node == cSci )
				{
					IupSetAttributeId( GLOBAL.fileListTree, "DELNODE", id, "SELECTED" );
					break;
				}
			}

			actionManager.OutlineAction.cleanTree( cSci.getFullPath );

			// Remove from the scintillaManager
			GLOBAL.scintillaManager.remove( cSci.getFullPath );
			delete cSci;
			if( GLOBAL.scintillaManager.length == 0 )
			{
				IupSetAttribute( GLOBAL.statusBar_Line_Col, "TITLE", "             " );
				IupSetAttribute( GLOBAL.statusBar_Ins, "TITLE", "   " );
				IupSetAttribute( GLOBAL.statusBar_FontType, "TITLE", "        " );	
			}
		}

		return IUP_CONTINUE;
	}

	int tabRightClick_cb( Ihandle* ih, int pos )
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
		IupSetCallback( _closeall, "ACTION", cast(Icallback) cast(Icallback) function( Ihandle* ih )
		{
			actionManager.ScintillaAction.closeAllDocument();
		});

		Ihandle* _refresh = IupItem( "Refresh Parser", null );
		IupSetAttribute( _refresh, "IMAGE", "icon_refresh" );
		IupSetCallback( _refresh, "ACTION", cast(Icallback) cast(Icallback) function( Ihandle* ih )
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
										_refresh,
										null
									);


		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );		

		return IUP_DEFAULT;
	}
}

