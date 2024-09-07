module images.xpm;

struct XPM
{
private:
	import iup.iup;
	import global, tools, actionManager;
	import std.string, std.conv, std.file, Array = std.array, std.uni;

	struct ColorUnit
	{
		string 	index, c, value;
		int		sn;
	}

	static ubyte hexStringToByte( string hex )
	{
		hex = toLower( hex );
	
		if( hex.length == 2 )
		{
			uint d1, d2;
			
			if( hex[0] == '0' )
			{
				d2 = 0;
			}
			else if( hex[0] >= 97 && hex[0] <= 102 )
			{
				d2 = ( hex[0] - 87 ) * 16;
			}
			else
			{
				d2 = ( hex[0] - 48 ) * 16;
			}

			if( hex[1] >= 97 && hex[1] <= 102 )
			{
				d1 = hex[1] - 87;
			}
			else if( hex[1] == '0' )
			{
				d1 = 0;
			}
			else
			{
				d1 = hex[1] - 48;
			}
		
			return cast(ubyte) ( d2 + d1 );
		}

		return 0;
	}

	static IupString convert( string filePath )
	{
		try
		{
			int 		quoteLineCount;
			int			width, height, num_colors, chars_per_pixel;
			ptrdiff_t	rPos;
			bool 		bFormat, bPixel, bColor;
			
			string		pixel;
			ColorUnit[]	color;
			int			_bom, _withbom;
			
			auto doc = FileAction.loadFile( filePath, _bom, _withbom );
			foreach( size_t count, line; std.string.splitLines( doc ) )
			{
				if( count == 0 )
				{
					if( line != "/* XPM */" ) return null;
				}
				
				if( line.length > 2 )
				{
					if( line[0..2] == "/*" || line[0] != '"' ) continue;
					
					if( line[0] == '"' ) quoteLineCount++;
					
					if( quoteLineCount == 1 )
					{
						string	formatString;
						bool	bIsNumber;
						foreach( char c; line[1..$-2] )
						{
							if( c > 47 && c < 58 )
							{
								formatString ~= c;
								bIsNumber = true;
							}
							else
							{
								if( bIsNumber )
								{
									bIsNumber = false;
									formatString ~= " ";
								}
							}
						}
						
						string[] splitWords = Array.split( formatString, " " );
						if( splitWords.length > 3 )
						{
							width = to!(int)( splitWords[0] );
							height = to!(int)( splitWords[1] );
							num_colors = to!(int)( splitWords[2] );
							chars_per_pixel = to!(int)( splitWords[3] );
						}
						continue;
					}
					else if( quoteLineCount <= num_colors + 1 )
					{
						rPos = lastIndexOf( line, "\"" );
						string[] splitData = tools.splitSigns( line[2..rPos], ' ', '\t' );
						if( splitData.length == 2 )
						{
							ColorUnit _color;
							_color.index = line[1..2].dup;
							_color.c = splitData[0].dup;
							if( splitData[1] == "None" )
							{
								_color.value = "00000000".dup;
							}
							else
							{
								_color.value = ( splitData[1][1..$] ~ "ff" ).dup;
								
							}

							color ~= _color;
						}
					}
					else if( quoteLineCount <= num_colors + 1 + width )
					{
						rPos = lastIndexOf( line, "\"" );
						foreach( char c; line[1..rPos] )
							pixel ~= c;
					}
				}
			}

			ubyte[] result; 

			foreach( char c; pixel )
			{
				foreach( ColorUnit _color; color )
				{
					if( c == _color.index[0] )
					{
						result ~= hexStringToByte( _color.value[0..2] );
						result ~= hexStringToByte( _color.value[2..4] );
						result ~= hexStringToByte( _color.value[4..6] );
						result ~= hexStringToByte( _color.value[6..8] );
					}
				}
			}
			
			auto ret = new IupString( cast(string) result );

			return ret;
		}
		catch( Exception e )
		{
			debug IupMessage( "XPM:convert", toStringz( e.toString ) );
		}

		return null;
	}	
	/+
	static char*[] getXpm( char[] filePath )
	{
		try
		{
			scope file = new File( filePath, File.ReadExisting );

			int count;
			char*[] data;
			
			foreach( line; new Lines!(char)(file) )
			{
				if( count++ == 0 )
				{
					if( line != "/* XPM */" ) return null;
				}
				
				if( line.length )
				{
					if( line[0] == '"' )
					{
						int rPos = Util.rindex( line, "\"" );
						data ~= toStringz( line[1..rPos].dup );
					}					
				}
			}

			return data.dup;
		}
		catch( Exception e )
		{
			return null;
		}
	}
	+/
	static IupString getRGBA( string filePath )
	{
		try
		{
			return convert( GLOBAL.poseidonPath ~ "/" ~ filePath );
		}
		catch( Exception e )
		{
		}

		return null;
	}

