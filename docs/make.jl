using Documenter, DataFrames, CSV, StatsBase, Gadfly

function makeplot(benchfile::String)
    # Load benchmark data from file
    benchmarks = CSV.read(benchfile, DataFrame; header=["language", "benchmark", "time"])

    # Capitalize and decorate language names from datafile
    dict = Dict("c"=>"C", "julia"=>"Julia", "lua"=>"LuaJIT", "fortran"=>"Fortran", "java"=>"Java",
                "javascript"=>"JavaScript", "matlab"=>"Matlab", "mathematica"=>"Mathematica",
                "python"=>"Python", "octave"=>"Octave", "r"=>"R", "rust"=>"Rust", "go"=>"Go");
    benchmarks[!,:language] = [dict[lang] for lang in benchmarks[!,:language]]

    # Normalize benchmark times by C times
    ctime = benchmarks[benchmarks[!,:language] .== "C", :]
    benchmarks = innerjoin(benchmarks, ctime, on=:benchmark, makeunique=true)
    select!(benchmarks, Not([:language_1]))
    rename!(benchmarks, :time_1 =>:ctime)
    benchmarks[!,:normtime] = benchmarks[!,:time] ./ benchmarks[!,:ctime];

    # Compute the geometric mean for each language
    langs = [];
    means = [];
    priorities = [];
    for lang in unique(benchmarks[!,:language])
        data = benchmarks[benchmarks[!,:language].== lang, :]
        gmean = geomean(data[!,:normtime])
        push!(langs, lang)
        push!(means, gmean)
        if (lang == "C")
            push!(priorities, 1)
        elseif (lang == "Julia")
            push!(priorities, 2)
        else
            push!(priorities, 3)
        end
    end

    # Add the geometric means back into the benchmarks dataframe
    langmean = DataFrame(language=langs, geomean = means, priority = priorities)
    benchmarks = innerjoin(benchmarks, langmean, on=:language)

    # Put C first, Julia second, and sort the rest by geometric mean
    sort!(benchmarks, [:priority, :geomean]);
    sort!(langmean,   [:priority, :geomean]);

    p = plot(benchmarks,
             x = :language,
             y = :normtime,
             color = :benchmark,
             Scale.y_log10,
             Guide.ylabel(nothing),
             Guide.xlabel(nothing),
             Coord.Cartesian(ymin=-0.5),
             Theme(
                 guide_title_position = :left,
                 colorkey_swatch_shape = :circle,
                 minor_label_font = "Georgia",
                 major_label_font = "Georgia"
             ),
             )

    golden = MathConstants.golden
    draw(SVG("docs/src/benchmarks.svg", 10inch, 10inch/golden), p)
end

makeplot("gh_action_benchmarks.csv")

makedocs(
    format = Documenter.HTML(),
    sitename = "Julia Microbenchmarks",
    pages = [
        "Microbenchmarks" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/JuliaLang/Microbenchmarks.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    push_preview = true,
)
