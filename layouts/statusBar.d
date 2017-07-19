module layouts.statusBar;

class CStatusBar
{
	private:
	import		iup.iup;
	import		tools;
	import		tango.stdc.stringz, Integer = tango.text.convert.Integer;
	
	Ihandle*	layoutHandle, prjName, LINExCOL, Ins, EOLType, EncodingType;
	IupString	_name, _lc, _ins, _eol, _en;
	
	
	void createLayout()
	{
		prjName = IupLabel( null );
		IupSetAttribute( prjName, "SIZE", "350x" );
		LINExCOL = IupLabel( "             " );
		Ins = IupLabel( "   " );
		EOLType = IupLabel( "        " );
		EncodingType = IupLabel( "           " );
		
		Ihandle*[4] labelSEPARATOR;
		for( int i = 0; i < 4; i++ )
		{
			labelSEPARATOR[i] = IupLabel( null ); 
			IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
		}		

		// Ihandle* StatusBar = IupHbox( GLOBAL.statusBar_PrjName, IupFill(), labelSEPARATOR[0], GLOBAL.statusBar_Line_Col, labelSEPARATOR[1], GLOBAL.statusBar_Ins, labelSEPARATOR[2], GLOBAL.statusBar_EOLType, labelSEPARATOR[3], GLOBAL.statusBar_encodingType, null );
		layoutHandle = IupHbox( prjName, IupFill(), labelSEPARATOR[0], LINExCOL, labelSEPARATOR[1], Ins, labelSEPARATOR[2], EOLType, labelSEPARATOR[3], EncodingType, null );
		IupSetAttributes( layoutHandle, "GAP=5,MARGIN=5,ALIGNMENT=ACENTER" );
		
		version(Windows)
		{
			IupSetAttribute( layoutHandle, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( layoutHandle, "FONT", "FreeMono,Bold 9" );
		}			
	}
	
	
	public:
	this()
	{
		_name = new IupString();
		_lc = new IupString();
		_ins = new IupString();
		_eol = new IupString();
		_en = new IupString();
		
		createLayout();
	}
	
	~this()
	{
		//delete _name, _lc, _ins, _eol, _en;
	}
	
	Ihandle* getLayoutHandle()
	{
		return layoutHandle;
	}
	
	void setPrjNameSize( int width )
	{
		IupSetAttribute( prjName, "SIZE", toStringz( Integer.toString( width / 3 ) ~ "x" ) );
	}
	
	void setPrjName( char[] name )
	{
		_name = name;
		IupSetAttribute( prjName, "TITLE", _name.toCString );
	}
	
	void setLINExCOL( char[] lc )
	{
		_lc = lc;
		IupSetAttribute( LINExCOL, "TITLE", _lc.toCString );
	}

	void setIns( char[] ins )
	{
		_ins = ins;
		IupSetAttribute( Ins, "TITLE", _ins.toCString );
	}

	void setEOLType( char[] eol )
	{
		_eol = eol;
		IupSetAttribute( EOLType, "TITLE", _eol.toCString );
	}

	void setEncodingType( char[] en )
	{
		_en = en;
		IupSetAttribute( EncodingType, "TITLE", _en.toCString );
	}
}