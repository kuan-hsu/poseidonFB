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
			if( tokenIndex > 0 ) return tokens[tokenIndex-1];

			throw new Exception( "Method prev(), out of range!" );
		}
		
		TokenUnit next()
		{
			if( tokenIndex < tokens.length - 1 ) return tokens[tokenIndex+1];

			throw new Exception( "Method next(), out of range!" );
		}

		TokenUnit next2()
		{
			if( tokenIndex < tokens.length - 2 ) return tokens[tokenIndex+2];
			
			throw new Exception( "Method next2(), out of range!" );
		}

		void parseToken( TOK t = TOK.Tidentifier )
		{
			if( tokenIndex < tokens.length ) 
				tokenIndex ++;
			else
				throw new Exception( "Method parseToken(), out of range!" );
		}

		TokenUnit getToken(){ return tokens[tokenIndex]; }	

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
			tokens = _tokens;
			
			if( !_tokens.length ) return false;
			
			return true;
		}		
}