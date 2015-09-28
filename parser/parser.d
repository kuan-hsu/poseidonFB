module parser.parser;

class CParser
{
	private:
	import			parser.ast;
	import			parser.token;

	import			tango.io.FilePath, tango.text.Ascii;
	import			Util = tango.text.Util;
	import 			tango.io.Stdout;

	bool			bEasyFlag = true;

	TokenUnit[]		tokens;
	int				tokenIndex;
	CASTnode		activeASTnode;
	


	TokenUnit token(){ return tokens[tokenIndex]; }

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

	void parseToken( TOK t = TOK.Tidentifier ){ tokenIndex ++;}

	TokenUnit getToken(){ return tokens[tokenIndex]; }

	bool parsePreprocessor()
	{
		static char[] _type;
		
		try
		{
			parseToken( TOK.Tpound );

			switch( token().tok )
			{
				case TOK.Tinclude:
					parseToken( TOK.Tinclude );
					if( token().tok == TOK.Tonce ) parseToken( TOK.Tonce );				

					if( token().tok == TOK.Tstrings )
					{
						TokenUnit t = getToken();
						parseToken( TOK.Tstring );

						activeASTnode.addChild( t.identifier, B_INCLUDE, null, _type, null, t.lineNumber );
					}
					break;

				case TOK.Tdefine:
					parseToken( TOK.Tdefine );

					if( token().tok == TOK.Tidentifier )
					{
						char[] 	name = token().identifier;
						int		lineNumber = token().lineNumber;
						parseToken( TOK.Tidentifier );

						if( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
						{
							if( token().tok == TOK.Tnumbers  )
							{
								char[] type;
								if( Util.index( token().identifier, "." ) < token().identifier.length )
								{
									type = "single";
								}
								else
								{
									type = "integer";

								}
								activeASTnode.addChild( name, B_VARIABLE, null, type, null, lineNumber );				
							}
							else if( token().tok == TOK.Tstrings  )
							{
								activeASTnode.addChild( name, B_VARIABLE, null, "string", null, lineNumber );	
							}
							else if( token().tok == TOK.Topenparen )
							{
								// #define GTK_VSCALE(obj) G_TYPE_CHECK_INSTANCE_CAST((obj), GTK_TYPE_VSCALE, GtkVScale)
								char[] param;
								while( token().tok != TOK.Teol )
								{
									param ~= token().identifier;
									if(  token().tok == TOK.Tcloseparen )
									{
										parseToken();
										break;
									}
									parseToken();
								}
								activeASTnode.addChild( name, B_FUNCTION, null, param, null, lineNumber );	
							}
							else if( token().tok == TOK.Tidentifier )
							{
								activeASTnode.addChild( name, B_VARIABLE, null, null, null, lineNumber );	
							}
						}
					}
					break;

				case TOK.Tifdef:
					parseToken( TOK.Tifdef );

					_type = token().identifier;
					parseToken();
					break;

				case TOK.Telseif, TOK.Telse:
					parseToken( TOK.Tifndef );

					if( _type.length )
					{
						if( _type[0] == '!' )
						{
							_type = _type[1..length];
						}
						else
						{
							_type = "!" ~ _type;
						}
					}
					break;

				case TOK.Tendif:
					parseToken( TOK.Tendif );
					_type = "";
					break;

				case TOK.Tifndef:
					parseToken( TOK.Tifndef );

					_type = "!" ~ token().identifier;
					parseToken();
					break;					

				default:
			}
		}
		catch( Exception e )
		{
			return false;
		}

		return true;
	}

	char[] getVariableType()
	{
		if( token().tok == TOK.Tunsigned )
		{
			switch( next().tok )
			{
				case TOK.Tbyte:
					parseToken();
					return "ubyte";
					
				case TOK.Tshort:
					parseToken();
					return "ushort";
				
				case TOK.Tinteger:
					parseToken();
					return "uinteger";
				
				case TOK.Tlongint:
					parseToken();
					return "ulongint";

				default:
					parseToken();
			}
		}
		
		switch( token().tok )
		{
			case TOK.Tbyte, TOK.Tubyte:			
			case TOK.Tshort,TOK.Tushort:
			case TOK.Tinteger, TOK.Tuinteger:
			case TOK.Tlongint, TOK.Tulongint:
			case TOK.Tsingle, TOK.Tdouble:
			case TOK.Tstring, TOK.Tzstring, TOK.Twstring:
			case TOK.Tany:
			case TOK.Tidentifier:
				return token.identifier;

			default:
		}
		return null;
	}

	// Return (..............)
	char[] parseParam( bool bDeclare )
	{
		char[] _param = "(";

		try
		{
			if( token().tok == TOK.Topenparen )
			{
				parseToken( TOK.Topenparen );

				while( token().tok != TOK.Tcloseparen )
				{
					char[] 	_name, _type;
					int		_lineNum;

					if( token().tok == TOK.Tbyref || token().tok == TOK.Tbyval ) parseToken();

					//if( token().tok == TOK.Tidentifier )
					//{
						_name = token().identifier;
						_lineNum = token().lineNumber;

						//parseToken( TOK.Tidentifier );
						parseToken();

						// Array
						if( token().tok == TOK.Topenparen ) _name ~= parseArray();

						_param ~= ( _name ~ " " );
						
						if( token().tok == TOK.Tas )
						{
							_param ~= ( token().identifier ~ " " );
							parseToken( TOK.Tas );

							if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );

							_type = getVariableType();
							if( _type.length )
							{
								_param ~= ( _type ~ " " );
								parseToken();

								while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
								{
									_type ~= "*";
									parseToken();
								}
								
								if( token().tok == TOK.Tassign )
								{
									parseToken( TOK.Tassign );
									if( token().tok != TOK.Tnumbers && token().tok != TOK.Tstrings && token().tok != TOK.Tidentifier ) return null;else parseToken();
								}
							
								if( token().tok == TOK.Tcomma || token().tok == TOK.Tcloseparen )
								{
									_param = Util.trim( _param );
									
									if( !bDeclare ) activeASTnode.addChild( _name, B_PARAM, null, _type, null, _lineNum );
									if( token().tok == TOK.Tcomma )
									{
										_param ~= ( token().identifier );
										parseToken( TOK.Tcomma );
									}
								}
							}
							else
							{
								break;
							}
						}
					//}
					//else
					//{
					//	break;
					//}
				}
			}

		}
		catch
		{
			return null;
		}

		return _param;
	}

