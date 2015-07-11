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

	Ihandle* StatusBar = IupHbox( IupFill(), labelSEPARATOR[0], GLOBAL.statusBar_Line_Col, labelSEPARATOR[1], GLOBAL.statusBar_Ins, labelSEPARATOR[2], GLOBAL.statusBar_FontType, null );
	IupSetAttribute( StatusBar, "GAP", "5" );
	IupSetAttribute( StatusBar, "MARGIN", "5" );

	return StatusBar;

}