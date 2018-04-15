module parser.parser;

class CParser
{
	private:
	import			parser.ast;
	import			parser.token, parser.autocompletion;

	import			tango.io.FilePath, tango.text.Ascii, Path = tango.io.Path;
	import			Util = tango.text.Util;
	import 			tango.io.Stdout;

	import			global, tools;

	TokenUnit[]		tokens;
	int				tokenIndex;
	CASTnode		activeASTnode;
	CASTnode		head;
	
	version(DIDE)
	{
		char[]			activeProt;
		bool			bAssignExpress;

		CStack!(char[]) curlyStack;
		CStack!(char[])	protStack;
		CStack!(char[])	parseStack;
	}
	
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
		if( tokenIndex < tokens.length - 1 ) 
			tokenIndex ++;
		else
			throw new Exception( "Method parseToken(), out of range!" );
	}

	TokenUnit getToken(){ return tokens[tokenIndex]; }

	version(FBIDE)
	{
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

							activeASTnode.addChild( Path.normalize( t.identifier ) , B_INCLUDE, null, _type, null, t.lineNumber );
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
				throw e;
				//debug Stdout( e.toString ~ "  ::  parsePreprocessor" ).newline;
				return false;
			}

			return true;
		}

		char[] getVariableType()
		{
			try
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
				
				if( token().tok == TOK.Tconst ) parseToken( TOK.Tconst );
				
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
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  getVariableType" ).newline;
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
									parseToken();
								else if( token().tok == TOK.Tidentifier ) // like " Declare Function app_oninit_cb WXCALL () As wxBool "
									parseToken( TOK.Tidentifier );

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
										if( _kind == B_FUNCTION ) activeASTnode.addChild( _name, _kind, null, _type, null, _lineNum ); else return null;
										
										//return true;
									}
								}
								else
								{
									if( _kind == B_SUB ) activeASTnode.addChild( _name, _kind, null, __param, null, _lineNum ); else return null;
								}
								
								if( token().tok == TOK.Tstatic || token().tok == TOK.Texport ) parseToken();

								if( token().tok == TOK.Tcomma || token().tok == TOK.Tcloseparen )
								{
									if( token().tok == TOK.Tcomma )
									{
										_param ~= ( token().identifier );
										parseToken( TOK.Tcomma );
									}
								}
								
								// Back to while-loop top
								continue;
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

				if( token().tok == TOK.Tcloseparen )
				{
					parseToken( TOK.Tcloseparen );
					if( _param[length-1] == ' ' ) _param = _param[0..length-1];
					_param ~= ")";
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseParam" ).newline;
				return null;
			}

			return _param;
		}

		char[] parseArray()
		{
			char[] result;
			
			try
			{
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
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseArray" ).newline;
			}
			
			return result;
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

									while( token.tok != TOK.Teol && token.tok != TOK.Tcolon )
									{
										if( token().tok == TOK.Topencurly )
										{
											countCurly ++;
										}
										else if( token().tok == TOK.Tclosecurly )
										{
											countCurly --;
										}
										else if( token().tok == TOK.Topenparen )
										{
											countParen ++;
										}
										else if( token().tok == TOK.Tcloseparen )
										{
											countParen --;
										}

										if( token().tok == TOK.Tcomma )
										{
											if( countParen == 0 && countCurly == 0 ) break;
										}
										parseToken();
										if( tokenIndex >= tokens.length ) break;
									}

									/+
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
									+/

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
										bool bSingle;
										if( token().tok == TOK.Tnumbers )
										{
											if( Util.index( token().identifier, "." ) < token().identifier.length ) bSingle = true;
										}
										parseToken( );
										
										if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
										{
											parseToken( );
											if( bSingle ) activeASTnode.addChild( _name, B_VARIABLE, null, "single", null, _lineNum ); else activeASTnode.addChild( _name, B_VARIABLE, null, "integer", null, _lineNum );
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
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseVariable" ).newline;
			}

			return false;
		}

		// Var [Shared] symbolname = expression[, symbolname = expression]
		bool parserVar()
		{
			try
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
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parserVar" ).newline;
				return false;
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
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseNamespace" ).newline;
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
								if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
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
								
									if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
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
									if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
								}
							}
							else // delete
							{
								activeASTnode.type = _param;
								if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
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
									if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
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
										if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
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
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseOperator" ).newline;
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
						
						/+
						// Lazy GO!!!^^
						while( token().tok != TOK.Teol && token().tok != TOK.Topenparen && token().tok != TOK.Tcolon )
						{
							parseToken();
						}
						+/
						
						if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal ) 
							parseToken();
						else if( token().tok == TOK.Tidentifier ) // like " Declare Function app_oninit_cb WXCALL () As wxBool "
							parseToken( TOK.Tidentifier );

						// Overload
						if( token().tok == TOK.Toverload ) parseToken( TOK.Toverload );
						
						// Lib "..."
						if( bDeclare )
						{
							if( token().tok == TOK.Tlib )
							{
								parseToken( TOK.Tlib );
								if( token.tok == TOK.Tstrings ) parseToken( TOK.Tstrings ); else return false;
							}
						}
						
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
								if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );

								if( token().tok == TOK.Tstatic ) parseToken( TOK.Tstatic );
								
								return true;
							}
						}

						if( token().tok == TOK.Tstatic || token().tok == TOK.Texport || token().tok == TOK.Toverride ) parseToken();
						
						if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
						{
							activeASTnode.type = _param;
							if( bDeclare && activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( _lineNum );//token().lineNumber );
							return true;
						}						
					}
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseProcedure" ).newline;
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
									_lineNum = token().lineNumber;
									_name	= token().identifier;
									
									parseToken( TOK.Tidentifier );

									// Array
									if( token().tok == TOK.Topenparen ) _name ~= parseArray();
									
									// As DataType fieldname : bits [= initializer], ...
									if( token().tok == TOK.Tcolon )
									{
										parseToken( TOK.Tcolon );
										if( token().tok == TOK.Tnumbers ) parseToken( TOK.Tnumbers );else return false;
									}								
									
									if( token().tok == TOK.Tassign )
									{
										parseToken( TOK.Tassign );

										int countCurly, countParen;

										while( token.tok != TOK.Teol && token.tok != TOK.Tcolon )
										{
											if( token().tok == TOK.Topencurly )
											{
												countCurly ++;
											}
											else if( token().tok == TOK.Tclosecurly )
											{
												countCurly --;
											}
											else if( token().tok == TOK.Topenparen )
											{
												countParen ++;
											}
											else if( token().tok == TOK.Tcloseparen )
											{
												countParen --;
											}

											if( token().tok == TOK.Tcomma )
											{
												if( countParen == 0 && countCurly == 0 ) break;
											}
											parseToken();
											if( tokenIndex >= tokens.length ) break;
										}
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
									
								
								/+
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
								+/
							}
							else
							{
								parseToken();
							}
							
							break;

						case TOK.Tstatic:
							parseToken( TOK.Tstatic );
							break;

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
								if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );
							}
							else
							{
								return false;
							}						
							break;

						case TOK.Tunion, TOK.Ttype:
							if( next().tok != TOK.Tas ) // If Not Variable......
							{
								TOK nestUnnameTOK = token().tok;
								_lineNum = token().lineNumber;
								
								parseToken();
								
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

								if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
								{
									tokenIndex += 1;
									activeASTnode = activeASTnode.addChild( null, ( nestUnnameTOK == TOK.Tunion ? B_UNION : B_TYPE ), null, null, null, _lineNum );
									parseTypeBody( activeASTnode.kind );
									break;
								}
								else
								{
									return false;
								}
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
					if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );
					return true;
				}			
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseTypeBody" ).newline;
			}

			return false;
		}

		bool parseFunctionPointer( char[] _name, int _lineNumber )
		{
			try
			{
				char[] 	_param, _type;
				int		_kind;
				
				// Function pointer
				if( token().tok == TOK.Tfunction || token().tok == TOK.Tsub )
				{
					if( token().tok == TOK.Tfunction ) _kind = B_FUNCTION; else _kind = B_SUB;
					parseToken();
					
					if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal ) 
						parseToken();
					else if( token().tok == TOK.Tidentifier ) // like " Declare Function app_oninit_cb WXCALL () As wxBool "
						parseToken( TOK.Tidentifier );			

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

					if( token().tok == TOK.Tstatic || token().tok == TOK.Texport || token().tok == TOK.Toverride ) parseToken();
					
					if( token().tok == TOK.Teol || token().tok == TOK.Tcolon ) // SUB
					{
						activeASTnode.addChild( _name, _kind, null, _param, null, _lineNumber );
						return true;
					}		
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseFunctionPointer" ).newline;
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

				if( token().tok == TOK.Ttype || token().tok == TOK.Tunion || ( bClass && token().tok == TOK.Tclass ) )
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
				throw e;
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
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseTypeBody" ).newline;
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
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseEnum" ).newline;
			}

			return false;
		}

		bool parseScope()
		{
			try
			{
				parseToken( TOK.Tscope );
				if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
				{
					activeASTnode = activeASTnode.addChild( null, B_SCOPE, null, null, null, token().lineNumber );
				}
				else
				{
					return false;
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseScope" ).newline;
				return false;
			}

			return true;
		}
		
		bool parseWith()
		{
			try
			{
				parseToken( TOK.Twith );
				
				if( token().tok == TOK.Tidentifier )
				{
					char[] user_defined_var;
					do
					{
						user_defined_var ~= token().identifier;
						parseToken();
					}
					while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
						
					activeASTnode = activeASTnode.addChild( user_defined_var, B_WITH, null, null, null, token().lineNumber );
					parseToken( TOK.Tidentifier );
					return true;
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseWith" ).newline;
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
					case TOK.Tsub, TOK.Tfunction, TOK.Tproperty, TOK.Toperator, TOK.Tconstructor, TOK.Tdestructor, TOK.Ttype, TOK.Tenum, TOK.Tunion, TOK.Tnamespace, TOK.Tscope, TOK.Twith, TOK.Tclass:
						parseToken();
						if( activeASTnode.getFather() !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );

						break;
					default:
						//parseToken();
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseEnd" ).newline;
			}

			return true;
		}
	}
	
	version(DIDE)
	{
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
							_countDemlimit ++;
						}
						else if( token().tok == _tokClose )
						{
							_countDemlimit --;
						}
						else if( token().tok == TOK.Tidentifier )
							_params ~= ( " " ~ token().identifier );
						else
							_params ~= token().identifier;
						
						parseToken();
					}
					while( _countDemlimit > 0 )
				}

				_params = Util.trim( _params );
				switch( _tokOpen )
				{
					case TOK.Topenparen:		_params = "(" ~ _params ~ ")"; break;
					case TOK.Topenbracket:		_params = "[" ~ _params ~ "]"; break;
					case TOK.Topencurly:		_params = "{" ~ _params ~ "}"; break;
				}
				
				return _params;
			}
			catch( Exception e )
			{
				throw e;
			}
			
			return null;
		}

		char[] getProt()
		{
			char[] result;
			
			if( !activeProt.length )
			{
				char[] _stackValue = protStack.top();
				
				if( _stackValue != "{" )
				{
					if( _stackValue.length > 1 )
					{
						if( _stackValue[$-1] == '{' ||  _stackValue[$-1] == ':' )  _stackValue =  _stackValue[0..$-1];
					}
				
					return _stackValue;
				}
			}

			return activeProt;
		}

		char[] getTokenIdentifierUntil( int[] _tokens ... )
		{
			char[]	_result;
			int		_countParen, _countCurly, _countBracket;
			bool	bExitFlag;
			
			try
			{
				while( tokenIndex < tokens.length )
				{
					if( token().tok == TOK.Topenparen )
						_countParen ++;
					else if( token().tok == TOK.Tcloseparen )
						_countParen --;
					else if( token().tok == TOK.Topenbracket )
						_countBracket ++;
					else if( token().tok == TOK.Tclosebracket )
						_countBracket --;
					else if( token().tok == TOK.Topencurly )
						_countCurly ++;
					else if( token().tok == TOK.Tclosecurly )
						_countCurly --;

					foreach( int _tok; _tokens )
					{
						if( token().tok == _tok )
						{
							if( _countParen <= 0 && _countBracket <= 0 && _countCurly <= 0 )
							{
								bExitFlag = true;
								break;
							}
						}
					}

					if( bExitFlag ) break;
					_result ~= token().identifier;
					parseToken();
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _result;
		}


		/***************************************************************************TYPE***************************************************************************/
		/*
		Type:
			TypeCtors<opt> BasicType BasicType2<opt>
		*/	
		char[] getType()
		{
			char[]	_type;

			try
			{
				/*
				while( isTypeCtor() )
				{
					if( next().tok != TOK.Topenparen ) parseToken(); else break;
				}
				*/

				_type = getBasicType();
				_type ~= getBasicType2();
			}
			catch( Exception e )
			{
				throw e;
			}

			return _type;
		}

		/*
		BasicType:
			BasicTypeX
			. IdentifierList
			IdentifierList
			Typeof
			Typeof . IdentifierList
			TypeCtor ( Type )
			TypeVector	
		*/
		char[] getBasicType()
		{
			char[] _type;

			try
			{
				if( isBasicTypeX() ) // BasicTypeX
				{
					_type = token().identifier;
					parseToken();
				}
				else if( token().tok == TOK.Tidentifier ) // IdentifierList
				{
					_type = getIdentifierList();
				}
				else if( token().tok == TOK.Tdot && next().tok == TOK.Tidentifier ) // . IdentifierList
				{
					parseToken( TOK.Tdot );
					_type = "." ~ getIdentifierList();
				}
				else if( token().tok == TOK.Ttypeof )
				{
					_type = getTypeof();
					if( token().tok == TOK.Tdot )
					{
						_type ~= ".";
						parseToken( TOK.Tdot );
						_type ~= getIdentifierList();
					}
				}
				else if( token().tok == TOK.T__vector )
				{
					_type = get__Vector();
				}
				else if( isTypeCtor() )
				{
					while( isTypeCtor() )
						parseToken();

					if( token().tok == TOK.Topenparen )
					{
						parseToken( TOK.Topenparen );

						_type = getType();
					
						if( token().tok == TOK.Tcloseparen ) parseToken( TOK.Tcloseparen ); else throw new Exception( "BasicType Parse Error!" );
					}
				}
				else
				{
					throw new Exception( "BasicType Parse Error!" );
				}
			}
			catch( Exception e )
			{
				throw e;
			}
			
			return _type;
		}

		/*
		BasicType2:
			BasicType2X BasicType2<opt>

		BasicType2X:
			*
			[ ]
			[ AssignExpression ]
			[ AssignExpression .. AssignExpression ]
			[ Type ]
			delegate Parameters MemberFunctionAttributes<opt>
			function Parameters FunctionAttributes<opt>
		*/
		char[] getBasicType2()
		{
			char[] _type;

			try
			{
				if( token().tok == TOK.Tdelegate || token().tok == TOK.Tfunction )
				{
					_type ~= ( " " ~ token().identifier );
					parseToken();

					if( token().tok == TOK.Topenparen )
					{
						// Variable
						int funTailIndex = getFunctionDeclareTailIndex();
						if( tokens[funTailIndex].tok == TOK.Tidentifier ) _type ~= getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
					}
				}
				else
				{
					do
					{
						if( token().tok == TOK.Ttimes ) // Check Pointer
						{
							_type ~= "*";
							parseToken( TOK.Ttimes );
						}

						if( token().tok == TOK.Topenbracket ) // Check Array
						{
							_type ~= getDelimitedString( TOK.Topenbracket, TOK.Tclosebracket ); // Include [.......]
						}
					}
					while( token().tok == TOK.Ttimes || token().tok == TOK.Topenbracket )
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _type;
		}	

		// IdentifierList = Symbol
		/*
		IdentifierList:
			Identifier
			Identifier . IdentifierList
			TemplateInstance
			TemplateInstance . IdentifierList
			Identifier [ AssignExpression ]. IdentifierList
		*/
		char[] getIdentifierList()
		{
			char[] _result;

			try
			{
				if( token().tok == TOK.Tidentifier && next().tok == TOK.Tnot )
				{
					_result ~= getTemplateInstance(); // Template, check TemplateInstance
				}
				else if( token().tok == TOK.Tidentifier )
				{
					_result = token().identifier;
					parseToken( TOK.Tidentifier );

					if( token().tok == TOK.Topenbracket ) _result ~= getDelimitedString( TOK.Topenbracket, TOK.Tclosebracket ); // Array
				}
				else
				{
					throw new Exception( "getIdentifierList Parse Error!" );
					return null;
				}

				if( token().tok == TOK.Tdot )
				{
					_result ~= ".";
					parseToken( TOK.Tdot );
					_result ~= getIdentifierList();
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _result;
		}

		/*
		Typeof:
			typeof ( Expression )
			typeof ( return )

		TypeVector:
			__vector ( Type )
		*/
		char[] getTypeof()
		{
			char[]	_type;
			
			try
			{
				if( token().tok == TOK.Ttypeof )
				{
					parseToken( TOK.Ttypeof );
					if( token().tok == TOK.Topenparen )
					{
						parseToken( TOK.Topenparen );
						
						if( token().tok == TOK.Treturn || token().tok == TOK.Tthis || token().tok == TOK.Tsuper )
						{
							_type = token().identifier;
							parseToken();
							if( token().tok == TOK.Tcloseparen ) parseToken( TOK.Tcloseparen ); else throw new Exception( "Typeof Parse Error!" );
						}
						else if( token().tok == TOK.Tnumbers )
						{
							_type = "int";
							if( token().tok == TOK.Tcloseparen ) parseToken( TOK.Tcloseparen ); else throw new Exception( "Typeof Parse Error!" );
						}
						else
						{
							_type = getDelimitedString( TOK.Topenparen,TOK.Tcloseparen );
						}
					}
					else
					{
						throw new Exception( "Typeof Parse Error!" );
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _type;
		}

		char[] get__Vector()
		{
			char[]	_type;
			
			try
			{
				if( token().tok == TOK.T__vector )
				{
					parseToken( TOK.T__vector );
					if( token().tok == TOK.Topenparen )
					{
						parseToken( TOK.Topenparen );

						_type = getType();

						if( token().tok == TOK.Tcloseparen ) parseToken( TOK.Tcloseparen ); else throw new Exception( "Typeof Parse Error!" );
					}
					else
					{
						throw new Exception( "Typeof Parse Error!" );
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _type;
		}


		/*
		TypeCtor:
			const
			immutable
			inout
			shared
		*/
		bool isTypeCtor()
		{
			switch( token().tok )
			{
				case TOK.Tconst, TOK.Timmutable, TOK.Tinout, TOK.Tshared:	return true;
				default:
			}
			
			return false;
		}

		/*
		BasicTypeX:
			bool
			byte
			ubyte
			short
			ushort
			int
			uint
			long
			ulong
			char
			wchar
			dchar
			float
			double
			real
			ifloat
			idouble
			ireal
			cfloat
			cdouble
			creal
			void
		*/
		bool isBasicTypeX()
		{
			switch( token().tok )
			{
				case TOK.Tbool, TOK.Tbyte, TOK.Tubyte, TOK.Tshort, TOK.Tushort, TOK.Tint, TOK.Tuint, TOK.Tlong, TOK.Tulong,
					TOK.Tchar, TOK.Tdchar, TOK.Twchar,
					TOK.Tfloat, TOK.Tdouble, TOK.Treal, TOK.Tifloat, TOK.Tidouble, TOK.Tireal, TOK.Tcfloat, TOK.Tcdouble, TOK.Tcreal,
					TOK.Tvoid:
					return true;
				default:
			}
			return false;
		}

		/*
		VisibilityAttribute:
			private
			package
			package ( IdentifierList )
			protected
			public
			export
		*/
		bool isVisibilityAttribute()
		{
			switch( token().tok )
			{
				case TOK.Tprivate, TOK.Tprotected, TOK.Tpublic, TOK.Texport:
					return true;
				case TOK.Tpackage:
					return true;
				default:
			}
			return false;
		}








		

		/*
		MemberFunctionAttributes:
			MemberFunctionAttribute
			MemberFunctionAttribute MemberFunctionAttributes

		MemberFunctionAttribute:
			const
			immutable
			inout
			return
			shared
			FunctionAttribute

		FunctionAttribute:
			nothrow
			pure
			Property		
		*/
		bool isMemberFunctionAttribute( int _tempTokenIndex = -1 )
		{
			if( _tempTokenIndex < 0 ) _tempTokenIndex = tokenIndex;
			if( _tempTokenIndex >= tokens.length ) return false;
			
			switch( tokens[_tempTokenIndex].tok )
			{
				case TOK.Tconst, TOK.Timmutable, TOK.Tinout, TOK.Treturn, TOK.Tshared, TOK.Tnothrow, TOK.Tpure://, TOK.TProperty:
					return false;
				default:
			}

			return false;
		}

		int getFunctionDeclareTailIndex( int _startIndex = -1 )
		{
			int _countDemlimit;
			int _tempTokenIndex = tokenIndex;
			if( _startIndex != -1 ) _tempTokenIndex = _startIndex;
			
			if( _tempTokenIndex >= tokens.length ) throw new Exception( "out of range!" );

			try
			{
				do
				{
					if( tokens[_tempTokenIndex].tok == TOK.Topenparen )
						_countDemlimit ++;
					else if( tokens[_tempTokenIndex].tok == TOK.Tcloseparen )
						_countDemlimit --;
					else if( tokens[_tempTokenIndex].tok == TOK.Tsemicolon )
					{
						throw new Exception( "isFunctionDeclare Break Error!" );
					}

					_tempTokenIndex ++;
				}
				while( _countDemlimit != 0 )

				// Pass MemberFunctionAttribute
				while( isMemberFunctionAttribute( _tempTokenIndex ) )
				{
					_tempTokenIndex ++;
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _tempTokenIndex;
		}








		/***************************************************************************MODULES***************************************************************************/
		/*
		ImportDeclaration:
			import ImportList ;
			static import ImportList ;

		ImportList:
			Import
			ImportBindings
			Import , ImportList

		Import:
			ModuleFullyQualifiedName
			ModuleAliasIdentifier = ModuleFullyQualifiedName

		ImportBindings:
			Import : ImportBindList

		ImportBindList:
			ImportBind
			ImportBind , ImportBindList

		ImportBind:
			Identifier
			Identifier = Identifier

		ModuleAliasIdentifier:
			Identifier
		*/
		char[] getModuleName()
		{
			char[] _result;

			try
			{
				if( token().tok == TOK.Tidentifier )
				{
					_result = token().identifier;
					parseToken( TOK.Tidentifier );

					if( token().tok == TOK.Tdot )
					{
						_result ~= ".";
						parseToken( TOK.Tdot );
						_result ~= getModuleName();
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _result;
		}

		// Modules -- module
		bool parseModule()
		{
			bool bDeprecated;
			
			try
			{
				if( tokenIndex > 0 )
					if( prev().tok == TOK.Tdeprecated ) bDeprecated = true;


				parseToken( TOK.Tmodule );
				int _ln = token().lineNumber;
				
				if( token().tok == TOK.Tidentifier )
				{
					char[] moduleName = getModuleName();
					if( moduleName.length )
					{
						CASTnode _head = activeASTnode;
						while( _head.getFather !is null )
							_head = _head.getFather;

						if( _head.kind & D_MODULE )
						{
							_head.name = moduleName;
							_head.protection = bDeprecated ? "deprecated" : "";
							_head.lineNumber = _ln;
						}

						return true;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		// Modules -- import
		bool parseImport()
		{
			try
			{
				if( token().tok == TOK.Timport )
				{
					parseToken( TOK.Timport );
					
					if( token().tok == TOK.Tidentifier ) return parseImportList();
				}
			}
			catch
			{
				throw new Exception( "parseImport Error!!" );
			}

			return false;
		}

		bool parseImportList()
		{
			char[]	importName, bindName, baseName;
			int		_ln = token().lineNumber;
			
			try
			{
				if( token().tok == TOK.Tidentifier )
				{
					importName = getModuleName();
					
					if( importName.length )
					{
						if( token().tok == TOK.Tassign )
						{
							parseToken( TOK.Tassign );
							bindName = getModuleName();
						}
						
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							baseName = getModuleName();
						}			
						
						if( token().tok == TOK.Tcomma )
						{
							activeASTnode.addChild( importName, D_IMPORT, getProt(), bindName, baseName, _ln );
							parseToken( TOK.Tcomma );
							parseImportList();
						}
						else if( token().tok == TOK.Tsemicolon )
						{
							activeASTnode.addChild( importName, D_IMPORT, getProt(), bindName, baseName, _ln );
							return true;
						}
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}
			
			return false;
		}
		
		






		/***************************************************************************DECLARATIONS***************************************************************************/
		/*
		VarDeclarations:
			StorageClasses<opt> BasicType Declarators ;
			AutoDeclaration

		Declarators:
			DeclaratorInitializer
			DeclaratorInitializer , DeclaratorIdentifierList

		DeclaratorInitializer:
			VarDeclarator
			VarDeclarator TemplateParametersopt = Initializer
			AltDeclarator
			AltDeclarator = Initializer

		DeclaratorIdentifierList:
			DeclaratorIdentifier
			DeclaratorIdentifier , DeclaratorIdentifierList

		DeclaratorIdentifier:
			VarDeclaratorIdentifier
			AltDeclaratorIdentifier

		VarDeclaratorIdentifier:
			Identifier
			Identifier TemplateParametersopt = Initializer

		AltDeclaratorIdentifier:
			BasicType2 Identifier AltDeclaratorSuffixes<opt>
			BasicType2 Identifier AltDeclaratorSuffixes<opt> = Initializer
			BasicType2<opt> Identifier AltDeclaratorSuffixes
			BasicType2<opt> Identifier AltDeclaratorSuffixes = Initializer

		Declarator:
			VarDeclarator
			AltDeclarator

		VarDeclarator:
			BasicType2<opt> Identifier

		AltDeclarator:
			BasicType2<opt> Identifier AltDeclaratorSuffixes
			BasicType2<opt> ( AltDeclaratorX )
			BasicType2<opt> ( AltDeclaratorX ) AltFuncDeclaratorSuffix
			BasicType2<opt> ( AltDeclaratorX ) AltDeclaratorSuffixes

		AltDeclaratorX:
			BasicType2<opt> Identifier
			BasicType2<opt> Identifier AltFuncDeclaratorSuffix
			AltDeclarator

		AltDeclaratorSuffixes:
			AltDeclaratorSuffix
			AltDeclaratorSuffix AltDeclaratorSuffixes

		AltDeclaratorSuffix:
			[ ]
			[ AssignExpression ]
			[ Type ]

		AltFuncDeclaratorSuffix:
			Parameters MemberFunctionAttributes<opt>
		*/
		bool parseStorageClass()
		{
			try
			{
				while( isStorageClass() )
				{
					if( token().tok == TOK.Textern )
					{
						if( next().tok == TOK.Topenparen )
						{
							parseToken( TOK.Textern );
							parseToken( TOK.Topenparen );
							if( token().tok == TOK.Tidentifier && next().tok == TOK.Tcloseparen )
							{
								parseToken( TOK.Tidentifier );
								parseToken( TOK.Tcloseparen );
							}
						}
						else
						{
							parseToken( TOK.Textern );
						}
					}
					else
					{
						parseToken();
					}
				}
			}
			catch( Exception e )
			{
				throw new Exception( "parseStorageClass Error. " );
			}

			return true;
		}

		

		// Declarations & Types
		bool parseAutoDeclaration()
		{
			try
			{
				char[]	_name, _type, _rightExpress;
				int		_ln = token().lineNumber;

				if( token().tok == TOK.Tidentifier )
				{
					if( next().tok == TOK.Tassign )
					{
						_name = token().identifier;
						parseToken( TOK.Tidentifier );
					}
					else if( next().tok == TOK.Topenparen )
					{
						_name = token().identifier;
						parseToken( TOK.Tidentifier );
						_name ~= getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
					}
					else
					{
						parseToken( TOK.Tidentifier );
						return false;
					}

					if( token().tok == TOK.Tassign )
					{
						parseToken( TOK.Tassign );

						if( token().tok == TOK.Tnew )
						{
							parseToken( TOK.Tnew );

							if( _type == "" ) _type = getType();//token.identifier;
						}
						else if( token().tok == TOK.Tcast )
						{
							parseToken( TOK.Tcast );
							if( token().tok == TOK.Topenparen )
							{
								_type = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
								if( _type.length ) _type = _type[1..$-1];
							}
						}

						while( token().tok != TOK.Tcomma && token().tok != TOK.Tsemicolon )
						{
							if( token().tok == TOK.Topenbracket )
								_rightExpress ~= getDelimitedString( TOK.Topenbracket, TOK.Tclosebracket );
							else if( token().tok == TOK.Topencurly )
								_rightExpress ~= getDelimitedString( TOK.Topencurly, TOK.Tclosecurly );
							else if( token().tok == TOK.Topenparen )
								_rightExpress ~= getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
							else
							{
								_rightExpress ~= token().identifier;
								parseToken();
							}
						}

						if( token().tok == TOK.Tcomma )
						{
							activeASTnode.addChild( _name, D_VARIABLE, getProt(), _type, _rightExpress, _ln );
							parseAutoDeclaration();
						}
						else
						{
							activeASTnode.addChild( _name, D_VARIABLE, getProt(), _type, _rightExpress, _ln );
						}

						return true;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		/* 
		Type:
			TypeCtors<opt> BasicType BasicType2<opt>

		TypeCtors:
			TypeCtor
			TypeCtor TypeCtors

		TypeCtor:
			const
			immutable
			inout
			shared

		BasicType:
			BasicTypeX
			. IdentifierList
			IdentifierList
			Typeof
			Typeof . IdentifierList
			TypeCtor ( Type )
			TypeVector	

		BasicType2:
			BasicType2X BasicType2<opt>

		BasicType2X:
			*
			[ ]
			[ AssignExpression ]
			[ AssignExpression .. AssignExpression ]
			[ Type ]
			delegate Parameters MemberFunctionAttributes<opt>
			function Parameters FunctionAttributes<opt>

		IdentifierList:
			Identifier
			Identifier . IdentifierList
			TemplateInstance
			TemplateInstance . IdentifierList
			Identifier [ AssignExpression ]. IdentifierList
		*/
		bool parseType()
		{
			try
			{
				char[] _type = getType();
				/*
				getBasicType();
				_type ~= getBasicType2();
				*/

				if( token.tok == TOK.Tidentifier )
				{
					return parseVariableOrFunction( _type );
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		bool parseVariableOrFunction( char[] _type )
		{
			try
			{
				if( token().tok == TOK.Tidentifier && next().tok == TOK.Topenparen )
				{
					return parseFunction( _type );
				}
				else if( token().tok == TOK.Tidentifier )
				{
					return parseVariable( _type );
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}
		
		bool parseVariable( char[] _type )
		{
			char[]	_name, _rightName;
			int		_ln;

			try
			{
				if( token().tok == TOK.Tidentifier )
				{
					_name	= token.identifier;
					_ln		= token().lineNumber;
					
					parseToken( TOK.Tidentifier );
					
					while( token().tok != TOK.Tcomma && token().tok != TOK.Tsemicolon )
					{
						if( token().tok == TOK.Topenparen )
							getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						else if( token().tok == TOK.Topenbracket )
							getDelimitedString( TOK.Topenbracket, TOK.Tclosebracket );
						else if( token().tok == TOK.Topencurly )
							getDelimitedString( TOK.Topencurly, TOK.Tclosecurly );
						else
							parseToken();
					}
						
					if( token().tok == TOK.Tcomma )
					{
						activeASTnode.addChild( _name, D_VARIABLE, getProt(), _type, _rightName, _ln );
						parseToken( TOK.Tcomma );
						parseVariable( _type );
					}
					else if( token().tok == TOK.Tsemicolon )
					{
						activeASTnode.addChild( _name, D_VARIABLE, getProt(), _type, _rightName, _ln );
						return true;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}








		/***************************************************************************FUNCTION***************************************************************************/
		/*
		FuncDeclaration:
			StorageClasses<opt> BasicType FuncDeclarator FunctionBody
			AutoFuncDeclaration

		AutoFuncDeclaration:
			StorageClasses Identifier FuncDeclaratorSuffix FunctionBody

		FuncDeclarator:
			BasicType2<opt> Identifier FuncDeclaratorSuffix

		FuncDeclaratorSuffix:
			Parameters MemberFunctionAttributesopt
			TemplateParameters Parameters MemberFunctionAttributes<opt> Constraint<opt>
		*/
		bool parseFunction( char[] _type )
		{
			char[]	_name = token().identifier;
			int		_ln = token().lineNumber;
			
			try
			{
				parseToken( TOK.Tidentifier );

				if( token().tok == TOK.Topenparen )
				{
					char[] _params;

					int funTailIndex = getFunctionDeclareTailIndex();
					if( funTailIndex >= tokens.length )
					{
						
						return false;
					}
					
					if( tokens[funTailIndex].tok == TOK.Tsemicolon )
					{
						_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type ~ _params, null, _ln );
						return true;
					}
					else if( tokens[funTailIndex].tok == TOK.Topencurly || tokens[funTailIndex].tok == TOK.Topenparen )
					{
						if( tokens[funTailIndex].tok == TOK.Topenparen ) // Template Function
						{
							_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
							activeASTnode = activeASTnode.addChild( _name, D_TEMPLATE, getProt(), _params, null, _ln );
							curlyStack.push( "Aggregate Templates" );
						}
						
						// FunctionBody
						activeASTnode = activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type, null, _ln );
						_params = getParameters();
						activeASTnode.type = _type ~ _params;
						curlyStack.push( "Function" );
					}
					else if( tokens[funTailIndex].tok == TOK.Tin || tokens[funTailIndex].tok == TOK.Tout )
					{
						if( tokens[funTailIndex+1].tok == TOK.Topencurly )
						{
							activeASTnode = activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type, null, _ln );
							_params = getParameters();
							activeASTnode.type = _params;
							curlyStack.push( "Function" );
							curlyStack.push( "{" );
							
							while( isMemberFunctionAttribute() )
								parseToken();
								
							return true;
						}
					}				

					while( isMemberFunctionAttribute() )
						parseToken();

					parseConstraint();
				}
			}
			catch( Exception e )
			{
				throw e;
			}
			
			return false;
		}


		bool parseTempleFunction( char[] _type )
		{
			Stdout( _type ).newline;
			return true;
			/+
			char[]	_name = getSeparateParam( _type )token().identifier;
			int		_ln = token().lineNumber;

			parseToken( TOK.Tidentifier );

			if( token().tok == TOK.Topenparen )
			{
				char[] _params;

				try
				{
					if( isFunctionDeclare() )
					{
						Stdout( "isFunctionDeclare: " ~ _name ).newline;
						
						_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type ~ _params, null, _ln );
						return true;
					}
					else
					{
						Stdout( "isFunction: " ~ _name ).newline;
						
						int _countDemlimit;
						int _tempTokenIndex = tokenIndex;

						do
						{
							if( tokens[_tempTokenIndex].tok == TOK.Topenparen )
								_countDemlimit ++;
							else if( tokens[_tempTokenIndex].tok == TOK.Tcloseparen )
								_countDemlimit --;
							else if( tokens[_tempTokenIndex].tok == TOK.Tsemicolon )
							{
								throw new Exception( "isFunctionDeclare Break Error!" );
							}

							_tempTokenIndex ++;
						}
						while( _countDemlimit != 0 )

						// Check if Template Function
						if( tokens[_tempTokenIndex].tok == TOK.Topenparen )
						{
							_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
							activeASTnode = activeASTnode.addChild( _name, D_TEMPLATE, getProt(), _params, null, _ln );
							curlyStack.push( "Aggregate Templates" );
						}
						
						// FunctionBody
						activeASTnode = activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type, null, _ln );
						_params = getParameters();
						activeASTnode.type = _type ~ _params;
						curlyStack.push( "Function" );
					}

					while( isMemberFunctionAttribute() )
						parseToken();

					parseConstraint();
				}
				catch
				{

				}
			}
			+/

			return false;
		}
		
		/*
		Parameters:
			( ParameterList<opt> )

		ParameterList:
			Parameter
			Parameter , ParameterList
			...

		Parameter:
			InOut<opt> BasicType Declarator
			InOut<opt> BasicType Declarator ...
			InOut<opt> BasicType Declarator = AssignExpression
			InOut<opt> Type
			InOut<opt> Type ...

		InOut:
			InOutX
			InOut InOutX

		InOutX:
			auto
			TypeCtor
			final
			in
			lazy
			out
			ref
			scope

		.............................
		Declarator:
			VarDeclarator
			AltDeclarator

		VarDeclarator:
			BasicType2<opt> Identifier		

		AltDeclarator:
			BasicType2<opt> Identifier AltDeclaratorSuffixes
			BasicType2<opt> ( AltDeclaratorX )
			BasicType2<opt> ( AltDeclaratorX ) AltFuncDeclaratorSuffix
			BasicType2<opt> ( AltDeclaratorX ) AltDeclaratorSuffixes

		AltDeclaratorX:
			BasicType2<opt> Identifier
			BasicType2<opt> Identifier AltFuncDeclaratorSuffix
			AltDeclarator

		AltDeclaratorSuffixes:
			AltDeclaratorSuffix
			AltDeclaratorSuffix AltDeclaratorSuffixes

		AltDeclaratorSuffix:
			[ ]
			[ AssignExpression ]
			[ Type ]

		AltFuncDeclaratorSuffix:
			Parameters MemberFunctionAttributes<opt>			
		*/
		char[] getParameters()
		{
			char[]	_result;

			try
			{
				if( token().tok == TOK.Topenparen )
				{
					_result = "(";
					parseToken( TOK.Topenparen );
					
					if( token().tok == TOK.Tcloseparen )
					{
						parseToken( TOK.Tcloseparen );
						return "()";
					}
					else
					{
						_result ~= parseParameterList();
					}
				}
				else
				{
					throw new Exception( "Parameters Parse Error!" );
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _result;
		}

		/*
		ParameterList:
			Parameter
			Parameter , ParameterList
			...
		*/
		char[] parseParameterList()
		{
			char[]	_result, _type, _name;
			int		_ln;
			
			try
			{
				if( token().tok == TOK.Tdotdotdot )
				{
					_result ~= "...";
					parseToken( TOK.Tdotdotdot );
				}
				else
				{
					while( isInOut() )
					{
						_type ~= ( token().identifier ~ " " );
						parseToken();
					}

					_type ~= getBasicType();
					_type ~= getBasicType2();
					_result ~= ( _type ~ " " );

					/*
					VarDeclarator:
						BasicType2<opt> Identifier

					AltDeclarator:
						BasicType2<opt> Identifier AltDeclaratorSuffixes
					*/
					if( token().tok == TOK.Tidentifier )
					{
						_name = token().identifier;
						_ln		= token().lineNumber;
						parseToken( TOK.Tidentifier );
						_result ~= _name;
					}
					else if( token().tok == TOK.Topenparen )
					{
						/*
						AltDeclarator:
							BasicType2<opt> Identifier AltDeclaratorSuffixes
							BasicType2<opt> ( AltDeclaratorX )
							BasicType2<opt> ( AltDeclaratorX ) AltFuncDeclaratorSuffix
							BasicType2<opt> ( AltDeclaratorX ) AltDeclaratorSuffixes

						AltDeclaratorX:
							BasicType2<opt> Identifier
							BasicType2<opt> Identifier AltFuncDeclaratorSuffix
							AltDeclarator
						*/
						_result ~= getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );

						/*
						AltDeclaratorSuffixes:
							AltDeclaratorSuffix
							AltDeclaratorSuffix AltDeclaratorSuffixes

						AltDeclaratorSuffix:
							[ ]
							[ AssignExpression ]
							[ Type ]
						*/
						while( token().tok == TOK.Topenbracket )
							_result ~= getDelimitedString( TOK.Topenbracket, TOK.Tclosebracket );

						/*
						AltFuncDeclaratorSuffix:
							Parameters MemberFunctionAttributes<opt>
						*/
						if( token().tok == TOK.Topenparen ) _result ~= getParameters();
					}
				}

				if( token().tok == TOK.Tassign )
				{
					// _result ~= "=";
					parseToken();

					getTokenIdentifierUntil( TOK.Tcomma, TOK.Tcloseparen );
				}
				
				if( token().tok == TOK.Tdotdotdot )
				{
					_result ~= "...";
					parseToken( TOK.Tdotdotdot );
				}			
				
				if( token().tok == TOK.Tcomma )
				{
					_result ~= ",";
					parseToken( TOK.Tcomma );
					activeASTnode.addChild( _name, D_PARAM, null, _type, null, _ln );
					_type = _name = "";
					_result ~= parseParameterList();
				}
				else if( token().tok == TOK.Tcloseparen ) // Tail
				{
					_result ~= ")";
					parseToken( TOK.Tcloseparen );
					activeASTnode.addChild( _name, D_PARAM, null, _type, null, _ln );
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return _result;
		}

		bool isInOut()
		{
			switch( token().tok )
			{
				case TOK.Tauto, TOK.Tfinal, TOK.Tin, TOK.Tlazy, TOK.Tout, TOK.Tref, TOK.Tscope:
					return true;

				default:
					if( isTypeCtor() ) return true;
			}

			return false;
		}

		bool isStorageClass( int _token = -1 )
		{
			if( _token == -1 ) _token = token().tok;
			
			switch( _token )
			{
				case TOK.Tdeprecated, TOK.Tenum, TOK.Tstatic, TOK.Tabstract, TOK.Tfinal, TOK.Toverride, TOK.Tsynchronized, TOK.Tauto, TOK.Tscope, TOK.Tconst,
					TOK.Timmutable, TOK.Tinout, TOK.Tshared, TOK.T__gshared, TOK.TProperty, TOK.Tnothrow,TOK.Tpure, TOK.Tref:
						return true;

				case TOK.Textern, TOK.Talign:
					return true;

				default:
			}

			return false;
		}








		/***************************************************************************CLASS***************************************************************************/
		/*
		ClassDeclaration:
			class Identifier ;
			class Identifier BaseClassList<opt> AggregateBody
			ClassTemplateDeclaration

		BaseClassList:
			: SuperClass
			: SuperClass , Interfaces
			: Interfaces

		SuperClass:
			BasicType

		Interfaces:
			Interface
			Interface , Interfaces

		Interface:
			BasicType


		ClassTemplateDeclaration:
			class Identifier TemplateParameters Constraint<opt> BaseClassList<opt> AggregateBody
			class Identifier TemplateParameters BaseClassList<opt> Constraint<opt> AggregateBody		
		*/
		bool parseClass_Interface()
		{
			int D_KIND;
			
			if( token().tok == TOK.Tclass )
				D_KIND = D_CLASS;
			else if( token().tok == TOK.Tinterface )
				D_KIND = D_INTERFACE;
			else
				return false;

			try
			{
				parseToken(); // parseToken( TOK.Tclass ) or parseToken( TOK.Tinterface );
				
				if( token().tok == TOK.Tidentifier )
				{
					char[]	_baseName, _name = token().identifier;
					int		_ln = token().lineNumber;

					parseToken( TOK.Tidentifier );

					if( token().tok == TOK.Topenparen )
					{
						/*
						ClassTemplateDeclaration:
						InterfaceTemplateDeclaration:
						*/				
						if( !parseAggregateTemplates( D_KIND, _name, _baseName ) ) return false;
					}
					else
					{
						if( token().tok == TOK.Tsemicolon )
						{
							//parseToken( TOK.Tsemicolon );
							activeASTnode.addChild( _name, D_KIND, getProt(), null, null, _ln );
							return true;
						}
						else if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							
							// Not in Language Reference
							if( isVisibilityAttribute() ) parseToken();
							
							_baseName = getBasicType();
							if( token().tok == TOK.Tcomma )
							{
								parseToken( TOK.Tcomma );
								_baseName ~= ( "," ~ getBasicType() );
							}
						}
					}

					if( token().tok == TOK.Topencurly )
					{
						activeASTnode = activeASTnode.addChild( _name, D_KIND, getProt(), null, _baseName, _ln );
						curlyStack.push( "CLASS" );
						return true;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}
		/*
		Constructor:
			this Parameters MemberFunctionAttributes<opt> ;
			this Parameters MemberFunctionAttributes<opt> FunctionBody
			ConstructorTemplate

		ConstructorTemplate:
			this TemplateParameters Parameters MemberFunctionAttributes<opt> Constraint<opt> :
			this TemplateParameters Parameters MemberFunctionAttributes<opt> Constraint<opt> FunctionBody		
		*/
		bool parseConstructor()
		{
			try
			{
				if( token().tok == TOK.Tthis && next().tok == TOK.Topenparen )
				{
					char[]	_params;
					int		_ln = token().lineNumber;

					parseToken( TOK.Tthis );

					int funTailIndex = getFunctionDeclareTailIndex();
					if( tokens[funTailIndex].tok == TOK.Tsemicolon )
					{
						_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						//activeASTnode.addChild( null, D_CTOR, null, _params, null, _ln );
						return true;
					}
					else if( tokens[funTailIndex].tok == TOK.Topencurly )
					{
						activeASTnode = activeASTnode.addChild( null, D_CTOR, null, _params, null, _ln );
						_params = getParameters();
						activeASTnode.type = _params;
						curlyStack.push( "CTOR" );
					}
					else if( tokens[funTailIndex].tok == TOK.Tin || tokens[funTailIndex].tok == TOK.Tout )
					{
						if( tokens[funTailIndex+1].tok == TOK.Topencurly )
						{
							activeASTnode = activeASTnode.addChild( null, D_CTOR, null, _params, null, _ln );
							_params = getParameters();
							activeASTnode.type = _params;
							curlyStack.push( "CTOR" );
							curlyStack.push( "{" );
							
							while( isMemberFunctionAttribute() )
								parseToken();
								
							return true;
						}
					}			

					while( isMemberFunctionAttribute() )
						parseToken();

					if( token().tok == TOK.Topencurly ) return true;
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		/*
		Destructor:
			~ this ( ) MemberFunctionAttributes<opt> ;
			~ this ( ) MemberFunctionAttributes<opt> FunctionBody
		*/
		bool parseDestructor()
		{
			try
			{
				if( token().tok == TOK.Ttilde && next().tok == TOK.Tthis && next2().tok == TOK.Topenparen )
				{
					int		_ln = token().lineNumber;

					parseToken( TOK.Ttilde );
					parseToken( TOK.Tthis );

					int funTailIndex = getFunctionDeclareTailIndex();
					if( tokens[funTailIndex].tok == TOK.Tsemicolon )
					{
						getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode.addChild( null, D_DTOR, null, null, null, _ln );
						return true;
					}
					else if( tokens[funTailIndex].tok == TOK.Topencurly )
					{
						getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode = activeASTnode.addChild( null, D_DTOR, null, null, null, _ln );
						curlyStack.push( "DTOR" );
					}			

					while( isMemberFunctionAttribute() )
						parseToken();

					if( token().tok == TOK.Topencurly ) return true;
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}	



		/***************************************************************************STRUCT & UNION***************************************************************************/
		/*
		StructDeclaration:
			struct Identifier ;
			struct Identifier AggregateBody
			StructTemplateDeclaration
			AnonStructDeclaration

		AnonStructDeclaration:
			struct AggregateBody

		UnionDeclaration:
			union Identifier ;
			union Identifier AggregateBody
			UnionTemplateDeclaration
			AnonUnionDeclaration

		AnonUnionDeclaration:
			union AggregateBody

		AggregateBody:
			{ DeclDefsopt }
		*/
		bool parseStruct_Union()
		{
			int D_KIND;
			
			if( token().tok == TOK.Tstruct )
				D_KIND = D_STRUCT;
			else if( token().tok == TOK.Tunion )
				D_KIND = D_UNION;
			else
				return false;

			int		_ln =  token().lineNumber;
			
			try
			{
				parseToken(); // parseToken( TOK.Tstruct ) or parseToken( TOK.Tunion )

				if( token().tok == TOK.Tidentifier )
				{
					char[]	_baseName, _name = token().identifier;

					parseToken( TOK.Tidentifier );

					if( token().tok == TOK.Topenparen )
					{
						/*
						ClassTemplateDeclaration:
						InterfaceTemplateDeclaration:
						*/				
						if( !parseAggregateTemplates( D_KIND, _name, _baseName ) ) return false;
					}
					else
					{
						if( token().tok == TOK.Tsemicolon )
						{
							//parseToken( TOK.Tsemicolon );
							activeASTnode.addChild( _name, D_KIND, getProt(), null, null, _ln );
							return true;
						}
						else if( token().tok == TOK.Topencurly )
						{
							activeASTnode = activeASTnode.addChild( _name, D_KIND, getProt(), null, null, _ln );
							curlyStack.push( "CLASS" );
							return true;
						}
					}
				}
				else if( token().tok == TOK.Topencurly )
				{
					// AnonStructDeclaration
					activeASTnode = activeASTnode.addChild( "-Anonymous-", D_KIND, null, null, null, _ln );
					curlyStack.push( "CLASS" );
					return true;
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}








		/***************************************************************************ENUM***************************************************************************/
		/*
		EnumDeclaration:
			enum Identifier EnumBody
			enum Identifier : EnumBaseType EnumBody
			AnonymousEnumDeclaration

		EnumBaseType:
			Type

		EnumBody:
			{ EnumMembers }
			;

		EnumMembers:
			EnumMember
			EnumMember ,
			EnumMember , EnumMembers

		EnumMember:
			Identifier
			Identifier = AssignExpression

		AnonymousEnumDeclaration:
			enum : EnumBaseType { EnumMembers }
			enum { EnumMembers }
			enum { AnonymousEnumMembers }

		AnonymousEnumMembers:
			AnonymousEnumMember
			AnonymousEnumMember ,
			AnonymousEnumMember , AnonymousEnumMembers

		AnonymousEnumMember:
			EnumMember
			Type Identifier = AssignExpression
		*/
		bool parseEnum()
		{
			try
			{
				if( token().tok == TOK.Tenum )
				{
					parseToken( TOK.Tenum );

					int		_ln =  token().lineNumber;
					char[]	_EnumBaseType;
					
					if( token().tok == TOK.Tidentifier )
					{
						char[]	_name = token().identifier;
						
						parseToken( TOK.Tidentifier );
						/*
						EnumBody:
							{ EnumMembers }
							;

						EnumMembers:
							EnumMember
							EnumMember ,
							EnumMember , EnumMembers

						EnumMember:
							Identifier
							Identifier = AssignExpression				
						*/
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							_EnumBaseType = getBasicType();
						}
						
						if( token().tok == TOK.Tsemicolon )
						{
							//parseToken( TOK.Tsemicolon );
							activeASTnode.addChild( _name, D_ENUM, null, null, _EnumBaseType, _ln );
							return true;
						}
						else if( token().tok == TOK.Topencurly )
						{
							activeASTnode = activeASTnode.addChild( _name, D_ENUM, null, null, _EnumBaseType, _ln );

							// Since Enum Body is spacial.......
							parseToken( TOK.Topencurly );					
							if( parseEnumMembers( false, _EnumBaseType ) )
							{
								if( token().tok == TOK.Tclosecurly )
								{
									parseToken( TOK.Tclosecurly );
									if( activeASTnode.getFather !is null )activeASTnode = activeASTnode.getFather();
									return true;
								}
							}
						}
					}
					else
					{
						/*
						AnonymousEnumDeclaration:
							enum : EnumBaseType { EnumMembers }
							enum { EnumMembers }
							enum { AnonymousEnumMembers }

						AnonymousEnumMembers:
							AnonymousEnumMember
							AnonymousEnumMember ,
							AnonymousEnumMember , AnonymousEnumMembers

						AnonymousEnumMember:
							EnumMember
							Type Identifier = AssignExpression
						*/
						if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							_EnumBaseType = getType();
						}
						
						if( token().tok == TOK.Topencurly )
						{
							activeASTnode = activeASTnode.addChild( null, D_ENUM, null, null, _EnumBaseType, _ln );

							// Since Enum Body is spacial.......
							parseToken( TOK.Topencurly );

							if( parseEnumMembers( true, _EnumBaseType ) )
							{
								if( token().tok == TOK.Tclosecurly )
								{
									parseToken( TOK.Tclosecurly );
									if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather();
									return true;
								}
							}
						}
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		bool parseEnumMembers( bool bAnonymous, char[] _EnumBaseType )
		{
			char[]	_name, _type;
			
			try
			{
				if( bAnonymous )
				{
					if( next().tok != TOK.Tassign && next().tok != TOK.Tcomma && next().tok != TOK.Tclosecurly )
					{
						// Type Identifier = AssignExpression
						_type = getType();
					}
				}
				
				if( token().tok == TOK.Tidentifier )
				{
					_name = token().identifier;
					int		_ln =  token().lineNumber;
					
					parseToken( TOK.Tidentifier );
					
					if( token().tok == TOK.Tassign )
					{
						while( token().tok != TOK.Tcomma && token().tok != TOK.Tclosecurly )
							parseToken();
					}

					activeASTnode.addChild( _name, D_ENUMMEMBER, null, _type.length ? _type : _EnumBaseType, null, _ln );

					if( token().tok == TOK.Tcomma )
					{
						parseToken( TOK.Tcomma );
						parseEnumMembers( bAnonymous, _EnumBaseType );
					}

					return true;
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}








		/***************************************************************************TEMPLATES***************************************************************************/
		/*
		TemplateDeclaration:
			template Identifier TemplateParameters Constraint<opt> { DeclDefs<opt> }

		TemplateParameters:
			( TemplateParameterList<opt> )

		TemplateParameterList:
			TemplateParameter
			TemplateParameter ,
			TemplateParameter , TemplateParameterList

		TemplateParameter:
			TemplateTypeParameter
			TemplateValueParameter
			TemplateAliasParameter
			TemplateSequenceParameter
			TemplateThisParameter
		*/
		bool parseTemplate()
		{
			try
			{
				if( token().tok == TOK.Ttemplate )
				{
					parseToken( TOK.Ttemplate );

					if( token().tok == TOK.Tidentifier )
					{
						char[]	_params, _name = token().identifier;
						int		_ln =  token().lineNumber;
						
						parseToken( TOK.Tidentifier );

						if( token().tok == TOK.Topenparen )
						{
							_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );

							if( token().tok == TOK.Tif ) parseConstraint();

							if( token().tok == TOK.Topencurly )
							{
								activeASTnode = activeASTnode.addChild( _name, D_TEMPLATE, null, _params, null, _ln );
								curlyStack.push( "TEMPLATE" );
								return true;
							}
						}
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		/*
		TemplateInstance:
			Identifier TemplateArguments

		TemplateArguments:
			! ( TemplateArgumentList<opt> )
			! TemplateSingleArgument

		TemplateArgumentList:
			TemplateArgument
			TemplateArgument ,
			TemplateArgument , TemplateArgumentList

		TemplateArgument:
			Type
			AssignExpression
			Symbol

		Symbol:
			SymbolTail
			. SymbolTail

		SymbolTail:
			Identifier
			Identifier . SymbolTail
			TemplateInstance
			TemplateInstance . SymbolTail

		TemplateSingleArgument:
			Identifier
			BasicTypeX
			CharacterLiteral
			StringLiteral
			IntegerLiteral
			FloatLiteral
			true
			false
			null
			this
			SpecialKeyword	
		*/
		char[] getTemplateInstance()
		{
			char[] _Instance;
			
			try
			{
				if( token().tok == TOK.Tidentifier && next().tok == TOK.Tnot ) // !
				{
					_Instance = token().identifier;
					parseToken();
					_Instance ~= "!";
					parseToken( TOK.Tnot );

					if( token.tok == TOK.Topenparen )
					{
						_Instance ~= getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );

						if( token().tok == TOK.Tdot && next().tok == TOK.Tidentifier )
						{
							_Instance ~= ".";
							parseToken( TOK.Tdot );
							_Instance ~= getIdentifierList();
						}
					}
					else // TemplateSingleArgument
					{
						switch( token().tok )
						{
							case TOK.Tbool, TOK.Tbyte, TOK.Tubyte, TOK.Tshort, TOK.Tushort, TOK.Tint, TOK.Tuint, TOK.Tlong, TOK.Tulong,
								TOK.Tchar, TOK.Tdchar, TOK.Twchar,
								TOK.Tfloat, TOK.Tdouble, TOK.Treal, TOK.Tifloat, TOK.Tidouble, TOK.Tireal, TOK.Tcfloat, TOK.Tcdouble, TOK.Tcreal,
								TOK.Tvoid:

							case TOK.Tstrings, TOK.Tnumbers:
							case TOK.Ttrue, TOK.Tfalse:
							case TOK.Tnull, TOK.Tthis:
							case TOK.T__FILE__, TOK.T__FILE_FULL_PATH__, TOK.T__MODULE__, TOK.T__LINE__, TOK.T__FUNCTION__, TOK.T__PRETTY_FUNCTION__: // SpecialKeyword

							case TOK.Tidentifier:
								_Instance ~= getIdentifierList();
								break;

							default:
						}
					}	
				}
			}
			catch( Exception e )
			{
				throw e;
			}			

			return _Instance;
		}

		/*
		ClassTemplateDeclaration:
			class Identifier TemplateParameters Constraint<opt> BaseClassList<opt> AggregateBody
			class Identifier TemplateParameters BaseClassList<opt> Constraint<opt> AggregateBody

		InterfaceTemplateDeclaration:
			interface Identifier TemplateParameters Constraint<opt> BaseInterfaceList<opt> AggregateBody
			interface Identifier TemplateParameters BaseInterfaceList Constraint AggregateBody

		StructTemplateDeclaration:
			struct Identifier TemplateParameters Constraint<opt> AggregateBody

		UnionTemplateDeclaration:
			union Identifier TemplateParameters Constraint<opt> AggregateBody
		*/
		bool parseAggregateTemplates( int D_KIND, char[] _name, inout char[] _baseName )
		{
			char[]	templateParam;
			int		_ln = token().lineNumber;

			try
			{
				// ClassTemplateDeclaration:
				if( token().tok == TOK.Topenparen )
				{
					templateParam = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );

					if( D_KIND == D_CLASS || D_KIND == D_INTERFACE )
					{
						if( token().tok == TOK.Tif )
						{
							parseConstraint();
							if( token().tok == TOK.Tcolon )
							{
								parseToken( TOK.Tcolon );
								
								// Not in Language Reference
								if( isVisibilityAttribute() ) parseToken();
								
								_baseName = getBasicType();
								if( token().tok == TOK.Tcomma )
								{
									parseToken( TOK.Tcomma );
									_baseName ~= ( "," ~ getBasicType() );
								}
							}					
						}
						else if( token().tok == TOK.Tcolon )
						{
							parseToken( TOK.Tcolon );
							
							// Not in Language Reference
							if( isVisibilityAttribute() ) parseToken();
							
							_baseName = getBasicType();
							if( token().tok == TOK.Tcomma )
							{
								parseToken( TOK.Tcomma );
								_baseName ~= ( "," ~ getBasicType() );
							}

							if( token().tok == TOK.Tif ) parseConstraint();
						}
					}
					else
					{
						if( token().tok == TOK.Tif ) parseConstraint();
					}

					if( token().tok == TOK.Topencurly )
					{
						activeASTnode = activeASTnode.addChild( _name, D_TEMPLATE, null, null, _baseName, _ln );
						curlyStack.push( "Aggregate Templates" );
						
						return true;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}
			
			return false;
		}

		bool parseConstraint()
		{
			try
			{
				if( token().tok == TOK.Tif )
				{
					if( next().tok == TOK.Topenparen )
					{
						parseToken( TOK.Tif );
						getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );

						return true;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}			

			return false;
		}








		/***************************************************************************ALIAS***************************************************************************/	
		/*
		AliasDeclaration:
			alias StorageClasses<opt> BasicType Declarators ;
			alias StorageClasses<opt> BasicType FuncDeclarator ;
			alias AliasDeclarationX ;

		AliasDeclarationX:
			AliasDeclarationY
			AliasDeclarationX , AliasDeclarationY

		AliasDeclarationY:
			Identifier TemplateParameters<opt> = StorageClasses<opt> Type
			Identifier TemplateParameters<opt> = FunctionLiteral


		TemplateParameters:
			( TemplateParameterList<opt> )

		FunctionLiteral:
			function Type<opt> ParameterAttributes<opt> FunctionLiteralBody
			delegate Type<opt> ParameterMemberAttributes<opt> FunctionLiteralBody
			ParameterMemberAttributes FunctionLiteralBody
			FunctionLiteralBody
			Lambda

		ParameterAttributes:
			Parameters FunctionAttributesopt

		ParameterMemberAttributes:
			Parameters MemberFunctionAttributesopt

		FunctionLiteralBody:
			BlockStatement
			FunctionContracts<opt> BodyStatement	
		*/
		bool parseAlias()
		{
			char[] _name, _type;
			
			try
			{
				if( token().tok == TOK.Talias )
				{
					parseToken( TOK.Talias );

					if( ( token().tok == TOK.Tidentifier && next().tok == TOK.Tassign ) || ( token().tok == TOK.Tidentifier && next().tok == TOK.Topenparen )  )
					{
						return parseAliasDeclarationY();
					}
					else
					{
						parseStorageClass();
						_type = getType();

						if( token.tok == TOK.Tidentifier )
						{
							if( parseVariable( _type ) )
							{
								auto _node = activeASTnode.getChild( activeASTnode.getChildrenCount - 1 );
								_node.kind = D_ALIAS;
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
			}
			catch( Exception e )
			{
				throw e;
			}			

			return false;
		}

		bool parseAliasDeclarationY()
		{
			try
			{
				if( token().tok == TOK.Tidentifier )
				{
					char[]	_type, _name = token().identifier;
					int		_ln = token().lineNumber;

					parseToken( TOK.Tidentifier );
					
					if( token().tok == TOK.Topenparen ) _name ~= getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
					if( token().tok == TOK.Tassign )
					{
						parseToken( TOK.Tassign );

						switch( token().tok )
						{
							case TOK.Tdelegate, TOK.Tfunction:
							case TOK.Topencurly: // BlockStatement
							case TOK.Tin, TOK.Tout, TOK.Tbody: // FunctionContracts
							case TOK.Topenparen:
								// TODO.....
								break;

							default:
								parseStorageClass();
								_type = getType();
						}

						activeASTnode.addChild( _name, D_ALIAS, getProt(), _type, null, _ln );

						if( token().tok == TOK.Tcomma )
						{
							parseToken( TOK.Tcomma );
							return parseAliasDeclarationY();
						}
						else if( token().tok == TOK.Tsemicolon )
						{
							return true;
						}
					}
					else
					{
						return false;
					}
				}
			}
			catch( Exception e )
			{
				throw e;
			}			

			return false;
		}








		/***************************************************************************Conditional Compilation***************************************************************************/	
		/*
		ConditionalDeclaration:
			Condition DeclarationBlock
			Condition DeclarationBlock else DeclarationBlock
			Condition : DeclDefs<opt>
			Condition DeclarationBlock else : DeclDefsopt

		ConditionalStatement:
			Condition NoScopeNonEmptyStatement
			Condition NoScopeNonEmptyStatement else NoScopeNonEmptyStatement
		*/

		/*
		Condition:
			VersionCondition
			DebugCondition
			StaticIfCondition
		*/
		bool parseCondition()
		{
			char[]	_name;
			int		_ln = token().lineNumber;

			int		D_KIND;
			
			try
			{
				if( token().tok == TOK.Tversion )
					D_KIND = D_VERSION;
				else if( token().tok == TOK.Tdebug )
					D_KIND = D_DEBUG;
				else if( token().tok == TOK.Tstatic && next().tok == TOK.Tif )
					D_KIND = D_STATICIF;
				else
					return false;

				
				
				switch( token().tok )
				{
					case TOK.Tversion, TOK.Tdebug:
						parseToken();

						if( token().tok == TOK.Topenparen )
						{
							_name = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
							if( _name.length > 2 ) _name = _name[1..$-1];
							activeASTnode = activeASTnode.addChild( _name, D_KIND, getProt(), null, null, _ln );

							if( token().tok != TOK.Topencurly )
							{
								parseStack.push( "version" );
								parse( null ); //getTokenIdentifierUntil( TOK.Tsemicolon );
								activeASTnode.endLineNum = prev().lineNumber; // prev().tok = TOK.Tcomma
								if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather();

								if( token().tok == TOK.Telse )
								{
									_ln = token().lineNumber;
									parseToken( TOK.Telse );

									if( token().tok != TOK.Tversion && token().tok != TOK.Tdebug )
									{
										activeASTnode = activeASTnode.addChild( "-else-", D_KIND, getProt(), null, _name, _ln );
										
										if( token().tok != TOK.Topencurly )
										{
											switch( D_KIND )
											{
												case D_VERSION:		parseStack.push( "version else" ); break;
												case D_DEBUG:		parseStack.push( "debug else" ); break;
												case D_STATICIF:	parseStack.push( "staticif else" ); break;
												default:
											}									
											parse( null );//getTokenIdentifierUntil( TOK.Tsemicolon );
											activeASTnode.endLineNum = prev().lineNumber; // prev().tok = TOK.Tcomma
											if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather();
										}
										else
										{
											switch( D_KIND )
											{
												case D_VERSION:		curlyStack.push( "version else" ); break;
												case D_DEBUG:		curlyStack.push( "debug else" ); break;
												case D_STATICIF:	curlyStack.push( "staticif else" ); break;
												default:			return false;
											}
										}
									}
									else
									{
										//parseCondition();
									}
								}
							}
							else
							{
								switch( D_KIND )
								{
									case D_VERSION:		curlyStack.push( "version" ); break;
									case D_DEBUG:		curlyStack.push( "debug" ); break;
									case D_STATICIF:	curlyStack.push( "staticif" ); break;
									default:			return false;
								}
							}
						}
						else if( token().tok == TOK.Tassign )
						{
							parseToken( TOK.Tassign );
							char[] _type = getTokenIdentifierUntil( TOK.Tsemicolon );
							activeASTnode.addChild( _type, D_KIND, getProt(), _type, null, _ln );
						}
						else
						{
							return false;
						}
						break;
					
					default:
						return false;
				}
			}
			catch( Exception e )
			{
				throw e;
			}			

			return true;
		}
	}


	public:
	this()
	{
		version(DIDE)
		{
			curlyStack	= new CStack!(char[]);
			protStack	= new CStack!(char[]);
			parseStack	= new CStack!(char[]);
		}
	}
	
	this( TokenUnit[] _tokens )
	{
		updateTokens( _tokens );
	}

	bool updateTokens( TokenUnit[] _tokens )
	{
		tokenIndex = 0;
		delete tokens;
		tokens.length = 0;
		tokens = _tokens;
		
		head = null;
		
		version(DIDE)
		{
			delete curlyStack;
			delete protStack;
			delete parseStack;
			
			curlyStack	= new CStack!(char[]);
			protStack	= new CStack!(char[]);
			parseStack	= new CStack!(char[]);
		}
		
		if( !_tokens.length ) return false;
		
		return true;
	}
	
	version(FBIDE)
	{
		CASTnode parse( char[] fullPath, int B_KIND = 0 )
		{
			try
			{
				scope f = new FilePath( fullPath );
				
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
							
						case TOK.Twith:
							parseWith();
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

						case TOK.Tassign:
							parseToken( TOK.Tassign );

							break;

						case TOK.Tendmacro:
							if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );

						default:
							tokenIndex ++;
							//Stdout( tokenIndex );
							//Stdout( "   " ~ token().identifier ).newline;
					}
				}
			}
			catch( Exception e )
			{
				debug GLOBAL.IDEMessageDlg.print( e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			}

			if( activeASTnode !is head ) head.endLineNum = 2147483646; else head.endLineNum = 2147483647;
			//printAST( head );

			return head;
		}
	}
	
	version(DIDE)
	{
		CASTnode parse( char[] fullPath, bool bSkipFlag = false )
		{
			try
			{
				if( fullPath.length )
				{
					head = new CASTnode( fullPath, D_MODULE, null, fullPath, null, 0, 2147483647 );

					activeASTnode = head;
				}

				while( tokenIndex < tokens.length )
				{
					switch( tokens[tokenIndex].tok )
					{
						case TOK.Tmodule:
							parseModule();
							break;

						case TOK.Timport:
							parseImport();
							break;

						case TOK.Tprivate:
							parseToken( TOK.Tprivate );

							activeProt = "private";
							if( token().tok == TOK.Tcolon )
							{
								char[] protValue = protStack.top();
								if( protValue.length )
									if( protValue[$-1] == ':' ) protStack.pop();

								protStack.push( "private:" );
							}
							
							break;

						case TOK.Tpublic:
							parseToken( TOK.Tpublic );

							activeProt = "public";
							if( token().tok == TOK.Tcolon )
							{
								char[] protValue = protStack.top();
								if( protValue.length )
									if( protValue[$-1] == ':' ) protStack.pop();

								protStack.push( "public:" );
							}
							
							break;

						case TOK.Tprotected:
							parseToken( TOK.Tprotected );

							activeProt = "protected";
							if( token().tok == TOK.Tcolon )
							{
								char[] protValue = protStack.top();
								if( protValue.length )
									if( protValue[$-1] == ':' ) protStack.pop();
								
								protStack.push( "protected:" );
							}
							
							break;

						// Basic Type
						case TOK.Tbool, TOK.Tbyte, TOK.Tubyte, TOK.Tshort, TOK.Tushort, TOK.Tint, TOK.Tuint, TOK.Tlong, TOK.Tulong,
							TOK.Tchar, TOK.Tdchar, TOK.Twchar,
							TOK.Tfloat, TOK.Tdouble, TOK.Treal, TOK.Tifloat, TOK.Tidouble, TOK.Tireal, TOK.Tcfloat, TOK.Tcdouble, TOK.Tcreal,
							TOK.Tvoid:
							switch( next().tok )
							{
								case TOK.Tidentifier, TOK.Topenbracket, TOK.Ttimes, TOK.Tdelegate, TOK.Tfunction:
									parseType();
									break;
								default:
									parseToken();
							}
							break;
							
						case TOK.Tidentifier:
							switch( next().tok )
							{
								case TOK.Tidentifier, TOK.Tnot, TOK.Topenbracket, TOK.Tdot, TOK.Ttimes, TOK.Tdelegate, TOK.Tfunction:
									if( !bAssignExpress ) parseType(); else parseToken();
									//if( prev().tok == TOK.Tsemicolon || prev().tok == TOK.Topencurly || prev().tok == TOK.Tclosecurly || isStorageClass( prev().tok ) ) parseType(); else parseToken( TOK.Tidentifier );
									break;

								default:
									parseToken( TOK.Tidentifier );
								
							}
							break;

						/+
						case TOK.Tauto, TOK.Tscope:
							parseAutoType();
							break;

						case TOK.Tconst, TOK.Timmutable, TOK.Tinout, TOK.Tshared:
							if( next().tok == TOK.Topenparen ) parseType(); else parseToken();
							break;
						+/

						case TOK.Talias:
							parseAlias();
							break;

						case TOK.Tversion, TOK.Tdebug:
							if( !parseCondition() ) parseToken();
							break;

						/*
						case TOK.Tstatic:
							if( next().tok == TOK.Tif )	parseCondition(); else parseToken( TOK.Tstatic );
							break;
						*/

						case TOK.Tclass, TOK.Tinterface:
							parseClass_Interface();
							break;

						case TOK.Tstruct, TOK.Tunion:
							parseStruct_Union();
							break;

						/+
						case TOK.Tenum:
							parseEnum();
							break;
						+/

						case TOK.Ttemplate:
							parseTemplate();
							break;

						// Speed UP!!!!!!!
						case TOK.Tif, TOK.Twhile, TOK.Tswitch:
							parseToken();
							// Speed UP
							if( token().tok == TOK.Topenparen ) getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
							break;

						case TOK.Tassign, TOK.Tless, TOK.Tgreater:
							parseToken( TOK.Tassign );
							bAssignExpress = true;
							break;

						case TOK.Topenparen:
							if( bAssignExpress ) getDelimitedString( TOK.Topenparen, TOK.Tcloseparen ); else parseToken( TOK.Topenparen );
							break;

						// End of Speed UP

						case TOK.Ttilde:
							if( next().tok == TOK.Tthis )
							{
								if( next2().tok == TOK.Topenparen )	parseDestructor();else parseToken( TOK.Ttilde );
							}
							else
							{
								parseToken( TOK.Ttilde );
							}
							break;
						
						case TOK.Tthis:
							if( next().tok == TOK.Topenparen ) parseConstructor();else parseToken( TOK.Tthis );
							break;

						case TOK.Tinvariant:
							if( next().tok == TOK.Topencurly )
							{
								parseToken( TOK.Tinvariant );
								curlyStack.push( "invariant" );
								parseToken( TOK.Topencurly );
							}
							else
							{
								parseToken( TOK.Tinvariant );
							}
							break;

						case TOK.Tout:
							if( next().tok == TOK.Topenparen )
							{
								if( next2().tok == TOK.Tidentifier )
								{
									parseToken( TOK.Tout );
									parseToken( TOK.Topenparen );
									parseToken( TOK.Tidentifier );

									if( token().tok == TOK.Tcloseparen && next().tok == TOK.Topencurly )
									{
										parseToken( TOK.Tcloseparen );
										parseToken( TOK.Topencurly );
										curlyStack.push( "out" );
										break;
									}
								}
								parseToken();
								break;
							}

						case TOK.Tin, TOK.Tbody:
							if( next().tok == TOK.Topencurly )
							{
								curlyStack.push( token().identifier );
								parseToken();
								//parseToken( TOK.Topencurly );
								break;
							}

							parseToken();
							break;

						case TOK.Tcatch:
							parseToken( TOK.Tcatch );
							if( token().tok == TOK.Topenparen ) getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
							break;

						case TOK.Tunittest:
							if( next().tok == TOK.Topencurly )
							{
								if( GLOBAL.toggleSkipUnittest == "ON" || bSkipFlag == true )
								{
									parseToken( TOK.Tunittest );
									getDelimitedString( TOK.Topencurly, TOK.Tclosecurly );
									break;
								}
								activeASTnode = activeASTnode.addChild( null, D_UNITTEST, null, null, null, token().lineNumber );
								curlyStack.push( "unittest" );
							}
							parseToken( TOK.Tunittest );
							break;

						case TOK.Topencurly:
							curlyStack.push( "{" );

							activeProt = "";
							if( prev().tok == TOK.Tprivate || prev().tok == TOK.Tprotected || prev().tok == TOK.Tpublic ) protStack.push( prev().identifier ~ "{" ); else protStack.push( "{" ); 
							//if( activeProt.length ) protStack.push( activeProt ~ "{" ); else protStack.push( "{" ); 
							
							parseToken( TOK.Topencurly );
							break;

						case TOK.Tclosecurly:

							switch( curlyStack.top() )
							{
								/+
								case "invariant", "in", "out", "body":
									curlyStack.pop();
									break;
	+/
								default:
									bool	bSkipParseToken;
									
									if( curlyStack.top() == "{" )
									{
										curlyStack.pop();

										int		D_KIND = -1;
										switch( curlyStack.top() )
										{
											case "{":
												break;

											case "debug":
												if( D_KIND < 0 ) D_KIND = D_DEBUG;

											case "staticif":
												if( D_KIND < 0 ) D_KIND = D_STATICIF;
												
											case "version":
												if( D_KIND < 0 ) D_KIND = D_VERSION;
												
												curlyStack.pop();

												char[] _name;
												if( activeASTnode.getFather !is null )
												{
													activeASTnode.endLineNum = token().lineNumber;
													_name = activeASTnode.name;
													if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather();
												}

												if( next().tok == TOK.Telse )
												{
													parseToken( TOK.Tclosecurly );

													int _ln = token().lineNumber;
													
													parseToken( TOK.Telse );

													if( token().tok != TOK.Tversion && token().tok != TOK.Tdebug )
													{
														activeASTnode = activeASTnode.addChild( "-else-", D_KIND, getProt(), null, _name, _ln );
														
														if( token().tok != TOK.Topencurly )
														{
															switch( D_KIND )
															{
																case D_VERSION:		parseStack.push( "version else" ); break;
																case D_DEBUG:		parseStack.push( "debug else" ); break;
																case D_STATICIF:	parseStack.push( "staticif else" ); break;
																default:
															}
															parse( null );//getTokenIdentifierUntil( TOK.Tsemicolon );
															activeASTnode.endLineNum = prev().lineNumber; // prev().tok = TOK.Tcomma
															if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather();
														}
														else
														{
															switch( D_KIND )
															{
																case D_VERSION:		curlyStack.push( "version else" ); break;
																case D_DEBUG:		curlyStack.push( "debug else" ); break;
																case D_STATICIF:	curlyStack.push( "staticif else" ); break;
																default:
															}
														}									
														bSkipParseToken = true;
													}
													else
													{
														bSkipParseToken = true;
													}
												}
												break;
												
											case "in", "out":
												curlyStack.pop();
												break;

											default:
												curlyStack.pop();
												if( activeASTnode.getFather !is null )
												{
													activeASTnode.endLineNum = token().lineNumber;
													if( activeASTnode.getFather !is null ) activeASTnode = activeASTnode.getFather();
												}
										}
										/+
										if( curlyStack.top() != "{" )
										{
											curlyStack.pop();
											if( activeASTnode.getFather !is null )
											{
												activeASTnode.endLineNum = token().lineNumber;
												activeASTnode = activeASTnode.getFather();
											}
										}
										+/
										if( curlyStack.top() == "Aggregate Templates" )
										{
											curlyStack.pop();
											if( activeASTnode.getFather !is null )
											{
												activeASTnode.endLineNum = token().lineNumber;
												activeASTnode = activeASTnode.getFather();
											}
										}
									}
									
									if( !bSkipParseToken ) parseToken( TOK.Tclosecurly );
							}

							switch( protStack.top() )
							{
								case "puclic{", "private{", "protected{":
									protStack.pop();
									break;

								case "puclic:", "private:", "protected:":
									protStack.pop();
									
								default:
									protStack.pop();
							}
							break;

						case TOK.Tsemicolon:
							parseToken( TOK.Tsemicolon );
							bAssignExpress = false;
							activeProt = "";
							if( parseStack.top().length )
							{
								parseStack.pop();
								return null;
							}
							break;

						default:
							if( isStorageClass() )
							{
								if( token().tok == TOK.Tenum )
								{
									if( next().tok == TOK.Topencurly || ( next().tok == TOK.Tidentifier && next2().tok == TOK.Topencurly ) || ( next().tok == TOK.Tidentifier && next2().tok == TOK.Tcolon ) ) 
									{
										parseEnum();
										break;
									}
								}


								while( isStorageClass( tokenIndex + 1 ) )
									parseToken();
									
								
								if( token().tok == TOK.Tconst || token().tok == TOK.Timmutable || token().tok == TOK.Tinout || token().tok == TOK.Tshared )
								{
									if( next().tok == TOK.Topenparen )
									{
										parseType();
										break;
									}
								}

								if( token().tok == TOK.Textern || token().tok == TOK.Talign )
								{
									if( next().tok == TOK.Topenparen )
									{
										parseToken();
										getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
									}
									else
									{
										parseToken();
									}
								}
								else
								{
									parseToken();
								}

								// Is Attributes
								if( token().tok == TOK.Tcolon )
								{
									parseToken( TOK.Tcolon );
									break;
								}

								// Identifier TemplateParameter<sopt> = Initializer
								if( token().tok == TOK.Tidentifier )
								{
									if( next().tok == TOK.Tassign )
									{
										parseAutoDeclaration();
										break;
									}
									else if( next().tok == TOK.Topenparen )
									{
										int funTailIndex = getFunctionDeclareTailIndex( tokenIndex + 1 );
										if( tokens[funTailIndex].tok == TOK.Tassign )
										{
											parseAutoDeclaration();
											break;
										}
									}
								}

								break;
							}

							tokenIndex ++;
					}
				}
			}
			catch( Exception e )
			{
				debug GLOBAL.IDEMessageDlg.print( e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			}

			if( activeASTnode !is head ) head.endLineNum = 2147483646; else head.endLineNum = 2147483647;
			//printAST( head );

			return head;
		}
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
}