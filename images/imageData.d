module images.imageData;

private import iup.iup;

/+
import tango.io.device.File;
import tango.io.stream.Lines;
import tango.stdc.stringz;
import Util = tango.text.Util;
import Integer = tango.text.convert.Integer;


void load_all_images_image()
{
	Ihandle* icon_bas = loadLed( "icons\\bas.led" );
	IupSetHandle( "icon_bas", icon_bas );

	Ihandle* icon_bi = loadLed( "icons\\bi.led" );
	IupSetHandle( "icon_bi", icon_bi );

	Ihandle* icon_add = loadLed( "icons\\add_obj.led" );
	IupSetHandle( "icon_add", icon_add );

	Ihandle* icon_compile = loadLed( "icons\\compile.led" );
	IupSetHandle( "icon_compile", icon_compile );

	Ihandle* icon_copy = loadLed( "icons\\copy_edit1.led" );
	IupSetHandle( "icon_copy", icon_copy );

	Ihandle* icon_cut = loadLed( "icons\\cut_edit.led" );
	IupSetHandle( "icon_cut", icon_cut );

	Ihandle* icon_delete = loadLed( "icons\\delete_obj.led" );
	IupSetHandle( "icon_delete", icon_delete );

	Ihandle* icon_document = loadLed( "icons\\file_obj.led" );
	IupSetHandle( "icon_document", icon_document );

	Ihandle* icon_goto = loadLed( "icons\\goto_obj.led" );
	IupSetHandle( "icon_goto", icon_goto );

	Ihandle* icon_markclear = loadLed( "icons\\mark_clear.led" );
	IupSetHandle( "icon_markclear", icon_markclear );

	Ihandle* icon_marknext = loadLed( "icons\\mark_next.led" );
	IupSetHandle( "icon_marknext", icon_marknext );

	Ihandle* icon_markprev = loadLed( "icons\\mark_prev.led" );
	IupSetHandle( "icon_markprev", icon_markprev );

	Ihandle* icon_mark = loadLed( "icons\\mark_toggle.led" );
	IupSetHandle( "icon_mark", icon_mark );

	Ihandle* icon_newfile = loadLed( "icons\\newfile.led" );
	IupSetHandle( "icon_newfile", icon_newfile );

	Ihandle* icon_newfolder = loadLed( "icons\\newfolder_wiz.led" );
	IupSetHandle( "icon_newfolder", icon_newfolder );

	Ihandle* icon_newprj = loadLed( "icons\\newprj_wiz.led" );
	IupSetHandle( "icon_newprj", icon_newprj );

	Ihandle* icon_downarrow = loadLed( "icons\\next_nav.led" );
	IupSetHandle( "icon_downarrow", icon_downarrow );

	Ihandle* icon_openfile = loadLed( "icons\\open_edit.led" );
	IupSetHandle( "icon_openfile", icon_openfile );

	Ihandle* icon_openprj = loadLed( "icons\\openprj.led" );
	IupSetHandle( "icon_openprj", icon_openprj );

	Ihandle* icon_outline = loadLed( "icons\\outline_co.led" );
	IupSetHandle( "icon_outline", icon_outline );

	Ihandle* icon_packageexplorer = loadLed( "icons\\package_explorer.led" );
	IupSetHandle( "icon_packageexplorer", icon_packageexplorer );

	Ihandle* icon_paste = loadLed( "icons\\paste_edit.led" );
	IupSetHandle( "icon_paste", icon_paste );

	Ihandle* icon_uparrow = loadLed( "icons\\prev_nav.led" );
	IupSetHandle( "icon_uparrow", icon_uparrow );

	Ihandle* icon_quickrun = loadLed( "icons\\quickrun.led" );
	IupSetHandle( "icon_quickrun", icon_quickrun );

	Ihandle* icon_rebuild = loadLed( "icons\\rebuild.led" );
	IupSetHandle( "icon_rebuild", icon_rebuild );

	Ihandle* icon_redo = loadLed( "icons\\redo_edit.led" );
	IupSetHandle( "icon_redo", icon_redo );

	Ihandle* icon_run = loadLed( "icons\\run.led" );
	IupSetHandle( "icon_run", icon_run );

	Ihandle* icon_save = loadLed( "icons\\save_edit.led" );
	IupSetHandle( "icon_save", icon_save );

	Ihandle* icon_saveall = loadLed( "icons\\saveall_edit.led" );
	IupSetHandle( "icon_saveall", icon_saveall );

	Ihandle* icon_saveas = loadLed( "icons\\saveas.led" );
	IupSetHandle( "icon_saveas", icon_saveas );

	Ihandle* icon_selectall = loadLed( "icons\\selectall.led" );
	IupSetHandle( "icon_selectall", icon_selectall );

	Ihandle* undo = loadLed( "icons\\undo_edit.led" );
	IupSetHandle( "icon_undo", undo );
}


struct ColorIndexUint
{
	char[] index, colorValue;
}


Ihandle* loadLed( char[] filePath )
{
	Ihandle*			image;
	
	try
	{
		ColorIndexUint[]	colorIndexes;
		bool				bReadColorIndexes, bReadData;
		int					width, height;
		ubyte[]				imgData;
		char[]				_imgData;
		
		scope file = new File( filePath, File.ReadExisting );
		
		int count;
		foreach( line; new Lines!(char)(file) )
		{
			if( line.length )
			{
				if( line[0] == ')' ) break;
				
				if( bReadColorIndexes )
				{
					char[][] data = Util.split( line, "=" );
					if( data.length == 2 )
					{
						// double quote
						int firstDoubleQuote = Util.index( data[1], "\"" );
						int lastDoubleQuote = Util.rindex( data[1], "\"" );
						char[] _data1 = data[1][firstDoubleQuote+1..lastDoubleQuote];
						
						ColorIndexUint temp = [ Util.trim(data[0]), _data1 ];
						colorIndexes ~= temp;
					}
				}
				else if( bReadData )
				{
					//if( filePath == "icons\\compile.led" ) IupMessage( " ", toStringz(line) );
					_imgData ~= line;
					/*				
					foreach( char[] s; Util.split( line, "," ) )
					{
						char[] _s = Util.trim( s ).dup;
						if( _s.length )
						{
							imgData ~= cast(ubyte) Integer.atoi( _s.dup );
							//if( filePath == "icons\\compile.led" ) IupMessage( " ", toStringz(_s) );
						}
					}
					*/
				}

				if( line == "[" )
					bReadColorIndexes = true;
				else if( line == "]" )
					bReadColorIndexes = false;
				else if( line[0] == '(' )
				{
					int firstComma = Util.index( line, "," );
					width = Integer.atoi( line[1..firstComma] );

					int lastComma = Util.rindex( line, "," );
					height = Integer.atoi( Util.trim(line[firstComma+1..lastComma]) );

					bReadData = true;
				}
			}
		}

		if( _imgData.length )
		{
			//if( filePath == "icons\\build.led" ) IupMessage("",toStringz( Integer.toString(imgData.length ) ));
			//IupMessage(toStringz(filePath),toStringz(_imgData));
			foreach( char[] s; Util.split( _imgData.dup, "," ) )
			{
				//IupMessage(toStringz(filePath),toStringz(">"~s~"<"));
				//IupMessage(toStringz(filePath),toStringz(">"~Util.trim( s )~"<"));
				
				ubyte b = Integer.atoi(Util.trim( s ));
				imgData ~= b;
				/*
				if( b >
				if( _s.length )
				{
					imgData ~= cast(ubyte) Integer.atoi( _s.dup );
					//if( filePath == "icons\\compile.led" ) IupMessage( " ", toStringz(_s) );
				}
				*/
			}

		
			image = IupImage( width, height, imgData.ptr );
			foreach( ColorIndexUint c; colorIndexes )
			{
				//IupMessage(toStringz(filePath), toStringz(c.index ~ ":" ~ c.colorValue) );

				IupSetAttribute( image, toStringz(c.index), toStringz(c.colorValue) );
			}
		}
	}
	catch( Exception e )
	{
		IupMessage( "", toStringz( e.toString ) );
	}
	
	return image;
}
+/
Ihandle* load_image_mark_clear()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 2, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 1, 1, 2, 5, 5, 5, 5, 5, 5,
    5, 1, 1, 1, 2, 5, 1, 1, 2, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 2, 1, 1, 1, 1, 2, 2, 5, 5, 5, 4, 5, 5, 5,
    5, 5, 5, 2, 1, 1, 1, 2, 5, 5, 5, 4, 5, 5, 5, 5,
    5, 5, 5, 2, 1, 1, 1, 1, 2, 5, 4, 4, 5, 5, 5, 5,
    5, 5, 5, 1, 1, 2, 2, 1, 1, 4, 3, 3, 4, 5, 5, 5,
    5, 5, 1, 1, 2, 2, 5, 5, 1, 1, 3, 3, 4, 5, 5, 5,
    5, 5, 1, 1, 2, 5, 5, 4, 3, 1, 3, 0, 4, 5, 5, 5,
    5, 5, 1, 2, 5, 5, 4, 4, 3, 3, 0, 0, 0, 4, 4, 5,
    5, 5, 2, 2, 5, 4, 5, 5, 4, 0, 0, 0, 0, 3, 3, 4,
    5, 5, 2, 5, 4, 5, 5, 5, 4, 0, 0, 0, 3, 3, 3, 4,
    5, 5, 5, 4, 5, 5, 5, 5, 4, 0, 0, 3, 3, 3, 4, 5,
    5, 5, 4, 5, 5, 5, 5, 5, 5, 4, 4, 3, 3, 4, 5, 5,
    5, 4, 5, 5, 5, 5, 5, 5, 5, 5, 2, 4, 4, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "0 0 128");
  IupSetAttribute(image, "1", "128 0 0");
  IupSetAttribute(image, "2", "168 160 152");
  IupSetAttribute(image, "3", "0 0 255");
  IupSetAttribute(image, "4", "24 48 80");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "0 0 0");
  IupSetAttribute(image, "7", "0 0 0");

  return image;
}

Ihandle* load_image_cut_edit()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 1, 7, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 5, 7, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 4, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 7, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 3, 5, 1, 6, 7, 4, 5, 6,
    6, 6, 4, 4, 4, 6, 6, 6, 1, 5, 1, 5, 4, 7, 3, 6,
    6, 4, 7, 6, 7, 4, 6, 4, 0, 5, 5, 7, 6, 6, 6, 6,
    6, 2, 6, 6, 7, 2, 4, 4, 5, 1, 3, 6, 6, 6, 6, 6,
    6, 2, 7, 7, 7, 2, 7, 1, 5, 7, 6, 6, 6, 6, 6, 6,
    6, 6, 5, 5, 5, 6, 6, 7, 5, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 7, 4, 4, 4, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 4, 7, 6, 7, 4, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 7, 2, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 2, 7, 7, 7, 2, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "20 50 92");
  IupSetAttribute(image, "1", "156 166 188");
  IupSetAttribute(image, "2", "58 118 168");
  IupSetAttribute(image, "3", "220 218 228");
  IupSetAttribute(image, "4", "116 140 172");
  IupSetAttribute(image, "5", "55 97 136");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "177 195 212");

  return image;
}

Ihandle* load_image_quickrun()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5,
    5, 7, 6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 2, 5, 7, 5,
    5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5,
    5, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 5,
    5, 3, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 3, 5,
    5, 3, 0, 0, 0, 5, 0, 0, 0, 7, 3, 3, 3, 3, 2, 5,
    5, 3, 7, 7, 5, 7, 7, 7, 3, 6, 1, 1, 1, 6, 2, 5,
    5, 3, 7, 7, 5, 7, 7, 6, 6, 1, 2, 2, 1, 1, 6, 5,
    5, 3, 3, 5, 3, 3, 3, 6, 4, 1, 5, 5, 2, 1, 1, 5,
    5, 3, 3, 5, 3, 3, 3, 2, 4, 4, 2, 5, 2, 4, 4, 5,
    5, 3, 6, 6, 6, 6, 6, 2, 4, 4, 5, 2, 4, 4, 1, 5,
    5, 3, 3, 3, 3, 3, 2, 2, 6, 4, 6, 4, 4, 4, 6, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 1, 4, 1, 6, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "52 77 121");
  IupSetAttribute(image, "1", "106 170 122");
  IupSetAttribute(image, "2", "191 195 176");
  IupSetAttribute(image, "3", "150 145 138");
  IupSetAttribute(image, "4", "75 148 85");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "153 184 179");
  IupSetAttribute(image, "7", "93 131 179");

  return image;
}

