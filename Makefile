# Will make multi-line targets work
# (so we can use @for on the second line)
.ONESHELL:

NODEJSBIN = node

ITERATIONS=$(shell seq 1 5)

PYTHON = python3

OCTAVE = octave-cli

ifeq ($(OS), WINNT)
MATHEMATICABIN = MathKernel
else ifeq ($(OS), Darwin)
MATHEMATICABIN = MathKernel
else
MATHEMATICABIN = math
endif

FFLAGS=-fexternal-blas
#gfortran cannot multiply matrices using 64-bit external BLAS.
ifeq ($(findstring gfortran, $(FC)), gfortran)
ifeq ($(USE_BLAS64), 1)
FFLAGS=
endif
FFLAGS+= -static-libgfortran
endif

default: benchmarks.html

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

dsfmt:
	mkdir -p dSFMT
	cd dSFMT
	wget -q https://github.com/MersenneTwister-Lab/dSFMT/archive/refs/tags/v2.2.4.tar.gz
	echo "39682961ecfba621a98dbb6610b6ae2b7d6add450d4f08d8d4edd0e10abd8174 v2.2.4.tar.gz" | sha256sum --check --status
	tar -xzf v2.2.4.tar.gz
	mv dSFMT-*/* ./
	cd ..

bin/perf%: perf.c
	$(CC) -std=c99 -O$* $< -o $@  -IdSFMT -lopenblas -lm $(CFLAGS) -lpthread

bin/fperf%: perf.f90
	mkdir -p mods/$@ #Modules for each binary go in separate directories
	$(FC) $(FFLAGS) -Jmods/$@ -O$* $< -o $@ -lopenblas -lm -lpthread

benchmarks/c.csv: benchmarks/c2.csv
	cat $^ > $@

benchmarks/fortran.csv:	benchmarks/fortran2.csv
	cat $^ > $@

benchmarks/c%.csv: bin/perf%
	@for t in $(ITERATIONS); do $<; done >$@

benchmarks/fortran%.csv: bin/fperf%
	@for t in $(ITERATIONS); do $<; done >$@

benchmarks/go.csv: export GOPATH=$(abspath gopath)
benchmarks/go.csv: perf.go
	export CGO_LDFLAGS="-lopenblas"
	go install gonum.org/v1/netlib/blas/netlib@latest
	go install gonum.org/v1/gonum/mat64@latest
	go install gonum.org/v1/gonum/stat@latest
	@for t in $(ITERATIONS); do go run $<; done >$@

benchmarks/julia.csv: perf.jl
	@for t in $(ITERATIONS); do julia $<; done >$@

benchmarks/python.csv: perf.py
	@for t in $(ITERATIONS); do $(PYTHON) $<; done >$@

benchmarks/matlab.csv: perf.m
	@for t in $(ITERATIONS); do matlab -nojvm -singleCompThread -r 'perf; perf; exit' | grep ^matlab | tail -8; done >$@

benchmarks/octave.csv: perf.m
	@for t in $(ITERATIONS); do $(OCTAVE) -q --eval perf 2>/dev/null; done >$@

benchmarks/r.csv: perf.R
	@for t in $(ITERATIONS); do cat $< | R --vanilla --slave 2>/dev/null; done >$@

benchmarks/javascript.csv: perf.js
	@for t in $(ITERATIONS); do $(NODEJSBIN) $<; done >$@

benchmarks/mathematica.csv: perf.nb
	@for t in $(ITERATIONS); do $(MATHEMATICABIN) -noprompt -run "<<$<; Exit[]"; done >$@

benchmarks/lua.csv: perf.lua
	export BIT=64
	@for t in $(ITERATIONS); do ./lua/ulua/bin/scilua $<; done >$@

benchmarks/java.csv: java/src/main/java/PerfBLAS.java
	cd java
	sh setup.sh
	@for t in $(ITERATIONS); do mvn -q exec:java; done >../$@

benchmarks/scala.csv: scala/src/main/scala/perf.scala scala/build.sbt
	cd scala
	@for t in $(ITERATIONS); do sbt run; done >../$@

benchmarks/rust.csv: rust/src/main.rs rust/src/util.rs rust/Cargo.lock
	cd rust
	@for t in $(ITERATIONS); do cargo run --release -q; done >../$@

LANGUAGES = c fortran java javascript julia lua mathematica matlab octave python r rust
GH_ACTION_LANGUAGES = c fortran java javascript julia lua python r rust

# These were formerly listed in LANGUAGES, but I can't get them to run
# 2017-09-27 johnfgibson
#	scala

BENCHMARKS = $(foreach lang,$(LANGUAGES),benchmarks/$(lang).csv)
GH_ACTION_BENCHMARKS = $(foreach lang,$(GH_ACTION_LANGUAGES),benchmarks/$(lang).csv)

COLON_SEPARATED_GHA_LANGUAGES = $(shell echo $(GH_ACTION_LANGUAGES) | sed 's/ /:/g')

versions.csv: bin/versions.sh
	$^ >$@

gh_action_versions.csv: bin/versions.sh
	$^ $(COLON_SEPARATED_GHA_LANGUAGES) >$@

benchmarks.csv: bin/collect.jl $(BENCHMARKS)
	julia $^ >$@

gh_action_benchmarks.csv: bin/collect.jl $(GH_ACTION_BENCHMARKS)
	julia $^ >$@

benchmarks.html: bin/table.jl versions.csv benchmarks.csv
	julia $^ >$@

gh_action_benchmarks.html: bin/table.jl gh_action_versions.csv gh_action_benchmarks.csv
	julia $^ >$@

clean:
	@rm -rf bin/perf* bin/fperf* benchmarks/*.csv benchmarks.csv mods *~ octave-core perf.log gopath/*

.PHONY: all perf clean

.PRECIOUS: bin/perf0 bin/perf1 bin/perf2 bin/perf3
