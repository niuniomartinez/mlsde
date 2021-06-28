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
  program procedure function forward
  unit uses interface implementation
  var const type packed record array set
  begin end
  if then else
  wile do
  repeat until
  for to downto
  case of otherwise
  as absolute
  with

  class private protected public published object
  constructor destructor operator
  property virtual abstract override
  inherited
  try finally except on
  in # Promoted to keyword because the FOR .. IN loops.
END KEYWORDS

TYPES
  Byte Word DoubleWord QWord UInt64
  ShortInt SmallInt Integer LongInt Int64
  Boolean
  Real Single Double
  Char WideChar AnsiChar
  String PascalString AnsiString WideString
  Pointer PChar
  File Text
END TYPES

OPERATORS
  .. # Not sure about this, but cannot be type or identifier (maybe someday).
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
