module parser.token;

version(FBIDE)
{
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
		Tptraccess,
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
		Terase,
		
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

	}

	struct TokenUnit
	{
		TOK		tok;
		char[]	identifier;
		int		lineNumber;
	}

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
		identToTOK["erase"]		= TOK.Terase;

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
		Tdotdotdot,			// ...

		//
		Teof,
		Teol,
		Tidentifier,
		Tstrings,
		Tnumbers,
	}


	struct TokenUnit
	{
		TOK		tok;
		char[]	identifier;
		int		lineNumber;
	}


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
		identToTOK["..."]		= TOK.Tdotdotdot;
	}
}