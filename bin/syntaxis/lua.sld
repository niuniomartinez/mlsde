# Describe Lua syntax.
# I'm not Lua developer so there may be some lacks and mistakes.
LANGUAGE Lua
EXTENSIONS lua

CASE SENSITIVE
COMMENT STARTS "--"

# TODO: Multiline.
STRING SIMPLE '"'
STRING SIMPLE "'"

SYMBOLS ".,:()[]{}#"
IDENTIFIER CHARS "abcdefghijklmnopqrstuvwxyz0123456789_"

KEYWORDS
  local
  function return
  end
  if then elseif else
  for do while repeat until break
END KEYWORDS

OPERATORS
  + - * /
  = < > == ~=
  ..
END OPERATORS

TYPES
  table
END TYPES

IDENTIFIERS
  print tostring
  insert remove pairs
  math random
  true false
END IDENTIFIERS
