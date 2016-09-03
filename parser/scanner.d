module parser.scanner;


class CScanner
{
	private:
	import iup.iup;

	import global, tools;
	import parser.token;

	import Integer = tango.text.convert.Integer;
	import tango.io.FilePath, tango.text.Ascii, tango.stdc.stringz, Util = tango.text.Util;//, tango.io.UnicodeFile;
	import tango.io.device.File;//, tango.io.stream.Lines;
	import tango.io.Stdout;


	public:
	this(){}
	~this(){}

	TokenUnit[] scanFile( char[] fullPath )
	{
		scope f = new FilePath( fullPath );
		if( f.exists() )
		{
			char[] 	document;
			//char[]	splitLineDocument;
			if( upperCase(fullPath) in GLOBAL.scintillaManager )
			{
				document = fromStringz( IupGetAttribute( GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla, "VALUE" ) );
			}
			else
			{
				document = cast(char[]) File.get( fullPath );
			}

			return scan( document );
		}				
	}
	
	TokenUnit[]	scan( char[] data )
	{
		bool			bStringFlag, bCommentFlag, bCommentBlockFlag;
		char[]			identifier;
		int				lineNum = 1;
		int				commentCount;
		TokenUnit		token_unit;
		TokenUnit[]		results;

		data ~= "\n";

		try
		{
			for( int i = 0; i < data.length; ++ i )
			{
				if( bCommentBlockFlag )
				{
					do
					{
						if( data[i] == '/' )
						{
							if( data[i+1] == '\'' ) // Check if /'
							{
								commentCount ++;
								continue;
							}
						}
						else if( data[i] == '\'' ) // '
						{
							if( data[i+1] == '/' ) // /
							{
								commentCount --;

								if( commentCount == 0 )
								{
									bCommentBlockFlag = false;
									i++;
									break;
								}
							}
						}
						else if( data[i] == '\n' )
						{
							lineNum ++;
						}

						++i;
					}
					while( i < data.length )

					// Continue the main for-loop
					continue;
				}
				else
				{
					if( !bStringFlag )
					{
						if( data[i] == '/' )
						{
							if( data[i+1] == '\'' ) // Check if /'
							{
								bCommentBlockFlag = true;
								commentCount = 1;
								continue;
							}
						}
					}
				}

				// Comment Line
				if( !bStringFlag )
				{
					if( data[i] == '\'' )
					{
						while( ++i < data.length )
						{
							if( data[i] == '\n' )
							{
								break;
							}
						}
					}
				}

				if( bStringFlag )
				{
					if( data[i] == '"' )
					{
						bStringFlag = false;
						identifier ~= data[i];
						TokenUnit t = {TOK.Tstrings, identifier, lineNum};
						results ~= t;
						identifier = "";
						continue;
					}
					identifier ~= data[i];
					continue;
				}
				else
				{
					if( !bCommentBlockFlag )
					{
						if( data[i] == '"' )
						{
							bStringFlag = true;
							identifier ~= data[i];
							continue;
						}
					}
				}

				// Change line
				switch( data[i]  )
				{
					case '#':
						if( i < data.length - 1 )
						{
							if( data[i+1] == '#' )
							{
								identifier ~= "##";
								i ++;
								break;
							}
						}
						
						TokenUnit t = {TOK.Tpound, "#", lineNum};
						results ~= t;
						identifier = "";
						break;

					case '-':
						if( results[length-1].tok == TOK.Tassign )
						{
							identifier ~= data[i];
							break;
						}
						/*
						if( i < data.length - 1 )
						{
							if( data[i+1] >=48 && data[i+1] <= 57 )
							{
								identifier ~= data[i];
								break;
							}
						}
						*/
					case '>':
						if( identifier == "-" )
						{
							TokenUnit t;
							t.tok = TOK.Tptraccess;
							t.identifier = "->";
							t.lineNumber = lineNum;
							results ~= t;
							identifier = "";
							break;
						}

					case ',', '+', '*', '/', ':', '(', ')', '[', ']', '<', '=', '{', '}': // '>', 
						if( lowerCase( identifier.dup ) in identToTOK )
						{
							if( identifier.length )
							{
								TokenUnit t = {identToTOK[lowerCase( identifier.dup )], identifier, lineNum};
								results ~= t;
							}
						}
						else
						{
							if( identifier.length )
							{
								TokenUnit t;
								
								if( identifier[0] >= 48 && identifier[0] <= 57 ) t.tok = TOK.Tnumbers; else	t.tok = TOK.Tidentifier;

								if( identifier.length > 1 )
								{
									if( identifier[0] == 45 && identifier[1] >=48 && identifier[1] <= 57 ) t.tok = TOK.Tnumbers;

									if( identifier.length > 2 )
									{
										if( lowerCase( identifier[0..2] ) == "&h" ) t.tok = TOK.Tnumbers;
										if( lowerCase( identifier[0..3] ) == "-&h" ) t.tok = TOK.Tnumbers;
									}									
								}

								t.identifier = identifier;
								t.lineNumber = lineNum;
								results ~= t;
							}
						}

						char[] s;
						s ~= data[i];
						TokenUnit t = {identToTOK[s], s, lineNum};
						results ~= t;
						identifier = "";
						break;

					case 13: // CR
						break;
					
					case '\t', ' ', '\n':
						if( lowerCase( identifier.dup ) in identToTOK )
						{
							if( identifier.length )
							{
								TokenUnit t = {identToTOK[lowerCase( identifier.dup )], identifier, lineNum};
								results ~= t;
							}
						}
						else
						{
							if( identifier.length )
							{
								TokenUnit t;
								
								if( identifier[0] >= 48 && identifier[0] <= 57 ) t.tok = TOK.Tnumbers; else	t.tok = TOK.Tidentifier;
								if( identifier.length > 1 )
								{
									if( identifier[0] == 45 && identifier[1] >=48 && identifier[1] <= 57 ) t.tok = TOK.Tnumbers;

									if( identifier.length > 2 )
									{
										if( lowerCase( identifier[0..2] ) == "&h" ) t.tok = TOK.Tnumbers;
										if( lowerCase( identifier[0..3] ) == "-&h" ) t.tok = TOK.Tnumbers;
									}
								}

								t.identifier = identifier;
								t.lineNumber = lineNum;
								results ~= t;
							}
						}

						//
						if( data[i] == '\n' )
						{
							if( results.length > 0 )
							{
								if( results[length-1].tok != TOK.Tunderline )
								{
									// Keep the TOK.Teol just only one
									if( results[length-1].tok != TOK.Teol )
									{
										TokenUnit t = { TOK.Teol, "\n", lineNum };
										results ~= t;
									}
								}
								else
								{
									results.length = results.length - 1;
								}
							}
				
							lineNum ++;
						}

						identifier = "";
						break;

					case '.':
						if( identifier.length )
						{
							if( identifier[0] < 48 || identifier[0] > 57 )
							{
								if( lowerCase( identifier.dup ) in identToTOK )
								{
									TokenUnit t = {identToTOK[lowerCase( identifier.dup )], identifier, lineNum};
									results ~= t;
								}
								else
								{
									TokenUnit t = {TOK.Tidentifier, identifier, lineNum};
									results ~= t;
								}

								identifier = "";
								TokenUnit t = {identToTOK["."], ".", lineNum};
								results ~= t;
								continue;
							}
						}

					default:
						identifier ~= data[i];
				}
			}
		}
		catch( Exception e )
		{
			// IupMessage( "Token Scanner", toStringz( e.toString ) );
		}

		//print( results );

		return results;
	}

	void print( TokenUnit[] token_units )
	{
		foreach( TokenUnit t; token_units )
		{
			if( t.identifier != "\n" )
			{
				Stdout( t.identifier );
				Stdout( " #");
				Stdout( t.lineNumber ).newline;
			}
			else
			{
				Stdout( "Teol");
				Stdout( " #");
				Stdout( t.lineNumber ).newline;

			}
		}
	}
}
