# Describe SQL syntax.
# Generic SQL, not specific (Trying to be standard).
# NOTE: This is a fast definition.  Expect lacks and mistakes.
LANGUAGE SQL
EXTENSIONS sql

CASE INSENSITIVE
COMMENT STARTS "--"

STRING SIMPLE "'"
STRING SIMPLE '"'
STRING SIMPLE '`'

SYMBOLS "#()[]:;,."
IDENTIFIER CHARS "abcdefghijklmnopqrstuvwxyz0123456789_"

KEYWORDS
  CREATE ALTER DROP TRUNC
  TABLE
  SELECT FROM WHERE
  INSERT INTO VALUES
  DELETE
  LEFT RIGHT INNER JOIN
END KEYWORDS

TYPES
  Integer Currency
  VarChar
END TYPES

OPERATORS
  + - * /
  < <= = => > <> LIKE
  NOT AND OR
END OPERATORS

IDENTIFIERS
END IDENTIFIERS
