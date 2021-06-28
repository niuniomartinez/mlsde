# Describe c syntax.
LANGUAGE C
EXTENSIONS c h

CASE SENSITIVE
COMMENT STARTS "/*" ENDS "*/"
DIRECTIVE STARTS "#"

STRING SIMPLE '"'
HEX PREFIX "0x"

SYMBOLS "{}()[]:;,."
IDENTIFIER CHARS "abcdefghijklmnopqrstuvwxyz0123456789_"

KEYWORDS
  if else
  switch case default
  for
  do while
  return break continue
  asm
  const auto extern static
  typedef struct union enum
  goto
# post ANSI-C
  inline
END KEYWORDS

TYPES
  void
  long short signed unsigned
  char int
  float double
  register volatile
END TYPES

OPERATORS
  ->
  =
  + - * / %
  ? :
  < <= == => > !=
  & && | || ! ~ ^
  << >>
  ++ --
  sizeof
END OPERATORS

IDENTIFIERS
  printf puts scanf
  fopen fclose fseek ftell
  malloc calloc realloc free
  strlengh strcmp

  main

  TRUE FALSE
  NULL
END IDENTIFIERS
