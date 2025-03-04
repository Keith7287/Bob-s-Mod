-------------------------------------------------------------------------------
--	FILE:	 Amazon.lua
--	AUTHOR:  Bob Thomas (Sirian)
--	PURPOSE: Regional map script - Amazon Rainforest, South America
-------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
-------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("TerrainGenerator");
include("FeatureGenerator");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	return {
		Name = "TXT_KEY_MAP_AMAZON",
		Description = "TXT_KEY_MAP_AMAZON_HELP",
		IconIndex = 7,
		IconAtlas = "WORLDTYPE_ATLAS_3",
		Folder = "MAP_FOLDER_SP_DLC_1",
	};
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- Amazon has fully custom grid sizes to match the slice of Earth being represented.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {22, 20},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {36, 32},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {44, 40},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {52, 46},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {60, 54},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {72, 64}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
	return {
		Width = grid_size[1],
		Height = grid_size[2],
		WrapX = false,
	};      
     end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Amazon uses custom plot generation with regional specificity.
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Amazon) ...");
	local iW, iH = Map.GetGridSize();
	-- Initiate plot table, fill all data slots with type PLOT_LAND
	local plotTypes = {};
	table.fill(plotTypes, PlotTypes.PLOT_LAND, iW * iH);

	-- Grains for reducing "clumping" of hills/peaks.
	local grainvalues = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 6
		}
	local grain_amount = grainvalues[Map.GetWorldSize()];

	local hillsFrac = Fractal.Create(iW, iH, grain_amount, {}, 6, 6);
	local peaksFrac = Fractal.Create(iW, iH, grain_amount + 1, {}, 6, 6);
	local regionsFrac = Fractal.Create(iW, iH, grain_amount, {}, 6, 6);

	local iHillsBottom1 = hillsFrac:GetHeight(20);
	local iHillsTop1 = hillsFrac:GetHeight(30);
	local iHillsBottom2 = hillsFrac:GetHeight(70);
	local iHillsTop2 = hillsFrac:GetHeight(80);
	local iForty = hillsFrac:GetHeight(40);
	local iFifty = hillsFrac:GetHeight(50);
	local iSixty = hillsFrac:GetHeight(60);
	local iPeakCol = peaksFrac:GetHeight(75);
	local iPeakAndes = peaksFrac:GetHeight(63);
	local iHillsAmazonBasin = hillsFrac:GetHeight(95);

	-- Define the Atlantic, which will be in the NE corner.
	print("Simulate the Atlantic Ocean, where the Amazon River terminates. (Lua Amazon) ...");
	local atlantic_coords = {
		{math.floor(iW * 0.54), iH - 1},
		{math.floor(iW * 0.6), math.floor(iH * 0.935)},
		{math.floor(iW * 0.7), math.floor(iH * 0.935)},
		{math.floor(iW * 0.8), math.floor(iH * 0.855)},
		{math.floor(iW * 0.86), math.floor(iH * 0.733)},
		{iW - 1, math.floor(iH * 0.665)},
	};
	-- Draw the Atlantic Line and fill in everything north of it with ocean.
	for loop = 1, 5 do
		local startX = atlantic_coords[loop][1];
		local startY = atlantic_coords[loop][2];
		local endX = atlantic_coords[loop + 1][1];
		local endY = atlantic_coords[loop + 1][2];
		local dx = endX - startX;
		local dy = endY - startY
		local slope = 0;
		if dx ~= 0 then
			slope = dy / dx;
		end
		local y = startY;
		for x = startX + 1, endX do
			y = y + slope;
			local iY = math.floor(y);
			for loop_y = iY, iH - 1 do
				local i = loop_y * iW + x + 1;
				plotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end
	
	-- Define the Pacific, which will be in the SW corner.
	local pacific_coords = {
		{0, math.floor(iH * 0.23)},
		{math.floor(iW * 0.06), math.floor(iH * 0.13)},
		{math.floor(iW * 0.23), 0},
	};
	-- Draw the Pacific Line and fill in everything south of it with ocean.
	for loop = 1, 2 do
		local startX = pacific_coords[loop][1];
		local startY = pacific_coords[loop][2];
		local endX = pacific_coords[loop + 1][1];
		local endY = pacific_coords[loop + 1][2];
		local dx = endX - startX;
		local dy = endY - startY
		local slope = 0;
		if dx ~= 0 then
			slope = dy / dx;
		end
		local y = startY;
		for x = startX, endX - 1 do
			y = y + slope;
			local iY = math.floor(y);
			for loop_y = iY, 0, -1 do
				local i = loop_y * iW + x + 1;
				plotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end

	-- Define the hilly regions and append their plots to their plot lists. GLOBAL variables used here.
	brazilian_hills = {};
	venezuelan_hills = {};
	columbian_hills = {};
	andes = {};
	for x  = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			if x + y <= iH / 2 then
				if plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					table.insert(andes, i);
				end
			elseif x <= iW * 0.15 and y >= iH * 0.73 then
				table.insert(columbian_hills, i);
			elseif x >= iW * 0.275 and x <= iW * 0.525 and y >= iH * 0.79 then
				table.insert(venezuelan_hills, i);
			elseif x >= iW * 0.65 and y <= iH * 0.39 then
				table.insert(brazilian_hills, i);
			end
        end
	end

	-- Now assign plot types. Note, the plot table is already filled with flatlands.
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			-- Regional membership checked, effects chosen.
			-- Python had a simpler, less verbose method for checking table membership.
			local inAndes = false;
			local inBraz = false;
			local inCol = false;
			local inVen = false;
			for memberPlot, plotIndex in ipairs(andes) do
				if i == plotIndex then
					inAndes = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(brazilian_hills) do
				if i == plotIndex then
					inBraz = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(columbian_hills) do
				if i == plotIndex then
					inCol = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(venezuelan_hills) do
				if i == plotIndex then
					inVen = true;
					break
				end
			end
			local hillVal = hillsFrac:GetHeight(x,y);
			if inAndes then
				if plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					if hillVal >= iHillsBottom1 then
						local peakVal = peaksFrac:GetHeight(x,y);
						if (peakVal >= iPeakAndes) then
							plotTypes[i] = PlotTypes.PLOT_PEAK;
						else
							plotTypes[i] = PlotTypes.PLOT_HILLS;
						end
					end
				end
			elseif inBraz then
				if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal <= iHillsTop2 and hillVal >= iHillsBottom2)) then
					plotTypes[i] = PlotTypes.PLOT_HILLS;
				end
			elseif inCol then
				if hillVal >= iFifty then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal >= iPeakCol) then
						plotTypes[i] = PlotTypes.PLOT_PEAK;
					else
						plotTypes[i] = PlotTypes.PLOT_HILLS;
					end
				end
			elseif inVen then
				if ((hillVal >= iHillsBottom1 and hillVal <= iForty) or (hillVal >= iSixty and hillVal <= iHillsTop2)) then
					plotTypes[i] = PlotTypes.PLOT_HILLS;
				end
			else
				if plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					if hillVal >= iHillsAmazonBasin then
						plotTypes[i] = PlotTypes.PLOT_HILLS;
					end
				end
			end
		end
	end

	SetPlotTypes(plotTypes);
	GenerateCoasts();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Amazon uses a custom terrain generation.
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Amazon) ...");
	local iW, iH = Map.GetGridSize();
	local terrainTypes = {};
	local terrainDesert	= GameInfoTypes["TERRAIN_DESERT"];
	local terrainPlains	= GameInfoTypes["TERRAIN_PLAINS"];
	local terrainGrass	= GameInfoTypes["TERRAIN_GRASS"];	

	-- Initiate terrain table, fill all land slots with type TERRAIN_PLAINS
	table.fill(terrainTypes, terrainPlains, iW * iH);
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y)
			if plot:IsWater() then
				local i = y * iW + x; -- C++ Plot indices, starting at 0.
				terrainTypes[i] = plot:GetTerrainType();
			end
		end
	end

	-- Set up fractals and thresholds
	local grass_check = Fractal.Create(iW, iH, 5, {}, 6, 6);
	local desert_check = Fractal.Create(iW, iH, 4, {}, 6, 6);
	local iAndesGrass = grass_check:GetHeight(65)
	local iAndesDesert = desert_check:GetHeight(75)
	local iGrass = grass_check:GetHeight(60)

	-- Main loop
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			local plot = Map.GetPlot(x, y)
			if plot:IsWater() then
				terrainTypes[i - 1] = plot:GetTerrainType();
			else
				local inAndes = false;
				local inBraz = false;
				local inCol = false;
				local inVen = false;
				for memberPlot, plotIndex in ipairs(andes) do
					if i == plotIndex then
						inAndes = true;
						break
					end
				end
				for memberPlot, plotIndex in ipairs(brazilian_hills) do
					if i == plotIndex then
						inBraz = true;
						break
					end
				end
				for memberPlot, plotIndex in ipairs(columbian_hills) do
					if i == plotIndex then
						inCol = true;
						break
					end
				end
				for memberPlot, plotIndex in ipairs(venezuelan_hills) do
					if i == plotIndex then
						inVen = true;
						break
					end
				end
				if inAndes then
					local desertVal = desert_check:GetHeight(x, y);
					local grassVal = grass_check:GetHeight(x, y);
					if desertVal >= iAndesDesert then
						terrainTypes[i - 1] = terrainDesert;
					elseif grassVal >= iAndesGrass then
						terrainTypes[i - 1] = terrainGrass;
					end
				elseif inBraz or inCol or inVen then
					local grassVal = grass_check:GetHeight(x, y);
					if grassVal >= iGrass then
						terrainTypes[i - 1] = terrainGrass;
					end
				end
			end
		end
	end

	SetTerrainTypes(terrainTypes);	
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Amazon uses a custom feature generation.
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Amazon) ...")
	local iW, iH = Map.GetGridSize();
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local plot = Map.GetPlot(x, y)
			if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
				if plot:IsCoastalLand() then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, true); -- These flags are for recalc of areas and rebuild of graphics. Instead of recalc over and over, do recalc at end of loop.
				end
			end
		end
	end
	
	local grainvalues = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 6
		}
	local forest_grain = grainvalues[Map.GetWorldSize()];
		
	local iMarshPercent = 10;
	local iRiverMarshPercent = 30;
	local iForestPercent = 12;
	local iSEForestPercent = 30;
	local iOpenPercent = 10;

	local marshes = Fractal.Create(iW, iH, forest_grain, {}, 6, 6);
	local forests = Fractal.Create(iW, iH, forest_grain, {}, 6, 6);
	local open_lands = Fractal.Create(iW, iH, forest_grain, {}, 6, 6);
		
	local iMarshLevel = marshes:GetHeight(100 - iMarshPercent)
	local iRiverMarshLevel = marshes:GetHeight(100 - iRiverMarshPercent)
	local iForestLevel = forests:GetHeight(100 - iForestPercent)
	local iSEForestLevel = forests:GetHeight(100 - iSEForestPercent)
	local iOpenLevel = open_lands:GetHeight(100 - iOpenPercent)

	local featureForest = FeatureTypes.FEATURE_FOREST;
	local featureJungle = FeatureTypes.FEATURE_JUNGLE;
	local featureMarsh = FeatureTypes.FEATURE_MARSH;
	
	-- Now the main loop.
	local centerX = iW * 0.825;
	local centerY = iH * 0.69;
	local xAxis = iW * 0.09;
	local yAxis = iH * 0.1;
	local xAxisSquared = xAxis * xAxis;
	local yAxisSquared = yAxis * yAxis;
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local plot = Map.GetPlot(x, y);
			if not plot:IsWater() and (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
				local deltaX = x - centerX;
				local deltaY = y - centerY;
				local deltaXSquared = deltaX * deltaX;
				local deltaYSquared = deltaY * deltaY;
				local d = deltaXSquared/xAxisSquared + deltaYSquared/yAxisSquared;
				if x + y <= iH / 2 then
					if plot:CanHaveFeature(featureForest) and forests:GetHeight(x, y) >= iForestLevel then
						plot:SetFeatureType(featureForest, -1);
						plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
					end
				elseif (iW - x) + y <= iH * 0.52 then
					if plot:CanHaveFeature(featureForest) and forests:GetHeight(x, y) >= iSEForestLevel then
						plot:SetFeatureType(featureForest, -1);
						plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
					elseif plot:IsFlatlands() then
						if marshes:GetHeight(x, y) >= iMarshLevel then
							plot:SetFeatureType(featureMarsh, -1);
							plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
						end
					end
				elseif d <= 1 then
					plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
					if plot:IsFlatlands() then
						plot:SetFeatureType(featureMarsh, -1);
					end
				else
					if plot:IsFlatlands() then
						if forests:GetHeight(x, y) >= iForestLevel then
							plot:SetFeatureType(featureForest, -1);
							plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
						else
							if plot:IsRiver() then
								if marshes:GetHeight(x, y) >= iRiverMarshLevel then
									plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
									plot:SetFeatureType(featureMarsh, -1);
								end
							else
								if marshes:GetHeight(x, y) >= iMarshLevel then
									plot:SetFeatureType(featureMarsh, -1);
									plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
								end
							end
						end
					end
					if plot:GetFeatureType() == FeatureTypes.NO_FEATURE and not plot:IsMountain() then
						if open_lands:GetHeight(x, y) < iOpenLevel then
							plot:SetFeatureType(featureJungle, -1);
						else
							plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function DoAmazonRiver(startPlot, thisFlowDirection, riverID)
	local thisFlowDirection = thisFlowDirection;
	local iW, iH = Map.GetGridSize()
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
	else
		riverPlot = startPlot;		
	end
	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return; 
	end
	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();
	
	-- Determine flow direction.
	if thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST then
		local dice = 1 + Map.Rand(100, "Amazon River Direction - Lua");
		if riverPlotX > iW * 0.765 and riverPlotY < iH * 0.685 then
			bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_NORTH;
		elseif riverPlotX > iW * 0.83 and riverPlotY <= iH * 0.73 then
			bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_NORTH;
		elseif riverPlotY <= iH * 0.73 and dice <= 28 then
			bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_NORTH;
		else
			bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
		end
	elseif thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST then
		local dice = 1 + Map.Rand(100, "Amazon River Direction - Lua");
		if riverPlotX < iW * 0.73 and riverPlotY >= iH * 0.57 and dice <= 16 then
			bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_SOUTH;
		else
			bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
		end
	elseif thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH then
		bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
	elseif thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH then
		bestFlowDirection = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
	end
	
	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		DoAmazonRiver(riverPlot, bestFlowDirection, riverID);
	end
end
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

					-- Fix river problems in top row of the map.
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

					-- Fix river problems in left column of the map.
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
function AddRivers()
	local iW, iH = Map.GetGridSize()

	-- Place the Amazon!
	print("Charting the Amazon River (Lua Amazon) ...")
	local startX = math.floor((iW - 1) * 0.03);
	local startY = math.floor(iH / 2);
	local top = math.floor((iH - 1) * 0.8);
	local bottom = math.floor((iH - 1) * 0.43);
	local plot = Map.GetPlot(startX, startY);
	local inlandCorner = plot:GetInlandCorner();
	DoAmazonRiver(inlandCorner, FlowDirectionTypes.FLOWDIRECTION_NORTHEAST, 0);
	nextRiverID = 1;
	
	print("Amazon - Adding Remaining Rivers");
	local passConditions = {
		function(plot)
			return plot:IsHills() or plot:IsMountain();
		end,
		
		function(plot)
			return (not plot:IsCoastalLand()) and (Map.Rand(8, "MapGenerator AddRivers") == 0);
		end,
		
		function(plot)
			local area = plot:Area();
			local plotsPerRiverEdge = GameDefines["PLOTS_PER_RIVER_EDGE"];
			return (plot:IsHills() or plot:IsMountain()) and (area:GetNumRiverEdges() <	((area:GetNumTiles() / plotsPerRiverEdge) + 1));
		end,
		
		function(plot)
			local area = plot:Area();
			local plotsPerRiverEdge = GameDefines["PLOTS_PER_RIVER_EDGE"];
			return (area:GetNumRiverEdges() < (area:GetNumTiles() / plotsPerRiverEdge) + 1);
		end
	}
	for iPass, passCondition in ipairs(passConditions) do
		local riverSourceRange;
		local seaWaterRange;
		if (iPass <= 2) then
			riverSourceRange = GameDefines["RIVER_SOURCE_MIN_RIVER_RANGE"];
			seaWaterRange = GameDefines["RIVER_SOURCE_MIN_SEAWATER_RANGE"];
		else
			riverSourceRange = (GameDefines["RIVER_SOURCE_MIN_RIVER_RANGE"] / 2);
			seaWaterRange = (GameDefines["RIVER_SOURCE_MIN_SEAWATER_RANGE"] / 2);
		end
		for i, plot in Plots() do
			local current_x = plot:GetX()
			local current_y = plot:GetY()
			if current_x < 1 or current_x >= iW - 2 or current_y < 2 or current_y >= iH - 1 then
				-- Plot too close to edge, ignore it.
			elseif current_y >= bottom and current_y <= top then
				-- Plot is inside Amazon Corridor, ignore it.
			elseif(not plot:IsWater()) then
				if(passCondition(plot)) then
					if (not Map.FindWater(plot, riverSourceRange, true)) then
						if (not Map.FindWater(plot, seaWaterRange, false)) then
							local inlandCorner = plot:GetInlandCorner();
							if(inlandCorner) then
								local start_x = inlandCorner:GetX()
								local start_y = inlandCorner:GetY()
								if start_x + start_y <= iH * 0.36 then -- Ocean side of Andes
									DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST, nil);
								elseif start_y >= top and start_y < iH - 2 then -- Top of map
									if start_x <= iW * 0.23 and start_x > 1 then
										DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST, nil);
									elseif start_x > iW * 0.23 and start_x < iW - 2 then
										DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_SOUTH, nil);
									end
								elseif start_y <= bottom and start_y > 1 then -- Bottom half of map, Amazon side of Andes
									if start_x <= iW * 0.14 and start_x > 1 then
										DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_NORTHEAST, nil);
									elseif start_x > iW * 0.14 and start_x < iW - 2 then
										DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_NORTH, nil);
									end
								elseif start_y >= 0.65 and start_y < iH - 2 then
									if start_x <= iW * 0.23 and start_x > 1 then
										DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST, nil);
									end
								elseif start_y >= 0.57 and start_y < iH - 2 then
									if start_x <= iW * 0.15 and start_x > 1 then
										DoRiver(inlandCorner, nil, FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST, nil);
									end
								end
							end
						end
					end
				end			
			end
		end
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:__InitLuxuryWeights()
	self.luxury_region_weights[1] = {};			-- Tundra (n/a)

	self.luxury_region_weights[2] = {			-- Jungle
	{self.spices_ID,	30},
	{self.sugar_ID,		30},
	{self.gems_ID,		15},
	{self.silver_ID,	10},
	{self.fur_ID,		05},
	{self.dye_ID,		10},	};
	
	self.luxury_region_weights[3] = {			-- Forest
	{self.dye_ID,		75},
	{self.fur_ID,		10},
	{self.spices_ID,	15},	};
	
	self.luxury_region_weights[4] = {			-- Desert
	{self.incense_ID,	50},
	{self.gold_ID,		50},	};
	
	self.luxury_region_weights[5] = {			-- Hills
	{self.gold_ID,		65},
	{self.incense_ID,	35},	};
	
	self.luxury_region_weights[6] = {			-- Plains
	{self.cotton_ID,	30},
	{self.wine_ID,		50},
	{self.incense_ID,	20},	};
	
	self.luxury_region_weights[7] = {			-- Grass
	{self.cotton_ID,	70},
	{self.silver_ID,	30},	};
	
	self.luxury_region_weights[8] = {			-- Hybrid
	{self.cotton_ID,	15},
	{self.wine_ID,		15},
	{self.silver_ID,	10},
	{self.spices_ID,	05},
	{self.sugar_ID,		05},
	{self.incense_ID,	05},
	{self.gems_ID,		10},
	{self.gold_ID,		20},	};

	self.luxury_fallback_weights = {			-- Fallbacks, in case of extreme map conditions, or
	{self.pearls_ID,	10},
	{self.gold_ID,		10},
	{self.silver_ID,	05},					-- This list is also used to assign Disabled and Random types.
	{self.gems_ID,		10},					-- So it's important that this list contain every available luxury type.
	{self.fur_ID,		05},					-- NOTE: Marble affects Wonders, so is handled as a special case, on the side.
	{self.dye_ID,		05},
	{self.spices_ID,	05},
	{self.sugar_ID,		05},
	{self.cotton_ID,	05},
	{self.wine_ID,		05},
	{self.incense_ID,	05},	};

	self.luxury_city_state_weights = {			-- Weights for City States
	{self.pearls_ID,	15},
	{self.gold_ID,		10},					-- Recommended that this list also contains every available luxury.
	{self.silver_ID,	10},
	{self.gems_ID,		05},					-- NOTE: Marble affects Wonders, so is handled as a special case, on the side.
	{self.fur_ID,		15},
	{self.dye_ID,		10},
	{self.spices_ID,	05},
	{self.sugar_ID,		05},
	{self.cotton_ID,	10},
	{self.wine_ID,		10},
	{self.incense_ID,	15},	};

