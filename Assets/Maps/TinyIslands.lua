------------------------------------------------------------------------------
--	FILE:	 Tiny_Islands.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Global map script - Produces a world full of tiny islands.
------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("FeatureGenerator");
include("TerrainGenerator");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_MAP_TINY_ISLANDS",
		Description = "TXT_KEY_MAP_TINY_ISLANDS_HELP",
		IsAdvancedMap = false,
		IconIndex = 17,
		CustomOptions = {world_age, temperature, rainfall, sea_level},
	}
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types (Lua Tiny Islands) ...");

	local sea_level = Map.GetCustomOption(4)
	if sea_level == 4 then
		sea_level = 1 + Map.Rand(3, "Random Sea Level - Lua");
	end
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end

	local fractal_world = FractalWorld.Create();
	fractal_world:InitFractal{continent_grain = 5};

	local args = {
		sea_level = sea_level,
		world_age = world_age,
		sea_level_low = 73,
		sea_level_normal = 78,
		sea_level_high = 82,
		extra_mountains = 15,
		adjust_plates = 2.5,
		tectonic_islands = true
		}
	local plotTypes = fractal_world:GeneratePlotTypes(args);
	
	SetPlotTypes(plotTypes);
	
	local args = {expansion_diceroll_table = {10, 4, 4}};
	GenerateCoasts(args);
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Tiny Islands) ...");
	
	-- Get Temperature setting input by user.
	local temp = Map.GetCustomOption(2)
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local args = {temperature = temp};
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Tiny Islands) ...");

	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rain}
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(false);
end
------------------------------------------------------------------------------
function StartPlotSystem()
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 3: Rectangular Division
	local args = {method = 3};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	-- Forcing starts along the ocean.
	-- Lowering start position minimum eligibility thresholds.
	local args = {
	mustBeCoast = true,
	minFoodMiddle = 2,
	minProdMiddle = 1,
	minFoodOuter = 2,
	minProdOuter = 1
	};
	start_plot_database:ChooseLocations(args)
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders.");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
	
	-- tell the AI that we should treat this as a naval + offshore expansion map
	Map.ChangeAIMapHint(1+4);

end
------------------------------------------------------------------------------
