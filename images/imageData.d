module images.imageData;

import iup.iup;

import tools, images.xpm;

Ihandle* load_image_poseidonFBico()
{
	ubyte imgdata[] = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 17, 16, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 16, 16, 16, 32, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 46, 41, 255, 17, 16, 16, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 42, 46, 47, 128, 45, 53, 56, 239, 31, 31, 27, 112, 0, 0, 0, 0, 0, 0, 0, 0, 58, 58, 45, 239, 44, 33, 30, 239, 14, 12, 11, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 15, 15, 16, 48, 111, 113, 108, 255, 92, 84, 65, 239, 4, 4, 4, 16, 0, 0, 0, 0, 39, 36, 28, 159, 92, 90, 74, 255, 38, 27, 24, 239, 16, 13, 13, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 20, 20, 20, 80, 64, 62, 47, 159, 91, 82, 55, 207, 18, 18, 15, 16, 0, 0, 0, 0, 33, 33, 28, 96, 91, 92, 75, 255, 41, 36, 31, 255, 22, 16, 16, 159, 21, 18, 20, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 58, 44, 159, 84, 81, 65, 207, 31, 30, 26, 16, 0, 0, 0, 0, 24, 25, 21, 64, 82, 90, 81, 239, 60, 62, 54, 255, 39, 32, 26, 255, 16, 15, 16, 143, 14, 14, 15, 80, 0, 0, 0, 0, 0, 0, 0, 0,
	27, 27, 28, 96, 29, 33, 36, 128, 19, 22, 24, 96, 21, 21, 21, 32, 0, 0, 0, 0, 55, 59, 55, 159, 100, 101, 91, 239, 35, 33, 27, 48, 0, 0, 0, 0, 11, 12, 12, 32, 62, 66, 58, 191, 86, 95, 81, 255, 65, 75, 65, 255, 46, 50, 40, 255, 31, 28, 24, 255, 17, 17, 18, 80,
	11, 10, 11, 32, 54, 48, 50, 207, 66, 63, 60, 255, 64, 58, 46, 207, 0, 0, 0, 0, 16, 17, 18, 16, 76, 84, 84, 207, 100, 104, 90, 255, 39, 36, 29, 96, 0, 0, 0, 0, 0, 0, 0, 0, 43, 43, 37, 96, 96, 101, 90, 223, 101, 117, 118, 255, 39, 35, 36, 239, 15, 14, 15, 111,
	0, 0, 0, 0, 0, 0, 0, 16, 65, 56, 57, 175, 120, 107, 98, 255, 59, 52, 37, 159, 0, 0, 0, 0, 20, 22, 22, 16, 75, 85, 85, 207, 98, 106, 95, 255, 61, 57, 45, 159, 1, 1, 1, 16, 0, 0, 0, 0, 46, 50, 43, 191, 104, 119, 119, 255, 17, 12, 12, 223, 13, 13, 14, 96,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 77, 78, 175, 129, 120, 107, 255, 59, 54, 44, 143, 0, 0, 0, 0, 35, 37, 38, 64, 96, 107, 105, 239, 101, 113, 109, 255, 84, 81, 67, 207, 31, 34, 34, 112, 95, 106, 97, 255, 85, 92, 93, 255, 10, 8, 9, 223, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 16, 138, 131, 129, 239, 100, 97, 87, 255, 30, 27, 22, 64, 0, 0, 0, 0, 38, 39, 34, 80, 103, 113, 102, 255, 109, 125, 126, 255, 135, 145, 144, 255, 119, 129, 129, 255, 36, 33, 32, 223, 13, 12, 14, 127, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 62, 65, 128, 122, 117, 117, 255, 105, 100, 86, 239, 5, 5, 5, 16, 0, 0, 0, 0, 67, 68, 55, 159, 140, 146, 137, 255, 126, 127, 129, 255, 103, 101, 101, 255, 39, 32, 31, 255, 25, 25, 25, 64, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 15, 16, 80, 121, 111, 110, 223, 82, 87, 84, 255, 85, 76, 61, 175, 33, 37, 32, 128, 121, 122, 96, 255, 148, 150, 137, 255, 132, 139, 140, 255, 127, 139, 140, 255, 95, 77, 66, 255, 38, 29, 25, 175, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 78, 78, 144, 97, 97, 96, 255, 126, 135, 127, 255, 136, 146, 130, 255, 125, 128, 110, 239, 60, 53, 47, 255, 55, 48, 48, 239, 120, 117, 92, 255, 126, 124, 80, 255, 96, 74, 54, 255, 36, 23, 19, 159,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 46, 44, 48, 110, 102, 98, 255, 70, 74, 74, 239, 37, 33, 33, 255, 10, 8, 9, 191, 9, 8, 9, 159, 18, 18, 20, 96, 88, 82, 80, 239, 119, 113, 83, 255, 74, 64, 43, 255, 81, 58, 46, 239,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 32, 33, 191, 19, 18, 19, 175, 19, 18, 19, 111, 13, 13, 15, 48, 0, 0, 0, 0, 0, 0, 0, 0, 19, 16, 17, 48, 100, 88, 84, 239, 46, 40, 35, 223, 8, 7, 6, 127];

	Ihandle* image = IupImageRGBA( 16, 16, imgdata.ptr );
	return image;
}