end	
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:CanPlaceCityStateAt(x, y, area_ID, force_it, ignore_collisions)
	-- Overriding default city state placement to prevent city states from being placed too close to map edges.
	local iW, iH = Map.GetGridSize();
	local plot = Map.GetPlot(x, y)
	local area = plot:GetArea()
	
	-- Adding this check for Great Plains
	if x < 1 or x >= iW - 1 or y < 1 or y >= iH - 1 then
		return false
	end
	--
	
	if area ~= area_ID and area_ID ~= -1 then
		return false
	end
	local plotType = plot:GetPlotType()
	if plotType == PlotTypes.PLOT_OCEAN or plotType == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	local terrainType = plot:GetTerrainType()
	if terrainType == TerrainTypes.TERRAIN_SNOW then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.cityStateData[plotIndex] > 0 and force_it == false then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.playerCollisionData[plotIndex] == true and ignore_collisions == false then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function AssignStartingPlots:AssignLuxuryToRegion(region_number)
	-- Assigns a luxury type to an individual region.
	local region_type = self.regionTypes[region_number];
	local luxury_candidates;
	if region_type > 0 and region_type < 9 then -- Note: if number of Region Types is modified, this line and the table to which it refers need adjustment.
		luxury_candidates = self.luxury_region_weights[region_type];
	else
		luxury_candidates = self.luxury_fallback_weights; -- Undefined Region, enable all possible luxury types.
	end
	--
	-- Build options list.
	local iNumAvailableTypes = 0;
	local resource_IDs, resource_weights, res_threshold = {}, {}, {};
	
	for index, resource_options in ipairs(luxury_candidates) do
		local res_ID = resource_options[1];
		
		-- CUSTOMIZING THIS LINE FOR AMAZON, changing maximum civs assigned the same type from 3 to 4!
		if self.luxury_assignment_count[res_ID] < 4 then -- This type still eligible.
		
			local test = TestMembership(self.resourceIDs_assigned_to_regions, res_ID)
			if self.iNumTypesAssignedToRegions < self.iNumMaxAllowedForRegions or test == true then -- Not a new type that would exceed number of allowed types, so continue.
				-- Water-based resources need to run a series of permission checks: coastal start in region, not a disallowed regions type, enough water, etc.
				if res_ID == self.whale_ID or res_ID == self.pearls_ID then
					if res_ID == self.whale_ID and self.regionTypes[region_number] == 2 then
						-- No whales in jungle regions, sorry
					elseif res_ID == self.pearls_ID and self.regionTypes[region_number] == 1 then
						-- No pearls in tundra regions, sorry
					else
						if self.startLocationConditions[region_number][1] == true then -- This region's start is along an ocean, so water-based luxuries are allowed.
							if self.regionTerrainCounts[region_number][8] >= 12 then -- Enough water available.
								table.insert(resource_IDs, res_ID);
								local adjusted_weight = resource_options[2] / (1 + self.luxury_assignment_count[res_ID]) -- If selected before, for a different region, reduce weight.
								table.insert(resource_weights, adjusted_weight);
								iNumAvailableTypes = iNumAvailableTypes + 1;
							end
						end
					end
				-- Land-based resources are automatically approved if they were in the region's option table.
				else
					table.insert(resource_IDs, res_ID);
					local adjusted_weight = resource_options[2] / (1 + self.luxury_assignment_count[res_ID])
					table.insert(resource_weights, adjusted_weight);
					iNumAvailableTypes = iNumAvailableTypes + 1;
				end
			end
		end
	end
	
	-- If options list is empty, pick from fallback options. First try to respect water-resources not being assigned to regions without coastal starts.
	if iNumAvailableTypes == 0 then
		for index, resource_options in ipairs(self.luxury_fallback_weights) do
			local res_ID = resource_options[1];
			if self.luxury_assignment_count[res_ID] < 3 then -- This type still eligible.
				local test = TestMembership(self.resourceIDs_assigned_to_regions, res_ID)
				if self.iNumTypesAssignedToRegions < self.iNumMaxAllowedForRegions or test == true then -- Won't exceed allowed types.
					if res_ID == self.whale_ID or res_ID == self.pearls_ID then
						if res_ID == self.whale_ID and self.regionTypes[region_number] == 2 then
							-- No whales in jungle regions, sorry
						elseif res_ID == self.pearls_ID and self.regionTypes[region_number] == 1 then
							-- No pearls in tundra regions, sorry
						else
							if self.startLocationConditions[region_number][1] == true then -- This region's start is along an ocean, so water-based luxuries are allowed.
								if self.regionTerrainCounts[region_number][8] >= 12 then -- Enough water available.
									table.insert(resource_IDs, res_ID);
									local adjusted_weight = resource_options[2] / (1 + self.luxury_assignment_count[res_ID]) -- If selected before, for a different region, reduce weight.
									table.insert(resource_weights, adjusted_weight);
									iNumAvailableTypes = iNumAvailableTypes + 1;
								end
							end
						end
					else
						table.insert(resource_IDs, res_ID);
						local adjusted_weight = resource_options[2] / (1 + self.luxury_assignment_count[res_ID])
						table.insert(resource_weights, adjusted_weight);
						iNumAvailableTypes = iNumAvailableTypes + 1;
					end
				end
			end
		end
	end

	-- If we get to here and still need to assign a luxury type, it means we have to force a water-based luxury in to this region, period.
	-- This should be the rarest of the rare emergency assignment cases, unless modifications to the system have tightened things too far.
	if iNumAvailableTypes == 0 then
		print("-"); print("Having to use emergency Luxury assignment process for Region#", region_number);
		print("This likely means a near-maximum number of civs in this game, and problems with not having enough legal Luxury types to spread around.");
		print("If you are modifying luxury types or number of regions allowed to get the same type, check to make sure your changes haven't violated the math so each region can have a legal assignment.");
		for index, resource_options in ipairs(self.luxury_fallback_weights) do
			local res_ID = resource_options[1];
			if self.luxury_assignment_count[res_ID] < 3 then -- This type still eligible.
				local test = TestMembership(self.resourceIDs_assigned_to_regions, res_ID)
				if self.iNumTypesAssignedToRegions < self.iNumMaxAllowedForRegions or test == true then -- Won't exceed allowed types.
					table.insert(resource_IDs, res_ID);
					local adjusted_weight = resource_options[2] / (1 + self.luxury_assignment_count[res_ID])
					table.insert(resource_weights, adjusted_weight);
					iNumAvailableTypes = iNumAvailableTypes + 1;
				end
			end
		end
	end
	if iNumAvailableTypes == 0 then -- Bad mojo!
		print("-"); print("FAILED to assign a Luxury type to Region#", region_number); print("-");
	end

	-- Choose luxury.
	local totalWeight = 0;
	for i, this_weight in ipairs(resource_weights) do
		totalWeight = totalWeight + this_weight;
	end
	local accumulatedWeight = 0;
	for index = 1, iNumAvailableTypes do
		local threshold = (resource_weights[index] + accumulatedWeight) * 10000 / totalWeight;
		table.insert(res_threshold, threshold);
		accumulatedWeight = accumulatedWeight + resource_weights[index];
	end
	local use_this_ID;
	local diceroll = Map.Rand(10000, "Choose resource type - Assign Luxury To Region - Lua");
	for index, threshold in ipairs(res_threshold) do
		if diceroll <= threshold then -- Choose this resource type.
			use_this_ID = resource_IDs[index];
			break
		end
	end
	
	return use_this_ID;
