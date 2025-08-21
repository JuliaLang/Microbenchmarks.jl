# Microbenchmarks

This is a collection of micro-benchmarks used to compare Julia's performance against
that of other languages.
It was formerly part of the Julia source tree.
The results of these benchmarks are used to generate the performance graph on the
[Julia benchmarks page](https://julialang.org/benchmarks).

The benchmark [results](https://julialang.github.io/Microbenchmarks.jl/) are auto-generated 
on Github Actions.

## Running benchmarks

Install Julia with `juliaup`.

To build binaries and run the benchmarks, simply run `make`.
Note that this refers to GNU Make, so BSD users will need to run `gmake`.

## Included languages:

* C
* Fortran
* Go
* Java
* JavaScript
* Julia
* LuaJIT
* Mathematica
* Matlab
* Python
* R
* Rust
* Scala
