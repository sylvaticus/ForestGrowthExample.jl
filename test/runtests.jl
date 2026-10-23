using Test, ForestGrowthExample

# Small subset of the inventory data (300 points), to test offline and fast
datadir = joinpath(@__DIR__, "data")
data    = load_data(tree_data      = joinpath(datadir, "trees.csv"),
                    dead_tree_data = joinpath(datadir, "dead_trees.csv"),
                    point_data     = joinpath(datadir, "points.csv"),
                    doc_data       = joinpath(datadir, "doc.csv"))

@testset "vHaContribution" begin
    @test ForestGrowthExample.vHaContribution(1.0, 50.0)  ≈ 1 / (6^2  * pi / 10000)
    @test ForestGrowthExample.vHaContribution(1.0, 100.0) ≈ 1 / (9^2  * pi / 10000)
    @test ForestGrowthExample.vHaContribution(1.0, 200.0) ≈ 1 / (15^2 * pi / 10000)
end

@testset "load_data" begin
    @test size(data) == (223, 6)
    @test all(data.ntrees .> 5)
    point = data[data.idp .== 700017, :]
    @test point.cac[1] == 37.5
    @test point.vHa[1] ≈ 34.5425 atol = 1e-4
    @test point.spLabel[1] == "CHENE ROUVRE"
end

@testset "estimate_plot_growth" begin
    pars = estimate_plot_growth(data)
    @test keys(pars) == (:max_growth, :growth_rate, :mid_age)
    @test collect(pars) ≈ [275.36, 0.0673, 29.32] rtol = 0.01
    @test estimate_plot_growth(data, "HETRE") != pars
    @test_throws ErrorException estimate_plot_growth(data, "BAOBAB")
end
