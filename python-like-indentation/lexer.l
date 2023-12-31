/* this example refers to code in https://stackoverflow.com/questions/1413204/how-to-use-indentation-as-block-delimiters-with-bison-and-flex */
%{   
#include "parser.h"
#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;

/* globals to track current indentation */
int current_line_indent = 0;   /* indentation of the current line */
int indent_level = 0;          /* indentation level passed to the parser */


#define SAVE_TOKEN     yylval.str = maketoken(yytext, yyleng)
#define SAVE_STRING    yylval.str = makestring(yytext, yyleng, 2)
#define SAVE_STRING_NC yylval.str = makestring(yytext, yyleng, 3)

char* maketoken(const char* data, int len);
char* makestring(const char* data, int len, int s);

/*windows compatibility case*/  
#ifdef _WIN32
#  define YY_NO_UNISTD_H
#  include <io.h>  
#  define isatty _isatty  
#  define fileno _fileno  
#endif

%}

%option yylineno
%option noyywrap


DIGIT    [0-9]
HEXDIGIT [0-9a-fA-F]

%x NORMAL


%%

" "      { printf("space\n"); current_line_indent++; }
"\t"     { printf("tab\n"); current_line_indent = (current_line_indent + 4) & ~3; }
"\n"     { printf("enter\n"); current_line_indent = 0; }
. {
                    printf("indentation\n");
                    unput(*yytext);
                    
                    if (current_line_indent > indent_level) {
                        if (current_line_indent == indent_level + 4) {
                            indent_level = current_line_indent;
                            BEGIN(NORMAL);
                            printf("indent: %d\n", current_line_indent);
                            return INDENT;
                        } else {
                            printf("Error at line %d: illegal indentation %d %d\n", yylloc.first_line,
                                    current_line_indent, indent_level); exit(0);
                        }
                    } else if (current_line_indent < indent_level) {
                        if (indent_level - current_line_indent < 4) {
                            printf("Error at line %d: illegal indentation %d %d\n", yylloc.first_line,
                                    current_line_indent, indent_level); exit(0);
                        }
                        indent_level -= 4;
                        printf("dedent: %d\n", current_line_indent);
                        return DEDENT;
                    } else {
                        printf("goto normal\n");
                        BEGIN(NORMAL);
                    }
                }

<<EOF>>         {
                    if (current_line_indent < indent_level) {
                        if (indent_level - current_line_indent < 4) {
                            printf("Error at line %d: illegal indentation %d %d\n", yylloc.first_line,
                                    current_line_indent, indent_level); exit(0);
                        }
                        indent_level -= 4;
                        printf("dedent: %d\n", current_line_indent);
                        return DEDENT;
                    } else return YYEOF;
                }

<NORMAL>{
    "\n"                    { printf("next line\n"); current_line_indent = 0; return '\n'; }
    [ \t]                   { }                  
    /* 界符 */
    [()\[\]{}.:`;]          { printf("%s ",yytext);return *yytext;}
    /* 运算符 */
    [+\-*/&|^~!%=,]         {return *yytext;}
    /* 比较 */
    [><]                    {return *yytext;}

    /* 关键字 */
    "for"                   { printf("for "      ); return FOR; }
    "if"                    { printf("if "       ); return IF; }
    "else"                  { printf("else "     ); return ELSE; }
    "while"                 { printf("while "    ); return WHILE; }
    "do"                    { printf("do "       ); return DO; }
    "break"                 { printf("break "    ); return BREAK; }
    "continue"              { printf("continue " ); return CONTINUE; }
    "return"                { printf("return "   ); return RETURN; }
    "in"                    { printf("in "       ); return IN; }
    "defun"                 { printf("defun "    ); return DEFUN; }
    "defmacro"              { printf("defmacro " ); return DEFMACRO; }
    "class"                 { printf("class "    ); return CLASS; }
    "var"                   { printf("var "      ); return VAR; }

    "true"                  { printf("true "     ); return T_TRUE; }
    "false"                 { printf("false "    ); return T_FALSE; }
    "nil"                   { printf("nil "      ); return T_NIL; }
    "<="                    { printf("<="        ); return LTE; }
    ">="                    { printf(">="        ); return GTE; }
    "=="                    { printf("=="        ); return EQ; }
    "!="                    { printf("!="        ); return NE; }

    /* 标识符 */
    [a-zA-Z_][a-zA-Z0-9_]*  { printf("%s ",yytext); SAVE_TOKEN; return TID; }
    /* 字符串 */
    \"(\\.|[^\\"])*\"       {SAVE_STRING; return STRING; }
    \'(\\.|[^\\'])*\'       {SAVE_STRING; return STRING; }
    /* 数字 */
    {DIGIT}+                {SAVE_TOKEN; return INTEGER;}
    0x{HEXDIGIT}+           {SAVE_TOKEN; return INTEGER;}
    (\.{DIGIT}+)|({DIGIT}+(\.{DIGIT}*)?([eE][+-]?[0-9]+)?)   {SAVE_TOKEN; return DOUBLE;}

    .     {printf("Error at line %d: unrecognized symbol \"%s\"\n", yylloc.first_line, yytext); exit(0);}
}

%%


void myunput(char c) { unput(c); }
void beginIndent() { BEGIN(INITIAL); }

char* maketoken(const char* data, int len) {
    char* str = (char*) malloc(len+1);
    strncpy(str, data, len);
    str[len] = 0;
    return str;
}

char* makestring(const char* data, int len, int s) {
    char* str = (char*) malloc(len-s+1);
    strncpy(str, data+s-1, len-s);
    str[len-s] = 0;
    if (s == 3) return str;
    return str;
}

void slip_reset_file(FILE* f) {
    yyrestart(f);
}

void slip_scan_string(const char* str)
{
    yy_switch_to_buffer(yy_scan_string(str));
}
