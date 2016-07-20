module main;

import iup.iup;
import iup.iup_scintilla;

import global, layout, images.imageData;
import menu, scintilla;

import tango.io.Stdout, tango.stdc.stringz;


version(Windows)
{
	pragma(lib, "gdi32.lib");
	pragma(lib, "user32.lib");
	pragma(lib, "comdlg32.lib");
	pragma(lib, "comctl32.lib");
	pragma(lib, "ole32.lib");
}
else
{
	// libgtk2.0-dev
	//-lgtk-x11-2.0 -lgdk-x11-2.0 -lpangox-1.0 -lgdk_pixbuf-2.0 -lpango-1.0 -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -liup -liup_scintilla
	//pragma(lib, "gtk-x11-2.0");
	//pragma(lib, "gdk-x11-2.0");
	//pragma(lib, "pangox-1.0");
	pragma(lib, "gdk_pixbuf-2.0");
	pragma(lib, "pango-1.0");
	pragma(lib, "gobject-2.0");
	pragma(lib, "gmodule-2.0");
	pragma(lib, "glib-2.0");
	pragma(lib, "iup");
	pragma(lib, "iup_scintilla");
}

version(Windows)
{
	import tango.sys.win32.UserGdi;

	bool bRunAgain;
	
	extern( Windows ) BOOL enumWindowsProc( HWND hWnd, LPARAM lParam )
	{
		int length = GetWindowTextLengthA( hWnd );

		char[] title;
		title.length = length + 1;
		
		GetWindowTextA( hWnd, title.ptr, length + 1 );

		if( title.length > 13 )
		{
			// poseidonFB - FreeBasic IDE
			if( title[length-14..length] == "FreeBasic IDE\0" )
			{
				if( IsIconic( hWnd ) )
				{
					ShowWindow( hWnd, SW_RESTORE);  
				}
				else
				{
					SetForegroundWindow( hWnd );
				}
				bRunAgain = true;
				return false;
			}
		}

		return TRUE;
	}
}




void main()
{
	version(Windows)
	{
		EnumWindows( &enumWindowsProc, 0 );
		if( bRunAgain ) return;

		/*
		HANDLE handle = CreateMutexA( NULL, FALSE, "poseidonFB.exe" );

		if( GetLastError( ) == ERROR_ALREADY_EXISTS )
		{
			EnumWindows( &enumWindowsProc, 0 );
			return;
		}
		*/
	}


	if( IupOpen( null, null ) == IUP_ERROR )
	{
		Stdout( "IUP open error!!!" ).newline;
		return;
	}
	
	createEditorSetting();

	IupScintillaOpen();

	// Set Default Font
	if(  GLOBAL.fonts[0].fontString.length )
	{
		IupSetGlobal( "DEFAULTFONT", toStringz( GLOBAL.fonts[0].fontString.dup ) );

		if( GLOBAL.fonts[0].fontString.length )
		{
			int comma = Util.index( GLOBAL.fonts[0].fontString, "," );
			if( comma < GLOBAL.fonts[0].fontString.length )
			{
				IupSetGlobal( "DEFAULTFONTFACE", toStringz( ( GLOBAL.fonts[0].fontString[0..comma] ).dup ) );

				for( int i = GLOBAL.fonts[0].fontString.length - 1; i > comma; -- i )
				{
					if( GLOBAL.fonts[0].fontString[i] < 48 || GLOBAL.fonts[0].fontString[i] > 57 )
					{
						IupSetGlobal( "DEFAULTFONTSIZE", toStringz( ( GLOBAL.fonts[0].fontString[i+1..length] ).dup ) );

						if( ++comma  < i ) IupSetGlobal( "DEFAULTFONTSTYLE", toStringz( ( GLOBAL.fonts[0].fontString[comma..i] ).dup ) );
						
						break;
					}
				}
				
			}
		}
	}

	IupSetGlobal( "UTF8MODE", "YES" );
	version(Windows) IupSetGlobal( "UTF8MODE_FILE", "YES" );

	load_all_images_icons();

	createMenu();
	// Creates a dialog containing the control
	GLOBAL.mainDlg = IupDialog( null );

	createLayout();

	IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
	//IupSetAttribute( GLOBAL.mainDlg, "RASTERSIZE", "700x500" );
	IupSetAttribute( GLOBAL.mainDlg, "ICON", "icon_poseidonFB" );
	//IupSetAttribute( GLOBAL.mainDlg, "MARGIN", "10x10");

	IupSetAttribute( GLOBAL.mainDlg, "MENU", "mymenu" );
	IupSetAttribute( GLOBAL.mainDlg, "PLACEMENT", "MAXIMIZED" );
	//IupAppend( GLOBAL.mainDlg, GLOBAL.documentTabs );

	IupSetGlobal( "INPUTCALLBACKS", "YES" );
	IupSetFunction( "GLOBALKEYPRESS_CB", cast(Icallback) &GlobalKeyPress_CB );

	
	// Shows dialog
	IupShow( GLOBAL.mainDlg );

	// Set Split %
	IupSetInt( GLOBAL.explorerSplit, "VALUE", 170 );
	IupSetInt( GLOBAL.messageSplit, "VALUE", 800 );
	IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );


	IupSetHandle( "MAIN_DIALOG",GLOBAL.mainDlg );
	
	IupSetCallback( GLOBAL.mainDlg, "CLOSE_CB", cast(Icallback) &mainDialog_CLOSE_cb );
	IupSetCallback( GLOBAL.mainDlg, "K_ANY", cast(Icallback) &mainKany_cb );
	

	createDialog();

	//if( GLOBAL.fonts.length == 11 )
	//{
		IupSetAttribute( GLOBAL.projectViewTabs, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[2].fontString ) );// Leftside
		IupSetAttribute( GLOBAL.fileListTree.getTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[3].fontString ) );// Filelist
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[4].fontString ) );// Project
		IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[5].fontString ) );// Outline
		IupSetAttribute( GLOBAL.messageWindowTabs, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[6].fontString ) );// Bottom
		IupSetAttribute( GLOBAL.outputPanel, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[7].fontString ) );// Output
		IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[8].fontString ) );// Search
		IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[8].fontString ) );// Debugger (shared Search)
	//}	

	//IUP main Loop
	IupMainLoop();
	IupClose();

	/*
	version( Windows )
	{
		if( handle != null )
		{
			ReleaseMutex( handle );
			CloseHandle( handle );
		}
	}
	*/
}