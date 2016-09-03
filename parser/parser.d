module parser.parser;

class CParser
{
	private:
	import			parser.ast;
	import			parser.token, parser.autocompletion;

	import			tango.io.FilePath, tango.text.Ascii;
	import			Util = tango.text.Util;
	import 			tango.io.Stdout;

	import			tools;

	TokenUnit[]		tokens;
	int				tokenIndex;
	CASTnode		activeASTnode;
	
	TokenUnit token()
	{
		if( tokenIndex < tokens.length ) return tokens[tokenIndex]; else throw new Exception( "Method next(), out of range!" );
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

						activeASTnode.addChild( Util.replace( t.identifier, '\\', '/' ) , B_INCLUDE, null, _type, null, t.lineNumber );
					}
					break;

				/*
				#macro identifier( [ parameters ] )
					body
				#endmacro

				#macro identifier( [ parameters, ] Variadic_Parameter... )
					body
				#endmacro
				*/
				case TOK.Tmacro:
					parseToken( TOK.Tmacro );
					if( token().tok == TOK.Tidentifier )
					{
						char[] 	name = token().identifier;
						int		lineNumber = token().lineNumber;
						parseToken( TOK.Tidentifier );

						char[] paramName, paramString;

						activeASTnode = activeASTnode.addChild( name, B_MACRO, null, paramString, null, lineNumber );	
						
						while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
						{
							paramString ~= token().identifier;
							
							if( token().tok == TOK.Topenparen )
							{
								parseToken( TOK.Topenparen );
							}
							else if( token().tok == TOK.Tcloseparen )
							{
								parseToken( TOK.Tcloseparen );
								break;
							}
							else if( token().tok == TOK.Tcomma )
							{
								activeASTnode.addChild( paramName, B_PARAM, null, null, null, lineNumber );
								paramName = "";
								parseToken();
							}
							else
							{
								paramName ~= token().identifier;
								parseToken();
							}
						}

						activeASTnode.type = paramString;
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
								activeASTnode.addChild( name, B_VARIABLE | B_DEFINE, null, type, null, lineNumber );				
							}
							else if( token().tok == TOK.Tstrings  )
							{
								activeASTnode.addChild( name, B_VARIABLE | B_DEFINE, null, "string", null, lineNumber );	
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
								activeASTnode.addChild( name, B_FUNCTION | B_DEFINE, null, param, null, lineNumber );	
							}
							else if( token().tok == TOK.Tidentifier )
							{
								activeASTnode.addChild( name, B_VARIABLE | B_DEFINE, null, null, null, lineNumber );	
							}
						}
					}
					break;

				case TOK.Tifdef:
					parseToken( TOK.Tifdef );

					_type = toUpper( token().identifier );
					parseToken();
					break;

				case TOK.Telseif, TOK.Telse:
					parseToken();

					if( _type.length )
					{
						if( _type[0] == '!' )
						{
							_type = toUpper( _type[1..length] );
						}
						else
						{
							_type = toUpper( "!" ~ _type );
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
				return lowerCase( token.identifier );
			
			case TOK.Tidentifier:
				char[] _type;
				while( next().tok == TOK.Tdot )
				{
					_type ~= token.identifier;
					parseToken( TOK.Tidentifier );
					_type ~= token.identifier;
					parseToken( TOK.Tdot );
				}

				if( !_type.length ) _type = token.identifier;else _type ~= token.identifier;

				return _type;

			default:
		}
		return null;
	}

	// Return (..............)
	/*
	parameter_list: parameter[, parameter[, ...]]
	parameter: [ByRef|ByVal] identifier [As type] [= default_value]

	identifier: the name of the variable referenced in the function. If the argument is an array then the identifier must be followed by an empty parenthesis. 
	type: the type of variable
	default_value: the value of the argument if none is specified in the call
	*/	
	char[] parseParam( bool bDeclare )
	{
		char[] _param = "(";

		try
		{
			if( token().tok == TOK.Topenparen )
			{
				parseToken( TOK.Topenparen );

				if( token().tok == TOK.Tcloseparen )
				{
					parseToken( TOK.Tcloseparen );
					return "()";
				}

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


						// Function pointer
						if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub )
						{
							int _kind;
							char[] __param;
							
							if( token().tok == TOK.Tfunction ) _kind = B_FUNCTION; else _kind = B_SUB;
							
							_param ~= token().identifier;
							parseToken();

							if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal )
							{
								//_param ~= token().identifier;
								parseToken();
							}

							// like " Declare Function app_oninit_cb WXCALL () As wxBool "
							if( token().tok == TOK.Tidentifier )
							{
								_param ~= ( " " ~ token().identifier );
								parseToken( TOK.Tidentifier );
							}

							// Overload
							if( token().tok == TOK.Toverload )
							{
								//_param ~= ( " " ~ token().identifier );
								parseToken( TOK.Toverload );
							}

							// Alias "..."
							if( token().tok == TOK.Talias )
							{
								//_param ~= ( " " ~ token().identifier );
								parseToken( TOK.Talias );
								if( token.tok == TOK.Tstrings ) parseToken( TOK.Tstrings ); else return null;
							}

							char[]  _returnType;

							if( token().tok == TOK.Topenparen ) __param = parseParam( false );

							_param ~= __param;

							if( token().tok == TOK.Tas )
							{
								_param ~= ( " " ~ token().identifier );
								parseToken( TOK.Tas );

								if( token().tok == TOK.Tconst )
								{
									_param ~= ( " " ~ token().identifier );
									parseToken( TOK.Tconst );
								}

								_returnType = getVariableType();
								if( _returnType.length )
								{
									parseToken();
									while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
									{
										_returnType ~= "*";
										parseToken();
									}

									// Mother param strings
									_param ~= ( " " ~ _returnType );

									_type = _returnType ~ __param;
									activeASTnode.addChild( _name, _kind, null, _type, null, _lineNum );
									
									//return true;
								}
							}

							if( token().tok == TOK.Tstatic || token().tok == TOK.Texport  ) parseToken();
							
							if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
							{
								activeASTnode.addChild( _name, _kind, null, __param, null, _lineNum );
							}		
						}

						if( token().tok == TOK.Tconst )
						{
							_param ~= ( token().identifier ~ " " );
							parseToken( TOK.Tconst );
						}

						_type = getVariableType();
						if( _type.length )
						{
							parseToken();

							while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
							{
								_type ~= "*";
								parseToken();
							}
							_param ~= ( _type ~ " " );


							if( token().tok == TOK.Tassign )
							{
								parseToken( TOK.Tassign );

								int countParen;
								do
								{
									if( token().tok == TOK.Topenparen )
									{
										countParen ++;
									}
									else if( token().tok == TOK.Tcloseparen )
									{
										countParen --;
										if( countParen == -1 ) break; // Param Tail
									}
									else if( token().tok == TOK.Tcomma )
									{
										if( countParen == 0 ) break;
									}
									
									if( tokenIndex >= tokens.length ) break;
									parseToken();
								}
								while( token().tok != TOK.Teol )
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

		if( token().tok == TOK.Tcloseparen )
		{
			parseToken( TOK.Tcloseparen );
			if( _param[length-1] == ' ' ) _param = _param[0..length-1];
			_param ~= ")";
		}	

		return _param;
	}

	char[] parseArray()
	{
		char[] result;

		if( token().tok == TOK.Topenparen )
		{
			parseToken( TOK.Topenparen );
			result = "(";

			if( token().tok == TOK.Tcloseparen )
			{
				parseToken( TOK.Tcloseparen );
				return "()";
			}
			
			int countOpenParen = 1;
			do
			{
				switch( token().tok )
				{
					case TOK.Tcloseparen:
						countOpenParen --;
						parseToken( TOK.Tcloseparen );
						result ~= ")";
						if( countOpenParen == 0 ) return result;
						break;

					case TOK.Topenparen:
						countOpenParen ++;
						parseToken( TOK.Topenparen );
						result ~= "(";
						break;

					case TOK.Tto:
						result ~= " to ";
						parseToken();
						break;

					case TOK.Teol:
					case TOK.Tcolon:
						parseToken();
						return null;

					default:
						result ~= token.identifier;
						parseToken();
				}
			}
			while( tokenIndex < tokens.length )
		}
		
		return result;

		
		/+
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
		+/
	}
	
	/*
	Dim [Shared] name1 As DataType [, name2 As DataType, ...]

	or

	Dim [Shared] As DataType name1 [, name2, ...]

	Arrays:

	Dim name ( [lbound To] ubound [, ...] ) As DataType
	Dim name ( Any [, Any...] ) As DataType
	Dim name ( ) As DataType


	Initializers:

	Dim scalar_symbol As DataType = expression | Any
	Dim array_symbol (arraybounds) As DataType = { expression [, ...] } | Any
	Dim udt_symbol As DataType = ( expression [, ...] ) | Any
	*/
	bool parseVariable()
	{
		bool bConst;
		
		try
		{
			if( token().tok == TOK.Tdim || token().tok == TOK.Tstatic || token().tok == TOK.Tcommon || token().tok == TOK.Tconst || token().tok == TOK.Tredim )
			{
				if( token().tok == TOK.Tconst ) bConst = true;

				if( token().tok == TOK.Tredim &&  next().tok == TOK.Tpreserve ) parseToken( TOK.Tredim );

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

						if( _type == "string" || _type == "zstring" || _type == "wstring" )
						{
							if( token().tok == TOK.Ttimes )
							{
								parseToken( TOK.Ttimes );
								parseToken(); // TOK.Tnumber or	TOK.Tidentifier
							}
						}

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

								int countCurly, countParen;

								switch( token().tok )
								{
									case TOK.Topencurly:
										do
										{
											if( token().tok == TOK.Topencurly )
											{
												countCurly ++;
											}
											else if( token().tok == TOK.Tclosecurly )
											{
												if( --countCurly == 0 )
												{
													parseToken( TOK.Tclosecurly );
													break;
												}
												
											}
											else if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
											{
												break;
											}

											parseToken();
										}
										while( tokenIndex < tokens.length )
										break;

									case TOK.Topenparen:
										do
										{
											if( token().tok == TOK.Topenparen )
											{
												countParen ++;
											}
											else if( token().tok == TOK.Tcloseparen )
											{
												if( --countParen == 0 )
												{
													parseToken( TOK.Tcloseparen );
													break;
												}
												
											}
											else if( token().tok == TOK.Teol ||  token().tok == TOK.Tcolon  )
											{
												break;
											}

											parseToken();
										}
										while( tokenIndex < tokens.length )
										break;

									default:
										while( token.tok != TOK.Teol && token.tok != TOK.Tcolon )
										{
											if( token().tok == TOK.Tcomma )
											{
												if( countParen == 0 && countCurly == 0 ) break;
											}
											parseToken();
											if( tokenIndex >= tokens.length ) break;
										}
								}

								/*
								int countParen;
								do
								{
									if( token().tok == TOK.Topenparen )
									{
										countParen ++;
									}
									else if( token().tok == TOK.Tcloseparen )
									{
										countParen --;
									}
									else if( token().tok == TOK.Tcomma )
									{
										if( countParen == 0 ) break;
									}
									else if( token().tok == TOK.Tcolon )
									{
										if( countParen == 0 )
										{
											parseToken();
											break;
										}
									}
									else if( token().tok == TOK.Topencurly )
									{
										int countCurly = 1;
										parseToken( TOK.Topencurly );

										while( countCurly != 0 )
										{
											if( tokenIndex >= tokens.length ) break;
											
											if( token().tok == TOK.Topencurly )
											{
												countCurly ++;
											}
											else if( token().tok == TOK.Tclosecurly )
											{
												countCurly --;
											}

											tokenIndex ++;
										}
									}
									
									if( tokenIndex >= tokens.length ) break;
									parseToken();
								}
								while( token().tok != TOK.Teol )
								*/
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
					while( token().tok == TOK.Tidentifier )
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

								if( _type == "string" || _type == "zstring" || _type == "wstring" )
								{
									if( token().tok == TOK.Ttimes )
									{
										parseToken( TOK.Ttimes );
										parseToken(); // TOK.Tnumber or	TOK.Tidentifier
									}
								}

								while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
								{
									_type ~= "*";
									parseToken();
								}
								
								activeASTnode.addChild( _name, B_VARIABLE, null, _type, null, _lineNum );

								if( token.tok != TOK.Tcomma ) break; else parseToken( TOK.Tcomma );
							}
						}
						else
						{
							return false;
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

	// Var [Shared] symbolname = expression[, symbolname = expression]
	bool parserVar()
	{
		char[] 	_name;
		int 	_lineNum;
		
		parseToken( TOK.Tvar );

		if( token().tok == TOK.Tshared ) parseToken( TOK.Tshared );

		_name = token().identifier;
		_lineNum = token().lineNumber;
		parseToken();

		if( token().tok == TOK.Tassign )
		{
			parseToken( TOK.Tassign );
			if( token().tok == TOK.Tcast )
			{
				parseToken( TOK.Tcast );
				
				if( token().tok == TOK.Topenparen )
				{
					parseToken( TOK.Topenparen );

					activeASTnode.addChild( _name, B_VARIABLE, null, toLower( token().identifier ), null, _lineNum );

					while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
					{
						if( tokenIndex < tokens.length ) parseToken(); else return false;
						parseToken();
					}
					parseToken();
				}
			}
			else
			{
				char[] _typeName = token().identifier;
				parseToken();

				activeASTnode.addChild( _name, B_VARIABLE, null, "Var(" ~ _typeName ~ ")", null, _lineNum );
				while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
				{
					if( tokenIndex < tokens.length ) parseToken(); else return false;
				}
				parseToken();				
			}
		}

		return true;
	}

	bool parseNamespace()
	{
		try
		{
			parseToken( TOK.Tnamespace );
			if( token().tok == TOK.Tidentifier )
			{
				activeASTnode = activeASTnode.addChild( token().identifier, B_NAMESPACE, null, null, null, token().lineNumber );
				parseToken( TOK.Tidentifier );
				return true;
			}
		}
		catch( Exception e )
		{

		}

		return false;
	}

	/*
	Syntax

	{ Type | Class | Union | Enum } typename

	Declare Operator Cast () [ ByRef ] As datatype
	Declare Operator @ () [ ByRef ] As datatype Ptr
	Declare Operator assignment_op ( [ ByRef | ByVal ] rhs As datatype )
	Declare Operator [] ( index As datatype ) [ ByRef ] As datatype
	Declare Operator New ( size As UInteger ) As Any Ptr
	Declare Operator New[] ( size As UInteger ) As Any Ptr
	Declare Operator Delete ( buf As Any Ptr )
	Declare Operator Delete[] ( buf As Any Ptr )

	End { Type | Class | Union | Enum }

	{ Type | Class | Union } typename

	Declare Operator For ()
	Declare Operator For ( [ ByRef | ByVal ] stp As typename )
	Declare Operator Step ()
	Declare Operator Step ( [ ByRef | ByVal ] stp As typename )
	Declare Operator Next ( [ ByRef | ByVal ] cond As typename ) As Integer
	Declare Operator Next ( [ ByRef | ByVal ] cond As typename, [ ByRef | ByVal ] stp As typename ) As Integer

	End { Type | Class | Union }

	Declare Operator unary_op ( [ ByRef | ByVal ] rhs As datatype ) As datatype
	Declare Operator binary_op ( [ ByRef | ByVal ] lhs As datatype, [ ByRef | ByVal ] rhs As datatype ) As datatype

	Operator typename.Cast () [ ByRef ] As datatype [ Export ]
	Operator typename.@ () [ ByRef ] As datatype Ptr [ Export ]
	Operator typename.assignment_op ( [ ByRef | ByVal ] rhs As datatype ) [ Export ]
	Operator [] ( index As datatype ) [ ByRef ] As datatype [ Export ]
	Operator unary_op ( [ ByRef | ByVal ] rhs As datatype ) As datatype [ Export ]
	Operator binary_op ( [ ByRef | ByVal ] lhs As datatype, [ ByRef | ByVal ] rhs As datatype ) As datatype [ Export ]
	Operator typename.New ( size as uinteger ) As Any Ptr [ Export ]
	Operator typename.New[] ( size As UInteger ) As Any Ptr [ Export ]
	Operator typename.Delete ( buf As Any Ptr ) [ Export ]
	Operator typename.Delete[] ( buf As Any Ptr ) [ Export ]
	*/
	bool parseOperator( bool bDeclare, char[] _protection )
	{
		//if( bDeclare ) return true;
		
		try
		{
			char[]	_returnType, _name, _kind, _param;
			int		_lineNum, opType;
			
			parseToken( TOK.Toperator );

			// Function Name
			// Function Name
			if( !bDeclare )
			{
				if( token().tok == TOK.Tidentifier && next().tok == TOK.Tdot  )
				{
					_name = token().identifier;
					parseToken();

					_name ~= token().identifier;
					parseToken( TOK.Tdot );
				}
			}

			switch( token().tok )
			{
				case TOK.Tcast, TOK.Tat:
				
					_name ~= token().identifier;
					_lineNum = token().lineNumber;
					parseToken();
					
					if( token().tok == TOK.Topenparen && next().tok == TOK.Tcloseparen )
					{
						parseToken( TOK.Topenparen );
						parseToken( TOK.Tcloseparen );

						if( token().tok == TOK.Tbyref ) 
							parseToken( TOK.Tbyref );
						else if( token().tok == TOK.Tbyval ) 
							parseToken( TOK.Tbyval );

						if( token().tok == TOK.Tas )
						{
							parseToken( TOK.Tas );
							_returnType = getVariableType();
							if( _returnType.length )
							{
								parseToken();
								while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
								{
									_returnType ~= "*";
									parseToken();
								}
							}

							activeASTnode = activeASTnode.addChild( _name, B_OPERATOR, _protection, _returnType ~ "()", null, _lineNum );
							if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
							break;
						}
					}
					return false;

				case TOK.Topenbracket:
					if( next().tok == TOK.Tclosebracket )
					{
						_lineNum = token().lineNumber;
						
						parseToken( TOK.Topenbracket );
						parseToken( TOK.Tclosebracket );
						_name ~= "[]";
						
						if( token().tok == TOK.Topenparen )
						{
							activeASTnode = activeASTnode.addChild( _name, B_OPERATOR, _protection, null, null, _lineNum );
							_param = parseParam( bDeclare );

							if( token().tok == TOK.Tbyref ) 
								parseToken( TOK.Tbyref );
							else if( token().tok == TOK.Tbyval ) 
								parseToken( TOK.Tbyval );

							if( token().tok == TOK.Tas )
							{
								parseToken( TOK.Tas );
								_returnType = getVariableType();
								if( _returnType.length )
								{
									parseToken();
									while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
									{
										_returnType ~= "*";
										parseToken();
									}
								}

								activeASTnode.type = _returnType ~ _param;
							
								if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
								break;
							}
						}
					}
					return false;
					
				case TOK.Tnew, TOK.Tdelete: // "new" and "new[]" and "delete" and "delete[]"
					_lineNum = token().lineNumber;
					_name ~= token().identifier;
					parseToken();

					if( token().tok == TOK.Topenbracket && next().tok == TOK.Tclosebracket )
					{
						parseToken( TOK.Topenparen );
						parseToken( TOK.Tcloseparen );	
						_name ~= "[]";
					}
					
					if( token().tok == TOK.Topenparen )
					{
						activeASTnode = activeASTnode.addChild( _name, B_OPERATOR, _protection, null, null, _lineNum );
						_param = parseParam( bDeclare );

						if( Util.index( lowerCase( _name ), "new" ) < _name.length )
						{
							if( token().tok == TOK.Tas )
							{
								parseToken( TOK.Tas );
								_returnType = getVariableType();
								if( _returnType.length )
								{
									parseToken();
									while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
									{
										_returnType ~= "*";
										parseToken();
									}
								}

								activeASTnode.type = _returnType ~ _param;
								if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
							}
						}
						else // delete
						{
							activeASTnode.type = _param;
							if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
						}
						break;
					}
					return false;

				case TOK.Tlet:
					if( next().tok == TOK.Topenparen ) opType = 1; else return false; // Check if assignment_op, p.s. opType = 1

				case TOK.Tplus, TOK.Tminus, TOK.Ttimes, TOK.Tandsign, TOK.Tdiv, TOK.Tintegerdiv, TOK.Tmod, TOK.Tshl, TOK.Tshr, TOK.Tand, TOK.Tor, TOK.Txor, TOK.Timp, TOK.Teqv, TOK.Tcaret:
					if( opType == 0 )
					{
						if( next().tok == TOK.Tassign )
						{
							opType = 1;
						}
						else if( next().tok == TOK.Topenparen )
						{
							opType = 3;
						}
						else if( token().tok == TOK.Tminus && next().tok == TOK.Tgreater )
						{
							_name ~= token().identifier;
							parseToken();
							opType = 2;							
						}						
					}
					
				case TOK.Tassign:
					if( opType == 0 )
						if( next().tok == TOK.Topenparen ) opType = 3; else return false;

				case TOK.Tless:
					if( opType == 0 )
					{
						if( next().tok == TOK.Tgreater || next().tok == TOK.Tassign )
						{
							_name ~= token().identifier;
							parseToken();
							opType = 3;
						}
						else if( next().tok == TOK.Topenparen )
						{
							opType = 3;
						}
						else
						{
							return false;
						}
					}

				case TOK.Tgreater:
					if( opType == 0 )
					{
						if( next().tok == TOK.Tassign )
						{
							_name ~= token().identifier;
							parseToken();
							opType = 3;
						}
						else if( next().tok == TOK.Topenparen )
						{
							opType = 3;
						}
						else
						{
							return false;
						}
					}

				case TOK.Tnot:
					if( opType == 0 )
						if( next().tok == TOK.Topenparen ) opType = 2; else return false;
			
				case TOK.Tidentifier:
					if( opType == 0 )
					{
						switch( lowerCase( token().identifier ) )
						{
							case "abs", "sgn", "fix", "frac", "int", "exp", "log", "sin", "asin", "cos", "acos", "tan", "atn", "len":
								if( next().tok == TOK.Topenparen )
								{
									opType = 2;
									break;
								}

							default:
								return false;
						}
						
					}

					switch( opType )
					{
						case 1:
							_name ~= token().identifier;
							_lineNum = token().lineNumber;
							parseToken();
							if( token().tok == TOK.Tassign )
							{
								parseToken( TOK.Tassign );
								_name ~= "=";
							}

							if( token().tok == TOK.Topenparen )
							{
								activeASTnode = activeASTnode.addChild( _name, B_OPERATOR, _protection, null, null, _lineNum );
								_param = parseParam( bDeclare );

								activeASTnode.type = _param;
								if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
								if( token().tok == TOK.Texport ) parseToken( TOK.Texport );
								break;
							}
							return false;

						case 2, 3:
							_name ~= token().identifier;
							_lineNum = token().lineNumber;
							parseToken();

							if( token().tok == TOK.Topenparen )
							{
								activeASTnode = activeASTnode.addChild( _name, B_OPERATOR, _protection, null, null, _lineNum );
								_param = parseParam( bDeclare );

								if( token().tok == TOK.Tbyref ) 
									parseToken( TOK.Tbyref );
								else if( token().tok == TOK.Tbyval ) 
									parseToken( TOK.Tbyval );

								if( token().tok == TOK.Tas )
								{
									parseToken( TOK.Tas );
									_returnType = getVariableType();
									if( _returnType.length )
									{
										parseToken();
										while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
										{
											_returnType ~= "*";
											parseToken();
										}
									}
			
									activeASTnode.type = _returnType ~ _param;
									if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
									if( token().tok == TOK.Texport ) parseToken( TOK.Texport );
									break;
								}
							}

						default:
							return false;
					}
					break;

				default:
					return false;
			}
		}
		catch
		{
			return false;
		}

		return true;
	}
	
	/*
	Declare [Static] Sub procedure_name [Cdecl|Stdcall|Pascal] Overload [Alias "external_name"] [([parameter_list])] [Constructor [priority]] [Static] [Export]
	identifier: the name of the function
	external_identifier: externally visible (to the linker) name enclosed in quotes
	parameter_list: parameter[, parameter[, ...]]
	parameter: [ByRef|ByVal] identifier [As type] [= default_value]

	identifier: the name of the variable referenced in the function. If the argument is an array then the identifier must be followed by an empty parenthesis. 
	type: the type of variable
	default_value: the value of the argument if none is specified in the call

	return_type: the type of variable returned by the function
	statements: one or more statements that make up the function body
	return_value: the value returned from the function
	*/
	
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

					if( token().tok == TOK.Topenparen ) _param = parseParam( bDeclare );

					// New
					if( token().tok == TOK.Tbyref ) 
						parseToken( TOK.Tbyref );
					else if( token().tok == TOK.Tbyval ) 
						parseToken( TOK.Tbyval );					

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
							if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );

							if( token().tok == TOK.Tstatic ) parseToken(  TOK.Tstatic );
							
							return true;
						}
					}

					if( token().tok == TOK.Tstatic || token().tok == TOK.Texport  ) parseToken();
					
					if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
					{
						activeASTnode.type = _param;
						if( bDeclare ) activeASTnode = activeASTnode.getFather( token().lineNumber );
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

	/*
	Type typename

	fieldname1 As DataType
	fieldname2 As DataType
	As DataType fieldname3, fieldname4
	...

	End Type

	Type typename [Extends base_typename] [Field = alignment]

	[Private:|Public:|Protected:]

	Declare Sub|Function|Constructor|Destructor|Property|Operator ...
	Static variablename As DataType

	fieldname As DataType [= initializer]
	fieldname(array dimensions) As DataType [= initializer]
	fieldname(Any [, Any...]) As DataType
	fieldname : bits As DataType [= initializer]

	As DataType fieldname [= initializer], ...
	As DataType fieldname(array dimensions) [= initializer], ...
	As DataType fieldname(Any [, Any...])
	As DataType fieldname : bits [= initializer], ...

	Union
		fieldname As DataType
		Type
			fieldname As DataType
			...
		End Type
		...
	End Union

	...

	End Type
	*/
	bool parseTypeBody( int B_KIND )
	{
		try
		{
			char[] _protection;

			switch( B_KIND )
			{
				case B_TYPE:	B_KIND = TOK.Ttype; break;
				case B_UNION:	B_KIND = TOK.Tunion; break;
				case B_ENUM:	B_KIND = TOK.Tenum; break;
				default:
					B_KIND = TOK.Ttype;
			}
			
			while( token().tok != TOK.Tend && next().tok != B_KIND )
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

					case TOK.Tdim:
						parseVariable();
						break;
						
					case TOK.Tas:
						parseToken( TOK.Tas );
						_type = getVariableType();

						if( _type.length )
						{
							parseToken();

							if( _type == "string" || _type == "zstring" || _type == "wstring" )
							{
								if( token().tok == TOK.Ttimes )
								{
									parseToken( TOK.Ttimes );
									parseToken(); // TOK.Tnumber or	TOK.Tidentifier
								}
							}

							while( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
							{
								_type ~= "*";
								parseToken();
							}							

							while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
							{
								_lineNum	= token().lineNumber;
								_name		= token().identifier;
								
								parseToken( TOK.Tidentifier );

								// Array
								if( token().tok == TOK.Topenparen ) _name ~= parseArray();

								// As DataType fieldname : bits [= initializer], ...
								if( token().tok == TOK.Tcolon )
								{
									parseToken( TOK.Tcolon );
									if( token().tok == TOK.Tnumbers ) parseToken( TOK.Tnumbers );else return false;
								}

								// [= initializer]
								if( token().tok == TOK.Tassign )
								{
									parseToken( TOK.Tassign );

									switch( token().tok )
									{
										case TOK.Topencurly:
											int countCurly;

											do
											{
												if( token().tok == TOK.Topencurly )
												{
													countCurly ++;
												}
												else if( token().tok == TOK.Tclosecurly )
												{
													if( --countCurly == 0 )
													{
														parseToken( TOK.Tclosecurly );
														break;
													}
													
												}
												else if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
												{
													break;
												}

												parseToken();
											}
											while( tokenIndex < tokens.length )
											break;

										case TOK.Topenparen:
											int countParen;

											do
											{
												if( token().tok == TOK.Topenparen )
												{
													countParen ++;
												}
												else if( token().tok == TOK.Tcloseparen )
												{
													if( --countParen == 0 )
													{
														parseToken( TOK.Tcloseparen );
														break;
													}
													
												}
												else if( token().tok == TOK.Teol ||  token().tok == TOK.Tcolon  )
												{
													break;
												}

												parseToken();
											}
											while( tokenIndex < tokens.length )
											break;

										default:
											while( token.tok != TOK.Teol && token.tok != TOK.Tcolon )
											{
												parseToken();
												if( tokenIndex >= tokens.length ) break;
											}
									}

									//if( token().tok == TOK.Tstring || token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers ) parseToken();else return false;
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

						if( token().tok == TOK.Tstatic || token().tok == TOK.Tconst || token().tok == TOK.Tabstract || token().tok == TOK.Tvirtual ) parseToken();

						if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub || token().tok == TOK.Tproperty )
						{
							parseProcedure( true, _protection );
						}
						else if( token().tok == TOK.Tconstructor || token().tok == TOK.Tdestructor )
						{
							parseProcedure( true, _protection );
						}
						else if( token().tok == TOK.Toperator )
						{
							parseOperator( true, _protection );
						}	
						break;

					case TOK.Teol, TOK.Tcolon:
						tokenIndex ++;
						break;

					case TOK.Tenum:
						parseEnum();
						if( token().tok == TOK.Tend || next().tok == TOK.Tenum )
						{
							tokenIndex += 2;
							activeASTnode = activeASTnode.getFather( token().lineNumber );
						}
						else
						{
							return false;
						}						
						break;

					case TOK.Tunion, TOK.Ttype:
						TOK nestUnnameTOK = token().tok;
						_lineNum = token().lineNumber;

						if( next().tok == TOK.Teol || next().tok == TOK.Tcolon )
						{
							tokenIndex += 2;
							activeASTnode = activeASTnode.addChild( null, ( nestUnnameTOK == TOK.Tunion ? B_UNION : B_TYPE ), null, null, null, _lineNum );
							parseTypeBody( activeASTnode.kind );
							break;
						}

					//case TOK.Tidentifier:
					default:
						_name = token().identifier;
						_lineNum = token().lineNumber;
						parseToken(); 

						// Array
						if( token().tok == TOK.Topenparen ) _name ~= parseArray();

						// fieldname : bits As DataType [= initializer]
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							if( token().tok == TOK.Tnumbers ) parseToken( TOK.Tnumbers );else return false;
						}
					
						if( token().tok == TOK.Tas )
						{
							parseToken( TOK.Tas );

							if(	parseFunctionPointer( _name, _lineNum ) ) break;

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

								// [= initializer]
								if( token().tok == TOK.Tassign )
								{
									parseToken( TOK.Tassign );
									if( token().tok == TOK.Tstring || token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers ) parseToken();else return false;
								}
							
								activeASTnode.addChild( _name, B_VARIABLE, _protection, _type, null, _lineNum );
							}
						}
						else
						{
							return false;
						}
				}
			}

			// After exit loop......
			if( token().tok == TOK.Tend && next().tok == B_KIND )
			{
				tokenIndex += 2;
				activeASTnode = activeASTnode.getFather( token().lineNumber );
				return true;
			}			
		}
		catch( Exception e )
		{
		}

		return false;
	}

	bool parseFunctionPointer( char[] _name, int _lineNumber )
	{
		char[] 	_param, _type;
		int		_kind;
		
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

			if( token().tok == TOK.Topenparen ) _param = parseParam( true );

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
					activeASTnode.addChild( _name, _kind, null, _type, null, _lineNumber );
					
					return true;
				}
			}

			if( token().tok == TOK.Tstatic || token().tok == TOK.Texport  ) parseToken();
			
			if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
			{
				activeASTnode.addChild( _name, _kind, null, _param, null, _lineNumber );
				return true;
			}		
		}

		return false;
	}

	bool parseType( bool bClass = false )
	{
		try
		{
			char[] 	_name, _param, _type, _base;
			int		_lineNum, _kind;

			/+
			if( tokenIndex != 0 )
			{
				if( prev().tok != TOK.Tcolon && prev().tok != TOK.Teol )
				{
					parseToken();
					return false;
				}
			}
			+/

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

					if( parseFunctionPointer( _name, _lineNum ) ) return true;

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

					/+
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

						if( token().tok == TOK.Topenparen ) _param = parseParam( true );

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
					+/
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
							parseToken( TOK.Tnumbers );//else return false;
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
						parseTypeBody( _kind );
					}
				}
			}
		}
		catch( Exception e )
		{
		}

		return false;
	}

	bool parseEnumBody()
	{
		try
		{
			char[] 	_name, _param, _type, _base;
			int		_lineNum;
			
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
		catch( Exception e ){}

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

					parseEnumBody();

					/+
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
					+/
				}
			}
		}
		catch( Exception e ){}

		return false;
	}

	bool parseScope()
	{
		if( next().tok == TOK.Teol || next().tok == TOK.Tcolon )
		{
			activeASTnode = activeASTnode.addChild( null, B_SCOPE, null, null, null, token().lineNumber );
			parseToken( TOK.Tscope );
		}
		else
		{
			return false;
		}

		return true;
	}	
	
	bool parseEnd()
	{
		try
		{
			parseToken( TOK.Tend );

			switch( token().tok )
			{
				case TOK.Tsub, TOK.Tfunction, TOK.Tproperty, TOK.Toperator, TOK.Tconstructor, TOK.Tdestructor, TOK.Ttype, TOK.Tenum, TOK.Tunion, TOK.Tnamespace, TOK.Tscope:
					parseToken();
					if( activeASTnode.getFather() !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );

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
	this(){}
	
	this( TokenUnit[] _tokens )
	{
		updateTokens( _tokens );
	}

	void updateTokens( TokenUnit[] _tokens )
	{
		tokenIndex = 0;
		delete tokens;
		tokens.length = 0;
		tokens = _tokens;
		activeASTnode = null;
	}
	
	CASTnode parse( char[] fullPath, int B_KIND = 0 )
	{
		scope f = new FilePath( fullPath );

		CASTnode		head;

		
		char[]		_ext;
		if( toLower( f.ext() ) == "bas" ) 
		{
			head = new CASTnode( fullPath, B_BAS, null, null, null, 0, 2147483647 );
		}
		else
		{
			head = new CASTnode( fullPath, B_BI, null, null, null, 0, 2147483647 );
		}

		activeASTnode = head;

		while( tokenIndex < tokens.length )
		{
			if( B_KIND > 0 )
			{
				if( B_KIND & ( B_TYPE | B_UNION ) )
					parseTypeBody( B_TYPE );
				else if( B_KIND & B_ENUM )
					parseEnumBody();
					
				break;
			}

			// Pass Member Acdess
			if( tokenIndex > 0 )
			{
				if( prev().tok == TOK.Tdot || prev.tok == TOK.Tptraccess )
				{
					tokenIndex ++;
					continue;
				}
			}
			
			switch( tokens[tokenIndex].tok )
			{
				case TOK.Tprivate:
					parseToken( TOK.Tprivate );
					if( token().tok == TOK.Tsub || token().tok == TOK.Tfunction ) parseProcedure( false, "private" );
					break;

				case TOK.Tprotected:
					parseToken( TOK.Tprotected );
					if( token().tok == TOK.Tsub || token().tok == TOK.Tfunction ) parseProcedure( false, "protected" );
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
				case TOK.Tredim:
					parseVariable();
					break;

				case TOK.Tvar:
					parserVar();
					break;

				case TOK.Tfunction, TOK.Tsub, TOK.Tproperty, TOK.Tconstructor, TOK.Tdestructor:
					parseProcedure( false, null );
					break;

				case TOK.Toperator:
					parseOperator( false, null );
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

				case TOK.Tscope:
					parseScope();
					break;

				case TOK.Tnamespace:
					parseNamespace();
					break;
					
				case TOK.Tdeclare:
					parseToken( TOK.Tdeclare );
					
					if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub || token().tok == TOK.Tconstructor || token().tok == TOK.Tdestructor || token().tok == TOK.Tproperty )
					{
						parseProcedure( true, null );
					}
					else if( token().tok == TOK.Toperator )
					{
						parseOperator( true, null );
					}
					break;

				case TOK.Tendmacro:
					activeASTnode = activeASTnode.getFather( token().lineNumber );					

				default:
					tokenIndex ++;
					//Stdout( tokenIndex );
					//Stdout( "   " ~ token().identifier ).newline;
			}
		}

		if( activeASTnode != head ) head.endLineNum = 2147483646; else head.endLineNum = 2147483647;
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