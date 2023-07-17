module tools;

private import iup.iup;
private import global, project, actionManager;
private import std.string, std.conv, Array = std.array, std.file, Uni = std.uni, Path = std.path;
private import core.stdc.stdlib, core.stdc.string, core.thread;


struct Stack(T)
{
@safe:
    T[] data;
    @property bool empty(){ return data.empty; }

    @property size_t size(){ return data.length; }

    void push(T val){ data ~= val;  }
	
	void clear(){ data.length = 0;  }

    @trusted T pop()
    {
        if( empty ) return null;
        auto val = data[$ - 1];
        data = data[0 .. $ - 1];
        if (!__ctfe)
            cast(void) data.assumeSafeAppend();
        return val;
    }

    @property T top()
    {
        if( empty ) return null;
        return data[$ - 1];
    }
}


class IupString
{
private:
	char*	_CstringPointer = null;

	void copy( string Dstring )
	{
		_CstringPointer = cast(char*)calloc( Dstring.length + 1, 1 );
		memcpy( _CstringPointer, Dstring.ptr, Dstring.length );
	}
	
	char* convert( string Dstring )
	{
		if( _CstringPointer != null ) free( _CstringPointer );
		copy( Dstring );

		return _CstringPointer;
	}	

public:
	this(){}
	
	this( string Dstring )
	{
		copy( Dstring );
	}

	this( char* Cstring )
	{
		if( Cstring != null )
		{
			auto _len = strlen( Cstring );
			_CstringPointer = cast(char*)calloc( _len + 1, 1 );
			memcpy( _CstringPointer, Cstring, _len );
		}
	}	

	~this()
	{
		if( _CstringPointer != null ) free( _CstringPointer );
	}
	
	void opAssign( string rhs )
	{
		convert( rhs );
	}
	
	void opAssign( char* rhs )
	{
		convert( fromStringz( rhs ).dup );
	}

	char* toCString()
	{
		return _CstringPointer;
	}

	string toDString()
	{
		if( _CstringPointer != null ) return fSTRz( _CstringPointer );
		return null;
	}
}

char* getCString( string Dstring )
{
	char* CstringPointer = cast(char*)calloc( 1, Dstring.length + 1 );
	memcpy( CstringPointer, Dstring.ptr, Dstring.length );

	return CstringPointer;
}

void freeCString( char* cString )
{
	if( cString != null )
	{
		free( cString );
		cString = null;
	}
}

string fSTRz( return scope inout(char)* cString )
{
	return fromStringz( cString ).dup;
}


string fullPathByOS( string s )
{
	version(Windows) return Uni.toLower( s );
	return s;
}

uint convertIupColor( string color )
{
	uint result = 0xffffff;
	
	if( color.length > 1 )
	{
		if( color[0] == '#' )
		{
			color = "0x" ~ color[1..$];
			result = to!(uint)( color );
		}
		else if( color[0..2] == "0x" )
		{
			result = to!(uint)( color );
		}
		else
		{
			string[] colors = split( color, " " );
			if( colors.length == 3 )
			{
				result = ( to!(uint)( colors[2] ) << 16 ) | ( to!(uint)( colors[1] ) << 8 ) | ( to!(uint)( colors[0] ) );
			}
		}
	}

	return result;
}


version(FBIDE)
{
	string convertKeyWordCase( int type, string replaceText )
	{
		switch( type )
		{
			case 1: replaceText = Uni.toLower( replaceText ); break; // lowercase
			case 2: replaceText = Uni.toUpper( replaceText ); break; // UPPERCASE
			case 3: replaceText = capitalize( replaceText ); break; // MixCase
			default:
		}

		return replaceText;
	}
}

version(DIDE)
{
	int DMDversion( string dmdFullPath )
	{
		if( Path.stripExtension( Path.baseName( dmdFullPath ) ) == "ldc2" ) return 4;
		version(Windows)
			if( exists( Path.dirName( dmdFullPath ) ~ "/dub.exe" ) ) return 2;
		else
			if( exists( Path.dirName( dmdFullPath ) ~ "/dub" ) ) return 2;
		
		return 1;
	}
}
	
bool isParsableExt( string _ext, int flag = 7 )
{
	if( !_ext.length ) return false;
	
	_ext = toLower( _ext );
	
	version(FBIDE)
	{
		if( _ext == ".bas" )
		{
			if( flag & 1 ) return true;
		}
		else if( _ext == ".bi" )
		{
			if( flag & 2 ) return true;
		}
		else if( _ext == GLOBAL.extraParsableExt )
		{
			if( !GLOBAL.extraParsableExt.length ) return false;
			if( flag & 4 ) return true;
		}
	}
	else
	{
		if( _ext == ".d" )
		{
			if( flag & 1 ) return true;
		}
		else if( _ext == ".di" )
		{
			if( flag & 2 ) return true;
		}
	}
	
	return false;
}