Ihandle* load_image_package_explorer()
{
  ubyte imgdata[] = [
    3, 1, 1, 6, 7, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 4, 4, 4, 4, 2, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 4, 5, 4, 5, 2, 3, 3, 1,
    3, 1, 3, 3, 0, 2, 2, 7, 4, 4, 4, 4, 2, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 4, 5, 4, 5, 2, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 4, 2, 2, 2, 2, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 4, 4, 4, 4, 2, 3, 3, 1,
    3, 1, 3, 3, 2, 3, 3, 3, 4, 5, 4, 5, 2, 3, 3, 1,
    3, 1, 3, 3, 0, 2, 2, 7, 4, 4, 4, 4, 2, 3, 3, 1,
    3, 1, 3, 3, 7, 3, 3, 3, 4, 5, 4, 5, 2, 3, 3, 1,
    3, 1, 3, 3, 7, 3, 3, 3, 4, 2, 2, 2, 2, 3, 3, 1,
    3, 1, 3, 3, 7, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1,
    3, 1, 1, 6, 7, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "4 2 132");
  IupSetAttribute(image, "1", "188 190 156");
  IupSetAttribute(image, "2", "78 62 74");
  IupSetAttribute(image, "3", "BGCOLOR");
  IupSetAttribute(image, "4", "124 94 60");
  IupSetAttribute(image, "5", "252 222 124");
  IupSetAttribute(image, "6", "220 222 188");
  IupSetAttribute(image, "7", "92 94 92");

  return image;
}

Ihandle* load_image_next_nav()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 7, 6, 6, 6, 6, 7, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 7, 6, 6, 6, 6, 7, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 7, 3, 3, 3, 3, 7, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 2, 3, 3, 3, 3, 2, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 2, 3, 3, 3, 3, 2, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 2, 5, 5, 5, 5, 2, 6, 6, 6, 6, 6,
    6, 6, 4, 2, 4, 2, 5, 5, 5, 5, 2, 4, 4, 2, 6, 6,
    6, 6, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 6, 6,
    6, 6, 6, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 6, 6, 6,
    6, 6, 6, 6, 4, 1, 1, 1, 1, 1, 1, 4, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 0, 1, 1, 1, 1, 0, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 0, 1, 1, 0, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 0, 0, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "167 109 20");
  IupSetAttribute(image, "1", "252 226 146");
  IupSetAttribute(image, "2", "182 124 20");
  IupSetAttribute(image, "3", "252 246 209");
  IupSetAttribute(image, "4", "175 116 20");
  IupSetAttribute(image, "5", "252 236 180");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "188 132 20");

  return image;
}

Ihandle* load_image_file_obj()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 7, 7, 7, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 6, 2, 7, 7, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 1, 6, 2, 7, 7, 7,
    7, 7, 7, 2, 7, 3, 3, 4, 4, 7, 1, 1, 6, 2, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2, 7, 7,
    7, 7, 7, 2, 7, 3, 3, 3, 3, 4, 4, 4, 7, 2, 7, 7,
    7, 7, 7, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 7, 7,
    7, 7, 7, 0, 5, 3, 3, 3, 3, 4, 4, 4, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 3, 3, 3, 3, 4, 4, 4, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 3, 3, 3, 4, 4, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "131 114 60");
  IupSetAttribute(image, "1", "223 194 129");
  IupSetAttribute(image, "2", "173 135 52");
  IupSetAttribute(image, "3", "137 157 192");
  IupSetAttribute(image, "4", "107 130 172");
  IupSetAttribute(image, "5", "228 236 250");
  IupSetAttribute(image, "6", "212 178 108");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_outline_co()
{
  ubyte imgdata[] = [
    4, 4, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 5, 6, 6, 6, 6, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 5, 2, 2, 2, 2, 5, 4, 7, 7, 7, 7, 7, 7, 4,
    4, 4, 5, 3, 3, 3, 3, 5, 4, 0, 0, 0, 0, 0, 0, 4,
    4, 4, 5, 1, 1, 1, 1, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 4, 0, 4, 5, 0, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 4, 4, 4, 4,
    4, 4, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 5, 6, 6, 6, 6, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 5, 2, 2, 2, 2, 5, 4, 7, 7, 7, 7, 7, 7, 4,
    4, 4, 5, 3, 3, 3, 3, 5, 4, 0, 0, 0, 0, 0, 0, 4,
    4, 4, 5, 1, 1, 1, 1, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "20 86 140");
  IupSetAttribute(image, "1", "148 210 244");
  IupSetAttribute(image, "2", "204 238 252");
  IupSetAttribute(image, "3", "180 224 252");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "20 106 172");
  IupSetAttribute(image, "6", "228 246 252");
  IupSetAttribute(image, "7", "196 234 252");

  return image;
}

Ihandle* load_image_newfile()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 2, 3, 6, 6, 3, 7, 3, 6, 3, 7,
    6, 6, 6, 3, 3, 2, 3, 3, 3, 3, 3, 3, 6, 6, 6, 3,
    6, 6, 6, 3, 6, 6, 2, 3, 0, 1, 3, 3, 3, 7, 3, 6,
    6, 6, 6, 3, 6, 6, 6, 5, 0, 0, 1, 3, 3, 3, 6, 6,
    6, 6, 6, 3, 6, 4, 7, 1, 5, 0, 0, 1, 3, 3, 6, 6,
    6, 6, 6, 7, 6, 6, 6, 6, 6, 5, 0, 0, 1, 7, 6, 6,
    6, 6, 6, 7, 6, 4, 4, 4, 4, 7, 5, 0, 0, 1, 6, 6,
    6, 6, 6, 7, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 1, 6,
    6, 6, 6, 7, 5, 4, 4, 4, 4, 7, 1, 1, 5, 0, 0, 1,
    6, 6, 6, 7, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 4,
    6, 6, 6, 1, 5, 4, 4, 4, 4, 7, 1, 1, 5, 1, 6, 6,
    6, 6, 6, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 6, 6,
    6, 6, 6, 1, 5, 4, 4, 7, 1, 1, 5, 5, 5, 1, 6, 6,
    6, 6, 6, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 6, 6,
    6, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "4 2 4");
  IupSetAttribute(image, "1", "137 152 182");
  IupSetAttribute(image, "2", "228 202 140");
  IupSetAttribute(image, "3", "201 179 122");
  IupSetAttribute(image, "4", "165 180 201");
  IupSetAttribute(image, "5", "226 236 249");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "162 165 158");

  return image;
}

Ihandle* load_image_selectall()
{
  ubyte imgdata[] = [
    7, 0, 0, 0, 7, 7, 0, 0, 0, 7, 7, 0, 0, 0, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 0, 7, 2, 2, 2, 2, 2, 2, 7, 7, 7, 7, 0, 7, 7,
    7, 0, 7, 2, 7, 7, 7, 7, 1, 2, 7, 7, 7, 0, 7, 7,
    7, 0, 7, 2, 7, 7, 7, 7, 1, 1, 2, 7, 7, 0, 7, 7,
    7, 7, 7, 2, 7, 4, 4, 7, 6, 1, 1, 2, 7, 7, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 7, 2, 7, 7, 7, 7,
    7, 0, 7, 2, 7, 4, 4, 4, 4, 4, 7, 2, 7, 0, 7, 7,
    7, 0, 7, 5, 3, 7, 3, 7, 3, 7, 3, 5, 7, 0, 7, 7,
    7, 0, 7, 5, 3, 4, 4, 4, 4, 4, 3, 5, 7, 0, 7, 7,
    7, 7, 7, 5, 3, 3, 3, 3, 3, 3, 3, 5, 7, 7, 7, 7,
    7, 7, 7, 5, 3, 3, 3, 3, 3, 3, 3, 5, 7, 7, 7, 7,
    7, 0, 7, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 0, 7, 7,
    7, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 7, 7,
    7, 0, 0, 0, 7, 7, 0, 0, 0, 7, 7, 0, 0, 0, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "92 94 92");
  IupSetAttribute(image, "1", "215 183 114");
  IupSetAttribute(image, "2", "174 143 63");
  IupSetAttribute(image, "3", "228 234 252");
  IupSetAttribute(image, "4", "149 167 199");
  IupSetAttribute(image, "5", "131 120 76");
  IupSetAttribute(image, "6", "228 202 140");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_undo_edit()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 6, 1,
    4, 4, 4, 4, 4, 4, 4, 6, 6, 4, 4, 4, 4, 3, 2, 6,
    4, 4, 4, 4, 4, 4, 6, 4, 6, 4, 4, 4, 4, 6, 4, 6,
    4, 4, 4, 4, 4, 6, 4, 4, 6, 4, 4, 4, 6, 2, 4, 6,
    4, 4, 4, 4, 6, 4, 4, 4, 6, 1, 6, 6, 5, 4, 2, 3,
    4, 4, 4, 6, 4, 4, 4, 4, 4, 5, 5, 4, 4, 4, 5, 3,
    4, 4, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 1,
    4, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 6, 4,
    4, 4, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 1, 4,
    4, 4, 4, 0, 2, 2, 2, 2, 2, 2, 2, 1, 0, 1, 4, 4,
    4, 4, 4, 4, 0, 2, 2, 2, 0, 0, 3, 1, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 0, 2, 2, 0, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 0, 2, 0, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "171 112 20");
  IupSetAttribute(image, "1", "210 192 137");
  IupSetAttribute(image, "2", "250 227 150");
  IupSetAttribute(image, "3", "193 166 105");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "228 212 148");
  IupSetAttribute(image, "6", "187 130 20");
  IupSetAttribute(image, "7", "252 238 168");

  return image;
}

Ihandle* load_image_newfolder_wiz()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 7, 7, 7,
    7, 7, 7, 4, 4, 4, 4, 7, 7, 7, 7, 3, 7, 3, 7, 7,
    7, 7, 0, 7, 7, 7, 7, 0, 7, 7, 3, 3, 7, 3, 3, 7,
    7, 4, 2, 2, 2, 6, 1, 1, 5, 4, 2, 2, 2, 2, 2, 4,
    7, 4, 2, 2, 2, 2, 2, 2, 2, 7, 0, 0, 2, 0, 0, 7,
    7, 4, 2, 2, 2, 2, 2, 2, 2, 2, 7, 0, 1, 0, 6, 7,
    7, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 2, 4, 7,
    7, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 7,
    7, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 7,
    7, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 7,
    7, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 7,
    7, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 7,
    7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "173 122 41");
  IupSetAttribute(image, "1", "251 216 133");
  IupSetAttribute(image, "2", "252 238 185");
  IupSetAttribute(image, "3", "188 150 36");
  IupSetAttribute(image, "4", "189 139 45");
  IupSetAttribute(image, "5", "220 182 132");
  IupSetAttribute(image, "6", "244 224 188");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_newprj_wiz()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 2, 4, 4, 4, 7, 4, 4, 4, 7, 4,
    4, 4, 4, 4, 4, 2, 7, 2, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 2, 0, 5, 4, 4, 4, 7, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 0, 0, 5, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 5, 4, 4, 4, 4, 4,
    4, 4, 4, 7, 7, 7, 7, 4, 4, 0, 0, 5, 4, 4, 4, 4,
    4, 4, 0, 4, 4, 4, 2, 0, 4, 4, 0, 0, 5, 4, 4, 4,
    0, 3, 3, 3, 3, 3, 3, 3, 3, 5, 4, 0, 0, 5, 4, 4,
    0, 5, 5, 5, 5, 5, 5, 1, 5, 1, 3, 4, 0, 0, 5, 4,
    4, 3, 5, 5, 5, 5, 1, 5, 1, 1, 3, 3, 4, 0, 2, 4,
    4, 3, 5, 5, 5, 1, 5, 1, 1, 1, 3, 6, 4, 4, 4, 4,
    4, 3, 5, 5, 1, 5, 1, 1, 1, 3, 3, 6, 4, 4, 4, 4,
    4, 3, 5, 1, 5, 1, 1, 1, 3, 3, 3, 6, 4, 4, 4, 4,
    4, 3, 1, 1, 1, 3, 3, 3, 3, 3, 3, 6, 4, 4, 4, 4,
    4, 3, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "37 35 51");
  IupSetAttribute(image, "1", "60 158 188");
  IupSetAttribute(image, "2", "193 168 108");
  IupSetAttribute(image, "3", "77 105 137");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "128 167 151");
  IupSetAttribute(image, "6", "8 6 136");
  IupSetAttribute(image, "7", "164 94 60");

  return image;
}

