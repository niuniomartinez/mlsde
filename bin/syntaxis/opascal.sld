# Describe Object Pascal syntax.
LANGUAGE Object Pascal
EXTENSIONS pas pp lpr dpr

CASE INSENSITIVE
COMMENT STARTS "{" ENDS "}"
COMMENT STARTS "(*" ENDS "*)"
COMMENT STARTS "//"
DIRECTIVE STARTS "{$" ENDS "}"
DIRECTIVE STARTS "(*$" ENDS "*)"

STRING SIMPLE "'"
HEX PREFIX "$"

SYMBOLS "#()[]:;,."
IDENTIFIER CHARS "abcdefghijklmnopqrstuvwxyz0123456789_"

KEYWORDS
  program procedure function
  unit uses interface implementation
  var const type record array set
  begin end
  if then else
  wile do
  repeat until
  for to downto
  case of otherwise
  as absolute

  class private protected public published
  constructor destructor operator
  property virtual abstract override
  inherited
  try finally except on
  in # Promoted to keyword because the FOR .. IN loops.
END KEYWORDS

TYPES
  Byte Word DoubleWord
  ShortInt SmallInt Integer LongInt
  Boolean
  Real Single Double
  Char WideChar AnsiChar
  String PascalString AnsiString WideString
  Pointer PChar
  File Text
END TYPES

OPERATORS
  := @ ^
  + - * / div mod
  < <= = => > <>
  not and or xor
  shl shr
END OPERATORS

IDENTIFIERS
  True False Nil
  Write WriteLn readLn
  ParamCnt ParamStr
  Hi Lo Abs Trunc Chr Ord
  Result Exit
  Length Setlength High Low
  GetMem Dispose Assigned
  Concat UpCase LowerCase
  Pos

  read write default
  self
  Exception
  Create Destroy Free
END IDENTIFIERS