string normalizeSlash( string s )
{
	import std.array, std.path;
	
	version(Windows)
	{
		return std.array.replace( std.path.buildNormalizedPath( s ), "\\", "/" );
	}
	else
	{
		return std.path.buildNormalizedPath( s );
	}
	
	return s;
}

version(Windows)
{
	import UTF = std.utf, core.sys.windows.shellapi, core.sys.windows.winbase;
	
	int Execute( string filename, string parameters, string cwd )
	{
		filename = Array.replace( filename, "/", "\\" ); 
		parameters = Array.replace( parameters, "/", "\\" );
		cwd = Array.replace( cwd, "/", "\\" ); 

		int err = cast(int) ShellExecute( null, "open", UTF.toUTF16z( filename ), UTF.toUTF16z( parameters ), UTF.toUTF16z( cwd ), 1); // SW_SHOWNORMAL = 1
		if (err <= 32)
		{
			switch (err)
			{
				case 2://ERROR_FILE_NOT_FOUND:
				case 3://ERROR_PATH_NOT_FOUND:
					return -2; /* File not found */
				default:
					return -1; /* Generic error */
			}
		}
		return 1;
	}	

	int ExecuteWait( string filename, string parameters, string cwd )
	{
		filename = Array.replace( filename, "/", "\\" );
		parameters = Array.replace( parameters, "/", "\\" ) ;
		cwd = Array.replace( cwd, "/", "\\" ); 
		
		SHELLEXECUTEINFO ExecInfo;
		memset(&ExecInfo, 0, SHELLEXECUTEINFO.sizeof);

		ExecInfo.cbSize = SHELLEXECUTEINFO.sizeof;
		//ExecInfo.fMask = SEE_MASK_NOASYNC | SEE_MASK_NOCLOSEPROCESS | SEE_MASK_FLAG_NO_UI | SEE_MASK_NO_CONSOLE;
		ExecInfo.fMask = 0x00000100 | 0x00000040 | 0x00000400 | 0x00008000;
		ExecInfo.hwnd = null;
		ExecInfo.lpVerb = "open";
		ExecInfo.lpFile = UTF.toUTF16z(filename);
		ExecInfo.lpParameters = UTF.toUTF16z(parameters);
		ExecInfo.lpDirectory = UTF.toUTF16z(cwd);
		ExecInfo.nShow = 1;//SW_SHOWNORMAL;

		if (!ShellExecuteEx(&ExecInfo))
		{
			int err = cast(int)ExecInfo.hInstApp;
			switch (err)
			{
			case SE_ERR_FNF:
			case SE_ERR_PNF:
			  return -2; /* File not found */
			default:
			  return -1; /* Generic error */
			}
		}

		WaitForSingleObject(ExecInfo.hProcess, INFINITE);

		return 1;
	}
}


version(Posix) string modifyLinuxDropFileName( string _fn )
{
	string result;
	
	for( int i = 0; i < _fn.length; ++ i )
	{
		if( _fn[i] != '%' )
		{
			result ~= _fn[i];
		}
		else
		{
			if( i + 2 < _fn.length )
			{
				char _a = _fn[i+1];
				char _b = _fn[i+2];
				char computeValue;
				
				if( _a >= '0' && _a <= '9' )
				{
					computeValue = cast(char) ( ( _a - 48 ) * 16 );
				}
				else if( _a >= 'A' && _a <= 'F' )
				{
					computeValue = cast(char) ( ( _a - 55 ) * 16 );
				}
				else
				{
					break;
				}
				
				if( _b >= '0' && _b <= '9' )
				{
					computeValue += ( _b - 48 );
				}
				else if( _b >= 'A' && _b <= 'F' )
				{
					computeValue += ( _b - 55 );
				}
				else
				{
					break;
				}
		
				result ~= cast(char)computeValue;
				
				i += 2;
			}
		}
	}
	
	return result;
}