Ihandle* load_image_compile()
{
  ubyte imgdata[] = [
    2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2,
    2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 6, 4, 2, 2, 2, 2,
    2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 6, 6, 4, 2, 2, 2,
    2, 2, 4, 2, 1, 1, 7, 7, 5, 2, 6, 6, 6, 4, 2, 2,
    2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 2, 2,
    2, 2, 4, 2, 1, 1, 1, 7, 7, 7, 5, 5, 2, 4, 2, 2,
    2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 2, 2,
    2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2,
    2, 2, 4, 2, 1, 0, 1, 2, 1, 0, 6, 2, 1, 0, 1, 2,
    2, 2, 3, 2, 0, 6, 0, 2, 6, 0, 6, 2, 0, 6, 0, 2,
    2, 2, 3, 2, 0, 6, 0, 2, 6, 0, 6, 2, 0, 6, 0, 2,
    2, 2, 3, 2, 0, 6, 0, 2, 6, 0, 6, 2, 0, 6, 0, 2,
    2, 2, 3, 2, 1, 0, 1, 2, 6, 0, 6, 2, 1, 0, 1, 2,
    2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 2, 2,
    2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "20 50 92");
  IupSetAttribute(image, "1", "153 165 188");
  IupSetAttribute(image, "2", "BGCOLOR");
  IupSetAttribute(image, "3", "127 119 76");
  IupSetAttribute(image, "4", "174 143 62");
  IupSetAttribute(image, "5", "100 126 172");
  IupSetAttribute(image, "6", "208 200 191");
  IupSetAttribute(image, "7", "119 140 180");

  return image;
}

Ihandle* load_image_openprj()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 1, 1, 1, 4, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 4, 7, 7, 1, 4, 5,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 5, 5,
    7, 7, 7, 7, 4, 4, 4, 4, 7, 7, 7, 7, 7, 5, 5, 5,
    7, 7, 7, 4, 7, 7, 7, 7, 4, 7, 7, 7, 7, 7, 7, 7,
    3, 3, 3, 2, 2, 2, 2, 4, 4, 3, 3, 3, 3, 3, 3, 7,
    3, 1, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 3, 7,
    7, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 7, 7,
    7, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 5, 7, 7,
    7, 5, 2, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    7, 0, 2, 2, 2, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5,
    7, 0, 2, 2, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 7,
    7, 0, 2, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 7, 7,
    7, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 7, 7, 7,
    7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "47 74 196");
  IupSetAttribute(image, "1", "153 162 175");
  IupSetAttribute(image, "2", "228 226 132");
  IupSetAttribute(image, "3", "154 130 132");
  IupSetAttribute(image, "4", "216 179 157");
  IupSetAttribute(image, "5", "100 98 137");
  IupSetAttribute(image, "6", "164 202 244");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_mark_next()
{
  ubyte imgdata[] = [
    4, 2, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    2, 0, 4, 4, 4, 2, 0, 4, 4, 0, 4, 4, 4, 4, 4, 4,
    0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 4, 4, 4, 4, 4, 4,
    0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 4, 4, 3, 4, 4, 4,
    2, 0, 4, 4, 4, 4, 0, 0, 0, 0, 4, 3, 4, 4, 4, 4,
    4, 2, 0, 4, 4, 4, 4, 4, 4, 4, 3, 3, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 1, 1, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 3, 1, 1, 1, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 3, 1, 1, 1, 0, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 3, 3, 1, 1, 0, 0, 0, 3, 3, 4,
    4, 4, 4, 4, 4, 3, 4, 4, 3, 0, 0, 0, 0, 1, 1, 3,
    4, 4, 4, 4, 3, 4, 4, 4, 3, 0, 0, 0, 1, 1, 1, 3,
    4, 4, 4, 3, 4, 4, 4, 4, 3, 0, 0, 1, 1, 1, 3, 4,
    4, 4, 3, 4, 4, 4, 4, 4, 4, 3, 3, 1, 1, 3, 4, 4,
    4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 2, 3, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "0 0 128");
  IupSetAttribute(image, "1", "0 0 255");
  IupSetAttribute(image, "2", "168 160 152");
  IupSetAttribute(image, "3", "24 48 80");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "0 0 0");
  IupSetAttribute(image, "6", "0 0 0");
  IupSetAttribute(image, "7", "0 0 0");

  return image;
}

Ihandle* load_image_prev_nav()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 7, 7, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 7, 5, 5, 7, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 7, 3, 3, 3, 3, 3, 3, 7, 5, 5, 5, 5,
    5, 5, 5, 2, 3, 3, 3, 3, 3, 3, 3, 3, 2, 5, 5, 5,
    5, 5, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 5, 5,
    5, 5, 2, 2, 2, 2, 6, 6, 6, 6, 2, 2, 2, 2, 5, 5,
    5, 5, 5, 5, 5, 2, 1, 1, 1, 1, 2, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 4, 1, 1, 1, 1, 4, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 4, 1, 1, 1, 1, 4, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 4, 1, 1, 1, 1, 4, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 0, 1, 1, 1, 1, 0, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 0, 1, 1, 1, 1, 0, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "166 108 20");
  IupSetAttribute(image, "1", "252 224 137");
  IupSetAttribute(image, "2", "181 123 20");
  IupSetAttribute(image, "3", "252 244 203");
  IupSetAttribute(image, "4", "172 115 20");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "252 234 178");
  IupSetAttribute(image, "7", "188 132 20");

  return image;
}

Ihandle* load_image_saveas()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 5, 6, 6, 3, 7, 7, 7, 7, 3, 6, 6, 5, 4, 4, 4,
    4, 6, 4, 7, 4, 4, 4, 4, 4, 4, 7, 4, 6, 4, 4, 4,
    4, 6, 4, 6, 4, 4, 4, 4, 4, 4, 6, 4, 6, 4, 4, 4,
    4, 6, 4, 6, 2, 2, 2, 2, 2, 2, 6, 4, 6, 4, 4, 4,
    4, 6, 2, 6, 5, 5, 5, 5, 5, 5, 6, 2, 6, 4, 4, 4,
    4, 6, 2, 7, 6, 6, 6, 6, 6, 6, 7, 2, 6, 4, 4, 4,
    4, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 4, 4, 4,
    4, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 3, 4, 4, 4,
    4, 3, 2, 2, 3, 4, 4, 4, 5, 3, 2, 2, 3, 4, 4, 4,
    4, 3, 5, 5, 3, 2, 2, 2, 7, 3, 5, 5, 3, 4, 4, 4,
    4, 3, 5, 5, 3, 5, 5, 3, 5, 3, 5, 5, 3, 4, 4, 4,
    4, 7, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 1, 4, 0, 1, 4, 0, 1,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 4, 0, 0, 4, 0, 0];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "80 102 143");
  IupSetAttribute(image, "1", "132 174 244");
  IupSetAttribute(image, "2", "211 223 239");
  IupSetAttribute(image, "3", "99 128 168");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "208 207 199");
  IupSetAttribute(image, "6", "135 152 158");
  IupSetAttribute(image, "7", "178 190 195");

  return image;
}

Ihandle* load_image_bas()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 5, 5, 5, 5, 5,
    5, 5, 5, 2, 4, 4, 4, 4, 4, 4, 7, 2, 5, 5, 5, 5,
    5, 5, 5, 2, 4, 4, 4, 4, 4, 4, 7, 7, 2, 5, 5, 5,
    5, 5, 5, 3, 4, 4, 4, 4, 4, 4, 7, 7, 7, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 0, 0, 0, 1, 4, 4, 4, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 1, 4, 4, 6, 2, 4, 4, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 1, 4, 4, 6, 2, 4, 4, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 0, 0, 0, 2, 4, 4, 4, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 1, 4, 4, 6, 2, 4, 4, 3, 5, 5,
    5, 5, 5, 3, 4, 4, 1, 4, 4, 6, 2, 4, 4, 3, 5, 5,
    5, 5, 5, 1, 4, 4, 0, 0, 0, 1, 4, 4, 4, 1, 5, 5,
    5, 5, 5, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 5, 5,
    5, 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "79 66 196");
  IupSetAttribute(image, "1", "127 160 196");
  IupSetAttribute(image, "2", "187 196 165");
  IupSetAttribute(image, "3", "175 160 155");
  IupSetAttribute(image, "4", "252 252 248");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "164 98 196");
  IupSetAttribute(image, "7", "228 194 132");

  return image;
}

Ihandle* load_image_new_untitled_text_file()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 7, 7, 7, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 6, 2, 7, 7, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 1, 6, 2, 7, 7, 7,
    7, 7, 7, 2, 7, 3, 3, 4, 4, 7, 1, 1, 6, 2, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2, 7, 7,
    7, 7, 7, 2, 7, 3, 3, 3, 3, 4, 4, 4, 7, 2, 7, 7,
    7, 7, 7, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 7, 7,
    7, 7, 7, 0, 5, 3, 3, 3, 3, 4, 4, 4, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 3, 3, 3, 3, 4, 4, 4, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 3, 3, 3, 4, 4, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 7, 7,
    7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "131 114 60");
  IupSetAttribute(image, "1", "223 194 129");
  IupSetAttribute(image, "2", "173 135 52");
  IupSetAttribute(image, "3", "137 157 192");
  IupSetAttribute(image, "4", "107 130 172");
  IupSetAttribute(image, "5", "228 236 250");
  IupSetAttribute(image, "6", "212 178 108");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_rebuild()
{
  ubyte imgdata[] = [
    2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 2, 2, 2, 2, 2,
    2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 2, 2, 2, 2, 2,
    2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 3, 3, 3, 2, 2, 2,
    2, 2, 3, 2, 2, 2, 3, 4, 2, 2, 2, 2, 4, 3, 2, 2,
    2, 2, 3, 2, 1, 1, 3, 4, 4, 4, 4, 4, 4, 4, 3, 2,
    2, 2, 3, 2, 2, 2, 2, 3, 4, 4, 3, 3, 4, 4, 3, 2,
    2, 2, 3, 2, 1, 1, 6, 6, 3, 4, 3, 5, 3, 4, 3, 2,
    2, 2, 3, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 3, 2, 2,
    2, 3, 2, 3, 2, 3, 2, 3, 2, 2, 2, 2, 2, 3, 2, 2,
    2, 3, 2, 2, 3, 3, 2, 4, 3, 0, 7, 2, 1, 0, 1, 2,
    2, 3, 4, 2, 2, 2, 2, 2, 4, 3, 7, 2, 0, 7, 0, 2,
    2, 2, 3, 4, 4, 4, 4, 4, 4, 3, 7, 2, 0, 7, 0, 2,
    2, 2, 3, 3, 3, 3, 4, 4, 3, 0, 7, 2, 0, 7, 0, 2,
    2, 2, 3, 2, 1, 3, 4, 3, 7, 0, 7, 2, 1, 0, 1, 2,
    2, 2, 3, 2, 2, 3, 3, 2, 2, 2, 2, 2, 2, 7, 2, 2,
    2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "20 50 92");
  IupSetAttribute(image, "1", "150 165 192");
  IupSetAttribute(image, "2", "BGCOLOR");
  IupSetAttribute(image, "3", "165 138 65");
  IupSetAttribute(image, "4", "223 195 131");
  IupSetAttribute(image, "5", "100 126 172");
  IupSetAttribute(image, "6", "132 150 188");
  IupSetAttribute(image, "7", "204 206 220");

  return image;
}

