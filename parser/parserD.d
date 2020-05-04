module parser.parserD;

version(DIDE)
{
	import parser._parser;

	class CParser : _PARSER
	{
	private :
		import			tools;
		import			parser.ast, parser.token;
		import			Util = tango.text.Util;
		
		char[]			activeProt;
		bool			bAssignExpress;

		CStack!(char[]) curlyStack;
		CStack!(char[])	protStack;
		CStack!(char[])	conditionStack;
		
		
		int getDelimitedTailIndex( int _tokOpen, int _tokClose, int _startIndex = -1, bool bSemiColonBreak = true )
		{
			int _countDemlimit;
			int _tempTokenIndex = tokenIndex;
			if( _startIndex != -1 ) _tempTokenIndex = _startIndex;
			
			if( _tempTokenIndex >= tokens.length ) throw new Exception( "out of range!" );
		
			try
			{
				do
				{
					if( tokens[_tempTokenIndex].tok == _tokOpen )
						_countDemlimit ++;
					else if( tokens[_tempTokenIndex].tok == _tokClose )
						_countDemlimit --;
					else
					{
						if( bSemiColonBreak )
							if( tokens[_tempTokenIndex].tok == TOK.Tsemicolon )	throw new Exception( "getDelimitedTailIndex Break Error!" );
					}

					_tempTokenIndex ++;
				}
				while( _countDemlimit != 0 && _tempTokenIndex < tokens.length );
			}
			catch( Exception e )
			{
				throw e;
			}

			return _tempTokenIndex;
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
						else if( token().tok == TOK.Tidentifier || token().tok == TOK.Tfunction || token().tok == TOK.Tdelegate )
						{
							_params ~= ( " " ~ token().identifier );
						}
						else
							_params ~= token().identifier;
						
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

		char[] getProt()
		{
			char[] result;
			
			if( !activeProt.length )
			{
				char[] _stackValue = protStack.top();
				
				if( _stackValue.length > 1 )
				{
					if( _stackValue[$-1] == ':' ) return _stackValue[0..$-1]; else return _stackValue;
				}
			}

			return activeProt;
		}
		

		char[] getTokenIdentifierUntil( int[] _tokens ... )
		{
			char[]	_result;
			int		_countParen, _countCurly, _countBracket;

			try
			{
				while( tokenIndex < tokens.length )
				{
					foreach( int _tok; _tokens )
					{
						if( token().tok == _tok )
						{
							if( _countParen <= 0 && _countBracket <= 0 && _countCurly <= 0 ) return _result;
						}
					}
				
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
				while( ( token().tok == TOK.Ttimes || token().tok == TOK.Topenbracket ) && tokenIndex < tokens.length );			

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
						if( next().tok == TOK.Treturn || next().tok == TOK.Tthis || next().tok == TOK.Tsuper )
						{
							parseToken( TOK.Topenparen );
							_type = token().identifier;
							parseToken();
							if( token().tok == TOK.Tcloseparen ) parseToken( TOK.Tcloseparen ); else throw new Exception( "Typeof Parse Error!" );
						}
						else if( next().tok == TOK.Tnumbers )
						{
							parseToken( TOK.Topenparen );
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
		FunctionAttributes:
			FunctionAttribute
			FunctionAttribute FunctionAttributes

		FunctionAttribute:
			nothrow
			pure
			Property		


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
		*/
		bool isMemberFunctionAttribute( int _tempTokenIndex = -1 )
		{
			if( _tempTokenIndex < 0 ) _tempTokenIndex = tokenIndex;
			if( _tempTokenIndex >= tokens.length ) return false;
			
			switch( tokens[_tempTokenIndex].tok )
			{
				case TOK.Tnothrow, TOK.Tpure:
					return true;
				
				case TOK.TatProperty, TOK.TatSafe, TOK.TatTrusted, TOK.TatSystem, TOK.TatDisable, TOK.TatNogc:
					return true;
				
				case TOK.Tconst, TOK.Timmutable, TOK.Tinout, TOK.Treturn, TOK.Tshared:
					return true;
					
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
				while( _countDemlimit != 0 && _tempTokenIndex < tokens.length );

				// Pass MemberFunctionAttribute
				while( isMemberFunctionAttribute( _tempTokenIndex ) )
				{
					_tempTokenIndex ++;
				}
				
				if( _tempTokenIndex >= tokens.length ) throw new Exception( "out of range!" );
				
				// Pass Constraint
				if( tokens[_tempTokenIndex].tok == TOK.Tif )
				{
					if( tokens[_tempTokenIndex+1].tok == TOK.Topenparen )
					{
						_tempTokenIndex ++;
						_tempTokenIndex = getDelimitedTailIndex( TOK.Topenparen, TOK.Tcloseparen, _tempTokenIndex, false );
					}
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
			catch( Exception e )
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
						if( next().tok != TOK.Topenparen ) parseToken(); else break;
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
						else if( token().tok == TOK.Tstrings )
						{
							_type = "char[]";
							parseToken( TOK.Tstrings );
							switch( token().identifier )
							{
								case "c":			_type = "char[]";	parseToken();	break;
								case "w":			_type = "wchar[]";	parseToken();	break;
								case "d":			_type = "dchar[]";	parseToken();	break;
								default:	break;
							}
						}
						else if( token().tok == TOK.Tnumbers )
						{
							if( token().identifier.length )
							{
								char[] tail2;
								if( token().identifier.length > 1 ) tail2 = token().identifier[$-2..$];
								
								if( Util.count( token().identifier, "." ) <= 0 )
								{
									_type = "int";
									switch( token().identifier[$-1] )
									{
										case 'L':			_type = "long";		break;
										case 'U':			_type = "uint";		break;
										case 'f', 'F':		_type = "float";	break;
										case 'i':			_type = "idouble";	break;
										default:	break;
									}
									
									if( tail2 == "UL" ) _type = "ulong";
								}
								else
								{
									_type = "float";
									switch( token().identifier[$-1] )
									{
										case 'f', 'F':		_type = "float";	break;
										case 'L':			_type = "real";		break;
										case 'i':			_type = "idouble";	break;
										default:			break;
									}
									
									if( token().identifier.length > 1 )
									{
										switch( tail2 )
										{
											case "fi", "Fi":	_type = "ifloat";	break;
											case "Li":			_type = "ireal";	break;
											default:	break;
										}										
									}
								}
							}
							parseToken( TOK.Tnumbers );
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
			
			void _addChild()
			{
				/*
				if( Util.index( _type, " function(" ) < _type.length )
					activeASTnode.addChild( _name, D_FUNCTIONPTR, getProt(), _type, _rightName, _ln );
				else if( Util.index( _type, " delegate(" ) < _type.length )
					activeASTnode.addChild( _name, D_FUNCTIONPTR, getProt(), _type, _rightName, _ln );
				else
					activeASTnode.addChild( _name, D_VARIABLE, getProt(), _type, _rightName, _ln );
				*/
				int keyPos = Util.index( _type, " function(" );
				if( keyPos >= _type.length ) keyPos = Util.index( _type, " delegate(" );
				if( keyPos < _type.length )
				{
					activeASTnode.addChild( _name, D_FUNCTIONPTR, getProt(), _type[0..keyPos] ~ _type[keyPos+9..$], _rightName, _ln );
				}
				else
				{
					activeASTnode.addChild( _name, D_VARIABLE, getProt(), _type, _rightName, _ln );
				}				
			}

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
						_addChild();
						parseToken( TOK.Tcomma );
						parseVariable( _type );
					}
					else if( token().tok == TOK.Tsemicolon )
					{
						_addChild();
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
					if( funTailIndex >= tokens.length ) return false;
					
					
					if( tokens[funTailIndex].tok == TOK.Topenparen ) // Template Function
					{
						_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode = activeASTnode.addChild( _name, D_TEMPLATE, getProt(), _params, null, _ln );
						curlyStack.push( "Aggregate Templates" );
						funTailIndex = getFunctionDeclareTailIndex();
					}					
					
					
					if( tokens[funTailIndex].tok == TOK.Tsemicolon )
					{
						_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type ~ _params, null, _ln );
						if( curlyStack.top() == "Aggregate Templates" )
						{
							if( activeASTnode.getFather !is null )
							{
								activeASTnode.endLineNum = tokens[funTailIndex].lineNumber;
								activeASTnode = activeASTnode.getFather;
							}
							/*
							else
								throw new Exception( "parseFunction() over top error!" );
							*/
							curlyStack.pop();
						}
						return true;
					}
					else if( tokens[funTailIndex].tok == TOK.Topencurly )
					{
						// FunctionBody
						activeASTnode = activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type, null, _ln );
						_params = getParameters();
						activeASTnode.type = _type ~ _params;
						curlyStack.push( "Function" );
					}
					else if( tokens[funTailIndex].tok == TOK.Tin || tokens[funTailIndex].tok == TOK.Tout )
					{
						bool bContract;
						
						if( tokens[funTailIndex+1].tok == TOK.Topencurly )
							bContract = true;
						//else if( tokens[funTailIndex].tok == TOK.Tout && tokens[funTailIndex+1].tok == TOK.Topenparen  )
						else if( tokens[funTailIndex+1].tok == TOK.Topenparen  )
						{
							int tailPos = getDelimitedTailIndex( TOK.Topenparen, TOK.Tcloseparen, funTailIndex+1 );
							if( tokens[tailPos].tok == TOK.Topencurly ) bContract = true;
						}
					
						if( bContract )
						{
							activeASTnode = activeASTnode.addChild( _name, D_FUNCTION, getProt(), _type, null, _ln );
							_params = getParameters();
							activeASTnode.type = _type ~ _params;
							curlyStack.push( "Function" );
							
							while( isMemberFunctionAttribute() )
								parseToken();
								
							parseConstraint();
								
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
			//writeln( _type );
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
				catch( Exception e )
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
					else if( token().tok == TOK.Tthis )
					{
						parseToken( TOK.Tthis );
						if( token().tok == TOK.Tcloseparen )
						{
							parseToken( TOK.Tcloseparen );
							return "(this)";
						}
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
						if( isTypeCtor() )
						{
							if( next().tok == TOK.Topenparen ) break; // Leave While immutable(char) or const(char) or inout(char).......
						}
						
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
		
		// Parameter Storage Classes
		/*
		Parameter Storage Classes Storage Class	Description:
		
		none		parameter becomes a mutable copy of its argument
		in			defined as scope const. However in has not yet been properly implemented so it's current implementation is equivalent to const. It is recommended to avoid using in until it is properly defined and implemented. Use scope const or const explicitly instead.
		out			parameter is initialized upon function entry with the default value for its type
		ref			parameter is passed by reference
		scope		references in the parameter cannot be escaped (e.g. assigned to a global variable). Ignored for parameters with no references
		return		Parameter may be returned or copied to the first parameter, but otherwise does not escape from the function. Such copies are required not to outlive the argument(s) they were derived from. Ignored for parameters with no references. See Scope Parameters.
		lazy		argument is evaluated by the called function and not by the caller
		const		argument is implicitly converted to a const type
		immutable	argument is implicitly converted to an immutable type
		shared		argument is implicitly converted to a shared type
		inout		argument is implicitly converted to an inout type		
		*/
		bool isInOut()
		{
			try
			{
				switch( token().tok )
				{
					case TOK.Tin, TOK.Tout, TOK.Tref, TOK.Tscope, TOK.Tlazy:
						return true;
					/*
					case TOK.Tauto, TOK.Tfinal, TOK.Tin, TOK.Tlazy, TOK.Tout, TOK.Tref, TOK.Tscope:
						return true;
					*/
					case TOK.Tauto, TOK.Tfinal:
						return true;
					
					case TOK.Treturn:
						if( next().tok == TOK.Tref || next().tok == TOK.Tscope ) // Return Ref Parameters & Return Scope Parameters
						{
							parseToken( TOK.Treturn );
							return true;
						}
						break;

					default:
						if( isTypeCtor() ) return true;
				}
			}
			catch( Exception e )
			{
				throw e;
			}

			return false;
		}

		bool isStorageClass( int _token = -1 )
		{
			if( _token == -1 ) _token = token().tok;
			
			switch( _token )
			{
				case TOK.Tdeprecated, TOK.Tenum, TOK.Tstatic, TOK.Tabstract, TOK.Tfinal, TOK.Toverride, TOK.Tsynchronized, TOK.Tauto, TOK.Tscope, TOK.Tconst,
					TOK.Timmutable, TOK.Tinout, TOK.Tshared, TOK.T__gshared, TOK.TProperty, TOK.Tnothrow, TOK.Tpure, TOK.Tref:
					return true;
				
				// Property
				case TOK.TatProperty, TOK.TatSafe, TOK.TatTrusted, TOK.TatSystem, TOK.TatDisable, TOK.TatNogc:
					return true;
				
				// LinkageAttribute. AlignAttribute
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
					if( funTailIndex >= tokens.length ) return false;

					if( tokens[funTailIndex].tok == TOK.Topenparen ) // Meet TemplateParameters
					{
						// TemplateParameters
						getDelimitedString( TOK.Topenparen, TOK.Tcloseparen ); // Skip TemplateParameters
						funTailIndex = getFunctionDeclareTailIndex();
					}
					
					if( tokens[funTailIndex].tok == TOK.Tsemicolon )
					{
						_params = getDelimitedString( TOK.Topenparen, TOK.Tcloseparen );
						activeASTnode.addChild( null, D_CTOR, null, _params, null, _ln );
						parseConstraint();
						
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
							//curlyStack.push( "{" );
							
							while( isMemberFunctionAttribute() )
								parseToken();
								
							parseConstraint();
								
							return true;
						}
					}			

					while( isMemberFunctionAttribute() )
						parseToken();
						
					parseConstraint();

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
					}
						
					if( token().tok == TOK.Topencurly )
					{
						activeASTnode = activeASTnode.addChild( _name, D_KIND, getProt(), null, null, _ln );
						curlyStack.push( "CLASS" );
						return true;
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
									if( activeASTnode.getFather !is null )
									{
										activeASTnode.endLineNum = prev().lineNumber;
										activeASTnode = activeASTnode.getFather();
									}
									/*
									else
										throw new Exception( "parseEnum() over top error!" );
									*/
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
									if( activeASTnode.getFather !is null )
									{
										activeASTnode.endLineNum = prev().lineNumber;
										activeASTnode = activeASTnode.getFather();
									}
									/*
									else
										throw new Exception( "parseEnum() over top error!" );
									*/
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
						if( token().tok != TOK.Tclosecurly ) parseEnumMembers( bAnonymous, _EnumBaseType );
					}

					return true;
				}
				else if( token().tok == TOK.Tclosecurly )
				{
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
							case TOK.Tstrings:
								_Instance = "char[]";
								parseToken();
								break;
							
							case TOK.Tnumbers:
								_Instance = "int";
								parseToken();
								break;
							
							case TOK.Tbool, TOK.Tbyte, TOK.Tubyte, TOK.Tshort, TOK.Tushort, TOK.Tint, TOK.Tuint, TOK.Tlong, TOK.Tulong,
								TOK.Tchar, TOK.Tdchar, TOK.Twchar,
								TOK.Tfloat, TOK.Tdouble, TOK.Treal, TOK.Tifloat, TOK.Tidouble, TOK.Tireal, TOK.Tcfloat, TOK.Tcdouble, TOK.Tcreal,
								TOK.Tvoid:
							case TOK.Ttrue, TOK.Tfalse:
							case TOK.Tnull, TOK.Tthis:
							case TOK.T__FILE__, TOK.T__FILE_FULL_PATH__, TOK.T__MODULE__, TOK.T__LINE__, TOK.T__FUNCTION__, TOK.T__PRETTY_FUNCTION__: // SpecialKeyword
								foreach( key; identToTOK.keys )
								{
									if( identToTOK[key] == token().tok )
									{
										_Instance ~= key;
										parseToken();
										break;
									}
								}
								break;

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
		bool parseAggregateTemplates( int D_KIND, char[] _name, ref char[] _baseName )
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
			//alias AsciiString = immutable(AsciiChar)[];
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
							case TOK.Tin, TOK.Tout, TOK.Tbody, TOK.Tdo: // FunctionContracts
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
								switch( D_KIND )
								{
									case D_VERSION:		conditionStack.push( "version" ); break;
									case D_DEBUG:		conditionStack.push( "debug" ); break;
									//case D_STATICIF:	conditionStack.push( "staticif" ); break;
									default:			return false;
								}
								break;
							}
							else
							{
								switch( D_KIND )
								{
									case D_VERSION:		curlyStack.push( "version" ); break;
									case D_DEBUG:		curlyStack.push( "debug" ); break;
									//case D_STATICIF:	curlyStack.push( "staticif" ); break;
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

	public:
		this()
		{
			curlyStack		= new CStack!(char[]);
			protStack		= new CStack!(char[]);
			conditionStack	= new CStack!(char[]);
		}
		
		this( TokenUnit[] _tokens )
		{
			updateTokens( _tokens );
		}
		
		~this()
		{
			if( curlyStack !is null )		delete curlyStack;
			if( protStack !is null )		delete protStack;
			if( conditionStack !is null )	delete conditionStack;
		}
		

		bool updateTokens( TokenUnit[] _tokens )
		{
			tokenIndex = 0;
			tokens.length = 0;
			tokens = _tokens;
			
			activeProt = "";
			bAssignExpress = false;
			
			if( curlyStack !is null ) delete curlyStack;
			if( protStack !is null ) delete protStack;
			if( conditionStack !is null ) delete conditionStack;
			
			curlyStack		= new CStack!(char[]);
			protStack		= new CStack!(char[]);
			conditionStack	= new CStack!(char[]);
			
			if( !_tokens.length ) return false;
			
			return true;
		}
		
		CASTnode parse( char[] fullPath )
		{
			CASTnode	head = null;
			
			try
			{
				if( fullPath.length )
				{
					head = new CASTnode( fullPath, D_MODULE, null, fullPath, null, 0, 2147483647 );
					activeASTnode = head;
				}
				
				
				int	prevTokenIndex;
				int	repeatCount;

				while( tokenIndex < tokens.length )
				{
					if( tokenIndex == prevTokenIndex )
					{
						if( ++repeatCount > 10 )
						{
							IupMessageError( GLOBAL.mainDlg, "Infinite Loop of parse() function" );
							//Stdout( "Infinite Loop of parse() function" ).newline;
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
						
						case TOK.Tdotdot:
							parseToken( TOK.Tidentifier );
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
							
						case TOK.Tfunction, TOK.Tdelegate:
							if( next().tok == TOK.Topenparen )
							{
								int tailIndex = getDelimitedTailIndex( TOK.Topenparen, TOK.Tcloseparen, tokenIndex + 1, false );
								if( tokens[tailIndex].tok == TOK.Topencurly )
								{
									parseToken(); // TOK.Tfunction, TOK.Tdelegate
									activeASTnode = activeASTnode.addChild( "-Anonymous-", D_FUNCTIONLITERALS, "private", null, null, token().lineNumber );
									activeASTnode.type = getParameters();
									curlyStack.push( "D_FUNCTIONLITERALS" );
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

						/+
						Pre and Post Contracts
						
						in (expression)
						in (expression, "failure string")
						out (identifier; expression)
						out (identifier; expression, "failure string")
						out (; expression)
						out (; expression, "failure string")
						{
							...function body...
						}							
						+/
						case TOK.Tout, TOK.Tin:
							if( next().tok == TOK.Topenparen )
							{
								/+
								if( next2().tok == TOK.Tidentifier )
								{
									parseToken( TOK.Tout );
									parseToken( TOK.Topenparen );
									parseToken( TOK.Tidentifier );

									if( token().tok == TOK.Tcloseparen && next().tok == TOK.Topencurly )
									{
										parseToken( TOK.Tcloseparen );
										//parseToken( TOK.Topencurly );
										curlyStack.push( "out" );
										break;
									}
								}
								parseToken();
								break;
								+/
								int tailIndex = getDelimitedTailIndex( TOK.Topenparen, TOK.Tcloseparen, tokenIndex + 1, false );
								if( tokens[tailIndex].tok == TOK.Topencurly )
								{
									//curlyStack.push( token().identifier );
									tokenIndex = tailIndex;
									break;
								}
							}
							
						case TOK.Tdo:
							if( next().tok == TOK.Topencurly )
							{
								if( prev().tok == TOK.Tclosecurly )
								{
									int tailIndex = getDelimitedTailIndex( TOK.Topencurly, TOK.Tclosecurly, tokenIndex + 1, false );
									if( tokens[tailIndex].tok != TOK.Twhile )
									{
										//curlyStack.push( "do" );
										parseToken( TOK.Tdo );
										break;
									}
								}
							}
							
							parseToken( TOK.Tdo );
							break;

						case /*TOK.Tin,*/ TOK.Tbody:
							if( next().tok == TOK.Topencurly )
							{
								//curlyStack.push( token().identifier );
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
								//if( GLOBAL.toggleSkipUnittest == "ON" || bSkipFlag == true )
								//{
									parseToken( TOK.Tunittest );
									getDelimitedString( TOK.Topencurly, TOK.Tclosecurly );
									break;
								//}
								/*
								activeASTnode = activeASTnode.addChild( null, D_UNITTEST, null, null, null, token().lineNumber );
								curlyStack.push( "unittest" );
								*/
							}
							parseToken( TOK.Tunittest );
							break;

						case TOK.Topencurly:
							curlyStack.push( "{" );
							
							// Protection
							activeProt = "";
							protStack.push( "{" );
							if( prev().tok == TOK.Tprivate || prev().tok == TOK.Tprotected || prev().tok == TOK.Tpublic ) protStack.push( prev().identifier );
							
							parseToken( TOK.Topencurly );
							break;
							
						case TOK.Tclosecurly:
							// Protection
							if( protStack.size() > 0 )
							{
								while( protStack.top() != "{" && protStack.top() != "" )
									protStack.pop();
								
								if( protStack.top() == "{" ) protStack.pop();
							}
							

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
										// goto case; // D2 compiler

									case "staticif":
										if( D_KIND < 0 ) D_KIND = D_STATICIF;
										// goto case; // D2 compiler
										
									case "version":
										if( D_KIND < 0 ) D_KIND = D_VERSION;
										
										curlyStack.pop();

										char[] _name;
										if( activeASTnode.getFather !is null )
										{
											activeASTnode.endLineNum = token().lineNumber;
											_name = activeASTnode.name;
											activeASTnode = activeASTnode.getFather();
										}
										else
										{
											throw new Exception( "parse()--TOK.Tclosecurly--'version' over top error!" );
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
														case D_VERSION:		conditionStack.push( "version else" ); break;
														case D_DEBUG:		conditionStack.push( "debug else" ); break;
														//case D_STATICIF:	conditionStack.push( "staticif else" ); break;
														default:
													}
												}
												else
												{
													switch( D_KIND )
													{
														case D_VERSION:		curlyStack.push( "version else" ); break;
														case D_DEBUG:		curlyStack.push( "debug else" ); break;
														//case D_STATICIF:	curlyStack.push( "staticif else" ); break;
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
										
									case "version else", "debug else": //, "staticif else":
										curlyStack.pop();

										if( activeASTnode.getFather !is null )
										{
											activeASTnode.endLineNum = token().lineNumber;
											activeASTnode = activeASTnode.getFather();
										}
										else
										{
											throw new Exception( "parse()--TOK.Tclosecurly--'version else, debug else' over top error!" );
										}
										break;
									
									// Contract Programming
									case "in", "out", "do":
										curlyStack.pop();
										//goto default;  		// D2 compiler
										
									default:
										curlyStack.pop();
										if( activeASTnode.getFather !is null )
										{
											activeASTnode.endLineNum = token().lineNumber;
											activeASTnode = activeASTnode.getFather();
										}
										/*
										else
										{
											throw new Exception( "parse()--TOK.Tclosecurly over top error!" );
										}
										*/
										break;
								}

								// Aggregate Templates
								if( curlyStack.top() == "Aggregate Templates" )
								{
									curlyStack.pop();
									if( activeASTnode.getFather !is null )
									{
										activeASTnode.endLineNum = token().lineNumber;
										activeASTnode = activeASTnode.getFather();
									}
									else
									{
										throw new Exception( "parse()--TOK.Tclosecurly--'Aggregate Templates' over top error!" );
									}
								}
							}
							
							if( !bSkipParseToken ) parseToken( TOK.Tclosecurly );
							break;

						case TOK.Tsemicolon:
							parseToken( TOK.Tsemicolon );
							bAssignExpress = false;
							activeProt = "";
							

							int		prevD_KIND;
							switch( conditionStack.top() )
							{
								case "version":		prevD_KIND = D_VERSION;		break;
								case "debug":		prevD_KIND = D_DEBUG;		break;
								//case "staticif":	D_KIND = D_STATICIF;	break;
								default:
							}
							
							if( conditionStack.size > 0 )
							{
								conditionStack.pop();
								activeASTnode.endLineNum = prev().lineNumber;
								
								if( activeASTnode.getFather !is null )
								{
									activeASTnode = activeASTnode.getFather();
								}
								else
								{
									throw new Exception( "parse()--TOK.Tsemicolon--'Condition' over top error!" );
								}
							
								if( prevD_KIND & D_VERSION )
								{
									if( token().tok == TOK.Telse )
									{
										int _ln = token().lineNumber;
										
										parseToken( TOK.Telse );

										if( token().tok != TOK.Tversion && token().tok != TOK.Tdebug )
										{
											activeASTnode = activeASTnode.addChild( "-else-", prevD_KIND, getProt(), null, "", _ln );
											
											if( token().tok != TOK.Topencurly )
											{
												switch( prevD_KIND )
												{
													case D_VERSION:		conditionStack.push( "version else" ); break;
													case D_DEBUG:		conditionStack.push( "debug else" ); break;
													//case D_STATICIF:	conditionStack.push( "staticif else" ); break;
													default:
												}
											}
											else
											{
												switch( prevD_KIND )
												{
													case D_VERSION:		curlyStack.push( "version else" ); break;
													case D_DEBUG:		curlyStack.push( "debug else" ); break;
													//case D_STATICIF:	curlyStack.push( "staticif else" ); break;
													default:
												}
											}									
										}
									}
								}
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
								
								if( token().tok == TOK.Tstatic )
								{
									if( next().tok == TOK.Tidentifier )
									{
										if( next().identifier == "opCall" )
										{
											parseToken();
											parseFunction( "AUTO" );
											break;
										}
									}
								}
								
								while( isStorageClass( next().tok ) && token().tok != TOK.Tauto )
									parseToken();
								
								// Auto Functions & Auto Ref Functions
								if( token().tok == TOK.Tauto )
								{
									if( next().tok == TOK.Tref && next2().tok == TOK.Tidentifier ) parseToken( TOK.Tauto );
									
									if( next().tok == TOK.Tidentifier && next2().tok == TOK.Topenparen )
									{
										parseToken();
										parseFunction( "AUTO" );
										break;
									}
									
									while( isStorageClass( next().tok ) )
										parseToken();									
								}

								
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
				//debug GLOBAL.IDEMessageDlg.print( e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
				//Stdout( e.toString ~"\n" ~ fullPath ~ ": " ~ Integer.toString( tokenIndex ) ).newline;
			}

			if( head !is null )
			{
				if( activeASTnode !is head ) head.endLineNum = 2147483646; else head.endLineNum = 2147483647;
			}
				
			//printAST( head );

			return head;
		}
	}
}