FocusUnit getActiveCompilerInformation( string fromProjectDir = null )
{
	import std.stdio;
	FocusUnit _focus;
	
	// Check custom compiler 
	string customOpt, customCompiler;
	CustomToolAction.getCustomCompilers( customOpt, customCompiler );
	if( !customCompiler.length ) customCompiler = ( GLOBAL.compilerSettings.Bit64 == "OFF" ? GLOBAL.compilerSettings.compilerFullPath : GLOBAL.compilerSettings.x64compilerFullPath );
	
	string activePrjName = !fromProjectDir.length ? ProjectAction.getActiveProjectName : fromProjectDir;
	if( activePrjName.length )
	{
		_focus.Compiler = GLOBAL.projectManager[activePrjName].compilerPath;
		_focus.Option = GLOBAL.projectManager[activePrjName].compilerOption;
		_focus.Target = GLOBAL.projectManager[activePrjName].targetName;
		_focus.IncDir = GLOBAL.projectManager[activePrjName].includeDirs;
		_focus.LibDir = GLOBAL.projectManager[activePrjName].libDirs;
		if( GLOBAL.projectManager[activePrjName].focusOn.length )
		{
			if( GLOBAL.projectManager[activePrjName].focusOn in GLOBAL.projectManager[activePrjName].focusUnit ) _focus = GLOBAL.projectManager[activePrjName].focusUnit[GLOBAL.projectManager[activePrjName].focusOn];
		}
		// If project has no options, just no options!
		if( !_focus.Compiler.length ) _focus.Compiler = customCompiler;
		if( fromProjectDir.length ) _focus.IncDir = [ fromProjectDir ] ~ _focus.IncDir;

		string[] _compilerDefaultImportPath = getCompilerImportPath( _focus.Compiler );
		if( _compilerDefaultImportPath.length ) _focus.IncDir ~= _compilerDefaultImportPath; // IncDir include compiler 
		return _focus;
	}

	_focus.Compiler = customCompiler;
	_focus.Option = customOpt;
	string[] _compilerDefaultImportPath = getCompilerImportPath( _focus.Compiler );
	if( _compilerDefaultImportPath.length ) _focus.IncDir ~= _compilerDefaultImportPath; // IncDir include compiler 	
	
	return _focus;
}


string[] getCompilerImportPath( string compilerFullPath )
{
	version(FBIDE)
	{
		version(Windows)
		{
			return [Path.dirName( compilerFullPath ) ~ "/inc"];
		}
		else
		{
			if( compilerFullPath == "fbc" ) return ["/usr/local/include/freebasic"];
			return [Path.buildNormalizedPath( Path.dirName( compilerFullPath )  ~ "/../include/freebasic" )];
		}
	}
	else // version(DIDE)
	{
		// Get and Set Default Import Path
		string compilerPath = Path.dirName( compilerFullPath ); // Without last /
		string scFullPath;
		version(Windows)
		{
			scFullPath = compilerPath ~ "/sc.ini";
		}
		else
		{
			scFullPath = compilerPath ~ "/dmd.conf";
			if( !exists( scFullPath ) ) scFullPath = "/etc/dmd.conf";
		}
		
		string[] results;
		if( exists( scFullPath ) )
		{
			auto scfile = cast(string) std.file.read( scFullPath );
			foreach( line; std.string.splitLines( scfile ) )
			{
				if( line.length > 7 )
				{
					if( line[0..7] == "DFLAGS=" )
					{
						line = Array.replace( line[7..$], "\t", " " ); // Convert TAB -> SPACE
						if( line.length )
						{
							ptrdiff_t endPos;
							auto iPos = indexOf( line, "-I" );
							while( iPos > -1 )
							{
								bool bWithQuote;
								if( iPos > endPos )
									if( line[iPos-1] == '"' ) bWithQuote = true;
									
								if( bWithQuote )
									endPos = indexOf( line, "\"", iPos + 2 );
								else
									endPos = indexOf( line, " ", iPos + 2 );
									
								if( endPos > -1 )
								{
									string _section = line[iPos+2..endPos].dup;
									foreach( string s; Array.split( _section, ";" ) )
									{
										if( s.length )
										{
											s = Array.replace( s, "%@P%", compilerPath );
											results ~= tools.normalizeSlash( s );
										}
									}
									
									iPos = indexOf( line, "-I", endPos );
								}
								else
									break;
							}
						}
					}
				}
			}
		}
		return results;
	}
	return null;
}


void* DyLibLoad( string libName )
{
	import core.runtime;
	return Runtime.loadLibrary( libName );
}

void* DyLibSymbol( void* lib, string symName )
{
	if( !lib ) return null;
	
	version(Windows)
	{
		import core.sys.windows.winbase:GetProcAddress;
		return GetProcAddress( lib, toStringz( symName ) );
	}
	else
	{
		import core.sys.posix.dlfcn;
		
		auto ret = dlsym( lib, toStringz( symName ) );
		char* error = dlerror();
		if( error ) return null;
		
		return ret;
	}
}

void DyLibFree( void* lib )
{
	import core.runtime;
	Runtime.unloadLibrary( lib );
}


// DLL loader, code form Tango Library, 
version (Posix) {
    version (FreeBSD) { } else { pragma (lib, "dl"); }
}