end
------------------------------------------------------------------------------
function AssignStartingPlots:AssignLuxuryRoles()
	self.iNumMaxAllowedForRegions = 6; -- Resetting to below legal minimum, because of disabling Whale, Silk, Ivory.
	-- This is possible because of raising the max number of civs with same lux type from 3 to 4. 4x6=24, which is the same as 3x8. See?
	self:SortRegionsByType()

	-- Assign a luxury to each region.
	for index, region_info in ipairs(self.regions_sorted_by_type) do
		local region_number = region_info[1];
		local resource_ID = self:AssignLuxuryToRegion(region_number)
		self.regions_sorted_by_type[index][2] = resource_ID; -- This line applies the assignment.
		self.region_luxury_assignment[region_number] = resource_ID;
		self.luxury_assignment_count[resource_ID] = self.luxury_assignment_count[resource_ID] + 1; -- Track assignments
		--
		--print("-"); print("Region#", region_number, " of type ", self.regionTypes[region_number], " has been assigned Luxury ID#", resource_ID);
		--
		local already_assigned = TestMembership(self.resourceIDs_assigned_to_regions, resource_ID)
		if not already_assigned then
			table.insert(self.resourceIDs_assigned_to_regions, resource_ID);
			self.iNumTypesAssignedToRegions = self.iNumTypesAssignedToRegions + 1;
			self.iNumTypesUnassigned = self.iNumTypesUnassigned - 1;
		end
	end
	
	-- Assign only TWO of the remaining types to be exclusive to City States. - CUSTOM
	-- Build options list.
	local iNumAvailableTypes = 0;
	local resource_IDs, resource_weights = {}, {};
	for index, resource_options in ipairs(self.luxury_city_state_weights) do
		local res_ID = resource_options[1];
		local test = TestMembership(self.resourceIDs_assigned_to_regions, res_ID)
		if test == false then
			table.insert(resource_IDs, res_ID);
			table.insert(resource_weights, resource_options[2]);
			iNumAvailableTypes = iNumAvailableTypes + 1;
		else
			--print("Luxury ID#", res_ID, "rejected by City States as already belonging to Regions.");
		end
	end
	if iNumAvailableTypes < 3 then
		print("---------------------------------------------------------------------------------------");
		print("- Luxuries have been modified in ways disruptive to the City State Assignment Process -");
		print("---------------------------------------------------------------------------------------");
	end
	-- Choose luxuries.
	for cs_lux = 1, 2 do -- CUSTOM
		local totalWeight = 0;
		local res_threshold = {};
		for i, this_weight in ipairs(resource_weights) do
			totalWeight = totalWeight + this_weight;
		end
		local accumulatedWeight = 0;
		for index, weight in ipairs(resource_weights) do
			local threshold = (weight + accumulatedWeight) * 10000 / totalWeight;
			table.insert(res_threshold, threshold);
			accumulatedWeight = accumulatedWeight + resource_weights[index];
		end
		local use_this_ID;
		local diceroll = Map.Rand(10000, "Choose resource type - City State Luxuries - Lua");
		for index, threshold in ipairs(res_threshold) do
			if diceroll < threshold then -- Choose this resource type.
				use_this_ID = resource_IDs[index];
				table.insert(self.resourceIDs_assigned_to_cs, use_this_ID);
				table.remove(resource_IDs, index);
				table.remove(resource_weights, index);
				self.iNumTypesUnassigned = self.iNumTypesUnassigned - 1;
				--print("-"); print("City States have been assigned Luxury ID#", use_this_ID);
				break
			end
		end
	end
	
	-- Assign Marble to special casing.
	table.insert(self.resourceIDs_assigned_to_special_case, self.marble_ID);
	self.iNumTypesUnassigned = self.iNumTypesUnassigned - 1;

	-- Assign appropriate amount to be Disabled, then assign the rest to be Random.
	local maxToDisable = 0; -- CUSTOM
	self.iNumTypesDisabled = math.min(self.iNumTypesUnassigned, maxToDisable);
	self.iNumTypesRandom = self.iNumTypesUnassigned - self.iNumTypesDisabled;
	local remaining_resource_IDs = {};
	for index, resource_options in ipairs(self.luxury_fallback_weights) do
		local res_ID = resource_options[1];
		local test1 = TestMembership(self.resourceIDs_assigned_to_regions, res_ID)
		local test2 = TestMembership(self.resourceIDs_assigned_to_cs, res_ID)
		if test1 == false and test2 == false then
			table.insert(remaining_resource_IDs, res_ID);
		end
	end
	local randomized_version = GetShuffledCopyOfTable(remaining_resource_IDs)
	local countdown = math.min(self.iNumTypesUnassigned, maxToDisable);
	for loop, resID in ipairs(randomized_version) do
		if countdown > 0 then
			table.insert(self.resourceIDs_not_being_used, resID);
			countdown = countdown - 1;
		else
			table.insert(self.resourceIDs_assigned_to_random, resID);
		end
	end
	
	--[[ Debug printout of luxury assignments.
	print("--- Luxury Assignment Table ---");
	print("-"); print("- - Assigned to Regions - -");
	for index, data in ipairs(self.regions_sorted_by_type) do
		print("Region#", data[1], "has Luxury type", data[2]);
	end
	print("-"); print("- - Assigned to City States - -");
	for index, type in ipairs(self.resourceIDs_assigned_to_cs) do
		print("Luxury type", type);
	end
	print("-"); print("- - Assigned to Random - -");
	for index, type in ipairs(self.resourceIDs_assigned_to_random) do
		print("Luxury type", type);
	end
	print("-"); print("- - Luxuries handled via Special Case - -");
	for index, type in ipairs(self.resourceIDs_assigned_to_special_case) do
		print("Luxury type", type);
	end
	print("- - - - - - - - - - - - - - - -");
	]]--	
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceOilInTheSea()
	-- WARNING: This operation will render the Strategic Resource Impact Table useless for
	-- further operations, so should always be called last, even after minor placements.
	local sea_oil_amt = 5;
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 1,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 2,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 4
	}
	local iNumToPlace = worldsizes[Map.GetWorldSize()];

	print("Adding Oil resources to the Sea.");
	self:PlaceSpecificNumberOfResources(self.oil_ID, sea_oil_amt, iNumToPlace, 0.2, 1, 4, 7, self.coast_list)