	public:
	/* XPM */
	version(FBIDE)
	{
	static IupString private_fun_rgba, protected_fun_rgba, public_fun_rgba, private_sub_rgba, protected_sub_rgba, public_sub_rgba,
			private_variable_array_rgba, protected_variable_array_rgba, public_variable_array_rgba, private_variable_rgba, alias_obj_rgba,
			protected_variable_rgba, public_variable_rgba, class_private_obj_rgba, class_protected_obj_rgba,
			class_obj_rgba, struct_private_obj_rgba, struct_protected_obj_rgba, struct_obj_rgba,  
			union_private_obj_rgba,
			union_protected_obj_rgba, union_obj_rgba, enum_private_obj_rgba, enum_protected_obj_rgba, enum_obj_rgba,
			normal_rgba, with_rgba, parameter_rgba, enum_member_obj_rgba, template_obj_rgba,
			functionpointer_obj_rgba, namespace_obj_rgba, property_rgba, property_var_rgba, define_var_rgba, define_fun_rgba, macro_obj_rgba,
			bas_rgba, bi_rgba, folder_rgba,
			bookmark_rgba;
	}
	version(DIDE)
	{
	static IupString private_fun_rgba, protected_fun_rgba, public_fun_rgba, private_sub_rgba, protected_sub_rgba, public_sub_rgba,
			private_variable_array_rgba, protected_variable_array_rgba, public_variable_array_rgba, private_variable_rgba, alias_obj_rgba,
			protected_variable_rgba, public_variable_rgba, class_private_obj_rgba, class_protected_obj_rgba,
			interface_obj_rgba, class_obj_rgba, struct_private_obj_rgba, struct_protected_obj_rgba, struct_obj_rgba,  
			union_private_obj_rgba,
			union_protected_obj_rgba, union_obj_rgba, enum_private_obj_rgba, enum_protected_obj_rgba, enum_obj_rgba,
			normal_rgba, import_rgba, template_rgba, parameter_rgba, enum_member_obj_rgba,
			functionpointer_obj_rgba, namespace_obj_rgba, property_rgba, property_var_rgba, define_var_rgba, define_fun_rgba,
			bas_rgba, bi_rgba, folder_rgba,
			bookmark_rgba;
	}

	static Ihandle* getIUPimageFormXPM( string filePath )
	{
		try
		{
			int 		colorSN;
			ptrdiff_t	rPos;
			bool 		bPixel, bColor;
			int			quoteLineCount, width, height, num_colors, chars_per_pixel;
			string		prevLine, pixel;
			ColorUnit[]	color;
			
			if( !std.file.exists( filePath ) ) filePath = GLOBAL.poseidonPath ~ "/" ~ filePath;
			if( !std.file.exists( filePath ) ) return null;
			auto doc = cast(string) std.file.read( filePath );
			foreach( size_t count, line; std.string.splitLines( doc ) )
			{
				if( count == 0 )
				{
					if( line != "/* XPM */" ) return null;
				}
				
				if( line.length > 2 )
				{
					if( line[0..2] == "/*" || line[0] != '"' ) continue;
					
					if( line[0] == '"' ) quoteLineCount++;
					
					if( quoteLineCount == 1 )
					{
						string	formatString;
						bool	bIsNumber;
						foreach( char c; line[1..$-2] )
						{
							if( c > 47 && c < 58 )
							{
								formatString ~= c;
								bIsNumber = true;
							}
							else
							{
								if( bIsNumber )
								{
									bIsNumber = false;
									formatString ~= " ";
								}
							}
						}
						
						string[] splitWords = Array.split( formatString, " " );
						if( splitWords.length > 3 )
						{
							width = to!(int)( splitWords[0] );
							height = to!(int)( splitWords[1] );
							num_colors = to!(int)( splitWords[2] );
							chars_per_pixel = to!(int)( splitWords[3] );
						}
						continue;
					}
					else if( quoteLineCount <= num_colors + 1 )
					{
						rPos = lastIndexOf( line, "\"" );
						string[] splitData = tools.splitSigns( line[2..rPos], ' ', '\t' );
						if( splitData.length == 2 )
						{
							ColorUnit _color;
							_color.index = line[1..2].dup;
							_color.c = splitData[0].dup;
							if( splitData[1] == "None" )
							{
								_color.value = "BGCOLOR";
							}
							else
							{
								int r = hexStringToByte( splitData[1][1..3] );
								int g = hexStringToByte( splitData[1][3..5] );
								int b = hexStringToByte( splitData[1][5..7] );

								_color.value = to!(string)( r ) ~ " " ~ to!(string)( g ) ~ " " ~ to!(string)( b );
							}

							_color.sn = colorSN++;
							color ~= _color;
						}
					}
					else if( quoteLineCount <= num_colors + 1 + width )
					{
						rPos = lastIndexOf( line, "\"" );
						foreach( char c; line[1..rPos] )
							pixel ~= c;
					}
				}
			}
			
			ubyte[] data; 
			foreach( char c; pixel )
			{
				foreach( ColorUnit __color; color )
				{
					if( c == __color.index[0] )
					{
						data ~= cast(ubyte) __color.sn;
						break;
					}
				}
			}
			
			Ihandle* image = IupImage( width, height, data.ptr );

			foreach( ColorUnit __color; color )
				IupSetStrAttribute( image, toStringz( to!(string)( __color.sn ) ) , toStringz( __color.value ) );

			return image;

		}
		catch( Exception e )
		{
		}

		return null;
	}