final class SharedLib
{
	import std.string;
	version(Windows)
		import core.sys.windows.winbase, core.sys.windows.windef, core.sys.windows.winnls;
	else
		import core.sys.posix.dlfcn;
		
    // Mapped from RTLD_NOW, RTLD_LAZY, RTLD_GLOBAL and RTLD_LOCAL
    enum LoadMode
	{
        Now = 0b1,
        Lazy = 0b10,
        Global = 0b100,
        Local = 0b1000
    }


    /**
        Loads an OS-specific shared library.
        Note:
        Please use this function instead of the constructor, which is private.
        Params:
            path = The path to a shared library to be loaded
            mode = Library loading mode. See LoadMode
        Returns:
            A SharedLib instance being a handle to the library, or throws
            SharedLibException if it could not be loaded
      */
    static SharedLib load(const(char)[] path, LoadMode mode = LoadMode.Now | LoadMode.Global) {
    	return loadImpl(path, mode, true);
    }

    /**
        Loads an OS-specific shared library.
        Note:
        Please use this function instead of the constructor, which is private.
        Params:
            path = The path to a shared library to be loaded
            mode = Library loading mode. See LoadMode
        Returns:
            A SharedLib instance being a handle to the library, or null if it
            could not be loaded
      */
    static SharedLib loadNoThrow(const(char)[] path, LoadMode mode = LoadMode.Now | LoadMode.Global) {
    	return loadImpl(path, mode, false);
    }


    private static SharedLib loadImpl(const(char)[] path, LoadMode mode, bool throwExceptions) {
        SharedLib res;

        synchronized (mutex) {
            auto lib = path in loadedLibs;
            if (lib) {
                version (SharedLibVerbose) Trace.formatln("SharedLib found in the hashmap");
                res = *lib;
            }
            else {
                version (SharedLibVerbose) Trace.formatln("Creating a new instance of SharedLib");
                res = new SharedLib(path);
                loadedLibs[path] = res;
            }

            ++res.refCnt;
        }

        bool delRes = false;
        Exception exc;

        synchronized (res) {
            if (!res.loaded) {
                version (SharedLibVerbose) Trace.formatln("Loading the SharedLib");
                try {
                    res.load_(mode, throwExceptions);
                } catch (Exception e) {
                    exc = e;
                }
            }

            if (res.loaded) {
                version (SharedLibVerbose) Trace.formatln("SharedLib successfully loaded, returning");
                return res;
            } else {
                synchronized (mutex) {
                    if (path in loadedLibs) {
                        version (SharedLibVerbose) Trace.formatln("Removing the SharedLib from the hashmap");
                        loadedLibs.remove(path);
                    }
                }
            }

            // make sure that only one thread will delete the object
            if (0 == --res.refCnt) {
                delRes = true;
            }
        }

        if (delRes) {
            version (SharedLibVerbose) Trace.formatln("Deleting the SharedLib");
            res.destroy;
        }

        if (exc !is null) {
            throw exc;
        }

        version (SharedLibVerbose) Trace.formatln("SharedLib not loaded, returning null");
        return null;
    }


    /**
        Unloads the OS-specific shared library associated with this SharedLib instance.
        Note:
        It's invalid to use the object after unload() has been called, as unload()
        will delete it if it's not referenced any more.
        Throws SharedLibException on failure. In this case, the SharedLib object is not deleted.
      */
    void unload() {
    	return unloadImpl(true);
    }


    /**
        Unloads the OS-specific shared library associated with this SharedLib instance.
        Note:
        It's invalid to use the object after unload() has been called, as unload()
        will delete it if it's not referenced any more.
      */
    void unloadNoThrow() {
    	return unloadImpl(false);
    }


    private void unloadImpl(bool throwExceptions) {
        bool deleteThis = false;

        synchronized (this) {
            assert (loaded);
            assert (refCnt > 0);

            synchronized (mutex) {
                if (--refCnt <= 0) {
                    version (SharedLibVerbose) Trace.formatln("Unloading the SharedLib");
                    try {
                        unload_(throwExceptions);
                    } catch (Exception e) {
                        ++refCnt;
                        throw e;
                    }

                    assert ((path in loadedLibs) !is null);
                    loadedLibs.remove(path);

                    deleteThis = true;
                }
            }
        }
        if (deleteThis) {
            version (SharedLibVerbose) Trace.formatln("Deleting the SharedLib");
            ((SharedLib l) { l.destroy; })(this);
        }
    }


    /**
        Returns the path to the OS-specific shared library associated with this object.
      */
    @property const(char)[] path() {
        return this.path_;
    }


