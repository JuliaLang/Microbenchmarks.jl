# Julia MicroBenchmarks

These micro-benchmarks, while not comprehensive, do test compiler performance on a range of common code patterns, such as function calls, string parsing, sorting, numerical loops, random number generation, recursion, and array operations.

It is important to note that the benchmark codes are not written for absolute maximal performance (the fastest code to compute `recursion_fibonacci(20)` is the constant literal `6765`). Instead, the benchmarks are written to test the performance of identical algorithms and code patterns implemented in each language. For example, the Fibonacci benchmarks all use the same (inefficient) doubly-recursive algorithm, and the pi summation benchmarks use the same for-loop. The “algorithm” for matrix multiplication is to call the most obvious built-in/standard random-number and matmul routines (or to directly call BLAS if the language does not provide a high-level matmul), except where a matmul/BLAS call is not possible (such as in JavaScript).

![Benchmark results](benchmarks.svg)

Note that the Julia results depicted above do not include compile time.

These micro-benchmark results were obtained on a single core (serial execution) on Github Actions.
