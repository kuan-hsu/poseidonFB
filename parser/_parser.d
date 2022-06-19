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
		
		char[] getDelimitedString( int _tokOpen, int _tokClose )
		{
			try
			{
				int		_countDemlimit;
				char[]	_params;		// include open Delimit and close Delimit

				if( token().tok == _tokOpen )
				{
					do
					{
						if( token().tok == _tokOpen )
						{
							if( _countDemlimit > 0 ) _params ~= token().identifier;
							_countDemlimit ++;
						}
						else if( token().tok == _tokClose )
						{
							_countDemlimit --;
							if( _countDemlimit > 0 ) _params ~= token().identifier;
						}
						else
						{
							version(FBIDE)
							{
								if( token().tok == TOK.Tidentifier )
									_params ~= ( " " ~ token().identifier );
								else
									_params ~= token().identifier;
							}
							version(DIDE)
							{
								if( token().tok == TOK.Tidentifier || token().tok == TOK.Tfunction || token().tok == TOK.Tdelegate )
									_params ~= ( " " ~ token().identifier );
								else
									_params ~= token().identifier;
							}
						}
						
						parseToken();
					}
					while( _countDemlimit > 0 && tokenIndex < tokens.length );
				}
				else
				{
					parseToken();
				}

				_params = Util.trim( _params );
				
				switch( _tokOpen )
				{
					case TOK.Topenparen:		_params = "(" ~ _params ~ ")"; break;
					case TOK.Topenbracket:		_params = "[" ~ _params ~ "]"; break;
					case TOK.Topencurly:		_params = "{" ~ _params ~ "}"; break;
					default:					break;
				}
				
				return _params;
			}
			catch( Exception e )
			{
				throw e;
			}
			
			return null;
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
}