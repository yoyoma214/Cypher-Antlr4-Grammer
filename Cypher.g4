/*
 * MIT license 
 * Copyright (C) 2016/12/10 adam
 */
 
grammar Cypher;

document: (unionQuery |  callClause | dropConstraint | dropIndexClause | importClause) ';'?;
directive: CYPHER directiveItem (',' directiveItem )*;
directiveItem:  id EQUAL expression ;
createNode: CREATE assignGraphRelation (',' assignGraphRelation)*;
unwind: UNWIND expression (AS id)? ;
//merge;
mergeClause: MERGE graphRelation mergeClauseOn*;
mergeClauseOn:mergeOnCreate | mergeOnMatch;
mergeOnCreate:  ON CREATE setClause;
mergeOnMatch:  ON MATCH setClause;
setClause: SET setClauseItem (',' setClauseItem)*;
setClauseItem: assignExpression | setMap | setAddMap | setLabel ;
setMap: id EQUAL(PARAMETER | nodePropertyList );
setAddMap: id ADDEQUAL (PARAMETER | nodePropertyList );
setLabel: id labelVar+;
assignExpression: idPath EQUAL expression;
procedure: idPath  expressionList? ;
//index
createIndexClause: CREATE INDEX ON labelVar '(' id ')';
createUnique: CREATE UNIQUE graphRelation ( ',' graphRelation )*;
useIndexClause: USING INDEX id labelVar '(' id ')';
useScanClause: USING SCAN id labelVar ;
useJoinClause: USING JOIN id (',' id)* ;
dropIndexClause: DROP INDEX ON labelVar '(' id ')';
callClause: CALL procedure (YIELD id)? returnClause?;
createConstraint: CREATE CONSTRAINT ON (node | graphRelation) assert_;
dropConstraint: DROP CONSTRAINT ON graphRelation assert_;
assert_: ASSERT_ expression;
unionQuery: directive? query unionClause* ;
unionClause: UNION ALL? query;
query: PROFILE? startClause?  (matchOrWith)* 
       modifyCluase*
       returnClause? ;
modifyCluase:createClause | mergeClause |setClause | deleteClause | removeClause | foreachClause;
startClause: START  assignGraphRelation (',' assignGraphRelation)*;
matchOrWith: matchClause |  unwind  | withClause;
createClause:  createIndexClause | createUnique | createConstraint | createNode   ; //| createNodeMap
matchClause : matchClauseItem+ (useIndexClause | useScanClause | useJoinClause)*
        whereClause?  ;
matchClauseItem: OPTIONAL? MATCH assignGraphRelation (',' assignGraphRelation)*;
assignGraphRelation: (id EQUAL)? (relationIndex | nodeIndex | graphRelation |  builtInCall);
nodeIndex:  NODE labelVar '(' (id EQUAL expression | indexQueryString) ')';
relationIndex: RELATIONSHIP labelVar '(' (id EQUAL expression | indexQueryString) ')';
indexQueryString:STRING;

whereClause: WHERE expression ;
fetchVar:  fetchOneVar | allVar;
fetchOneVar:( DISTINCT? idPath | expression) (AS var)?;
allVar: MULIT;
withClause:WITH fetchVar(',' fetchVar)*  orderBy? skipClause? limitClause? whereClause?; 
orderBy: ORDER BY orderByItem (',' orderByItem)*;
orderByItem: idPath (ASC | DESC)?;
skipClause: SKIP expression;
limitClause: LIMIT expression;
returnClause: RETURN fetchVar(',' fetchVar)* orderBy? skipClause? limitClause?;

deleteClause: DETACH? DELETE deleteItem  (',' deleteItem)*;
deleteItem:var | graphRelation;
removeClause: removeLabel | removeProperty;
removeLabel: REMOVE var+;
removeProperty: REMOVE idPath;

updateClause: SET updateItem (',' updateItem )*;
updateItem: idPath EQUAL expression;

foreachClause: FOREACH '(' var IN expression '|' (setClause | createClause) ')';

nodePropertyList: json | PARAMETER;
node : nodeEmpty | nodeNotEmpty ;
nodeNotEmpty:  '(' id? labelVar*   nodePropertyList? ')' ;
nodeEmpty: NIL;
idPath: id ('.' id)*;

