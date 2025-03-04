------------------------------------------------------------------------------
--	FILE:	 WB_Script_Scandinavia_Classic.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Hybrid script - For the traditional Scandinavia map, which includes
--	         the Baltic states and a bit more of Russia than does the compact map.
------------------------------------------------------------------------------
--	Copyright (c) 2013 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("FeatureGenerator");
include("TerrainGenerator");
include("MapmakerUtilities");

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
	-- This version of Apply Tectonics has been modified to leave existing hills and mountains intact.
	local args = args or {};
	local world_age = args.world_age or 2; -- Default to 4 Billion Years old.
	--
	local world_age_old = args.world_age_old or 1;
	local world_age_normal = args.world_age_normal or 2;
	local world_age_new = args.world_age_new or 3;
	--
	local extra_mountains = args.extra_mountains or 0;
	local grain_amount = args.grain_amount or 4;
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
	local hillsNearMountains = 95 - (adjustment * 2) - extra_mountains;
	local mountains = 98 - adjustment - extra_mountains;

	-- Hills and Mountains handled differently according to map size
	local WorldSizeTypes = {};
	for row in GameInfo.Worlds() do
		WorldSizeTypes[row.Type] = row.ID;
	end
	local sizekey = Map.GetWorldSize();
	-- Fractal Grains
	local sizevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]     = 3,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 3,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 4,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 4,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 5,
		[WorldSizeTypes.WORLDSIZE_HUGE]		= 5
	};
	local grain = sizevalues[sizekey] or 3;
	-- Tectonics Plate Counts
	local platevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]		= 6,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 9,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 12,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 18,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 24,
		[WorldSizeTypes.WORLDSIZE_HUGE]     = 30
	};
	local numPlates = platevalues[sizekey] or 5;
	-- Add in any plate count modifications passed in from the map script.
	numPlates = numPlates * adjust_plates;

	-- Generate fractals to govern hills and mountains
	self.hillsFrac = Fractal.Create(self.iW, self.iH, grain_amount, self.iTerrainFlags, fracXExp, fracYExp);
	self.mountainsFrac = Fractal.Create(self.iW, self.iH, grain_amount, self.iTerrainFlags, fracXExp, fracYExp);

	-- Use Brian's tectonics method to weave ridgelines in to the fractals.
	self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);

	-- Get height values for plot types
	local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
	local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
	local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
	local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
	local iHillsClumps = self.mountainsFrac:GetHeight(hillsClumps);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
	local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
	local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);

	-- Get height values for tectonic islands
	local iMountain100 = self.mountainsFrac:GetHeight(100);
	local iMountain99 = self.mountainsFrac:GetHeight(99);
	local iMountain97 = self.mountainsFrac:GetHeight(97);
	local iMountain95 = self.mountainsFrac:GetHeight(95);

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
					
			elseif self.wholeworldPlotTypes[i] == PlotTypes.PLOT_LAND then
				-- Add new hills and mountains only on existing flats.
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
	self.plains = Fractal.Create(	self.iWidth, self.iHeight, 
									3, self.fractalFlags, 
									-1, -1);
									
	self.iPlainsTop = self.plains:GetHeight(70);

	self.grass = Fractal.Create(	self.iWidth, self.iHeight, 
									4, self.fractalFlags, 
									-1, -1);

	self.iGrassTop = self.grass:GetHeight(80);

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
		local plainsVal = self.plains:GetHeight(iX, iY);
		if plainsVal >= self.iPlainsTop then
			terrainVal = self.terrainGrass;
		end
	elseif terrainVal == self.terrainGrass then
		local plainsVal = self.grass:GetHeight(iX, iY);
		if plainsVal >= self.iGrassTop then
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
function GetRiverValueAtPlot(plot)
	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = (numPlots - plot:GetPlotType()) * 20;
	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = 0
		end
	end
	sum = sum + Map.Rand(10, "River Rand");
	return sum;
