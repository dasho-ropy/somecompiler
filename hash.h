/* Data type for links in the chain of symbols.      */


struct symrec{  
  char *name;  /* name of symbol                     */  
  char addr[100];           /* value of a VAR          */  
  struct symrec *next;    /* link field              */
  char symtype;
};

typedef struct symrec symrec;/* The symbol table: a chain of `struct symrec'.     */

extern symrec *sym_table;

symrec *putsym ();

symrec *getsym ();

typedef struct StmtsNode *stmtsptr;

typedef struct StmtNode *stmtptr;