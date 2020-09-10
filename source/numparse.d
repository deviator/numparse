///
module numparse;

import std.traits : isFloatingPoint, isIntegral, isUnsigned, isSigned, Unsigned, Signed;

///
enum ParseError
{
    none, ///
    wrongSymbol, ///
    valueLimit,  ///
    elementCount ///
}

pure @nogc nothrow @trusted
ParseError parseUintNumber(int bais, T)(ref T dst, scope const(char)[] str, uint* pow=null)
    if (isIntegral!T && isUnsigned!T)
{
    ulong result;

    static immutable tbl = buildSymbolTr(bais);
    if (str.length == 0)
    {
        dst = 0;
        return ParseError.none;
    }
    if (str.length > 64) return ParseError.valueLimit;

    int i;
    foreach (char c; str[0..$-1])
    {
        const v = tbl[c];
        if (v == -1) return ParseError.wrongSymbol;
        result = (result + v) * bais;
        i++;
    }
    const v = tbl[str[$-1]];
    if (v == -1) return ParseError.wrongSymbol;
    result += v;
    i++;

    if (pow !is null) *pow = i;

    version (checkfullstrlength)
    {
        static immutable ms = maxSymbols!(bais, T);
        if (i > ms) return ParseError.valueLimit;
    }

    if (result > T.max) return ParseError.valueLimit;
    dst = cast(T)result;
    return ParseError.none;
}

unittest
{
    import std : enforce, format, filter, map, array, AliasSeq;

    void testSuccessParse(int bais, T)(string ostr, T need, size_t line=__LINE__)
    {
        T val;
        const str = ostr.filter!"a!='_'".map!"cast(char)a".array;
        const err = parseUintNumber!bais(val, str);
        enforce (err == ParseError.none,
                 new Exception(format!"parse fails for '%s' with bais %d and type '%s': %s"
                                        (str, bais, T.stringof, err), __FILE__, line));
        enforce (val == need,
                 new Exception(format!"wrong value for '%s' with bais %d and type '%s': %s (need %s)"
                                        (str, bais, T.stringof, val, need), __FILE__, line));
    }

    void testFailureParse(int bais, T)(string ostr, ParseError need, size_t line=__LINE__)
    {
        T val;
        const str = ostr.filter!"a!='_'".map!"cast(char)a".array;
        const err = parseUintNumber!bais(val, str);
        enforce (err == need,
                 new Exception(format!"parse return wrong error for '%s' with bais %d and type '%s': %s (need %s)"
                                        (str, bais, T.stringof, err, need), __FILE__, line));
    }

    static immutable baises = [2, 8, 10, 16];
    alias TYPES = AliasSeq!(ubyte, ushort, uint, ulong);

    static foreach (b; baises)
    {
        static foreach (T; TYPES)
        {
            testSuccessParse!(b, T)("", 0);
            testSuccessParse!(b, T)("0", 0);
            testSuccessParse!(b, T)("1", 1);
        }
    }

    static foreach (T; TYPES)
    {
        foreach (ubyte bs; 0 .. ubyte.max)
        {
            testSuccessParse!(2,  T)(format!"%b"(bs), bs);
            testSuccessParse!(8,  T)(format!"%o"(bs), bs);
            testSuccessParse!(10, T)(format!"%d"(bs), bs);
            testSuccessParse!(16, T)(format!"%x"(bs), bs);

            testSuccessParse!(2,  T)(format!"%08b"(bs), bs);
            testSuccessParse!(8,  T)(format!"%03o"(bs), bs);
            testSuccessParse!(10, T)(format!"%03d"(bs), bs);
            testSuccessParse!(16, T)(format!"%02x"(bs), bs);
        }

        foreach (ubyte obs; 1 .. ubyte.max)
        {
            const bs = obs << 8;
            static if (is(T == ubyte))
            {
                testFailureParse!(2,  T)(format!"%b"(bs), ParseError.valueLimit);
                testFailureParse!(8,  T)(format!"%o"(bs), ParseError.valueLimit);
                testFailureParse!(10, T)(format!"%d"(bs), ParseError.valueLimit);
                testFailureParse!(16, T)(format!"%x"(bs), ParseError.valueLimit);
            }
            else
            {
                testSuccessParse!(2,  T)(format!"%b"(bs), bs);
                testSuccessParse!(8,  T)(format!"%o"(bs), bs);
                testSuccessParse!(10, T)(format!"%d"(bs), bs);
                testSuccessParse!(16, T)(format!"%x"(bs), bs);

                testSuccessParse!(2,  T)(format!"%016b"(bs), bs);
                testSuccessParse!(8,  T)(format!"%06o"(bs), bs);
                testSuccessParse!(10, T)(format!"%05d"(bs), bs);
                testSuccessParse!(16, T)(format!"%04x"(bs), bs);
            }
        }
    }

    testSuccessParse!(2, ubyte)("1", 1);
    testSuccessParse!(2, ubyte)("0001", 1);
    testSuccessParse!(2, ubyte)("0000_0001", 1);

    version (checkfullstrlength)
    {
        pragma(msg, "checkfullstrlength");
        testFailureParse!(2, ubyte)("0_0000_0000", ParseError.valueLimit);
        testFailureParse!(2, ubyte)("0_0000_0001", ParseError.valueLimit);
    }

    testSuccessParse!(2, ushort)("0_0000_0000", 0);
    testSuccessParse!(2, ushort)("0_0000_0001", 1);

    testSuccessParse!(2, uint)("1011_1001_1010_1100_0110_1010_1010_0011",
                              0b1011_1001_1010_1100_0110_1010_1010_0011);

    testSuccessParse!(2, ushort)("11111111", ubyte.max);
    testSuccessParse!(2, ushort)("1111111111111111", ushort.max);
    testSuccessParse!(2, uint)("11111111111111111111111111111111", uint.max);
    testSuccessParse!(2, ulong)("1111111111111111111111111111111111111111111111111111111111111111", ulong.max);

    testSuccessParse!(10, uint)("0145023", 145023);
    testSuccessParse!(16, uint)("abc3_af99", 0xabc3_af99);
}

