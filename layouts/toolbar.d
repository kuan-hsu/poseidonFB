module layouts.toolbar;

private import iup.iup, iup.iup_scintilla;;
private import global, actionManager, menu, executer, scintilla, project;

private import tango.sys.Process, tango.core.Exception, tango.io.stream.Lines, tango.io.stream.Iterator, tango.stdc.stringz, tango.io.UnicodeFile;
private import tango.io.Stdout;


Ihandle* createToolBar()
{
	Ihandle* hBox;

	Ihandle* btnNew, btnOpen;
	Ihandle* btnSave, btnSaveAll;
	Ihandle* btnUndo, btnRedo;
	Ihandle* btnCut, btnCopy, btnPaste;
	Ihandle* btnMark, btnMarkPrev, btnMarkNext, btnMarkClean;
	Ihandle* btnCompile, btnRun, btnBuildAll, btnQuickRun;

	btnNew		= IupButton( null, "New" );
	btnOpen		= IupButton( null, "Open" );

	btnSave		= IupButton( null, "Save" );
	btnSaveAll	= IupButton( null, "SaveAll" );	

	btnUndo		= IupButton( null, "Undo" );
	btnRedo		= IupButton( null, "Redo" );
	
	btnCut		= IupButton( null, "Cut" );
	btnCopy		= IupButton( null, "Copy" );
	btnPaste	= IupButton( null, "Paste" );

	btnMark		= IupButton( null, "Mark" );
	btnMarkPrev	= IupButton( null, "MarkPrev" );
	btnMarkNext	= IupButton( null, "MarkNext" );
	btnMarkClean= IupButton( null, "MarkClean" );
	
	btnCompile	= IupButton( null, "Mark" );
	btnRun		= IupButton( null, "MarkPrev" );
	btnBuildAll	= IupButton( null, "MarkNext" );
	btnQuickRun = IupButton( null, "MarkClean" );


	IupSetAttributes( btnNew, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_newfile,TIP=New_File" );
	IupSetCallback( btnNew, "ACTION", cast(Icallback) &menu.newFile_cb ); // From menu.d

	IupSetAttributes( btnOpen, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_openfile,TIP=OPEN" );
	IupSetCallback( btnOpen, "ACTION", cast(Icallback) &menu.openFile_cb ); // From menu.d

	IupSetAttributes( btnSave, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_save,TIP=Save" );
	IupSetCallback( btnSave, "ACTION", cast(Icallback) &menu.saveFile_cb ); // From menu.d

	IupSetAttributes( btnSaveAll, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_saveall,TIP=Save_All" );
	IupSetCallback( btnSaveAll, "ACTION", cast(Icallback) &menu.saveAllFile_cb ); // From menu.d


	IupSetAttributes( btnUndo, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_undo,TIP=Undo" );
	IupSetCallback( btnUndo, "ACTION", cast(Icallback) &menu.undo_cb ); // From menu.d
	
	IupSetAttributes( btnRedo, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_redo,TIP=Redo" );
	IupSetCallback( btnRedo, "ACTION", cast(Icallback) &menu.redo_cb ); // From menu.d
	
	IupSetAttributes( btnCut, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_cut,TIP=Cut" );
	IupSetCallback( btnCut, "ACTION", cast(Icallback) &menu.cut_cb ); // From menu.d
	
	IupSetAttributes( btnCopy, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_copy,TIP=Copy" );
	IupSetCallback( btnCopy, "ACTION", cast(Icallback) &menu.copy_cb ); // From menu.d
	
	IupSetAttributes( btnPaste, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_paste,TIP=Paste" );
	IupSetCallback( btnPaste, "ACTION", cast(Icallback) &menu.paste_cb ); // From menu.d

	IupSetAttributes( btnMark, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_mark,TIP=Mark_Bookmark" );
	//IupSetCallback( btnMark, "ACTION", cast(Icallback) &btnMark_cb );
	IupSetCallback( btnMark, "ACTION", cast(Icallback) function()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166
			
			if( IupGetIntId( ih, "MARKERGET", currentLine ) & 2 )
			{
				IupSetIntId( ih, "MARKERDELETE", currentLine, 1 );
			}
			else
			{
				IupSetIntId( ih, "MARKERADD", currentLine, 1 );
			}
		}		
	});
	
	IupSetAttributes( btnMarkPrev, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_markprev,TIP=Prev_Bookmark" );
	//IupSetCallback( btnMarkPrev, "ACTION", cast(Icallback) &btnMarkPrev_cb );
	IupSetCallback( btnMarkPrev, "ACTION", cast(Icallback) function()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

			IupSetIntId( ih, "MARKERPREVIOUS", --currentLine, 2 );
			
			int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

			if( markLineNumber < 0 )
			{
				int count = IupGetInt( ih, "LINECOUNT" );
				IupSetIntId( ih, "MARKERPREVIOUS", count, 2 );
				markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
				if( markLineNumber < 0 ) return;
			}			
			
			IupSetFocus( ih );
			if( markLineNumber > -1 ) IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
			StatusBarAction.update();
		}		
	});
	
	IupSetAttributes( btnMarkNext, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_marknext,TIP=Next_Bookmark" );
	//IupSetCallback( btnMarkNext, "ACTION", cast(Icallback) &btnMarkNext_cb );
	IupSetCallback( btnMarkNext, "ACTION", cast(Icallback) function()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

			IupSetIntId( ih, "MARKERNEXT", ++currentLine, 2 );
			
			int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

			if( markLineNumber < 0 )
			{
				IupSetIntId( ih, "MARKERNEXT", 0, 2 );
				markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
				if( markLineNumber < 0 ) return;
			}

			IupSetFocus( ih );
			IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
			StatusBarAction.update();
		}
	});
	
	IupSetAttributes( btnMarkClean, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_markclear,TIP=Clear_Bookmark" );
	//IupSetCallback( btnMarkClean, "ACTION", cast(Icallback) &btnMarkClean_cb );
	IupSetCallback( btnMarkClean, "ACTION", cast(Icallback) function()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetInt( ih, "MARKERDELETEALL", 1 );
	});


	IupSetAttributes( btnCompile, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_compile,TIP=Compile" );
	IupSetCallback( btnCompile, "ACTION", cast(Icallback) &menu.compile_cb ); // From menu.d

	IupSetAttributes( btnRun, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_run,TIP=Run" );
	IupSetCallback( btnRun, "ACTION", cast(Icallback) &menu.run_cb ); // From menu.d

	IupSetAttributes( btnBuildAll, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_rebuild,TIP=Rebuild_All" );
	IupSetAttribute( btnBuildAll, "TIP", "Rebuild All" );
	IupSetCallback( btnBuildAll, "ACTION", cast(Icallback) &menu.buildAll_cb ); // From menu.d

	IupSetAttributes( btnQuickRun, "ALIGNMENT=ALEFT:ATOP,FLAT=YES,IMAGE=icon_quickrun,TIP=Quick Run" );
	IupSetAttribute( btnQuickRun, "TIP", "Quick Run" );
	IupSetCallback( btnQuickRun, "ACTION", cast(Icallback) &menu.quickRun_cb ); // From menu.d


	Ihandle*[5] labelSEPARATOR;
	for( int i = 0; i < 5; i++ )
	{
		labelSEPARATOR[i] = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
	}
	
	// IUP Container to put buttons on~
	hBox = IupHbox( btnNew, btnOpen, labelSEPARATOR[0], btnSave, btnSaveAll, labelSEPARATOR[3], btnUndo, btnRedo, labelSEPARATOR[1], btnCut, btnCopy, btnPaste, labelSEPARATOR[2], btnMark, btnMarkPrev,
					btnMarkNext, btnMarkClean, labelSEPARATOR[4], btnCompile, btnRun, btnBuildAll, btnQuickRun, null );
	IupSetAttributes( hBox, "GAP=5" );

	return hBox;
}

/+
extern(C)
{
	void btnMark_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166
			
			if( IupGetIntId( ih, "MARKERGET", currentLine ) & 2 )
			{
				IupSetIntId( ih, "MARKERDELETE", currentLine, 1 );
			}
			else
			{
				IupSetIntId( ih, "MARKERADD", currentLine, 1 );
			}
		}
	}

	void btnMarkPrev_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

			IupSetIntId( ih, "MARKERPREVIOUS", --currentLine, 2 );
			
			int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

			if( markLineNumber < 0 )
			{
				int count = IupGetInt( ih, "LINECOUNT" );
				IupSetIntId( ih, "MARKERPREVIOUS", count, 2 );
				markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
				if( markLineNumber < 0 ) return;
			}			
			
			IupSetFocus( ih );
			if( markLineNumber > -1 ) IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
			StatusBarAction.update();
		}
	}

	void btnMarkNext_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null )
		{
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

			IupSetIntId( ih, "MARKERNEXT", ++currentLine, 2 );
			
			int markLineNumber 		= IupGetInt( ih, "LASTMARKERFOUND" );

			if( markLineNumber < 0 )
			{
				IupSetIntId( ih, "MARKERNEXT", 0, 2 );
				markLineNumber = IupGetInt( ih, "LASTMARKERFOUND" );
				if( markLineNumber < 0 ) return;
			}

			IupSetFocus( ih );
			IupScintillaSendMessage( ih, 2024, markLineNumber, 0 ); // SCI_GOTOLINE = 2024
			StatusBarAction.update();
		}
	}

	void btnMarkClean_cb()
	{
		Ihandle* ih = actionManager.ScintillaAction.getActiveIupScintilla();
		if( ih != null ) IupSetInt( ih, "MARKERDELETEALL", 1 );
	}
}
+/
