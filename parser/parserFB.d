module parser.parserFB;

version(FBIDE)
{
	import parser._parser;
	
	class CParser : _PARSER
	{
		private:
		
		// Parse the continuous identifiers, include any words until the EOL / :
		char[] parseIdentifier()
		{
			char[] ident;
			
			while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
			{
				ident ~= token().identifier;
				parseToken();
			}
			
			return ident;
		}
		

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
							parseToken( TOK.Tstrings );

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
									parseToken();
								}
								else if( token().tok == TOK.Tstrings  )
								{
									activeASTnode.addChild( name, B_VARIABLE | B_DEFINE, null, "string", null, lineNumber );	
									parseToken();
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
									parseToken();
								}
								else if( token().tok == TOK.Tidentifier )
								{
									activeASTnode.addChild( name, B_ALIAS | B_DEFINE, null, null, null, lineNumber );
									parseToken();
								}
							}
						}
						break;

					case TOK.Tifdef:
						parseToken( TOK.Tifdef );

						_type = upperCase( token().identifier );
						parseToken();
						break;

					case TOK.Telseif, TOK.Telse:
						parseToken();

						if( _type.length )
						{
							if( _type[0] == '!' )
							{
								_type = upperCase( _type[1..$] );
							}
							else
							{
								_type = upperCase( "!" ~ _type );
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
										if( tokenIndex >= tokens.length - 1 ) break;
										
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
										
										parseToken();
									}
									while( token().tok != TOK.Teol );
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
					if( _param[$-1] == ' ' ) _param = _param[0..$-1];
					_param ~= ")";
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parseParam" ).newline;
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
					while( tokenIndex < tokens.length );
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

					if( token().tok == TOK.Tredim && next().tok == TOK.Tpreserve ) parseToken( TOK.Tredim );

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
										if( tokenIndex >= tokens.length - 1 ) break;
										
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
										parseToken();
										
										if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
										{
											if( bSingle ) activeASTnode.addChild( _name, B_VARIABLE, null, "single", null, _lineNum ); else activeASTnode.addChild( _name, B_VARIABLE, null, "integer", null, _lineNum );
											parseToken( );
											return true;
										}
										else
										{
											return false;
										}
									}
									else if( token().tok == TOK.Tstrings )
									{
										parseToken( TOK.Tstrings );
										if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
										{
											activeASTnode.addChild( _name, B_VARIABLE, null, "string", null, _lineNum );
											parseToken( );
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
								
								
								if( parseFunctionPointer( _name, _lineNum ) )
								{
									if( token.tok != TOK.Tcomma ) break; else parseToken( TOK.Tcomma );
									continue;
								}

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
				char[]	_name, _type, _rightExpress;
				int 	_lineNum = token().lineNumber;
				
				parseToken( TOK.Tvar );

				if( token().tok == TOK.Tshared ) parseToken( TOK.Tshared );
				
				if( token().tok == TOK.Tidentifier && next().tok == TOK.Tassign )
				{
					_name = token().identifier;
					parseToken( TOK.Tidentifier );
					parseToken( TOK.Tassign );
					
					if( token().tok == TOK.Tnew )
					{
						parseToken( TOK.Tnew );
						while( token().tok != TOK.Teol && token().tok != TOK.Tcolon && token().tok != TOK.Topenparen )
						{
							_type ~= token().identifier;
							parseToken();
						}
					}
					else if( token().tok == TOK.Tcast )
					{
						parseToken( TOK.Tcast );
						
						if( token().tok == TOK.Topenparen )
						{
							parseToken( TOK.Topenparen );
							while( token().tok != TOK.Tcomma && token().tok != TOK.Teol && token().tok != TOK.Tcolon )
							{
								if( token().tok == TOK.Tptr || token().tok == TOK.Tpointer )
									_type ~= "*";
								else
									_type ~= token().identifier;
									
								parseToken();
							}
						}
					}
					else if( token().tok == TOK.Tstrings )
					{
						_type = "string";
						parseToken( TOK.Tstrings );
					}
					else if( token().tok == TOK.Tnumbers )
					{
						if( Util.count( token().identifier, "." ) > 0 ) _type = "double"; else _type = "integer";
						parseToken( TOK.Tnumbers );
					}
					
					while( token().tok != TOK.Teol && token().tok != TOK.Tcolon )
					{
						_rightExpress ~= token().identifier;
						parseToken();
					}
					
					int indexOpenparen = Util.index( _rightExpress, "(" );
					if( indexOpenparen < _rightExpress.length ) _rightExpress = _rightExpress[0..indexOpenparen];
					
					activeASTnode.addChild( _name, B_VARIABLE, null, _type, _rightExpress, _lineNum );
				}
				else
				{
					return  false;
				}
			}
			catch( Exception e )
			{
				throw e;
				//debug Stdout( e.toString ~ "  ::  parserVar" ).newline;
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
					char[][] _names = Util.split( parseIdentifier(), "." );
					for( int i = 0; i < _names.length; ++ i )
						activeASTnode = activeASTnode.addChild( _names[i], B_NAMESPACE, null, Integer.toString( i ), null, token().lineNumber );
					
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

		bool parseUsing()
		{
			try
			{
				parseToken( TOK.Tusing );
				
				char[] _name;
				while( token().tok == TOK.Tidentifier )
				{
					int _lineNum	= token().lineNumber;
					
					_name ~= token().identifier;

					parseToken( TOK.Tidentifier );

					if( token().tok == TOK.Tdot )
					{
						_name ~= ".";
						parseToken( TOK.Tdot );
					}
					else if( token().tok == TOK.Tcomma )
					{
						// .type = activeASTnode.name(name of Mother Scope), .endLineNum = activeASTnode.lineNumber
						activeASTnode.addChild( _name, B_USING, null, null, null, _lineNum );
						parseToken( TOK.Tcomma );
						_name = "";
					}
					else if( token().tok == TOK.Teol || token().tok == TOK.Tcolon )
					{
						activeASTnode.addChild( _name, B_USING, null, null, null, _lineNum );
						parseToken();
						break;
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
				//debug Stdout( e.toString ~ "  ::  parseUsing" ).newline;
			}

			return true;
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
						}

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
				
				/*
				Think below.....
				#define RAYGUIDEF Declare
				....
				RAYGUIDEF sub GuiEnable()
				*/
				if( tokenIndex > 0 )
					if( prev().tok == TOK.Tidentifier && !bDeclare ) bDeclare = true;
					
				if( token().tok == B_OPERATOR ) return parseOperator( bDeclare, _protection );
				
				
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
						
						if( _kind & ( B_FUNCTION | B_SUB ) )
						{	
							if( token().tok == TOK.Tnaked ) parseToken();
						
							if( token().tok == TOK.Tstdcall || token().tok == TOK.Tcdecl || token().tok == TOK.Tpascal ) 
								parseToken();
							else if( token().tok == TOK.Tidentifier ) // like " Declare Function app_oninit_cb WXCALL () As wxBool "
								parseToken( TOK.Tidentifier );
						}

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
						
						// Constructor (Module) 
						if( _kind == B_SUB )
						{
							if( token().tok == TOK.Tconstructor )
							{
								activeASTnode.base = "ctor";
								parseToken( TOK.Tconstructor );
							}
							else if( token().tok == TOK.Tdestructor )
							{
								activeASTnode.base = "dtor";
								parseToken( TOK.Tdestructor );
							}
						}

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
											if( tokenIndex >= tokens.length - 1 ) break;
											
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
							}
							else
							{
								parseToken();
							}
							
							break;

						case TOK.Tstatic:
							parseToken( TOK.Tstatic );
							break;
							
						case TOK.Tconst:
							parseToken( TOK.Tconst );
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
							parseToken();
							//tokenIndex ++;
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
							
						case TOK.Tpound:
							parsePreprocessor();
							break;

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
										if( token().tok == TOK.Tstrings || token().tok == TOK.Tidentifier || token().tok == TOK.Tnumbers ) parseToken();else return false;
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
				if( tokenIndex > 0 )
				{
					if( prev().tok == TOK.Tdot || prev().tok == TOK.Tptraccess )
					{
						parseToken();
						return false;
					}
				}
			
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
							if( token().tok == TOK.Tidentifier || token().tok == TOK.Tobject ) _base = parseIdentifier();
							/*
							_base = token().identifier;
							parseToken( TOK.Tidentifier );
							*/
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
						while( token().tok != TOK.Teol && token().tok != TOK.Tcolon && token().tok != TOK.Tcomma )
						{
							parseToken();
						}

						if( token().tok == TOK.Tcomma || token().tok == TOK.Teol || token().tok == TOK.Tcolon )
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
			}

			return true;
		}
		
		bool parseWith()
		{
			try
			{
				parseToken( TOK.Twith );
				
				char[] user_defined_var;
				do
				{
					user_defined_var ~= token().identifier;
					parseToken();
				}
				while( token().tok != TOK.Teol && token().tok != TOK.Tcolon );
				
				activeASTnode = activeASTnode.addChild( user_defined_var, B_WITH, null, null, null, token().lineNumber );
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
					case TOK.Tsub, TOK.Tfunction, TOK.Tproperty, TOK.Toperator, TOK.Tconstructor, TOK.Tdestructor, TOK.Ttype, TOK.Tenum, TOK.Tunion, TOK.Tscope, TOK.Twith, TOK.Tclass:
						if( activeASTnode.getFather() !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );
						parseToken();

						break;

					case TOK.Tnamespace:
						if( activeASTnode.kind & B_NAMESPACE )
						{	
							int loopUpperLimit = Integer.toInt( activeASTnode.type ) + 1;
							for( int i = 0; i < loopUpperLimit; ++ i )
								if( activeASTnode.getFather() !is null ) activeASTnode = activeASTnode.getFather( token().lineNumber );
						}
						parseToken();
					
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



		public:
		this(){}
		
		this( TokenUnit[] _tokens )
		{
			updateTokens( _tokens );
		}

		CASTnode parse( char[] fullPath )
		{
			CASTnode head = null;
			
			try
			{
				scope f = new FilePath( fullPath );
				
				char[]		_ext;
				if( lowerCase( f.ext() ) == "bas" ) 
				{
					head = new CASTnode( fullPath, B_BAS, null, null, null, 0, 2147483647 );
				}
				else
				{
					head = new CASTnode( fullPath, B_BI, null, null, null, 0, 2147483647 );
				}

				activeASTnode = head;
				
				int	prevTokenIndex;
				int	repeatCount;

				while( tokenIndex < tokens.length )
				{
					if( tokenIndex == prevTokenIndex )
					{
						if( ++repeatCount > 10 ) 
						{
							IupMessageError( GLOBAL.mainDlg, "Infinite Loop of parse() function" );
							break;
						}
					}
					else
					{
						prevTokenIndex = tokenIndex;
						repeatCount = 0;
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
							
						case TOK.Tsub:
							if( next().tok == TOK.Tidentifier && next2().tok == TOK.Tcomma )
							{
								// ASM Command
								parseToken( TOK.Tsub );
								break;
							}
							
						case TOK.Tfunction, /*TOK.Tsub,*/ TOK.Tproperty, TOK.Tconstructor, TOK.Tdestructor:
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
							
						case TOK.Tusing:
							if( next().tok != TOK.Tstrings && next().tok == TOK.Tidentifier ) parseUsing();
							break;
							
							
						case TOK.Tdeclare:
							parseToken( TOK.Tdeclare );
							
							if( activeASTnode.kind & ( B_TYPE | B_CLASS ) )
							{
								if( token().tok == TOK.Tstatic )
								{
									parseToken( TOK.Tstatic );
									if( token().tok == TOK.Tvirtual ) parseToken( TOK.Tvirtual );
								}
								else if( token().tok == TOK.Tvirtual )
								{
									parseToken( TOK.Tvirtual );
									if( token().tok == TOK.Tstatic ) parseToken( TOK.Tstatic );
								}
							}
							
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
							parseToken( TOK.Tendmacro );
							break;

						default:
							tokenIndex ++;
					}
				}
			}
			catch( Exception e )
			{
				debug IupMessageError( null, toStringz( "parserFB Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
			}

			if( head !is null )
			{
				if( activeASTnode != head ) head.endLineNum = 2147483646; else head.endLineNum = 2147483647;
			}
			//printAST( head );

			return head;
		}
	}
}