    /**
        Obtains the address of a symbol within the shared library
        Params:
            name = The name of the symbol; must be a null-terminated C string
        Returns:
            A pointer to the symbol or throws SharedLibException if it's
            not present in the library.
      */
    void* getSymbol(const(char)* name) {
       return getSymbolImpl(name, true);
    }


    /**
        Obtains the address of a symbol within the shared library
        Params:
            name = The name of the symbol; must be a null-terminated C string
        Returns:
            A pointer to the symbol or null if it's not present in the library.
      */
    void* getSymbolNoThrow(const(char)* name) {
       return getSymbolImpl(name, false);
    }


    private void* getSymbolImpl(const(char)* name, bool throwExceptions) {
        assert (loaded);
        return getSymbol_(name, throwExceptions);
    }



    /**
        Returns the total number of libraries currently loaded by SharedLib
      */
    static uint numLoadedLibs() {
        return cast(uint) loadedLibs.keys.length;
    }


    private {
        version (Windows) {
            HMODULE handle;

            void load_(LoadMode mode, bool throwExceptions) {
                version (Win32SansUnicode)
                         handle = LoadLibraryA((this.path_ ~ "\0").ptr);
                    else {
                         wchar[1024] tmp = void;
                         auto i = MultiByteToWideChar (CP_UTF8, 0,
                                                       path.ptr, cast(int) path.length,
                                                       tmp.ptr, tmp.length-1);
                         if (i > 0)
                            {
                            tmp[i] = 0;
                            handle = LoadLibraryW (tmp.ptr);
                            }
                    }
                if (handle is null && throwExceptions) {
                    throw new Exception("Couldn't load shared library '" ~ this.path_.idup ~ "' : " /*~ SysError.lastMsg.idup*/);
                }
            }

            void* getSymbol_(const(char)* name, bool throwExceptions) {
                // MSDN: "Multiple threads do not overwrite each other's last-error code."
                auto res = GetProcAddress(handle, name);
                if (res is null && throwExceptions) {
                    throw new Exception("Couldn't load symbol '" ~ fromStringz(name).idup ~ "' from shared library '" ~ this.path_.idup ~ "' : "/* ~ SysError.lastMsg.idup*/);
                } else {
                    return res;
                }
            }

            void unload_(bool throwExceptions) {
                if (0 == FreeLibrary(handle) && throwExceptions) {
                    throw new Exception("Couldn't unload shared library '" ~ this.path_.idup ~ "' : "/* ~ SysError.lastMsg.idup*/);
                }
            }
        }
        else version (Posix) {
            void* handle;

            void load_(LoadMode mode, bool throwExceptions) {
                int mode_;
                if (mode & LoadMode.Now) mode_ |= RTLD_NOW;
                if (mode & LoadMode.Lazy) mode_ |= RTLD_LAZY;
                if (mode & LoadMode.Global) mode_ |= RTLD_GLOBAL;
                if (mode & LoadMode.Local) mode_ |= RTLD_LOCAL;

                handle = dlopen((this.path_ ~ "\0").ptr, mode_);
                if (handle is null && throwExceptions) {
                    throw new Exception("Couldn't load shared library: " ~ fromStringz(dlerror()).idup);
                }
            }

            void* getSymbol_(const(char)* name, bool throwExceptions) {
                if (throwExceptions) {
                    synchronized (typeof(this).classinfo) { // dlerror need not be reentrant
                        auto err = dlerror();               // clear previous error condition
                        auto res = dlsym(handle, name);     // result of null does NOT indicate error
                        
                        err = dlerror();                    // check for error condition
                        if (err !is null) {
                            throw new Exception("Couldn't load symbol: " ~ fromStringz(err).idup);
                        } else {
                            return res;
                        }
                    }
                } else {
                    return dlsym(handle, name);
                }
            }

            void unload_(bool throwExceptions) {
                if (0 != dlclose(handle) && throwExceptions) {
                    throw new Exception("Couldn't unload shared library: " ~ fromStringz(dlerror()).idup);
                }
            }
        }
        else {
            static assert (false, "No support for this platform");
        }


        const(char)[] path_;
        int refCnt = 0;


        @property bool loaded() {
            return handle !is null;
        }


        this(const(char)[] path) {
            this.path_ = path;
        }
    }


    private __gshared {
        SharedLib[char[]] loadedLibs;
        Object mutex;
    }


    shared static this() {
        mutex = new Object;
    }
}



/+
Process Class
The issue: https://forum.dlang.org/thread/jpdoormeobwxrszcyrmg@forum.dlang.org

Process class
Code by DannyArends
https://github.com/DannyArends/DaNode
+/
class Process : Thread
{
private:
	import std.stdio, std.process, std.datetime, std.array, std.format, std.file;
	version(Posix) import core.sys.posix.fcntl : fcntl, F_SETFL, O_NONBLOCK;
	