	char[] parseArray()
	{
		char[] result;
		
		if( token().tok == TOK.Topenparen )
		{
			parseToken( TOK.Topenparen );
			if( token().tok == TOK.Tcloseparen )
			{
				parseToken( TOK.Tcloseparen );
				return "()";
			}
			else
			{
				result = "(";
				
				do
				{
					if( token().tok == TOK.Tcomma )
					{
						result ~= token.identifier;
						parseToken( TOK.Tcomma );
					}
					
					if( token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers )
					{
						result ~= token.identifier;
						parseToken();
						
						if( token().tok == TOK.Tto )
						{
							result ~= " to ";
							parseToken( TOK.Tto );
							if( token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers )
							{
								result ~= token.identifier;
								parseToken();
							}
							else
							{
								return null;
							}
						}
					}
				}
				while( token().tok == TOK.Tcomma )

				if( token().tok == TOK.Tcloseparen )
				{
					parseToken( TOK.Tcloseparen );
					result ~= ")";
				}
				else
				{
					return null;
				}
			}
		}

		return result;
	}

	bool parseVariable()
	{
		bool bConst;
		
		try
		{
			if( token().tok == TOK.Tdim || token().tok == TOK.Tstatic || token().tok == TOK.Tcommon || token().tok == TOK.Tconst )
			{
				if( token().tok == TOK.Tconst ) bConst = true;
				
				parseToken();

				char[]	_type, _name, _protection;
				int		_lineNum;

				if( token().tok == TOK.Tshared )
				{
					parseToken( TOK.Tshared );
					_protection = "shared";
				}
				
				if( token().tok == TOK.Tas )
				{
					parseToken( TOK.Tas );

					if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );
					
					_type = getVariableType();
					
					if( _type.length )
					{
						parseToken(); 

						while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
						{
							_type ~= "*";
							parseToken();
						}

						while( token().tok == TOK.Tidentifier )
						{
							_lineNum = token().lineNumber;
							_name	= token().identifier;
							
							parseToken( TOK.Tidentifier );

							// Array
							if( token().tok == TOK.Topenparen ) _name ~= parseArray();
							

							if( token().tok == TOK.Tassign )
							{
								parseToken( TOK.Tassign );
								if( token().tok == TOK.Tstring || token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers ) parseToken();else return false;
							}
									
							if( token().tok == TOK.Tcomma )
							{
								activeASTnode.addChild( _name, B_VARIABLE, _protection, _type, null, _lineNum );
								parseToken( TOK.Tcomma );
							}
							else if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
							{
								activeASTnode.addChild( _name, B_VARIABLE, _protection, _type, null, _lineNum );
								parseToken();
								break;
							}
							else
							{
								return false;
							}
						}
					}					
				}
				else if( token().tok == TOK.Tidentifier )
				{
					_name = token().identifier;
					_lineNum = token().lineNumber;
					parseToken( TOK.Tidentifier );

					if( bConst )
					{
						if( token().tok == TOK.Tassign )
						{
							parseToken( TOK.Tassign );
							if( token().tok == TOK.Tnumbers || token().tok == TOK.Tidentifier )
							{
								parseToken( );
								if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
								{
									parseToken( );
									activeASTnode.addChild( _name, B_VARIABLE, null, null, null, _lineNum );
									return true;
								}
								else
								{
									return false;
								}
							}
							else
							{
								return false;
							}
						}
					}
					
					// Array
					if( token().tok == TOK.Topenparen ) _name ~= parseArray();
				
					if( token().tok == TOK.Tas )
					{
						parseToken( TOK.Tas );

						if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );

						_type = getVariableType();
						if( _type.length )
						{
							parseToken();

							while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
							{
								_type ~= "*";
								parseToken();
							}
							
							activeASTnode.addChild( _name, B_VARIABLE, null, _type, null, _lineNum );
						}
					}
				}
			}