unittest
{
    uint val;
    uint pow;
    assert (parseUintNumber!10(val, "1", &pow) == ParseError.none);
    assert (val == 1);
    assert (pow == 1);
    assert (parseUintNumber!10(val, "10", &pow) == ParseError.none);
    assert (val == 10);
    assert (pow == 2);
    assert (parseUintNumber!10(val, "01", &pow) == ParseError.none);
    assert (val == 1);
    assert (pow == 2);
    assert (parseUintNumber!10(val, "001", &pow) == ParseError.none);
    assert (val == 1);
    assert (pow == 3);
}

pure @nogc nothrow @trusted
ParseError parseIntNumber(int bais, T)(ref T dst, scope const(char)[] str, uint* pow=null)
    if (isIntegral!T && isSigned!T)
{
    if (str.length == 0)
    {
        dst = 0;
        return ParseError.none;
    }

    size_t s = 0;
    T k = 1;
    if (str[0] == '-')
    {
        k = -1;
        s = 1;
    }
    else if (str[0] == '+')
    {
        s = 1;
    }
    Unsigned!T result;
    const r = parseUintNumber!bais(result, str[s..$], pow);
    if (r != ParseError.none) return r;
    dst = (cast(T)result) * k;
    return ParseError.none;
}

unittest
{
    int val;
    assert (parseIntNumber!10(val, "") == ParseError.none);
    assert (val == 0);
    assert (parseIntNumber!10(val, "0") == ParseError.none);
    assert (val == 0);
    assert (parseIntNumber!10(val, "1") == ParseError.none);
    assert (val == 1);
    assert (parseIntNumber!10(val, "10") == ParseError.none);
    assert (val == 10);
    assert (parseIntNumber!10(val, "-10") == ParseError.none);
    assert (val == -10);
    assert (parseIntNumber!10(val, "+10") == ParseError.none);
    assert (val == 10);
}

pure @nogc nothrow @trusted
ParseError parseSimpleFloatNumber(int bais, T)(ref T dst, scope const(char)[] str, char sep='.')
    if (isFloatingPoint!T)
{
    if (str.length == 0)
    {
        dst = 0;
        return ParseError.none;
    }

    size_t s = 0;
    T k = 1;
    if (str[0] == '-')
    {
        k = -1;
        s = 1;
    }
    else if (str[0] == '+')
    {
        s = 1;
    }

    size_t sp;
    foreach (char c; str)
    {
        if (c == sep) break;
        sp++;
    }

    ulong c;
    if (sp > 0)
    {
        const r = parseUintNumber!bais(c, str[s..sp]);
        if (r != ParseError.none) return r;
    }

    sp++;

    T frac = 0;
    if (sp < str.length)
    {
        uint pow;
        ulong f;
        auto r2 = parseUintNumber!bais(f, str[sp..$], &pow);
        if (r2 != ParseError.none) return r2;
        T div = 1;
        foreach (i; 0 .. pow) div *= bais;
        frac = f / div;
    }
    dst = (c + frac) * k;
    return ParseError.none;
}

