------------------------------------------------------------------------------
--	FILE:	 WB_Script_Random_South_America.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Hybrid script - Random generation for South America.
------------------------------------------------------------------------------
--	Copyright (c) 2013 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("FeatureGenerator");
include("TerrainGenerator");

------------------------------------------------------------------------------
function MultilayeredFractal.Create()
	local iW, iH = Map.GetGridSize();
	-- Set up flags for the fractal generator. These are no longer bit values.
	-- For Lua, we had to convert to a table of booleans to simulate bits.
	local iNoFlags = {};
	local iTerrainFlags = Map.GetFractalFlags(); -- Matches wrap to that of the map.
	iTerrainFlags.FRAC_POLAR = false;
	local iRoundFlags = {};
	local iHorzFlags = {
		FRAC_WRAP_X = true,
	};
	local iVertFlags = {
		FRAC_WRAP_Y = true,
	};
	local iXYFlags = {
		FRAC_WRAP_X = true,
		FRAC_WRAP_Y = true,
	};
	
	-- Current region, reinitiated in GeneratePlotsByRegion for each layer.
	local plotTypes = {};

	-- CUSTOMIZED FOR READING WB MAPS: obtain the existing plot types from the WB. -- Sirian, Summer 2013
	local wholeworldPlotTypes = {};
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			-- Read this plot's type from the WB.
			local plot = Map.GetPlot(x, y);
			-- Record the data in the standard Multilayered Fractal plot table.
			local i = y * iW + x + 1; -- Lua Plot indices, starting at 1.
			wholeworldPlotTypes[i] = plot:GetPlotType();
		end
	end

	-- Create data.
	local data = {
	
		-- member variables
		iW				= iW,
		iH				= iH,
		iTerrainFlags	= iTerrainFlags,
		iNoFlags		= iNoFlags,
		iRoundFlags		= iRoundFlags,
		iHorzFlags		= iHorzFlags,
		iVertFlags		= iVertFlags,
		iXYFlags		= iXYFlags,
		
		-- plot arrays
		plotTypes		= plotTypes,
		wholeworldPlotTypes = wholeworldPlotTypes,		
	}
	
	setmetatable(data, {__index = MultilayeredFractal});

	return data;
end
-------------------------------------------------------------------------------------------
function MultilayeredFractal:ApplyTectonics(args)
	local args = args or {};
	local world_age = args.world_age or 2; -- Default to 4 Billion Years old.
	--
	local world_age_old = args.world_age_old or 2;
	local world_age_normal = args.world_age_normal or 3;
	local world_age_new = args.world_age_new or 5;
	--
	local extra_mountains = args.extra_mountains or 0;
	local grain_amount = args.grain_amount or 3;
	local adjust_plates = args.adjust_plates or 1.0;
	local shift_plot_types = args.shift_plot_types or false; -- Default to false for tectonics pass. Land/sea already generated.
	local tectonic_islands = args.tectonic_islands or false;
	local hills_ridge_flags = args.hills_ridge_flags or self.iTerrainFlags;
	local peaks_ridge_flags = args.peaks_ridge_flags or self.iTerrainFlags;
	local fracXExp = args.fracXExp or -1;
	local fracYExp = args.fracYExp or -1;
	
	-- Need to implement the new WorldAge startup options
	--
	-- Set values for hills and mountains according to World Age chosen by user.
	local adjustment = world_age_normal;
	if world_age == 3 then -- 5 Billion Years
		adjustment = world_age_old;
		adjust_plates = adjust_plates * 0.75;
	elseif world_age == 1 then -- 3 Billion Years
		adjustment = world_age_new;
		adjust_plates = adjust_plates * 1.5;
	else -- 4 Billion Years
	end
	-- Apply adjustment to hills and peaks settings.
	local hillsBottom1 = 28 - adjustment;
	local hillsTop1 = 28 + adjustment;
	local hillsBottom2 = 72 - adjustment;
	local hillsTop2 = 72 + adjustment;
	local hillsClumps = 1 + adjustment;
	local hillsNearMountains = 86;
	local mountains = 92;

	local grain = 3;

	-- Generate fractals to govern hills and mountains
	self.hillsFrac = Fractal.Create(self.iW, self.iH, grain_amount, self.iTerrainFlags, fracXExp, fracYExp);
	self.mountainsFrac = Fractal.Create(self.iW, self.iH, grain_amount, self.iTerrainFlags, fracXExp, fracYExp);

	-- Use Brian's tectonics method to weave ridgelines in to the fractals.
	self.hillsFrac:BuildRidges(12, hills_ridge_flags, 1, 2);
	self.mountainsFrac:BuildRidges(5, peaks_ridge_flags, 6, 1);

	-- Get height values for plot types
	local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
	local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
	local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
	local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
	local iHillsClumps = self.mountainsFrac:GetHeight(hillsClumps);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
	local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
	local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);

	-- Main loop
	for x = 0, self.iW - 1 do
		for y = 0, self.iH - 1 do
		
			local i = y * self.iW + x + 1;
	
			if self.wholeworldPlotTypes[i] == PlotTypes.PLOT_OCEAN then
				-- No hills or mountains here, but check for tectonic islands if that setting is active.
				if tectonic_islands then -- Build islands in oceans along tectonic ridge lines
					local mountainVal = self.mountainsFrac:GetHeight(x, y);
					if (mountainVal == iMountain100) then -- Isolated peak in the ocean
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					elseif (mountainVal == iMountain99) then
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
					elseif (mountainVal == iMountain97) or (mountainVal == iMountain95) then
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
					end
				end
					
			else
				local mountainVal = self.mountainsFrac:GetHeight(x, y);
				local hillVal = self.hillsFrac:GetHeight(x, y);
				if (mountainVal >= iMountainThreshold) then
					if (hillVal >= iPassThreshold) then -- Mountain Pass though the ridgeline
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
					else -- Mountain
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					end
				elseif (mountainVal >= iHillsNearMountains) then
					self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS; -- Foot hills
				else
					if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
					else
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
					end
				end
			end
		end
	end
