module layouts.tabDocument;

private import iup.iup;
private import iup.iup_scintilla;
private import global, actionManager, scintilla, menu, tools;

import tango.stdc.stringz;

void createTabs()
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
	IupSetAttribute( GLOBAL.documentTabs, "TABSHIGHCOLOR", "240 255 240" );
	//IupSetCallback( GLOBAL.documentTabs, "WHEEL_CB", cast(Icallback) function( Ihandle* ih ){ return IUP_DEFAULT; });
	IupSetCallback( GLOBAL.documentTabs, "FLAT_BUTTON_CB", cast(Icallback) &tabbutton_cb );
	IupSetCallback( GLOBAL.documentTabs, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	version(Windows) IupSetCallback( GLOBAL.documentTabs, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
}

void createTabs2()
{
	GLOBAL.documentTabs_Right = IupFlatTabs( null );
	
	IupSetAttribute( GLOBAL.documentTabs_Right, "SHOWCLOSE", "YES" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "TABSIMAGESPACING", "1" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "CLOSEIMAGE", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "CLOSEIMAGEPRESS", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "TABSPADDING", "5x5" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "SIZE", "NULL" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "HIGHCOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.documentTabs_Right, "TABSHIGHCOLOR", "240 255 240" );
	IupSetCallback( GLOBAL.documentTabs_Right, "FLAT_BUTTON_CB", cast(Icallback) &tabbutton_cb );
	IupSetCallback( GLOBAL.documentTabs_Right, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs_Right, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	version(Windows) IupSetCallback( GLOBAL.documentTabs_Right, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
}


extern(C)
{
	private int tabchangePos_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		DocumentTabAction.setActiveDocumentTabs( ih );
		
		return actionManager.DocumentTabAction.tabChangePOS( ih, new_pos );
	}

	// Close the document Iuptab......
	private int tabClose_cb( Ihandle* ih, int pos )
	{
		DocumentTabAction.setActiveDocumentTabs( ih );
		
		Ihandle* _child = IupGetChild( ih, pos );
		CScintilla cSci = ScintillaAction.getCScintilla( _child );
		if( cSci !is null )
		{
			int result;
			
			Ihandle* oldHandle = cast(Ihandle*) IupGetAttribute( ih, "VALUE_HANDLE" );
			
			if( oldHandle != cSci.getIupScintilla )
			{
				Ihandle* _documentTabs = IupGetParent( cSci.getIupScintilla );
				
				result = actionManager.ScintillaAction.closeDocument( cSci.getFullPath(), pos );
				if( IupGetInt( ih, "COUNT" ) > 0 && oldHandle != null )
				{
					int oldPos = IupGetChildPos( ih, oldHandle );
					DocumentTabAction.tabChangePOS( ih, oldPos );
					IupRefresh( _documentTabs );
				}
			}
			else
			{
				result = actionManager.ScintillaAction.closeDocument( cSci.getFullPath(), pos );
			}
			
			if( result == IUP_IGNORE ) return IUP_IGNORE;
		}

		return IUP_CONTINUE;
	}

	private int tabRightClick_cb( Ihandle* ih, int pos )
	{
		DocumentTabAction.setActiveDocumentTabs( ih );
		
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
			return IUP_DEFAULT;
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
			return IUP_DEFAULT;
		});
		
		Ihandle* _moveDocument;
		if( GLOBAL.activeDocumentTabs == GLOBAL.documentTabs )
		{
			_moveDocument = IupItem( GLOBAL.languageItems["torighttabs"].toCString, null );//IupItem( GLOBAL.languageItems["closeall"].toCString, null );
			IupSetAttribute( _moveDocument, "IMAGE", "icon_debug_right" );
			if( IupGetChildCount( GLOBAL.activeDocumentTabs ) == 1 ) IupSetAttribute( _moveDocument, "ACTIVE", "NO" );
			IupSetCallback( _moveDocument, "ACTION", cast(Icallback) function( Ihandle* ih )
			{
				CScintilla beMoveDocumentCSci = ScintillaAction.getActiveCScintilla;

				if( beMoveDocumentCSci !is null )
				{
					Ihandle* dragHandle = IupGetChild( GLOBAL.documentTabs, IupGetInt( GLOBAL.documentTabs, "VALUEPOS" ) );
					//Ihandle* dropHandle = IupGetChild( GLOBAL.documentTabs_Right, 0 );
					
					if( dragHandle != null )
					{
						IupReparent( dragHandle, GLOBAL.documentTabs_Right, null );
						IupRefresh( GLOBAL.documentTabs_Right );
						
						DocumentTabAction.resetTip();

						int newDocumentPos = IupGetChildCount( GLOBAL.documentTabs_Right ) - 1;
						IupSetAttributeId( GLOBAL.documentTabs_Right , "TABTITLE", newDocumentPos, beMoveDocumentCSci.getTitleHandle.toCString );
						IupSetAttributeId( GLOBAL.documentTabs_Right , "TABTIP", newDocumentPos,  beMoveDocumentCSci.getFullPath_IupString.toCString );
						DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs_Right );
						
						IupSetAttribute( GLOBAL.documentTabs_Right , "VALUE_HANDLE", cast(char*) beMoveDocumentCSci.getIupScintilla );
						if( newDocumentPos == 0 )
						{
							IupSetAttributes( GLOBAL.documentSplit, "ACTIVE=YES,BARSIZE=2" );
							IupSetInt( GLOBAL.documentSplit, "VALUE", GLOBAL.documentSplit_value );
						}
						DocumentTabAction.tabChangePOS( GLOBAL.documentTabs_Right, newDocumentPos );
					}				
				}
				
				return IUP_DEFAULT;
			});
		}
		else
		{
			_moveDocument = IupItem( GLOBAL.languageItems["tolefttabs"].toCString, null );//IupItem( GLOBAL.languageItems["closeall"].toCString, null );
			IupSetAttribute( _moveDocument, "IMAGE", "icon_debug_left" );
			IupSetCallback( _moveDocument, "ACTION", cast(Icallback) function( Ihandle* ih )
			{
				CScintilla beMoveDocumentCSci = ScintillaAction.getActiveCScintilla;

				if( beMoveDocumentCSci !is null )
				{
					Ihandle* dragHandle = IupGetChild( GLOBAL.documentTabs_Right, IupGetInt( GLOBAL.documentTabs_Right, "VALUEPOS" ) );
					//Ihandle* dropHandle = IupGetChild( GLOBAL.documentTabs, 0 );
					
					if( dragHandle != null )
					{
						IupReparent( dragHandle, GLOBAL.documentTabs, null );
						IupRefresh( GLOBAL.documentTabs );
						
						DocumentTabAction.resetTip();

						int newDocumentPos = IupGetChildCount( GLOBAL.documentTabs ) - 1;
						IupSetAttributeId( GLOBAL.documentTabs , "TABTITLE", newDocumentPos, beMoveDocumentCSci.getTitleHandle.toCString );
						IupSetAttributeId( GLOBAL.documentTabs , "TABTIP", newDocumentPos,  beMoveDocumentCSci.getFullPath_IupString.toCString );
						DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs );
						
						IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*) beMoveDocumentCSci.getIupScintilla );
						if( IupGetChildCount( GLOBAL.documentTabs_Right ) == 0 )
						{
							GLOBAL.documentSplit_value = IupGetInt( GLOBAL.documentSplit, "VALUE" );
							IupSetAttributes( GLOBAL.documentSplit, "VALUE=1000,BARSIZE=0,ACTIVE=NO" );
							IupSetAttribute( GLOBAL.documentTabs, "ACTIVE","YES" );
							IupSetAttribute( GLOBAL.documentTabs_Right, "ACTIVE","YES" );							
						}
						DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, newDocumentPos );
					}				
				}
				
				return IUP_DEFAULT;
			});
		}
		
		
		Ihandle* popupMenu = IupMenu( 
										_close,
										_closeothers,
										_closeall,
										IupSeparator(),
										_save,
										IupSeparator(),
										_moveDocument,
										null
									);


		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );		

		return IUP_DEFAULT;
	}
	
	private int tabbutton_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		DocumentTabAction.setActiveDocumentTabs( ih );
		
		int pos = IupConvertXYToPos( ih, x, y );
		
		if( IupGetChildCount( GLOBAL.activeDocumentTabs ) == 1 || pos < 0 )
		{
			CScintilla cSci = ScintillaAction.getCScintilla( cast(Ihandle*) IupGetAttribute( ih, "VALUE_HANDLE" ) );
			
			StatusBarAction.update( cSci.getIupScintilla );
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
			
			if( !( actionManager.ScintillaAction.toTreeMarked( cSci.getFullPath() ) & 2 ) )
			{
				GLOBAL.statusBar.setPrjName( "                                            " );
			}
			else
			{
				int prjID = actionManager.ProjectAction.getActiveProjectID();
				scope	_prjName = new IupString( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", prjID ) );
				GLOBAL.statusBar.setPrjName( GLOBAL.languageItems["caption_prj"].toDString() ~ ": " ~ _prjName.toDString );
			}				
		}

		/*
		IupMessage( "CURSORPOS", IupGetGlobal( "CURSORPOS" ) );
		IupMessage( "SCREENPOSITION", IupGetAttribute( ih, "SCREENPOSITION" ) );
		IupMessage( "", toStringz( Integer.toString(x) ~ "x" ~ Integer.toString(y) ) );
		*/
		if( pressed == 1 )
		{
			GLOBAL.tabDocumentPos = -1;
			GLOBAL.dragDocumentTabs = null;
		}
		
		// On/OFF Outline Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			char[] _s = fromStringz( status ).dup;
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
					return IUP_DEFAULT;
				}
			}
		}
		else if( button == IUP_BUTTON3 ) // Right Click
		{
			if( pressed == 0 && pos > -1 ) return tabRightClick_cb( ih, pos );
		}
		
		if( pressed == 0 ) // Release
		{
			if( button == IUP_BUTTON2 )
			{
				return tabClose_cb( ih, pos );
			}
			else if( button == IUP_BUTTON1 )
			{
				if( fromStringz( IupGetAttribute( ih, "CURSOR" ) ) == "HAND" )
				{
					IupSetAttribute( ih, "CURSOR", "ARROW" );
					
					if( GLOBAL.tabDocumentPos > -1 && GLOBAL.dragDocumentTabs != null )
					{
						int			dropPos = -1;
						Ihandle* 	dropHandle;
						Ihandle* 	dragHandle = IupGetChild( GLOBAL.dragDocumentTabs, GLOBAL.tabDocumentPos );
						Ihandle*	dragTabs;
						Ihandle*	dropTabs;
						
						int		screenX, screenY;
						int		tabs1X, tabs1Y, tabs2X, tabs2Y;
						char[]	screenPos	= fromStringz( IupGetGlobal( "CURSORPOS" ) );
						char[]	tabs1Pos	= fromStringz( IupGetAttribute( GLOBAL.documentTabs, "SCREENPOSITION" ) );
						char[]	tabs2Pos	= fromStringz( IupGetAttribute( GLOBAL.documentTabs_Right, "SCREENPOSITION" ) );
							
						if( screenPos.length )
						{
							int crossPos = Util.index( screenPos, "x" );
							if( crossPos < screenPos.length )
							{
								screenX = Integer.atoi( screenPos[0..crossPos] );
								screenY = Integer.atoi( screenPos[crossPos+1..$] );
							}
							else
							{
								GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
								return IUP_DEFAULT;
							}
						}
						else
						{
							GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
							return IUP_DEFAULT;
						}
						
						if( tabs1Pos.length )
						{
							int commaPos = Util.index( tabs1Pos, "," );
							if( commaPos < tabs1Pos.length )
							{
								tabs1X = Integer.atoi( tabs1Pos[0..commaPos] );
								tabs1Y = Integer.atoi( tabs1Pos[commaPos+1..$] );
							}
							else
							{
								GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
								return IUP_DEFAULT;
							}
						}
						else
						{
							GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
							return IUP_DEFAULT;
						}
						
						if( tabs2Pos.length )
						{
							int commaPos = Util.index( tabs2Pos, "," );
							if( commaPos < tabs2Pos.length )
							{
								tabs2X = Integer.atoi( tabs2Pos[0..commaPos] );
								tabs2Y = Integer.atoi( tabs2Pos[commaPos+1..$] );
							}
							else
							{
								GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
								return IUP_DEFAULT;
							}
						}
						else
						{
							GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
							return IUP_DEFAULT;
						}						
						
						dropPos = IupConvertXYToPos( GLOBAL.documentTabs, screenX - tabs1X, screenY - tabs1Y );
						if( dropPos < 0 )
						{
							dropHandle = null;
							
							if( y == screenY - tabs1Y )
							{
								if( screenX > tabs1X && screenX < tabs2X )
								{
									dropTabs = GLOBAL.documentTabs;
									dropHandle = null;
								}
							}
							
							dropPos = IupConvertXYToPos( GLOBAL.documentTabs_Right, screenX - tabs2X, screenY - tabs2Y );								
							if( dropPos > -1 )
							{
								dropTabs = GLOBAL.documentTabs_Right;
								dropHandle = IupGetChild( GLOBAL.documentTabs_Right, dropPos );
							}
							else
							{
								if( dropTabs == null )
								{
									if( screenX - tabs2X < tabs1X )
									{
										dropTabs = GLOBAL.documentTabs_Right;
										dropHandle = null;
									}
								}
							}
						}
						else
						{
							dropTabs = GLOBAL.documentTabs;
							dropHandle = IupGetChild( GLOBAL.documentTabs, dropPos );
						}
						
						if( dragHandle != null  )
						{
							dragTabs = IupGetParent( dragHandle );
							//dropTabs = IupGetParent( dropHandle );
							
							if( dragHandle != dropHandle )
							{
								if( dragTabs == dropTabs )
								{
									if( GLOBAL.tabDocumentPos > pos )
										IupReparent( dragHandle, GLOBAL.activeDocumentTabs, dropHandle );
									else
									{
										if( pos < IupGetInt( GLOBAL.activeDocumentTabs, "COUNT" ) - 1 )
										{
											IupReparent( dragHandle, GLOBAL.activeDocumentTabs, IupGetChild(  GLOBAL.activeDocumentTabs, pos + 1 ) );
										}
										else
										{
											IupReparent( dragHandle, GLOBAL.activeDocumentTabs, null );
										}
									}
								}
								else
								{
									IupReparent( dragHandle, dropTabs, dropHandle );
								}
								
								DocumentTabAction.resetTip();
								IupRefresh( dropTabs );
								
								int newDocumentPos = IupGetChildPos( dropTabs, dragHandle );
								auto dragSci = ScintillaAction.getCScintilla( dragHandle );
								if( dragSci !is null )
								{
									IupSetAttributeId( dropTabs, "TABTITLE", newDocumentPos, dragSci.getTitleHandle.toCString );
									IupSetAttributeId( dropTabs, "TABTIP", newDocumentPos,  dragSci.getFullPath_IupString.toCString );
									DocumentTabAction.setActiveDocumentTabs( dropTabs );
									
									IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*) dragSci.getIupScintilla );
									//DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, newDocumentPos );
									
									DocumentTabAction.updateTabsLayout();
								}
							}
						}
					}
				}

				GLOBAL.tabDocumentPos = -1;
				GLOBAL.dragDocumentTabs = null;				
			}
		}
		else
		{
			if( pos > -1 )
			{
				if( button == IUP_BUTTON1 )
				{
					GLOBAL.tabDocumentPos = pos;
					GLOBAL.dragDocumentTabs = GLOBAL.activeDocumentTabs;
					IupSetAttribute( ih, "CURSOR", "HAND" );
				}
			}
		}

		return IUP_DEFAULT;
	}
}