end
------------------------------------------------------------------------------
function DoRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)
	-- Customizing to handle problems in top row of the map. Only this aspect has been altered.

	local iW, iH = Map.GetGridSize()
	thisFlowDirection = thisFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;
	originalFlowDirection = originalFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;

	-- pStartPlot = the plot at whose SE corner the river is starting
	if (riverID == nil) then
		riverID = nextRiverID;
		nextRiverID = nextRiverID + 1;
	end

	local otherRiverID = _rivers[startPlot]
	if (otherRiverID ~= nil and otherRiverID ~= riverID and originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		return; -- Another river already exists here; can't branch off of an existing river!
	end

	local riverPlot;
	
	local bestFlowDirection = FlowDirectionTypes.NO_FLOWDIRECTION;
	if (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH) then
	
		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if ( adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		riverPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);
		
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST) then
	
		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if ( adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then
	
		riverPlot = Map.PlotDirection(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH) then
	
		riverPlot = Map.PlotDirection(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then

		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST) then
		
		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		
		if ( adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		riverPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_WEST);

	else
		-- River is starting here, set the direction in the next step
		riverPlot = startPlot;		
	end

	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return; 
	end

	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();
	
	-- Table of methods used to determine the adjacent plot.
	local adjacentPlotFunctions = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST); 
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHEAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_EAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTH] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_SOUTHWEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_WEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end	
	}
	
	if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

		-- Attempt to calculate the best flow direction.
		local bestValue = math.huge;
		for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
			if (GetOppositeFlowDirection(flowDirection) ~= originalFlowDirection) then
				
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
					
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (flowDirection == originalFlowDirection) then
							value = (value * 3) / 4;
						end
						
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end

					-- Custom addition for Highlands, to fix river problems in top row of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotY == iH - 1 then -- Top row of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST then
							
							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end

					-- Custom addition for Highlands, to fix river problems in left column of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotX == 0 then -- Left column of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST then
							
							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end
					end
				end
			end
		end
		
		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		
			local bestValue = math.huge;
			for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
						
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end	
				end
			end
		end
	end
	
	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		if  (originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			originalFlowDirection = bestFlowDirection;
		end
		
		DoRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AddLakes()
	print("Map Generation - Adding Custom Lakes for Random Scandinavia.");
	local iW, iH = Map.GetGridSize();
	local iWest = math.floor(iW * 0.6);
	local iNorth = math.floor(iH * 0.78);
	local iEast = math.floor(iW * 0.9);
	local iSouth = math.floor(iH * 0.43);
	
	-- Identify candidate plots.
	local lake_plot_candidate_list = {};
	for x = iWest, iEast do
		for y = iSouth, iNorth do
			local plot = Map.GetPlot(x, y);
			if not plot:IsWater() then
				if not plot:IsMountain() then
					if not plot:IsRiver() then
						if not plot:IsCoastalLand() then
							table.insert(lake_plot_candidate_list, {x, y});
						end
					end
				end
			end
		end
	end
	local max_possible_lakes = table.maxn(lake_plot_candidate_list);
	print(tostring(max_possible_lakes).." plots eligible for lakes.");
	if max_possible_lakes < 3 then
		return
	end
	
	-- Determine Number of Lakes to be added.
	local worldsizes = { -- Data is {Addition, Maprand} where the addition is added to a random number to reach a total.
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {5, 4},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {7, 5},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {10, 5},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {13, 8},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {17, 9},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {22, 11}
		}
	local temp_table = worldsizes[Map.GetWorldSize()];
	local addition = temp_table[1];
	local lake_rand = math.floor(Map.Rand(temp_table[2], "Lua WB Script - Lakes Random"));
	local iNumLakes = math.min(addition + lake_rand, max_possible_lakes) -- Make sure not to target more Lakes than are possible.
	local numLakesAdded = 0;
	local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
	local firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
	
	print("Number of Lakes to add =", iNumLakes);
	print("Lake Rand =", lake_rand, " and Addition =", addition);
	
	--
	function ApplyHexAdjustment(x, y, plot_adjustments)
		local iW, iH = Map.GetGridSize();
		local adjusted_x, adjusted_y;
		if Map:IsWrapX() == true then
			adjusted_x = (x + plot_adjustments[1]) % iW;
		else
			adjusted_x = x + plot_adjustments[1];
		end
		if Map:IsWrapY() == true then
			adjusted_y = (y + plot_adjustments[2]) % iH;
		else
			adjusted_y = y + plot_adjustments[2];
		end
		return adjusted_x, adjusted_y;
	end
	--
	
	-- Create lake size table for the current map.
	local worldsizes = { -- Data is number of table entries for each lake size; size values (# of plots to the lake) range from 1 - 5.
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {4, 2, 1, 0, 0},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {12, 9, 4, 1, 0},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {4, 3, 2, 1, 0},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {11, 9, 6, 3, 1},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {7, 6, 4, 2, 1},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {8, 7, 5, 3, 2},
		}
	local plot_targets = worldsizes[Map.GetWorldSize()];
	local lake_size_table = {};
	for current_size = 1, 5 do
		local target = plot_targets[current_size];
		if target > 0 then
			for loop = 1, target do
				table.insert(lake_size_table, current_size);
			end
		end
	end
	local rand_target = table.maxn(lake_size_table);
	
	-- Build Lakes.
	for loop = 1, iNumLakes do
		local rand = 1 + Map.Rand(max_possible_lakes, "Lua WB Script - Choose Lake Center Plot");
		local lake_center_plot = lake_plot_candidate_list[rand];
		local center_plot = Map.GetPlot(lake_center_plot[1], lake_center_plot[2]);
		-- Choose lake target size.
		local lake_size_rand = 1 + Map.Rand(rand_target, "Lua WB Script - Choose Lake Size");
		local lake_size = lake_size_table[lake_size_rand];
		print("Lake #", loop, " has size of ", lake_size);
		-- If Lake target size is greater than 1 plot, proceed to identify wing plots.
		if lake_size > 1 then
			-- Identify candidate wing plots.
			local x, y = lake_center_plot[1], lake_center_plot[2];
			local wing_plot_candidate_list = {};
			local randomized_first_ring_adjustments = nil;
			local isEvenY = true;
			if y / 2 > math.floor(y / 2) then
				isEvenY = false;
			end
			if isEvenY then
				randomized_first_ring_adjustments = GetShuffledCopyOfTable(firstRingYIsEven);
			else
				randomized_first_ring_adjustments = GetShuffledCopyOfTable(firstRingYIsOdd);
			end
			for attempt = 1, 6 do
				local plot_adjustments = randomized_first_ring_adjustments[attempt];
				local searchX, searchY = ApplyHexAdjustment(x, y, plot_adjustments)
				local plot = Map.GetPlot(searchX, searchY);
				if not plot:IsWater() then
					if not plot:IsMountain() then
						if not plot:IsRiver() then
							if not plot:IsCoastalLand() then
								table.insert(wing_plot_candidate_list, {searchX, searchY});
							end
						end
					end
				end
			end
			local iNumWingCandidates = table.maxn(wing_plot_candidate_list);
			if iNumWingCandidates >= 1 then
				local iNumWings = math.min(lake_size - 1, iNumWingCandidates)
				-- Create Lake "wing" plots.
				for wing_loop = 1, iNumWings do
					local plot = Map.GetPlot(wing_plot_candidate_list[wing_loop][1], wing_plot_candidate_list[wing_loop][2])
					plot:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
					plot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
				end
			end
		end
		-- Create Lake "center" plot.
		center_plot:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
		center_plot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
		numLakesAdded = numLakesAdded + 1;
		print("Added lake of size ", tostring(lake_size).." at plot ", lake_center_plot[1], lake_center_plot[2]);
	end

	print(tostring(numLakesAdded).." lakes added.")

	Map.RecalculateAreas();
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
	self.iForestLevel	= self.forests:GetHeight(100 - 40)
	self.iClumpLevel	= self.forestclumps:GetHeight(80)
	self.iMarshLevel	= self.marsh:GetHeight(100 - self.fMarshPercent)
	
	self.terrainGrass	= GameInfoTypes["TERRAIN_GRASS"];	
end
------------------------------------------------------------------------------
function FeatureGenerator:AddFeaturesAtPlot(iX, iY)
	-- adds any appropriate features at the plot (iX, iY) where (0,0) is in the SW
	local lat = self:GetLatitudeAtPlot(iX, iY);
	local plot = Map.GetPlot(iX, iY);

	if plot:CanHaveFeature(self.featureFloodPlains) then
		-- All desert plots along river are set to flood plains.
		plot:SetFeatureType(self.featureFloodPlains, -1)
	end
	
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddOasisAtPlot(plot, iX, iY, lat);
	end

	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddIceAtPlot(plot, iX, iY, lat);
	end

	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddMarshAtPlot(plot, iX, iY, lat);
	end
		
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddJunglesAtPlot(plot, iX, iY, lat);
	end
	
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		if plot:GetTerrainType() ~= self.terrainTundra then
			self:AddForestsAtPlot(plot, iX, iY, lat);
		end
	end
		
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
end
------------------------------------------------------------------------------
function FeatureGenerator:AddAtolls()
end
------------------------------------------------------------------------------
function FeatureGenerator:AdjustTerrainTypes()
	-- This function added April 2009 for Civ5, by Bob Thomas.
	-- Purpose of this function is to turn terrain under jungles
	-- into Plains, and to soften arctic terrain types at rivers.
	local width = self.iGridW - 1;
	local height = self.iGridH - 1;
	
	self.tundra = Fractal.Create(self.iGridW, self.iGridH, 5, {}, -1, -1);
	self.iTundraBottom = self.tundra:GetHeight(60);
	
	for y = 0, height do
		for x = 0, width do
			local plot = Map.GetPlot(x, y);
			
			if (plot:GetFeatureType() == self.featureForest) then
				if (plot:GetTerrainType() == self.terrainPlains) then
					local tundraVal = self.tundra:GetHeight(x, y);
					if tundraVal >= self.iTundraBottom then
						plot:SetTerrainType(self.terrainTundra, false, true)  -- These flags are for recalc of areas and rebuild of graphics. No need to recalc from any of these changes.
					end	
				end	
			elseif (plot:IsRiver()) then
				local terrainType = plot:GetTerrainType();
				if (terrainType == self.terrainTundra) then
					plot:SetTerrainType(self.terrainPlains, false, true)
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua WB Script) ...");
	
	local args = {}
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(true);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function StartPlotSystem()
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	local args = {
		method = 3,
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

