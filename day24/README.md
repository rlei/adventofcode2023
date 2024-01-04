# Advent of Code 2023 - Day 24

Solved with [Julia](https://julialang.org/) `1.9.2`, [SymPy.jl](https://github.com/JuliaPy/SymPy.jl) and [NLsolve.jl](https://github.com/JuliaNLSolvers/NLsolve.jl).

## Problem 1 & 2

To run:

`julia day24.jl < path/to/input_data`

Note for the first run, it needs a moment to download the needed packages.

Solving part 1 takes much longer time probably due to the overhead calling SymPy which is
a Python module. Though I'm too lazy to replace it with the builtin linear system solving.

## See also

* [SymPy](https://docs.sympy.org/latest/guides/solving/solve-system-of-equations-algebraically.html)
