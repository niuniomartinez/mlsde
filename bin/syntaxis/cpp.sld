# Describe C++ syntax.
LANGUAGE C++
EXTENSIONS cpp hpp

CASE SENSITIVE
COMMENT STARTS "/*" ENDS "*/"
COMMENT STARTS "//"
DIRECTIVE STARTS "#"

STRING SIMPLE '"'
HEX PREFIX "0x"

SYMBOLS "{}()[]:;,."
IDENTIFIER CHARS "abcdefghijklmnopqrstuvwxyz0123456789_"

KEYWORDS
# From C.
  if else
  switch case default
  for
  do while
  return break continue
  asm
  const auto extern static
  typedef struct union enum
  goto
  inline
# New in C++.
  namespace using
  class private protected public friend virtual
  new delete
  template
  throw try catch
  explicit

  const_cast dynamic_cast reinterpret_cast static_cast
  mutable
  typeid typename
END KEYWORDS

TYPES
# From C.
  void
  long short signed unsigned
  char int
  float double
  register volatile
# New in C++.
  bool
  wchar_t
END TYPES

OPERATORS
# From C.
  ->
  =
  + - * / %
  ? :
  < <= == => > !=
  & && | || ! ~ ^
  << >>
  ++ --
  sizeof
# New in C++.
# Some extra operators.  Not used by all implementations (never saw in use).
  and and_eq or or_eq not not_eq xor xor_eq
  bitand bitor
  compl
END OPERATORS

IDENTIFIERS
# From C.
  printf puts scanf
  fopen fclose fseek ftell
  malloc calloc realloc free
  strlengh strcmp

  main

  TRUE FALSE
  NULL
# New in C++.
  true false
  this
  operator

  cin cout endl
  std string
END IDENTIFIERS
