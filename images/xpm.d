module images.xpm;

struct XPM
{
	private:
	import iup.iup;
	
	import tango.io.device.File, tango.io.stream.Lines, Util = tango.text.Util, Integer = tango.text.convert.Integer, tools;
	import tango.stdc.stringz;
	import tango.io.Stdout;

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
					class_obj_xpm, struct_private_obj_xpm, struct_protected_obj_xpm, struct_obj_xpm, mixin_template_obj_xpm, 
					interface_private_obj_xpm, interface_protected_obj_xpm, interface_obj_xpm, union_private_obj_xpm,
					union_protected_obj_xpm, union_obj_xpm, enum_private_obj_xpm, enum_protected_obj_xpm, enum_obj_xpm,
					normal_xpm, import_xpm, autoWord_xpm, parameter_xpm, enum_member_obj_xpm, template_obj_xpm,
					functionpointer_obj_xpm, namespace_obj_xpm, property_xpm, property_var_xpm, define_var_xpm, define_fun_xpm;

	/+
	static ubyte[] private_method_rgba, protected_method_rgba, public_method_rgba, private_variable_rgba, alias_obj_rgba,
					protected_variable_rgba, public_variable_rgba, class_private_obj_rgba, class_protected_obj_rgba,
					class_obj_rgba, struct_private_obj_rgba, struct_protected_obj_rgba, struct_obj_rgba, mixin_template_obj_rgba, 
					interface_private_obj_rgba, interface_protected_obj_rgba, interface_obj_rgba, union_private_obj_rgba,
					union_protected_obj_rgba, union_obj_rgba, enum_private_obj_rgba, enum_protected_obj_rgba, enum_obj_rgba,
					normal_rgba, import_rgba, autoWord_rgba, parameter_rgba, enum_member_obj_rgba, template_obj_rgba,
					functionpointer_obj_rgba, template_function_obj_rgba, template_class_obj_rgba, template_struct_obj_rgba,
					template_union_obj_rgba, template_interface_obj_rgba;
	+/

	static CstringConvert private_fun_rgba, protected_fun_rgba, public_fun_rgba, private_sub_rgba, protected_sub_rgba, public_sub_rgba,
		private_variable_array_rgba, protected_variable_array_rgba, public_variable_array_rgba, private_variable_rgba, alias_obj_rgba,
		protected_variable_rgba, public_variable_rgba, class_private_obj_rgba, class_protected_obj_rgba,
		class_obj_rgba, struct_private_obj_rgba, struct_protected_obj_rgba, struct_obj_rgba, mixin_template_obj_rgba, 
		interface_private_obj_rgba, interface_protected_obj_rgba, interface_obj_rgba, union_private_obj_rgba,
		union_protected_obj_rgba, union_obj_rgba, enum_private_obj_rgba, enum_protected_obj_rgba, enum_obj_rgba,
		normal_rgba, import_rgba, autoWord_rgba, parameter_rgba, enum_member_obj_rgba, template_obj_rgba,
		functionpointer_obj_rgba, namespace_obj_rgba, property_rgba, property_var_rgba, define_var_rgba, define_fun_rgba;

