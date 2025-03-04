-------------------------------------------------------------------------------
--	FILE:	 Ice_Age.lua
--	AUTHOR:  Bob Thomas (Sirian)
--	PURPOSE: Global map script - Simulates habitable region at the
--	         equator during severe glaciation of a random world.
-------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
-------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("TerrainGenerator");
include("FeatureGenerator");

-------------------------------------------------------------------------------
--[[
SIRIAN'S NOTES

Not much change to this script for Civ5. Large continents occur a bit more. In 
line with Jon's directives regarding terrain, hills and forests are handled a 
bit differently.

- Bob Thomas  March 22, 2010


Ice Age turned out to be a fun script. The extreme difference between the 
width and height pulls unusual results from the fractal generator: many 
wide, short landmasses that offer a unique map balance. Combined with the 
lower sea levels (lots of water from the oceans locked in the polar ice), 
this script offers a uniquely snaky and intertwining set of lands. The 
lands are also close to one another, allowing intense early naval activity.

This script can be particularly fun for team games!

- Bob Thomas  July 14, 2005
]]--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_MAP_ICE_AGE",
		Description = "TXT_KEY_MAP_ICE_AGE_HELP",
		IsAdvancedMap = false,
		IconIndex = 22,
		IconAtlas = "WORLDTYPE_ATLAS_3",
		CustomOptions = {world_age, temperature, rainfall, sea_level, resources,
			{
				Name = "TXT_KEY_MAP_OPTION_LANDMASS_TYPE",
				Values = {
					"TXT_KEY_MAP_OPTION_RANDOM",
					{"TXT_KEY_MAP_OPTION_WIDE_CONTINENTS", "TXT_KEY_MAP_WIDE_CONTINENTS_HELP"},
					{"TXT_KEY_MAP_OPTION_NARROW_CONTINENTS", "TXT_KEY_MAP_NARROW_CONTINENTS_HELP"},
					{"TXT_KEY_MAP_OPTION_ISLANDS", "TXT_KEY_MAP_ISLANDS_HELP"},
					{"TXT_KEY_MAP_OPTION_SMALL_ISLANDS", "TXT_KEY_MAP_SMALL_ISLANDS_HELP"},
				},
				DefaultValue = 1,
			},
		
		},
	}
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	--
	-- Ice Age simulates polar ice taking over more of the world, so we use a "flatter" grid.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {40, 16},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {52, 24},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {64, 28},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {84, 36},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {104, 44},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {128, 52}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
		return {
			Width = grid_size[1],
			Height = grid_size[2],
			WrapX = true
		};      
	end
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Ice Age) ...")

	local sea_level = Map.GetCustomOption(4)
	if sea_level == 4 then
		sea_level = 1 + Map.Rand(3, "Random Sea Level - Lua");
	end
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local userInputLandmass = Map.GetCustomOption(6)
	land_type = userInputLandmass - 1;
	local plotTypes = {};
	
	if userInputLandmass == 1 then -- Weighted Random
		-- Roll a D20 in case of random landmass size, to choose the option.
		-- 0-6 = wide continents
		-- 7-12 = narrow continents
		-- 13-17 = archipelago
		-- 18-19 = tiny islands
		local terrainRoll = Map.Rand(20, "PlotGen Chooser - Ice Age Lua");
		if terrainRoll < 7 then
			land_type = 1;
		elseif terrainRoll < 13 then
			land_type = 2;
		elseif terrainRoll < 18 then
			land_type = 3;
		else
			land_type = 4;
		end
	end

	-- Now implement the landmass type.
	if land_type == 2 then -- Narrow Continents
		local fractal_world = FractalWorld.Create();
		division_method = 2; -- NOTE: This variable is intended to be a global, do not make it local.

		fractal_world:InitFractal{
			continent_grain = 3};

		local args = {
			sea_level = sea_level,
			world_age = world_age,
			sea_level_low = 60,
			sea_level_normal = 65,
			sea_level_high = 72,
			tectonic_islands = true
			}
		plotTypes = fractal_world:GeneratePlotTypes(args);

	elseif land_type == 3 then -- Islands
		local fractal_world = FractalWorld.Create();
		division_method = 3; -- NOTE: This variable is intended to be a global, do not make it local.

		fractal_world:InitFractal{
			continent_grain = 4};

		local args = {
			sea_level = sea_level,
			world_age = world_age,
			sea_level_low = 61,
			sea_level_normal = 66,
			sea_level_high = 73,
			tectonic_islands = true
			}
		plotTypes = fractal_world:GeneratePlotTypes(args);

	elseif land_type == 4 then -- Tiny Islands
		local fractal_world = FractalWorld.Create();
		division_method = 3; -- NOTE: This variable is intended to be a global, do not make it local.

		fractal_world:InitFractal{
			continent_grain = 5};

		local args = {
			sea_level = sea_level,
			world_age = world_age,
			sea_level_low = 62,
			sea_level_normal = 67,
			sea_level_high = 74,
			tectonic_islands = true
			}
		plotTypes = fractal_world:GeneratePlotTypes(args);

	else -- Wide Continents, Large
		local fractal_world = FractalWorld.Create();
		local grain_dice = 1 + Map.Rand(2, "Continent Grain - Ice Age Lua");
		local rift_dice = Map.Rand(3, "Rift Grain - Ice Age Lua");
		local center_dice = Map.Rand(7, "Continent Grain - Ice Age Lua");
		if rift_dice == 0 then
			rift_dice = -1;
		end
		division_method = 2; -- NOTE: This variable is intended to be a global, do not make it local.
		
		if center_dice < 3 then
			fractal_world:InitFractal{
				continent_grain = 3,
				rift_grain = rift_dice,
				has_center_rift = true
				};
		else
			fractal_world:InitFractal{
				continent_grain = 3,
				rift_grain = rift_dice,
				has_center_rift = false
				};
		end
			
		local args = {
			sea_level = sea_level,
			world_age = world_age,
			sea_level_low = 59,
			sea_level_normal = 64,
			sea_level_high = 70,
			tectonic_islands = false
			}
		plotTypes = fractal_world:GeneratePlotTypes(args);

	end
	
	SetPlotTypes(plotTypes);
	GenerateCoasts()
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Ice_AgeTerrainGenerator = {};
-------------------------------------------------------------------------------
function Ice_AgeTerrainGenerator.Create(args)
	--[[ Civ4's truncated "Climate" setting has been abandoned. Civ5 has returned to 
	Civ3-style map options for World Age, Temperature, and Rainfall. Control over the 
	terrain has been removed from the XML.  - Bob Thomas, March 2010  ]]--
	--
	-- Sea Level and World Age map options affect only plot generation.
	-- Temperature map options affect only terrain generation.
	-- Rainfall map options affect only feature generation.
	--
	local args = args or {};
	local fracXExp = args.fracXExp or -1;
	local fracYExp = args.fracYExp or -1;
	local grain_amount = args.grain_amount or 3;
	
	-- Get Temperature setting input by user.
	local temperature = Map.GetCustomOption(2)
	if temperature == 4 then
		temperature = 1 + Map.Rand(3, "Random Temperature - Lua");
	end
	-- Set terrain bands.
	local iDesertPercent = args.iDesertPercent or 20;
	local iPlainsPercent = args.iPlainsPercent or 75; -- Deserts are processed first, so Plains will take this percentage of whatever remains.
	local fSnowLatitude  = args.fSnowLatitude  or 0.45;
	local fTundraLatitude = args.fTundraLatitude or 0.3;
	local fGrassLatitude = args.fGrassLatitude or 0.0; -- Above this is actually the latitude where it stops being all grass.
	local fDesertBottomLatitude = args.fDesertBottomLatitude or 0.1;
	local fDesertTopLatitude = args.fDesertTopLatitude or 0.2;
	-- Adjust terrain bands according to user's Temperature selection.
	if temperature == 1 then -- World Temperature is Cool.
		iDesertPercent = 10;
		fTundraLatitude = 0.15;
		fDesertTopLatitude = 0.15;
		fDesertBottomLatitude = 0.05;
	elseif temperature == 3 then -- World Temperature is Hot.
		iDesertPercent = 30;
		fSnowLatitude  = 0.5;
		fTundraLatitude = 0.4;
		fDesertTopLatitude = 0.35;
		fGrassLatitude = 0.05;
	else -- Normal Temperature.
	end

	local gridWidth, gridHeight = Map.GetGridSize();
	local world_info = GameInfo.Worlds[Map.GetWorldSize()];

	local data = {
	
		-- member methods
		InitFractals			= TerrainGenerator.InitFractals,
		GetLatitudeAtPlot		= TerrainGenerator.GetLatitudeAtPlot,
		GenerateTerrain			= TerrainGenerator.GenerateTerrain,
		GenerateTerrainAtPlot	= TerrainGenerator.GenerateTerrainAtPlot,
	
		-- member variables
		grain_amount	= grain_amount,
		fractalFlags	= Map.GetFractalFlags(), 
		iWidth			= gridWidth,
		iHeight			= gridHeight,
		
		iDesertPercent	= iDesertPercent,
		iPlainsPercent	= iPlainsPercent,

		iDesertTopPercent		= 100,
		iDesertBottomPercent	= math.max(0, math.floor(100-iDesertPercent)),
		iPlainsTopPercent		= 100,
		iPlainsBottomPercent	= math.max(0, math.floor(100-iPlainsPercent)),
		
		fSnowLatitude			= fSnowLatitude,
		fTundraLatitude			= fTundraLatitude,
		fGrassLatitude			= fGrassLatitude,
		fDesertBottomLatitude	= fDesertBottomLatitude,
		fDesertTopLatitude		= fDesertTopLatitude,
		
		fracXExp		= fracXExp,
		fracYExp		= fracYExp,
		
	}

	data:InitFractals();
	
	return data;