	static void createIUPimageHandle( string filePath, string handleName, bool bCreateInvert = false )
	{
		try
		{
			int 		colorSN;
			ptrdiff_t	rPos;
			bool 		bPixel, bColor;
			int			quoteLineCount, width, height, num_colors, chars_per_pixel;
			string		prevLine, pixel;
			ColorUnit[]	color;

			if( !std.file.exists( filePath ) ) filePath = GLOBAL.poseidonPath ~ "/" ~ filePath;
			if( !std.file.exists( filePath ) ) return;
			auto doc = cast(string) std.file.read( filePath );
			foreach( size_t count, line; std.string.splitLines( doc ) )
			{
				if( count == 0 )
					if( line != "/* XPM */" ) return;
				
				if( line.length > 2 )
				{
					if( line[0..2] == "/*" || line[0] != '"' ) continue;
					
					if( line[0] == '"' ) quoteLineCount++;
					
					if( quoteLineCount == 1 )
					{
						string	formatString;
						bool	bIsNumber;
						foreach( char c; line[1..$-2] )
						{
							if( c > 47 && c < 58 )
							{
								formatString ~= c;
								bIsNumber = true;
							}
							else
							{
								if( bIsNumber )
								{
									bIsNumber = false;
									formatString ~= " ";
								}
							}
						}
						
						string[] splitWords = Array.split( formatString, " " );
						if( splitWords.length > 3 )
						{
							width = to!(int)( splitWords[0] );
							height = to!(int)( splitWords[1] );
							num_colors = to!(int)( splitWords[2] );
							chars_per_pixel = to!(int)( splitWords[3] );
						}
						continue;
					}
					else if( quoteLineCount <= num_colors + 1 )
					{
						rPos = lastIndexOf( line, "\"" );
						string[] splitData = tools.splitSigns( line[2..rPos], ' ', '\t' );
						if( splitData.length == 2 )
						{
							ColorUnit _color;
							_color.index = line[1..2].dup;
							_color.c = splitData[0].dup;
							if( splitData[1] == "None" )
							{
								_color.value = "BGCOLOR";
							}
							else
							{
								int r = hexStringToByte( splitData[1][1..3] );
								int g = hexStringToByte( splitData[1][3..5] );
								int b = hexStringToByte( splitData[1][5..7] );
			
								if( GLOBAL.editorSetting00.IconInvert == "ALL" )
									_color.value = to!(string)( 255 - r ) ~ " " ~ to!(string)( 255 - g ) ~ " " ~ to!(string)( 255 - b );
								else
									_color.value = to!(string)( r ) ~ " " ~ to!(string)( g ) ~ " " ~ to!(string)( b );
							}

							_color.sn = colorSN++;
							color ~= _color;
						}
					}
					else if( quoteLineCount <= num_colors + 1 + width )
					{
						rPos = lastIndexOf( line, "\"" );
						foreach( char c; line[1..rPos] )
							pixel ~= c;
					}
				}
			}			
			
			ubyte[] data; 
			foreach( char c; pixel )
			{
				foreach( ColorUnit __color; color )
				{
					if( c == __color.index[0] )
					{
						data ~= cast(ubyte) __color.sn;	
						break;
					}
				}
			}
			
			Ihandle* image = IupImage( width, height, data.ptr );

			foreach( ColorUnit __color; color )
				IupSetStrAttribute( image, toStringz( to!(string)( __color.sn ) ) , toStringz( __color.value ) );
			
			auto _handleName = new IupString( handleName );
			IupSetHandle( _handleName.toCString, image );
			
			
			if( bCreateInvert )
			{
				Ihandle* imageInvert = IupImage( width, height, data.ptr );
				
				foreach( ColorUnit __color; color )
				{
					if( __color.value != "BGCOLOR" )
					{
						string[] _colorValues = Array.split( __color.value, " " );
						if( _colorValues.length == 3 )
							__color.value = to!(string)( 255 - to!(int)( _colorValues[0] ) ) ~ " " ~ to!(string)( 255 - to!(int)( _colorValues[1] ) ) ~ " " ~ to!(string)( 255 - to!(int)( _colorValues[2] ) );
					}
					IupSetStrAttribute( imageInvert, toStringz( to!(string)( __color.sn ) ) , toStringz( __color.value ) );
					
					auto __handleName = new IupString( handleName ~ "_invert" );
					
					IupSetHandle( __handleName.toCString, imageInvert );
				}
			}
		}
		catch( Exception e )
		{
		}
	}
	
