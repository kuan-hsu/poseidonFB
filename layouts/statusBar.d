module layouts.statusBar;


private import iup.iup;
private import global, scintilla;

Ihandle* createStatusBar()
{
	GLOBAL.statusBar_Line_Col = IupLabel( "             " );
	//IupSetAttributes( labelFont, "VISIBLELINES=1,VISIBLECOLUMNS=1" );

	GLOBAL.statusBar_Ins = IupLabel( "   " );
	GLOBAL.statusBar_FontType = IupLabel( "        " );


	Ihandle*[3] labelSEPARATOR;
	for( int i = 0; i < 3; i++ )
	{
		labelSEPARATOR[i] = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
	}

	//IupSetAttribute( GLOBAL.projectTree.getShadowTreeHandle, "VISIBLE", "NO" );	// Shadow


	Ihandle* StatusBar = IupHbox( IupFill(), /*GLOBAL.projectTree.getShadowTreeHandle,*/ labelSEPARATOR[0], GLOBAL.statusBar_Line_Col, labelSEPARATOR[1], GLOBAL.statusBar_Ins, labelSEPARATOR[2], GLOBAL.statusBar_FontType, null );
	IupSetAttribute( StatusBar, "GAP", "5" );
	IupSetAttribute( StatusBar, "MARGIN", "5" );
	version( Windows )
	{
		IupSetAttribute( StatusBar, "FONT", "Courier New,9" );
	}
	else
	{
		IupSetAttribute( StatusBar, "FONT", "FreeMono,Bold 9" );
	}	

	return StatusBar;

}