	struct WaitResult {
	  bool terminated; /// Is the process terminated
	  int status; /// Exit status when terminated
	}
	
	
	string            command;              /// Command to execute
	/+string            inputfile;            /// Path of input file+/
	bool              completed = false;
	/+bool              removeInput = true;+/

	/+File              fStdIn;               /// Input file stream+/
	File              fStdOut;              /// Output file stream
	File              fStdErr;              /// Error file stream

	Pipe              pStdOut;              /// Output pipe
	Pipe              pStdErr;              /// Error pipe

	WaitResult        process;              /// Process try/wait results
	SysTime           starttime;            /// Time in ms since this process came alive
	SysTime           modified;             /// Time in ms since this process was modified
	long              maxtime;              /// Maximum time in ms before we kill the process

	Appender!(char[])  outbuffer;           /// Output appender buffer
	Appender!(char[])  errbuffer;           /// Error appender buffer
	
	string				cwd;


	/* Set a filestream to nonblocking mode, if not Posix, use winbase.h */
	bool nonblocking(ref File file) {
	  version(Posix) {
		return(fcntl(fileno(file.getFP()), F_SETFL, O_NONBLOCK) != -1); 
	  }else{
		import core.sys.windows.winbase;
		auto x = PIPE_NOWAIT;
		auto res = SetNamedPipeHandleState(file.windowsHandle(), &x, null, null);
		return(res != 0);
	  }
	}
	
	version(Posix) {
	  alias kill killProcess;
	}else{
	  /* Windows hack: Spawn a new process to kill the still running process */
	  void killProcess(Pid pid, uint signal) { executeShell(format("taskkill /F /T /PID %d", pid.processID)); }
	}


public:
	/+
    this(string command, string inputfile, bool removeInput = true, long maxtime = 4500) {
      this.command = command;
      this.inputfile = inputfile;
      this.removeInput = removeInput;
      this.maxtime = maxtime;
      this.starttime = Clock.currTime();
      this.modified = Clock.currTime();
      this.outbuffer = appender!(char[])();
      this.errbuffer = appender!(char[])();
      super(&run);
    }
	+/
	this( string command, string cwd, long maxtime = 4500 )
	{
		this.command = command;
		this.maxtime = maxtime;
		this.starttime = Clock.currTime();
		this.modified = Clock.currTime();
		this.outbuffer = appender!(char[])();
		this.errbuffer = appender!(char[])();
		this.cwd = cwd;
		
		super(&run);
	}	

     // Query Output/Errors from 'from' to the end, if the outbuffer contains any output this will be served
     // from is checked to be in-range of the outbuffer/errbuffer, if not an empty array is returned
    final @property const(char)[] output(ptrdiff_t from) const { 
      synchronized {
        if (outbuffer.data.length > 0 && from >= 0 && from <= outbuffer.data.length) {
          return outbuffer.data[from .. $];
        }
        if (from >= 0 && from <= errbuffer.data.length) {
          return errbuffer.data[from .. $]; 
        }
        return [];
      }
    }

    // Runtime of the thread in mseconds
    final @property long time() const
	{
			synchronized { return(0); }
      //synchronized { return(Msecs(starttime)); }
    }

    // Last time the process was modified (e.g. data on stdout/stderr)
    final @property long lastmodified() const
	{
		synchronized { return(0); }
      //synchronized { return(Msecs(modified)); }
    }

    // Is the external process still running ?
    final @property bool running() const { 
      synchronized { return(!process.terminated); }
    }

    // Did our internal thread finish processing the external process, etc ?
    final @property bool finished() const { 
      synchronized { return(this.completed); }
    }

    // Returns the 'flattened' exit status of the external process 
    // ( -1 = non-0 exit code, 0 = succes, 1 = still running )
    final @property int status() const { 
      synchronized { 
        if (running) return 1;
        if (process.status == 0) return 0;
        return -1;
      }
    }

    // Length of output, if the outbuffer contains any data, the outbuffer will be prefered (errors are silenced)
    final @property long length() const { synchronized { 
      if (outbuffer.data.length > 0) { return(outbuffer.data.length); }
      return errbuffer.data.length; 
    } }

    // Read a character from a filestream and append it to buffer
    // TODO: Use another function an read more bytes at the same time
    void readpipe (ref File file, ref Appender!(char[]) buffer) {
      try {
        int ch;
        auto fp = file.getFP();
        while ((ch = fgetc(fp)) != EOF && lastmodified < maxtime) { 
          modified = Clock.currTime(); 
          buffer.put(cast(char) ch);
        }
      } catch (Exception e) {
        debug writefln("exception during readpipe command: %s", e.msg);
        file.close();
      }
    }
    
