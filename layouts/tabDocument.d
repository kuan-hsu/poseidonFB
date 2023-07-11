module layouts.tabDocument;

private import iup.iup, iup.iup_scintilla;
private import global, actionManager, scintilla, menu, tools, parser.autocompletion;
private import std.string, std.conv, Path = std.path, Array = std.array;


void createTabs()
{
	GLOBAL.documentTabs = IupFlatTabs( null );
	
	IupSetAttribute( GLOBAL.documentTabs, "SHOWCLOSE", "YES" );
	IupSetAttribute( GLOBAL.documentTabs, "TABSIMAGESPACING", "1" );
	IupSetAttribute( GLOBAL.documentTabs, "CLOSEIMAGE", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs, "CLOSEIMAGEPRESS", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs, "TABSPADDING", "3x2" );
	IupSetAttribute( GLOBAL.documentTabs, "SIZE", "NULL" );
	IupSetAttribute( GLOBAL.documentTabs, "NAME", "POSEIDON_MAIN_TABS" );
	//IupSetAttribute( GLOBAL.documentTabs, "FORECOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.documentTabs, "HIGHCOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.documentTabs, "TABSHIGHCOLOR", "240 255 240" );
	IupSetStrAttribute( GLOBAL.documentTabs, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );
	IupSetStrAttribute( GLOBAL.documentTabs, "BGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );
	IupSetStrAttribute( GLOBAL.documentTabs, "TABSFORECOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
	IupSetStrAttribute( GLOBAL.documentTabs, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
	IupSetStrAttribute( GLOBAL.documentTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
	IupSetCallback( GLOBAL.documentTabs, "FLAT_BUTTON_CB", cast(Icallback) &tabbutton_cb );
	IupSetCallback( GLOBAL.documentTabs, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	//version(Windows) IupSetCallback( GLOBAL.documentTabs, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
}

void createTabs2()
{
	GLOBAL.documentTabs_Sub = IupFlatTabs( null );
	
	IupSetAttribute( GLOBAL.documentTabs_Sub, "SHOWCLOSE", "YES" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "TABSIMAGESPACING", "1" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "CLOSEIMAGE", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "CLOSEIMAGEPRESS", "icon_clear" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "TABSPADDING", "3x2" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "SIZE", "NULL" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "NAME", "POSEIDON_SUB_TABS" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "HIGHCOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.documentTabs_Sub, "TABSHIGHCOLOR", "240 255 240" );	
	IupSetStrAttribute( GLOBAL.documentTabs_Sub, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );
	IupSetStrAttribute( GLOBAL.documentTabs_Sub, "BGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );
	IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSFORECOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
	IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSBACKCOLOR",  toStringz( GLOBAL.editColor.dlgBack ) );
	IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
	IupSetCallback( GLOBAL.documentTabs_Sub, "FLAT_BUTTON_CB", cast(Icallback) &tabbutton_cb );
	IupSetCallback( GLOBAL.documentTabs_Sub, "TABCLOSE_CB", cast(Icallback) &tabClose_cb );
	IupSetCallback( GLOBAL.documentTabs_Sub, "TABCHANGEPOS_CB", cast(Icallback) &tabchangePos_cb );
	//version(Windows) IupSetCallback( GLOBAL.documentTabs_Sub, "RIGHTCLICK_CB", cast(Icallback) &tabRightClick_cb );
}


extern(C)
{
	private int tabchangePos_cb( Ihandle* ih, int new_pos, int old_pos )
	{
		Ihandle* _oldChild = IupGetChild( ih, old_pos );
		if( _oldChild != null )
		{
			if( fromStringz( IupGetAttribute( _oldChild, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( _oldChild, "AUTOCCANCEL", "YES" );
			if( cast(int) IupScintillaSendMessage( _oldChild, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( _oldChild, 2201, 1, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
			AutoComplete.cleanCalltipContainer();
		}
		
		DocumentTabAction.setActiveDocumentTabs( ih );
		
		GLOBAL.outlineTree.cleanListItems();
		
		return actionManager.DocumentTabAction.tabChangePOS( ih, new_pos );
	}

	// Close the document Iuptab......
	private int tabClose_cb( Ihandle* ih, int pos )
	{
		// The GLOBAL.activeDocumentTabs had already change to ih
		// DocumentTabAction.setActiveDocumentTabs( ih );
		Ihandle* _child = IupGetChild( ih, pos );
		CScintilla cSci = ScintillaAction.getCScintilla( _child );

		if( cSci !is null )
		{
			int result;
			
			Ihandle* oriHandle			= cast(Ihandle*) IupGetAttribute( ih, "VALUE_HANDLE" );
			if( oriHandle != null )
			{
				if( oriHandle != _child )
				{
					result = actionManager.ScintillaAction.closeDocument( cSci.getFullPath(), pos );
					if( result == IUP_DEFAULT )	IupSetAttribute( ih, "VALUE_HANDLE", cast(char*) oriHandle );
				}
				else
				{
					result = actionManager.ScintillaAction.closeDocument( cSci.getFullPath(), pos );
				}
			}
		}

		return IUP_IGNORE; // Because delete CScintilla will call ~this() which include IupDestroy( sci )
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
		
		Ihandle* _savetabs = IupItem( GLOBAL.languageItems["savetabs"].toCString, null );
		IupSetAttribute( _savetabs, "IMAGE", "icon_savetabs" );
		IupSetCallback( _savetabs, "ACTION", cast(Icallback) &menu.saveTabs_cb ); // from menu.d
		
		Ihandle* _close = IupItem( GLOBAL.languageItems["close"].toCString, null );
		IupSetAttribute( _close, "IMAGE", "icon_delete" );
		IupSetCallback( _close, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
			return IUP_DEFAULT;
		});
		
		Ihandle* _explorer = IupItem( GLOBAL.languageItems["openinexplorer"].toCString, null );
		IupSetAttribute( _explorer, "IMAGE", "icon_openfile" );
		IupSetCallback( _explorer, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				version( Windows )
				{
					IupExecute( "explorer", toStringz( "\"" ~ Array.replace( Path.dirName( cSci.getFullPath ), "/", "\\" ) ~ "\"" ) );
				}
				else
				{
					IupExecute( "xdg-open", toStringz( "\"" ~ Path.dirName( cSci.getFullPath ) ~ "\"" ) );
				}
			}
			return IUP_DEFAULT;
		});		
		
		Ihandle* _closeRight = IupItem( GLOBAL.languageItems["closeright"].toCString, null );
		IupSetAttribute( _closeRight, "IMAGE", "icon_deleteright" );
		IupSetCallback( _closeRight, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			int currentPos = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
			for( int i = IupGetChildCount( GLOBAL.activeDocumentTabs ); i > currentPos; -- i )
			{
				CScintilla cSci = ScintillaAction.getCScintilla( IupGetChild( GLOBAL.activeDocumentTabs, i ) );
				if( cSci !is null )
				{
					if( ScintillaAction.closeDocument( cSci.getFullPath, i ) == IUP_IGNORE ) break;
				}
			}
			DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, currentPos );
			IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" , currentPos ); 
			return IUP_DEFAULT;
		});		
		
		Ihandle* _closeothers = IupItem( GLOBAL.languageItems["closeothers"].toCString, null );
		IupSetAttribute( _closeothers, "IMAGE", "icon_deleteothers" );
		IupSetCallback( _closeothers, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )	actionManager.ScintillaAction.closeOthersDocument( cSci.getFullPath() );
			return IUP_DEFAULT;
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
						IupReparent( dragHandle, GLOBAL.documentTabs_Sub, null );
						IupRefresh( GLOBAL.documentTabs_Sub );
						
						DocumentTabAction.resetTip();

						int newDocumentPos = IupGetChildCount( GLOBAL.documentTabs_Sub ) - 1;
						IupSetStrAttributeId( GLOBAL.documentTabs_Sub , "TABTITLE", newDocumentPos, toStringz( beMoveDocumentCSci.getTitle ) );
						IupSetStrAttributeId( GLOBAL.documentTabs_Sub , "TABTIP", newDocumentPos,  toStringz( beMoveDocumentCSci.getFullPath ) );
						DocumentTabAction.setTabItemDocumentImage( GLOBAL.documentTabs_Sub, newDocumentPos, beMoveDocumentCSci.getFullPath );
						DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs_Sub );
						
						IupSetAttribute( GLOBAL.documentTabs_Sub , "VALUE_HANDLE", cast(char*) beMoveDocumentCSci.getIupScintilla );
						if( newDocumentPos == 0 )
						{
							if( GLOBAL.editorSetting01.RotateTabs == "OFF" )
							{
								IupSetInt( GLOBAL.documentSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
								IupSetInt( GLOBAL.documentSplit, "VALUE", GLOBAL.documentSplit_value );
							}
							else
							{
								IupSetInt( GLOBAL.documentSplit2, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
								IupSetInt( GLOBAL.documentSplit2, "VALUE", GLOBAL.documentSplit2_value );
							}
						}
						DocumentTabAction.tabChangePOS( GLOBAL.documentTabs_Sub, newDocumentPos );
						IupSetFocus( dragHandle );
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
						IupSetStrAttributeId( GLOBAL.documentTabs , "TABTITLE", newDocumentPos, toStringz( beMoveDocumentCSci.getTitle ) );
						IupSetStrAttributeId( GLOBAL.documentTabs , "TABTIP", newDocumentPos,  toStringz( beMoveDocumentCSci.getFullPath ) );
						DocumentTabAction.setTabItemDocumentImage( GLOBAL.documentTabs, newDocumentPos, beMoveDocumentCSci.getFullPath );
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
						IupSetFocus( dragHandle );
					}				
				}
				
				return IUP_DEFAULT;
			});
		}
		
		Ihandle* popupMenu;
		if( fromStringz( IupGetAttribute( _moveDocument, "ACTIVE" ) ) == "YES" )
		{
			if( IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" ) < IupGetChildCount( GLOBAL.activeDocumentTabs ) - 1 )
			{
			popupMenu= IupMenu( 
								_close,
								_closeRight,
								_closeothers,
								_closeall,
								IupSeparator(),
								_save,
								_savetabs,
								_explorer,
								IupSeparator(),
								_moveDocument,
								null
								);
			}
			else
			{
			popupMenu= IupMenu( 
								_close,
								_closeothers,
								_closeall,
								IupSeparator(),
								_save,
								_savetabs,
								_explorer,
								IupSeparator(),
								_moveDocument,
								null
								);
			}
		}
		else
		{
			popupMenu= IupMenu( 
								_close,
								_closeothers,
								_closeall,
								IupSeparator(),
								_save,
								_savetabs,
								_explorer,
								null
								);
		}

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
			IupSetFocus( cSci.getIupScintilla );
			StatusBarAction.update( cSci.getIupScintilla );
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
			
			if( !( actionManager.ScintillaAction.toTreeMarked( cSci.getFullPath() ) & 2 ) )
			{
				GLOBAL.statusBar.setPrjName( "                                            " );
			}
			/*
			else
			{
				GLOBAL.statusBar.setPrjName( null, true );
			}
			*/
		}

		
		if( pressed == 1 )
		{
			GLOBAL.tabDocumentPos = -1;
			GLOBAL.dragDocumentTabs = null;
		}
		
		// On/OFF Outline Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			if( DocumentTabAction.isDoubleClick( status ) )
			{
				if( pos > -1 )
				{
					menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
					return IUP_DEFAULT;
				}
				else
				{
					int		RASTER_W = -1;
					string	documentTabs_RASTERSIZE = fSTRz( IupGetAttribute(ih, "RASTERSIZE" ) );
					auto		crossPos = indexOf( documentTabs_RASTERSIZE, "x" );
					
					if( crossPos > 0 )
					{
						RASTER_W = to!(int)( documentTabs_RASTERSIZE[0..crossPos] );

						if( ( x > 12 && x < RASTER_W - 12 ) )
						{
							menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
							return IUP_DEFAULT;
						}
					}
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
						Ihandle*	dropTabs;
						
						int		screenX, screenY;
						int		tabs1X, tabs1Y, tabs2X, tabs2Y;
						string	screenPos	= fSTRz( IupGetGlobal( "CURSORPOS" ) );
						string	tabs1Pos	= fSTRz( IupGetAttribute( GLOBAL.documentTabs, "SCREENPOSITION" ) );
						string	tabs2Pos	= fSTRz( IupGetAttribute( GLOBAL.documentTabs_Sub, "SCREENPOSITION" ) );

						if( screenPos.length )
						{
							auto crossPos = indexOf( screenPos, "x" );
							if( crossPos > 0 )
							{
								screenX = to!(int)( screenPos[0..crossPos] );
								screenY = to!(int)( screenPos[crossPos+1..$] );
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
							auto commaPos = indexOf( tabs1Pos, "," );
							if( commaPos > 0 )
							{
								tabs1X = to!(int)( tabs1Pos[0..commaPos] );
								tabs1Y = to!(int)( tabs1Pos[commaPos+1..$] );
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
							auto commaPos = indexOf( tabs2Pos, "," );
							if( commaPos > 0 )
							{
								tabs2X = to!(int)( tabs2Pos[0..commaPos] );
								tabs2Y = to!(int)( tabs2Pos[commaPos+1..$] );
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
							
							string documentTabs_CLIENTSIZE = fSTRz( IupGetAttribute( GLOBAL.documentTabs, "CLIENTSIZE" ) );
							string documentTabs_RASTERSIZE = fSTRz( IupGetAttribute( GLOBAL.documentTabs, "RASTERSIZE" ) );
							
							int titleH = -1, CLIENT_H = -1, RASTER_H = -1, RASTER_W = -1;
							
							auto crossPos = indexOf( documentTabs_CLIENTSIZE, "x" );
							if( crossPos > 0 )	CLIENT_H = to!(int)( documentTabs_CLIENTSIZE[crossPos+1..$] );
							
							crossPos = indexOf( documentTabs_RASTERSIZE, "x" );
							if( crossPos > 0 )
							{
								RASTER_H = to!(int)( documentTabs_RASTERSIZE[crossPos+1..$] );
								RASTER_W = to!(int)( documentTabs_RASTERSIZE[0..crossPos] );
								titleH = RASTER_H - CLIENT_H; 
							}
							
							if( titleH < 0 || RASTER_W < 0 || RASTER_H < 0 || CLIENT_H < 0 )
							{
								GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
								return IUP_DEFAULT;
							}
							
							if( documentTabs_RASTERSIZE.length )
							{
								if( screenX > tabs1X && screenX < tabs1X + RASTER_W )
								{
									if( screenY > tabs1Y && screenY < tabs1Y + titleH )
									{
										dropTabs = GLOBAL.documentTabs;
										dropHandle = null;
									}									
								}
							}
							
							
							if( dropTabs == null )
							{
								dropPos = IupConvertXYToPos( GLOBAL.documentTabs_Sub, screenX - tabs2X, screenY - tabs2Y );								
								if( dropPos < 0 )
								{
									documentTabs_RASTERSIZE = fSTRz( IupGetAttribute( GLOBAL.documentTabs_Sub, "RASTERSIZE" ) );
									if( documentTabs_RASTERSIZE.length )
									{
										crossPos = indexOf( documentTabs_RASTERSIZE, "x" );
										if( crossPos > 0 )
										{
											RASTER_W = to!(int)( documentTabs_RASTERSIZE[0..crossPos] );
											
											if( screenX > tabs2X && screenX < tabs2X + RASTER_W )
											{
												if( screenY > tabs2Y && screenY < tabs2Y + titleH )
												{
													dropTabs = GLOBAL.documentTabs_Sub;
													dropHandle = null;
												}
											}
										}
									}
								}
								else
								{
									dropTabs = GLOBAL.documentTabs_Sub;
									dropHandle = IupGetChild( GLOBAL.documentTabs_Sub, dropPos );
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
							if( dragHandle != dropHandle )
							{
								if( GLOBAL.dragDocumentTabs == dropTabs )
								{
									if( dropHandle == null )
									{
										IupReparent( dragHandle, GLOBAL.activeDocumentTabs, null ); // pos = -1
									}
									else if( GLOBAL.tabDocumentPos > pos )
									{
										IupReparent( dragHandle, GLOBAL.activeDocumentTabs, dropHandle );
									}
									else
									{
										if( pos < IupGetInt( GLOBAL.activeDocumentTabs, "COUNT" ) - 1 )
											IupReparent( dragHandle, GLOBAL.activeDocumentTabs, IupGetChild(  GLOBAL.activeDocumentTabs, pos + 1 ) );
										else
											IupReparent( dragHandle, GLOBAL.activeDocumentTabs, null );
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
									IupSetStrAttributeId( dropTabs, "TABTITLE", newDocumentPos, toStringz( dragSci.getTitle ) );
									IupSetStrAttributeId( dropTabs, "TABTIP", newDocumentPos,  toStringz( dragSci.getFullPath ) );
									DocumentTabAction.setActiveDocumentTabs( dropTabs );
									
									IupSetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE", cast(char*) dragSci.getIupScintilla );
									//DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, newDocumentPos );
									
									DocumentTabAction.updateTabsLayout();
								}
							}
							IupSetFocus( dragHandle );
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
					if( ih == GLOBAL.documentTabs )
						if( IupGetChildCount( ih ) == 1 ) return IUP_DEFAULT;
							
					
					GLOBAL.tabDocumentPos = pos;
					GLOBAL.dragDocumentTabs = GLOBAL.activeDocumentTabs;
					IupSetAttribute( ih, "CURSOR", "HAND" );
				}
			}
		}

		return IUP_DEFAULT;
	}
}