graphRelation: node |  node relation*;
relation: (relationToNext | relationToPrev | relationToBoth )
          node;

relationToNext:'-' relationType?  ARROWAHEAD;
relationToPrev:ARROWBACK relationType? '-';
relationToBoth:'-' relationType? '-';
relationType:  '['matchTag relationTypeRestrict? nodePropertyList? ']';
matchTag: var? labelVar? ;
relationTypeRestrict: relationTypeCounterRange | relationTypeCounterAll | relationTypeIdList ;
relationTypeCounterRange: MULIT INTEGER? (DOUBLEDOT  INTEGER)? ; 
relationTypeCounterAll: MULIT ALL ;
relationTypeIdList: labelVar ('|' labelVar)*;

importClause: usingPeriodicCommit?
              loadCvs
              matchClause?
              modifyCluase*;    

loadCvs:LOAD CSV (WITH HEADERS)? FROM STRING (AS id)? (FIELDTERMINATOR STRING)? ;
usingPeriodicCommit:USING PERIODIC COMMIT integerCypher?;

//expression
expression   :   conditionalOrExpression ;
conditionalOrExpression   :   conditionalAndExpression ( OR conditionalAndExpression )* ;
conditionalAndExpression   :   valueLogical ( AND valueLogical )* ;
valueLogical   :   relationalExpression ;


argList   :   NIL | '(' DISTINCT? expression ( ',' expression )* ')'  ;
expressionList   :   NIL | '(' expression ( ',' expression )* ')'  ;
relationalExpression   : NOT? (relationalExpressionChain | relationalExpressionIsNull | relationalExpressionString | relationalExpressionIn | relationalExpresionExists | graphRelation | caseExpression | relationalIsUnique);
relationalExpressionIn:numericExpression (  IN expression | NOT IN expression )? ;
relationalExpressionChain: numericExpression relationalExpressionChainTtem* ;
relationalExpressionChainTtem:(LT | LT_EQUAL |GT | GT_EQUAL |EQUAL | NOT_EQUAL |XOR ) numericExpression;

relationalExpressionIsNull: numericExpression IS NULL;
relationalExpressionString: relationalExpressionStartsWith | relationalExpressionEndsWith | relationalExpressionContains | relationalExpressionRegular;
relationalExpressionStartsWith: numericExpression STARTS WITH STRING;
relationalExpressionEndsWith: numericExpression ENDS WITH STRING;
relationalExpressionContains: numericExpression CONTAINS STRING;
relationalExpressionRegular:numericExpression EQUAL_REGUALR STRING;

relationalIsUnique: idPath IS UNIQUE;

relationalExpresionExists: EXISTS '(' expression ')';

numericExpression   :   additiveExpression ;

additiveExpression   :   multiplicativeExpression additiveExpressionRightPart* ;

additiveExpressionRightPart:addMultiplicativeExpression | subtractionMultiplicativeExpression | additiveExpressionMulti;

addMultiplicativeExpression : ADD multiplicativeExpression;

subtractionMultiplicativeExpression: SUBTRACTION multiplicativeExpression ;

multiplicativeExpression   :   unaryExpression multiplicativeExpressionItem* ;

additiveExpressionMulti:
                           numericLiteral  multiplicativeExpressionItem *
                      ;
multiplicativeExpressionItem:
                                 (MULIT | DIVISION) unaryExpression
                             ;
unaryExpression   :     
                      NEGATE primaryExpression 
                    | ADD primaryExpression 
                    | SUBTRACTION primaryExpression 
                    | NOT primaryExpression
                    | primaryExpression ;

primaryExpression   :  
                     caseExpression  
                    |brackettedExpression 
                    |anyVal  
                    |listExpression 
                    |list 
                    |primaryExpressionChain;

rangeExpression: '[' numericLiteral DOUBLEDOT numericLiteral ']';
primaryExpressionChain:
                          primaryExpressionChainItem primaryExpressionChainRightPart*
                      ;

primaryExpressionChainRightPart:listFetch | '.' primaryExpressionChainItem | rangeExpression;

primaryExpressionChainItem:
                              builtInCall | id
                          ;

