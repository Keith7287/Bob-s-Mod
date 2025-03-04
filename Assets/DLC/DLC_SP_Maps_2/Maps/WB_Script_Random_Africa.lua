------------------------------------------------------------------------------
--	FILE:	 WB_Script_Random_Africa.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Hybrid script - Customized to randomize Africa.
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
------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Applies random flat, hills and mountains to existing landforms.

	local args = {
		world_age = world_age,
		adjust_plates = 1.4,			-- Increases both hills and mountains.
		extra_mountains = 1,			-- Increases only mountains.
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
	GenerateCoasts()
	
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function TerrainGenerator:InitFractals()
	-- Customized for Random Africa.
	self.deserts = Fractal.Create(	56, 18, 
									2, self.fractalFlags, 
									6, 5);
									
	self.iDesertBottom = self.deserts:GetHeight(20);

	self.plains = Fractal.Create(	self.iWidth, self.iHeight, 
									3, self.fractalFlags, 
									6, 6);
									
	self.iPlainsTop = self.plains:GetHeight(65);

	self.variation = Fractal.Create(self.iWidth, self.iHeight, 
									self.grain_amount, self.fractalFlags, 
									self.fracXExp, self.fracYExp);

	self.terrainDesert	= GameInfoTypes["TERRAIN_DESERT"];
	self.terrainPlains	= GameInfoTypes["TERRAIN_PLAINS"];
	self.terrainSnow	= GameInfoTypes["TERRAIN_SNOW"];
	self.terrainTundra	= GameInfoTypes["TERRAIN_TUNDRA"];
	self.terrainGrass	= GameInfoTypes["TERRAIN_GRASS"];	
end
------------------------------------------------------------------------------
function TerrainGenerator:GenerateTerrainAtPlot(iX,iY)
	local plot = Map.GetPlot(iX, iY);
	local terrainVal = plot:GetTerrainType();

	if (plot:IsWater()) then
		local val = plot:GetTerrainType();
		if val == TerrainTypes.NO_TERRAIN then -- Error handling.
			val = self.terrainGrass;
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		return val;	 
	end
	
	if terrainVal == self.terrainPlains then
		if iY > 48 then
			local desertVal = self.deserts:GetHeight(iX, iY - 48);
			if desertVal >= self.iDesertBottom then
				terrainVal = self.terrainDesert;
			end
		else
			local plainsVal = self.plains:GetHeight(iX, iY);
			if plainsVal >= self.iPlainsTop then
				terrainVal = self.terrainDesert;
			end
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
function FeatureGenerator:__initFractals()
	local width = self.iGridW;
	local height = self.iGridH;
	
	-- Create fractals
	self.jungles		= Fractal.Create(width, height, 2, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forests		= Fractal.Create(width, height, 4, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forestclumps	= Fractal.Create(width, height, self.clump_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.marsh			= Fractal.Create(width, height, 4, self.fractalFlags, self.fracXExp, self.fracYExp);
	
	-- Get heights
	self.iJungleBottom	= self.jungles:GetHeight(15)
	self.iJungleTop		= self.jungles:GetHeight(95)
	self.iJungleRange	= (self.iJungleTop - self.iJungleBottom) * self.iJungleFactor;
	self.iForestLevel	= self.forests:GetHeight(100 - 50)
	self.iClumpLevel	= self.forestclumps:GetHeight(70)
	self.iMarshLevel	= self.marsh:GetHeight(100 - self.fMarshPercent)
	
	self.terrainGrass	= GameInfoTypes["TERRAIN_GRASS"];	
end
------------------------------------------------------------------------------
function FeatureGenerator:AddFeaturesAtPlot(iX, iY)
	-- Customized for Random Africa.
	local lat = self:GetLatitudeAtPlot(iX, iY);
	local plot = Map.GetPlot(iX, iY);
	local terrainVal = plot:GetTerrainType();

	if plot:CanHaveFeature(self.featureFloodPlains) then
		-- All desert plots along river are set to flood plains.
		plot:SetFeatureType(self.featureFloodPlains, -1)
	end
	
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddOasisAtPlot(plot, iX, iY, lat);
	end

	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddMarshAtPlot(plot, iX, iY, lat);
	end
		
	if iY >= self.iGridH * (28/70) and iY <= self.iGridH * (42/70) and terrainVal == self.terrainGrass then
		if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
			self:AddJunglesAtPlot(plot, iX, iY, lat);
		end
	end
	
	if terrainVal == self.terrainGrass then
		if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
			self:AddForestsAtPlot(plot, iX, iY, lat);
		end
	end
		
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
	local jungle_height = self.jungles:GetHeight(iX, iY);
	if jungle_height <= self.iJungleTop and jungle_height >= self.iJungleBottom then
		if(plot:CanHaveFeature(self.featureJungle)) then
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
	local args = {
		method = 1,
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
	
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function PostProcessMap()
	-- Execute the script. This method engages the standard map generation
	-- process, plus any customizations set up in this script file.
	GenerateMap()
end
------------------------------------------------------------------------------

