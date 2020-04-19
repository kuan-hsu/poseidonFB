module dialogs.shortcutDlg;

import iup.iup;
import global, IDE, tools, dialogs.baseDlg;
import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util, tango.io.Stdout;

class CShortCutDialog : CBaseDialog
{
	private:
	Ihandle*	textResult;
	char[]		labelName;

	void createLayout( int item, char[] listText )
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc" );
		IupSetAttribute( btnAPPLY, "TITLE", GLOBAL.languageItems["clear"].toCString );

		char[]		shortKeyValue;
		foreach( char[] s; Util.split( listText[0..30], "+" ) )
		{
			s = Util.trim( s );
			if( s.length )
			{
				if( shortKeyValue.length ) shortKeyValue ~= ( " + " ~ s ); else shortKeyValue ~= s;
			}
		}
		
		if( item < 8 )
			item --;
		else if( item < 23 )
			item -= 2;
		else if( item < 29 )
			item -= 3;
		else if( item < 34 )
			item -= 4;
		else if( item < 37 )
			item -= 5;
		else if( item < 47 )
			item -= 6;


		Ihandle* label0 = IupLabel( toStringz( GLOBAL.languageItems["shortcutname"].toDString() ~ ": " ~ GLOBAL.shortKeys[item-1].title ) );
		IupSetHandle( "labelKeyName", label0 );
		
		Ihandle* label1 = IupLabel( toStringz( GLOBAL.languageItems["shortcutkey"].toDString() ~ ": " ~ shortKeyValue ) );
		IupSetHandle( "labelKeyValue", label1 );
		
		Ihandle* label2 = IupLabel( toStringz( GLOBAL.shortKeys[item-1].name ) );
		IupSetHandle( "labelName", label2 );
		IupSetAttribute( label2, "VISIBLE", "NO" );

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

		listOptions ~=  "DROPDOWN=YES,VALUESTRING=" ~ Util.trim( listText[25..30] );
		IupSetAttributes( keyList, toStringz( listOptions ) );

		Ihandle* HBox0 = IupHbox( toggleCtrl, toggleShift, toggleAlt, keyList, null );
		IupSetAttributes( HBox0, "ALIGNMENT=ACENTER, MARGIN=5x5" );


