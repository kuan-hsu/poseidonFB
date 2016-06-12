module parser.ast;

class CASTnode
{
	private:
	CASTnode			father;
	CASTnode[]			children;
	
	public:
	char[]				name;
	int					kind;
	char[]				protection;
	char[]				type;
	char[]				base;
	int					lineNumber;
	int					endLineNum;

	this(){}

	this( char[] _name, int _kind, char[] _protection, char[] _type, char[] _base, int _lineNumber, int _endLineNum = -1 )
	{
		name = _name;
		kind = _kind;
		protection = _protection;
		type = _type;
		base = _base;
		lineNumber = _lineNumber;
		endLineNum = _endLineNum = -1 ? _lineNumber : _endLineNum;
	}

	~this()
	{
		foreach( CASTnode _ast; children )
		{
			delete _ast;
		}
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

	void zeroChildCount(){ children.length = 0; }// Warning, very dangerous! 
}

const int B_VARIABLE = 1;
const int B_FUNCTION = 2;
const int B_SUB = 4;
const int B_PROPERTY = 8;
const int B_CTOR = 16;
const int B_DTOR = 32;
const int B_PARAM = 64;
const int B_TYPE = 128;
const int B_ENUM = 256;
const int B_UNION = 512;
const int B_CLASS = 1024;
const int B_INCLUDE = 2048;
const int B_ENUMMEMBER = 4096;
const int B_ALIAS = 8192;
const int B_BAS = 16384;
const int B_BI = 32768;
const uint B_NAMESPACE = 65536;
const uint B_MACRO = 131072;
const uint B_SCOPE = 262144;
const uint B_DEFINE = 524288;
const uint B_OPERATOR  = 1048576;

const int B_ALL = B_VARIABLE | B_FUNCTION | B_SUB | B_PROPERTY | B_CTOR | B_DTOR | B_PARAM | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_INCLUDE | B_ENUMMEMBER | B_ALIAS | B_NAMESPACE | B_MACRO;
const int B_FIND = B_VARIABLE | B_FUNCTION | B_PROPERTY | B_PARAM | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_ALIAS | B_NAMESPACE | B_MACRO;// | B_SUB;