caseExpression: CASE expression? caseExpressionWhen+ caseExpressionElse? END ;
caseExpressionWhen: WHEN expression THEN  expression;
caseExpressionElse: ELSE expression;
listExpression: listExpressionAll | listExpressionAny | listExpressionNone | listExpressionSingle;
listExpressionExist:listExpressionAll | listExpressionAny | listExpressionNone | listExpressionSingle;
listExpressionAll: ALL '('var IN expression WHERE listExpressionCondition  ')';
listExpressionAny: ANY '('var IN expression WHERE listExpressionCondition  ')';
listExpressionNone: NONE '('var IN expression WHERE listExpressionCondition  ')';
listExpressionSingle: SINGLE '('var IN expression WHERE listExpressionCondition  ')';
listExpressionCondition:  EXISTS '(' idPath  ')' | expression ;
list: '[' anyVal (',' anyVal)* ']';
listFetch : '[' expression ']';
var : id ;
brackettedExpression   :   '(' expression ')' ;
builtInCall   :     pathFunc |  nodesFunc  | relationshipsFunc |extractFunc | filterFunc | absFunc | randFunc | roundFunc | sqrtFunc |signFunc | sinFunc | cosFunc | 
           tanFunc | cotFunc |  asinFunc |  acosFunc | atanFunc |  atan2Func |  haversinFunc | degreesFunc | radiansFunc | pi | log10Func| logFunc | expFunc | e | countAllFunc |
           countFunc | collectFunc | sumFunc | avgFunc |  minFunc |  maxFunc |percentileDiscFunc | percentileContFunc | stdevFunc | stdevpFunc | toStringFunc | replaceStrFunc | substringStrFunc | leftStrFunc | rightStrFunc | trimStrFunc | ltrimStrFunc|
rtrimStrFunc | upperStrFunc | lowerStrFunc | splitStrFunc | reverseStrFunc | lengthStrFunc | nodeId | rangeFunc | typeFunc | shortestPathFunc | allShortestPathsFunc | relsFunc | toLowerFunc |toInt | labelsFunc | timestampFunc | sizeFunc |
coalesceFunc | headFunc | lastFunc | startNodeFunc | endNodeFunc | propertiesFunc | toFloatFunc |keysFunc | tailFunc | reduceFunc | floorFunc;