	static this()
	{
		version( Windows) 
		{
			private_fun_xpm 			= getXpm( "icons/xpm/fun_private.xpm");
			protected_fun_xpm 			= getXpm( "icons/xpm/fun_protected.xpm" );
			public_fun_xpm 				= getXpm( "icons/xpm/fun_public.xpm" );
			private_sub_xpm 			= getXpm( "icons/xpm/sub_private.xpm");
			protected_sub_xpm 			= getXpm( "icons/xpm/sub_protected.xpm" );
			public_sub_xpm 				= getXpm( "icons/xpm/sub_public.xpm" );

			private_variable_array_xpm	= getXpm( "icons/xpm/variable_array_private_obj.xpm" );
			protected_variable_array_xpm = getXpm( "icons/xpm/variable_array_protected_obj.xpm" );
			public_variable_array_xpm	= getXpm( "icons/xpm/variable_array_obj.xpm" );
			private_variable_xpm 		= getXpm( "icons/xpm/variable_private_obj.xpm" );
			protected_variable_xpm 		= getXpm( "icons/xpm/variable_protected_obj.xpm" );
			public_variable_xpm 		= getXpm( "icons/xpm/variable_obj.xpm" );

			class_private_obj_xpm 		= getXpm( "icons/xpm/class_private_obj.xpm" );
			class_protected_obj_xpm		= getXpm( "icons/xpm/class_protected_obj.xpm" );
			class_obj_xpm 				= getXpm( "icons/xpm/class_obj.xpm" );
			struct_private_obj_xpm 		= getXpm( "icons/xpm/struct_private_obj.xpm" );
			struct_protected_obj_xpm 	= getXpm( "icons/xpm/struct_protected_obj.xpm" );
			struct_obj_xpm 				= getXpm( "icons/xpm/struct_obj.xpm" );
			interface_private_obj_xpm 	= getXpm( "icons/xpm/interface_private_obj.xpm" );
			interface_protected_obj_xpm = getXpm( "icons/xpm/interface_protected_obj.xpm" );
			interface_obj_xpm 			= getXpm( "icons/xpm/interface_obj.xpm" );
			union_private_obj_xpm 		= getXpm( "icons/xpm/union_private_obj.xpm" );
			union_protected_obj_xpm 	= getXpm( "icons/xpm/union_protected_obj.xpm" );
			union_obj_xpm 				= getXpm( "icons/xpm/union_obj.xpm" );
			enum_private_obj_xpm 		= getXpm( "icons/xpm/enum_private_obj.xpm" );
			enum_protected_obj_xpm 		= getXpm( "icons/xpm/enum_protected_obj.xpm" );
			enum_obj_xpm 				= getXpm( "icons/xpm/enum_obj.xpm" );
			
			normal_xpm 					= getXpm( "icons/xpm/normal.xpm" );
			import_xpm 					= getXpm( "icons/xpm/import.xpm" );
			autoWord_xpm 				= getXpm( "icons/xpm/autoword.xpm" );

			parameter_xpm				= getXpm( "icons/xpm/parameter_obj.xpm" );
			enum_member_obj_xpm			= getXpm( "icons/xpm/enum_member_obj.xpm" );
			//template_obj_xpm			= getXpm( "icons/xpm/template_obj.xpm" );

			alias_obj_xpm				= getXpm( "icons/xpm/alias_obj.xpm" );
			//mixin_template_obj_xpm		= getXpm( "icons/xpm/mixin_template_obj.xpm" );
			functionpointer_obj_xpm		= getXpm( "icons/xpm/functionpointer_obj.xpm" );
			namespace_obj_xpm			= getXpm( "icons/xpm/namespace_obj.xpm" );

			property_xpm				= getXpm( "icons/xpm/property_obj.xpm" );
			property_var_xpm			= getXpm( "icons/xpm/property_var.xpm" );

			define_var_xpm				= getXpm( "icons/xpm/define_var.xpm" );
			define_fun_xpm				= getXpm( "icons/xpm/define_fun.xpm" );
		}
		else
		{
			private_fun_rgba 			= getRGBA( "icons/xpm/fun_private.xpm");
			protected_fun_rgba 			= getRGBA( "icons/xpm/fun_protected.xpm" );
			public_fun_rgba 				= getRGBA( "icons/xpm/fun_public.xpm" );
			private_sub_rgba 			= getRGBA( "icons/xpm/sub_private.xpm");
			protected_sub_rgba 			= getRGBA( "icons/xpm/sub_protected.xpm" );
			public_sub_rgba 				= getRGBA( "icons/xpm/sub_public.xpm" );
			
			private_variable_array_rgba	= getRGBA( "icons/xpm/variable_array_private_obj.xpm" );
			protected_variable_array_rgba = getRGBA( "icons/xpm/variable_array_protected_obj.xpm" );
			public_variable_array_rgba	= getRGBA( "icons/xpm/variable_array_obj.xpm" );
			private_variable_rgba 		= getRGBA( "icons/xpm/variable_private_obj.xpm" );
			protected_variable_rgba 		= getRGBA( "icons/xpm/variable_protected_obj.xpm" );
			public_variable_rgba 		= getRGBA( "icons/xpm/variable_obj.xpm" );
			
			class_private_obj_rgba 		= getRGBA( "icons/xpm/class_private_obj.xpm" );
			class_protected_obj_rgba		= getRGBA( "icons/xpm/class_protected_obj.xpm" );
			class_obj_rgba 				= getRGBA( "icons/xpm/class_obj.xpm" );
			struct_private_obj_rgba 		= getRGBA( "icons/xpm/struct_private_obj.xpm" );
			struct_protected_obj_rgba 	= getRGBA( "icons/xpm/struct_protected_obj.xpm" );
			struct_obj_rgba 				= getRGBA( "icons/xpm/struct_obj.xpm" );
			interface_private_obj_rgba 	= getRGBA( "icons/xpm/interface_private_obj.xpm" );
			interface_protected_obj_rgba = getRGBA( "icons/xpm/interface_protected_obj.xpm" );
			interface_obj_rgba 			= getRGBA( "icons/xpm/interface_obj.xpm" );
			union_private_obj_rgba	= getRGBA( "icons/xpm/union_private_obj.xpm" );
			union_protected_obj_rgba	= getRGBA( "icons/xpm/union_protected_obj.xpm" );
			union_obj_rgba				= getRGBA( "icons/xpm/union_obj.xpm" );
			enum_private_obj_rgba 		= getRGBA( "icons/xpm/enum_private_obj.xpm" );
			enum_protected_obj_rgba		= getRGBA( "icons/xpm/enum_protected_obj.xpm" );
			enum_obj_rgba				= getRGBA( "icons/xpm/enum_obj.xpm" );
			
			normal_rgba					= getRGBA( "icons/xpm/normal.xpm" );
			import_rgba					= getRGBA( "icons/xpm/import.xpm" );
			autoWord_rgba				= getRGBA( "icons/xpm/autoword.xpm" );
			
			parameter_rgba			= getRGBA( "icons/xpm/parameter_obj.xpm" );
			enum_member_obj_rgba		= getRGBA( "icons/xpm/enum_member_obj.xpm" );
			//template_obj_xpm			= getRGBA( "icons/xpm/template_obj.xpm" );
			
			alias_obj_rgba		= getRGBA( "icons/xpm/alias_obj.xpm" );
			//mixin_template_obj_xpm		= getRGBA( "icons/xpm/mixin_template_obj.xpm" );
			functionpointer_obj_rgba	= getRGBA( "icons/xpm/functionpointer_obj.xpm" );
			namespace_obj_rgba			= getRGBA( "icons/xpm/namespace_obj.xpm" );
			
			property_rgba				= getRGBA( "icons/xpm/property_obj.xpm" );
			property_var_rgba			= getRGBA( "icons/xpm/property_var.xpm" );
			
			define_var_rgba				= getRGBA( "icons/xpm/define_var.xpm" );
			define_fun_rgba				= getRGBA( "icons/xpm/define_fun.xpm" );
		}
	}

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
									_color.index = splitData[0].dup;
									_color.c = splitData[1].dup;
									if( splitData[2] == "None" )
									{
										_color.value = "BGCOLOR".dup;
									}
									else
									{
										int r = hexStringToByte( splitData[2][1..3] );
										int g = hexStringToByte( splitData[2][3..5] );
										int b = hexStringToByte( splitData[2][5..7] );

										_color.value = ( Integer.toString( r ) ~ " " ~ Integer.toString( g ) ~ " " ~ Integer.toString( b ) ).dup;
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
				foreach( ColorUnit _color; color )
				{
					if( c == _color.index[0] )
					{
						data ~= _color.sn;
						break;
					}
				}
			}

			Ihandle* image = IupImage( 16, 16, data.ptr );
			foreach( _color; color )
			{
				IupSetAttribute( image, ( new CstringConvert( Integer.toString( _color.sn ).dup ) ).toZ, ( new CstringConvert( _color.value ) ).toZ );
			}

			return image;

		}
		catch( Exception e )
		{
		}

		return null;

	}
}