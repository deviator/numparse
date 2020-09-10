/+ dub.sdl:
    dependency "numparse" path=".."
    dflags "-betterC"
 +/
// dub --single --build=release bc.d -- -10 +0.5 abc -.1
module bench.bc;

import numparse;

import core.stdc.stdio;

extern(C) nothrow @nogc:
int main(int argc, char** argv)
{
    if (argc < 2)
    {
        fprintf(stderr, "pass float numbers to program\n");
        return 1;
    }

    foreach (i; 1 .. argc)
    {
        printf("try parse: %s\n", argv[i]);

        size_t n = 0;
        while (argv[i][n] != 0) n++;
        const arg = argv[i][0..n];

        double val;
        const err = parseSimpleFloatNumber!10(val, arg);
        if (err != ParseError.none)
            fprintf(stderr, "problem then parse '%s': %d\n", argv[i], err);
        else
            printf("%f\n", val);
    }
    return 0;
}