/*
Ihandle* load_image_prj_obj()
{
  ubyte imgdata[] = [
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53,
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53,
    53, 53, 53, 53, 50, 50, 50, 50, 53, 53, 53, 53, 53, 53, 53, 53,
    53, 53, 53, 51, 52, 52, 52, 52, 49, 53, 53, 53, 53, 53, 53, 53,
    1, 1, 0, 37, 37, 38, 41, 47, 48, 0, 0, 0, 0, 0, 1, 53,
    2, 16, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 16, 2, 53,
    53, 3, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 3, 53, 53,
    53, 8, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 8, 53, 53,
    53, 10, 44, 44, 9, 6, 5, 6, 6, 6, 4, 7, 4, 6, 9, 6,
    53, 15, 43, 43, 43, 12, 36, 36, 36, 36, 36, 36, 36, 36, 36, 11,
    53, 19, 46, 46, 14, 35, 34, 33, 35, 33, 33, 33, 33, 35, 13, 53,
    53, 24, 45, 17, 31, 31, 30, 32, 31, 32, 29, 32, 32, 18, 53, 53,
    53, 21, 22, 25, 25, 28, 27, 26, 27, 28, 25, 28, 23, 53, 53, 53,
    53, 53, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 53, 53, 53, 53,
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53,
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "149 129 136");
  IupSetAttribute(image, "1", "149 129 137");
  IupSetAttribute(image, "2", "137 123 141");
  IupSetAttribute(image, "3", "114 113 147");
  IupSetAttribute(image, "4", "95 100 157");
  IupSetAttribute(image, "5", "96 100 158");
  IupSetAttribute(image, "6", "96 100 157");
  IupSetAttribute(image, "7", "96 101 157");
  IupSetAttribute(image, "8", "99 103 153");
  IupSetAttribute(image, "9", "95 101 157");
  IupSetAttribute(image, "10", "86 95 158");
  IupSetAttribute(image, "11", "81 92 163");
  IupSetAttribute(image, "12", "82 93 162");
  IupSetAttribute(image, "13", "69 85 168");
  IupSetAttribute(image, "14", "69 86 168");
  IupSetAttribute(image, "15", "74 90 165");
  IupSetAttribute(image, "16", "133 145 200");
  IupSetAttribute(image, "17", "57 79 173");
  IupSetAttribute(image, "18", "57 80 172");
  IupSetAttribute(image, "19", "63 84 170");
  IupSetAttribute(image, "20", "40 70 179");
  IupSetAttribute(image, "21", "46 73 176");
  IupSetAttribute(image, "22", "47 74 177");
  IupSetAttribute(image, "23", "47 74 176");
  IupSetAttribute(image, "24", "53 78 173");
  IupSetAttribute(image, "25", "146 181 236");
  IupSetAttribute(image, "26", "146 182 236");
  IupSetAttribute(image, "27", "146 181 235");
  IupSetAttribute(image, "28", "146 182 235");
  IupSetAttribute(image, "29", "157 197 242");
  IupSetAttribute(image, "30", "157 198 242");
  IupSetAttribute(image, "31", "158 197 242");
  IupSetAttribute(image, "32", "158 198 242");
  IupSetAttribute(image, "33", "169 214 249");
  IupSetAttribute(image, "34", "169 213 248");
  IupSetAttribute(image, "35", "169 214 248");
  IupSetAttribute(image, "36", "177 225 253");
  IupSetAttribute(image, "37", "250 233 158");
  IupSetAttribute(image, "38", "246 223 150");
  IupSetAttribute(image, "39", "255 241 194");
  IupSetAttribute(image, "40", "255 235 179");
  IupSetAttribute(image, "41", "236 209 139");
  IupSetAttribute(image, "42", "255 229 164");
  IupSetAttribute(image, "43", "255 218 137");
  IupSetAttribute(image, "44", "255 223 150");
  IupSetAttribute(image, "45", "255 209 117");
  IupSetAttribute(image, "46", "255 213 125");
  IupSetAttribute(image, "47", "227 193 125");
  IupSetAttribute(image, "48", "217 178 113");
  IupSetAttribute(image, "49", "208 172 120");
  IupSetAttribute(image, "50", "209 173 121");
  IupSetAttribute(image, "51", "208 172 121");
  IupSetAttribute(image, "52", "255 255 255");
  IupSetAttribute(image, "53", "BGCOLOR");
  IupSetAttribute(image, "54", "0 0 0");
  IupSetAttribute(image, "55", "0 0 0");
  IupSetAttribute(image, "56", "0 0 0");
  IupSetAttribute(image, "57", "0 0 0");
  IupSetAttribute(image, "58", "0 0 0");
  IupSetAttribute(image, "59", "0 0 0");
  IupSetAttribute(image, "60", "0 0 0");
  IupSetAttribute(image, "61", "0 0 0");
  IupSetAttribute(image, "62", "0 0 0");
  IupSetAttribute(image, "63", "0 0 0");

  return image;
}
*/

Ihandle* load_image_copy_edit()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6, 6, 6, 6, 6,
    6, 3, 6, 6, 6, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6, 6,
    6, 3, 6, 6, 6, 3, 6, 6, 6, 6, 6, 6, 3, 3, 6, 6,
    6, 3, 6, 4, 4, 3, 6, 6, 6, 6, 6, 6, 1, 3, 3, 6,
    6, 3, 6, 6, 6, 3, 6, 4, 4, 7, 0, 6, 1, 1, 3, 3,
    6, 3, 6, 4, 4, 3, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3,
    6, 3, 5, 5, 5, 3, 6, 4, 4, 4, 7, 7, 7, 0, 6, 3,
    6, 2, 5, 4, 4, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3,
    6, 2, 5, 5, 5, 2, 5, 4, 4, 4, 7, 7, 7, 0, 5, 2,
    6, 2, 5, 4, 4, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2,
    6, 2, 5, 5, 5, 2, 5, 4, 4, 4, 7, 7, 7, 0, 5, 2,
    6, 2, 5, 4, 4, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2,
    6, 2, 5, 5, 5, 2, 5, 4, 4, 7, 7, 0, 5, 5, 5, 2,
    6, 2, 2, 2, 2, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2,
    6, 6, 6, 6, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "98 122 166");
  IupSetAttribute(image, "1", "223 194 129");
  IupSetAttribute(image, "2", "163 158 141");
  IupSetAttribute(image, "3", "196 180 116");
  IupSetAttribute(image, "4", "139 159 193");
  IupSetAttribute(image, "5", "228 236 250");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "112 135 176");

  return image;
}

/*
Ihandle* load_image_build()
{
  ubyte imgdata[] = [
    6, 6, 13, 13, 13, 13, 13, 13, 13, 13, 13, 6, 6, 6, 6, 6,
    6, 6, 13, 6, 6, 6, 6, 6, 6, 6, 5, 13, 6, 6, 6, 6,
    6, 6, 13, 6, 6, 6, 6, 6, 6, 6, 5, 5, 13, 6, 6, 6,
    6, 6, 13, 6, 15, 1, 14, 7, 7, 6, 12, 5, 5, 13, 6, 6,
    6, 6, 13, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 13, 6, 6,
    6, 6, 13, 6, 15, 1, 1, 14, 14, 7, 7, 9, 6, 13, 6, 6,
    6, 6, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 6, 6,
    6, 6, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 11, 6, 6,
    6, 6, 4, 2, 8, 0, 15, 2, 15, 0, 10, 2, 8, 0, 15, 6,
    6, 6, 4, 2, 0, 10, 0, 2, 10, 0, 10, 2, 0, 10, 0, 6,
    6, 6, 3, 2, 0, 10, 0, 2, 10, 0, 10, 2, 0, 10, 0, 6,
    6, 6, 3, 2, 0, 10, 0, 2, 10, 0, 10, 2, 0, 10, 0, 6,
    6, 6, 3, 2, 15, 0, 15, 2, 10, 0, 10, 2, 15, 0, 15, 6,
    6, 6, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 6, 6,
    6, 6, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "20 50 92");
  IupSetAttribute(image, "1", "137 159 196");
  IupSetAttribute(image, "2", "230 239 250");
  IupSetAttribute(image, "3", "127 119 76");
  IupSetAttribute(image, "4", "159 135 68");
  IupSetAttribute(image, "5", "215 183 114");
  IupSetAttribute(image, "6", "251 252 252");
  IupSetAttribute(image, "7", "112 134 176");
  IupSetAttribute(image, "8", "175 185 204");
  IupSetAttribute(image, "9", "100 126 172");
  IupSetAttribute(image, "10", "204 206 220");
  IupSetAttribute(image, "11", "172 170 148");
  IupSetAttribute(image, "12", "228 202 140");
  IupSetAttribute(image, "13", "178 145 61");
  IupSetAttribute(image, "14", "129 147 185");
  IupSetAttribute(image, "15", "148 160 184");

  return image;
}
*/

Ihandle* load_image_save_edit()
{
  ubyte imgdata[] = [
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 4, 3, 3, 3, 7, 1, 1, 1, 1, 1, 7, 3, 3, 3, 4,
    2, 3, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 3,
    2, 3, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 3,
    2, 3, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 3,
    2, 7, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 7,
    2, 7, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 7,
    2, 7, 4, 4, 3, 5, 5, 5, 5, 5, 5, 5, 3, 4, 4, 7,
    2, 7, 4, 4, 1, 3, 3, 3, 3, 3, 3, 3, 1, 4, 4, 7,
    2, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7,
    2, 7, 4, 4, 4, 4, 0, 0, 0, 0, 0, 4, 4, 4, 4, 7,
    2, 0, 4, 4, 4, 0, 2, 2, 2, 2, 5, 0, 4, 4, 4, 0,
    2, 0, 1, 1, 1, 0, 6, 6, 6, 3, 3, 0, 1, 1, 1, 0,
    2, 0, 1, 1, 1, 0, 1, 1, 1, 6, 6, 0, 1, 1, 1, 0,
    2, 0, 1, 1, 1, 0, 5, 5, 5, 0, 5, 0, 1, 1, 1, 0,
    2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "97 126 169");
  IupSetAttribute(image, "1", "183 200 220");
  IupSetAttribute(image, "2", "BGCOLOR");
  IupSetAttribute(image, "3", "139 154 157");
  IupSetAttribute(image, "4", "204 216 234");
  IupSetAttribute(image, "5", "228 206 156");
  IupSetAttribute(image, "6", "154 178 201");
  IupSetAttribute(image, "7", "117 141 164");

  return image;
}

Ihandle* load_image_add_obj()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 2, 5, 5, 2, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 2, 5, 5, 2, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 2, 5, 5, 2, 6, 6, 6, 6, 6, 6,
    6, 6, 2, 2, 2, 2, 7, 7, 7, 7, 2, 2, 2, 2, 6, 6,
    6, 6, 2, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 6, 6,
    6, 6, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 6, 6,
    6, 6, 3, 3, 3, 3, 1, 1, 1, 1, 3, 3, 3, 3, 6, 6,
    6, 6, 6, 6, 6, 6, 3, 4, 4, 3, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 0, 4, 4, 0, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 0, 4, 4, 0, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 0, 0, 0, 0, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "56 121 86");
  IupSetAttribute(image, "1", "170 197 92");
  IupSetAttribute(image, "2", "88 168 118");
  IupSetAttribute(image, "3", "69 140 99");
  IupSetAttribute(image, "4", "143 183 84");
  IupSetAttribute(image, "5", "223 227 100");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "201 215 100");

  return image;
}

Ihandle* load_image_goto_obj()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1,
    4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 4, 1,
    4, 4, 4, 4, 4, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 1,
    4, 4, 4, 4, 4, 3, 4, 3, 4, 1, 1, 4, 1, 1, 4, 7,
    4, 3, 3, 3, 3, 3, 4, 4, 3, 4, 4, 4, 4, 4, 4, 7,
    3, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 0, 0, 0, 4, 7,
    3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 6, 6, 6, 4, 7,
    3, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 0, 0, 0, 4, 7,
    4, 3, 3, 3, 3, 3, 2, 2, 3, 4, 4, 4, 4, 4, 4, 7,
    4, 4, 4, 4, 4, 3, 2, 3, 4, 1, 1, 4, 1, 1, 4, 7,
    4, 4, 4, 4, 4, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5,
    4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 4, 5,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5,
    4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "44 98 148");
  IupSetAttribute(image, "1", "185 186 184");
  IupSetAttribute(image, "2", "252 235 166");
  IupSetAttribute(image, "3", "177 121 20");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "136 151 170");
  IupSetAttribute(image, "6", "108 133 175");
  IupSetAttribute(image, "7", "170 170 152");

  return image;
}

Ihandle* load_image_bi()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 5, 5, 5, 5, 5,
    5, 5, 5, 2, 3, 3, 3, 3, 3, 3, 6, 2, 5, 5, 5, 5,
    5, 5, 5, 2, 3, 3, 3, 3, 3, 3, 6, 6, 2, 5, 5, 5,
    5, 5, 5, 4, 3, 3, 3, 3, 3, 3, 6, 6, 6, 4, 5, 5,
    5, 5, 5, 4, 3, 3, 3, 1, 7, 1, 3, 3, 3, 4, 5, 5,
    5, 5, 5, 4, 3, 3, 3, 3, 7, 3, 3, 3, 3, 4, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 3, 0, 3, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 3, 0, 3, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 3, 0, 3, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 3, 0, 3, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 1, 7, 1, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 5, 5,
    5, 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "100 98 196");
  IupSetAttribute(image, "1", "143 158 185");
  IupSetAttribute(image, "2", "196 194 132");
  IupSetAttribute(image, "3", "252 252 248");
  IupSetAttribute(image, "4", "196 162 132");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "228 194 132");
  IupSetAttribute(image, "7", "164 202 244");

  return image;
}

