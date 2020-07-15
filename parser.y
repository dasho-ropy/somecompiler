%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h> 
#include "hash.h"
 void yyerror (char const *s) {
   fprintf (stderr, "%s\n", s); 
 }
FILE *out;
int ifthenelsecounter;

struct identifier_list_stack{
  struct symrec *tptr;
  struct identifier_list_stack *next;
};

struct identifier_list_stack * identifier_list_stack_head = NULL;

void identifier_list_stack_push(struct symrec *tpt);

void identifier_list_stack_pop(char symtyp);

%}
 %union semrec{
   int integer;
   double real;
   char *string;
   char charval;
   struct symrec  *tptr;   /* For returning symbol-table pointers      */
 }
 /*declare tokens*/
 %start  program
 %token  ASSIGNOP DIVOP
 %token  OPAR CPAR 
 %token  DOT COMMA SEMICOLON COLON
 %token  REAL BEGINS END PROGRAM
 %token  T_VAR DO WHILE IF THEN ELSE NOT
 %token <charval> ADDOP MULOP
 %token <string> RELOP
 %token <integer> INTEGER
 %token <integer> INTNO
 %token <real> REALNO 
 %type <string> procedure_statement identifier_list 
 %type <charval> type factor statement expression simple_expression term expression_list
 %token <tptr> VAR

 %%

 program: 
 PROGRAM VAR {
 fprintf(out, ".data\n");
 fprintf(out, "user_input: .word 0\n");
 fprintf(out, "readspace: .asciiz \"read: \"\n");
 fprintf(out, "writespace: .asciiz \"write: \"\n");
 fprintf(out, "here: .asciiz \":here: \"\n");
 fprintf(out, "space: .asciiz \"\\n\"\n");

 } SEMICOLON
 declarations{

  fprintf(out, "\n.text\n.globl main\n main:\n");

}
compound_statement
DOT
{ printf("Parsed the program!\n");
fprintf(out,"\n\n### END THE PROGRAM ###\n");
// Syscall for ending program
fprintf(out,"\nli\t$v0, 10\t#the end\n");   
fprintf(out,"syscall\n");
}
;

identifier_list:
VAR { printf("reducing identifier_list: VAR\n"); identifier_list_stack_push($1);}
| VAR COMMA identifier_list{ printf("reducing identifier_list: identifier_list COMMA VAR\n");identifier_list_stack_push($1);}
;

declarations:
T_VAR identifier_list COLON type {identifier_list_stack_pop($4);} SEMICOLON declarations
  { printf("reducing declarations: declarations VAR identifier_list COLON type SEMICOLON\n");}
  |{ printf("reducing declarations EMPTY rule\n");}
  ;

  type:
  INTEGER { $$='i'; printf("reducing type: INTEGER\n");}
  |REAL {$$='r'; printf("reducing type: REAL\n"); }
  ;

  compound_statement:
  BEGINS 
  optional_statements
  END
  { printf("compound statement\n");}
  ;

  optional_statements:
  statement_list { printf("reducing optional_statements: statement_list\n");}
  |{ printf("reducing optional statements EMPTY rule\n");}
  ;

  statement_list:
  statement { printf("reducing statement_list: statement\n");}
  |statement_list SEMICOLON statement { printf("reducing statement_list: statement_list SEMICOLON statement\n");}
  ;

  statement:
  VAR ASSIGNOP expression { printf("reducing statement: VAR ASSIGNOP expression\n");
  fprintf(out, "\n\n###POP THE STACK FOR ASSIGNOP###\n");
  fprintf(out, "lw\t$t0, ($sp)\t#pop 1st!\n");
  fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");
  fprintf(out, "sw\t$t0, %s\t#add value to variable\n",$1->name);
  
}
|procedure_statement { printf("reducing statement: procedure_statement\n");}
|compound_statement { printf("reducing statement: compound_statement\n");}
|IF expression THEN{

  fprintf(out, "\n\n###GET VALUE FROM EXPRESSION###\n");
  fprintf(out, "move\t$t2, $t0\t#get result form expression\n");
  fprintf(out, "beq\t$t2, 0, ELSE\t#JUMP to tag if exp is false\n");

}statement ELSE{

  fprintf(out, "\n\n###USE EXPRESSION VALUE###\n");
  fprintf(out, "beq\t$t2, 1, STOPTRUE\t#get result form expression\n");
  fprintf(out, "ELSE:\n ");

}statement{

  printf("reducing statement: IF...THEN... ELSE\n");
  fprintf(out, "\n\nSTOPTRUE: #finished\n");
  fprintf(out, "###End IF...THEN...ELSE###\n");

}| WHILE {fprintf(out,"\n\nWHILE:\n");} expression {
    fprintf(out, "\n\n###GET VALUE FROM EXPRESSION###\n");
    fprintf(out, "move\t$t2, $t0\t#get result form expression\n");
    fprintf(out, "beq\t$t2, 0, FINISH\t#JUMP to tag if exp is false\n");
    fprintf(out, "beq\t$t2, 1, WHILE\t#JUMP to tag if exp is true\n");
} DO BEGINS statement_list END  { printf("reducing statement: WHILE...DO\n");
  fprintf(out, "b WHILE\n\n");
  fprintf(out,"FINISH: \n\n\n");
};

