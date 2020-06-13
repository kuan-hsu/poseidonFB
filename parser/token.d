module parser.token;

version(FBIDE)
{
	private import tools;
	
	enum TOK
	{
		Tassign,			// =
		Tplus,				// +
		Tminus,				// -	
		Tdiv,				// /
		Ttimes,				// *	
		Tmod,				// mod
		Tintegerdiv,		// \
		Tshl,				// shl
		Tshr,				// shr
		Tcaret,				// ^

		Tgreater,			// >
		Tless,				// <
		Tis,				// is

		Tdotdotdot,			// ...
		Tdot,				// .
		Tunderline,			// _
		Texclam,			// !
		Tquest,				// ?
		Tdollar,			// $
		Tquote,				// "
		Tcolon,				// :
		Tcomma,				// ,
		Tpound,				// #
		Tandsign,			// &
		Tat,				// @
		Topenparen,			// (
		Tcloseparen,		// )
		Topenbracket,		// [
		Tclosebracket,		// ]
		Topencurly,			// {
		Tclosecurly,		// }


		Tand,
		Tor,
		Txor,
		Tnot,
		Teqv,
		Timp,

		Tandalso,
		Torelse,

		Tlet,
		Tfor,
		Tto,
		Tnext,
		Tstep,
		Texit,
		Tnew,
		Tdelete,
		Tdo,
		Tloop,
		Twhile,
		Twend,
		Tuntil,
		Tif,
		Tthen,
		Telse,
		Tend,
		Tdim,
		Tas,
		Tenum,
		Ttype,
		Tunion,
		Tfield,
		Treturn,
		Twith,
		Tselect,
		Tcase,
		Tcast,	

		Toption,
		Texplicit,
		

		
		// function
		Tdeclare,
		Tsub,
		Tfunction,
		Tbyval,
		Tbyref,
		Tstdcall,
		Tcdecl,
		Tpascal,
		Toverload,
		Talias,
		Texport,
		Tnaked,

		// data
		Tbyte,
		Tubyte,
		Tshort,
		Tushort,
		Tinteger,
		Tuinteger,
		Tlongint,
		Tulongint,
		Tsingle,
		Tdouble,
		Tstring,
		Tzstring,
		Twstring,
		Tany,
		
		Tconst,
		Tpointer, Tptr,
		Tptraccess,			// ->
		Tunsigned,
		Textern,
		Tcommon,
		Tshared,
		Tstatic,
		Tscope,

		// Array
		Tredim,
		Tvar,
		Tpreserve,
		//Terase,
		
		// class
		Tclass,
		Tprivate,
		Tprotected,
		Tpublic,
		Textends,
		Tobject,
		Tvirtual,
		Tabstract,
		Tconstructor,
		Tdestructor,
		Tproperty,
		Toperator,
		Tthis,
		Tbase,
		Toverride,


		//
		Tinclude,
		Tlibpath,
		Tonce,
		Telseif,
		Tendif,
		Tifdef,
		Tifndef,
		Tdefine,
		Tmacro,
		Tendmacro,
		Tlib,
		
		//Tinclib,
		Tnamespace,
		
		


		//
		Teol, // \n
		Tidentifier,
		Tstrings,
		Tnumbers,


		_INVALID_,
	}

	struct TokenUnit
	{
		TOK		tok;
		char[]	identifier;
		int		lineNumber;
	}

	TOK	IdentToTok( char[] s )
	{
		s = lowerCase( s );
		switch( s )
		{
			case "=":			return TOK.Tassign;
			case "+":			return TOK.Tplus;
			case "-":			return TOK.Tminus;
			case "/":			return TOK.Tdiv;
			case "*":			return TOK.Ttimes;
			case "mod":			return TOK.Tmod;
			case "\\":			return TOK.Tintegerdiv;
			case "shl":			return TOK.Tshl;
			case "shr":	 		return TOK.Tshr;
			case "^":		 	return TOK.Tcaret;
			case ">":		 	return TOK.Tgreater;
			case "<":			return TOK.Tless;
			case "is":	 		return TOK.Tis;
			case "...":			return TOK.Tdotdotdot;
			case ".":		 	return TOK.Tdot;
			case "_":			return TOK.Tunderline;
			case "!":			return TOK.Texclam;
			case "?":		 	return TOK.Tquest;
			case "$":			return TOK.Tdollar;
			case "\"":	 		return TOK.Tquote;
			case ":":		 	return TOK.Tcolon;
			case ",":		 	return TOK.Tcomma;
			case "#":		 	return TOK.Tpound;
			case "&":		 	return TOK.Tandsign;
			case "@":		 	return TOK.Tat;
			case "(":		 	return TOK.Topenparen;
			case ")":		 	return TOK.Tcloseparen;
			case "[":		 	return TOK.Topenbracket;
			case "]":		 	return TOK.Tclosebracket;
			case "{":		 	return TOK.Topencurly;
			case "}":		 	return TOK.Tclosecurly;

			case "and":	 	return TOK.Tand;
			case "or":	 	return TOK.Tor;
			case "xor":	 	return TOK.Txor;
			case "not":	 	return TOK.Tnot;
			case "eqv":	 	return TOK.Teqv;
			case "imp":	 	return TOK.Timp;
			case "andalso": return TOK.Tandalso;
			case "orelse": 	return TOK.Torelse;

			case "let":	 	return TOK.Tlet;
			case "for":	 	return TOK.Tfor;
			case "to":	 	return TOK.Tto;
			case "next":	return TOK.Tnext;
			case "step":	return TOK.Tstep;
			case "exit":	return TOK.Texit;
			case "new":		return TOK.Tnew;
			case "delete":	return TOK.Tdelete;
			case "do":		return TOK.Tdo;
			case "loop":	return TOK.Tloop;
			case "while":	return TOK.Twhile;
			case "wend":	return TOK.Twend;
			case "until":	return TOK.Tuntil;
			case "if":	 	return TOK.Tif;
			case "then":	return TOK.Tthen;
			case "else":	return TOK.Telse;
			case "end":	 	return TOK.Tend;
			case "dim":	 	return TOK.Tdim;
			case "as":	 	return TOK.Tas;
			case "enum":	return TOK.Tenum;
			case "type":	return TOK.Ttype;
			case "union":	return TOK.Tunion;
			case "field":	return TOK.Tfield;
			case "return": 	return TOK.Treturn;
			case "with":	return TOK.Twith;
			case "select":	return TOK.Tselect;
			case "case":	return TOK.Tcase;
			case "cast":	return TOK.Tcast;
			
			case "option":	return TOK.Toption;
			case "explicit":	return TOK.Texplicit;
				
			// function
			case "declare": return TOK.Tdeclare;
			case "sub":	 return TOK.Tsub;
			case "function": return TOK.Tfunction;
			case "byval":	 return TOK.Tbyval;
			case "byref":	 return TOK.Tbyref;
			case "stdcall": return TOK.Tstdcall;
			case "cdecl":	 return TOK.Tcdecl;
			case "pascal": return TOK.Tpascal;
			case "overload": return TOK.Toverload;
			case "alias":	 return TOK.Talias;
			case "export": return TOK.Texport;
			case "naked":	 return TOK.Tnaked;

			
			// data
			case "byte":	 return TOK.Tbyte;
			case "ubyte":	 return TOK.Tubyte;
			case "short":	 return TOK.Tshort;
			case "ushort": return TOK.Tushort;
			case "integer": return TOK.Tinteger;
			case "uinteger": return TOK.Tuinteger;
			case "longint": return TOK.Tlongint;
			case "ulongint": return TOK.Tulongint;
			case "single": return TOK.Tsingle;
			case "double": return TOK.Tdouble;
			case "string": return TOK.Tstring;
			case "zstring": return TOK.Tzstring;
			case "wstring": return TOK.Twstring;
			case "any":	 return TOK.Tany;
			
			case "const":	 return TOK.Tconst;
			case "pointer": return TOK.Tpointer;
			case "ptr":	 return TOK.Tptr;
			case "unsigned": return TOK.Tunsigned;
			case "extern": return TOK.Textern;
			case "common": return TOK.Tcommon;
			case "shared": return TOK.Tshared;
			case "static": return TOK.Tstatic;
			case "scope":	 return TOK.Tscope;

			// Array
			case "redim":	 return TOK.Tredim;
			case "var":	 return TOK.Tvar;
			case "preserve": return TOK.Tpreserve;
			//case "erase":	 return TOK.Terase;

			// class
			case "class":		 return TOK.Tclass;
			case "private":	 return TOK.Tprivate;
			case "protected":	 return TOK.Tprotected;
			case "public":	 return TOK.Tpublic;
			case "extends":	 return TOK.Textends;
			case "object":	 return TOK.Tobject;
			case "virtual":	 return TOK.Tvirtual;
			case "abstract":	 return TOK.Tabstract;
			case "constructor": return TOK.Tconstructor;
			case "destructor": return TOK.Tdestructor;
			case "property":	 return TOK.Tproperty;
			case "operator":	 return TOK.Toperator;
			case "this":		 return TOK.Tthis;
			case "base":		 return TOK.Tbase;
			case "override":	 return TOK.Toverride;
			

			case "include":	 return TOK.Tinclude;
			case "libpath":	 return TOK.Tlibpath;
			case "once":		 return TOK.Tonce;
			case "elseif":	 return TOK.Telseif;
			case "endif":		 return TOK.Tendif;
			case "ifdef":		 return TOK.Tifdef;
			case "ifndef":	 return TOK.Tifndef;
			case "define":	 return TOK.Tdefine;
			case "macro":		 return TOK.Tmacro;
			case "endmacro":	 return TOK.Tendmacro;
			case "lib":		 		return TOK.Tlib;

			case "namespace":	 return TOK.Tnamespace;
			default:
		}
		
		return TOK._INVALID_;
	}
	
	/*
	TOK[char[]]	identToTOK;
	static this()
	{
		identToTOK["="]			= TOK.Tassign;
		identToTOK["+"]			= TOK.Tplus;
		identToTOK["-"]			= TOK.Tminus;
		identToTOK["/"]			= TOK.Tdiv;
		identToTOK["*"]			= TOK.Ttimes;
		identToTOK["mod"]		= TOK.Tmod;
		identToTOK["\\"]		= TOK.Tintegerdiv;
		identToTOK["shl"]		= TOK.Tshl;
		identToTOK["shr"]		= TOK.Tshr;
		identToTOK["^"]			= TOK.Tcaret;
		identToTOK[">"]			= TOK.Tgreater;
		identToTOK["<"]			= TOK.Tless;
		identToTOK["is"]		= TOK.Tis;
		identToTOK["..."]		= TOK.Tdotdotdot;
		identToTOK["."]			= TOK.Tdot;
		identToTOK["_"]			= TOK.Tunderline;
		identToTOK["!"]			= TOK.Texclam;
		identToTOK["?"]			= TOK.Tquest;
		identToTOK["$"]			= TOK.Tdollar;
		identToTOK["\""]		= TOK.Tquote;
		identToTOK[":"]			= TOK.Tcolon;
		identToTOK[","]			= TOK.Tcomma;
		identToTOK["#"]			= TOK.Tpound;
		identToTOK["&"]			= TOK.Tandsign;
		identToTOK["@"]			= TOK.Tat;
		identToTOK["("]			= TOK.Topenparen;
		identToTOK[")"]			= TOK.Tcloseparen;
		identToTOK["["]			= TOK.Topenbracket;
		identToTOK["]"]			= TOK.Tclosebracket;
		identToTOK["{"]			= TOK.Topencurly;
		identToTOK["}"]			= TOK.Tclosecurly;

		identToTOK["and"]		= TOK.Tand;
		identToTOK["or"]		= TOK.Tor;
		identToTOK["xor"]		= TOK.Txor;
		identToTOK["not"]		= TOK.Tnot;
		identToTOK["eqv"]		= TOK.Teqv;
		identToTOK["imp"]		= TOK.Timp;
		identToTOK["andalso"]	= TOK.Tandalso;
		identToTOK["orelse"]	= TOK.Torelse;

		identToTOK["let"]		= TOK.Tlet;
		identToTOK["for"]		= TOK.Tfor;
		identToTOK["to"]		= TOK.Tto;
		identToTOK["next"]		= TOK.Tnext;
		identToTOK["step"]		= TOK.Tstep;
		identToTOK["exit"]		= TOK.Texit;
		identToTOK["new"]		= TOK.Tnew;
		identToTOK["delete"]	= TOK.Tdelete;
		identToTOK["do"]		= TOK.Tdo;
		identToTOK["loop"]		= TOK.Tloop;
		identToTOK["while"]		= TOK.Twhile;
		identToTOK["wend"]		= TOK.Twend;
		identToTOK["until"]		= TOK.Tuntil;
		identToTOK["if"]		= TOK.Tif;
		identToTOK["then"]		= TOK.Tthen;
		identToTOK["else"]		= TOK.Telse;
		identToTOK["end"]		= TOK.Tend;
		identToTOK["dim"]		= TOK.Tdim;
		identToTOK["as"]		= TOK.Tas;
		identToTOK["enum"]		= TOK.Tenum;
		identToTOK["type"]		= TOK.Ttype;
		identToTOK["union"]		= TOK.Tunion;
		identToTOK["field"]		= TOK.Tfield;
		identToTOK["return"]	= TOK.Treturn;
		identToTOK["with"]		= TOK.Twith;
		identToTOK["select"]	= TOK.Tselect;
		identToTOK["case"]		= TOK.Tcase;
		identToTOK["cast"]		= TOK.Tcast;
		
		identToTOK["option"]	= TOK.Toption;
		identToTOK["explicit"]	= TOK.Texplicit;
			
		// function
		identToTOK["declare"]	= TOK.Tdeclare;
		identToTOK["sub"]		= TOK.Tsub;
		identToTOK["function"]	= TOK.Tfunction;
		identToTOK["byval"]		= TOK.Tbyval;
		identToTOK["byref"]		= TOK.Tbyref;
		identToTOK["stdcall"]	= TOK.Tstdcall;
		identToTOK["cdecl"]		= TOK.Tcdecl;
		identToTOK["pascal"]	= TOK.Tpascal;
		identToTOK["overload"]	= TOK.Toverload;
		identToTOK["alias"]		= TOK.Talias;
		identToTOK["export"]	= TOK.Texport;
		identToTOK["naked"]		= TOK.Tnaked;

		


		

		// data
		identToTOK["byte"]		= TOK.Tbyte;
		identToTOK["ubyte"]		= TOK.Tubyte;
		identToTOK["short"]		= TOK.Tshort;
		identToTOK["ushort"]	= TOK.Tushort;
		identToTOK["integer"]	= TOK.Tinteger;
		identToTOK["uinteger"]	= TOK.Tuinteger;
		identToTOK["longint"]	= TOK.Tlongint;
		identToTOK["ulongint"]	= TOK.Tulongint;
		identToTOK["single"]	= TOK.Tsingle;
		identToTOK["double"]	= TOK.Tdouble;
		identToTOK["string"]	= TOK.Tstring;
		identToTOK["zstring"]	= TOK.Tzstring;
		identToTOK["wstring"]	= TOK.Twstring;
		identToTOK["any"]		= TOK.Tany;
		
		identToTOK["const"]		= TOK.Tconst;
		identToTOK["pointer"]	= TOK.Tpointer;
		identToTOK["ptr"]		= TOK.Tptr;
		identToTOK["unsigned"]	= TOK.Tunsigned;
		identToTOK["extern"]	= TOK.Textern;
		identToTOK["common"]	= TOK.Tcommon;
		identToTOK["shared"]	= TOK.Tshared;
		identToTOK["static"]	= TOK.Tstatic;
		identToTOK["scope"]		= TOK.Tscope;

		// Array
		identToTOK["redim"]		= TOK.Tredim;
		identToTOK["var"]		= TOK.Tvar;
		identToTOK["preserve"]	= TOK.Tpreserve;
		//identToTOK["erase"]		= TOK.Terase;

		// class
		identToTOK["class"]			= TOK.Tclass;
		identToTOK["private"]		= TOK.Tprivate;
		identToTOK["protected"]		= TOK.Tprotected;
		identToTOK["public"]		= TOK.Tpublic;
		identToTOK["extends"]		= TOK.Textends;
		identToTOK["object"]		= TOK.Tobject;
		identToTOK["virtual"]		= TOK.Tvirtual;
		identToTOK["abstract"]		= TOK.Tabstract;
		identToTOK["constructor"]	= TOK.Tconstructor;
		identToTOK["destructor"]	= TOK.Tdestructor;
		identToTOK["property"]		= TOK.Tproperty;
		identToTOK["operator"]		= TOK.Toperator;
		identToTOK["this"]			= TOK.Tthis;
		identToTOK["base"]			= TOK.Tbase;
		identToTOK["override"]		= TOK.Toverride;
		

		identToTOK["include"]		= TOK.Tinclude;
		identToTOK["libpath"]		= TOK.Tlibpath;
		identToTOK["once"]			= TOK.Tonce;
		identToTOK["elseif"]		= TOK.Telseif;
		identToTOK["endif"]			= TOK.Tendif;
		identToTOK["ifdef"]			= TOK.Tifdef;
		identToTOK["ifndef"]		= TOK.Tifndef;
		identToTOK["define"]		= TOK.Tdefine;
		identToTOK["macro"]			= TOK.Tmacro;
		identToTOK["endmacro"]		= TOK.Tendmacro;
		identToTOK["lib"]			= TOK.Tlib;

		identToTOK["namespace"]		= TOK.Tnamespace;
	}
	*/
}