Ihandle* load_image_mark_prev()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 0, 0, 0, 0, 2, 4, 4, 4, 4, 4, 4, 4,
    0, 4, 4, 0, 2, 4, 4, 4, 0, 2, 4, 4, 4, 4, 4, 4,
    0, 0, 0, 4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4,
    0, 0, 0, 4, 4, 4, 4, 4, 4, 0, 4, 4, 3, 4, 4, 4,
    0, 0, 0, 0, 4, 4, 4, 4, 0, 2, 4, 3, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 0, 2, 4, 3, 3, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 1, 1, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 3, 1, 1, 1, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 3, 1, 1, 1, 0, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 3, 3, 1, 1, 0, 0, 0, 3, 3, 4,
    4, 4, 4, 4, 4, 3, 4, 4, 3, 0, 0, 0, 0, 1, 1, 3,
    4, 4, 4, 4, 3, 4, 4, 4, 3, 0, 0, 0, 1, 1, 1, 3,
    4, 4, 4, 3, 4, 4, 4, 4, 3, 0, 0, 1, 1, 1, 3, 4,
    4, 4, 3, 4, 4, 4, 4, 4, 4, 3, 3, 1, 1, 3, 4, 4,
    4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 2, 3, 3, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "0 0 128");
  IupSetAttribute(image, "1", "0 0 255");
  IupSetAttribute(image, "2", "168 160 152");
  IupSetAttribute(image, "3", "24 48 80");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "0 0 0");
  IupSetAttribute(image, "6", "0 0 0");
  IupSetAttribute(image, "7", "0 0 0");

  return image;
}

Ihandle* load_image_lrun_obj()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 5, 2, 0, 0, 0, 0, 2, 5, 6, 6, 6, 6,
    6, 6, 6, 2, 0, 4, 4, 1, 1, 1, 2, 0, 2, 6, 6, 6,
    6, 6, 2, 3, 1, 4, 6, 4, 1, 1, 1, 1, 3, 2, 6, 6,
    6, 5, 0, 2, 1, 7, 6, 6, 4, 1, 1, 1, 1, 0, 5, 6,
    6, 2, 3, 2, 2, 7, 6, 6, 6, 4, 2, 2, 2, 2, 2, 6,
    6, 0, 3, 3, 3, 7, 6, 6, 6, 6, 4, 3, 3, 2, 0, 6,
    6, 0, 3, 3, 3, 7, 6, 6, 6, 6, 6, 5, 3, 2, 0, 6,
    6, 0, 0, 0, 0, 7, 6, 6, 6, 6, 7, 0, 0, 3, 0, 6,
    6, 0, 0, 0, 0, 7, 6, 6, 6, 7, 0, 0, 3, 2, 0, 6,
    6, 2, 3, 3, 3, 7, 6, 6, 7, 3, 3, 3, 3, 3, 2, 6,
    6, 5, 0, 3, 3, 7, 6, 7, 0, 0, 3, 3, 2, 0, 5, 6,
    6, 6, 2, 3, 2, 7, 7, 0, 0, 3, 2, 2, 3, 2, 6, 6,
    6, 6, 6, 2, 0, 3, 2, 2, 2, 2, 3, 0, 2, 6, 6, 6,
    6, 6, 6, 6, 5, 2, 0, 0, 0, 0, 2, 5, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "47 133 67");
  IupSetAttribute(image, "1", "152 186 121");
  IupSetAttribute(image, "2", "107 173 107");
  IupSetAttribute(image, "3", "78 147 80");
  IupSetAttribute(image, "4", "132 206 36");
  IupSetAttribute(image, "5", "196 234 124");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "177 204 177");

  return image;
}

Ihandle* load_image_delete_obj()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 5, 2, 1, 6, 6, 6, 6, 6, 1, 2, 5, 6, 6,
    6, 6, 5, 2, 2, 2, 1, 6, 6, 6, 1, 2, 2, 2, 5, 6,
    6, 6, 1, 2, 4, 4, 2, 2, 1, 2, 2, 4, 4, 2, 1, 6,
    6, 6, 6, 1, 3, 4, 4, 2, 3, 2, 4, 4, 3, 1, 6, 6,
    6, 6, 6, 6, 2, 3, 4, 2, 2, 2, 2, 3, 2, 6, 6, 6,
    6, 6, 6, 6, 6, 3, 7, 2, 2, 2, 7, 3, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 0, 7, 7, 7, 7, 7, 0, 6, 6, 6, 6,
    6, 6, 6, 6, 2, 0, 7, 7, 7, 7, 7, 0, 2, 6, 6, 6,
    6, 6, 6, 2, 0, 7, 7, 0, 0, 0, 7, 7, 0, 2, 6, 6,
    6, 6, 1, 0, 7, 7, 0, 2, 1, 2, 0, 7, 7, 0, 1, 6,
    6, 6, 5, 0, 7, 0, 2, 6, 6, 6, 2, 0, 3, 0, 5, 6,
    6, 6, 6, 5, 0, 2, 6, 6, 6, 6, 6, 2, 0, 5, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "201 28 41");
  IupSetAttribute(image, "1", "216 150 146");
  IupSetAttribute(image, "2", "219 94 96");
  IupSetAttribute(image, "3", "199 62 58");
  IupSetAttribute(image, "4", "236 120 114");
  IupSetAttribute(image, "5", "228 198 196");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "241 62 80");

  return image;
}

Ihandle* load_image_open_edit()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 1, 6, 6, 6, 1, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 0, 1, 7, 7, 6, 1, 0, 7,
    7, 7, 4, 4, 4, 4, 7, 7, 7, 7, 7, 7, 1, 0, 0, 7,
    7, 2, 7, 7, 7, 7, 2, 7, 7, 7, 7, 7, 0, 0, 0, 7,
    4, 3, 3, 3, 5, 5, 5, 4, 4, 4, 4, 4, 7, 7, 7, 7,
    4, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 7, 7, 7, 7,
    4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 7, 7, 7, 7,
    4, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7,
    4, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3, 3, 3, 5, 4, 7,
    2, 3, 3, 4, 3, 3, 3, 3, 3, 3, 3, 3, 5, 4, 7, 7,
    2, 5, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 7, 7, 7,
    2, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 7, 7, 7, 7,
    7, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "84 109 146");
  IupSetAttribute(image, "1", "193 201 210");
  IupSetAttribute(image, "2", "158 101 35");
  IupSetAttribute(image, "3", "252 226 158");
  IupSetAttribute(image, "4", "181 122 47");
  IupSetAttribute(image, "5", "246 208 130");
  IupSetAttribute(image, "6", "130 145 166");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_paste_edit()
{
  ubyte imgdata[] = [
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 5, 1, 1, 5, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 5, 1, 1, 1, 1, 5, 3, 3, 3, 3, 3,
    3, 3, 6, 2, 2, 0, 5, 5, 5, 5, 0, 2, 2, 6, 3, 3,
    3, 3, 7, 3, 0, 5, 5, 5, 5, 5, 5, 0, 3, 7, 3, 3,
    3, 3, 7, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 7, 3, 3,
    3, 3, 7, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 2, 3, 3,
    3, 3, 7, 6, 6, 6, 6, 4, 3, 3, 3, 3, 7, 4, 3, 3,
    3, 3, 7, 6, 6, 6, 6, 4, 3, 5, 0, 3, 6, 7, 4, 3,
    3, 3, 7, 6, 6, 6, 6, 4, 3, 3, 3, 3, 3, 3, 4, 3,
    3, 3, 7, 6, 6, 6, 6, 4, 3, 5, 5, 0, 0, 3, 4, 3,
    3, 3, 2, 6, 6, 6, 6, 4, 3, 3, 3, 3, 3, 3, 4, 3,
    3, 3, 2, 6, 6, 6, 6, 5, 3, 5, 5, 0, 0, 3, 5, 3,
    3, 3, 2, 6, 6, 6, 6, 5, 3, 3, 3, 3, 3, 3, 5, 3,
    3, 3, 2, 7, 6, 6, 6, 5, 3, 3, 3, 3, 3, 3, 5, 3,
    3, 3, 6, 2, 2, 2, 2, 5, 5, 5, 5, 5, 5, 5, 5, 3];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "102 123 162");
  IupSetAttribute(image, "1", "172 189 207");
  IupSetAttribute(image, "2", "187 147 99");
  IupSetAttribute(image, "3", "BGCOLOR");
  IupSetAttribute(image, "4", "180 177 144");
  IupSetAttribute(image, "5", "139 155 179");
  IupSetAttribute(image, "6", "240 207 144");
  IupSetAttribute(image, "7", "207 171 118");

  return image;
}

Ihandle* load_image_mark_toggle()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 1, 1, 2, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 2, 1, 1, 1, 2, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 2, 1, 1, 1, 0, 2, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 2, 2, 1, 1, 0, 0, 0, 2, 2, 4,
    4, 4, 4, 4, 4, 2, 4, 4, 2, 0, 0, 0, 0, 1, 1, 2,
    4, 4, 4, 4, 2, 4, 4, 4, 2, 0, 0, 0, 1, 1, 1, 2,
    4, 4, 4, 2, 4, 4, 4, 4, 2, 0, 0, 1, 1, 1, 2, 4,
    4, 4, 2, 4, 4, 4, 4, 4, 4, 2, 2, 1, 1, 2, 4, 4,
    4, 2, 4, 4, 4, 4, 4, 4, 4, 4, 3, 2, 2, 4, 4, 4,
    2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "0 0 128");
  IupSetAttribute(image, "1", "0 0 255");
  IupSetAttribute(image, "2", "24 48 80");
  IupSetAttribute(image, "3", "168 160 152");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "0 0 0");
  IupSetAttribute(image, "6", "0 0 0");
  IupSetAttribute(image, "7", "0 0 0");

  return image;
}

Ihandle* load_image_saveall_edit()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 3, 4, 4, 7, 1, 1, 1, 1, 7, 4, 3, 6, 6, 6, 6,
    6, 4, 6, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 6, 6, 6,
    6, 4, 6, 3, 4, 4, 7, 1, 1, 1, 7, 4, 4, 3, 6, 6,
    6, 4, 6, 4, 6, 3, 6, 6, 6, 6, 6, 3, 6, 4, 6, 6,
    6, 7, 2, 4, 6, 3, 4, 4, 7, 1, 1, 1, 7, 4, 4, 3,
    6, 7, 2, 4, 6, 4, 6, 1, 6, 6, 6, 6, 6, 1, 6, 4,
    6, 7, 2, 7, 2, 4, 2, 4, 2, 2, 2, 2, 2, 4, 2, 4,
    6, 7, 2, 7, 2, 7, 2, 4, 5, 5, 5, 5, 5, 4, 2, 7,
    6, 0, 2, 7, 2, 7, 2, 1, 4, 4, 4, 4, 4, 1, 2, 7,
    6, 0, 3, 7, 2, 7, 3, 3, 3, 3, 3, 3, 3, 3, 3, 7,
    6, 1, 0, 0, 2, 7, 3, 3, 3, 0, 0, 0, 3, 3, 3, 7,
    6, 6, 6, 0, 3, 7, 3, 3, 0, 6, 6, 5, 0, 3, 3, 7,
    6, 6, 6, 1, 0, 0, 3, 3, 0, 3, 3, 1, 0, 3, 3, 0,
    6, 6, 6, 6, 6, 0, 1, 1, 0, 5, 0, 5, 0, 1, 1, 0,
    6, 6, 6, 6, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "100 127 165");
  IupSetAttribute(image, "1", "184 196 205");
  IupSetAttribute(image, "2", "224 233 243");
  IupSetAttribute(image, "3", "206 217 232");
  IupSetAttribute(image, "4", "140 154 157");
  IupSetAttribute(image, "5", "228 206 156");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "116 141 164");

  return image;
}