pathFunc: LENGTH '(' expression ')';
nodesFunc: NODES '(' expression ')';
relationshipsFunc: RELATIONSHIPS '(' expression ')';
extractFunc: EXTRACT '(' var IN expression '|' expression ')';
filterFunc: FILTER  '(' var IN expression WHERE relationalExpression ')';
absFunc: ABS '(' expression ')';
randFunc:RAND NIL;
roundFunc:ROUND '(' expression ')';
sqrtFunc: SQRT '(' expression ')';
signFunc: SIGN '(' expression ')';
sinFunc:SIN '(' expression ')';
cosFunc:COS '(' expression ')';
tanFunc:TAN '(' expression ')';
cotFunc:COT '(' expression ')';
asinFunc:ASIN '(' expression ')';
acosFunc:ACOS '(' expression ')';
atanFunc:ATAN '(' expression ')';
atan2Func:ATAN2 '(' expression ',' expression ')';
haversinFunc:HAVERSIN '(' expression ')';
degreesFunc:DEGREES '(' expression ')';
radiansFunc:RADIANS '(' expression ')';
pi:PI NIL;
log10Func:LOG10 '(' expression ')';
logFunc:LOG '(' expression ')';
expFunc:EXP '(' expression ')';
e: EFUNC NIL;
countAllFunc:COUNT '(' '*' ')';
countFunc:COUNT '(' DISTINCT? idPath ')';
collectFunc:COLLECT '(' idPath ')';
sumFunc:SUM '(' idPath ')';
avgFunc:AVG '(' idPath ')';
minFunc:MIN '(' idPath ')';
maxFunc:MAX '(' idPath ')';
percentileDiscFunc:PERCENTILEDISC '(' idPath ',' numericLiteral ')';
percentileContFunc:PERCENTILECONT '(' idPath ',' numericLiteral ')';
stdevFunc:STDEV '(' expression ')';
stdevpFunc:STDEVP '(' expression ')';
toStringFunc:TOSTRING '(' expression ')';
replaceStrFunc:REPLACE '(' expression ',' expression ',' expression ')';
substringStrFunc:SUBSTRING '(' expression ',' INTEGER (',' INTEGER)? ')';
leftStrFunc:LEFT '(' expression ',' INTEGER ')';
rightStrFunc:RIGHT '(' expression ',' INTEGER ')';
trimStrFunc:TRIM '(' expression ')';
ltrimStrFunc:LTRIM '(' expression ')';
rtrimStrFunc:RTRIM '(' expression ')';
upperStrFunc:UPPER '(' expression ')';
lowerStrFunc:LOWER '(' expression ')';
splitStrFunc:SPLIT '(' expression ',' STRING ')';
reverseStrFunc:REVERSE '(' expression ')';
lengthStrFunc:LENGTH '(' expression ')';
nodeId: IDFUNC '(' id ')';
rangeFunc: RANGE '(' expression ',' expression (',' expression)? ')';
typeFunc: TYPE '(' id ')';
shortestPathFunc: SHORTESTPATH '(' expression ')';
relsFunc: RELS '(' expression ')';
allShortestPathsFunc: ALLSHORTESTPATHS '(' expression ')';
toLowerFunc: TOLOWER '(' expression ')';
toInt:TOINT '(' expression ')';
labelsFunc: LABELS '(' expression ')';
timestampFunc:TIMESTAMP NIL;
sizeFunc: SIZE '(' expression ')';
coalesceFunc: COALESCE expressionList;
headFunc: HEAD '(' expression ')';
lastFunc: LAST '(' expression ')';
startNodeFunc: STARTNODE '(' expression ')';
endNodeFunc: ENDNODE '(' expression ')';
propertiesFunc:PROPERTIES  '(' expression ')';
toFloatFunc: TOFLOAT  '(' expression ')';
keysFunc: KEYS '(' expression ')';
tailFunc: TAIL '(' expression ')';
reduceFunc: REDUCE '(' accumulator EQUAL expression ',' ID IN expression '|' expression ')';
accumulator : ID;
floorFunc: FLOOR '(' expression ')';     

graphElment: id labelVar;

anyVal :  STRING | BOOLEAN | NULL | parameterPath | numericLiteral |graphElment | idPath | json ;

//json
json:   jsonObject
    |   jsonArray
    ;

jsonObject
    :   ('{' jsonField (',' jsonField)* '}' 
            |   '{' '}' // empty object
        ) 
    ;
jsonArray
    :   '['list ']'  
    |   '[' ']' // empty array
    ;

jsonField:   id ':' expression;

numericLiteral: integerCypher | decimalCypher | doubleCypher ;
integerCypher   :   ('+'| '-')? INTEGER ;
decimalCypher   :   ('+'| '-')? DECIMAL ;
doubleCypher   :   ('+'| '-')? DOUBLE ;

parameterPath: PARAMETER ('.' id )*;
labelVar: ':' id ;
id: ID | MATCH | OPTIONAL | WITH | SKIP | LIMIT | UNION | RETURN | DETACH |REMOVE|SET|CALL|YIELD|CONSTRAINT|ON|ASSERT_|DROP|
    UNWIND|MERGE|INDEX|USING|SCAN|JOIN|FOREACH|CSV|IN|NOT|AND|OR|XOR|CASE|WHEN|ELSE|IS|UNIQUE|NULL|STARTS|START|ENDS|
    END|CONTAINS|THEN|ALL|ANY|NONE|SINGLE|COUNT|DISTINCT|SUM|MIN|MAX|AVG|WHERE|SELECT|AS|FROM|BY|ORDER|ASC|DESC|LOAD|
    CREATE|DELETE|EXISTS|HEADERS|FIELDTERMINATOR|PERIODIC|COMMIT|PROFILE|CYPHER|LENGTH|NODES|NODE|RELATIONSHIP|
    RELATIONSHIPS|EXTRACT|FILTER|ABS|RAND|ROUND|SQRT|SIGN|COS|TAN|COT|ASIN|ACOS|ATAN|ATAN2|HAVERSIN|SIN|DEGREES|RADIANS|
    PI|LOG10|LOG|EXP|EFUNC|COLLECT|PERCENTILEDISC|PERCENTILECONT|STDEVP|STDEV|TOSTRING|REPLACE|SUBSTRING|LEFT|RIGHT|TRIM|
    LTRIM|RTRIM|UPPER|LOWER|SPLIT|REVERSE|IDFUNC|RANGE|TYPE|SHORTESTPATH|RELS|ALLSHORTESTPATHS|TOLOWER|TOINT|LABELS|
    TIMESTAMP|SIZE|COALESCE|HEAD|LAST|STARTNODE|ENDNODE|PROPERTIES|TOFLOAT|KEYS|TAIL|REDUCE|FLOOR;