	static Ihandle* loadIupImage( string filePath, bool bInvert = false )
	{
		Ihandle*	img;
		
		int			MODE;
		string		_width, _height;
		ubyte[]		imgData;
		
		if( !std.file.exists( filePath ) ) filePath = GLOBAL.poseidonPath ~ "/" ~ filePath;
		if( !std.file.exists( filePath ) ) return null;
		auto doc = cast(string) std.file.read( filePath );
		foreach( line; std.string.splitLines( doc ) )
		{
			line = strip( line );
			
			if( line.length )
			{
				if( MODE == 0 )
				{
					if( line.length > 25 )
					{
						if( line == "unsigned char imgdata[] = {" )
						{
							MODE = 1;
							continue;
						}
						
						if( line[0..26] == "Ihandle* image = IupImage(" )
						{
							auto _data = Array.split( line[26..$], "," );
							if( _data.length == 3 )
							{
								_width = _data[0];
								_height = strip( _data[1] );
								if( imgData.length ) img = IupImage( std.conv.to!(int)(_width), std.conv.to!(int)(_height), imgData.ptr );
								
							}
						}
						
						else if( line[0..23] == "IupSetAttribute(image, " )
						{
							if( img )
							{
								string[] _data = Array.split( line[23..$-3], "," );
								if( _data.length == 2 )
								{
									string _num = strip( _data[0], "\"" );
									string _colorvalue = strip( strip( _data[1] ), "\"" );
									if( bInvert )
									{
										auto temp = Array.split( _colorvalue, " " );
										if( temp.length == 3 )
										{
											int r = 255 - std.conv.to!(int)(temp[0]);
											int g = 255 - std.conv.to!(int)(temp[1]);
											int b = 255 - std.conv.to!(int)(temp[2]);
											_colorvalue = std.conv.to!(string)(r) ~ " " ~ std.conv.to!(string)(g) ~ " " ~ std.conv.to!(string)(b); 
										}
									}
										
									IupSetStrAttribute( img, toStringz( _num), toStringz( _colorvalue ) ); 
								}
							}
						}
						
					}
				}
				else if( MODE == 1 )
				{
					string pixel;
					foreach( c; line )
					{						
						if( c == ',' )
						{
							imgData ~= std.conv.to!(ubyte)(pixel);
							pixel = "";
						}
						else if( c == '}' )
						{
							imgData ~= std.conv.to!(ubyte)(pixel);
							MODE = 0;
							break;
						}
						else if( isNumber( c ) )
						{
							pixel ~= c;
						}
					}
					
				}
			}
		}
		return img;
	}
	