end
------------------------------------------------------------------------------
function AssignStartingPlots:GetMajorStrategicResourceQuantityValues()
	local uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt = 4, 4, 5, 6, 7, 8;
	return uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt
end
------------------------------------------------------------------------------
function AssignStartingPlots:GetSmallStrategicResourceQuantityValues()
	local uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt = 1, 2, 2, 2, 3, 3;
	return uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceSmallQuantitiesOfStrategics(frequency, plot_list)
	-- This function distributes small quantities of strategic resources.
	if plot_list == nil then
		print("No strategics were placed! -SmallQuantities");
		return
	end
	local iW, iH = Map.GetGridSize();
	local iNumTotalPlots = table.maxn(plot_list);
	local iNumToPlace = math.ceil(iNumTotalPlots / frequency);

	local uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt = self:GetSmallStrategicResourceQuantityValues()
	
	-- Main loop
	local current_index = 1;
	for place_resource = 1, iNumToPlace do
		local placed_this_res = false;
		if current_index <= iNumTotalPlots then
			for index_to_check = current_index, iNumTotalPlots do
				if placed_this_res == true then
					break
				else
					current_index = current_index + 1;
				end
				local plotIndex = plot_list[index_to_check];
				if self.strategicData[plotIndex] == 0 then
					local x = (plotIndex - 1) % iW;
					local y = (plotIndex - x - 1) / iW;
					local res_plot = Map.GetPlot(x, y)
					if res_plot:GetResourceType(-1) == -1 then
						-- Placing a small strategic resource here. Need to determine what type to place.
						local selected_ID = -1;
						local selected_quantity = 2;
						local plotType = res_plot:GetPlotType()
						local terrainType = res_plot:GetTerrainType()
						local featureType = res_plot:GetFeatureType()
						if featureType == FeatureTypes.FEATURE_MARSH then
							local diceroll = Map.Rand(4, "Resource selection - Place Small Quantities LUA");
							if diceroll == 0 then
								selected_ID = self.iron_ID;
								selected_quantity = iron_amt;
							elseif diceroll == 1 then
								selected_ID = self.coal_ID;
								selected_quantity = coal_amt;
							else
								selected_ID = self.oil_ID;
								selected_quantity = oil_amt;
							end
						elseif featureType == FeatureTypes.FEATURE_JUNGLE then
							local diceroll = Map.Rand(4, "Resource selection - Place Small Quantities LUA");
							if diceroll == 0 then
								selected_ID = self.iron_ID;
								selected_quantity = iron_amt;
							elseif diceroll == 1 then
								selected_ID = self.coal_ID;
								selected_quantity = coal_amt;
							else
								selected_ID = self.aluminum_ID;
								selected_quantity = alum_amt;
							end
						elseif featureType == FeatureTypes.FEATURE_FOREST then
							local diceroll = Map.Rand(4, "Resource selection - Place Small Quantities LUA");
							if diceroll == 0 then
								selected_ID = self.uranium_ID;
								selected_quantity = uran_amt;
							elseif diceroll == 1 then
								selected_ID = self.coal_ID;
								selected_quantity = coal_amt;
							else
								selected_ID = self.iron_ID;
								selected_quantity = iron_amt;
							end
						elseif featureType == FeatureTypes.NO_FEATURE then
							if plotType == PlotTypes.PLOT_HILLS then
								if terrainType == TerrainTypes.TERRAIN_GRASS or terrainType == TerrainTypes.TERRAIN_PLAINS then
									local diceroll = Map.Rand(5, "Resource selection - Place Small Quantities LUA");
									if diceroll <= 2 then
										selected_ID = self.iron_ID;
										selected_quantity = iron_amt;
									else
										selected_ID = self.coal_ID;
										selected_quantity = coal_amt;
									end
								else
									local diceroll = Map.Rand(5, "Resource selection - Place Small Quantities LUA");
									if diceroll < 2 then
										selected_ID = self.iron_ID;
										selected_quantity = iron_amt;
									else
										selected_ID = self.coal_ID;
										selected_quantity = coal_amt;
									end
								end
							elseif terrainType == TerrainTypes.TERRAIN_GRASS or terrainType == TerrainTypes.TERRAIN_PLAINS then
								selected_ID = self.iron_ID;
								selected_quantity = iron_amt;
							elseif terrainType == TerrainTypes.TERRAIN_DESERT then
								local diceroll = Map.Rand(3, "Resource selection - Place Small Quantities LUA");
								if diceroll == 0 then
									selected_ID = self.iron_ID;
									selected_quantity = iron_amt;
								elseif diceroll == 1 then
									selected_ID = self.aluminum_ID;
									selected_quantity = alum_amt;
								else
									selected_ID = self.oil_ID;
									selected_quantity = oil_amt;
								end
							else
								local diceroll = Map.Rand(4, "Resource selection - Place Small Quantities LUA");
								if diceroll == 0 then
									selected_ID = self.iron_ID;
									selected_quantity = iron_amt;
								elseif diceroll == 1 then
									selected_ID = self.uranium_ID;
									selected_quantity = uran_amt;
								else
									selected_ID = self.oil_ID;
									selected_quantity = oil_amt;
								end
							end
						end
						-- Now place the resource, then impact the strategic data layer.
						if selected_ID ~= -1 then	
							local strat_radius = Map.Rand(4, "Resource Radius - Place Small Quantities LUA");
							if strat_radius > 2 then
								strat_radius = 1;
							end
							res_plot:SetResourceType(selected_ID, selected_quantity);
							self:PlaceResourceImpact(x, y, 1, strat_radius);
							placed_this_res = true;
							self.amounts_of_resources_placed[selected_ID + 1] = self.amounts_of_resources_placed[selected_ID + 1] + selected_quantity;
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceStrategicAndBonusResources()
	local iW, iH = Map.GetGridSize()
	local uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt = self:GetMajorStrategicResourceQuantityValues()

	-- Place Strategic resources.
	print("Map Generation - Placing Strategics");
	local resources_to_place = {
	{self.oil_ID, oil_amt, 65, 1, 1},
	{self.iron_ID, iron_amt, 35, 0, 1} };
	self:ProcessResourceList(10, 1, self.marsh_list, resources_to_place)

	local resources_to_place = {
	{self.oil_ID, oil_amt, 50, 0, 1},
	{self.iron_ID, iron_amt, 50, 1, 1} };
	self:ProcessResourceList(13, 1, self.desert_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.iron_ID, iron_amt, 26, 0, 2},
	{self.coal_ID, coal_amt, 35, 1, 3},
	{self.aluminum_ID, alum_amt, 39, 2, 3} };
	self:ProcessResourceList(22, 1, self.hills_list, resources_to_place)

	local resources_to_place = {
	{self.coal_ID, coal_amt, 30, 1, 2},
	{self.uranium_ID, uran_amt, 70, 1, 1} };
	self:ProcessResourceList(75, 1, self.jungle_flat_list, resources_to_place)

	self:AddModernMinorStrategicsToCityStates()
	
	self:PlaceSmallQuantitiesOfStrategics(30, self.land_list);
	
	self:PlaceOilInTheSea()

	
	-- Check for low or missing Strategic resources
	if self.amounts_of_resources_placed[self.iron_ID + 1] < 8 then
		--print("Map has very low iron, adding another.");
		local resources_to_place = { {self.iron_ID, iron_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.hills_list, resources_to_place) -- 99999 means one per that many tiles: a single instance.
	end
	if self.amounts_of_resources_placed[self.iron_ID + 1] < 4 * self.iNumCivs then
		--print("Map has very low iron, adding another.");
		local resources_to_place = { {self.iron_ID, iron_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.land_list, resources_to_place)
	end
	if self.amounts_of_resources_placed[self.coal_ID + 1] < 8 then
		--print("Map has very low coal, adding another.");
		local resources_to_place = { {self.coal_ID, coal_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.hills_list, resources_to_place)
	end
	if self.amounts_of_resources_placed[self.coal_ID + 1] < 4 * self.iNumCivs then
		--print("Map has very low coal, adding another.");
		local resources_to_place = { {self.coal_ID, coal_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.land_list, resources_to_place)
	end
	if self.amounts_of_resources_placed[self.oil_ID + 1] < 4 * self.iNumCivs then
		--print("Map has very low oil, adding another.");
		local resources_to_place = { {self.oil_ID, oil_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.land_list, resources_to_place)
	end
	if self.amounts_of_resources_placed[self.aluminum_ID + 1] < 4 * self.iNumCivs then
		--print("Map has very low aluminum, adding another.");
		local resources_to_place = { {self.aluminum_ID, alum_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.hills_list, resources_to_place)
	end
	if self.amounts_of_resources_placed[self.uranium_ID + 1] < 2 * self.iNumCivs then
		--print("Map has very low uranium, adding another.");
		local resources_to_place = { {self.uranium_ID, uran_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.land_list, resources_to_place)
	end
	
	
	-- Place Bonus Resources
	print("Map Generation - Placing Bonuses");
	self:PlaceFish(6, self.coast_list);
	self:PlaceSexyBonusAtCivStarts()
	self:AddExtraBonusesToHillsRegions()

	local resources_to_place = {
	{self.wheat_ID, 1, 100, 0, 2} };
	self:ProcessResourceList(10, 3, self.desert_wheat_list, resources_to_place)

	local resources_to_place = {
	{self.banana_ID, 1, 100, 0, 3} };
	self:ProcessResourceList(17, 3, self.banana_list, resources_to_place)

	local resources_to_place = {
	{self.wheat_ID, 1, 100, 0, 2} };
	self:ProcessResourceList(17, 3, self.plains_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.cow_ID, 1, 100, 1, 2} };
	self:ProcessResourceList(20, 3, self.grass_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.stone_ID, 1, 100, 1, 1} };
	self:ProcessResourceList(20, 3, self.dry_grass_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.sheep_ID, 1, 100, 0, 1} };
	self:ProcessResourceList(11, 3, self.hills_open_list, resources_to_place)

	local resources_to_place = {
	{self.stone_ID, 1, 100, 1, 2} };
	self:ProcessResourceList(19, 3, self.desert_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.deer_ID, 1, 100, 3, 4} };
	self:ProcessResourceList(20, 3, self.forest_flat_that_are_not_tundra, resources_to_place)

end
------------------------------------------------------------------------------
function StartPlotSystem()
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = 1,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("No Natural Wonders available on this script.");
	--start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function DetermineContinents()
	-- Setting all continental art to Africa style.
	for i, plot in Plots() do
		if plot:IsWater() then
			plot:SetContinentArtType(0);
		else
			plot:SetContinentArtType(3);
		end
	end
end
-------------------------------------------------------------------------------
