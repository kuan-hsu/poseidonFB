module parser.scanner;


class CScanner
{
	private:
	import iup.iup;

	import global;
	import parser.token;

	import Integer = tango.text.convert.Integer;
	import tango.io.FilePath, tango.text.Ascii, tango.stdc.stringz, Util = tango.text.Util;//, tango.io.UnicodeFile;
	import tango.io.device.File;//, tango.io.stream.Lines;
	import tango.io.Stdout;


	public:

	TokenUnit[] scanFile( char[] fullPath )
	{
		scope f = new FilePath( Util.substitute( fullPath, "\\", "/" ) );
		if( f.exists() )
		{
			Util.substitute( fullPath, "/", "\\" );
			
			char[] 	document;
			//char[]	splitLineDocument;
			if( fullPath in GLOBAL.scintillaManager )
			{
				document = fromStringz( IupGetAttribute( GLOBAL.scintillaManager[fullPath].getIupScintilla, "VALUE" ) );
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

				if( bCommentFlag )
				{
					while( i < data.length )
					{
						if( data[i] == '\n' )
						{
							bCommentFlag = false;
							lineNum ++;
							break;
						}

						++i;
					}

					// Continue the main for-loop
					continue;
				}
				else
				{
					if( !bStringFlag )
					{
						if( data[i] == '\'' )
						{
							bCommentFlag = true;
							continue;
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
					if( !bCommentFlag && !bCommentBlockFlag )
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

					case ',', '+', '*', '/', ':', '(', ')', '[', ']', '>', '<', '=':
						if( toLower( identifier.dup ) in identToTOK )
						{
							if( identifier.length )
							{
								TokenUnit t = {identToTOK[toLower( identifier.dup )], identifier, lineNum};
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
						if( toLower( identifier.dup ) in identToTOK )
						{
							if( identifier.length )
							{
								TokenUnit t = {identToTOK[toLower( identifier.dup )], identifier, lineNum};
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
									TokenUnit t = {TOK.Teol, "\n", lineNum};
									results ~= t;
								}
								else
								{
									results.length = results.length - 1;
								}
							}
							else
							{
								TokenUnit t = {TOK.Teol, "\n", lineNum};
								results ~= t;
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
								if( toLower( identifier.dup ) in identToTOK )
								{
									TokenUnit t = {identToTOK[toLower( identifier.dup )], identifier, lineNum};
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
			IupMessage( "Token Scanner", toStringz( e.toString ) );
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
		}
	}
}