procedure_statement:
VAR { printf("reducing procedure_statement: VAR\n");
}
|VAR OPAR expression_list CPAR {
   printf("reducing procedure_statement: VAR OPAR expression_list CPAR\n");
  if(strcmp($1->name,"read")==0){
    fprintf(out,"\n\n### READ INPUT ###\n");

    switch($3){
      case 'i':
      fprintf(out,"li\t$v0, 5\t#accept input instruction\n");
      break;
      case 'r':
      fprintf(out,"li\t$v0, 7\t#accept input instruction\n");
      break;
      default:
      break;
    }
    
    fprintf(out,"syscall\t\n");

    fprintf(out, "lw\t$t1, ($sp)\t#pop 1st! done with the variable\n");
    fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");
    fprintf(out, "sw\t$v0, ($t0)\t#add value to variable\n");

  }
  else if(strcmp($1->name,"write")==0){
    fprintf(out,"\n\n### PRINT THE RESULT ###\n");
    fprintf(out,"li\t$v0, 4\t#print instruction\n");
    fprintf(out,"la\t$a0, writespace\t#put the message to be print\n");
    fprintf(out,"syscall\t\n"); 

    fprintf(out, "lw\t$t0, ($sp)\t#pop 1st!\n");
    fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");

    switch($3){
      case 'i':
      fprintf(out,"li\t$v0, 1\t#print integer instruction\n");
      break;
      case 'r':
      fprintf(out,"li\t$v0, 3\t#print real instruction\n");
      break;
      default:
      break;
    }

    fprintf(out,"move\t$a0, $t0\t#put the value to be print\n"); 
    fprintf(out,"syscall\t\n");
 

  }
}
;

expression_list:
expression { printf("reducing expression_list: expression\n"); $$=$1;}
|expression_list COMMA expression { printf("reducing expression_list: expression_list COMMA expression\n");$$=$1;}
;

expression:
simple_expression { printf("reducing expression simple_expression\n");$$=$1;}
|simple_expression RELOP simple_expression {
  $$='i'; printf("reducing expression: simple_expression RELOP simple_expression\n");
  fprintf(out,"\n\n### PERFORMING RELOP ###\n");
  fprintf(out, "lw\t$t1, ($sp)\t#pop 1st!\n");
  fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");
  fprintf(out, "lw\t$t0, ($sp)\t#pop 2nd!\n");
  fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");

  if(strcmp($2, "<")==0){
    fprintf(out, "slt\t$t0, $t0, $t1\t#is it less than?\n");
  }
  else if(strcmp($2, ">")==0){
    fprintf(out, "sgt \t$t0, $t0, $t1\t#is it less than?\n");
  }
  else if(strcmp($2, "<=")==0){
    fprintf(out, "sle\t$t0, $t0, $t1\t#is it less than or equal?\n");
  }
  else if(strcmp($2, ">=")==0){
    fprintf(out, "sge\t$t0, $t0, $t1\t#is it greater than or equal?\n");
  }


}
;

simple_expression:
term { printf("reducing simple_expression term\n");}
|sign term { printf("reducing simple_expression sign term\n");}
|simple_expression ADDOP term {if($1 == 'r' || $3 == 'r')$$ = 'r'; else $$='i';  printf("reducing simple_expression: simple_expression ADDOP term\n");
fprintf(out,"\n\n### PERFORMING ADDITION ###\n");
fprintf(out, "lw\t$t0, ($sp)\t#pop 1st!\n");
fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");
fprintf(out, "lw\t$t1, ($sp)\t#pop 2nd!\n");
fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");

switch($2){
  case '+':
  fprintf(out, "add\t$t0, $t1, $t0\t#add\n");
  break;
  case '-':
  fprintf(out, "sub\t$t0, $t1, $t0\t#add\n");
  break;
  default:
  fprintf(out,"#Wrong ADDOP Operation\n");
  break;
}
fprintf(out, "subu\t$sp, $sp, 4\t#move the stack ptr\n");
fprintf(out, "sw\t$t0, ($sp)\t#push!\n");
}
;

