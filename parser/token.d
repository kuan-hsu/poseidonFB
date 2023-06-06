module parser.token;

struct TokenUnit
{
	TOK		tok;
	char[]	identifier;
	int		lineNumber;
}
	
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
		/*Tobject,*/
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
		Tdefined,
		Tmacro,
		Tendmacro,
		Tlib,
		
		//Tinclib,
		Tnamespace,
		Tusing,
		
		


		//
		Teol, // \n
		Tidentifier,
		Tstrings,
		Tnumbers,


		_INVALID_,
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
			/*case "object":	 return TOK.Tobject;*/
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
			case "defined":	 return TOK.Tdefined;
			case "macro":		 return TOK.Tmacro;
			case "endmacro":	 return TOK.Tendmacro;
			case "lib":		 		return TOK.Tlib;

			case "namespace":	return TOK.Tnamespace;
			case "using":		return TOK.Tusing;
			default:
		}
		
		return TOK._INVALID_;
	}
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
		TatLive,

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
			case "@live":			return TOK.TatLive;
			
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
}