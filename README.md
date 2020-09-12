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
ParseError parseUintNumber(int base, T)(ref T dst, scope const(char)[] str, uint* pow=null)
    if (isIntegral!T && isUnsigned!T);

pure @nogc nothrow @trusted
ParseError parseIntNumber(int base, T)(ref T dst, scope const(char)[] str, uint* pow=null)
    if (isIntegral!T && isSigned!T);

pure @nogc nothrow @trusted
ParseError parseSimpleFloatNumber(int base, T)(ref T dst, scope const(char)[] str, char sep='.')
    if (isFloatingPoint!T);
```

`base` must be `>=2` and `<=16`