end
-------------------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Applies random flat, hills and mountains to existing landforms.

	local iW, iH = Map.GetGridSize();
	local args = {};

	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 40,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 80,
	};
	local peaks_target = worldsizes[Map.GetWorldSize()] or 40;

	for loop = 1, 10 do
		self:ApplyTectonics(args)
		print("Mountains generation, Pass #", loop);
		local hills_count, peaks_count = 0, 0;
		for i = 1, iW * iH do
			if self.wholeworldPlotTypes[i] == PlotTypes.PLOT_MOUNTAIN then
				peaks_count = peaks_count + 1;
			elseif self.wholeworldPlotTypes[i] == PlotTypes.PLOT_HILLS then
				hills_count = hills_count + 1;
			end
		end
		print("Mountains count: ", peaks_count);
		print("Hills count: ", hills_count);
		print("-");
		if peaks_count > peaks_target then
			break
		end
	end

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua WB Script) ...");

	local layered_world = MultilayeredFractal.Create();
	local elevations_randomized = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(elevations_randomized);
	--GenerateCoasts()
	
end
------------------------------------------------------------------------------
function TerrainGenerator:GetLatitudeAtPlot(iX, iY)
	return 0.3;
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua WB Script) ...");
	
	local args = {iDesertPercent = 8,
	              iPlainsPercent = 48};
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FeatureGenerator:__initFractals()
	local width = self.iGridW;
	local height = self.iGridH;
	
	-- Create fractals
	self.jungles		= Fractal.Create(width, height, self.jungle_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forests		= Fractal.Create(width, height, self.forest_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forestclumps	= Fractal.Create(width, height, self.clump_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.marsh			= Fractal.Create(width, height, 4, self.fractalFlags, self.fracXExp, self.fracYExp);

	self.variation		= Fractal.Create(self.iGridW, self.iGridH, 
									3, self.fractalFlags, 
									self.fracXExp, self.fracYExp);
	
	-- Get heights
	self.iJungleBottom	= self.jungles:GetHeight((100 - self.iJunglePercent)/2)
	self.iJungleTop		= self.jungles:GetHeight((100 + self.iJunglePercent)/2)
	self.iJungleRange	= (self.iJungleTop - self.iJungleBottom) * self.iJungleFactor;
	self.iForestLevel	= self.forests:GetHeight(100 - self.iForestPercent)
	self.iClumpLevel	= self.forestclumps:GetHeight(self.iClumpHeight)
	self.iMarshLevel	= self.marsh:GetHeight(100 - self.fMarshPercent)
end
------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = iY / self.iGridH;

	-- Adjust latitude using self.variation fractal, to roughen the border between bands:
	lat = lat + (128 - self.variation:GetHeight(iX, iY))/(255.0 * 5.0);
	-- Limit to the range [0, 1]:
	lat = math.clamp(lat, 0, 1);
	
	return lat;
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
end
------------------------------------------------------------------------------
function FeatureGenerator:AddAtolls()
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
	local jungle_height = self.jungles:GetHeight(iX, iY);
	if lat > 0.59 then
		if (plot:CanHaveFeature(self.featureJungle)) then
			plot:SetFeatureType(self.featureJungle, -1);
		end
	end
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua WB Script) ...");
	
	local args = {}
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(false);
end
------------------------------------------------------------------------------
function StartPlotSystem()
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	local args = {method = 1};
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
	
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function PostProcessMap()
	-- Execute the script. This method engages the standard map generation
	-- process, plus any customizations set up in this script file.
	GenerateMap()
end
------------------------------------------------------------------------------