    @property void notifyovertime() { maxtime = -1; }

    
    // Execute the process
    // check the input path, and create a pipe:StdIn to the input file
    // create 2 pipes for the external process stdout & stderr
    // execute the process and wait until maxtime has finished or the process returns
    // inputfile is removed when the run() returns succesfully, on error, it is kept
    final void run() {
      try {
        int  ch;
		/+
        if( !exists(inputfile) ) {
          writefln("no input path: %s", inputfile);
          this.process.terminated = true;
          this.completed = true;
          return;
        }
        fStdIn = File(inputfile, "r");
		+/
        pStdOut = pipe(); pStdErr = pipe();
        /+writeln( format( "PROC command: %s < %s", command, inputfile));+/
        auto cpid = spawnShell(command, stdin, pStdOut.writeEnd, pStdErr.writeEnd, null, Config.suppressConsole, cwd );

        fStdOut = pStdOut.readEnd;
        /+if(!nonblocking(fStdOut) && fStdOut.isOpen()) writeln(2, "WARN", "unable to create nonblocking stdout pipe for command");+/
		if(!nonblocking(fStdOut) && fStdOut.isOpen()) throw new Exception( "WARN : unable to create nonblocking stdout pipe for command");
		
        fStdErr = pStdErr.readEnd;
        /+if(!nonblocking(fStdErr) && fStdErr.isOpen()) writeln(2, "WARN", "unable to create nonblocking error pipe for command");+/
		if(!nonblocking(fStdErr) && fStdErr.isOpen()) throw new Exception("WARN : unable to create nonblocking error pipe for command");
		
        while (running && lastmodified < maxtime) {
          this.readpipe(fStdOut, outbuffer);  // Non blocking slurp of stdout
          this.readpipe(fStdErr, errbuffer);  // Non blocking slurp of stderr
          process = cast(WaitResult) tryWait(cpid);
          Thread.sleep(msecs(1));
        }
		
        if (!process.terminated) {
          /+writeln("command: %s < %s did not finish in time [%s msecs]", command, inputfile, time());+/
          killProcess(cpid, 9);
          process = WaitResult(true, wait(cpid));
        }
        /+writeln("command finished %d after %s msecs", status(), time());+/

        this.readpipe(fStdOut, outbuffer);  // Non blocking slurp of stdout
        this.readpipe(fStdErr, errbuffer);  // Non blocking slurp of stderr
        /+writeln("Output %d & %d processed after %s msecs", outbuffer.data.length, errbuffer.data.length, time());+/

        // Close the file handles
        /+fStdIn.close();+/ fStdOut.close(); fStdErr.close();
		/+
        writeln("removing process input file %s ? %s", inputfile, removeInput);
        if(removeInput) remove(inputfile);
		+/
        this.completed = true;
      } catch(Exception e) {
        /+writeln("process.d, exception: '%s'", e.msg);+/
		throw new Exception( "Process Class Exception: " ~ e.msg );
      }
    }
	
	/+
	If length of outbuffer and errbuffer are empty, compiler success~
	+/
	int getMessageState()
	{
		int ret;
		if( outbuffer.data.length ) ret = 1;
		if( errbuffer.data.length ) ret = ret | 2;
		return ret;
	}	
}

class CPLUGIN
{
	private:
	import											iup.iup;
	/*
	import											tango.sys.SharedLib;
	import											tango.stdc.stringz;
	*/
	extern(C) void function( char* _fullPath )		poseidon_Dll_Go;
	extern(C) void function()						poseidon_Dll_Release;
	
	SharedLib										sharedLib;
	string											pluginName, pluginPath;
	bool											bSuccess, bReleaseSuccess;
	
	public:
	
	this( string name, string fullPath )
	{
		try
		{
			pluginName = name;
			pluginPath = fullPath;
			
			sharedLib = SharedLib.load( fullPath );
			
			void* iupPtr = sharedLib.getSymbol( "poseidon_Dll_Go" );
			if( iupPtr )
			{
				void **point = cast(void **) &poseidon_Dll_Go; // binding function address from DLL to our function pointer
				*point = iupPtr;
				bSuccess = true;
				
				// Release
				void* iupPtrRelease = sharedLib.getSymbol( "poseidon_Dll_Release" );
				if( iupPtrRelease )
				{
					void **pointRelease = cast(void **) &poseidon_Dll_Release; // binding function address from DLL to our function pointer
					*pointRelease = iupPtrRelease;
					bReleaseSuccess = true;
				}				
			}
			else
			{
				unload();
				IupMessage( "Error", toStringz( "Load poseidon_Dll_Go Symbol in " ~ name ~ " Error!" ) );
				throw new Exception( "Load poseidon_Dll_Go Symbol in " ~ name ~ " Error!" );
			}
		}
		catch( Exception e )
		{
			if( !bSuccess )
			{
				unload();
				IupMessage( "Error", toStringz( "Load " ~ name ~ " Error!\n" ~ e.toString ) );
				throw new Exception( "Load " ~ name ~ " Error!\n" ~ e.toString );
			}
		}
	}
	
