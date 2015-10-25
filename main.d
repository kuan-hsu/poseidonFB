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

//-lgtk-x11-2.0 -lgdk-x11-2.0 -lpangox-1.0 -lgdk_pixbuf-2.0 -lpango-1.0 -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -liup -liup_scintilla
version(Linux)
{
	pragma(lib, "gtk-x11-2.0");
	pragma(lib, "gdk-x11-2.0");
	pragma(lib, "pangox-1.0");
	pragma(lib, "gdk_pixbuf-2.0");
	pragma(lib, "pango-1.0");
	pragma(lib, "gobject-2.0");
	pragma(lib, "gmodule-2.0");
	pragma(lib, "glib-2.0");
}



void main()
{
	if( IupOpen( null, null ) == IUP_ERROR )
	{
		Stdout( "IUP open error!!!" ).newline;
		return;
	}
	createEditorSetting();

	IupScintillaOpen();
	version( Windows )
	{
		//IupSetGlobal( "DEFAULTFONT", toStringz( "Verdana, 10" ) );
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
		//IupSetGlobal( "DEFAULTFONTSIZE", toStringz( "Consolas" ) );
		//IupSetGlobal( "DEFAULTFONTSTYLE", toStringz( "Consolas" ) );
	}
	else
	{
		IupSetGlobal( "DEFAULTFONT", "FreeMono,Bold 10" );
	}

	IupSetGlobal( "UTF8MODE", "YES" );
	version(Windows) IupSetGlobal( "UTF8MODE_FILE", "YES" );

	load_all_images_icons();

	createMenu();
	// Creates a dialog containing the control
	GLOBAL.mainDlg = IupDialog( null );

	createLayout();

	IupSetAttribute( GLOBAL.mainDlg, "TITLE", "Poseidon - FreeBasic IDE" );
	IupSetAttribute( GLOBAL.mainDlg, "RASTERSIZE", "700x500" );
	//IupSetAttribute( GLOBAL.mainDlg, "MARGIN", "10x10");

	IupSetAttribute( GLOBAL.mainDlg, "MENU", "mymenu" );
	IupSetAttribute( GLOBAL.mainDlg, "PLACEMENT", "MAXIMIZED" );
	//IupAppend( GLOBAL.mainDlg, GLOBAL.documentTabs );

	
	
	// Shows dialog
	IupShow( GLOBAL.mainDlg );
	IupSetHandle( "MAIN_DIALOG",GLOBAL.mainDlg );
	IupSetCallback( GLOBAL.mainDlg, "CLOSE_CB", cast(Icallback) &mainDialog_CLOSE_cb );

	createDialog();

	if( GLOBAL.fonts.length == 10 )
	{
		IupSetAttribute( GLOBAL.projectViewTabs, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[2].fontString ) );// Leftside
		IupSetAttribute( GLOBAL.fileListTree, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[3].fontString ) );// Filelist
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[4].fontString ) );// Project
		IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[5].fontString ) );// Outline
		IupSetAttribute( GLOBAL.messageWindowTabs, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[6].fontString ) );// Bottom
		IupSetAttribute( GLOBAL.outputPanel, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[7].fontString ) );// Output
		IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[8].fontString ) );// Search
		IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "FONT", GLOBAL.cString.convert( GLOBAL.fonts[8].fontString ) );// Debugger (shared Search)
	}	

	//IUP main Loop
	IupMainLoop();
	IupClose();
}