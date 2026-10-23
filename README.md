# ForestGrowthExample.jl

[![CI](https://github.com/sylvaticus/ForestGrowthExample.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/sylvaticus/ForestGrowthExample.jl/actions/workflows/CI.yml)
[![Docs stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://sylvaticus.github.io/ForestGrowthExample.jl/stable)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://sylvaticus.github.io/ForestGrowthExample.jl/dev)

> [!WARNING]
> This is a toy package, written only to show students how to turn a script into a Julia package.
> It is not registered, not maintained and not meant for real analyses: the growth model is deliberately simplistic.

A minimal, teaching-oriented Julia package that fits a logistic growth model of forest stand volumes against their age, using the French National Forest Inventory data.

```julia
using ForestGrowthExample
data = load_data()                        # urls or local files of the inventory data
estimate_plot_growth(data)                # (max_growth, growth_rate, mid_age) for all species
estimate_plot_growth(data, "HETRE")       # ...or for a single species
```