	static Ihandle* InvertIupImage( Ihandle* oriImage )
	{
		if( oriImage )
		{
			Ihandle* modImage = IupImage( IupGetInt( oriImage, "WIDTH" ), IupGetInt( oriImage, "HEIGHT" ), null );
			
			IupCopyAttributes( oriImage, modImage );
			
			string[] colors;
			for( int i = 0; i < 8; ++i )
				colors ~= fSTRz( IupGetAttributeId( modImage, "", i ) );

			foreach( size_t counter, string color; colors )
			{
				if( color != "BGCOLOR" )
				{
					string[] _colorValues = Array.split( color, " " );
					if( _colorValues.length == 3 )
					{
						string invert = to!(string)( 255 - to!(int)( _colorValues[0] ) ) ~ " " ~ to!(string)( 255 - to!(int)( _colorValues[1] ) ) ~ " " ~ to!(string)( 255 - to!(int)( _colorValues[2] ) );
						//if( handleName == "icon_cut" ) IupMessage( "before", IupGetAttributeId( oriImage, "", cast(int)counter ) );
						IupSetStrAttribute( modImage, toStringz( to!(string)( counter ) ) , toStringz( invert ) );
						//if( handleName == "icon_cut" ) IupMessage( "after", IupGetAttributeId( oriImage, "", cast(int)counter ) );
					}
				}
			}
			return modImage;
		}
		
		return null;
	}	
	