void load_all_images_icons()
{
	XPM.init();
	
	IupSetHandle( "icon_markclear", XPM.getIUPimage( "icons/xpm/mark_clear.xpm" ) ); // IupSetHandle("icon_markclear", load_image_mark_clear());
	IupSetHandle( "icon_cut", XPM.getIUPimage( "icons/xpm/cut.xpm" ) ); // IupSetHandle("icon_cut", load_image_cut_edit());
	IupSetHandle( "icon_quickrun", XPM.getIUPimage( "icons/xpm/quickrun.xpm" ) ); //IupSetHandle("icon_quickrun", load_image_quickrun());
	IupSetHandle( "icon_packageexplorer", XPM.getIUPimage( "icons/xpm/prjexplorer.xpm" ) ); // IupSetHandle("icon_packageexplorer", load_image_package_explorer());
	IupSetHandle ("icon_downarrow", XPM.getIUPimage( "icons/xpm/down.xpm" ) ); // IupSetHandle("icon_downarrow", load_image_next_nav());
	//IupSetHandle( "icon_file", XPM.getIUPimage( "icons/xpm/down.xpm"() ); // IupSetHandle("icon_file", load_image_file_obj());
	IupSetHandle( "icon_outline", XPM.getIUPimage( "icons/xpm/outline.xpm" ) ); // IupSetHandle("icon_outline", load_image_outline_co());
	IupSetHandle( "icon_newfile", XPM.getIUPimage( "icons/xpm/newfile.xpm" ) ); // IupSetHandle("icon_newfile", load_image_newfile());
	IupSetHandle( "icon_selectall", XPM.getIUPimage( "icons/xpm/selectall.xpm" ) ); // IupSetHandle("icon_selectall", load_image_selectall());
	IupSetHandle( "icon_undo", XPM.getIUPimage( "icons/xpm/undo.xpm" ) ); // IupSetHandle("icon_undo", load_image_undo_edit());
	//IupSetHandle("icon_newfolder", load_image_newfolder_wiz()); // IupSetHandle("icon_newfolder", load_image_newfolder_wiz());
	IupSetHandle( "icon_newprj", XPM.getIUPimage( "icons/xpm/newprj.xpm" ) ); // IupSetHandle("icon_newprj", load_image_newprj_wiz());
	IupSetHandle( "icon_compile", XPM.getIUPimage( "icons/xpm/compile.xpm" ) ); // IupSetHandle("icon_compile", load_image_compile());
	IupSetHandle( "icon_openprj", XPM.getIUPimage( "icons/xpm/openprj.xpm" ) ); // IupSetHandle("icon_openprj", load_image_openprj());
	IupSetHandle( "icon_importprj", XPM.getIUPimage( "icons/xpm/fbedit.xpm" ) ); // IupSetHandle("icon_openprj", load_image_openprj());
	IupSetHandle( "icon_marknext", XPM.getIUPimage( "icons/xpm/mark_next.xpm" ) ); // IupSetHandle("icon_marknext", load_image_mark_next());
	IupSetHandle( "icon_uparrow", XPM.getIUPimage( "icons/xpm/up.xpm" ) ); // IupSetHandle("icon_uparrow", load_image_prev_nav());
	IupSetHandle( "icon_saveas", XPM.getIUPimage( "icons/xpm/saveas.xpm" ) ); // IupSetHandle("icon_saveas", load_image_saveas());
	IupSetHandle( "icon_bas", XPM.getIUPimage( "icons/xpm/bas.xpm" ) ); // IupSetHandle("icon_bas", load_image_bas());
	IupSetHandle( "icon_txt", XPM.getIUPimage( "icons/xpm/txt.xpm" ) ); // IupSetHandle("icon_txt", load_image_new_untitled_text_file());
	IupSetHandle( "icon_rebuild", XPM.getIUPimage( "icons/xpm/build.xpm" ) ); // IupSetHandle( "icon_rebuild", load_image_rebuild());
	IupSetHandle( "icon_buildrun", XPM.getIUPimage( "icons/xpm/buildrun.xpm" ) );
	IupSetHandle( "icon_console", XPM.getIUPimage( "icons/xpm/console.xpm" ) );
	IupSetHandle( "icon_gui", XPM.getIUPimage( "icons/xpm/gui.xpm" ) );

	IupSetHandle( "icon_copy", XPM.getIUPimage( "icons/xpm/copy.xpm" ) ); // IupSetHandle("icon_copy", load_image_copy_edit());
	IupSetHandle( "icon_save", XPM.getIUPimage( "icons/xpm/save.xpm" ) ); // IupSetHandle("icon_save", load_image_save_edit());
	IupSetHandle( "icon_goto", XPM.getIUPimage( "icons/xpm/goto.xpm" ) ); // IupSetHandle("icon_goto", load_image_goto_obj());
	IupSetHandle( "icon_bi", XPM.getIUPimage( "icons/xpm/bi.xpm" ) ); // IupSetHandle( "icon_bi", load_image_bi());
	IupSetHandle( "icon_markprev", XPM.getIUPimage( "icons/xpm/mark_prev.xpm" ) ); // IupSetHandle("icon_markprev", load_image_mark_prev());
	IupSetHandle( "icon_run", XPM.getIUPimage( "icons/xpm/run.xpm" ) ); // IupSetHandle("icon_run", load_image_lrun_obj());
	IupSetHandle( "icon_delete", XPM.getIUPimage( "icons/xpm/remove.xpm" ) ); // IupSetHandle("icon_delete", load_image_delete_obj());
	IupSetHandle( "icon_openfile", XPM.getIUPimage( "icons/xpm/openfile.xpm" ) ); // IupSetHandle("icon_openfile", load_image_open_edit());
	IupSetHandle( "icon_paste", XPM.getIUPimage( "icons/xpm/paste.xpm" ) ); // IupSetHandle("icon_paste", load_image_paste_edit());
	IupSetHandle( "icon_mark", XPM.getIUPimage( "icons/xpm/mark_toggle.xpm" ) ); // IupSetHandle("icon_mark", load_image_mark_toggle());
	IupSetHandle( "icon_saveall", XPM.getIUPimage( "icons/xpm/saveall.xpm" ) ); // IupSetHandle("icon_saveall", load_image_saveall_edit());
	IupSetHandle( "icon_redo", XPM.getIUPimage( "icons/xpm/redo.xpm" ) ); // IupSetHandle("icon_redo", load_image_redo_edit());
	IupSetHandle( "icon_filelist", XPM.getIUPimage( "icons/xpm/filelist.xpm" ) ); // IupSetHandle("icon_filelist", load_image_th_single());
	IupSetHandle( "icon_Write", XPM.getIUPimage( "icons/xpm/write.xpm" ) ); // IupSetHandle("icon_Write", load_image_write_obj());
	IupSetHandle( "icon_search", XPM.getIUPimage( "icons/xpm/search.xpm" ) ); // IupSetHandle("icon_find", load_image_find_obj());
	IupSetHandle( "icon_message", XPM.getIUPimage( "icons/xpm/message.xpm" ) ); // IupSetHandle("icon_message", load_image_details_view());
	IupSetHandle( "icon_help", XPM.getIUPimage( "icons/xpm/help.xpm" ) ); // IupSetHandle("icon_help", load_image_help());
	IupSetHandle( "icon_deleteothers", XPM.getIUPimage( "icons/xpm/removeothers.xpm" ) ); // IupSetHandle("icon_deleteothers", load_image_delete_others());
	IupSetHandle( "icon_deleteall", XPM.getIUPimage( "icons/xpm/removeall.xpm" ) ); // IupSetHandle("icon_deleteall", load_image_removeall());
	IupSetHandle( "icon_refresh", XPM.getIUPimage( "icons/xpm/refresh.xpm" ) ); // IupSetHandle("icon_refresh", load_image_refresh());
	IupSetHandle( "icon_annotation", XPM.getIUPimage( "icons/xpm/annotate.xpm" ) ); // IupSetHandle("icon_annotation", load_image_annotation());
	IupSetHandle( "icon_annotation_hide", XPM.getIUPimage( "icons/xpm/annotatehide.xpm" ) ); // IupSetHandle("icon_annotation_hide", load_image_annotation_hide());
	IupSetHandle( "icon_annotation_remove", XPM.getIUPimage( "icons/xpm/annotate_removeall.xpm" ) ); //IupSetHandle("icon_annotation_remove", load_image_annotation_remove());
	IupSetHandle( "icon_windows", XPM.getIUPimage( "icons/xpm/windows.xpm" ) ); // IupSetHandle("icon_windows", load_image_windows());
	IupSetHandle( "icon_mac", XPM.getIUPimage( "icons/xpm/mac.xpm" ) ); // IupSetHandle("icon_mac", load_image_mac());
	IupSetHandle( "icon_linux", XPM.getIUPimage( "icons/xpm/linux.xpm" ) ); // IupSetHandle("icon_linux", load_image_linux());
	IupSetHandle( "icon_tools", XPM.getIUPimage( "icons/xpm/tools.xpm" ) );
	IupSetHandle( "icon_properties", XPM.getIUPimage( "icons/xpm/properties.xpm" ) );
	IupSetHandle( "icon_preference", XPM.getIUPimage( "icons/xpm/preference.xpm" ) );
	IupSetHandle( "icon_shift_r", XPM.getIUPimage( "icons/xpm/shift_r_edit.xpm" ) );
	IupSetHandle( "icon_shift_t", XPM.getIUPimage( "icons/xpm/shift_t_edit.xpm" ) );
	IupSetHandle( "icon_shift_l", XPM.getIUPimage( "icons/xpm/shift_l_edit.xpm" ) );
	IupSetHandle( "icon_shift_b", XPM.getIUPimage( "icons/xpm/shift_b_edit.xpm" ) );
	IupSetHandle( "icon_information", XPM.getIUPimage( "icons/xpm/information.xpm" ) );
	IupSetHandle( "icon_find", XPM.getIUPimage( "icons/xpm/find.xpm" ) );
	IupSetHandle( "icon_findnext", XPM.getIUPimage( "icons/xpm/findnext.xpm" ) );
	IupSetHandle( "icon_findprev", XPM.getIUPimage( "icons/xpm/findprev.xpm" ) );
	IupSetHandle( "icon_findfiles", XPM.getIUPimage( "icons/xpm/findfiles.xpm" ) );
	IupSetHandle( "icon_clear", XPM.getIUPimage( "icons/xpm/clear.xpm" ) );
	IupSetHandle( "icon_clearall", XPM.getIUPimage( "icons/xpm/clearall.xpm" ) );
	IupSetHandle( "icon_door", XPM.getIUPimage( "icons/xpm/door.xpm" ) );
	IupSetHandle( "icon_dooropen", XPM.getIUPimage( "icons/xpm/door_open.xpm" ) );
	IupSetHandle( "icon_type", XPM.getIUPimage( "icons/xpm/type.xpm" ) );
	IupSetHandle( "icon_comment", XPM.getIUPimage( "icons/xpm/comment.xpm" ) );

	IupSetHandle( "icon_prj_open", XPM.getIUPimage( "icons/xpm/prjfolderopen.xpm" ) ); // IupSetHandle("icon_prj_open", load_image_prj_open());
	IupSetHandle( "icon_prj", XPM.getIUPimage( "icons/xpm/prjfolder.xpm" ) ); // IupSetHandle("icon_prj", load_image_prj()); 
	IupSetHandle( "icon_collapse", XPM.getIUPimage( "icons/xpm/collapse.xpm" ) ); // IupSetHandle("icon_collapse", load_image_collapse());
	IupSetHandle( "icon_show_pr", XPM.getIUPimage( "icons/xpm/show_pr.xpm" ) ); // IupSetHandle("icon_show_pr", load_image_show_pr());
	IupSetHandle( "icon_show_p", XPM.getIUPimage( "icons/xpm/show_p.xpm" ) ); // IupSetHandle("icon_show_p", load_image_show_p());
	IupSetHandle( "icon_show_r", XPM.getIUPimage( "icons/xpm/show_r.xpm" ) ); // IupSetHandle("icon_show_r", load_image_show_r()); 
	IupSetHandle( "icon_show_nopr", XPM.getIUPimage( "icons/xpm/show_nopr.xpm" ) ); // IupSetHandle("icon_show_nopr", load_image_show_nopr());
	IupSetHandle( "icon_searchany", XPM.getIUPimage( "icons/xpm/searchany.xpm" ) ); // IupSetHandle("icon_searchany", load_image_searchany());

	IupSetHandle( "icon_manual", XPM.getIUPimage( "icons/xpm/manual.xpm" ) );
	IupSetHandle( "icon_manual_home", XPM.getIUPimage( "icons/xpm/home.xpm" ) );
	

	IupSetHandle( "IUP_function", XPM.getIUPimage( "icons/xpm/outline/fun_public.xpm" ) ); //IupSetHandle("IUP_function", load_image_function_public_obj());
	IupSetHandle( "IUP_sub", XPM.getIUPimage( "icons/xpm/outline/sub_public.xpm" ) ); //IupSetHandle("IUP_sub", load_image_sub_public_obj());
	IupSetHandle( "IUP_function_protected", XPM.getIUPimage( "icons/xpm/outline/fun_protected.xpm" ) ); //IupSetHandle("IUP_function_protected", load_image_function_protected_obj());
	IupSetHandle( "IUP_function_private", XPM.getIUPimage( "icons/xpm/outline/fun_private.xpm" ) );// IupSetHandle("IUP_function_private", load_image_function_private_obj());
	IupSetHandle( "IUP_sub_protected", XPM.getIUPimage( "icons/xpm/outline/sub_protected.xpm" ) );//IupSetHandle("IUP_sub_protected", load_image_sub_protected_obj());
	IupSetHandle( "IUP_sub_private", XPM.getIUPimage( "icons/xpm/outline/sub_private.xpm" ) );//IupSetHandle("IUP_sub_private", load_image_sub_private_obj());
	IupSetHandle( "IUP_variable_array", XPM.getIUPimage( "icons/xpm/outline/variable_array_obj.xpm" ) );//IupSetHandle("IUP_variable_array", load_image_variable_array_public_obj());
	IupSetHandle( "IUP_variable", XPM.getIUPimage( "icons/xpm/outline/variable_obj.xpm" ) );//IupSetHandle("IUP_variable", load_image_variable_obj());



	IupSetHandle( "IUP_ctor", XPM.getIUPimage( "icons/xpm/outline/ctor.xpm" ) );//IupSetHandle("IUP_ctor", load_image_ctor_obj());
	IupSetHandle( "IUP_dtor", XPM.getIUPimage( "icons/xpm/outline/dtor.xpm" ) );//IupSetHandle("IUP_dtor", load_image_dtor_obj());
	IupSetHandle( "IUP_class", XPM.getIUPimage( "icons/xpm/outline/class_obj.xpm" ) );//IupSetHandle("IUP_class", load_image_class_obj());
	IupSetHandle( "IUP_struct", XPM.getIUPimage( "icons/xpm/outline/struct_obj.xpm" ) );//IupSetHandle("IUP_struct", load_image_struct_obj());
	IupSetHandle( "IUP_property", XPM.getIUPimage( "icons/xpm/outline/property_obj.xpm" ) );//IupSetHandle("IUP_property", load_image_property_obj());
	IupSetHandle( "IUP_property_var", XPM.getIUPimage( "icons/xpm/outline/property_var.xpm" ) );//IupSetHandle("IUP_property_var", load_image_property_var());
	IupSetHandle( "IUP_operator", XPM.getIUPimage( "icons/xpm/outline/operator.xpm" ) );//IupSetHandle("IUP_operator", load_image_operator());
	IupSetHandle( "IUP_variable_protected", XPM.getIUPimage( "icons/xpm/outline/variable_protected_obj.xpm" ) );//IupSetHandle("IUP_variable_protected", load_image_variable_protected_obj());
	IupSetHandle( "IUP_variable_array_protected", XPM.getIUPimage( "icons/xpm/outline/variable_array_protected_obj.xpm" ) );//IupSetHandle("IUP_variable_array_protected", load_image_variable_array_protected_obj());
	IupSetHandle( "IUP_variable_array_private", XPM.getIUPimage( "icons/xpm/outline/variable_array_private_obj.xpm" ) ); //IupSetHandle("IUP_variable_array_private", load_image_variable_array_private_obj());
	IupSetHandle( "IUP_variable_private", XPM.getIUPimage( "icons/xpm/outline/variable_private_obj.xpm" ) );  //IupSetHandle("IUP_variable_private", load_image_variable_private_obj());  
	IupSetHandle( "IUP_enummember", XPM.getIUPimage( "icons/xpm/outline/enum_member_obj.xpm" ) );//IupSetHandle("IUP_enummember", load_image_enum_member_obj());
	IupSetHandle( "IUP_enum", XPM.getIUPimage( "icons/xpm/outline/enum_obj.xpm" ) );//IupSetHandle("IUP_enum", load_image_enum_obj());
	IupSetHandle( "IUP_alias", XPM.getIUPimage( "icons/xpm/outline/alias.xpm" ) );//IupSetHandle("IUP_alias", load_image_alias_obj());
	IupSetHandle( "IUP_union", XPM.getIUPimage( "icons/xpm/outline/union_obj.xpm" ) );//IupSetHandle("IUP_union", load_image_union_obj());
	IupSetHandle( "IUP_namespace", XPM.getIUPimage( "icons/xpm/outline/namespace_obj.xpm" ) );//IupSetHandle("IUP_namespace", load_image_namespace_obj());
	IupSetHandle( "IUP_macro", XPM.getIUPimage( "icons/xpm/outline/macro.xpm" ) );//IupSetHandle("IUP_macro", load_image_macro());
	IupSetHandle( "IUP_scope", XPM.getIUPimage( "icons/xpm/outline/scope.xpm" ) );//IupSetHandle("IUP_scope", load_image_scope());
	IupSetHandle( "IUP_define_fun", XPM.getIUPimage( "icons/xpm/outline/define_fun.xpm" ) );// IupSetHandle("IUP_define_fun", load_image_define_fun());
	IupSetHandle( "IUP_define_var", XPM.getIUPimage( "icons/xpm/outline/define_fun.xpm" ) );//IupSetHandle("IUP_define_var", load_image_define_var());


	IupSetHandle( "icon_debug_until", XPM.getIUPimage( "icons/xpm/debug/until.xpm" ) );//IupSetHandle("icon_debug_until", load_image_until());
	IupSetHandle( "icon_debug_step", XPM.getIUPimage( "icons/xpm/debug/step.xpm" ) );//IupSetHandle("icon_debug_step", load_image_step());
	IupSetHandle( "icon_debug_bt0",  XPM.getIUPimage( "icons/xpm/debug/bt0.xpm" ) );//IupSetHandle("icon_debug_bt0", load_image_backtrace0());
	IupSetHandle( "icon_debug_bt1", XPM.getIUPimage( "icons/xpm/debug/bt1.xpm" ) );//IupSetHandle("icon_debug_bt1", load_image_backtrace1());
	IupSetHandle( "icon_debug_stop", XPM.getIUPimage( "icons/xpm/debug/stop.xpm" ) );//IupSetHandle("icon_debug_stop", load_image_stop());
	IupSetHandle( "icon_debug_resume", XPM.getIUPimage( "icons/xpm/debug/resume.xpm" ) );//IupSetHandle("icon_debug_resume", load_image_resume());
	IupSetHandle( "icon_debug", XPM.getIUPimage( "icons/xpm/debug/debug.xpm" ) );//IupSetHandle("icon_debug", load_image_debug());
	IupSetHandle( "icon_debugrun", XPM.getIUPimage( "icons/xpm/debug/debug_run.xpm" ) );
	IupSetHandle( "icon_debugbuild", XPM.getIUPimage( "icons/xpm/debug/debug_build.xpm" ) );
	IupSetHandle( "icon_debug_add", XPM.getIUPimage( "icons/xpm/debug/add.xpm" ) );//IupSetHandle("icon_debug_add", load_image_add());
	IupSetHandle( "icon_debug_next", XPM.getIUPimage( "icons/xpm/debug/over.xpm" ) );//IupSetHandle("icon_debug_next", load_image_next());
	IupSetHandle( "icon_debug_left", XPM.getIUPimage( "icons/xpm/debug/left.xpm" ) );//IupSetHandle("icon_debug_left", load_image_left_nav());
	IupSetHandle( "icon_debug_return", XPM.getIUPimage( "icons/xpm/debug/return.xpm" ) );//IupSetHandle("icon_debug_return", load_image_return());
	IupSetHandle( "icon_debug_clear", XPM.getIUPimage( "icons/xpm/debug/clear.xpm" ) );//IupSetHandle("icon_debug_clear", load_image_clear());

	IupSetHandle( "icon_poseidonFB", load_image_poseidonFBico() );
}