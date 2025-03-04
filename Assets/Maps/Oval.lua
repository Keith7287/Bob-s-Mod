------------------------------------------------------------------------------
--	FILE:	 Oval.lua
--	AUTHOR:  Bob Thomas (based on a concept by Brian Wade)
--	PURPOSE: Global map script - Creates an oval-shaped Pangaea.
------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("FeatureGenerator");
include("TerrainGenerator");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_MAP_OVAL",
		Description = "TXT_KEY_MAP_OVAL_HELP",
		IsAdvancedMap = false,
		IconIndex = 15,
		SortIndex = 2,
		CustomOptions = {world_age, temperature, rainfall, sea_level, resources},
	}
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	--
	-- Oval has predictable land scope, like Civ4's Pangaea did, so use grid sizes one level below normal to reduce ocean coverage.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {32, 20},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {40, 24},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {52, 32},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {64, 40},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {84, 52},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {104, 64}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
	return {
		Width = grid_size[1],
		Height = grid_size[2],
		WrapX = true,
	};      
     end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- This implementation is specific to Oval.
	local iW, iH = Map.GetGridSize();
	local fracFlags = {FRAC_POLAR = true};

	local sea_level = Map.GetCustomOption(4)
	if sea_level == 4 then
		sea_level = 1 + Map.Rand(3, "Random Sea Level - Lua");
	end
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local axis_list = {0.87, 0.81, 0.75};
	local axis_multiplier = axis_list[sea_level];
	local cohesion_list = {0.41, 0.38, 0.35};
	local cohesion_multiplier = cohesion_list[sea_level];

	-- Fill all rows with water plots.
	self.wholeworldPlotTypes = table.fill(PlotTypes.PLOT_OCEAN, iW * iH);

	-- Add the main oval as land plots.
	local centerX = iW / 2;
	local centerY = iH / 2;
	local majorAxis = centerX * axis_multiplier;
	local minorAxis = centerY * axis_multiplier;
	local majorAxisSquared = majorAxis * majorAxis;
	local minorAxisSquared = minorAxis * minorAxis;
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local deltaX = x - centerX;
			local deltaY = y - centerY;
			local deltaXSquared = deltaX * deltaX;
			local deltaYSquared = deltaY * deltaY;
			local d = deltaXSquared/majorAxisSquared + deltaYSquared/minorAxisSquared;
			if d <= 1 then
				local i = y * iW + x + 1;
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
			end
		end
	end
	
	-- Now add bays, fjords, inland seas, etc, but not inside the cohesion area.
	local baysFrac = Fractal.Create(iW, iH, 3, fracFlags, -1, -1);
	local iBaysThreshold = baysFrac:GetHeight(82);
	local centerX = iW / 2;
	local centerY = iH / 2;
	local majorAxis = centerX * cohesion_multiplier;
	local minorAxis = centerY * cohesion_multiplier;
	local majorAxisSquared = majorAxis * majorAxis;
	local minorAxisSquared = minorAxis * minorAxis;
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local deltaX = x - centerX;
			local deltaY = y - centerY;
			local deltaXSquared = deltaX * deltaX;
			local deltaYSquared = deltaY * deltaY;
			local d = deltaXSquared/majorAxisSquared + deltaYSquared/minorAxisSquared;
			if d > 1 then
				local i = y * iW + x + 1;
				local baysVal = baysFrac:GetHeight(x, y);
				if baysVal >= iBaysThreshold then
					self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
				end
			end
		end
	end

	-- Land and water are set. Now apply hills and mountains.
	local args = {
		adjust_plates = 1.5,
		world_age = world_age,
	};
	self:ApplyTectonics(args)

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Oval) ...");

	local layered_world = MultilayeredFractal.Create();
	local plot_list = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(plot_list);

	local args = {bExpandCoasts = false};
	GenerateCoasts(args);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GenerateTerrain()
	print("Adding Terrain (Lua Oval) ...");
	
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
	print("Adding Features (Lua Oval) ...");

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

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = 1,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders.");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------
