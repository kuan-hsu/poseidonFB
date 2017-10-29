module parser.token;

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
	identToTOK["virtural"]		= TOK.Tvirtual;
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


