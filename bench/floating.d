/+ dub.sdl:
    dependency "numparse" path=".."
 +/
module bench.floating;

import std.datetime.stopwatch;
import std : uniform, tuple, Tuple, format, to, stderr, abs;

import numparse;

enum N = 5_000_000;

float test()
{
    alias T = float;
    Tuple!(T, string)[] list;
    list.length = N;

    immutable fmt = "%.6f";

    foreach (i; 0 .. N)
    {
        const v = uniform(-1000.0f, 1000.0f);
        const str = format(fmt, v);
        list[i] = tuple(str.to!T, str);
    }

    static void checkValid(T orig, T parsed, string str, size_t line=__LINE__)
    {
        if (abs(orig - parsed) <= 1e-6) return;
        throw new Exception("wrong parse: %s(%f) parsed as %f".format(str, orig, parsed), __FILE__, line);
    }

    auto t0 = StopWatch(AutoStart.yes);
    foreach (v; list)
    {
        T tmp;
        auto err = parseSimpleFloatNumber!10(tmp, v[1]);
        if (err != ParseError.none)
            throw new Exception("parse error: %s (%s)".format(err, v[1]));
        checkValid(v[0], tmp, v[1]);
    }
    t0.stop();

    auto t1 = StopWatch(AutoStart.yes);
    foreach (v; list)
    {
        T tmp;
        if (v[1].length) tmp = v[1].to!T;
        checkValid(v[0], tmp, v[1]);
    }
    t1.stop();

    const t0f = cast(float)t0.peek().total!"hnsecs";

    stderr.writeln("numparse: ", t0.peek());
    stderr.writeln("std impl: ", t1.peek());
    const win = t1.peek().total!"hnsecs" / t0f;
    stderr.writeln("     win: ", win);
    return win;
}

void main()
{
    stderr.writeln("number count: ", N);
    stderr.writeln("avg win: ", test());
}
