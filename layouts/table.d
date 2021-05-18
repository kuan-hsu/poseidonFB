module layouts.table;

private import iup.iup;
private import tools;

class CTable
{
private:
	import tango.stdc.stringz;
	
	/*
	typedef extern(C) int function( Ihandle*, char*, int, int ) _ACTION;
	_ACTION ACTION;
	
	typedef extern(C) int function( Ihandle*, int, int, int, int, char* ) _BUTTON_CB;
	_BUTTON_CB BUTTON_CB;
	*/
	
	typedef extern(C) int function( Ihandle*, int, char* )		_DBLCLICK_CB;
	_DBLCLICK_CB	DBLCLICK_CB;
	
	class ColumnMember
	{
	private:
		Ihandle* object;
		
		extern(C) static int _action( Ihandle *ih, char *text, int item, int state )
		{
			Ihandle* mother = IupGetParent( IupGetParent( ih ) ); // get recent split handle
			
			while( fromStringz( IupGetAttribute( IupGetParent( mother ), "NAME" ) ) == "TABLESPLIT" )
			{
				mother = IupGetParent( mother );
			}
			
			void _check( Ihandle* _father )
			{
				Ihandle* nextChild;
				
				for( int i = 0; i < IupGetChildCount( _father ) ; ++ i )
				{
					nextChild = IupGetNextChild( _father, nextChild );
					if( nextChild != null )
					{
						if( fromStringz( IupGetAttribute( nextChild, "NAME" ) ) == "TABLEITEM" )
						{
							IupSetInt( nextChild, "VALUE", item );
						}
						else
						{
							_check( nextChild );
						}
					}
				}
			}
			
			_check( mother );
			
			return IUP_DEFAULT;
		}
		
	public:
		this()
		{
			object = IupList( null );
			IupSetAttributes( object, "EXPAND=YES,SCROLLBAR=NO,SHOWDRAGDROP=YES,NAME=TABLEITEM,SHOWIMAGE=YES" );
			/*
			if( ACTION != null ) IupSetCallback( object, "ACTION", cast(Icallback) ACTION );
			if( BUTTON_CB != null ) IupSetCallback( object, "BUTTON_CB", cast(Icallback) BUTTON_CB );
			*/
			IupSetCallback( object, "ACTION", cast(Icallback) &ColumnMember._action );
			if( DBLCLICK_CB != null ) IupSetCallback( object, "DBLCLICK_CB", cast(Icallback) DBLCLICK_CB );
			IupSetCallback( object, "DRAGDROP_CB", cast(Icallback) function( Ihandle* ih )
			{
				return IUP_IGNORE;
			});
		}
	}

	class ColumnFrame
	{
	private:
		Ihandle*	object;
		IupString	title;
		
	public:
		this( char[] _title, ColumnMember _member  )
		{
			object = IupFlatFrame( _member.object );
			title = new IupString( _title );
			IupSetAttribute( object, "TITLE", title.toCString );
			IupSetAttributes( object, "FRAME=NO,FRAMESPACE=0,FRAMEWIDTH=0,TITLELINE=NO" );
		}
	}

	class ColumnSplit
	{
	private:
		Ihandle* object;
		
	public:
		this( Ihandle* _member0, Ihandle* _member1 )
		{
			object = IupSplit( _member0, _member1 );
			IupSetAttribute( object, "COLOR", "255 255 255" );
			IupSetAttributes( object, "BARSIZE=1,EXPAND=YES,NAME=TABLESPLIT" );
			IupSetAttribute( IupGetChild( object, 0 ), "STYLE", "FILL" ); // IupFlatSeparator
		}
		
		this( ColumnFrame _ColumnFrame0, ColumnFrame _ColumnFrame1 )
		{
			object = IupSplit( _ColumnFrame0.object, _ColumnFrame1.object );
			IupSetAttribute( object, "COLOR", "255 255 255" );
			IupSetAttributes( object, "BARSIZE=1,EXPAND=YES,NAME=TABLESPLIT" );
			IupSetAttribute( IupGetChild( object, 0 ), "STYLE", "FILL" ); // IupFlatSeparator
		}
		
		this( ColumnSplit _ColumnSplit, ColumnFrame _ColumnFrame1 )
		{
			object = IupSplit( _ColumnSplit.object, _ColumnFrame1.object );
			IupSetAttribute( object, "COLOR", "255 255 255" );
			IupSetAttributes( object, "BARSIZE=1,EXPAND=YES,NAME=TABLESPLIT" );
			IupSetAttribute( IupGetChild( object, 0 ), "STYLE", "FILL" ); // IupFlatSeparator
		}
	}	
	
	ColumnFrame[]		columnFrame;
	ColumnMember[]		columnMember;
	ColumnSplit[]		split;

public:
	this(){}
	
	/*
	void setAction( _ACTION _action )
	{
		ACTION = _action;
	}
	
	void setBUTTON_CB( _BUTTON_CB _action )
	{
		BUTTON_CB = _action;
	}
	*/
	
	void setDBLCLICK_CB( _DBLCLICK_CB _action )
	{
		DBLCLICK_CB = _action;
	}
	
	Ihandle* getMainHandle()
	{
		if( !split.length ) return columnFrame[$-1].object;
		return split[$-1].object;
	}