Ihandle* load_image_redo_edit()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 1, 7, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 7, 5, 6, 4, 4, 4, 4, 7, 7, 4, 4, 4, 4, 4, 4,
    4, 7, 4, 7, 4, 4, 4, 4, 7, 4, 7, 4, 4, 4, 4, 4,
    4, 7, 4, 5, 7, 4, 4, 4, 7, 4, 4, 7, 4, 4, 4, 4,
    4, 6, 5, 4, 1, 7, 7, 6, 7, 4, 4, 4, 7, 4, 4, 4,
    4, 6, 1, 4, 4, 4, 5, 5, 4, 4, 4, 4, 4, 7, 4, 4,
    4, 1, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 7, 4,
    4, 4, 0, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0,
    4, 4, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 4,
    4, 4, 4, 1, 0, 6, 2, 2, 2, 2, 2, 2, 2, 0, 4, 4,
    4, 4, 4, 4, 4, 1, 3, 0, 0, 2, 2, 2, 0, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 2, 2, 0, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 2, 0, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "173 115 20");
  IupSetAttribute(image, "1", "212 196 143");
  IupSetAttribute(image, "2", "251 232 158");
  IupSetAttribute(image, "3", "180 150 76");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "232 217 152");
  IupSetAttribute(image, "6", "199 173 106");
  IupSetAttribute(image, "7", "187 130 20");

  return image;
}

Ihandle* load_image_th_single()
{
	ubyte imgdata[] = [
    4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4,
    4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 7, 0, 7, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 0, 3, 0, 4, 2, 6, 3, 1, 5, 4, 3, 4,
    4, 4, 3, 4, 7, 0, 7, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 7, 0, 7, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 0, 3, 0, 4, 2, 6, 3, 1, 5, 4, 3, 4,
    4, 4, 3, 4, 7, 0, 7, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 7, 0, 7, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 0, 3, 0, 4, 2, 6, 3, 1, 5, 4, 3, 4,
    4, 4, 3, 4, 7, 0, 7, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4,
    4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "132 134 132");
  IupSetAttribute(image, "1", "212 210 212");
  IupSetAttribute(image, "2", "164 166 164");
  IupSetAttribute(image, "3", "191 190 191");
  IupSetAttribute(image, "4", "252 254 252");
  IupSetAttribute(image, "5", "228 226 228");
  IupSetAttribute(image, "6", "180 178 180");
  IupSetAttribute(image, "7", "220 218 220");

  return image;
}

Ihandle* load_image_write_obj()
{
  ubyte imgdata[] = [
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 7, 7, 2, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 7, 6, 6, 5, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 7, 6, 6, 7, 5, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 2, 7, 6, 6, 7, 2, 2, 3,
    3, 3, 3, 3, 3, 3, 3, 2, 7, 6, 6, 7, 2, 5, 3, 3,
    3, 3, 3, 3, 3, 3, 2, 7, 6, 6, 7, 2, 5, 3, 3, 3,
    3, 3, 3, 3, 3, 2, 7, 6, 6, 7, 2, 5, 3, 3, 3, 3,
    3, 3, 3, 3, 2, 7, 6, 6, 7, 2, 5, 3, 3, 3, 3, 3,
    3, 3, 3, 4, 2, 6, 6, 1, 2, 5, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 5, 6, 6, 1, 2, 5, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 4, 0, 1, 1, 5, 5, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 0, 5, 0, 5, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 0, 0, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);
  IupSetAttribute(image, "0", "4 38 108");
  IupSetAttribute(image, "1", "196 170 124");
  IupSetAttribute(image, "2", "156 104 74");
  IupSetAttribute(image, "3", "BGCOLOR");
  IupSetAttribute(image, "4", "148 138 167");
  IupSetAttribute(image, "5", "156 79 30");
  IupSetAttribute(image, "6", "245 209 154");
  IupSetAttribute(image, "7", "252 190 100");

  return image;
}

Ihandle* load_image_find_obj()
{
  ubyte imgdata[] = [
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 5, 2, 2, 1,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 3, 3, 1, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 3, 0, 6, 6, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 3, 0, 6, 6, 6, 5,
    3, 3, 3, 3, 3, 3, 3, 4, 4, 3, 3, 6, 6, 6, 4, 4,
    3, 3, 3, 3, 3, 2, 2, 2, 2, 3, 6, 6, 6, 4, 4, 3,
    3, 3, 3, 3, 2, 1, 1, 1, 1, 5, 6, 6, 4, 4, 3, 3,
    3, 3, 3, 2, 1, 1, 1, 1, 7, 7, 5, 4, 4, 3, 3, 3,
    3, 3, 2, 2, 2, 1, 1, 7, 7, 7, 5, 4, 3, 3, 3, 3,
    3, 3, 4, 6, 3, 2, 7, 7, 7, 7, 5, 3, 3, 3, 3, 3,
    3, 4, 6, 3, 3, 3, 5, 7, 7, 2, 5, 3, 3, 3, 3, 3,
    4, 6, 3, 3, 3, 3, 3, 5, 2, 5, 3, 3, 3, 3, 3, 3,
    6, 3, 3, 3, 3, 3, 6, 5, 5, 3, 3, 3, 3, 3, 3, 3,
    6, 3, 3, 3, 3, 6, 6, 5, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "76 110 164");
  IupSetAttribute(image, "1", "200 195 191");
  IupSetAttribute(image, "2", "173 146 110");
  IupSetAttribute(image, "3", "BGCOLOR");
  IupSetAttribute(image, "4", "239 169 71");
  IupSetAttribute(image, "5", "146 113 78");
  IupSetAttribute(image, "6", "244 215 139");
  IupSetAttribute(image, "7", "182 172 180");

  return image;
}

Ihandle* load_image_details_view()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    6, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    6, 2, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2,
    6, 2, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2,
    6, 2, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2,
    6, 5, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5,
    6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    6, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5,
    6, 5, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5,
    6, 0, 1, 6, 7, 7, 7, 4, 4, 4, 3, 3, 3, 6, 6, 0,
    6, 0, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0,
    6, 0, 1, 6, 7, 7, 4, 4, 3, 3, 6, 6, 6, 6, 6, 0,
    6, 0, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0,
    6, 0, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0,
    6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "112 121 144");
  IupSetAttribute(image, "1", "212 242 252");
  IupSetAttribute(image, "2", "161 155 109");
  IupSetAttribute(image, "3", "116 138 178");
  IupSetAttribute(image, "4", "129 150 190");
  IupSetAttribute(image, "5", "139 138 124");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "143 164 196");

  return image;
}

Ihandle* load_image_help()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 1, 1, 0, 0, 1, 1, 5, 5, 5, 5, 5,
    5, 5, 5, 1, 0, 2, 4, 4, 4, 4, 2, 0, 1, 5, 5, 5,
    5, 5, 1, 2, 4, 4, 4, 4, 4, 4, 4, 4, 2, 1, 5, 5,
    5, 5, 0, 4, 4, 4, 1, 0, 0, 0, 4, 4, 4, 0, 5, 5,
    5, 1, 2, 4, 4, 1, 0, 6, 2, 0, 0, 4, 4, 2, 1, 5,
    5, 1, 4, 4, 4, 2, 3, 4, 4, 1, 0, 4, 4, 4, 1, 5,
    5, 0, 4, 4, 4, 4, 4, 4, 1, 0, 1, 4, 4, 4, 0, 5,
    5, 0, 4, 4, 4, 4, 4, 1, 0, 6, 4, 4, 4, 4, 0, 5,
    5, 1, 4, 4, 4, 4, 4, 0, 0, 4, 4, 4, 4, 7, 1, 5,
    5, 1, 2, 4, 4, 4, 4, 2, 2, 4, 4, 4, 4, 2, 1, 5,
    5, 5, 0, 4, 4, 4, 4, 0, 0, 4, 4, 4, 4, 0, 5, 5,
    5, 5, 1, 2, 4, 4, 4, 4, 4, 4, 4, 4, 2, 1, 5, 5,
    5, 5, 5, 1, 0, 2, 4, 4, 4, 4, 2, 0, 1, 5, 5, 5,
    5, 5, 5, 5, 5, 1, 1, 0, 0, 1, 1, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "36 98 132");
  IupSetAttribute(image, "1", "99 130 196");
  IupSetAttribute(image, "2", "164 194 196");
  IupSetAttribute(image, "3", "132 162 196");
  IupSetAttribute(image, "4", "252 253 250");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "100 162 196");
  IupSetAttribute(image, "7", "196 222 196");

  return image;
}

Ihandle* load_image_delete_others()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 2, 7, 7, 7, 7, 7, 7, 7, 7, 2, 7, 7, 7,
    7, 7, 2, 2, 6, 7, 7, 7, 7, 7, 7, 6, 2, 2, 7, 7,
    7, 2, 2, 5, 5, 2, 2, 7, 7, 5, 2, 2, 2, 5, 2, 7,
    7, 7, 7, 5, 7, 7, 7, 7, 7, 7, 7, 7, 5, 7, 7, 7,
    7, 7, 7, 7, 4, 4, 7, 7, 7, 7, 4, 4, 7, 7, 7, 7,
    7, 7, 7, 1, 2, 2, 4, 7, 7, 6, 2, 2, 6, 7, 7, 7,
    7, 7, 4, 2, 5, 5, 2, 1, 1, 2, 5, 2, 5, 7, 7, 7,
    7, 7, 7, 6, 2, 5, 5, 2, 2, 5, 2, 2, 4, 7, 7, 7,
    7, 7, 7, 7, 6, 0, 2, 5, 5, 2, 3, 4, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 0, 3, 2, 2, 3, 2, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 6, 0, 3, 3, 3, 3, 0, 4, 7, 7, 7, 7,
    7, 7, 7, 6, 0, 3, 3, 0, 0, 3, 3, 0, 4, 7, 7, 7,
    7, 7, 4, 3, 3, 3, 3, 1, 1, 0, 3, 0, 2, 7, 7, 7,
    7, 7, 7, 1, 0, 0, 4, 7, 7, 6, 0, 0, 6, 7, 7, 7,
    7, 7, 7, 7, 6, 4, 7, 7, 7, 7, 6, 6, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "206 28 43");
  IupSetAttribute(image, "1", "223 166 165");
  IupSetAttribute(image, "2", "216 86 80");
  IupSetAttribute(image, "3", "222 56 69");
  IupSetAttribute(image, "4", "242 215 216");
  IupSetAttribute(image, "5", "238 118 115");
  IupSetAttribute(image, "6", "235 189 190");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_removeall()
{
  ubyte imgdata[] = [
    5, 5, 2, 4, 5, 5, 5, 5, 5, 4, 2, 5, 5, 5, 5, 5,
    5, 2, 2, 2, 4, 5, 5, 5, 4, 2, 2, 2, 5, 5, 5, 5,
    5, 2, 1, 1, 2, 2, 4, 2, 2, 1, 1, 2, 4, 5, 5, 5,
    5, 4, 3, 1, 1, 2, 3, 2, 1, 1, 3, 4, 5, 5, 5, 5,
    5, 5, 2, 3, 1, 1, 1, 1, 1, 3, 2, 5, 5, 5, 5, 5,
    5, 5, 5, 3, 2, 1, 3, 2, 2, 3, 5, 5, 5, 2, 3, 5,
    5, 5, 2, 3, 1, 3, 3, 3, 2, 3, 2, 5, 2, 3, 3, 3,
    5, 2, 3, 1, 4, 3, 7, 7, 3, 3, 4, 3, 3, 7, 7, 3,
    5, 3, 1, 1, 3, 2, 6, 2, 2, 3, 6, 3, 2, 2, 6, 2,
    5, 3, 3, 3, 2, 5, 3, 0, 2, 2, 2, 2, 2, 0, 3, 5,
    5, 5, 3, 2, 5, 5, 5, 0, 3, 3, 3, 3, 3, 0, 5, 5,
    5, 5, 5, 5, 5, 5, 3, 0, 3, 3, 3, 3, 3, 0, 3, 5,
    5, 5, 5, 5, 5, 3, 0, 3, 3, 6, 0, 6, 3, 3, 0, 3,
    5, 5, 5, 5, 4, 0, 3, 3, 0, 3, 4, 3, 0, 3, 3, 0,
    5, 5, 5, 5, 5, 0, 6, 0, 3, 5, 5, 5, 3, 0, 6, 0,
    5, 5, 5, 5, 5, 5, 0, 3, 5, 5, 5, 5, 5, 3, 0, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "190 60 62");
  IupSetAttribute(image, "1", "252 198 196");
  IupSetAttribute(image, "2", "238 108 110");
  IupSetAttribute(image, "3", "219 89 91");
  IupSetAttribute(image, "4", "252 132 133");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "204 74 76");
  IupSetAttribute(image, "7", "252 122 124");

  return image;
}