end
-------------------------------------------------------------------------------
function Ice_AgeTerrainGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = math.abs((self.iHeight / 2) - iY) / (self.iHeight / 2);
	lat = lat + (128 - self.variation:GetHeight(iX, iY))/(255.0 * 5.0);
	
	-- In order to increase the coverage of tundra latitude, had to increase the "power" of each 0.1 of latitudinal effect.
	lat = lat * 0.6;

	return lat;
end
-------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Ice Age) ...");
	
	local terraingen = Ice_AgeTerrainGenerator.Create();
	local terrainTypes = terraingen:GenerateTerrain()
		
	SetTerrainTypes(terrainTypes);
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Ice_AgeFeatureGenerator = {};
-------------------------------------------------------------------------------
function Ice_AgeFeatureGenerator.Create(args)
	-- Customizations for Ice Age include adding much more forest in tundra 
	-- regions, but reducing foliage elsewhere, and adding more random feature ice.
	local args = args or {};
	local jungle_grain = args.jungle_grain or 7;
	local forest_grain = args.forest_grain or 6;
	local clump_grain = args.clump_grain or 3;
	local iFoliageChange = args.iFoliageChange or 10;
	local iClumpChange = args.iClumpChange or 5;
	local iJungleFactor = args.iJungleFactor or 5;
	local iAridFactor = args.iAridFactor or 5;
	local iWetFactor = args.iWetFactor or 5;
	local fMarshChange = args.fMarshChange or 1.5;
	local fOasisChange = args.fOasisChange or 1.5;
	local fracXExp = args.fracXExp or -1;
	local fracYExp = args.fracYExp or -1;
	
	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	-- Set feature traits.
	local iJunglePercent = args.iJunglePercent or 30;
	local iForestPercent = args.iForestPercent or 28;
	--
	local iTundraPercent = 70;
	--
	local iClumpHeight = args.iClumpHeight or 93;
	local fMarshPercent = args.fMarshPercent or 20;
	local iOasisPercent = args.iOasisPercent or 6;
	-- Adjust terrain bands according to user's Temperature selection.
	if rain == 1 then -- Rainfall is sparse, climate is Arid.
		iJunglePercent = iJunglePercent - iFoliageChange;
		iJungleFactor = iAridFactor;
		iForestPercent = iForestPercent - iFoliageChange;
		--
		iTundraPercent = iTundraPercent - iFoliageChange;
		--
		iClumpHeight = iClumpHeight - iClumpChange;
		fMarshPercent = fMarshPercent / fMarshChange;
		iOasisPercent = iOasisPercent / fOasisChange;
	elseif rain == 3 then -- Rainfall is abundant, climate is Wet.
		iJunglePercent = iJunglePercent + iFoliageChange;
		iJungleFactor = iWetFactor;
		iForestPercent = iForestPercent + iFoliageChange;
		--
		iTundraPercent = iTundraPercent + iFoliageChange;
		--
		iClumpHeight = iClumpHeight + iClumpChange;
		fMarshPercent = fMarshPercent * fMarshChange;
		iOasisPercent = iOasisPercent * fOasisChange;
	else -- Rainfall is Normal.
	end

	local gridWidth, gridHeight = Map.GetGridSize();
	local world_info = GameInfo.Worlds[Map.GetWorldSize()];
	jungle_grain = jungle_grain + world_info.FeatureGrainChange;
	forest_grain = forest_grain + world_info.FeatureGrainChange;

	-- create instance data
	local instance = {
	
		-- methods
		__initFractals		= Ice_AgeFeatureGenerator.__initFractals,
		__initFeatureTypes	= FeatureGenerator.__initFeatureTypes,
		AddFeatures			= FeatureGenerator.AddFeatures,
		GetLatitudeAtPlot	= Ice_AgeFeatureGenerator.GetLatitudeAtPlot,
		AddFeaturesAtPlot	= FeatureGenerator.AddFeaturesAtPlot,
		AddOasisAtPlot		= FeatureGenerator.AddOasisAtPlot,
		AddIceAtPlot		= Ice_AgeFeatureGenerator.AddIceAtPlot,
		AddMarshAtPlot		= FeatureGenerator.AddMarshAtPlot,
		AddJunglesAtPlot	= FeatureGenerator.AddJunglesAtPlot,
		AddForestsAtPlot	= Ice_AgeFeatureGenerator.AddForestsAtPlot,
		AddAtolls			= FeatureGenerator.AddAtolls,
		AdjustTerrainTypes	= FeatureGenerator.AdjustTerrainTypes,
		
		-- members
		iGridW = gridWidth,
		iGridH = gridHeight,
		
		iJunglePercent = iJunglePercent,
		iJungleFactor = iJungleFactor,
		iForestPercent = iForestPercent,
		--
		iTundraPercent = iTundraPercent,
		--
		iClumpHeight = iClumpHeight,
		fMarshPercent = fMarshPercent,
		iOasisPercent = iOasisPercent,
	
		jungle_grain = jungle_grain,
		forest_grain = forest_grain,
		clump_grain = clump_grain,
		
		fractalFlags = Map.GetFractalFlags(),
		fracXExp = fracXExp,
		fracYExp = fracYExp,
	};

	-- initialize instance data
	instance:__initFractals()
	instance:__initFeatureTypes()
	
	return instance;
