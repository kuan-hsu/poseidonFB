module layouts.statusBar;


private import iup.iup;
private import global, scintilla;

Ihandle* createStatusBar()
{
	GLOBAL.statusBar_Line_Col = IupLabel( "             " );
	//IupSetAttributes( labelFont, "VISIBLELINES=1,VISIBLECOLUMNS=1" );

	GLOBAL.statusBar_Ins = IupLabel( "   " );
	GLOBAL.statusBar_EOLType = IupLabel( "        " );
	GLOBAL.statusBar_encodingType = IupLabel( "           " );


	Ihandle*[4] labelSEPARATOR;
	for( int i = 0; i < 4; i++ )
	{
		labelSEPARATOR[i] = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
	}


	Ihandle* StatusBar = IupHbox( IupFill(), labelSEPARATOR[0], GLOBAL.statusBar_Line_Col, labelSEPARATOR[1], GLOBAL.statusBar_Ins, labelSEPARATOR[2], GLOBAL.statusBar_EOLType, labelSEPARATOR[3], GLOBAL.statusBar_encodingType, null );
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