Ihandle* load_image_refresh()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 4, 6, 4, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 4, 6, 6, 4, 4, 4, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 5, 3, 2, 2, 2, 2, 1, 5, 6, 6,
    6, 6, 6, 6, 6, 6, 5, 1, 3, 3, 3, 3, 3, 1, 7, 6,
    6, 6, 6, 6, 6, 6, 6, 0, 1, 3, 0, 0, 1, 3, 0, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 0, 1, 0, 6, 0, 1, 0, 6,
    6, 6, 4, 6, 6, 4, 4, 6, 6, 0, 0, 6, 6, 0, 6, 6,
    6, 4, 6, 4, 6, 4, 6, 4, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 4, 6, 2, 4, 4, 6, 3, 4, 6, 6, 6, 6, 6, 6, 6,
    6, 4, 3, 2, 2, 2, 2, 2, 1, 7, 6, 6, 6, 6, 6, 6,
    6, 6, 5, 1, 3, 3, 3, 3, 1, 5, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 0, 0, 0, 1, 1, 0, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 0, 1, 0, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "169 110 20");
  IupSetAttribute(image, "1", "250 212 111");
  IupSetAttribute(image, "2", "252 242 180");
  IupSetAttribute(image, "3", "251 231 150");
  IupSetAttribute(image, "4", "188 134 20");
  IupSetAttribute(image, "5", "184 127 20");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "196 152 32");

  return image;
}

Ihandle* load_image_function_public_obj()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 4,
    4, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 4,
    4, 1, 4, 4, 4, 4, 3, 0, 5, 3, 4, 4, 4, 4, 1, 4,
    1, 1, 4, 4, 4, 2, 2, 6, 7, 2, 2, 4, 4, 4, 1, 1,
    1, 1, 4, 4, 3, 2, 6, 6, 6, 6, 2, 3, 4, 4, 1, 1,
    1, 1, 4, 4, 0, 1, 1, 1, 1, 1, 1, 0, 4, 4, 1, 1,
    1, 1, 4, 4, 0, 3, 3, 3, 3, 3, 3, 0, 4, 4, 1, 1,
    1, 1, 4, 4, 3, 5, 1, 1, 1, 1, 5, 3, 4, 4, 1, 1,
    4, 1, 4, 4, 4, 2, 2, 1, 1, 2, 2, 4, 4, 4, 1, 4,
    4, 1, 1, 4, 4, 4, 3, 0, 5, 3, 4, 4, 4, 1, 1, 4,
    4, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "12 134 79");
  IupSetAttribute(image, "1", "139 187 132");
  IupSetAttribute(image, "2", "79 162 111");
  IupSetAttribute(image, "3", "110 177 130");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "52 151 98");
  IupSetAttribute(image, "6", "174 207 156");
  IupSetAttribute(image, "7", "156 198 148");

  return image;
}

Ihandle* load_image_variable_obj()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 0, 3, 3, 3, 3, 1, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 3, 3, 3, 3, 3, 2, 1, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 3, 3, 3, 3, 3, 2, 1, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 3, 3, 3, 3, 3, 2, 1, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 3, 3, 3, 3, 2, 2, 1, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 1, 2, 2, 2, 2, 1, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "63 127 63");
  IupSetAttribute(image, "1", "63 95 63");
  IupSetAttribute(image, "2", "127 159 95");
  IupSetAttribute(image, "3", "159 191 95");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "0 0 0");
  IupSetAttribute(image, "6", "0 0 0");
  IupSetAttribute(image, "7", "0 0 0");

  return image;
}

static Ihandle* load_image_ctor_obj()
{
  ubyte imgdata[] = [
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2, 4, 4, 3,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 4, 3, 3, 4,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 4, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 4, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 4, 4, 4, 4, 7, 1, 4, 3, 3, 4,
    7, 7, 7, 7, 7, 4, 5, 5, 5, 5, 0, 7, 2, 4, 4, 3,
    7, 7, 7, 7, 4, 5, 5, 5, 5, 5, 6, 0, 7, 7, 7, 7,
    7, 7, 7, 7, 4, 5, 5, 5, 5, 5, 6, 0, 7, 7, 7, 7,
    7, 7, 7, 7, 4, 5, 5, 5, 5, 5, 6, 0, 7, 7, 7, 7,
    7, 7, 7, 7, 4, 5, 5, 5, 5, 6, 6, 0, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 0, 6, 6, 6, 6, 0, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "60 94 60");
  IupSetAttribute(image, "1", "68 182 92");
  IupSetAttribute(image, "2", "44 174 76");
  IupSetAttribute(image, "3", "188 238 196");
  IupSetAttribute(image, "4", "47 125 56");
  IupSetAttribute(image, "5", "155 193 98");
  IupSetAttribute(image, "6", "124 158 92");
  IupSetAttribute(image, "7", "BGCOLOR");

  return image;
}

Ihandle* load_image_dtor_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 3, 2, 3, 7,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 5, 4, 5, 3,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 4, 5, 4, 0,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 4, 5, 4, 0,
    5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 5, 3, 5, 4, 5, 3,
    5, 5, 5, 5, 5, 6, 1, 1, 1, 1, 6, 7, 3, 0, 3, 7,
    5, 5, 5, 5, 6, 1, 1, 1, 1, 1, 1, 6, 5, 5, 5, 5,
    5, 5, 5, 5, 6, 1, 1, 1, 1, 1, 1, 6, 5, 5, 5, 5,
    5, 5, 5, 5, 6, 1, 1, 1, 1, 1, 1, 6, 5, 5, 5, 5,
    5, 5, 5, 5, 6, 1, 1, 1, 1, 1, 1, 6, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 6, 1, 1, 1, 1, 6, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "145 38 36");
  IupSetAttribute(image, "1", "147 181 92");
  IupSetAttribute(image, "2", "209 38 36");
  IupSetAttribute(image, "3", "190 86 88");
  IupSetAttribute(image, "4", "235 69 68");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "60 108 60");
  IupSetAttribute(image, "7", "222 166 164");

  return image;
}

Ihandle* load_image_struct_obj()
{
  ubyte imgdata[] = [
     6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 5, 2, 4, 4, 4, 2, 3, 6, 6, 6, 6,
    6, 6, 6, 6, 4, 2, 2, 1, 1, 7, 2, 2, 4, 6, 6, 6,
    6, 6, 6, 4, 2, 1, 1, 1, 2, 1, 7, 1, 2, 4, 6, 6,
    6, 6, 3, 2, 7, 2, 6, 6, 6, 6, 6, 1, 1, 2, 3, 6,
    6, 6, 2, 2, 1, 1, 1, 1, 6, 7, 1, 2, 1, 2, 2, 6,
    6, 6, 4, 7, 2, 1, 2, 1, 6, 1, 1, 7, 1, 1, 4, 6,
    6, 6, 4, 1, 1, 7, 1, 1, 6, 1, 7, 1, 2, 7, 0, 6,
    6, 6, 4, 7, 2, 1, 1, 7, 6, 1, 1, 2, 1, 1, 4, 6,
    6, 6, 2, 2, 1, 7, 1, 1, 6, 1, 7, 2, 1, 2, 2, 6,
    6, 6, 3, 2, 1, 2, 7, 1, 6, 1, 1, 1, 7, 4, 3, 6,
    6, 6, 6, 4, 2, 1, 1, 1, 2, 1, 7, 1, 2, 4, 6, 6,
    6, 6, 6, 6, 4, 2, 4, 1, 1, 2, 2, 4, 4, 6, 6, 6,
    6, 6, 6, 6, 6, 5, 2, 4, 4, 4, 2, 3, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "52 42 156");
  IupSetAttribute(image, "1", "52 170 194");
  IupSetAttribute(image, "2", "64 130 190");
  IupSetAttribute(image, "3", "156 170 204");
  IupSetAttribute(image, "4", "59 86 158");
  IupSetAttribute(image, "5", "156 214 204");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "100 170 201");

  return image;
}

Ihandle* load_image_property_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 5, 5,
    5, 1, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 5,
    5, 1, 5, 5, 5, 5, 2, 0, 0, 2, 5, 5, 5, 5, 1, 5,
    1, 1, 5, 5, 5, 3, 3, 4, 1, 3, 3, 5, 5, 5, 1, 1,
    1, 1, 5, 5, 2, 3, 6, 6, 6, 6, 3, 2, 5, 5, 1, 1,
    1, 1, 5, 5, 0, 1, 1, 1, 1, 1, 1, 0, 5, 5, 1, 1,
    1, 1, 5, 5, 0, 2, 7, 7, 7, 7, 2, 0, 5, 5, 1, 1,
    1, 1, 5, 5, 2, 0, 1, 1, 1, 1, 0, 2, 5, 5, 1, 1,
    5, 1, 5, 5, 5, 3, 3, 6, 1, 3, 3, 5, 5, 5, 1, 5,
    5, 1, 1, 5, 5, 5, 2, 0, 0, 2, 5, 5, 5, 1, 1, 5,
    5, 5, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "41 11 169");
  IupSetAttribute(image, "1", "93 141 221");
  IupSetAttribute(image, "2", "84 68 218");
  IupSetAttribute(image, "3", "50 37 210");
  IupSetAttribute(image, "4", "132 206 236");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "119 185 234");
  IupSetAttribute(image, "7", "68 102 220");

  return image;
}

Ihandle* load_image_variable_protected_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 2, 2, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 2, 3, 3, 2, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 2, 3, 3, 3, 3, 2, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 4, 3, 6, 6, 6, 6, 3, 4, 5, 5, 5, 5,
    5, 5, 5, 5, 4, 7, 1, 1, 1, 1, 7, 4, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 0, 6, 6, 6, 6, 0, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 0, 6, 6, 0, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 0, 0, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "169 130 29");
  IupSetAttribute(image, "1", "252 206 108");
  IupSetAttribute(image, "2", "187 154 40");
  IupSetAttribute(image, "3", "252 237 159");
  IupSetAttribute(image, "4", "180 142 36");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "252 223 141");
  IupSetAttribute(image, "7", "252 218 140");

  return image;
}

Ihandle* load_image_function_protected_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 0, 5, 5, 5, 5, 5, 5, 5, 5, 0, 5, 5, 5,
    5, 5, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 5, 5,
    5, 5, 0, 5, 5, 5, 5, 2, 2, 5, 5, 5, 5, 0, 5, 5,
    5, 0, 0, 5, 5, 5, 2, 3, 3, 2, 5, 5, 5, 0, 0, 5,
    5, 0, 0, 5, 5, 2, 3, 3, 3, 3, 2, 5, 5, 0, 0, 5,
    5, 0, 0, 5, 4, 3, 6, 6, 6, 6, 3, 4, 5, 0, 0, 5,
    5, 0, 0, 5, 4, 7, 1, 1, 1, 1, 7, 4, 5, 0, 0, 5,
    5, 0, 0, 5, 5, 0, 6, 6, 6, 6, 0, 5, 5, 0, 0, 5,
    5, 5, 0, 5, 5, 5, 0, 6, 6, 0, 5, 5, 5, 0, 5, 5,
    5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5,
    5, 5, 5, 0, 5, 5, 5, 5, 5, 5, 5, 5, 0, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "165 127 28");
  IupSetAttribute(image, "1", "252 206 108");
  IupSetAttribute(image, "2", "187 154 40");
  IupSetAttribute(image, "3", "252 237 159");
  IupSetAttribute(image, "4", "180 142 36");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "252 223 141");
  IupSetAttribute(image, "7", "252 218 140");

  return image;
}

Ihandle* load_image_function_private_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 5, 5,
    5, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 5,
    5, 0, 5, 5, 3, 3, 3, 3, 3, 3, 3, 5, 5, 5, 0, 5,
    0, 0, 5, 5, 3, 1, 1, 1, 1, 1, 3, 5, 5, 5, 0, 0,
    0, 0, 5, 5, 3, 1, 6, 6, 6, 1, 3, 5, 5, 5, 0, 0,
    0, 0, 5, 5, 4, 6, 7, 7, 7, 6, 4, 5, 5, 5, 0, 0,
    0, 0, 5, 5, 4, 6, 2, 2, 2, 6, 4, 5, 5, 5, 0, 0,
    0, 0, 5, 5, 0, 1, 1, 1, 1, 1, 0, 5, 5, 5, 0, 0,
    5, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0, 5, 5, 5, 0, 5,
    5, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 5,
    5, 5, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "204 26 44");
  IupSetAttribute(image, "1", "237 146 140");
  IupSetAttribute(image, "2", "228 98 100");
  IupSetAttribute(image, "3", "204 68 60");
  IupSetAttribute(image, "4", "204 46 52");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "242 125 129");
  IupSetAttribute(image, "7", "244 78 92");

  return image;
}

