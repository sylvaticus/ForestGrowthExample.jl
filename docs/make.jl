using Documenter, Literate, ForestGrowthExample

ENV["GKSwstype"] = "100" # headless plotting on CI

# Convert the Literate script in a markdown page (executed later by Documenter)
Literate.markdown(joinpath(@__DIR__, "lit", "tutorial.jl"), joinpath(@__DIR__, "src"); documenter = true)

makedocs(
    sitename = "ForestGrowthExample.jl",
    modules  = [ForestGrowthExample],
    pages    = ["Home" => "index.md", "Tutorial" => "tutorial.md", "API" => "api.md"],
)

deploydocs(repo = "github.com/sylvaticus/ForestGrowthExample.jl.git", devbranch = "main")