PARAMETER: '{' WS* (PN_CHARS_U ( PN_CHARS_U | [0-9])*) WS* '}';
LBRACE: '{';
RBRACE: '}';
MATCH: M A T C H;
OPTIONAL: O P T I O N A L;
WITH: W I T H;
SKIP: S K I P;
LIMIT: L I M I T;
UNION: U N I O N;
RETURN: R E T U R N;
DETACH: D E T A C H;
REMOVE: R E M O V E;
SET: S E T;
CALL: C A L L ;
YIELD: Y I E L D;
CONSTRAINT: C O N S T R A I N T;
ON: O N;
ASSERT_: A S S E R T;
DROP : D R O P ;
UNWIND :U N W I N D ;
MERGE: M E R G E;
INDEX: I N D E X;
USING : U S I N G;
SCAN:S C A N;
JOIN:J O I N;
FOREACH: F O R E A C H;
CSV: C S V;
IN:I N;
NOT:N O T;
AND: A N D ;
OR: O R;
XOR:X O R;

CASE: C A S E;
WHEN : W H E N;
ELSE : E L S E;
IS: I S;
UNIQUE:U N I Q U E;
NULL: N U L L ;
STARTS: S T A R T S;
START: S T A R T;
ENDS: E N D S;
END: E N D; 
CONTAINS: C O N T A I N S;  
THEN: T H E N;
ALL : A L L;
ANY: A N Y ;
NONE: N O N E;
SINGLE: S I N G L E;
BOOLEAN : BOOL_VAL_TRUE | BOOL_VAL_FALSE;
COUNT : C O U N T;
DISTINCT : D I S T I N C T;
SUM : S U M;
MIN : M I N;
MAX : M A X;
AVG : A V G;
WHERE: W H E R E;
SELECT:S E L E C T;
AS:A S;
FROM:F R O M;
BY:B Y;
ORDER:O R D E R;
ASC:A S C;
DESC:D E S C;   
LOAD:L O A D;
CREATE:C R E A T E;
DELETE:D E L E T E;
EXISTS:E X I S T S;
HEADERS:H E A D E R S;
FIELDTERMINATOR:F I E L D T E R M I N A T O R;
PERIODIC:P E R I O D I C;
COMMIT: C O M M I T;
PROFILE:P R O F I L E;
CYPHER:C Y P H E R ;

LENGTH : L E N G T H;
NODES : N O D E S;
NODE:N O D E;
RELATIONSHIP:R E L A T I O N S H I P;
RELATIONSHIPS:R E L A T I O N S H I P S;
EXTRACT:E X T R A C T;
FILTER:F I L T E R;
ABS:A B S;
RAND:R A N D;
ROUND:R O U N D;
SQRT:S Q R T;
SIGN:S I G N;
COS:C O S;
TAN:T A N;
COT:C O T;
ASIN:A S I N;
ACOS:A C O S;
ATAN:A T A N;
ATAN2:A T A N '2';
HAVERSIN:H A V E R S I N;
SIN:S I N;
DEGREES:D E G R E E S;
RADIANS:R A D I A N S;
PI:P I;
LOG10:L O G '10';
LOG:L O G;
EXP:E X P;
EFUNC:E;
COLLECT:C O L L E C T;
PERCENTILEDISC:P E R C E N T I L E D I S C;
PERCENTILECONT:P E R C E N T I L E C O N T;
STDEVP:S T D E V P;
STDEV:S T D E V;
TOSTRING:T O S T R I N G;
REPLACE:R E P L A C E;
SUBSTRING:S U B S T R I N G;
LEFT:L E F T;
RIGHT:R I G H T;
TRIM:T R I M;
LTRIM:L T R I M;
RTRIM:R T R I M;
UPPER:U P P E R;
LOWER:L O W E R;
SPLIT:S P L I T;
REVERSE:R E V E R S E;
IDFUNC:I D;
RANGE: R A N G E;
TYPE: T Y P E;
SHORTESTPATH: S H O R T E S T P A T H;
RELS:R E L S;
ALLSHORTESTPATHS:A L L S H O R T E S T P A T H S;
TOLOWER:T O L O W E R ;
TOINT: T O I N T ;
LABELS:L A B E L S;
TIMESTAMP:T I M E S T A M P;
SIZE:S I Z E;
COALESCE:C O A L E S C E;
HEAD: H E A D;
LAST:L A S T;
STARTNODE: S T A R T N O D E;
ENDNODE:E N D N O D E;
PROPERTIES:P R O P E R T I E S;
TOFLOAT:T O F L O A T;
KEYS:K E Y S;
TAIL:T A I L;
REDUCE:R E D U C E;
FLOOR:F L O O R;

