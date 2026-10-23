"""
    ForestGrowthExample

A minimal example package to fit a logistic growth model of forest stand volumes
from the French National Forest Inventory data.

$(EXPORTS)
"""
module ForestGrowthExample

using DocStringExtensions, HTTP, CSV, DataFrames, LsqFit

export load_data, estimate_plot_growth

const ltURL     = "https://bit.ly/apress_julia_alive_trees"
const dtURL     = "https://bit.ly/apress_julia_dead_trees"
const pointsURL = "https://bit.ly/apress_julia_inv_points"
const docURL    = "https://bit.ly/apress_julia_inv_doc"

"Read a CSV file in a DataFrame, either from a url or a local path."
read_csv(source) = startswith(source, r"https?://") ? CSV.read(HTTP.get(source).body, DataFrame) : CSV.read(source, DataFrame)

"""
$(TYPEDSIGNATURES)

Return the contribution in terms of m³/ha of the tree.

The French inventory system is based on a concentric sample method: small trees are sampled on a small area (6 metres radius), intermediate trees on a concentric area of 9 metres and only large trees (with a circonference larger than 117.5 cm) are sampled on a concentric area of 15 metres of radius.
This function normalise the contribution of each tree to m³/ha.
"""
function vHaContribution(v::Real, c13::Real)
    if c13 < 70.5
        return v/(6^2*pi/(100*100))
    elseif c13 < 117.5
        return v/(9^2*pi/(100*100))
    else
        return v/(15^2*pi/(100*100))
    end
end

"Logistic growth model, with parameters (max growth, growth rate, mid age)."
logisticModel(age, parameters) = parameters[1]/(1+exp(-parameters[2] * (age-parameters[3]) ))
logisticModelVec(age, parameters) = logisticModel.(age, Ref(parameters))

"""
$(TYPEDSIGNATURES)

Load the French National Forest Inventory data and return a DataFrame of the inventory points with
their timber volume per hectare (`vHa`), number of trees (`ntrees`), age class (`cac`, in years),
main species code (`esspre`) and label (`spLabel`).

Each argument can be either a url or a local file path, and defaults to the data used in the course.

# Example
```jldoctest
julia> using ForestGrowthExample

julia> data = load_data();

julia> size(data)
(5390, 6)

julia> names(data)
6-element Vector{String}:
 "idp"
 "esspre"
 "cac"
 "vHa"
 "ntrees"
 "spLabel"
```
"""
function load_data(; tree_data = ltURL, dead_tree_data = dtURL, point_data = pointsURL, doc_data = docURL)
    # 3) Load the data
    lt     = read_csv(tree_data)
    dt     = read_csv(dead_tree_data)
    points = read_csv(point_data)
    doc    = read_csv(doc_data)

    # 4) Filter out unused information
    lt     = lt[:,["idp","c13","v"]]
    dt     = dt[:,["idp","c13","v"]]
    trees  = vcat(lt,dt)
    points = points[:,["idp","esspre","cac"]]

    # 5) Compute the timber volumes per hectare
    trees.vHa  = vHaContribution.(trees.v,trees.c13)

    # 6) Aggregate trees data
    pointsVols = combine(groupby(trees,["idp"]) ,  "vHa" => sum => "vHa", nrow => "ntrees")

    # 7) Join datasets
    points     = innerjoin(points,pointsVols,on="idp")

    # 8) Filter data
    filter_nTrees           = points.ntrees .> 5 # we skip points with few trees
    filter_IHaveAgeClass    = .! in.(points.cac,Ref(["AA","NR"]))
    filter_IHaveMainSpecies = .! ismissing.(points.esspre)
    filter_overall          = filter_nTrees .&& filter_IHaveAgeClass .&& filter_IHaveMainSpecies
    points                  = points[filter_overall,:]

    # 9) Compute the age class
    points.cac              = (parse.(Int64,points.cac) .- 1 ) .* 5 .+ 2.5

    # Add the species label
    spLabel        = doc[doc.donnee .== "ESSPRE",:]
    spLabel.esspre = parse.(Int64,spLabel.code)
    points         = leftjoin(points,spLabel[:,["esspre","libelle"]], on="esspre")
    rename!(points, "libelle" => "spLabel")
    return points
end

"""
$(TYPEDSIGNATURES)

Fit a logistic growth model of the volumes per hectare against the age of the inventory points in `data`
(as returned by [`load_data`](@ref)) and return the tuple `(max_growth, growth_rate, mid_age)`.

The fit is done on the points of the given `specie` label (e.g. `"HETRE"`), or on all points if `specie` is empty.

# Example
```jldoctest
julia> using ForestGrowthExample

julia> data = load_data();

julia> pars =estimate_plot_growth(data, "HETRE");

julia> map(x -> round(x, digits = 2), pars)
(max_growth = 315.12, growth_rate = 0.07, mid_age = 42.6)
```
"""
function estimate_plot_growth(data::AbstractDataFrame, specie::AbstractString = "")
    pointsSp = specie == "" ? data : data[isequal.(data.spLabel, specie), :]
    nrow(pointsSp) == 0 && error("No data for specie \"$specie\"")
    initialParameters = [1000,0.05,50] #max growth; growth rate, mid age
    fitobject = curve_fit(logisticModelVec, pointsSp.cac, pointsSp.vHa, initialParameters)
    return (max_growth = fitobject.param[1], growth_rate = fitobject.param[2], mid_age = fitobject.param[3])
end

end # module ForestGrowthExample
