module parser._parser;

class _PARSER
{
	protected:
		import			iup.iup;
		
		import			parser.ast;
		import			parser.token, parser.autocompletion;

		import			tango.io.FilePath, tango.text.Ascii, Path = tango.io.Path;
		import			Util = tango.text.Util, tango.stdc.stringz;
		import 			tango.io.Stdout, Integer = tango.text.convert.Integer;

		import			global, tools;

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

		void printAST( CASTnode _node, char[] space = "" )
		{
			Stdout( space );
			Stdout( _node.kind );
			Stdout( "  " ~ _node.protection ~ "  " ~ _node.name ~ "  " ~ _node.type );

			if( _node.type.length ) Stdout( "  #" ); else Stdout( "#" );
			
			Stdout( _node.lineNumber ).newline;

			if( _node.getChildrenCount > 0 ) space ~= "--";
			foreach( CASTnode t; _node.getChildren() )
			{
				printAST( t, space );
			}

			if( space.length > 1 ) space.length = space.length - 2;
		}
	
	public:
		this(){}
		
		this( TokenUnit[] _tokens )
		{
			updateTokens( _tokens );
		}

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
		
		CASTnode json2Ast( char[] jsonTXT )
		{
			// Nested function
			void splitColon( char[] _line, ref char[] _left, ref char[] _right )
			{
				char[][] _lineData = Util.split( _line, ": " );
				if( _lineData.length )
				{
					_left = Util.strip( _lineData[0], '"' );
					_right = Util.stripr( _lineData[1], ',' );
					_right = Util.strip( Util.trim( _right ), '"' );
				}
			}		
		
			CASTnode NODE;
			
			foreach( char[] line; Util.splitLines( jsonTXT ) )
			{
				line = Util.trim( line );
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
						char[] right, left;
						splitColon( line, left, right );

						switch( left )
						{
							case "line":		NODE.lineNumber = Integer.toInt( right );	break;
							case "tail":		NODE.endLineNum = Integer.toInt( right );	break;
							case "name":		NODE.name = right;							break;
							case "kind":		NODE.kind = Integer.toInt( right );			break;
							case "prot":		NODE.protection = right;					break;
							case "type":		NODE.type = right;							break;
							case "base":		NODE.base = right;							break;
							default:
						}
					}
				}			
			}
			
			return NODE;
		}
		
		
		char[] ast2Json( CASTnode _node )
		{
			char[] jsonTXT;
			
			jsonTXT ~= "{\n";
			jsonTXT ~=	( "\"line\": \"" ~ Integer.toString( _node.lineNumber ) ~ "\",\n" );
			jsonTXT ~=	( "\"tail\": \"" ~ Integer.toString( _node.endLineNum )	~ "\",\n" );	
			jsonTXT ~=	( "\"name\": \"" ~ _node.name ~ "\",\n" );
			jsonTXT ~=	( "\"kind\": \"" ~ Integer.toString( _node.kind ) ~ "\",\n" );
			jsonTXT ~=	( "\"prot\": \"" ~ _node.protection ~ "\",\n" );
			jsonTXT ~=	( "\"type\": \"" ~ _node.type	~ "\",\n" );
			jsonTXT ~=	( "\"base\": \"" ~ _node.base ~ "\",\n" );
			
			if( _node.getChildrenCount == 0 )
				jsonTXT ~=	"\"sons\": []\n";
			else
			{
				jsonTXT ~=	"\"sons\": [\n";
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