EQUAL_REGUALR:'=~';
ADDEQUAL: '+=';
NOT_EQUAL:'<>';
LT_EQUAL:'<=';
GT_EQUAL:'>=';
DOUBLEDOT: '..';
ARROWAHEAD :'->';
ARROWBACK:'<-';
LT:'<';
GT:'>';
EQUAL:'=';
NEGATE:'!';
DOT:'.';
MULIT:'*';
ADD :'+';
SUBTRACTION:'-';
DIVISION:'/';
STRING: STRING_VAL1 | STRING_VAL2;
INTEGER   :   [0-9]+ ;
DECIMAL   :   [0-9]* '.' [0-9]+ ;
DOUBLE   :   [0-9]+ '.' [0-9]+ EXPONENT | '.' ([0-9])+ EXPONENT | ([0-9])+ EXPONENT ;
NIL   :   '(' ')' ;
WS   :   ('\u0020' | '\u0009' | '\u000D' | '\u000A') {skip();} ;
ANON   :   '[' ']' ;  
ID: (PN_CHARS_U ( PN_CHARS_U | [0-9])*) | ('`' (ESC | ~[`\\])* '`');

fragment STRING_VAL1   :   '\'' (ESC | ~['\\])* '\'' ;
fragment STRING_VAL2   :   '\"' (ESC | ~["\\])* '\"' ;
fragment BOOL_VAL_TRUE:'true';
fragment BOOL_VAL_FALSE:'false';
fragment ESC :   '\\' (['\\/bfnrt]);
fragment EXPONENT   :   'e' [+-]? [0-9]+ ;
fragment ECHAR   :   '\\' [tbnrf\\"'] ;
fragment PN_CHARS_BASE   :   (A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z) | [\u00C0-\u00D6] | [\u00D8-\u00F6] | [\u00F8-\u02FF] | [\u0370-\u037D] | [\u037F-\u1FFF] | [\u200C-\u200D] | [\u2070-\u218F] | [\u2C00-\u2FEF] | [\u3001-\uD7FF] | [\uF900-\uFDCF] | [\uFDF0-\uFFFD];// | [\u10000-\uEFFFF] ;
fragment PN_CHARS_U   :   PN_CHARS_BASE | '_' ;
fragment PN_CHARS   :   PN_CHARS_U | '-' | [0-9] | '\u00B7' | [\u0300-\u036F] | [\u203F-\u2040] ;

fragment A:[aA];
fragment B:[bB];
fragment C:[cC];
fragment D:[dD];
fragment E:[eE];
fragment F:[fF];
fragment G:[gG];
fragment H:[hH];
fragment I:[iI];
fragment J:[jJ];
fragment K:[kK];
fragment L:[lL];
fragment M:[mM];
fragment N:[nN];
fragment O:[oO];
fragment P:[pP];
fragment Q:[qQ];
fragment R:[rR];
fragment S:[sS];
fragment T:[tT];
fragment U:[uU];
fragment V:[vV];
fragment W:[wW];      
fragment X:[xX];
fragment Y:[yY];
fragment Z:[zZ];