version(DIDE)
{
	enum TOK
	{
		// keyword
		Tabstract,
		Talias,
		Talign,
		Tasm,
		Tassert,
		Tauto,

		Tbody,
		Tbool,
		Tbreak,
		Tbyte,

		Tcase,
		Tcast,
		Tcatch,
		Tcdouble,
		Tcent,
		Tcfloat,
		Tchar,
		Tclass,
		Tconst,
		Tcontinue,
		Tcreal,

		Tdchar,
		Tdebug,
		Tdefault,
		Tdelegate,
		Tdelete,		// (deprecated)
		Tdeprecated,
		Tdo,
		Tdouble,

		Telse,
		Tenum,
		Texport,
		Textern,

		Tfalse,
		Tfinal,
		Tfinally,
		Tfloat,
		Tfor,
		Tforeach,
		Tforeach_reverse,
		Tfunction,

		Tgoto,

		Tidouble,
		Tif,
		Tifloat,
		Timmutable,
		Timport,
		Tin,
		Tinout,
		Tint,
		Tinterface,
		Tinvariant,
		Tireal,
		Tis,

		Tlazy,
		Tlong,

		// macro (unused)
		Tmixin,
		Tmodule,

		Tnew,
		Tnothrow,
		Tnull,

		Tout,
		Toverride,

		Tpackage,
		Tpragma,
		Tprivate,
		TProperty,	
		Tprotected,
		Tpublic,
		Tpure,
		
		TatProperty,
		TatSafe,
		TatTrusted,
		TatSystem,
		TatDisable,
		TatNogc,

		Treal,
		Tref,
		Treturn,

		Tscope,
		Tshared,
		Tshort,
		Tstatic,
		Tstruct,
		Tsuper,
		Tswitch,
		Tsynchronized,

		Ttemplate,
		Tthis,
		Tthrow,
		Ttrue,
		Ttry,
		Ttypedef, // (deprecated)
		Ttypeid,
		Ttypeof,

		Tubyte,
		Tucent,
		Tuint,
		Tulong,
		Tunion,
		Tunittest,
		Tushort,

		Tversion,
		Tvoid,
		Tvolatile, // (deprecated)

		Twchar,
		Twhile,
		Twith,

		T__FILE__,
		T__FILE_FULL_PATH__,
		T__MODULE__,
		T__LINE__,
		T__FUNCTION__,
		T__PRETTY_FUNCTION__,

		T__gshared,
		T__traits,
		T__vector,
		T__parameters,


		// Sign
		Tassign,			// =
		Tplus,				// +
		Tminus,				// -	
		Tdiv,				// /
		Ttimes,				// *
		Tpercent,			// %
		Tintegerdiv,		// \
		//Tshl,				// <<
		//Tshr,				// >>
		Tcaret,				// ^
		Ttilde,				// ~
		Tequal,				// ==

		Tgreater,			// >
		Tless,				// <

		Tquest,				// ?
		Tdollar,			// $
		Tnot,				// !
		Tand,				// &
		Tor,				// |


		Tandand,			// &&
		Toror,				// ||


		Tdot,				// .
		Tcolon,				// :
		Tsemicolon,			// ;
		Tcomma,				// ,
		Tapostrophe,		// `
		Tdquote,			// "
		Tsquote,			// '
		Tunderline,			// _

		
		Tat,				// @
		Topenparen,			// (
		Tcloseparen,		// )
		Topenbracket,		// [
		Tclosebracket,		// ]
		Topencurly,			// {
		Tclosecurly,		// }
		Tdotdot,			// ..
		Tdotdotdot,			// ...

		//
		Teof,
		Teol,
		Tidentifier,
		Tstrings,
		Tnumbers,
		
		
		_INVALID_,
	}


	struct TokenUnit
	{
		TOK		tok;
		char[]	identifier;
		int		lineNumber;
	}


	TOK	IdentToTok( char[] s )
	{
		switch( s )
		{
			case "abstract":		return TOK.Tabstract;
			case "alias":			return TOK.Talias;
			case "align":			return TOK.Talign;
			case "asm":				return TOK.Tasm;
			case "assert":			return TOK.Tassert;
			case "auto":			return TOK.Tauto;
		
			case "body":			return TOK.Tbody;
			case "bool":			return TOK.Tbool;
			case "break":			return TOK.Tbreak;
			case "byte":			return TOK.Tbyte;
			
			case "case":			return TOK.Tcase;
			case "cast":			return TOK.Tcast;
			case "catch":			return TOK.Tcatch;
			case "cdouble":			return TOK.Tcdouble;
			case "cent":			return TOK.Tcent;
			case "cfloat":			return TOK.Tcfloat;
			case "char":			return TOK.Tchar;
			case "class":			return TOK.Tclass;
			case "const":			return TOK.Tconst;
			case "continue":		return TOK.Tcontinue;
			case "creal":			return TOK.Tcreal;
			
			case "dchar":			return TOK.Tdchar;
			case "debug":			return TOK.Tdebug;
			case "default":			return TOK.Tdefault;
			case "delegate":		return TOK.Tdelegate;
			case "delete":			return TOK.Tdelete;
			case "deprecated":		return TOK.Tdeprecated;
			case "do":				return TOK.Tdo;
			case "double":			return TOK.Tdouble;
			
			case "else":			return TOK.Telse;
			case "enum":			return TOK.Tenum;
			case "export":			return TOK.Texport;
			case "extern":			return TOK.Textern;

			case "false":			return TOK.Tfalse;
			case "final":			return TOK.Tfinal;
			case "finally":			return TOK.Tfinally;
			case "float":			return TOK.Tfloat;
			case "for":				return TOK.Tfor;
			case "foreach":			return TOK.Tforeach;
			case "foreach_reverse": return TOK.Tforeach_reverse;
			case "function":		return TOK.Tfunction;

			case "goto":			return TOK.Tgoto;

			case "idouble":			return TOK.Tidouble;
			case "if":				return TOK.Tif;
			case "ifloat":			return TOK.Tifloat;
			case "immutable":		return TOK.Timmutable;
			case "import":			return TOK.Timport;
			case "in":				return TOK.Tin;
			case "inout":			return TOK.Tinout;
			case "int":				return TOK.Tint;
			case "interface":		return TOK.Tinterface;
			case "invariant":		return TOK.Tinvariant;
			case "ireal":			return TOK.Tireal;
			case "is":				return TOK.Tis;

			case "lazy":			return TOK.Tlazy;
			case "long":			return TOK.Tlong;

			case "mixin":			return TOK.Tmixin;
			case "module":			return TOK.Tmodule;

			case "new":				return TOK.Tnew;
			case "nothrow":			return TOK.Tnothrow;
			case "null":			return TOK.Tnull;

			case "out":				return TOK.Tout;
			case "override":		return TOK.Toverride;

			case "package":			return TOK.Tpackage;
			case "pragma":			return TOK.Tpragma;
			case "private":			return TOK.Tprivate;
			case "Property":		return TOK.TProperty;
			case "protected":		return TOK.Tprotected;
			case "public":			return TOK.Tpublic;
			case "pure":			return TOK.Tpure;
			
			case "@property":		return TOK.TatProperty;
			case "@safe":			return TOK.TatSafe;
			case "@trusted":		return TOK.TatTrusted;
			case "@system":			return TOK.TatSystem;
			case "@disable":		return TOK.TatDisable;
			case "@nogc":			return TOK.TatNogc;
			
			case "real":			return TOK.Treal;
			case "ref":				return TOK.Tref;
			case "return":			return TOK.Treturn;

			case "scope":			return TOK.Tscope;
			case "shared":			return TOK.Tshared;
			case "short":			return TOK.Tshort;
			case "static":			return TOK.Tstatic;
			case "struct":			return TOK.Tstruct;
			case "super":			return TOK.Tsuper;
			case "switch":			return TOK.Tswitch;
			case "synchronized":	return TOK.Tsynchronized;

			case "template":		return TOK.Ttemplate;
			case "this":			return TOK.Tthis;
			case "throw":			return TOK.Tthrow;
			case "true":			return TOK.Ttrue;
			case "try":				return TOK.Ttry;
			case "typedef":			return TOK.Ttypedef;
			case "typeid":			return TOK.Ttypeid;
			case "typeof":			return TOK.Ttypeof;

			case "ubyte":			return TOK.Tubyte;
			case "ucent":			return TOK.Tucent;
			case "uint":			return TOK.Tuint;
			case "ulong":			return TOK.Tulong;
			case "union":			return TOK.Tunion;
			case "unittest":		return TOK.Tunittest;
			case "ushort":			return TOK.Tushort;

			case "version":			return TOK.Tversion;
			case "void":			return TOK.Tvoid;
			case "volatile":		return TOK.Tvolatile;

			case "wchar":			return TOK.Twchar;
			case "while":			return TOK.Twhile;
			case "with":			return TOK.Twith;

			case "__FILE__":			return TOK.T__FILE__;
			case "__FILE_FULL_PATH__":	return TOK.T__FILE_FULL_PATH__;
			case "__MODULE__":			return TOK.T__MODULE__;
			case "__LINE__":			return TOK.T__LINE__;
			case "__FUNCTION__":		return TOK.T__FUNCTION__;
			case "__PRETTY_FUNCTION__":	return TOK.T__PRETTY_FUNCTION__;
			
			case "__gshared":		return TOK.T__gshared;
			case "__traits":		return TOK.T__traits;
			case "__vector":		return TOK.T__vector;
			case "__parameters":	return TOK.T__parameters;


			// Sign
			case "=":			return TOK.Tassign;
			case "+":			return TOK.Tplus;
			case "-":			return TOK.Tminus;
			case "/":			return TOK.Tdiv;
			case "*":			return TOK.Ttimes;
			case "%":			return TOK.Tpercent;
			case "\\":			return TOK.Tintegerdiv;
			//case "shl":		return TOK.Tshl;
			//case "shr":		return TOK.Tshr;
			case "^":			return TOK.Tcaret;
			case "~":			return TOK.Ttilde;
			case "==":			return TOK.Tequal;
			
			case ">":			return TOK.Tgreater;
			case "<":			return TOK.Tless;
			
			case "?":			return TOK.Tquest;
			case "$":			return TOK.Tdollar;
			case "!":			return TOK.Tnot;
			case "&":			return TOK.Tand;
			case "|":			return TOK.Tor;

			case "&&":			return TOK.Tandand;
			case "||":			return TOK.Toror;

			case ".":			return TOK.Tdot;
			case ":":			return TOK.Tcolon;
			case ";":			return TOK.Tsemicolon;
			case ",":			return TOK.Tcomma;
			case "`":			return TOK.Tapostrophe;
			case "\"":			return TOK.Tdquote;
			case "'":			return TOK.Tsquote;
			case "_":			return TOK.Tunderline;	

			case "@":			return TOK.Tat;
			case "(":			return TOK.Topenparen;
			case ")":			return TOK.Tcloseparen;
			case "[":			return TOK.Topenbracket;
			case "]":			return TOK.Tclosebracket;
			case "{":			return TOK.Topencurly;
			case "}":			return TOK.Tclosecurly;
			case "..":			return TOK.Tdotdot;
			case "...":			return TOK.Tdotdotdot;	
			default:
		}
		return TOK._INVALID_;
	}

	/+
	TOK[char[]]	identToTOK;
	static this()
	{
		identToTOK["abstract"]		= TOK.Tabstract;
		identToTOK["alias"]			= TOK.Talias;
		identToTOK["align"]			= TOK.Talign;
		identToTOK["asm"]			= TOK.Tasm;
		identToTOK["assert"]		= TOK.Tassert;
		identToTOK["auto"]			= TOK.Tauto;
		
		identToTOK["body"]			= TOK.Tbody;
		identToTOK["bool"]			= TOK.Tbool;
		identToTOK["break"]			= TOK.Tbreak;
		identToTOK["byte"]			= TOK.Tbyte;
		
		identToTOK["case"]			= TOK.Tcase;
		identToTOK["cast"]			= TOK.Tcast;
		identToTOK["catch"]			= TOK.Tcatch;
		identToTOK["cdouble"]		= TOK.Tcdouble;
		identToTOK["cent"]			= TOK.Tcent;
		identToTOK["cfloat"]		= TOK.Tcfloat;
		identToTOK["char"]			= TOK.Tchar;
		identToTOK["class"]			= TOK.Tclass;
		identToTOK["const"]			= TOK.Tconst;
		identToTOK["continue"]		= TOK.Tcontinue;
		identToTOK["creal"]			= TOK.Tcreal;
		
		identToTOK["dchar"]			= TOK.Tdchar;
		identToTOK["debug"]			= TOK.Tdebug;
		identToTOK["default"]		= TOK.Tdefault;
		identToTOK["delegate"]		= TOK.Tdelegate;
		identToTOK["delete"]		= TOK.Tdelete;
		identToTOK["deprecated"]	= TOK.Tdeprecated;
		identToTOK["do"]			= TOK.Tdo;
		identToTOK["double"]		= TOK.Tdouble;
		
		identToTOK["else"]			= TOK.Telse;
		identToTOK["enum"]			= TOK.Tenum;
		identToTOK["export"]		= TOK.Texport;
		identToTOK["extern"]		= TOK.Textern;

		identToTOK["false"]			= TOK.Tfalse;
		identToTOK["final"]			= TOK.Tfinal;
		identToTOK["finally"]		= TOK.Tfinally;
		identToTOK["float"]			= TOK.Tfloat;
		identToTOK["for"]			= TOK.Tfor;
		identToTOK["foreach"]		= TOK.Tforeach;
		identToTOK["foreach_reverse"] = TOK.Tforeach_reverse;
		identToTOK["function"]		= TOK.Tfunction;

		identToTOK["goto"]			= TOK.Tgoto;

		identToTOK["idouble"]		= TOK.Tidouble;
		identToTOK["if"]			= TOK.Tif;
		identToTOK["ifloat"]		= TOK.Tifloat;
		identToTOK["immutable"]		= TOK.Timmutable;
		identToTOK["import"]		= TOK.Timport;
		identToTOK["in"]			= TOK.Tin;
		identToTOK["inout"]			= TOK.Tinout;
		identToTOK["int"]			= TOK.Tint;
		identToTOK["interface"]		= TOK.Tinterface;
		identToTOK["invariant"]		= TOK.Tinvariant;
		identToTOK["ireal"]			= TOK.Tireal;
		identToTOK["is"]			= TOK.Tis;

		identToTOK["lazy"]			= TOK.Tlazy;
		identToTOK["long"]			= TOK.Tlong;

		identToTOK["mixin"]			= TOK.Tmixin;
		identToTOK["module"]		= TOK.Tmodule;

		identToTOK["new"]			= TOK.Tnew;
		identToTOK["nothrow"]		= TOK.Tnothrow;
		identToTOK["null"]			= TOK.Tnull;

		identToTOK["out"]			= TOK.Tout;
		identToTOK["override"]		= TOK.Toverride;

		identToTOK["package"]		= TOK.Tpackage;
		identToTOK["pragma"]		= TOK.Tpragma;
		identToTOK["private"]		= TOK.Tprivate;
		identToTOK["Property"]		= TOK.TProperty;
		identToTOK["protected"]		= TOK.Tprotected;
		identToTOK["public"]		= TOK.Tpublic;
		identToTOK["pure"]			= TOK.Tpure;
		
		identToTOK["@property"]		= TOK.TatProperty;
		identToTOK["@safe"]			= TOK.TatSafe;
		identToTOK["@trusted"]		= TOK.TatTrusted;
		identToTOK["@system"]		= TOK.TatSystem;
		identToTOK["@disable"]		= TOK.TatDisable;
		identToTOK["@nogc"]			= TOK.TatNogc;
		
		identToTOK["real"]			= TOK.Treal;
		identToTOK["ref"]			= TOK.Tref;
		identToTOK["return"]		= TOK.Treturn;

		identToTOK["scope"]			= TOK.Tscope;
		identToTOK["shared"]		= TOK.Tshared;
		identToTOK["short"]			= TOK.Tshort;
		identToTOK["static"]		= TOK.Tstatic;
		identToTOK["struct"]		= TOK.Tstruct;
		identToTOK["super"]			= TOK.Tsuper;
		identToTOK["switch"]		= TOK.Tswitch;
		identToTOK["synchronized"]	= TOK.Tsynchronized;

		identToTOK["template"]		= TOK.Ttemplate;
		identToTOK["this"]			= TOK.Tthis;
		identToTOK["throw"]			= TOK.Tthrow;
		identToTOK["true"]			= TOK.Ttrue;
		identToTOK["try"]			= TOK.Ttry;
		identToTOK["typedef"]		= TOK.Ttypedef;
		identToTOK["typeid"]		= TOK.Ttypeid;
		identToTOK["typeof"]		= TOK.Ttypeof;

		identToTOK["ubyte"]			= TOK.Tubyte;
		identToTOK["ucent"]			= TOK.Tucent;
		identToTOK["uint"]			= TOK.Tuint;
		identToTOK["ulong"]			= TOK.Tulong;
		identToTOK["union"]			= TOK.Tunion;
		identToTOK["unittest"]		= TOK.Tunittest;
		identToTOK["ushort"]		= TOK.Tushort;

		identToTOK["version"]		= TOK.Tversion;
		identToTOK["void"]			= TOK.Tvoid;
		identToTOK["volatile"]		= TOK.Tvolatile;

		identToTOK["wchar"]			= TOK.Twchar;
		identToTOK["while"]			= TOK.Twhile;
		identToTOK["with"]			= TOK.Twith;

		identToTOK["__FILE__"]				= TOK.T__FILE__;
		identToTOK["__FILE_FULL_PATH__"]	= TOK.T__FILE_FULL_PATH__;
		identToTOK["__MODULE__"]			= TOK.T__MODULE__;
		identToTOK["__LINE__"]				= TOK.T__LINE__;
		identToTOK["__FUNCTION__"]			= TOK.T__FUNCTION__;
		identToTOK["__PRETTY_FUNCTION__"]	= TOK.T__PRETTY_FUNCTION__;
		
		identToTOK["__gshared"]		= TOK.T__gshared;
		identToTOK["__traits"]		= TOK.T__traits;
		identToTOK["__vector"]		= TOK.T__vector;
		identToTOK["__parameters"]	= TOK.T__parameters;


		// Sign
		identToTOK["="]			= TOK.Tassign;
		identToTOK["+"]			= TOK.Tplus;
		identToTOK["-"]			= TOK.Tminus;
		identToTOK["/"]			= TOK.Tdiv;
		identToTOK["*"]			= TOK.Ttimes;
		identToTOK["%"]			= TOK.Tpercent;
		identToTOK["\\"]		= TOK.Tintegerdiv;
		//identToTOK["shl"]		= TOK.Tshl;
		//identToTOK["shr"]		= TOK.Tshr;
		identToTOK["^"]			= TOK.Tcaret;
		identToTOK["~"]			= TOK.Ttilde;
		identToTOK["=="]		= TOK.Tequal;
		
		identToTOK[">"]			= TOK.Tgreater;
		identToTOK["<"]			= TOK.Tless;
		
		identToTOK["?"]			= TOK.Tquest;
		identToTOK["$"]			= TOK.Tdollar;
		identToTOK["!"]			= TOK.Tnot;
		identToTOK["&"]			= TOK.Tand;
		identToTOK["|"]			= TOK.Tor;

		identToTOK["&&"]		= TOK.Tandand;
		identToTOK["||"]		= TOK.Toror;

		identToTOK["."]			= TOK.Tdot;
		identToTOK[":"]			= TOK.Tcolon;
		identToTOK[";"]			= TOK.Tsemicolon;
		identToTOK[","]			= TOK.Tcomma;
		identToTOK["`"]			= TOK.Tapostrophe;
		identToTOK["\""]		= TOK.Tdquote;
		identToTOK["'"]			= TOK.Tsquote;
		identToTOK["_"]			= TOK.Tunderline;	

		identToTOK["@"]			= TOK.Tat;
		identToTOK["("]			= TOK.Topenparen;
		identToTOK[")"]			= TOK.Tcloseparen;
		identToTOK["["]			= TOK.Topenbracket;
		identToTOK["]"]			= TOK.Tclosebracket;
		identToTOK["{"]			= TOK.Topencurly;
		identToTOK["}"]			= TOK.Tclosecurly;
		identToTOK[".."]		= TOK.Tdotdot;
		identToTOK["..."]		= TOK.Tdotdotdot;
	}
	+/
}