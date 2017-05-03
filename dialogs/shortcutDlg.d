module dialogs.shortcutDlg;

import iup.iup;
import global, IDE, tools, dialogs.baseDlg;
import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util, tango.io.Stdout;;

class CShortCutDialog : CBaseDialog
{
	private:
	Ihandle*	textResult;
	char[]		labelName;

	void createLayout( int item, char[] listText )
	{
		Ihandle* bottom = createDlgButton();

		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );		
		
		char[]		shortKeyValue;
		foreach( char[] s; Util.split( listText[30..length], "+" ) )
		{
			s = Util.trim( s );
			if( s.length )
			{
				if( shortKeyValue.length ) shortKeyValue ~= ( " + " ~ s ); else shortKeyValue ~= s;
			}
		}

		Ihandle* label0 = IupLabel( toStringz( GLOBAL.languageItems["shortcutname"].toDString() ~ ": " ~ GLOBAL.shortKeys[item-1].name ) );
		IupSetHandle( "labelKeyName", label0 );

		
		Ihandle* label1 = IupLabel( toStringz( GLOBAL.languageItems["shortcutkey"].toDString() ~ ": " ~ shortKeyValue ) );

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

		listOptions ~= ( "39=\"TAB\"," );

		listOptions ~=  "DROPDOWN=YES,VALUESTRING=" ~ Util.trim( listText[length-5..length] );
		IupSetAttributes( keyList, toStringz( listOptions ) );

		Ihandle* HBox0 = IupHbox( toggleCtrl, toggleShift, toggleAlt, keyList, null );
		IupSetAttributes( HBox0, "ALIGNMENT=ACENTER, MARGIN=5x5" );


		Ihandle* VBox0 = IupVbox( label0, label1, labelSEPARATOR, HBox0, IupFill(), bottom, null );
		IupSetAttributes( VBox0, "MARGIN=5x5" );
		IupAppend( _dlg, VBox0 );
	}	

	public:
	this( int w, int h, int item, char[] listText, bool bResize = false, char[] parent = null )
	{
		super( w, h, GLOBAL.languageItems["shortcut"].toDString(), bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );
		}		

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
	private int CShortCutDialog_btnOK_cb( Ihandle* ih )
	{
		char[] keyValue;
		
		Ihandle* _ctrl = IupGetHandle( "toggleCtrl" );
		Ihandle* _shift = IupGetHandle( "toggleShift" );
		Ihandle* _alt = IupGetHandle( "toggleAlt" );
		Ihandle* _list = IupGetHandle( "keyList" );
		if( fromStringz( IupGetAttribute( _ctrl, "VALUE" ) ) == "ON" ) keyValue = "C+";else keyValue = "+";
		if( fromStringz( IupGetAttribute( _shift, "VALUE" ) ) == "ON" ) keyValue ~= "S+";else keyValue ~= "+";
		if( fromStringz( IupGetAttribute( _alt, "VALUE" ) ) == "ON" ) keyValue ~= "A+";else keyValue ~= "+";
		keyValue ~= fromStringz( IupGetAttribute( _list, "VALUESTRING" ) ).dup;

		int value = IDECONFIG.convertShortKeyValue2Integer( keyValue );
		foreach( ShortKey sk; GLOBAL.shortKeys )
		{
			if( sk.keyValue == value )
			{
				IupMessage( "Alarm", toStringz( GLOBAL.languageItems["samekey"].toDString() ~ " \"" ~ sk.name ~ "\"" ) );
				return IUP_CONTINUE;
			}
		}
		
		Ihandle* label = IupGetHandle( "labelKeyName" );
		char[] name = fromStringz( IupGetAttribute( label, "TITLE" ) ).dup;
		int pos = Util.index( name, ":" );
		if( pos < name.length )	name = Util.trim( name[pos+1..length] );else return IUP_CLOSE;

		switch( name )
		{
			case "find":						pos = 0;	break;
			case "findinfile":					pos = 1;	break;
			case "findnext":					pos = 2;	break;
			case "findprev":					pos = 3;	break;
			case "gotoline":					pos = 4;	break;
			case "undo":						pos = 5;	break;
			case "redo":						pos = 6;	break;
			case "defintion":					pos = 7;	break;
			case "quickrun":					pos = 8;	break;
			case "run":							pos = 9;	break;
			case "build":						pos = 10;	break;
			case "outlinewindow":				pos = 11;	break;
			case "messagewindow":				pos = 12;	break;
			case "showtype":					pos = 13;	break;
			case "reparse":						pos = 14;	break;
			case "save":						pos = 15;	break;
			case "saveall":						pos = 16;	break;
			case "close":						pos = 17;	break;
			case "nexttab":						pos = 18;	break;
			case "prevtab":						pos = 19;	break;
			case "newtab":						pos = 20;	break;
			case "autocomplete":				pos = 21;	break;
			case "compilerun":					pos = 22;	break;
			case "comment":						pos = 23;	break;
			case "backdefinition":				pos = 24;	break;
			case "customtool1":					pos = 25;	break;
			case "customtool2":					pos = 26;	break;
			case "customtool3":					pos = 27;	break;
			case "customtool4":					pos = 28;	break;
			case "customtool5":					pos = 29;	break;
			case "customtool6":					pos = 30;	break;
			case "customtool7":					pos = 31;	break;
			case "customtool8":					pos = 32;	break;
			case "customtool9":					pos = 33;	break;
			default:
				IupMessage( "Error", "Key Name Error" );
				return IUP_CLOSE;
		}

		GLOBAL.shortKeys[pos].keyValue = value;

		Ihandle* shortCutList = IupGetHandle( "shortCutList" );
		if( shortCutList != null )
		{
			keyValue = IDECONFIG.convertShortKeyValue2String( GLOBAL.shortKeys[pos].keyValue );
			char[][] splitWord = Util.split( keyValue, "+" );

			if(  splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			char[] string = Stdout.layout.convert( "{,-30} {,-5} + {,-5} + {,-5} + {,-5}", GLOBAL.shortKeys[pos].title, splitWord[0], splitWord[1], splitWord[2], splitWord[3] );

			scope _cString = new IupString ;
			IupSetAttribute( shortCutList, _cString.convert( Integer.toString( pos + 1 ) ), GLOBAL.cString.convert( string ) );
		}

		return IUP_CLOSE;
	}
}