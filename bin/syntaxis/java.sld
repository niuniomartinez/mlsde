# Describe Java syntax.
LANGUAGE Java
EXTENSIONS java

CASE SENSITIVE
COMMENT STARTS "/*" ENDS "*/"
COMMENT STARTS "//"

STRING SIMPLE '"'
STRING SIMPLE "'"
HEX PREFIX "0x"

SYMBOLS "()[]{}:;,."
IDENTIFIER CHARS "abcdefghijklmnopqrstuvwxyz0123456789_"

KEYWORDS
  package # Tempted to make it a DIRECTIVE STARTS "package" ENDS ";".
  import # Same than above.
  interface class extends implements new
  public private protected abstract default final static throws
  if else
  switch case default break
  for while do continue
  return
  try throw catch finally
END KEYWORDS

TYPES
  void
  boolean
  byte int long
  double
  char String
END TYPES

OPERATORS
  ... # Not sure about this, but cannot be type or identifier (maybe someday).
  =
  * / + - %
  += -= *= /=
  ++ --
  << >> <<= >>=
  == != < > >= <=
  & && | || ^ !
  =
END OPERATORS

IDENTIFIERS
  true false
  main this super
# Java has a HUGE standard runtime library.  I'll not add it all here.
# In any case, maybe I'll remove it all in the future.  Not sure.
  length substring charAt equals compareTo indexOf lastIndexOf
  java io
  System out println print write in read

  Math sqrt
END IDENTIFIERS
