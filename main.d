module main;

import iup.iup;
import iup.iup_scintilla;
import iup.iupcontrols;

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

	IupScintillaOpen();
	version( Windows )
	{
		IupSetGlobal( "DEFAULTFONT", "Verdana, 10" );
	}
	else
	{
		IupSetGlobal( "DEFAULTFONT", "FreeMono,Bold 10" );
	}
	IupSetGlobal( "UTF8MODE", "YES" );

	load_all_images_icons();

	createEditorSetting();
	//version(Windows) IupSetGlobal( "DEFAULTFONT", toStringz( GLOBAL.fonts[0].fontString ) );

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

	if( GLOBAL.fonts.length == 9 )
	{
		IupSetAttribute( GLOBAL.projectViewTabs, "FONT", toStringz( GLOBAL.fonts[2].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Leftside
		IupSetAttribute( GLOBAL.fileListTree, "FONT", toStringz( GLOBAL.fonts[3].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Filelist
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[4].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Project
		IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", toStringz( GLOBAL.fonts[5].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Outline
		IupSetAttribute( GLOBAL.messageWindowTabs, "FONT", toStringz( GLOBAL.fonts[6].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Bottom
		IupSetAttribute( GLOBAL.outputPanel, "FONT", toStringz( GLOBAL.fonts[7].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Output
		IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", toStringz( GLOBAL.fonts[8].fontString, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;// Search
	}	
	
	
	
	//ScintillaTest();

	//IUP main Loop
	IupMainLoop();
	IupClose();
}