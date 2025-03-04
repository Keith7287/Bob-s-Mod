------------------------------------------------------------------------------
--	FILE:	 Archipelago.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Global map script - Produces a world full of islands.
--           This is one of Civ5's featured map scripts.
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
		Name = "TXT_KEY_MAP_ARCHIPELAGO",
		Description = "TXT_KEY_MAP_ARCHIPELAGO_HELP",
		IsAdvancedMap = false,
		IconIndex = 2,
		SortIndex = 3,
		CustomOptions = {world_age, temperature, rainfall, sea_level, resources},
	}
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types (Lua Archipelago) ...");

	-- Fetch Sea Level and World Age user selections.
	local sea = Map.GetCustomOption(4)
	if sea == 4 then
		sea = 1 + Map.Rand(3, "Random Sea Level - Lua");
	end
	local age = Map.GetCustomOption(1)
	if age == 4 then
		age = 1 + Map.Rand(3, "Random World Age - Lua");
	end

	local fractal_world = FractalWorld.Create();
	fractal_world:InitFractal{
		continent_grain = 4};

	local args = {
		sea_level = sea,
		world_age = age,
		sea_level_low = 72,
		sea_level_normal = 78,
		sea_level_high = 83,
		extra_mountains = 10,
		adjust_plates = 2,
		tectonic_islands = true
		}
	local plotTypes = fractal_world:GeneratePlotTypes(args);
	
	SetPlotTypes(plotTypes);

	local args = {expansion_diceroll_table = {10, 4, 4}};
	GenerateCoasts(args);
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Archipelago) ...");
	
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
	print("Adding Features (Lua Archipelago) ...");

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
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(5)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database (MapGenerator.Lua)");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions (Lua Archipelago)");
	-- Regional Division Method 3: Rectangular Division
	local args = {
		method = 3,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations (Lua Archipelago)");
	-- Forcing starts along the ocean.
	-- Lowering start position minimum eligibility thresholds.
	local args = {
	mustBeCoast = true,
	minFoodMiddle = 2,
	minFoodOuter = 3,
	minProdOuter = 1
	};
	start_plot_database:ChooseLocations(args)
	
	print("Normalizing start locations and assigning them to Players (MapGenerator.Lua)");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders (MapGenerator.Lua)");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States (MapGenerator.Lua)");
	start_plot_database:PlaceResourcesAndCityStates()
	
	-- tell the AI that we should treat this as a naval expansion map
	Map.ChangeAIMapHint(1+4);

end
------------------------------------------------------------------------------
