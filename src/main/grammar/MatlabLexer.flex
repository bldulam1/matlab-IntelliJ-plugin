package com.github.korniloval.matlab.lexer;

import com.intellij.lexer.FlexAdapter;
import com.intellij.lexer.FlexLexer;
import com.intellij.psi.tree.IElementType;

import static com.github.korniloval.matlab.psi.MatlabTypes.*;
import static com.intellij.psi.TokenType.BAD_CHARACTER;
import static com.intellij.psi.TokenType.WHITE_SPACE;

%%

%{
    private boolean isTranspose = false;
    private int blockCommentLevel = 0;

    public static FlexAdapter getAdapter() {
        return new FlexAdapter(new MatlabLexer());
    }

    private MatlabLexer() {
        this(null);
    }
%}

%public
%class MatlabLexer
%implements FlexLexer
%function advance
%type IElementType
%unicode

NEWLINE=(\R( \t)*)+
WHITE_SPACE=[ \t\x0B\f]+ // do not match new line
SINGLE_QUOTE='
LINE_COMMENT=%.*
FLOAT=(([\d]*\.[\d]+)|([\d]+\.))i?
FLOAT_EXPONENTIAL=(([\d]*\.[\d]+)|([\d]+\.)|\d+)e[\+-]?[\d]+i?
IDENTIFIER = [:jletter:] [:jletterdigit:]*
INTEGER=[0-9]+i?

/* double quote literal does not allow single \ character. Sequence \" gives double quote */
ESCAPE_SEQUENCE = \\[^\r\n]
DOUBLE_QUOTE_STRING = \" ([^\\\"\r\n] | {ESCAPE_SEQUENCE})* \"?
/* single quote literal allows single \ character. Sequence '' gives single quote */
SINGLE_QUOTE_EXCAPE_SEQUENCE=\\[\\bfnrt]|''

%state STRING_SINGLE_STATE
%state BLOCKCOMMENT_STATE
%state FILE_NAME_STATE

%%
<YYINITIAL> {
  {WHITE_SPACE}         { isTranspose = false; return WHITE_SPACE; }

  {SINGLE_QUOTE}$       { if (isTranspose) {
                              isTranspose = false;
                              return TRANSPOSE;
                          } else {
                              return SINGLE_QUOTE_STRING;
                          }
                        }

  {SINGLE_QUOTE}        { if (isTranspose) {
                              isTranspose = false;
                              return TRANSPOSE;
                          } else {
                              yybegin(STRING_SINGLE_STATE);
                          }
                        }

  function              { isTranspose = false; return FUNCTION; }
  elseif                { isTranspose = false; return ELSEIF; }
  else                  { isTranspose = false; return ELSE; }
  end                   { isTranspose = false; return END; }
  if                    { isTranspose = false; return IF; }
  for                   { isTranspose = false; return FOR; }
  while                 { isTranspose = false; return WHILE; }
  classdef              { isTranspose = false; return CLASSDEF; }
  properties            { isTranspose = false; return PROPERTIES; }
  methods               { isTranspose = false; return METHODS; }
  load/" "+[^ (]        { isTranspose = false; yybegin(FILE_NAME_STATE); return LOAD; }
  true                  { return TRUE; }
  false                 { return FALSE; }

  "("                   { isTranspose = false; return LPARENTH; }
  ")"                   { isTranspose = true; return RPARENTH; }
  "."                   { isTranspose = false; return DOT; }
  "<="                  { isTranspose = false; return LESS_OR_EQUAL; }
  "-"                   { isTranspose = false; return MINUS; }
  "+"                   { isTranspose = false; return PLUS; }
  "./"                  { isTranspose = false; return DOT_RDIV; }
  "/"                   { isTranspose = false; return RDIV; }
  "\\"                  { isTranspose = false; return LDIV; }
  ".\\"                 { isTranspose = false; return DOT_LDIV; }
  ".*"                  { isTranspose = false; return DOT_MUL; }
  "*"                   { isTranspose = false; return MUL; }
  ".^"                  { isTranspose = false; return DOT_POW; }
  "^"                   { isTranspose = false; return POW; }
  "&&"                  { isTranspose = false; return AND; }
  "&"                   { isTranspose = false; return MATRIX_AND; }
  "||"                  { isTranspose = false; return OR; }
  "|"                   { isTranspose = false; return MATRIX_OR; }
  ".'"                  { isTranspose = false; return DOT_TRANSPOSE; }
  "~"                   { isTranspose = false; return TILDA; }
  "="                   { isTranspose = false; return ASSIGN; }
  ">="                  { isTranspose = false; return MORE_OR_EQUAL; }
  ">"                   { isTranspose = false; return MORE; }
  "<"                   { isTranspose = false; return LESS; }
  "=="                  { isTranspose = false; return EQUAL; }
  "!="                  { isTranspose = false; return NOT_EQUAL; }
  ","                   { isTranspose = false; return COMA; }
  ":"                   { isTranspose = false; return COLON; }
  ";"                   { isTranspose = false; return SEMICOLON; }
  "["                   { isTranspose = false; return LBRACKET; }
  "]"                   { isTranspose = true; return RBRACKET; }
  "{"                   { isTranspose = false; return LBRACE; }
  "}"                   { isTranspose = false; return RBRACE; }
  "%{"                  { isTranspose = false; blockCommentLevel = 1; yybegin(BLOCKCOMMENT_STATE); }
  "..."                 { isTranspose = false; return DOTS; }
  "."                   { isTranspose = false; return DOT; }

  {NEWLINE}             { isTranspose = false; return NEWLINE; }
  {LINE_COMMENT}        { isTranspose = false; return COMMENT; }
  {FLOAT_EXPONENTIAL}   { isTranspose = false; return FLOAT_EXPONENTIAL; }
  {FLOAT}               { isTranspose = false; return FLOAT; }
  {INTEGER}             { isTranspose = false; return INTEGER; }
  {IDENTIFIER}          { isTranspose = true; return IDENTIFIER; }
  {DOUBLE_QUOTE_STRING} { return DOUBLE_QUOTE_STRING; }

  <<EOF>>               { return null; }
}

<STRING_SINGLE_STATE> {
    {SINGLE_QUOTE_EXCAPE_SEQUENCE} / \n  { yybegin(YYINITIAL); return SINGLE_QUOTE_STRING; }
    {SINGLE_QUOTE_EXCAPE_SEQUENCE}       {  }
    "'"                                  { yybegin(YYINITIAL); return SINGLE_QUOTE_STRING; }
    <<EOF>>                              { yybegin(YYINITIAL); return SINGLE_QUOTE_STRING; }

    /* line should not consume \n character */
    . / \n                               { yybegin(YYINITIAL); return SINGLE_QUOTE_STRING; }
    .                                    {  }
}

<BLOCKCOMMENT_STATE> {
    "%{"                { blockCommentLevel += 1; }

    "%}"                { blockCommentLevel -= 1;
                          if (blockCommentLevel == 0) {
                              yybegin(YYINITIAL);
                              return COMMENT;
                          }
                        }
    <<EOF>>             { yybegin(YYINITIAL); return COMMENT; }

    [^]                 {  }
}

<FILE_NAME_STATE> {
    /* stop consuming filename when find newline */
    [^\n(]/\n         { yybegin(YYINITIAL); return FILE_NAME; }
    "("               { yybegin(YYINITIAL); }
    [^\n(]            {  }
}

[^] { return BAD_CHARACTER; }
