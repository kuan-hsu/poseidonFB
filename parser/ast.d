module parser.ast;

class CASTnode
{
private:
	CASTnode			father;
	CASTnode[]			children;
	
public:
	char[]				name;
	uint				kind;
	char[]				protection;
	char[]				type;
	char[]				base;
	int					lineNumber;
	int					endLineNum;

	this( char[] _name, int _kind, char[] _protection, char[] _type, char[] _base, int _lineNumber, int _endLineNum = -1 )
	{
		name = _name;
		kind = _kind;
		protection = _protection;
		type = _type;
		base = _base;
		lineNumber = _lineNumber;
		if( _endLineNum == -1 ) endLineNum = _lineNumber; else endLineNum = _endLineNum;
	}

	~this()
	{
		foreach( CASTnode _ast; children )
		{
			delete _ast;
		}
	}

	// Overload []
	CASTnode opIndex( int i )
	{ 
		if( i < children.length ) return children[i]; else return null;
	}
	
	// Return index of children
	int addChild( CASTnode _child )
	{
		_child.father = this;
		children ~= _child;
		return children.length - 1;
	}

	CASTnode addChild( char[] _name, int _kind, char[] _protection, char[] _type, char[] _base, int _lineNumber, int _endLineNum = -1  )
	{
		CASTnode _child = new CASTnode( _name, _kind, _protection, _type, _base, _lineNumber, _endLineNum );
		_child.father = this;
		children ~= _child;
		return _child;
	}

	int insertChildByLineNumber( CASTnode _child, int _ln )
	{
		int			mid;
		int			low = 0; 
		int			upper = children.length - 1;
		CASTnode[]	tempChildren;

		if( children.length )
		{
			if( children[0].lineNumber > _ln )
			{
				_child.father = this;
				children = _child ~ children;
				return 0;
			}
			else if( children[$-1].lineNumber <= _ln )
			{
				return addChild( _child );
			}
			else
			{
				// Binary Search
				while( low <= upper ) 
				{ 
					mid = ( low + upper ) / 2; 
					if( children[mid].lineNumber < _ln ) 
					{
						low = mid + 1 ;
					}
					else if( children[mid].lineNumber > _ln )
					{
						upper = mid - 1;
					}
					else
					{
						for( int i = low + 1; i < children.length; ++ i )
						{
							if( children[i].lineNumber > _ln )
							{
								low = i;
								break;
							}
						}
					}
				}
			}

			_child.father = this;
			tempChildren = children[0..low] ~ _child ~ children[low..$];
			this.children = tempChildren;
		}
		else
		{
			return addChild( _child );
		}

		return low;
	}
	
	CASTnode getChild( int index )
	{
		if( index < children.length ) return children[index];
		return null;
	}

	CASTnode getFather( int _endLineNum = -1 )
	{
		if( _endLineNum > 0 ) endLineNum = _endLineNum;
		return father;
	}
	
	CASTnode[] getChildren(){ return children; }

	int getChildrenCount(){ return children.length; }
	
	void killChild( int index )
	{	
		if( index >= children.length ) return;

		CASTnode[] tempChildren;
		for( int i = 0; i < children.length; ++ i )
		{
			if( i != index ) tempChildren ~= children[i]; else delete children[i];
		}
		
		zeroChildCount();
		children = tempChildren;
	}

	void zeroChildCount(){ children.length = 0; }// Warning, very dangerous! 
}

version(FBIDE)
{
	const uint B_VARIABLE = 1;
	const uint B_FUNCTION = 2;
	const uint B_SUB = 4;
	const uint B_PROPERTY = 8;
	const uint B_CTOR = 16;
	const uint B_DTOR = 32;
	const uint B_PARAM = 64;
	const uint B_TYPE = 128;
	const uint B_ENUM = 256;
	const uint B_UNION = 512;
	const uint B_CLASS = 1024;
	const uint B_INCLUDE = 2048;
	const uint B_ENUMMEMBER = 4096;
	const uint B_ALIAS = 8192;
	const uint B_BAS = 16384;
	const uint B_BI = 32768;
	const uint B_NAMESPACE = 65536;
	const uint B_MACRO = 131072;
	const uint B_SCOPE = 262144;
	const uint B_DEFINE = 524288;
	const uint B_OPERATOR  = 1048576;
	const uint B_WITH  = 2097152;
	const uint B_USING  = 4194304;
	const uint B_VERSION  = 8388608;

	const uint B_ALL = B_VARIABLE | B_FUNCTION | B_SUB | B_PROPERTY | B_CTOR | B_DTOR | B_PARAM | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_INCLUDE | B_ENUMMEMBER | B_ALIAS | B_NAMESPACE | B_MACRO | B_VERSION;
	const uint B_FIND = B_VARIABLE | B_FUNCTION | B_PROPERTY | B_OPERATOR | B_PARAM | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_ALIAS | B_NAMESPACE | B_MACRO;// | B_SUB;
}

version(DIDE)
{
	const uint D_VARIABLE = 1;
	const uint D_FUNCTION = 2;
	const uint D_STRUCT = 4;
	const uint D_CLASS = 8;
	const uint D_CTOR = 16;
	const uint D_DTOR = 32;
	const uint D_UNION = 64;
	const uint D_ENUM = 128;
	const uint D_ENUMMEMBER = 256;
	const uint D_TEMPLATE = 512;
	const uint D_INTERFACE = 1024;
	const uint D_ALIAS = 2048;
	const uint D_VERSION = 4096;
	const uint D_DEBUG = 8192;
	const uint D_SCOPE = 16384;
	const uint D_IMPORT = 32768;
	const uint D_MIXIN = 65536;
	const uint D_MODULE = 131072;
	const uint D_PARAM = 262144;
	const uint D_STATICIF = 524288;
	const uint D_UNITTEST  = 1048576;
	const uint D_FUNCTIONLITERALS = 2097152;
	const uint D_FUNCTIONPTR = 4194304;

	const uint D_ALL = D_VARIABLE | D_FUNCTION | D_STRUCT | D_CLASS | D_CTOR | D_DTOR | D_UNION | D_ENUM | D_ENUMMEMBER | D_TEMPLATE | D_INTERFACE | D_ALIAS | D_VERSION | D_DEBUG | D_SCOPE | D_IMPORT | D_MIXIN | D_MODULE | D_PARAM | D_STATICIF | D_FUNCTIONLITERALS | D_FUNCTIONPTR;
	const uint D_FIND = D_VARIABLE | D_PARAM | D_FUNCTION | D_STRUCT | D_UNION | D_CLASS | D_INTERFACE | D_ENUM | D_ALIAS | D_TEMPLATE | D_FUNCTIONLITERALS | D_FUNCTIONPTR;
}