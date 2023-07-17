module layouts.customMenu;

class CCustomMenubar
{
private:
	import iup.iup;
	import std.string, Conv = std.conv;
	import core.thread;
	
	struct ItemUnit
	{
		Ihandle*	button;
		Ihandle*	menu;
		string		title;
		bool		bOpen;
	}

	Ihandle*			layout;
	Ihandle*			timer;
	static ItemUnit[]	items;
	
	static void splitCross( ref string _source, ref int w, ref int h )
	{
		auto crossPosition = indexOf( _source, "x" );
		if( crossPosition > 0 )
		{
			w = Conv.to!(int)( _source[0..crossPosition] );
			h = Conv.to!(int)( _source[crossPosition+1..$] );
		}
	}

public:
	this( int interval = 200 )
	{
		layout = IupHbox( null );
		IupSetAttribute( layout, "NGAP", "-1" );

		timer = IupTimer();
		IupSetInt( timer, "TIME", interval );
		IupSetInt( timer, "RUN", 1 );
		IupSetCallback( timer, "ACTION_CB", cast(Icallback) function( Ihandle* _ih )
		{
			Ihandle* preFocusButton = null;
			foreach( _item; this.items )
			{
				if( _item.bOpen )
				{
					preFocusButton = _item.button;
					break;
				}
			}		
		
			if( preFocusButton != null )
			{
				int cursorX, cursorY;
				string cursorXY = fromStringz( IupGetGlobal( "CURSORPOS" ) ).dup;
				splitCross( cursorXY, cursorX, cursorY );

				int			itemX, itemY, itemW, itemH;
				ItemUnit	BeFocusItem;
				foreach( _item; this.items )
				{
					string itemSize = fromStringz( IupGetAttribute( _item.button, "RASTERSIZE" ) ).dup;
					splitCross( itemSize, itemW, itemH );
					itemX = IupGetInt( _item.button, "X" );
					itemY = IupGetInt( _item.button, "Y" );
					
					if( cursorX > itemX && cursorX < itemX + itemW )
						if( cursorY > itemY && cursorY < itemY + itemH )
						{
							BeFocusItem = _item;
							break;
						}
				}
				
				if( BeFocusItem.button != null )
				{
					if( !BeFocusItem.bOpen )
					{
						IupSetGlobal( "MOUSEBUTTON", toStringz( cursorXY ~ " 1 1" ) );
						Thread.sleep( 15.msecs );
						IupSetGlobal( "MOUSEBUTTON", toStringz( cursorXY ~ " 1 0" ) );
					}
				}
			}

			return IUP_DEFAULT;
		});
	}
	
	~this()
	{
		if( timer != null )
		{
			IupSetAttribute( timer, "RUN", "OFF" );
			IupDestroy( timer );
		}
	}
	
	void addItem( string _title, Ihandle* _IupMenu )
	{
		ItemUnit _unit;
		
		_unit.title = _title;
		_unit.button = IupFlatButton( toStringz( " " ~ _unit.title ~ " " ) );
		_unit.menu = _IupMenu;
		
		IupSetAttribute( _unit.button, "CANFOCUS", "NO" );
		IupSetStrAttribute( _unit.button, "PADDING", "2x4" );
		IupSetStrAttribute( _unit.button, "TEXTHLCOLOR", "0 0 0" );
		IupSetStrAttribute( _unit.button, "BORDERWIDTH", "0" );
		//IupSetInt( _unit.button, "FOCUSFEEDBACK", 0 );
		IupSetCallback( _unit.button, "FLAT_ACTION", cast(Icallback) function( Ihandle* _ih )
		{
			int itemW, itemH;
			string itemSize = fromStringz( IupGetAttribute( _ih, "RASTERSIZE") ).dup;
			splitCross( itemSize, itemW, itemH );
	
			int itemX = IupGetInt( _ih, "X" );
			int itemY = IupGetInt( _ih, "Y" );
			
			for( int i = 0; i < this.items.length; ++ i )
			{
				if( this.items[i].button == _ih )
				{
					this.items[i].bOpen = true;
					IupSetStrAttribute( _ih, "FGCOLOR", "0 0 0" );
					IupSetAttribute( _ih, "BGCOLOR", "200 225 245" );
					IupPopup( this.items[i].menu, itemX, itemY + itemH );
					break;
				}
			}
		
			return IUP_DEFAULT;
		});

		
		IupSetCallback( _unit.menu, "MENUCLOSE_CB", cast(Icallback) function( Ihandle* _ih )
		{
			foreach( _item; this.items )
			{
				IupSetStrAttribute( _item.button, "FGCOLOR", null );
				IupSetAttribute( _item.button, "BGCOLOR", null );
			}
			
			for( int i = 0; i < this.items.length; ++ i )
			{
				if( this.items[i].menu == _ih )
				{
					this.items[i].bOpen = false;
					break;
				}
			}		

			return IUP_DEFAULT;
		});

		IupAppend( layout, _unit.button );
		items ~= _unit;
	}

	Ihandle* getLayoutHandle()
	{
		return layout;
	}
	
	ItemUnit[] getItems()
	{
		return items;
	}

	void changeColor( string fgcolor, string bgcolor )
	{
		IupSetStrAttribute( layout, "FGCOLOR", toStringz( fgcolor ) );
		IupSetStrAttribute( layout, "BGCOLOR", toStringz( bgcolor ) );
		for( int i = 0; i < this.items.length; ++ i )
		{
			if( this.items[i].button != null )
			{
				IupSetStrAttribute( this.items[i].button, "FGCOLOR", toStringz( fgcolor ) );
				IupSetStrAttribute( this.items[i].button, "BGCOLOR", toStringz( bgcolor ) );
			}
		}
	}
	
	void setFont( string font )
	{
		for( int i = 0; i < this.items.length; ++ i )
		{
			if( this.items[i].button != null ) IupSetStrAttribute( this.items[i].button, "FONT", toStringz( font ) );
		}
	}
	
	void setInterval( int ms )
	{
		IupSetInt( timer, "TIME", ms );
	}
}