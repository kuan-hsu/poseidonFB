module dialogs.shortcutDlg;

import iup.iup;
import global, dialogs.baseDlg, dialogs.preferenceDlg;
import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util, tango.io.Stdout;;

class CShortCutDialog : CBaseDialog
{
	private:
	

	
	Ihandle*	textResult;
	char[]		labelName;

	void createLayout( int item, char[] listText )
	{
		Ihandle* bottom = createDlgButton();
		
		char[]		shortKeyValue;
		foreach( char[] s; Util.split( listText[40..length], "+" ) )
		{
			s = Util.trim( s );
			if( s.length ) shortKeyValue ~= ( s ~ "+" );
		}
		if( shortKeyValue.length > 1 ) shortKeyValue = shortKeyValue[0..length-1];

		Ihandle* label0 = IupLabel( toStringz( "Short Key Name: " ~ GLOBAL.shortKeys[item-1].name ) );
		IupSetHandle( "labelKeyName", label0 );

		
		Ihandle* label1 = IupLabel( toStringz( "Current Key: " ~ shortKeyValue ) );

		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL");


		Ihandle* toggleCtrl = IupToggle( "Ctrl", null );
		IupSetHandle( "toggleCtrl", toggleCtrl );
		if( GLOBAL.shortKeys[item-1].keyValue & 0x20000000 ) IupSetAttribute( toggleCtrl, "VALUE", "ON" );else IupSetAttribute( toggleCtrl, "VALUE", "OFF" );

		Ihandle* toggleShift = IupToggle( "Shift", null );
		IupSetHandle( "toggleShift", toggleShift );
		if( GLOBAL.shortKeys[item-1].keyValue & 0x10000000 ) IupSetAttribute( toggleShift, "VALUE", "ON" );else IupSetAttribute( toggleShift, "VALUE", "OFF" );

		Ihandle* toggleAlt = IupToggle( "Alt", null );
		IupSetHandle( "toggleAlt", toggleAlt );
		if( GLOBAL.shortKeys[item-1].keyValue & 0x40000000 ) IupSetAttribute( toggleAlt, "VALUE", "ON" );else IupSetAttribute( toggleAlt, "VALUE", "OFF" );

		Ihandle* keyList = IupList( null );
		IupSetHandle( "keyList", keyList );

		char[] listOptions;
		for( int i = 1; i < 27; ++ i )
		{
			listOptions ~= ( Integer.toString( i ) ~ "=\"" ~ cast(char)( 64 + i ) ~ "\"," );
		}

		for( int i = 27; i < 39; ++ i )
		{
			listOptions ~= ( Integer.toString( i ) ~ "=\"F" ~ Integer.toString( i - 26 ) ~ "\"," );
		}

		listOptions ~=  "DROPDOWN=YES,VALUESTRING=" ~ Util.trim( listText[length-5..length] );
		IupSetAttributes( keyList, toStringz( listOptions ) );

		Ihandle* HBox0 = IupHbox( toggleCtrl, toggleShift, toggleAlt, keyList, null );
		IupSetAttributes( HBox0, "ALIGNMENT=ACENTER, MARGIN=5x5" );


		Ihandle* VBox0 = IupVbox( label0, label1, labelSEPARATOR, HBox0, IupFill(), bottom, null );
		IupAppend( _dlg, VBox0 );
	}	

	public:
	this( int w, int h, int item, char[] listText, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, "Config Short Key", bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );

		createLayout( item, listText );

		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CShortCutDialog_btnOK_cb );
	}

	~this()
	{
		IupSetHandle( "labelKeyName", null );
		IupSetHandle( "toggleCtrl", null );
		IupSetHandle( "toggleShift", null );
		IupSetHandle( "toggleAlt", null );
		IupSetHandle( "keyList", null );
	}

	char[] show( int x, int y ) // Overload form CBaseDialog
	{
		IupPopup( _dlg, x, y );

		return null;
	}	
}


extern(C) // Callback for CSingleTextDialog
{
	int CShortCutDialog_btnOK_cb( Ihandle* ih )
	{
		char[] keyValue;
		
		Ihandle* _ctrl = IupGetHandle( "toggleCtrl" );
		Ihandle* _shift = IupGetHandle( "toggleShift" );
		Ihandle* _alt = IupGetHandle( "toggleAlt" );
		Ihandle* _list = IupGetHandle( "keyList" );
		if( fromStringz( IupGetAttribute( _ctrl, "VALUE" ) ) == "ON" ) keyValue = "C+";else keyValue = "+";
		if( fromStringz( IupGetAttribute( _shift, "VALUE" ) ) == "ON" ) keyValue ~= "S+";else keyValue ~= "+";
		if( fromStringz( IupGetAttribute( _alt, "VALUE" ) ) == "ON" ) keyValue ~= "A+";else keyValue ~= "+";
		keyValue ~= fromStringz( IupGetAttribute( _list, "VALUESTRING" ) );

		int value = CPreferenceDialog.convertShortKeyValue2Integer( keyValue );
		foreach( ShortKey sk; GLOBAL.shortKeys )
		{
			if( sk.keyValue == value )
			{
				IupMessage( "Alarm", toStringz( "The same key value with \"" ~ sk.name ~ "\"" ) );
				return IUP_CONTINUE;
			}
		}
		
		Ihandle* label = IupGetHandle( "labelKeyName" );
		char[] name = fromStringz( IupGetAttribute( label, "TITLE" ) );
		int pos = Util.index( name, ":" );
		if( pos < name.length )	name = Util.trim( name[pos+1..length] );else return IUP_CLOSE;

		switch( name )
		{
			case "Find/Replace":				pos = 0;	break;
			case "Find/Replace In Files":		pos = 1;	break;
			case "Find Next":					pos = 2;	break;
			case "Find Previous":				pos = 3;	break;
			case "Goto Line":					pos = 4;	break;
			case "Undo":						pos = 5;	break;
			case "Redo":						pos = 6;	break;
			case "Goto Defintion":				pos = 7;	break;
			case "Quick Run":					pos = 8;	break;
			case "Run":							pos = 9;	break;
			case "Build":						pos = 10;	break;
			case "On/Off Left-side Window":		pos = 11;	break;
			case "On/Off Bottom-side Window":	pos = 12;	break;
			case "Show Type":					pos = 13;	break;
			case "Reparse":						pos = 14;	break;
			default:
				IupMessage( "Error", "Key Name Error" );
				return IUP_CLOSE;
		}

		GLOBAL.shortKeys[pos].keyValue = value;

		Ihandle* shortCutList = IupGetHandle( "shortCutList" );
		if( shortCutList != null )
		{
			keyValue = CPreferenceDialog.convertShortKeyValue2String( GLOBAL.shortKeys[pos].keyValue );
			char[][] splitWord = Util.split( keyValue, "+" );

			if(  splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			char[] string = Stdout.layout.convert( "{,-40} {,-5} + {,-5} + {,-5} + {,-5}", GLOBAL.shortKeys[pos].name, splitWord[0], splitWord[1], splitWord[2], splitWord[3] );

			IupSetAttribute( shortCutList, toStringz( Integer.toString( pos + 1 ) ), toStringz( string ) );
		}

		return IUP_CLOSE;
	}
}