Ihandle* load_image_variable_private_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 3, 3, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 3, 1, 1, 1, 1, 1, 3, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 3, 1, 6, 6, 6, 1, 3, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 4, 6, 7, 7, 7, 6, 4, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 4, 6, 2, 2, 2, 6, 4, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 0, 1, 1, 1, 1, 1, 0, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "204 27 44");
  IupSetAttribute(image, "1", "237 146 140");
  IupSetAttribute(image, "2", "228 98 100");
  IupSetAttribute(image, "3", "204 68 60");
  IupSetAttribute(image, "4", "204 46 52");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "242 125 129");
  IupSetAttribute(image, "7", "244 78 92");

  return image;
}

Ihandle* load_image_class_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 2, 6, 6, 6, 6, 6, 2, 5, 5, 5, 5,
    5, 5, 5, 5, 6, 6, 3, 3, 3, 3, 3, 6, 6, 5, 5, 5,
    5, 5, 5, 6, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 5, 5,
    5, 5, 4, 6, 3, 3, 1, 5, 5, 5, 1, 3, 3, 6, 4, 5,
    5, 5, 3, 3, 3, 1, 5, 7, 3, 1, 5, 3, 3, 3, 6, 5,
    5, 5, 6, 3, 3, 7, 5, 3, 3, 3, 3, 3, 3, 3, 0, 5,
    5, 5, 6, 3, 3, 7, 5, 3, 3, 3, 3, 3, 3, 3, 0, 5,
    5, 5, 6, 3, 3, 7, 5, 3, 3, 3, 3, 3, 3, 3, 0, 5,
    5, 5, 3, 3, 3, 1, 5, 7, 3, 1, 5, 3, 3, 6, 6, 5,
    5, 5, 4, 6, 3, 3, 1, 5, 5, 5, 1, 3, 3, 0, 4, 5,
    5, 5, 5, 6, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6, 5, 5,
    5, 5, 5, 5, 6, 6, 3, 3, 3, 3, 6, 0, 6, 5, 5, 5,
    5, 5, 5, 5, 5, 4, 6, 0, 0, 0, 6, 4, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "60 94 60");
  IupSetAttribute(image, "1", "124 190 108");
  IupSetAttribute(image, "2", "220 222 188");
  IupSetAttribute(image, "3", "60 158 63");
  IupSetAttribute(image, "4", "188 190 156");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "60 126 92");
  IupSetAttribute(image, "7", "188 222 188");

  return image;
}

Ihandle* load_image_enum_member_obj()
{
  ubyte imgdata[] = [
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 0, 1, 1, 1, 1, 2, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 1, 1, 1, 1, 1, 3, 0, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 1, 1, 1, 1, 1, 3, 0, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 1, 1, 1, 1, 1, 3, 0, 4, 4, 4, 4,
    4, 4, 4, 4, 0, 1, 1, 1, 1, 3, 3, 0, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 0, 3, 3, 3, 3, 0, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "142 92 36");
  IupSetAttribute(image, "1", "190 161 129");
  IupSetAttribute(image, "2", "147 99 45");
  IupSetAttribute(image, "3", "158 115 67");
  IupSetAttribute(image, "4", "BGCOLOR");
  IupSetAttribute(image, "5", "0 0 0");
  IupSetAttribute(image, "6", "0 0 0");
  IupSetAttribute(image, "7", "0 0 0");

  return image;
}

Ihandle* load_image_enum_obj()
{
  ubyte imgdata[] = [
    5, 5, 5, 5, 6, 3, 7, 0, 7, 3, 6, 5, 5, 5, 5, 5,
    5, 5, 5, 4, 0, 2, 3, 3, 3, 2, 0, 4, 5, 5, 5, 5,
    5, 5, 4, 0, 4, 1, 1, 1, 1, 1, 2, 0, 4, 5, 5, 5,
    5, 6, 0, 2, 2, 5, 5, 5, 5, 5, 1, 3, 0, 6, 5, 5,
    5, 3, 3, 3, 3, 5, 5, 6, 1, 1, 2, 3, 3, 2, 5, 5,
    5, 7, 3, 3, 3, 5, 5, 4, 3, 3, 3, 2, 3, 7, 5, 5,
    5, 0, 0, 0, 0, 5, 5, 5, 5, 5, 2, 0, 7, 0, 5, 5,
    5, 7, 7, 7, 7, 5, 5, 1, 4, 4, 3, 7, 7, 7, 5, 5,
    5, 2, 7, 3, 3, 5, 5, 4, 3, 3, 3, 3, 3, 2, 5, 5,
    5, 6, 0, 3, 3, 5, 5, 5, 5, 5, 1, 3, 0, 6, 5, 5,
    5, 5, 4, 0, 7, 4, 4, 4, 4, 4, 2, 0, 4, 5, 5, 5,
    5, 5, 5, 4, 0, 3, 3, 3, 3, 3, 0, 4, 5, 5, 5, 5,
    5, 5, 5, 5, 6, 3, 7, 7, 7, 3, 6, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "144 95 40");
  IupSetAttribute(image, "1", "204 184 160");
  IupSetAttribute(image, "2", "175 137 97");
  IupSetAttribute(image, "3", "161 119 74");
  IupSetAttribute(image, "4", "190 160 128");
  IupSetAttribute(image, "5", "BGCOLOR");
  IupSetAttribute(image, "6", "227 209 194");
  IupSetAttribute(image, "7", "149 103 49");

  return image;
}


Ihandle* load_image_alias_obj()
{
  ubyte imgdata[] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "BGCOLOR");
  IupSetAttribute(image, "1", "0 128 192");
  IupSetAttribute(image, "2", "0 128 0");
  IupSetAttribute(image, "3", "128 128 0");
  IupSetAttribute(image, "4", "0 0 128");
  IupSetAttribute(image, "5", "128 0 128");
  IupSetAttribute(image, "6", "0 128 128");
  IupSetAttribute(image, "7", "192 192 192");

  return image;
}

Ihandle* load_image_union_obj()
{
  ubyte imgdata[] = [
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 2, 7, 7, 7, 7, 7, 2, 6, 6, 6, 6,
    6, 6, 6, 6, 7, 7, 4, 2, 2, 2, 4, 7, 7, 6, 6, 6,
    6, 6, 6, 7, 4, 2, 2, 2, 2, 2, 2, 2, 4, 7, 6, 6,
    6, 6, 2, 7, 2, 2, 3, 3, 2, 3, 3, 2, 2, 7, 2, 6,
    6, 6, 7, 4, 2, 2, 0, 1, 2, 1, 0, 2, 2, 4, 7, 6,
    6, 6, 5, 2, 2, 2, 0, 1, 2, 1, 0, 2, 2, 2, 7, 6,
    6, 6, 5, 2, 2, 2, 0, 1, 2, 1, 0, 2, 2, 2, 7, 6,
    6, 6, 5, 2, 2, 2, 0, 1, 2, 1, 0, 2, 2, 2, 7, 6,
    6, 6, 7, 4, 2, 2, 0, 1, 3, 1, 0, 2, 2, 4, 7, 6,
    6, 6, 2, 5, 2, 2, 3, 0, 0, 0, 3, 2, 2, 7, 2, 6,
    6, 6, 6, 7, 4, 2, 2, 2, 2, 2, 2, 2, 4, 7, 6, 6,
    6, 6, 6, 6, 7, 5, 4, 2, 2, 2, 4, 7, 7, 6, 6, 6,
    6, 6, 6, 6, 6, 2, 7, 5, 5, 5, 7, 2, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6];

  Ihandle* image = IupImage(16, 16, imgdata.ptr);

  IupSetAttribute(image, "0", "4 2 4");
  IupSetAttribute(image, "1", "156 158 92");
  IupSetAttribute(image, "2", "212 214 163");
  IupSetAttribute(image, "3", "188 190 92");
  IupSetAttribute(image, "4", "172 170 124");
  IupSetAttribute(image, "5", "124 126 44");
  IupSetAttribute(image, "6", "BGCOLOR");
  IupSetAttribute(image, "7", "172 170 84");

  return image;
}



void load_all_images_icons()
{
  IupSetHandle("icon_markclear", load_image_mark_clear());
  IupSetHandle("icon_cut", load_image_cut_edit());
  IupSetHandle("icon_quickrun", load_image_quickrun());
  IupSetHandle("icon_packageexplorer", load_image_package_explorer());
  IupSetHandle("icon_downarrow", load_image_next_nav());
  IupSetHandle("icon_file", load_image_file_obj());
  IupSetHandle("icon_outline", load_image_outline_co());
  IupSetHandle("icon_newfile", load_image_newfile());
  IupSetHandle("icon_selectall", load_image_selectall());
  IupSetHandle("icon_undo", load_image_undo_edit());
  IupSetHandle("icon_newfolder", load_image_newfolder_wiz());
  IupSetHandle("icon_newprj", load_image_newprj_wiz());
  IupSetHandle("icon_compile", load_image_compile());
  IupSetHandle("icon_openprj", load_image_openprj());
  IupSetHandle("icon_marknext", load_image_mark_next());
  IupSetHandle("icon_uparrow", load_image_prev_nav());
  IupSetHandle("icon_saveas", load_image_saveas());
  IupSetHandle("icon_bas", load_image_bas());
  IupSetHandle("icon_txt", load_image_new_untitled_text_file());
  IupSetHandle("icon_rebuild", load_image_rebuild());
  //IupSetHandle("IUP_prj", load_image_prj_obj());
  IupSetHandle("icon_copy", load_image_copy_edit());
  //IupSetHandle("icon_build", load_image_build());
  IupSetHandle("icon_save", load_image_save_edit());
  IupSetHandle("icon_add", load_image_add_obj());
  IupSetHandle("icon_goto", load_image_goto_obj());
  IupSetHandle("icon_bi", load_image_bi());
  IupSetHandle("icon_markprev", load_image_mark_prev());
  IupSetHandle("icon_run", load_image_lrun_obj());
  IupSetHandle("icon_delete", load_image_delete_obj());
  IupSetHandle("icon_openfile", load_image_open_edit());
  IupSetHandle("icon_paste", load_image_paste_edit());
  IupSetHandle("icon_mark", load_image_mark_toggle());
  IupSetHandle("icon_saveall", load_image_saveall_edit());
  IupSetHandle("icon_redo", load_image_redo_edit());
  IupSetHandle("icon_filelist", load_image_th_single());
  IupSetHandle("icon_Write", load_image_write_obj());
  IupSetHandle("icon_find", load_image_find_obj());
  IupSetHandle("icon_message", load_image_details_view());
  IupSetHandle("icon_help", load_image_help());
  IupSetHandle("icon_deleteothers", load_image_delete_others());
  IupSetHandle("icon_deleteall", load_image_removeall());
  IupSetHandle("icon_refresh", load_image_refresh());


  IupSetHandle("IUP_function", load_image_function_public_obj());
  IupSetHandle("IUP_variable", load_image_variable_obj());
  IupSetHandle("IUP_ctor", load_image_ctor_obj());
  IupSetHandle("IUP_dtor", load_image_dtor_obj());
  IupSetHandle("IUP_class", load_image_class_obj());
  IupSetHandle("IUP_struct", load_image_struct_obj());
  IupSetHandle("IUP_property", load_image_property_obj());
  IupSetHandle("IUP_variable_protected", load_image_variable_protected_obj());
  IupSetHandle("IUP_function_protected", load_image_function_protected_obj());
  IupSetHandle("IUP_function_private", load_image_function_private_obj());
  IupSetHandle("IUP_variable_private", load_image_variable_private_obj());  
  IupSetHandle("IUP_enummember", load_image_enum_member_obj());
  IupSetHandle("IUP_enum", load_image_enum_obj());
  IupSetHandle("IUP_alias", load_image_alias_obj());
  IupSetHandle("IUP_union", load_image_union_obj());

  
}


