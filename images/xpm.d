module images.xpm;

struct XPM
{
	private:
	import iup.iup;
	
	import tango.io.device.File, tango.io.stream.Lines, Util = tango.text.Util, Integer = tango.text.convert.Integer, tools;
	import tango.stdc.stringz;
	import tango.io.Stdout;

	static CstringConvert[] colorStrings;

	struct ColorUnit
	{
		char[] 	index, c, value;
		int		sn;
	}

	static ubyte hexStringToByte( char[] hex )
	{
		hex = lowerCase( hex );
	
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

	static CstringConvert convert( char[] filePath )
	{
		try
		{
			//return null;

			scope file = new File( filePath, File.ReadExisting );
			int 		count;
			bool 		bPixel, bColor;
			
			char[]		pixel;
			ColorUnit[]	color;
			
			foreach( line; new Lines!(char)(file) )
			{
				if( count++ == 0 )
				{
					if( line != "/* XPM */" ) return null;
				}
				
				if( line.length )
				{
					if( line == "/* pixels */" )
					{
						bPixel = true;
						bColor = false;
						continue;
					}
					else if( line == "/* colors */" )
					{
						bColor = true;
						bPixel = false;
						continue;
					}
					else
					{
						int rPos;
						if( line[0] == '"' )
						{
							rPos = Util.rindex( line, "\"" );

							if( bPixel )
							{
								foreach( char c; line[1..rPos] )
								{
									pixel ~= c;
								}
							}
							else if( bColor )
							{
								char[][] splitData = Util.split( line[1..rPos], " " );
								if( splitData.length == 3 )
								{
									ColorUnit _color;
									_color.index = splitData[0].dup;
									_color.c = splitData[1].dup;
									if( splitData[2] == "None" )
									{
										_color.value = "00000000".dup;
									}
									else
									{
										_color.value = ( splitData[2][1..length] ~ "ff" ).dup;
										
									}

									color ~= _color;
								}
							}
						}
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

			return new CstringConvert( cast(char[]) result.dup );
		}
		catch( Exception e )
		{
			Stdout( e.toString ).newline;
		}

		return null;
	}	

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
						char[] temp;
						data ~= toStringz( line[1..rPos].dup, temp ); delete temp;
					}					
				}
			}

			return data.dup;
		}
		catch
		{
			return null;
		}
	}

	static CstringConvert getRGBA( char[] filePath )
	{
		try
		{
			return convert( filePath );
		}
		catch
		{
		}

		return null;
	}

	public:
	/* XPM */
	static char*[] private_fun_xpm, protected_fun_xpm, public_fun_xpm, private_sub_xpm, protected_sub_xpm, public_sub_xpm,
					private_variable_array_xpm, protected_variable_array_xpm, public_variable_array_xpm, private_variable_xpm, alias_obj_xpm,
					protected_variable_xpm, public_variable_xpm, class_private_obj_xpm, class_protected_obj_xpm,
					class_obj_xpm, struct_private_obj_xpm, struct_protected_obj_xpm, struct_obj_xpm,  
					union_private_obj_xpm,
					union_protected_obj_xpm, union_obj_xpm, enum_private_obj_xpm, enum_protected_obj_xpm, enum_obj_xpm,
					normal_xpm, parameter_xpm, enum_member_obj_xpm, template_obj_xpm,
					functionpointer_obj_xpm, namespace_obj_xpm, property_xpm, property_var_xpm, define_var_xpm, define_fun_xpm,
					bookmark_xpm;
					

	static CstringConvert private_fun_rgba, protected_fun_rgba, public_fun_rgba, private_sub_rgba, protected_sub_rgba, public_sub_rgba,
			private_variable_array_rgba, protected_variable_array_rgba, public_variable_array_rgba, private_variable_rgba, alias_obj_rgba,
			protected_variable_rgba, public_variable_rgba, class_private_obj_rgba, class_protected_obj_rgba,
			class_obj_rgba, struct_private_obj_rgba, struct_protected_obj_rgba, struct_obj_rgba,  
			union_private_obj_rgba,
			union_protected_obj_rgba, union_obj_rgba, enum_private_obj_rgba, enum_protected_obj_rgba, enum_obj_rgba,
			normal_rgba, parameter_rgba, enum_member_obj_rgba, template_obj_rgba,
			functionpointer_obj_rgba, namespace_obj_rgba, property_rgba, property_var_rgba, define_var_rgba, define_fun_rgba,
			bookmark_rgba;


	static Ihandle* getIUPimage( char[] filePath )
	{
		try
		{
			scope file = new File( filePath, File.ReadExisting );
			int 		count, colorSN;
			bool 		bPixel, bColor;
			
			char[]		pixel;
			ColorUnit[]	color;
			
			foreach( line; new Lines!(char)(file) )
			{
				if( count++ == 0 )
				{
					if( line != "/* XPM */" ) return null;
				}
				
				if( line.length )
				{
					if( line == "/* pixels */" )
					{
						bPixel = true;
						bColor = false;
						continue;
					}
					else if( line == "/* colors */" )
					{
						bColor = true;
						bPixel = false;
						continue;
					}
					else
					{
						int rPos;
						if( line[0] == '"' )
						{
							rPos = Util.rindex( line, "\"" );

							if( bPixel )
							{
								foreach( char c; line[1..rPos] )
								{
									pixel ~= c;
								}
							}
							else if( bColor )
							{
								char[][] splitData = Util.split( line[1..rPos], " " );
								if( splitData.length == 3 )
								{
									ColorUnit _color;
									_color.index = splitData[0];
									_color.c = splitData[1];
									if( splitData[2] == "None" )
									{
										_color.value = "BGCOLOR";
									}
									else
									{
										int r = hexStringToByte( splitData[2][1..3] );
										int g = hexStringToByte( splitData[2][3..5] );
										int b = hexStringToByte( splitData[2][5..7] );

										_color.value = Integer.toString( r ) ~ " " ~ Integer.toString( g ) ~ " " ~ Integer.toString( b );
									}

									_color.sn = colorSN++;

									color ~= _color;
								}
							}
						}
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
						data ~= __color.sn;
						break;
					}
				}
			}

			Ihandle* image = IupImage( 16, 16, data.ptr );

			foreach( ColorUnit __color; color )
			{
				auto VALUE = new CstringConvert( __color.value );
				colorStrings ~= VALUE;
				IupSetAttribute( image, toStringz( Integer.toString( __color.sn ) ) , VALUE.toZ );
			}

			return image;

		}
		catch( Exception e )
		{
		}

		return null;
	}

	static this()
	{
		version(Windows) 
		{
			private_fun_xpm 				= getXpm( "icons/xpm/outline/fun_private.xpm");
			protected_fun_xpm 				= getXpm( "icons/xpm/outline/fun_protected.xpm" );
			public_fun_xpm 					= getXpm( "icons/xpm/outline/fun_public.xpm" );
			private_sub_xpm 				= getXpm( "icons/xpm/outline/sub_private.xpm");
			protected_sub_xpm 				= getXpm( "icons/xpm/outline/sub_protected.xpm" );
			public_sub_xpm 					= getXpm( "icons/xpm/outline/sub_public.xpm" );

			private_variable_array_xpm		= getXpm( "icons/xpm/outline/variable_array_private_obj.xpm" );
			protected_variable_array_xpm 	= getXpm( "icons/xpm/outline/variable_array_protected_obj.xpm" );
			public_variable_array_xpm		= getXpm( "icons/xpm/outline/variable_array_obj.xpm" );
			private_variable_xpm 			= getXpm( "icons/xpm/outline/variable_private_obj.xpm" );
			protected_variable_xpm 			= getXpm( "icons/xpm/outline/variable_protected_obj.xpm" );
			public_variable_xpm 			= getXpm( "icons/xpm/outline/variable_obj.xpm" );

			//class_private_obj_xpm 		= getXpm( "icons/xpm/outline/class_private_obj.xpm" );
			//class_protected_obj_xpm		= getXpm( "icons/xpm/outline/class_protected_obj.xpm" );
			class_obj_xpm 					= getXpm( "icons/xpm/outline/class_obj.xpm" );
			struct_private_obj_xpm 			= getXpm( "icons/xpm/outline/struct_private_obj.xpm" );
			struct_protected_obj_xpm 		= getXpm( "icons/xpm/outline/struct_protected_obj.xpm" );
			struct_obj_xpm 					= getXpm( "icons/xpm/outline/struct_obj.xpm" );
			union_private_obj_xpm 			= getXpm( "icons/xpm/outline/union_private_obj.xpm" );
			union_protected_obj_xpm 		= getXpm( "icons/xpm/outline/union_protected_obj.xpm" );
			union_obj_xpm 					= getXpm( "icons/xpm/outline/union_obj.xpm" );
			//enum_private_obj_xpm 			= getXpm( "icons/xpm/outline/enum_private_obj.xpm" );
			enum_protected_obj_xpm 			= getXpm( "icons/xpm/outline/enum_protected_obj.xpm" );
			enum_obj_xpm 					= getXpm( "icons/xpm/outline/enum_obj.xpm" );
			
			normal_xpm 						= getXpm( "icons/xpm/outline/normal.xpm" );
			//import_xpm 					= getXpm( "icons/xpm/import.xpm" );
			//autoWord_xpm 					= getXpm( "icons/xpm/autoword.xpm" );

			parameter_xpm					= getXpm( "icons/xpm/outline/parameter_obj.xpm" );
			enum_member_obj_xpm				= getXpm( "icons/xpm/outline/enum_member_obj.xpm" );

			alias_obj_xpm					= getXpm( "icons/xpm/outline/alias_obj.xpm" );
			//functionpointer_obj_xpm		= getXpm( "icons/xpm/functionpointer_obj.xpm" );
			namespace_obj_xpm				= getXpm( "icons/xpm/outline/namespace_obj.xpm" );

			property_xpm					= getXpm( "icons/xpm/outline/property_obj.xpm" );
			property_var_xpm				= getXpm( "icons/xpm/outline/property_var.xpm" );

			define_var_xpm					= getXpm( "icons/xpm/outline/define_var.xpm" );
			define_fun_xpm					= getXpm( "icons/xpm/outline/define_fun.xpm" );

			bookmark_xpm					= getXpm( "icons/xpm/bookmark.xpm" );
		}
		else
		{
			private_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_private.xpm");
			protected_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_protected.xpm" );
			public_fun_rgba 				= getRGBA( "icons/xpm/outline/fun_public.xpm" );
			private_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_private.xpm");
			protected_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_protected.xpm" );
			public_sub_rgba 				= getRGBA( "icons/xpm/outline/sub_public.xpm" );
			
			private_variable_array_rgba		= getRGBA( "icons/xpm/outline/variable_array_private_obj.xpm" );
			protected_variable_array_rgba 	= getRGBA( "icons/xpm/outline/variable_array_protected_obj.xpm" );
			public_variable_array_rgba		= getRGBA( "icons/xpm/outline/variable_array_obj.xpm" );
			private_variable_rgba 			= getRGBA( "icons/xpm/outline/variable_private_obj.xpm" );
			protected_variable_rgba 		= getRGBA( "icons/xpm/outline/variable_protected_obj.xpm" );
			public_variable_rgba 			= getRGBA( "icons/xpm/outline/variable_obj.xpm" );
			
			//class_private_obj_rgba 		= getRGBA( "icons/xpm/outline/class_private_obj.xpm" );
			//class_protected_obj_rgba		= getRGBA( "icons/xpm/outline/class_protected_obj.xpm" );
			class_obj_rgba 					= getRGBA( "icons/xpm/outline/class_obj.xpm" );
			struct_private_obj_rgba 		= getRGBA( "icons/xpm/outline/struct_private_obj.xpm" );
			struct_protected_obj_rgba 		= getRGBA( "icons/xpm/outline/struct_protected_obj.xpm" );
			struct_obj_rgba 				= getRGBA( "icons/xpm/outline/struct_obj.xpm" );
			union_private_obj_rgba			= getRGBA( "icons/xpm/outline/union_private_obj.xpm" );
			union_protected_obj_rgba		= getRGBA( "icons/xpm/outline/union_protected_obj.xpm" );
			union_obj_rgba					= getRGBA( "icons/xpm/outline/union_obj.xpm" );
			//enum_private_obj_rgba 		= getRGBA( "icons/xpmoutline//enum_private_obj.xpm" );
			enum_protected_obj_rgba			= getRGBA( "icons/xpm/outline/enum_protected_obj.xpm" );
			enum_obj_rgba					= getRGBA( "icons/xpm/outline/enum_obj.xpm" );
			
			normal_rgba						= getRGBA( "icons/xpm/outline/normal.xpm" );
			//import_rgba					= getRGBA( "icons/xpm/import.xpm" );
			//autoWord_rgba					= getRGBA( "icons/xpm/autoword.xpm" );
			
			parameter_rgba					= getRGBA( "icons/xpm/outline/parameter_obj.xpm" );
			enum_member_obj_rgba			= getRGBA( "icons/xpm/outline/enum_member_obj.xpm" );
			
			alias_obj_rgba					= getRGBA( "icons/xpm/outline/alias_obj.xpm" );
			//functionpointer_obj_rgba		= getRGBA( "icons/xpm/functionpointer_obj.xpm" );
			namespace_obj_rgba				= getRGBA( "icons/xpm/outline/namespace_obj.xpm" );
			
			property_rgba					= getRGBA( "icons/xpm/outline/property_obj.xpm" );
			property_var_rgba				= getRGBA( "icons/xpm/outline/property_var.xpm" );
			
			define_var_rgba					= getRGBA( "icons/xpm/outline/define_var.xpm" );
			define_fun_rgba					= getRGBA( "icons/xpm/outline/define_fun.xpm" );

			bookmark_rgba					= getRGBA( "icons/xpm/bookmark.xpm" );
		}
	}	
}