		Ihandle* VBox0 = IupVbox( label0, label1, label2, labelSEPARATOR, HBox0, IupFill(), bottom, null );
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
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Monospace, 10" ) );
		}		

		createLayout( item, listText );

		IupSetCallback( btnAPPLY, "ACTION", cast(Icallback) &CShortCutDialog_btnClear_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CShortCutDialog_btnOK_cb );
	}

	~this()
	{
		IupSetHandle( "labelKeyName", null );
		IupSetHandle( "labelName", null );
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
	private int CShortCutDialog_btnClear_cb( Ihandle* ih )
	{
	
		Ihandle* label1_handle = IupGetHandle( "labelKeyValue" );
		if( label1_handle != null ) IupSetAttribute( label1_handle, "TITLE", toStringz( GLOBAL.languageItems["shortcutkey"].toDString() ~ ":" ) );
		
		Ihandle* _ctrl = IupGetHandle( "toggleCtrl" );
		Ihandle* _shift = IupGetHandle( "toggleShift" );
		Ihandle* _alt = IupGetHandle( "toggleAlt" );
		Ihandle* _list = IupGetHandle( "keyList" );
		
		IupSetAttribute( _ctrl, "VALUE", "OFF" );
		IupSetAttribute( _shift, "VALUE", "OFF" );
		IupSetAttribute( _alt, "VALUE", "OFF" );
		IupSetAttribute( _list, "VALUE", "" );
		
		Ihandle* label = IupGetHandle( "labelName" );
		char[] name = fromStringz( IupGetAttribute( label, "TITLE" ) ).dup;
		int pos = -1;
		
		switch( name )
		{
			case "save":						pos = 0;	break;
			case "saveall":						pos = 1;	break;
			case "close":						pos = 2;	break;
			case "newtab":						pos = 3;	break;
			case "nexttab":						pos = 4;	break;
			case "prevtab":						pos = 5;	break;
			
			case "cut":							pos = 6;	break;
			case "copy":						pos = 7;	break;
			case "paste":						pos = 8;	break;
			case "find":						pos = 9;	break;
			case "findinfile":					pos = 10;	break;
			case "findnext":					pos = 11;	break;
			case "findprev":					pos = 12;	break;
			case "gotoline":					pos = 13;	break;
			case "undo":						pos = 14;	break;
			case "redo":						pos = 15;	break;
			case "comment":						pos = 16;	break;
			case "uncomment":					pos = 17;	break;
			case "backnav":						pos = 18;	break;
			case "forwardnav":					pos = 19;	break;
			
			case "showtype":					pos = 20;	break;
			case "defintion":					pos = 21;	break;
			case "procedure":					pos = 22;	break;
			case "autocomplete":				pos = 23;	break;
			case "reparse":						pos = 24;	break;
			
			case "compilerun":					pos = 25;	break;
			case "quickrun":					pos = 26;	break;
			case "run":							pos = 27;	break;
			case "build":						pos = 28;	break;
			
			case "outlinewindow":				pos = 29;	break;
			case "messagewindow":				pos = 30;	break;
			
			case "customtool1":					pos = 31;	break;
			case "customtool2":					pos = 32;	break;
			case "customtool3":					pos = 33;	break;
			case "customtool4":					pos = 34;	break;
			case "customtool5":					pos = 35;	break;
			case "customtool6":					pos = 36;	break;
			case "customtool7":					pos = 37;	break;
			case "customtool8":					pos = 38;	break;
			case "customtool9":					pos = 39;	break;
			default:
				IupMessage( "Error", "Key Name Error" );
				return IUP_CLOSE;
		}
		
		if( pos == -1 )
		{
			IupMessage( "Error", "Key Name( pos ) Error" );
			return  IUP_CLOSE;
		}

		GLOBAL.shortKeys[pos].keyValue = 0;

		return IUP_DEFAULT;
	}
	
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
			if( value > 0 )
			{
				if( sk.keyValue == value )
				{
					IupMessage( "Alarm", toStringz( GLOBAL.languageItems["samekey"].toDString() ~ " \"" ~ sk.name ~ "\"" ) );
					return IUP_CONTINUE;
				}
			}
		}
		
		Ihandle* label = IupGetHandle( "labelName" );
		char[] name = fromStringz( IupGetAttribute( label, "TITLE" ) ).dup;
		int pos = -1;
		
		switch( name )
		{
			case "save":						pos = 0;	break;
			case "saveall":						pos = 1;	break;
			case "close":						pos = 2;	break;
			case "newtab":						pos = 3;	break;
			case "nexttab":						pos = 4;	break;
			case "prevtab":						pos = 5;	break;
			
			case "cut":							pos = 6;	break;
			case "copy":						pos = 7;	break;
			case "paste":						pos = 8;	break;
			case "find":						pos = 9;	break;
			case "findinfile":					pos = 10;	break;
			case "findnext":					pos = 11;	break;
			case "findprev":					pos = 12;	break;
			case "gotoline":					pos = 13;	break;
			case "undo":						pos = 14;	break;
			case "redo":						pos = 15;	break;
			case "comment":						pos = 16;	break;
			case "uncomment":					pos = 17;	break;
			case "backnav":						pos = 18;	break;
			case "forwardnav":					pos = 19;	break;
			
			case "showtype":					pos = 20;	break;
			case "defintion":					pos = 21;	break;
			case "procedure":					pos = 22;	break;
			case "autocomplete":				pos = 23;	break;
			case "reparse":						pos = 24;	break;
			
			case "compilerun":					pos = 25;	break;
			case "quickrun":					pos = 26;	break;
			case "run":							pos = 27;	break;
			case "build":						pos = 28;	break;
			
			case "outlinewindow":				pos = 29;	break;
			case "messagewindow":				pos = 30;	break;
			
			case "customtool1":					pos = 31;	break;
			case "customtool2":					pos = 32;	break;
			case "customtool3":					pos = 33;	break;
			case "customtool4":					pos = 34;	break;
			case "customtool5":					pos = 35;	break;
			case "customtool6":					pos = 36;	break;
			case "customtool7":					pos = 37;	break;
			case "customtool8":					pos = 38;	break;
			case "customtool9":					pos = 39;	break;
			default:
				IupMessage( "Error", "Key Name Error" );
				return IUP_CLOSE;
		}
		
		if( pos == -1 )
		{
			IupMessage( "Error", "Key Name( pos ) Error" );
			return  IUP_CLOSE;
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
			
			char[] string = Stdout.layout.convert( " {,-5} + {,-5} + {,-5} + {,-5} {,-40}", splitWord[0], splitWord[1], splitWord[2], splitWord[3], GLOBAL.shortKeys[pos].title );
			if( pos < 6 )
				pos ++;
			else if( pos < 20 )
				pos += 2;
			else if( pos < 25 )
				pos += 3;
			else if( pos < 29 )
				pos += 4;
			else if( pos < 31 )
				pos += 5;
			else if( pos < 40 )
				pos += 6;

			scope _cString = new IupString ;
			IupSetAttributeId( shortCutList, "", pos + 1, GLOBAL.cString.convert( string ) );
			IupSetInt( shortCutList, "VALUE", pos+1 ); // Set focus node identifier
		}

		return IUP_CLOSE;
	}
}