term:
factor { printf("reducing term: factor\n");}
|term MULOP factor {if($1 == 'r' || $3 == 'r')$$ = 'r'; else $$='i'; printf("reducing term: term MULOP factor\n");
fprintf(out,"\n\n### PERFORMING MULTIPLICATION ###\n");
fprintf(out, "lw\t$t0, ($sp)\t#pop 1st!\n");
fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");
fprintf(out, "lw\t$t1, ($sp)\t#pop 2nd!\n");
fprintf(out, "addu\t$sp, $sp, 4\t#move the ptr\n");
switch($2){
  case '*':
  fprintf(out, "mul\t$t0, $t1, $t0\t#multiply\n");
  break;
  case '/':
  fprintf(out, "div\t$t0, $t1, $t0\t#divide\n");
  break;
  default:
  fprintf(out,"#Wrong MULOP Operation\n");
  break;
}

fprintf(out, "subu\t$sp, $sp, 4\t#move the stack ptr\n");
fprintf(out, "sw\t$t0, ($sp)\t#push!\n");

}
;

factor:
VAR { printf("reducing factor: VAR\n");
$$=$1->symtype;
fprintf(out, "\n\n### ADDING AN VAR TO THE STACK ####\n");
fprintf(out, "lw\t$t0, %s\t #store value from id into t0\n",$1->name);
fprintf(out, "subu\t$sp, $sp, 4\t#move the stack ptr\n");
fprintf(out, "sw\t$t0, ($sp)\t#push!\n");
fprintf(out, "la\t$t0, %s\t #load address of var into t0",$1->name);
}
|VAR OPAR expression_list CPAR { printf("reducing factor: VAR OPAR expression_list CPAR\n");
}
|INTNO {$$='i'; printf("reducing factor: INTNO\n");
//put value of current number at the top of the stack 
fprintf(out, "\n\n### ADDING AN INT TO THE STACK ####\n");
fprintf(out, "li\t$t0, %d\t #store value\n",$1);
fprintf(out, "subu\t$sp, $sp, 4\t#move the stack ptr\n");
fprintf(out, "sw\t $t0, ($sp)\t#push!\n");

}
|REALNO {$$='r'; printf("reducing factor: REALNO\n");
fprintf(out, "\n\n### ADDING A DOUBLE/FLOAT/REAL TO THE STACK ####\n");
fprintf(out, "li\t$t0, %f\t #store value\n",$1);
fprintf(out, "subu\t$sp, $sp, 4\t#move the stack ptr\n");
fprintf(out, "sw\t $t0, ($sp)\t#push!\n");

}
|OPAR expression CPAR { printf("reducing factor: OPAR expression CPAR\n");}
|NOT factor { printf("reducing factor: NOT factor\n");}
;

sign:
ADDOP { printf("reducing sign: ADDOP\n");}
;

%%
extern FILE *yyin; 

int main(int argc, char **argv) {
  char *filename;
  /* read input */
  if( argc > 1) {
    FILE * file;
    filename = argv [1];
    file = fopen( filename, "r");
    if (! file) {
      exit (1);
    }
    yyin = file;
  }

  printf("File name: %s\n", filename);
  int iter=0;
  while(filename[iter]!='.') iter++;
  iter++;
  filename[iter]='s';
  iter++;
  filename[iter]= '\0';
  printf("Creating output file...\n");
  if ((out = fopen(filename, "w")) == NULL) {
    printf("ERROR: Output file cannot be generated.");
  }
  
  yyparse();
  fclose(out); 

}

void identifier_list_stack_push(struct symrec *tpt){
  struct identifier_list_stack * x = (struct identifier_list_stack *)malloc(sizeof(struct identifier_list_stack));
  x->tptr =  tpt;
  x->next=identifier_list_stack_head;
  identifier_list_stack_head=x;
  fprintf(out, "\n\n###DECLARE VARIABLES##\n");
  fprintf(out, "%s: .word 0 ",tpt->name);
}

void identifier_list_stack_pop(char symtyp){
  while(identifier_list_stack_head!=NULL){
    (identifier_list_stack_head->tptr)->symtype=symtyp;
    identifier_list_stack_head = identifier_list_stack_head->next;
  }
}