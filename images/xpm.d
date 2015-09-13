module images.xpm;

struct XPM
{
	private:
	import tango.io.device.File, tango.io.stream.Lines, Util = tango.text.Util;
	import tango.io.Stdout;
	import tango.stdc.stringz;

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
		catch
		{
			return null;
		}
	}

	public:
	/* XPM */
	static char*[] private_method_xpm, protected_method_xpm, public_method_xpm, private_variable_xpm, alias_obj_xpm,
					protected_variable_xpm, public_variable_xpm, class_private_obj_xpm, class_protected_obj_xpm,
					class_obj_xpm, struct_private_obj_xpm, struct_protected_obj_xpm, struct_obj_xpm, mixin_template_obj_xpm, 
					interface_private_obj_xpm, interface_protected_obj_xpm, interface_obj_xpm, union_private_obj_xpm,
					union_protected_obj_xpm, union_obj_xpm, enum_private_obj_xpm, enum_protected_obj_xpm, enum_obj_xpm,
					normal_xpm, import_xpm, autoWord_xpm, parameter_xpm, enum_member_obj_xpm, template_obj_xpm,
					functionpointer_obj_xpm, template_function_obj_xpm, template_class_obj_xpm, template_struct_obj_xpm,
					template_union_obj_xpm, template_interface_obj_xpm;

	//static char* bookmark_xpm, arrow_xpm, breakpoint_xpm;

	static this()
	{
		private_method_xpm 			= getXpm( "icons\\xpm\\function_private_obj.xpm");
		protected_method_xpm 		= getXpm( "icons\\xpm\\function_protected_obj.xpm" );

		public_method_xpm 			= getXpm( "icons\\xpm\\function_obj.xpm" );
		private_variable_xpm 		= getXpm( "icons\\xpm\\variable_private_obj.xpm" );
		protected_variable_xpm 		= getXpm( "icons\\xpm\\variable_protected_obj.xpm" );
		public_variable_xpm 		= getXpm( "icons\\xpm\\variable_obj.xpm" );
		class_private_obj_xpm 		= getXpm( "icons\\xpm\\class_private_obj.xpm" );
		class_protected_obj_xpm		= getXpm( "icons\\xpm\\class_protected_obj.xpm" );
		class_obj_xpm 				= getXpm( "icons\\xpm\\class_obj.xpm" );
		struct_private_obj_xpm 		= getXpm( "icons\\xpm\\struct_private_obj.xpm" );
		struct_protected_obj_xpm 	= getXpm( "icons\\xpm\\struct_protected_obj.xpm" );
		struct_obj_xpm 				= getXpm( "icons\\xpm\\struct_obj.xpm" );
		interface_private_obj_xpm 	= getXpm( "icons\\xpm\\interface_private_obj.xpm" );
		interface_protected_obj_xpm = getXpm( "icons\\xpm\\interface_protected_obj.xpm" );
		interface_obj_xpm 			= getXpm( "icons\\xpm\\interface_obj.xpm" );
		union_private_obj_xpm 		= getXpm( "icons\\xpm\\union_private_obj.xpm" );
		union_protected_obj_xpm 	= getXpm( "icons\\xpm\\union_protected_obj.xpm" );
		union_obj_xpm 				= getXpm( "icons\\xpm\\union_obj.xpm" );
		enum_private_obj_xpm 		= getXpm( "icons\\xpm\\enum_private_obj.xpm" );
		enum_protected_obj_xpm 		= getXpm( "icons\\xpm\\enum_protected_obj.xpm" );
		enum_obj_xpm 				= getXpm( "icons\\xpm\\enum_obj.xpm" );
		
		normal_xpm 					= getXpm( "icons\\xpm\\normal.xpm" );
		import_xpm 					= getXpm( "icons\\xpm\\import.xpm" );
		autoWord_xpm 				= getXpm( "icons\\xpm\\autoword.xpm" );

		parameter_xpm				= getXpm( "icons\\xpm\\parameter_obj.xpm" );
		enum_member_obj_xpm			= getXpm( "icons\\xpm\\enum_member_obj.xpm" );
		template_obj_xpm			= getXpm( "icons\\xpm\\template_obj.xpm" );

		alias_obj_xpm				= getXpm( "icons\\xpm\\alias_obj.xpm" );
		mixin_template_obj_xpm		= getXpm( "icons\\xpm\\mixin_template_obj.xpm" );
		functionpointer_obj_xpm		= getXpm( "icons\\xpm\\functionpointer_obj.xpm" );
		/+
		template_function_obj_xpm	= getXpm( "icons\\xpm\\template_function_obj.xpm" );
		template_class_obj_xpm		= getXpm( "icons\\xpm\\template_class_obj.xpm" );
		template_struct_obj_xpm		= getXpm( "icons\\xpm\\template_struct_obj.xpm" );
		template_union_obj_xpm		= getXpm( "icons\\xpm\\template_union_obj.xpm" );
		template_interface_obj_xpm	= getXpm( "icons\\xpm\\template_interface_obj.xpm" );


		bookmark_xpm 				= getXpm( "icons\\xpm\\bookmark_obj.xpm");
		arrow_xpm					= getXpm( "icons\\xpm\\arrow.xpm");
		breakpoint_xpm				= getXpm( "icons\\xpm\\breakpoint.xpm");
		+/
	}
}