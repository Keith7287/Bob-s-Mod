------------------------------------------------------------------------------
--	FILE:	 WB_Script_Random_Earth.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Hybrid script - Randomizes all except continental shapes and rivers.
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
			-- Instruction to erase any pre-placed Goody Huts
			plot:SetImprovementType(-1);
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
------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Applies random flat, hills and mountains to existing landforms.

	local args = {
		world_age = world_age,
		adjust_plates = 1.25,			-- Increases both hills and mountains.
		extra_mountains = 5,			-- Increases only mountains.
		tectonic_islands = false,
	};
	self:ApplyTectonics(args)

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

------------------------------------------------------------------------------
function TerrainGenerator:GetLatitudeAtPlot(iX, iY)
	-- Terrain bands are governed by latitude.
	--
	-- As drawn, the WB Earth maps do not have the equator at the middle of the
	-- map. Need to adjust the climate latitude to reflect this.
	--
	-- Represent the equator at 40% of map height.
	local lat = (2 / 3) * math.abs((self.iHeight * 0.4) - iY) / (self.iHeight * 0.4);
	
	-- Adjust latitude using self.variation fractal, to roughen the border between bands:
	lat = lat + (128 - self.variation:GetHeight(iX, iY))/(255.0 * 5.0);
	-- Limit to the range [0, 1]:
	lat = math.clamp(lat, 0, 1);
	
	return lat;
end
----------------------------------------------------------------------------------
function TerrainGenerator:GenerateTerrainAtPlot(iX,iY)
	local lat = self:GetLatitudeAtPlot(iX,iY);

	local plot = Map.GetPlot(iX, iY);
	local val = plot:GetTerrainType();
	if (plot:IsWater()) then
		if val == TerrainTypes.NO_TERRAIN then -- Error handling.
			val = self.terrainGrass;
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		return val;
	elseif val == self.terrainSnow then
		return val;
	end
	
	local terrainVal = self.terrainGrass;

	if(lat >= self.fSnowLatitude) then
		terrainVal = self.terrainSnow;
	elseif(lat >= self.fTundraLatitude) then
		terrainVal = self.terrainTundra;
	elseif (lat < self.fGrassLatitude) then
		terrainVal = self.terrainGrass;
	else
		local desertVal = self.deserts:GetHeight(iX, iY);
		local plainsVal = self.plains:GetHeight(iX, iY);
		if ((desertVal >= self.iDesertBottom) and (desertVal <= self.iDesertTop) and (lat >= self.fDesertBottomLatitude) and (lat < self.fDesertTopLatitude)) then
			terrainVal = self.terrainDesert;
		elseif ((plainsVal >= self.iPlainsBottom) and (plainsVal <= self.iPlainsTop)) then
			terrainVal = self.terrainPlains;
		end
	end
	
	-- Error handling.
	if (terrainVal == TerrainTypes.NO_TERRAIN) then
		return plot:GetTerrainType();
	end

	return terrainVal;
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua WB Script) ...");
	
	local args = {};
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	-- Represent the equator at 40% of map height.
	return (2 / 3) * math.abs(((self.iGridH * 0.4) - iY) / (self.iGridH * 0.4));
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
	-- Regional Division Method 2: Continental
	local args = {
		method = 2,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	-- Forcing starts along the ocean.
	local args = {mustBeCoast = false};
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

