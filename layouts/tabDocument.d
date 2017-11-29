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
	GLOBAL.documentTabs_Sub = IupFlatTabs( null );
	
	IupSetAttribute( GLOBAL.documentTabs_Sub, "SHOWCLOSE", "YES" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "TABSIMAGESPACING", "1" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "CLOSEIMAGE", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "CLOSEIMAGEPRESS", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "TABSPADDING", "5x5" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "SIZE", "NULL" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "HIGHCOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "TABSHIGHCOLOR", "240 255 240" );
	IupSetCallback( GLOBAL.documentTabs_Sub, "FLAT_BUTTON_CB", cast(Icallback) &tabbutton_cb );
	IupSetCallback( GLOBAL.documentTabs_Sub, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs_Sub, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	version(Windows) IupSetCallback( GLOBAL.documentTabs_Sub, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
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
			if( GLOBAL.editorSetting01.RotateTabs == "OFF" ) IupSetAttribute( _moveDocument, "IMAGE", "icon_debug_right" ); else IupSetAttribute( _moveDocument, "IMAGE", "icon_downarrow");
			if( IupGetChildCount( GLOBAL.activeDocumentTabs ) == 1 ) IupSetAttribute( _moveDocument, "ACTIVE", "NO" );
			IupSetCallback( _moveDocument, "ACTION", cast(Icallback) function( Ihandle* ih )
			{
				CScintilla beMoveDocumentCSci = ScintillaAction.getActiveCScintilla;

				if( beMoveDocumentCSci !is null )
				{
					Ihandle* dragHandle = IupGetChild( GLOBAL.documentTabs, IupGetInt( GLOBAL.documentTabs, "VALUEPOS" ) );
					//Ihandle* dropHandle = IupGetChild( GLOBAL.documentTabs_Sub, 0 );
					
					if( dragHandle != null )
					{
						if( GLOBAL.editorSetting01.RotateTabs == "OFF" )
						{
							IupAppend( GLOBAL.documentSplit, GLOBAL.documentTabs_Sub );
							IupMap( GLOBAL.documentTabs_Sub );
							IupRefresh( GLOBAL.documentSplit );
						}
						else
						{
							IupAppend( GLOBAL.documentSplit2, GLOBAL.documentTabs_Sub );
							IupMap( GLOBAL.documentTabs_Sub );
							IupRefresh( GLOBAL.documentSplit2 );
						}
						
						IupReparent( dragHandle, GLOBAL.documentTabs_Sub, null );
						IupRefresh( GLOBAL.documentTabs_Sub );
						
						DocumentTabAction.resetTip();

						int newDocumentPos = IupGetChildCount( GLOBAL.documentTabs_Sub ) - 1;
						IupSetAttributeId( GLOBAL.documentTabs_Sub , "TABTITLE", newDocumentPos, beMoveDocumentCSci.getTitleHandle.toCString );
						IupSetAttributeId( GLOBAL.documentTabs_Sub , "TABTIP", newDocumentPos,  beMoveDocumentCSci.getFullPath_IupString.toCString );
						DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs_Sub );
						
						IupSetAttribute( GLOBAL.documentTabs_Sub , "VALUE_HANDLE", cast(char*) beMoveDocumentCSci.getIupScintilla );
						if( newDocumentPos == 0 )
						{
							if( GLOBAL.editorSetting01.RotateTabs == "OFF" )
							{
								IupSetAttributes( GLOBAL.documentSplit, "BARSIZE=2" );
								IupSetInt( GLOBAL.documentSplit, "VALUE", GLOBAL.documentSplit_value );
							}
							else
							{
								IupSetAttributes( GLOBAL.documentSplit2, "BARSIZE=2" );
								IupSetInt( GLOBAL.documentSplit2, "VALUE", GLOBAL.documentSplit2_value );
							}
						}
						DocumentTabAction.tabChangePOS( GLOBAL.documentTabs_Sub, newDocumentPos );
					}				
				}
				
				return IUP_DEFAULT;
			});
		}
		else
		{
			_moveDocument = IupItem( GLOBAL.languageItems["tolefttabs"].toCString, null );//IupItem( GLOBAL.languageItems["closeall"].toCString, null );
			if( GLOBAL.editorSetting01.RotateTabs == "OFF" ) IupSetAttribute( _moveDocument, "IMAGE", "icon_debug_left" ); else IupSetAttribute( _moveDocument, "IMAGE", "icon_uparrow");
			IupSetCallback( _moveDocument, "ACTION", cast(Icallback) function( Ihandle* ih )
			{
				CScintilla beMoveDocumentCSci = ScintillaAction.getActiveCScintilla;

				if( beMoveDocumentCSci !is null )
				{
					Ihandle* dragHandle = IupGetChild( GLOBAL.documentTabs_Sub, IupGetInt( GLOBAL.documentTabs_Sub, "VALUEPOS" ) );
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
						if( IupGetChildCount( GLOBAL.documentTabs_Sub ) == 0 )
						{
							if( GLOBAL.editorSetting01.RotateTabs == "OFF" )
							{
								GLOBAL.documentSplit_value = IupGetInt( GLOBAL.documentSplit, "VALUE" );
								IupSetAttributes( GLOBAL.documentSplit, "VALUE=1000,BARSIZE=0" );
							}
							else
							{
								GLOBAL.documentSplit2_value = IupGetInt( GLOBAL.documentSplit2, "VALUE" );
								IupSetAttributes( GLOBAL.documentSplit2, "VALUE=1000,BARSIZE=0" );
							}
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
		IupMessage( "SIZE", IupGetAttribute( ih, "SIZE" ) );
		IupMessage( "CLIENTSIZE ", IupGetAttribute( ih, "CLIENTSIZE" ) );
		IupMessage( "RASTERSIZE ", IupGetAttribute( ih, "RASTERSIZE" ) );
		
		IupMessage( "messageSplit SCREENPOSITION", IupGetAttribute( GLOBAL.messageSplit, "SCREENPOSITION" ) );
		
		IupMessage( "messageSplit POSITION", IupGetAttribute( GLOBAL.messageSplit, "POSITION" ) );
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
						char[]	tabs2Pos	= fromStringz( IupGetAttribute( GLOBAL.documentTabs_Sub, "SCREENPOSITION" ) );

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
							
							
							char[] documentTabs_Size = fromStringz( IupGetAttribute( GLOBAL.documentTabs, "RASTERSIZE" ) );
							if( documentTabs_Size.length )
							{
								if( GLOBAL.editorSetting01.RotateTabs == "OFF" )
								{
									if( screenX > tabs1X && screenX < tabs2X )
									{
										int crossPos = Util.index( documentTabs_Size, "x" );
										if( crossPos < documentTabs_Size.length )
										{
											tabs2Y = Integer.atoi( documentTabs_Size[crossPos+1..$] );
											
											if( screenY > tabs1Y && screenY < tabs1Y + tabs2Y )
											{
												dropTabs = GLOBAL.documentTabs;
												dropHandle = null;
											}
										}									
									}
								}
								else
								{
									if( screenY > tabs1Y && screenY < tabs2Y )
									{
										int crossPos = Util.index( documentTabs_Size, "x" );
										if( crossPos < documentTabs_Size.length )
										{
											tabs2X = Integer.atoi( documentTabs_Size[0..crossPos] );
											
											if( screenX > tabs1X && screenX < tabs1X + tabs2X )
											{
												dropTabs = GLOBAL.documentTabs;
												dropHandle = null;
											}
										}
									}
								}
							}
							
							
							
							dropPos = IupConvertXYToPos( GLOBAL.documentTabs_Sub, screenX - tabs2X, screenY - tabs2Y );								
							if( dropPos > -1 )
							{
								dropTabs = GLOBAL.documentTabs_Sub;
								dropHandle = IupGetChild( GLOBAL.documentTabs_Sub, dropPos );
							}
							else
							{
								if( dropTabs == null )
								{
									char[] documentTabs_SubSize = fromStringz( IupGetAttribute( GLOBAL.documentTabs_Sub, "RASTERSIZE" ) );
									if( documentTabs_SubSize.length )
									{
										int crossPos = Util.index( documentTabs_SubSize, "x" );
										if( crossPos < documentTabs_SubSize.length )
										{
											tabs1X = Integer.atoi( documentTabs_SubSize[0..crossPos] );
											tabs1Y = Integer.atoi( documentTabs_SubSize[crossPos+1..$] );
											
											if( screenX > tabs2X && screenX < tabs2X + tabs1X )
											{
												if( screenY > tabs2Y && screenY < tabs2Y + tabs1Y )
												{
													dropTabs = GLOBAL.documentTabs_Sub;
													dropHandle = null;
												}
											}
										}
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