			return true;
		}
		catch( Exception e )
		{
		}

		return false;
	}

	// Declare [Static] Sub procedure_name [Cdecl|Stdcall|Pascal] Overload [Alias "external_name"] [([parameter_list])] [Constructor [priority]] [Static] [Export]
	bool parseProcedure( bool bDeclare, char[] _protection )
	{
		int _kind;
		
		try
		{
			if( next().tok == TOK.Tassign )
			{
				parseToken();
				return true;
			}
			
			switch( token().tok )
			{
				case TOK.Tfunction:		_kind = B_FUNCTION	; break;
				case TOK.Tsub:			_kind = B_SUB		; break;
				case TOK.Tproperty:		_kind = B_PROPERTY	; break;
				case TOK.Tconstructor:	_kind = B_CTOR		; break;
				case TOK.Tdestructor:	_kind = B_DTOR		; break;
				default:
			}
			
			if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub || token().tok == TOK.Tproperty || token().tok == TOK.Tconstructor || token().tok == TOK.Tdestructor )
			{
				if( bDeclare )
				{
					if( token().tok != TOK.Tconstructor && token().tok != TOK.Tdestructor )
					{
						parseToken();
						if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal ) parseToken();
					}
				}
				else
				{
					parseToken();
				}

				// Function Name
				if( token().tok == TOK.Tidentifier || ( bDeclare & ( token().tok == TOK.Tconstructor || token().tok == TOK.Tdestructor ) ) )
				{
					char[] 	_name, _param, _returnType;
					int		_lineNum;

					_name = token().identifier;
					_lineNum = token().lineNumber;
					parseToken();

					if( token().tok == TOK.Tdot && next().tok == TOK.Tidentifier ) // method
					{
						_name ~= token().identifier;
						parseToken( TOK.Tdot );

						_name ~= token().identifier;
						parseToken( TOK.Tidentifier );
					}

					if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal ) parseToken();

					// like " Declare Function app_oninit_cb WXCALL () As wxBool "
					if( token().tok == TOK.Tidentifier ) parseToken( TOK.Tidentifier );	

					// Overload
					if( token().tok == TOK.Toverload ) parseToken( TOK.Toverload );

					// Alias "..."
					if( token().tok == TOK.Talias )
					{
						parseToken( TOK.Talias );
						if( token.tok == TOK.Tstrings ) parseToken( TOK.Tstrings ); else return false;
					}

					activeASTnode = activeASTnode.addChild( _name, _kind, _protection, null, null, _lineNum );

					if( token().tok == TOK.Topenparen )
					{
						if( next().tok != TOK.Tcloseparen )	_param = parseParam( bDeclare );else parseToken( TOK.Topenparen );

						if( token().tok == TOK.Tcloseparen )
						{
							if( !_param.length ) _param = "()"; else _param ~= token().identifier;
							parseToken( TOK.Tcloseparen );
						}
					}

					if( token().tok == TOK.Tas )
					{
						parseToken( TOK.Tas );

						if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );

						_returnType = getVariableType();
						if( _returnType.length )
						{
							parseToken();
							while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
							{
								_returnType ~= "*";
								parseToken();
							}
						
							activeASTnode.type = _returnType ~ _param;
							if( bDeclare ) activeASTnode = activeASTnode.getFather();

							if( token().tok == TOK.Tstatic ) parseToken(  TOK.Tstatic );
							
							return true;
						}
					}

					if( token().tok == TOK.Tstatic || token().tok == TOK.Texport  ) parseToken();
					
					if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
					{
						activeASTnode.type = _param;
						if( bDeclare ) activeASTnode = activeASTnode.getFather();
						return true;
					}						
				}
			}
		}
		catch( Exception e )
		{

		}

		return false;
	}

	bool parseTypeBody()
	{
		try
		{
			char[] _protection;
			
			while( token().tok != TOK.Tend && next().tok !=TOK.Ttype )
			{
				char[]	_type, _name;
				int		_lineNum;
				
				switch( token().tok )
				{
					case TOK.Tpublic:
						parseToken( TOK.Tpublic );
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							_protection = "public";
						}
						break;

					case TOK.Tprivate:
						parseToken( TOK.Tprivate );
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							_protection = "private";
						}
						break;

					case TOK.Tprotected:
						parseToken( TOK.Tprivate );
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							_protection = "protected";
						}
						break;
					
					case TOK.Tas:
						parseToken( TOK.Tas );
						_type = getVariableType();

						if( _type.length )
						{
							parseToken();

							while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
							{
								_type ~= "*";
								parseToken();
							}							

							while( token().tok == TOK.Tidentifier )
							{
								_lineNum = token().lineNumber;
								_name		= token().identifier;
								
								parseToken( TOK.Tidentifier );

								// Array
								if( token().tok == TOK.Topenparen ) _name ~= parseArray();

								if( token().tok == TOK.Tassign )
								{
									parseToken( TOK.Tassign );
									if( token().tok == TOK.Tstring || token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers ) parseToken();else return false;
								}
										
								if( token().tok == TOK.Tcomma )
								{
									activeASTnode.addChild( _name, B_VARIABLE, _protection, _type, null, _lineNum );
									parseToken( TOK.Tcomma );
								}
								else if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
								{
									activeASTnode.addChild( _name, B_VARIABLE, _protection, _type, null, _lineNum );
									parseToken();
									break;
								}
								else
								{
									return false;
								}
							}
						}
						else
						{
							parseToken();
						}
						
						break;

					case TOK.Tstatic:
						parseToken( TOK.Tstatic );

					case TOK.Tdeclare:
						parseToken( TOK.Tdeclare );

						if( token().tok == TOK.Tstatic || token().tok == TOK.Tconst ) parseToken();

						if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub || token().tok == TOK.Tproperty )
						{
							parseProcedure( true, _protection );
						}
						else if( token().tok == TOK.Tconstructor || token().tok == TOK.Tdestructor )
						{
							parseProcedure( true, _protection );
						}
						
						break;

					case TOK.Teol, TOK.Tcolon:
						tokenIndex ++;
						break;
						

					//case TOK.Tidentifier:
					default:

						_name = token().identifier;
						_lineNum = token().lineNumber;
						parseToken( TOK.Tidentifier );

						// Array
						if( token().tok == TOK.Topenparen ) _name ~= parseArray();						
					
						if( token().tok == TOK.Tas )
						{
							parseToken( TOK.Tas );

							if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );

							_type = getVariableType();
							if( _type.length )
							{
								parseToken();
								while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
								{
									_type ~= "*";
									parseToken();
								}								
								activeASTnode.addChild( _name, B_VARIABLE, _protection, _type, null, _lineNum );
							}
						}
						
						break;
					/*
					default:
						tokenIndex ++;
					*/
				}
			}

			return true;
		}
		catch( Exception e )
		{
		}

		return false;
	}		

	bool parseType( bool bClass = false )
	{
		try
		{
			char[] 	_name, _param, _type, _base;
			int		_lineNum, _kind;

			if( token().tok == TOK.Ttype || token().tok == TOK.Tunion || ( bClass & token().tok == TOK.Tclass ) )
			{
				switch( token().tok )
				{
					case TOK.Tunion:			_kind = B_UNION;	break;
					case TOK.Ttype:				_kind = B_TYPE;		break;
					case TOK.Tclass:			_kind = B_CLASS;	break;
					default:
				}
				
				parseToken();

				_name = token().identifier;
				_lineNum = token().lineNumber;

				parseToken( TOK.Tidentifier );

				if( token().tok == TOK.Tas )
				{
					parseToken( TOK.Tas );

					// Function pointer
					if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub )
					{
						if( token().tok == TOK.Tfunction ) _kind = B_FUNCTION; else _kind = B_SUB;
						
						parseToken();

						if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal ) parseToken();

						// like " Declare Function app_oninit_cb WXCALL () As wxBool "
						if( token().tok == TOK.Tidentifier ) parseToken( TOK.Tidentifier );	

						// Overload
						if( token().tok == TOK.Toverload ) parseToken( TOK.Toverload );

						// Alias "..."
						if( token().tok == TOK.Talias )
						{
							parseToken( TOK.Talias );
							if( token.tok == TOK.Tstrings ) parseToken( TOK.Tstrings ); else return false;
						}

						char[]  _returnType;

						if( token().tok == TOK.Topenparen )
						{
							if( next().tok != TOK.Tcloseparen )	_param = parseParam( false );else parseToken( TOK.Topenparen );

							if( token().tok == TOK.Tcloseparen )
							{
								if( !_param.length ) _param = "()"; else _param ~= token().identifier;
								parseToken( TOK.Tcloseparen );
							}
						}

						if( token().tok == TOK.Tas )
						{
							parseToken( TOK.Tas );

							if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );

							_returnType = getVariableType();
							if( _returnType.length )
							{
								parseToken();
								while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
								{
									_returnType ~= "*";
									parseToken();
								}

								_type = _returnType ~ _param;
								activeASTnode.addChild( _name, _kind, null, _type, null, _lineNum );
								
								return true;
							}
						}

						if( token().tok == TOK.Tstatic || token().tok == TOK.Texport  ) parseToken();
						
						if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
						{
							activeASTnode.addChild( _name, _kind, null, _param, null, _lineNum );
							return true;
						}		
					}

					if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );

					_type = getVariableType();
					if( _type.length )
					{
						parseToken();

						while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
						{
							_type ~= "*";
							parseToken();
						}
					}

					if( token().tok == TOK.Tcolon || token().tok == TOK.Teol )
					{
						activeASTnode.addChild( _name, B_ALIAS, null, _type, null, _lineNum );
						return true;
					}
				}
				else
				{
					if( token().tok == TOK.Textends )
					{
						parseToken( TOK.Textends );
						_base = token().identifier;
						parseToken( TOK.Tidentifier );
					}

					if( token().tok == TOK.Tfield )
					{
						if( next().tok == TOK.Tassign )
						{
							parseToken( TOK.Tfield );
							parseToken( TOK.Tassign );
							if( token().tok == TOK.Tnumbers ) parseToken( TOK.Tnumbers );else return false;
						}
						else
						{
							return false;
						}
					}

					if( token().tok == TOK.Teol )
					{
						if( bClass ) activeASTnode = activeASTnode.addChild( _name, B_CLASS, null, null, _base, _lineNum ); else activeASTnode = activeASTnode.addChild( _name, _kind, null, null, _base, _lineNum );
						parseToken( TOK.Teol );
						parseTypeBody();
					}
				}
			}
		}
		catch( Exception e )
		{
		}

		return false;
	}	

	bool parseEnum()
	{
		try
		{
			char[] 	_name, _param, _type, _base;
			int		_lineNum;

			if( token().tok == TOK.Tenum )
			{
				parseToken( TOK.Tenum );

				if( token().tok == TOK.Tidentifier )
				{
					_name = token().identifier;
					parseToken( TOK.Tidentifier );
				}

				_lineNum = token().lineNumber;

				if( token().tok == TOK.Teol )
				{
					activeASTnode = activeASTnode.addChild( _name, B_ENUM, null, null, _base, _lineNum );
					parseToken( TOK.Teol );

					while( token().tok != TOK.Tend && next().tok !=TOK.Tenum )
					{
						if( token().tok == TOK.Tidentifier )
						{
							_name = token().identifier;
							_lineNum = token().lineNumber;
							parseToken( TOK.Tidentifier );

							if( token().tok == TOK.Tassign )
							{
								parseToken( TOK.Tassign );
								//if( token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers ) parseToken(); else break;
							}

							// Pass the maybe complicated express
							while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
							{
								parseToken();
							}

							if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
							{
								activeASTnode.addChild( _name, B_ENUMMEMBER, null, null, null, _lineNum );
								parseToken();
							}
						}
						else
						{
							break;
						}
					}
				}
			}
		}
		catch( Exception e )
		{
		}

		return false;
	}	
	
	bool parseEnd()
	{
		try
		{
			parseToken( TOK.Tend );

			switch( token().tok )
			{
				case TOK.Tsub, TOK.Tfunction, TOK.Tproperty, TOK.Tconstructor, TOK.Tdestructor, TOK.Ttype, TOK.Tenum, TOK.Tunion:
					parseToken();
					if( activeASTnode.getFather() !is null ) activeASTnode = activeASTnode.getFather();

					break;
				default:
					//parseToken();
			}
		}
		catch( Exception e )
		{
		}

		return true;
	}


	public:
	this( TokenUnit[] _tokens )
	{
		tokens = _tokens;
	}

	void updateTokens( TokenUnit[] _tokens )
	{
		tokens.length = 0;
		tokens = _tokens;
	}
	
	CASTnode parse( char[] fullPath )
	{
		scope f = new FilePath( fullPath );

		CASTnode		head;

		
		char[]		_ext;
		if( toLower( f.ext() ) == "bas" ) 
		{
			head = new CASTnode( fullPath, B_BAS, null, null, null, 0 );
		}
		else
		{
			head = new CASTnode( fullPath, B_BI, null, null, null, 0 );
		}

		activeASTnode = head;

		while( tokenIndex < tokens.length )
		{
			switch( tokens[tokenIndex].tok )
			{
				case TOK.Tprivate:
					parseToken( TOK.Tprivate );
					if( token().tok == TOK.Tsub || token().tok == TOK.Tfunction ) parseProcedure( false, "private" );
					break;
					
				case TOK.Tpublic:
					parseToken( TOK.Tpublic );
					if( token().tok == TOK.Tsub || token().tok == TOK.Tfunction ) parseProcedure( false, "public" );
					break;
				
				case TOK.Tpound:
					parsePreprocessor();
					break;

				case TOK.Tconst:
				case TOK.Tcommon:
				case TOK.Tstatic:
				case TOK.Tdim:
					parseVariable();
					break;

				case TOK.Tfunction, TOK.Tsub, TOK.Tproperty, TOK.Tconstructor, TOK.Tdestructor:
					parseProcedure( false, null );
					break;

				case TOK.Tend:
					parseEnd();
					break;

				case TOK.Ttype:
					parseType();
					break;

				case TOK.Tclass:
					parseType( true );
					break;

				case TOK.Tunion:
					parseType();
					break;
					
				case TOK.Tenum:
					parseEnum();
					break;
					
				case TOK.Tdeclare:
					parseToken( TOK.Tdeclare );
					
					if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub )
					{
						parseProcedure( true, null );
					}

					break;

				default:
					tokenIndex ++;
					//Stdout( tokenIndex );
					//Stdout( "   " ~ token().identifier ).newline;
			}
		}

		//printAST( head );

		return head;
	}

	void printAST( CASTnode _node )
	{
		foreach( CASTnode t; _node.getChildren() )
		{
			printAST( t );
		}
	}

}