end
-------------------------------------------------------------------------------
function Ice_AgeFeatureGenerator:__initFractals()
	local width = self.iGridW;
	local height = self.iGridH;
	
	-- Create fractals
	self.jungles		= Fractal.Create(width, height, self.jungle_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forests		= Fractal.Create(width, height, self.forest_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forestclumps	= Fractal.Create(width, height, self.clump_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.marsh			= Fractal.Create(width, height, 4, self.fractalFlags, self.fracXExp, self.fracYExp);
	
	-- Get heights
	self.iJungleBottom	= self.jungles:GetHeight((100 - self.iJunglePercent)/2)
	self.iJungleTop		= self.jungles:GetHeight((100 + self.iJunglePercent)/2)
	self.iJungleRange	= (self.iJungleTop - self.iJungleBottom) * self.iJungleFactor;
	self.iTundraLevel	= self.forests:GetHeight(100 - self.iTundraPercent)
	self.iForestLevel	= self.forests:GetHeight(100 - self.iForestPercent)
	self.iClumpLevel	= self.forestclumps:GetHeight(self.iClumpHeight)
	self.iMarshLevel	= self.marsh:GetHeight(100 - self.fMarshPercent)
end
------------------------------------------------------------------------------
function Ice_AgeFeatureGenerator:GetLatitudeAtPlot(iX, iY)
	-- 0.0 (tropical) to 0.6 (polar) - Customized for Ice Age.
	return (math.abs((self.iGridH/2) - iY)/(self.iGridH/2)) * 0.6;
end
-------------------------------------------------------------------------------
function Ice_AgeFeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	if(plot:CanHaveFeature(self.featureIce)) then
	
		if iY == 0 or iY == self.iGridH - 1 then
			plot:SetFeatureType(self.featureIce, -1)

		elseif lat > 0.47 then
			local rand = Map.Rand(100, "Add Ice Lua") / 100;
			if rand < 8 * (lat - 0.50) then
				plot:SetFeatureType(self.featureIce, -1)
			elseif rand < 4 * (lat - 0.46) then
				plot:SetFeatureType(self.featureIce, -1)
			end
			
		-- Add encroaching icebergs reaching out beyond normal range
		elseif lat > 0.39 then
			local rand = Map.Rand(100, "Add Encroaching Ice - Sirian's Ice Age - Lua") / 100;
			if rand < 0.06 then
				plot:SetFeatureType(self.featureIce, -1)
			end
		elseif lat > 0.32 then
			local rand = Map.Rand(100, "Add Encroaching Ice - Sirian's Ice Age - Lua") / 100;
			if rand < 0.04 then
				plot:SetFeatureType(self.featureIce, -1)
			end
		elseif lat > 0.27 then
			local rand = Map.Rand(100, "Add Encroaching Ice - Sirian's Ice Age - Lua") / 100;
			if rand < 0.02 then
				plot:SetFeatureType(self.featureIce, -1)
			end
		end
	end
end
------------------------------------------------------------------------------
function Ice_AgeFeatureGenerator:AddForestsAtPlot(plot, iX, iY, lat)
	local terrainType = plot:GetTerrainType()
	if terrainType == TerrainTypes.TERRAIN_TUNDRA then
		if (self.forests:GetHeight(iX, iY) >= self.iTundraLevel) or (self.forestclumps:GetHeight(iX, iY) >= self.iClumpLevel) then
			if plot:CanHaveFeature(self.featureForest) then
				plot:SetFeatureType(self.featureForest, -1)
			end
		end
	else
		if (self.forests:GetHeight(iX, iY) >= self.iForestLevel) or (self.forestclumps:GetHeight(iX, iY) >= self.iClumpLevel) then
			if plot:CanHaveFeature(self.featureForest) then
				plot:SetFeatureType(self.featureForest, -1)
			end
		end
	end
end
-------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Ice Age) ...");

	local featuregen = Ice_AgeFeatureGenerator.Create();

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
	-- Regional Division Method depends on landmass type selected.
	local args = {
		method = division_method,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	-- Forcing starts along the ocean.
	local args = {mustBeCoast = true};
	start_plot_database:ChooseLocations(args)
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders.");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()

	if land_type >= 2 then
		-- tell the AI that we should treat this as a naval expansion map
		Map.ChangeAIMapHint(1);
	end

end
------------------------------------------------------------------------------