	static void init()
	{
		version(FBIDE)
		{
			private_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_private.xpm");
			protected_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_protected.xpm" );
			public_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_public.xpm" );
			private_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_private.xpm");
			protected_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_protected.xpm" );
			public_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_public.xpm" );
			
			private_variable_array_rgba		= getRGBA( "icons/xpm/outline/variable_array_private.xpm" );
			protected_variable_array_rgba 	= getRGBA( "icons/xpm/outline/variable_array_protected.xpm" );
			public_variable_array_rgba		= getRGBA( "icons/xpm/outline/variable_array.xpm" );
			private_variable_rgba 			= getRGBA( "icons/xpm/outline/variable_private.xpm" );
			protected_variable_rgba 		= getRGBA( "icons/xpm/outline/variable_protected.xpm" );
			public_variable_rgba 			= getRGBA( "icons/xpm/outline/variable.xpm" );
			
			class_private_obj_rgba 			= getRGBA( "icons/xpm/outline/class_private.xpm" );
			class_protected_obj_rgba		= getRGBA( "icons/xpm/outline/class_protected.xpm" );
			class_obj_rgba 					= getRGBA( "icons/xpm/outline/class.xpm" );
			
			struct_private_obj_rgba 		= getRGBA( "icons/xpm/outline/type_private.xpm" );
			struct_protected_obj_rgba 		= getRGBA( "icons/xpm/outline/type_protected.xpm" );
			struct_obj_rgba 				= getRGBA( "icons/xpm/outline/type.xpm" );

			union_private_obj_rgba			= getRGBA( "icons/xpm/outline/union_private.xpm" );
			union_protected_obj_rgba		= getRGBA( "icons/xpm/outline/union_protected.xpm" );
			union_obj_rgba					= getRGBA( "icons/xpm/outline/union.xpm" );
			
			enum_private_obj_rgba 			= getRGBA( "icons/xpm/outline//enum_private.xpm" );
			enum_protected_obj_rgba			= getRGBA( "icons/xpm/outline/enum_protected.xpm" );
			enum_obj_rgba					= getRGBA( "icons/xpm/outline/enum.xpm" );
			
			normal_rgba						= getRGBA( "icons/xpm/outline/normal.xpm" );
			//import_rgba					= getRGBA( "icons/xpm/import.xpm" );
			//autoWord_rgba					= getRGBA( "icons/xpm/autoword.xpm" );
			with_rgba						= getRGBA( "icons/xpm/outline/with.xpm" );
			
			parameter_rgba					= getRGBA( "icons/xpm/outline/parameter.xpm" );
			enum_member_obj_rgba			= getRGBA( "icons/xpm/outline/enum_member.xpm" );
			
			alias_obj_rgba					= getRGBA( "icons/xpm/outline/alias.xpm" );
			//functionpointer_obj_rgba		= getRGBA( "icons/xpm/functionpointer.xpm" );
			namespace_obj_rgba				= getRGBA( "icons/xpm/outline/namespace.xpm" );
			
			property_rgba					= getRGBA( "icons/xpm/outline/property.xpm" );
			property_var_rgba				= getRGBA( "icons/xpm/outline/property_var.xpm" );
			
			define_var_rgba					= getRGBA( "icons/xpm/outline/define_var.xpm" );
			define_fun_rgba					= getRGBA( "icons/xpm/outline/define_fun.xpm" );
			
			macro_obj_rgba					= getRGBA( "icons/xpm/outline/macro.xpm" );
			
			bas_rgba						= getRGBA( "icons/xpm/bas.xpm" );
			bi_rgba							= getRGBA( "icons/xpm/bi.xpm" );
			folder_rgba						= getRGBA( "icons/xpm/folder.xpm" );
		}
		version(DIDE)
		{
			private_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_private.xpm");
			protected_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_protected.xpm" );
			public_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_public.xpm" );
			private_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_private.xpm");
			protected_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_protected.xpm" );
			public_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_public.xpm" );
			
			private_variable_array_rgba		= getRGBA( "icons/xpm/outline/variable_array_private.xpm" );
			protected_variable_array_rgba 	= getRGBA( "icons/xpm/outline/variable_array_protected.xpm" );
			public_variable_array_rgba		= getRGBA( "icons/xpm/outline/variable_array.xpm" );
			private_variable_rgba 			= getRGBA( "icons/xpm/outline/variable_private.xpm" );
			protected_variable_rgba 		= getRGBA( "icons/xpm/outline/variable_protected.xpm" );
			public_variable_rgba 			= getRGBA( "icons/xpm/outline/variable.xpm" );
			
			class_private_obj_rgba 			= getRGBA( "icons/xpm/outline/class_private.xpm" );
			class_protected_obj_rgba		= getRGBA( "icons/xpm/outline/class_protected.xpm" );
			class_obj_rgba 					= getRGBA( "icons/xpm/outline/class.xpm" );
			struct_private_obj_rgba 		= getRGBA( "icons/xpm/outline/struct_private.xpm" );
			struct_protected_obj_rgba 		= getRGBA( "icons/xpm/outline/struct_protected.xpm" );
			struct_obj_rgba 				= getRGBA( "icons/xpm/outline/struct.xpm" );
			union_private_obj_rgba			= getRGBA( "icons/xpm/outline/union_private.xpm" );
			union_protected_obj_rgba		= getRGBA( "icons/xpm/outline/union_protected.xpm" );
			union_obj_rgba					= getRGBA( "icons/xpm/outline/union.xpm" );
			enum_private_obj_rgba 			= getRGBA( "icons/xpm/outline/enum_private.xpm" );
			enum_protected_obj_rgba			= getRGBA( "icons/xpm/outline/enum_protected.xpm" );
			enum_obj_rgba					= getRGBA( "icons/xpm/outline/enum.xpm" );
			
			normal_rgba						= getRGBA( "icons/xpm/outline/normal.xpm" );
			import_rgba						= getRGBA( "icons/xpm/outline/import.xpm" );
			template_rgba					= getRGBA( "icons/xpm/outline/template.xpm" );
			
			parameter_rgba					= getRGBA( "icons/xpm/outline/parameter.xpm" );
			enum_member_obj_rgba			= getRGBA( "icons/xpm/outline/enum_member.xpm" );
			
			alias_obj_rgba					= getRGBA( "icons/xpm/outline/alias.xpm" );
			interface_obj_rgba 				= getRGBA( "icons/xpm/outline/interface.xpm" );
			//functionpointer_obj_rgba		= getRGBA( "icons/xpm/functionpointer_obj.xpm" );
			namespace_obj_rgba				= getRGBA( "icons/xpm/outline/namespace.xpm" );
			
			property_rgba					= getRGBA( "icons/xpm/outline/property.xpm" );
			property_var_rgba				= getRGBA( "icons/xpm/outline/property_var.xpm" );
			
			define_var_rgba					= getRGBA( "icons/xpm/outline/define_var.xpm" );
			define_fun_rgba					= getRGBA( "icons/xpm/outline/define_fun.xpm" );
			
			bas_rgba						= getRGBA( "icons/xpm/d.xpm" );
			bi_rgba							= getRGBA( "icons/xpm/bi.xpm" );
			folder_rgba						= getRGBA( "icons/xpm/folder.xpm" );			
		}
		bookmark_rgba					= getRGBA( "icons/xpm/bookmark.xpm" );
	}	
}