	void addColumn( char[] _title )
	{
		auto newMember = new ColumnMember;
		columnMember ~= newMember;
		
		auto newColumnFrame = new ColumnFrame( _title, newMember );
		columnFrame ~= newColumnFrame;
		
		if( columnFrame.length > 2 )
		{
			auto newSplit = new ColumnSplit( split[$-1], columnFrame[$-1] );
			split ~= newSplit;
			
		}
		else if( columnFrame.length > 1 )
		{
			auto newSplit = new ColumnSplit( columnFrame[$-2], columnFrame[$-1] );
			split ~= newSplit;
		}
	}
	
	void setColumnAttribute( char[] _name, char[] _value )
	{
		if( columnFrame.length > 0 ) IupSetAttribute( columnFrame[$-1].object, toStringz( _name ), toStringz( _value ) );
	}
	
	void setColumnAttribute( char[] _value )
	{
		if( columnFrame.length > 0 ) IupSetAttributes( columnFrame[$-1].object, toStringz( _value ) );
	}
	
	void setSplitAttribute( char[] _name, char[] _value )
	{
		if( split.length > 0 ) IupSetAttribute( split[$-1].object, toStringz( _name ), toStringz( _value ) );
	}
	
	void setItemAttribute( char[] _name, char[] _value, int column = -99999 )
	{
		if( column >= 0 )
		{
			if( column < columnMember.length ) IupSetAttribute( columnMember[column].object, toStringz( _name ), toStringz( _value ) );
			return;
		}
	
		for( int i = 0; i < columnMember.length; ++ i )
		{
			IupSetAttribute( columnMember[$-1].object, toStringz( _name ), toStringz( _value ) );
		}
	}
	
	void setItemAttribute( char[] _value, int column = -99999 )
	{
		if( column >= 0 )
		{
			if( column < columnMember.length ) IupSetAttributes( columnMember[column].object, toStringz( _value ) );
			return;
		}
	
		for( int i = 0; i < columnMember.length; ++ i )
		{
			IupSetAttributes( columnMember[$-1].object, toStringz( _value ) );
		}
	}
	
	void addItem( char[][] _value )
	{
		if( _value.length <= columnFrame.length )
		{
			for( int i = 0; i < columnMember.length; ++ i )
			{
				//if( i < _value.length )	IupSetAttribute( columnMember[i].object, "APPENDITEM", toStringz( _value[i] ) ); else break;
				if( i < _value.length )	IupSetAttributeId( columnMember[i].object, "", IupGetInt( columnMember[i].object, "COUNT" ) + 1, toStringz( _value[i] ) ); else break;
			}
		}
		
		//IupRefresh( IupGetParent( getMainHandle() ) );
	}
	
	void setItem( char[][] _value, int id, bool bFocus = true )
	{
		if( columnMember.length )
			if( id <= IupGetInt( columnMember[0].object, "COUNT" ) )
				if( _value.length <= columnFrame.length )
				{
					for( int i = 0; i < columnMember.length; ++ i )
					{
						if( i < _value.length )	IupSetAttributeId( columnMember[i].object, "", id, toStringz( _value[i] ) ); else break;
					}
					if( bFocus ) setSelectionID( id );
				}
	}
	
	void removeItem( int id )
	{
		if( id > 0 )
		{
			foreach( ColumnMember _member; columnMember )
				if( id <= IupGetInt( _member.object, "COUNT" ) ) IupSetInt( _member.object, "REMOVEITEM", id );
		}
	}
	
	void removeAllItem()
	{
		foreach( ColumnMember _member; columnMember )
			IupSetAttribute( _member.object, "REMOVEITEM", "ALL" );
	}
	
	void setSelectionID( int id )
	{
		if( id > 0 )
		{
			foreach( ColumnMember _mem; columnMember )
				IupSetInt( _mem.object, "VALUE", id );
		}
	}
	
	int getSelectionID()
	{
		if( columnMember.length ) return IupGetInt( columnMember[0].object, "VALUE" );
		return -1;
	}
	
	char[][] getSelection( int id = 0 )
	{
		char[][] results;
		
		if( id < 1 ) id = getSelectionID();
		if( id > 0 )
		{
			if( columnMember.length <= 0 ) return null;
			if( id > IupGetInt( columnMember[0].object, "COUNT" ) ) return null;
		
			for( int i = 0; i < columnMember.length; ++ i )
			{
				results ~= fromStringz( IupGetAttributeId( columnMember[i].object, "", id ) ).dup;
			}
		}
		
		return results;
	}
	
	int getItemCount()
	{
		if( columnMember.length ) return IupGetInt( columnMember[0].object, "COUNT" );
		return 0;
	}
	
	int getColumnCount()
	{
		return columnFrame.length;
	}
	
	void setImageId( char[] imageName, int id, int location )
	{
		if( id > 0 )
		{
			for( int i = 0; i < columnMember.length; ++ i )
			{
				if( location & ( 1 << i ) )
				{
					if( imageName.length ) IupSetAttributeId( columnMember[i].object, "IMAGE", id, toStringz( imageName ) ); else IupSetAttributeId( columnMember[i].object, "IMAGE", id, null );
				}
			}
		}
	}
}