%{
#include <string.h>
#include "parser.tab.h"
#include "hash.h"
symrec *sym_table = (symrec *)0;
int Adr=0;
%}
%%
" "                             ;
[+\-]                           {yylval.charval = yytext[0];return ADDOP ; }
[*/]|"and"|"or"|"mod"|"div"     {yylval.charval = yytext[0];return MULOP ; }
":="                            return ASSIGNOP ; 
"<"|">"                         return RELOP ; 
"<>"|"<="|">="			        {yylval.string = strdup(yytext);return RELOP ; }
\(                              return OPAR ; 
\)                              return CPAR ; 
[0-9]+							{yylval.integer = atoi(yytext);return INTNO;}
[0-9]+\.[0-9]+					{yylval.real = atof(yytext);return REALNO;}
\.                              return DOT ;
\,                              return COMMA ; 
\;                              return SEMICOLON ;
\:                              return COLON  ; 
"program"                       return PROGRAM ; 
"var"                           return T_VAR ; 
"integer"                       return INTEGER ; 
"real"                          return REAL ;
"begin"                         return BEGINS ; 
"end"                           return END ; 
"do"                            return DO ; 
"while"                         return WHILE ; 
"if"                            return IF ; 
"then"                          return THEN ; 
"else"                          return ELSE ; 
"not"                           return NOT ; 
[a-z][a-zA-Z0-9]*               {symrec *s;s=getsym(yytext); if(s==0) s=putsym(yytext,VAR);yylval.tptr=s; return VAR ; }
[ \t]                           {/*whitespace*/}
[\n\r\0\x0B]+                   {/*end of line chars*/}
.                               printf("Mystery character %c\n ", *yytext);
%%

/* The symbol table: a chain of `struct symrec'.  */


symrec * putsym (char *sym_name,int sym_type){
  symrec *ptr;
  ptr = (symrec *) malloc (sizeof (symrec));
  ptr->name = (char *) malloc (strlen (sym_name) + 1);
  strcpy (ptr->name,sym_name);
  sprintf(ptr->addr,"%d",Adr); /* set value to 0 even if fctn.  */
  Adr=Adr+4;
  ptr->next = (struct symrec *)sym_table;
  sym_table = ptr;
  return ptr;
}

symrec *getsym (char *sym_name){
  symrec *ptr;
  for (ptr = sym_table; ptr != (symrec *) 0;
       ptr = (symrec *)ptr->next)
    if (strcmp (ptr->name,sym_name) == 0)
      return ptr;
  return 0;
}