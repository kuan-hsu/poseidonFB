module parser._parser;

class _PARSER
{
	protected:
		import			parser.ast;
		import			parser.token, parser.autocompletion;
		import			global, tools;
		import			std.string, std.conv, Array = std.array;

		TokenUnit[]		tokens;
		int				tokenIndex;
		CASTnode		activeASTnode;
		
		TokenUnit token()
		{
			if( tokenIndex < tokens.length ) return tokens[tokenIndex]; else throw new Exception( "Method token(), out of range!" );
		}

		TokenUnit prev()
		{
			if( tokenIndex > 0 && tokenIndex < tokens.length ) return tokens[tokenIndex-1];

			throw new Exception( "Method prev(), out of range!" );
		}
		
		TokenUnit next()
		{
			if( tokenIndex < tokens.length - 1 && tokenIndex >= 0 ) return tokens[tokenIndex+1];

			throw new Exception( "Method next(), out of range!" );
		}

		TokenUnit next2()
		{
			if( tokenIndex < tokens.length - 2 && tokenIndex >= 0 ) return tokens[tokenIndex+2];
			
			throw new Exception( "Method next2(), out of range!" );
		}

		void parseToken( TOK t = TOK.Tidentifier )
		{
			if( tokenIndex < tokens.length && tokenIndex >= 0 ) 
				tokenIndex ++;
			else
				throw new Exception( "Method parseToken(), out of range!" );
		}

		TokenUnit getToken()
		{
			if( tokenIndex < tokens.length && tokenIndex >= 0 ) return tokens[tokenIndex];
			
			throw new Exception( "Method getToken(), out of range!" );
		}	

	public:
		this(){}
		
		this( TokenUnit[] _tokens )
		{
			updateTokens( _tokens );
		}
		
		/+
		void printAST( CASTnode _node, string space = "" )
		{
			import std.stdio;
			
			writef( space );
			writef( _node.kind );
			writef( "  " ~ _node.protection ~ "  " ~ _node.name ~ "  " ~ _node.type );

			if( _node.type.length ) Stdout( "  #" ); else Stdout( "#" );
			
			writeln( _node.lineNumber );

			if( _node.getChildrenCount > 0 ) space ~= "--";
			foreach( CASTnode t; _node.getChildren )
			{
				printAST( t, space );
			}

			if( space.length > 1 ) space.length = space.length - 2;
		}		
		+/
		
		bool updateTokens( TokenUnit[] _tokens )
		{
			tokenIndex = 0;
			tokens.length = 0;
			if( _tokens == null )
				tokens.length = 0;
			else
				tokens = _tokens;
			
			if( !_tokens.length ) return false;
			
			return true;
		}
		
		CASTnode json2Ast( string jsonTXT )
		{
			// Nested function
			void splitColon( string _line, ref string _left, ref string _right )
			{
				string[] _lineData = Array.split( _line, ": " );
				if( _lineData.length )
				{
					_left = strip( _lineData[0], "\"" );
					_right = stripRight( _lineData[1], "," );
					_right = strip( strip( _right ), "\"" );
				}
			}		
		
			CASTnode NODE;
			
			foreach( string line; splitLines( jsonTXT ) )
			{
				line = strip( line );
				if( line.length )
				{
					if( line == "{" )
					{
						CASTnode _node = new CASTnode( null, 0, null, null, null, 0 ); 
						if( NODE is null )
							NODE =_node;
						else
						{
							int childIndex = NODE.addChild( _node );
							NODE = NODE[childIndex];
						}
					}
					else if( line == "}" || line == "}," || line == "}]" )
					{
						if( NODE.getFather !is null ) NODE = NODE.getFather;
					}
					else
					{
						string right, left;
						splitColon( line, left, right );

						switch( left )
						{
							case "line":		NODE.lineNumber = to!(int)( right );	break;
							case "tail":		NODE.endLineNum = to!(int)( right );	break;
							case "name":		NODE.name = right;						break;
							case "kind":		NODE.kind = to!(int)( right );			break;
							case "prot":		NODE.protection = right;				break;
							case "type":		NODE.type = right;						break;
							case "base":		NODE.base = right;						break;
							default:
						}
					}
				}			
			}
			
			return NODE;
		}
		
		
		string ast2Json( CASTnode _node )
		{
			string jsonTXT;
			
			jsonTXT ~= "{\n";
			jsonTXT ~=	( "\"line\": \"" ~ to!(string)( _node.lineNumber ) ~ "\",\n" );
			jsonTXT ~=	( "\"tail\": \"" ~ to!(string)( _node.endLineNum )	~ "\",\n" );	
			jsonTXT ~=	( "\"name\": \"" ~ _node.name ~ "\",\n" );
			jsonTXT ~=	( "\"kind\": \"" ~ to!(string)( _node.kind ) ~ "\",\n" );
			jsonTXT ~=	( "\"prot\": \"" ~ _node.protection ~ "\",\n" );
			jsonTXT ~=	( "\"type\": \"" ~ _node.type	~ "\",\n" );
			jsonTXT ~=	( "\"base\": \"" ~ _node.base ~ "\",\n" );
			
			if( _node.getChildrenCount == 0 )
				jsonTXT ~=	"\"sons\": []\n";
			else
			{
				jsonTXT ~= "\"sons\": [\n";
				for( int i = 0; i < _node.getChildrenCount; ++ i )
				{
					jsonTXT ~= ast2Json( _node[i] );
					if( i < _node.getChildrenCount - 1 ) jsonTXT ~= ",\n";
				}
				jsonTXT ~=	"]\n";
			}
			
			jsonTXT ~= "}";
			
			return jsonTXT;
		}		
}