	~this()
	{
		if( bReleaseSuccess) poseidon_Dll_Release();
		if( sharedLib !is null ) sharedLib.unload();
	}
	
	void go()
	{
		if( bSuccess ) poseidon_Dll_Go( cast(char*) toStringz( pluginPath ) );
	}
	
	bool isSuccess()
	{
		return bSuccess;
	}
	
	string getPath()
	{
		return pluginPath;
	}
	
	string getName()
	{
		return pluginName;
	}
	
	void unload()
	{
		if( sharedLib !is null )
		{
			if( bReleaseSuccess ) poseidon_Dll_Release();
			sharedLib.unload();
		}
	}
}


/+
BUTTONDEFAULT: Number of the default button. Can be "1", "2" or "3". "2" is valid only for "RETRYCANCEL", "OKCANCEL" and "YESNO" button configurations. "3" is valid only for "YESNOCANCEL". Default: "1".

BUTTONRESPONSE: Number of the pressed button. Can be "1", "2" or "3". Default: "1".

BUTTONS: Buttons configuration. Can have values: "OK", "OKCANCEL", "RETRYCANCEL", "YESNO", or "YESNOCANCEL". Default: "OK". Additionally the "Help" button is displayed if the HELP_CB callback is defined. (RETRYCANCEL and YESNOCANCEL since 3.16)

DIALOGTYPE: Type of dialog defines which icon will be displayed besides the message text. Can have values: "MESSAGE" (No Icon), "ERROR" (Stop-sign), "WARNING" (Exclamation-point), "QUESTION" (Question-mark)  or "INFORMATION" (Letter "i"). Default: "MESSAGE".
+/
int questMessage( string title, string message, string DIALOGTYPE = "QUESTION", string BUTTONS = "YESNO", int _x = IUP_CENTERPARENT, int _y = IUP_CENTERPARENT )
{
	Ihandle* dlg = IupMessageDlg();
	IupSetAttribute( dlg, "PARENTDIALOG", "POSEIDON_MAIN_DIALOG" );
	IupSetStrAttribute( dlg, "DIALOGTYPE", toStringz( DIALOGTYPE ) );
	IupSetStrAttribute( dlg, "TITLE", toStringz( title ) );
	IupSetStrAttribute( dlg, "BUTTONS", toStringz( BUTTONS ) );
	IupSetStrAttribute( dlg, "VALUE", toStringz( message ) );

	IupPopup( dlg, _x, _y );

	int result = IupGetInt(dlg, "BUTTONRESPONSE" );
	IupDestroy( dlg );

	return result;
}


string[] splitSign( string s, string sign ... )
{
	string[]	result;
	string		word;
	
	for( int i = 0; i < s.length; ++i )
	{
		bool bMatchSign;
		foreach( char c; sign )
		{
			if( s[i] == c )
			{
				bMatchSign = true;
				break;
			}
		}
		
		
		if( bMatchSign )
		{
			if( word.length )
			{
				result ~= word;
				word.length = 0;
			}
		}
		else
		{
			word ~= s[i];
		}
	}
	
	if( word.length ) result ~= word;
	
	return result;
}

string setINILineData( string left, string right = "" )
{
	if( !right.length )
	{
		if( left.length > 1 )
		{
			if( left[0] == '[' && left[$-1] == ']' ) return left ~ "\n";
		}
	}
	return left ~ "=" ~ right ~ "\n";
}

// Return: 1 = Block, 2 = Items, 0 = Illegal
int getINILineData( string lineData, out string left, out string right )
{
	if( lineData.length )
		if( lineData[0] == '\'' ) return 0;

		
	auto assignPos = indexOf( lineData, "=" );
	if( assignPos > 0 )
	{
		left	= strip( lineData[0..assignPos] );
		right	= strip( lineData[assignPos+1..$] );
		
		// For previous reversion.....
		if( left.length > 1 )
			if( left[0] == '[' && left[$-1] == ']' ) return 1;

		return 2;
	}
	else
	{
		if( lineData.length > 1 )
		{
			lineData = strip( lineData );
			if( lineData[0] == '[' && lineData[$-1] == ']' ) left = lineData;
			return 1;
		}
	}
	return 0;
}