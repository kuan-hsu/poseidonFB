module parser.autocompletion;

version(FBIDE) public import parser.autocompletionFB;
version(DIDE) public import parser.autocompletionD;
