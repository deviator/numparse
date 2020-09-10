# NUMPARSE

Library for parsing numbers from string.
`nothrow`, `@nogc`, `pure`, `@trusted` and `betterC` compatible.

Provide:

```d
enum ParseError
{
    none,
    wrongSymbol,
    valueLimit,
    elementCount
}

pure @nogc nothrow @trusted
ParseError parseUintNumber(int bais, T)(ref T dst, scope const(char)[] str, uint* pow=null)
    if (isIntegral!T && isUnsigned!T);

pure @nogc nothrow @trusted
ParseError parseIntNumber(int bais, T)(ref T dst, scope const(char)[] str, uint* pow=null)
    if (isIntegral!T && isSigned!T);

pure @nogc nothrow @trusted
ParseError parseSimpleFloatNumber(int bais, T)(ref T dst, scope const(char)[] str, char sep='.')
    if (isFloatingPoint!T);
```

`bais` must be `>=2` and `<=16`