unittest
{
    import std : enforce, format, filter, map, array, AliasSeq, abs;

    void testSuccessParse(int bais, T)(string str, T need, size_t line=__LINE__)
    {
        T val;
        const err = parseSimpleFloatNumber!bais(val, str);
        enforce (err == ParseError.none,
                 new Exception(format!"parse fails for '%s' with bais %d and type '%s': %s"
                                        (str, bais, T.stringof, err), __FILE__, line));
        enforce (abs(val - need) < T.epsilon * 8,
                 new Exception(format!"wrong value for '%s' with bais %d and type '%s': %s (need %s)"
                                        (str, bais, T.stringof, val, need), __FILE__, line));
    }

    void testFailureParse(int bais, T)(string str, ParseError need, size_t line=__LINE__)
    {
        T val;
        const err = parseSimpleFloatNumber!bais(val, str);
        enforce (err == need,
                 new Exception(format!"parse return wrong error for '%s' with bais %d and type '%s': %s (need %s)"
                                        (str, bais, T.stringof, err, need), __FILE__, line));
    }

    testSuccessParse!(10, float)("", 0.0);
    testSuccessParse!(10, float)(".", 0.0);
    testSuccessParse!(10, float)("0", 0.0);
    testSuccessParse!(10, float)(".0", 0.0);
    testSuccessParse!(10, float)("0.", 0.0);
    testSuccessParse!(10, float)("0.0", 0.0);

    testSuccessParse!(10, float)("-", 0.0);
    testSuccessParse!(10, float)("-.", 0.0);
    testSuccessParse!(10, float)("-0", 0.0);
    testSuccessParse!(10, float)("-.0", 0.0);
    testSuccessParse!(10, float)("-0.", 0.0);
    testSuccessParse!(10, float)("-0.0", 0.0);

    testSuccessParse!(10, float)("2", 2.0);
    testSuccessParse!(10, float)("2.", 2.0);
    testSuccessParse!(10, float)("2.0", 2.0);
    testSuccessParse!(10, float)("20", 20.0);
    testSuccessParse!(10, float)("2.2", 2.2);
    testSuccessParse!(10, float)(".2", 0.2);
    testSuccessParse!(10, float)(".002", 0.002);
    testSuccessParse!(10, float)("30.002", 30.002);

    testSuccessParse!(10, float)("-2", -2.0);
    testSuccessParse!(10, float)("-2.", -2.0);
    testSuccessParse!(10, float)("-2.0", -2.0);
    testSuccessParse!(10, float)("-20", -20.0);
    testSuccessParse!(10, float)("-2.2", -2.2);
    testSuccessParse!(10, float)("-.2", -0.2);
    testSuccessParse!(10, float)("-.002", -0.002);
    testSuccessParse!(10, float)("-30.002", -30.002);

    testSuccessParse!(10, float)("+2", 2.0);
    testSuccessParse!(10, float)("+2.", 2.0);
    testSuccessParse!(10, float)("+2.0", 2.0);
    testSuccessParse!(10, float)("+20", 20.0);
    testSuccessParse!(10, float)("+2.2", 2.2);
    testSuccessParse!(10, float)("+.2", 0.2);
    testSuccessParse!(10, float)("+.002", 0.002);
    testSuccessParse!(10, float)("+30.002", 30.002);

    testFailureParse!(10, float)("2+", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.+", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.+0", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.0+", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.+2", ParseError.wrongSymbol);
    testFailureParse!(10, float)(".+2", ParseError.wrongSymbol);
    testFailureParse!(10, float)(".+002", ParseError.wrongSymbol);
    testFailureParse!(10, float)("30+.002", ParseError.wrongSymbol);

    testFailureParse!(10, float)("2-", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.-", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.-0", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.0-", ParseError.wrongSymbol);
    testFailureParse!(10, float)("2.-2", ParseError.wrongSymbol);
    testFailureParse!(10, float)(".-2", ParseError.wrongSymbol);
    testFailureParse!(10, float)(".-002", ParseError.wrongSymbol);
    testFailureParse!(10, float)("30-.002", ParseError.wrongSymbol);
}

pure @nogc nothrow @trusted
ParseError parseUintNumbers(int bais, T)(T[] dst, scope const(char)[] str, char splt)
{
    if (str.length == 0) return ParseError.none;

    size_t cnt;
    foreach (char c; str) cnt += c == splt;
    if (cnt + 1 != dst.length) return ParseError.elementCount;

    size_t s, i;
    foreach (e, char c; str)
    {
        if (c == splt)
        {
            if (s < e)
            {
                const r = parseUintNumber!bais(dst[i], str[s..e]);
                if (r != ParseError.none) return r;
            }
            i++;

            s = e+1;
        }
    }
    if (s < str.length)
    {
        const r = parseUintNumber!bais(dst[i], str[s..$]);
        if (r != ParseError.none) return r;
    }

    return ParseError.none;
}

unittest
{
    import std : enforce, format, filter, map, array, AliasSeq;

    void testSuccessParse(int bais, T)(string str, char splt, T[] need, string file=__FILE__, size_t line=__LINE__)
    {
        T[] val;
        val.length = need.length;
        const err = parseUintNumbers!bais(val, str, splt);
        enforce (err == ParseError.none,
                 new Exception(format!"parse fails for '%s' with bais %d and type '%s': %s"
                                        (str, bais, T.stringof, err), file, line));
        enforce (val == need,
                 new Exception(format!"wrong value for '%s' with bais %d and type '%s': %s (need %s)"
                                        (str, bais, T.stringof, val, need), file, line));
    }

    testSuccessParse!(10, ubyte)("...", '.', [0, 0, 0, 0]);
    testSuccessParse!(10, ubyte)("...5", '.', [0, 0, 0, 5]);
    testSuccessParse!(10, ubyte)("..5.", '.', [0, 0, 5, 0]);
    testSuccessParse!(10, ubyte)(".5..", '.', [0, 5, 0, 0]);
    testSuccessParse!(10, ubyte)("5...", '.', [5, 0, 0, 0]);
    testSuccessParse!(10, ubyte)("5.5..", '.', [5, 5, 0, 0]);
    testSuccessParse!(10, ubyte)("5..5.", '.', [5, 0, 5, 0]);
    testSuccessParse!(10, ubyte)("5...5", '.', [5, 0, 0, 5]);
    testSuccessParse!(10, ubyte)("5..5.5", '.', [5, 0, 5, 5]);
    testSuccessParse!(10, ubyte)("5.5..5", '.', [5, 5, 0, 5]);
    testSuccessParse!(10, ubyte)("5.5.5.5", '.', [5, 5, 5, 5]);
    testSuccessParse!(10, ubyte)("123.0.10.5", '.', [123, 0, 10, 5]);

    //testFailureParse!(10, ubyte)("...", '.', [0, 0, 0, 0]);
}

private:

size_t maxSymbols(int bais, T)()
{
    enum TS = T.sizeof;
    enum TSb = TS * 8;
    import std.math;
    return cast(size_t)ceil(TSb / log2(bais));
}

unittest
{
    static assert(maxSymbols!(2, ubyte) == 8);
    static assert(maxSymbols!(2, ushort) == 16);
    static assert(maxSymbols!(2, uint) == 32);
    static assert(maxSymbols!(2, ulong) == 64);

    static assert(maxSymbols!(8, ubyte) == 3);
    static assert(maxSymbols!(8, ushort) == 6);
    static assert(maxSymbols!(8, uint) == 11);
    static assert(maxSymbols!(8, ulong) == 22);

    static assert(maxSymbols!(10, ubyte) == 3);
    static assert(maxSymbols!(10, ushort) == 5);
    static assert(maxSymbols!(10, uint) == 10);
    static assert(maxSymbols!(10, ulong) == 20);

    static assert(maxSymbols!(16, ubyte) == 2);
    static assert(maxSymbols!(16, ushort) == 4);
    static assert(maxSymbols!(16, uint) == 8);
    static assert(maxSymbols!(16, ulong) == 16);
}

pure @nogc nothrow @safe
byte[ubyte.max] buildSymbolTr(int bais)
{
    if (bais < 2 || bais > 16) assert(0, "unsupported bais");
    import std.uni : toLower, toUpper;
    typeof(return) r;
    static immutable char[] sym = "0123456789abcdef";
    r[] = -1;
    foreach (i; 0 .. bais)
    {
        r[cast(ubyte)(sym[i].toLower)] = cast(byte)i;
        r[cast(ubyte)(sym[i].toUpper)] = cast(byte)i;
    }
    return r;
}
