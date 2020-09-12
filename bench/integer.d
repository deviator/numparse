/+ dub.sdl:
    dependency "numparse" path=".."
 +/
module bench.integer;

import std.datetime.stopwatch;
import std : uniform, tuple, Tuple, format, to, stderr;

import numparse;

enum Base
{
    bin = 2,
    oct = 8,
    dec = 10,
    hex = 16
}

enum N = 5_000_000;

string getFormat(Base b, bool longfmt)
{
    final switch (b)
    {
        case Base.bin: return longfmt ? "%032b" : "%b";
        case Base.oct: return longfmt ? "%011o" : "%o";
        case Base.dec: return longfmt ? "%010d" : "%d";
        case Base.hex: return longfmt ? "%08x" : "%x";
    }
}

float test(Base base)(bool canEmpty=false, bool longFmt=true)
{
    Tuple!(uint, string)[] list;
    list.length = N;

    immutable fmt = getFormat(base, longFmt);

    foreach (i; 0 .. N)
    {
        const v = uniform(0, uint.max);
        const str = format(fmt, v);
        list[i] = tuple(cast()v, canEmpty ? (v ? str : "") : str);
    }

    static void checkValid(uint orig, uint parsed, string str, size_t line=__LINE__)
    {
        if (orig == parsed) return;
        throw new Exception("wrong parse: %s(%d) parsed as %d".format(str, orig, parsed), __FILE__, line);
    }

    auto t0 = StopWatch(AutoStart.yes);
    foreach (v; list)
    {
        uint tmp;
        auto err = parseUintNumber!(base)(tmp, v[1]);
        if (err != ParseError.none)
            throw new Exception("parse error: %s".format(err));
        checkValid(v[0], tmp, v[1]);
    }
    t0.stop();

    auto t1 = StopWatch(AutoStart.yes);
    foreach (v; list)
    {
        uint tmp;
        if (v[1].length) tmp = v[1].to!uint(cast(int)base);
        checkValid(v[0], tmp, v[1]);
    }
    t1.stop();

    const t0f = cast(float)t0.peek().total!"hnsecs";

    stderr.writeln("Base: ", base, " canEmpty: ", canEmpty, " longFmt: ", longFmt);
    stderr.writeln("numparse: ", t0.peek());
    stderr.writeln("std impl: ", t1.peek());
    const win = t1.peek().total!"hnsecs" / t0f;
    stderr.writeln("     win: ", win);
    return win;
}

void main()
{
    import std : EnumMembers;

    stderr.writeln("number count: ", N);

    float swin = 0;
    size_t k = 0;

    enum params = 
    [
        tuple(true, true),
        tuple(true, false),
        tuple(false, false),
        tuple(false, true),
    ];

    foreach (pp; params)
    {
        static foreach (b; EnumMembers!Base)
        {
            swin += test!b(pp.expand);
            k++;
        }
    }

    stderr.writeln("avg win: ", swin / k);
}
