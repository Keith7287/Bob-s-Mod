-------------------------------------------------------------------------------
--	FILE:	 Great_Plains.lua
--	AUTHOR:  Bob Thomas (Sirian)
--	PURPOSE: Regional map script - Great Plains, North America
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
		Name = "TXT_KEY_MAP_GREAT_PLAINS",
		Description = "TXT_KEY_MAP_GREAT_PLAINS_HELP",
		IconIndex = 21,
		IconAtlas = "WORLDTYPE_ATLAS_3",
	};
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- Great Plains has fully custom grid sizes to match the slice of Earth being represented.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {18, 14},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {28, 22},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {36, 26},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {44, 32},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {56, 44},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {72, 56}
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
-- Great Plains uses custom plot generation with regional specificity.
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Great Plains) ...");
	local iW, iH = Map.GetGridSize();
	-- Initiate plot table, fill all data slots with type PLOT_LAND
	local plotTypes = {};
	table.fill(plotTypes, PlotTypes.PLOT_LAND, iW * iH);
	-- set fractal flags, no wrap, no zero row anomalies.
	local iFlags = {};
	-- Grains for reducing "clumping" of hills/peaks on larger maps.
	local grainvalues = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 6
		}
	local grain_amount = grainvalues[Map.GetWorldSize()];

	local hillsFrac = Fractal.Create(iW, iH, grain_amount, iFlags, 6, 6);
	local peaksFrac = Fractal.Create(iW, iH, grain_amount + 1, iFlags, 6, 6);
	local regionsFrac = Fractal.Create(iW, iH, grain_amount, iFlags, 6, 6);

	local iPlainsThreshold = hillsFrac:GetHeight(8);
	local iHillsBottom1 = hillsFrac:GetHeight(20);
	local iHillsTop1 = hillsFrac:GetHeight(30);
	local iHillsBottom2 = hillsFrac:GetHeight(70);
	local iHillsTop2 = hillsFrac:GetHeight(80);
	local iForty = hillsFrac:GetHeight(40);
	local iFifty = hillsFrac:GetHeight(50);
	local iSixty = hillsFrac:GetHeight(60);
	local iPeakThreshold = peaksFrac:GetHeight(25);
	local iPeakRockies = peaksFrac:GetHeight(37);

	-- Define six regions:
	-- 1. Rockies  2. Plains  3. Eastern Grasslands
	-- 4. The Gulf  5. Ozarks  6. SW Desert
	local rockies = {};
	local plains = {};
	local grass = {};
	local gulf = {};
	local ozarks = {};
	local swDesert = {};
	local plainsWest = 0.2 -- regional divide between Rockies and Plains
	local plainsEast = 0.67 -- divide between Plains and East
	local south = math.ceil(iH / 4) -- divide between Rockies and SW
	local middle = iW / 2 -- western edge of the Gulf

	-- first define the Gulf, which will always be in the SE corner.
	print("Simulate the Gulf of Mexico (Lua Great Plains) ...");
	local coast = middle;
	for y = 0, south do
		coast = coast + Map.Rand(4, "Gulf of Mexico - Great Plains Lua");
		if coast > iW - 1 then
			break
		end
		for x = coast, iW - 1 do
			local i = y * iW + x + 1
			table.insert(gulf, i);
		end
	end

	-- now define the Ozark Mountains, a randomly placed region of hilly terrain.
	-- First roll the location in which the Ozarks will be placed.
	print("Simulate the Ozarks (Lua Great Plains) ...");
	local leftX = math.floor(iW * 0.38);
	local rightX = math.floor(iW * 0.71);
	local rangeX = rightX - leftX;
	local bottomY = math.floor(iH * 0.35);
	local topY = math.floor(iH * 0.67);
	local rangeY = topY - bottomY;
	local slideX = Map.Rand(rangeX, "Ozarks Placement - Great Plains Lua");
	local slideY = Map.Rand(rangeY, "Ozarks Placement - Great Plains Lua");
	-- Now set the boundaries and scope of the Ozarks.
	local leftOzark = leftX + slideX;
	local botOzark = bottomY + slideY;
	local widthOzark = iW / 6;
	local heightOzark = iH / 6;
	local rightOzark = leftOzark + widthOzark + 1;
	local topOzark = botOzark + heightOzark + 1;
	local midOzarkY = botOzark + heightOzark / 2;
	-- Now loop the plots and append their index numbers to the Ozark list.
	-- Run two loops for Y, both starting in middle, one to north, one to south.
	local varLeft = leftOzark;
	local varRight = rightOzark;
	for y = midOzarkY + 1, topOzark - 1 do
		if varLeft > varRight then
			break
		end
		for x = varLeft, varRight do
			local i = y * iW + x + 1;
			table.insert(ozarks, i);
		end
		local leftSeed = Map.Rand(5, "Ozarks Shape - Great Plains Lua");
		if leftSeed == 4 then
			leftSeed = 0;
		end
		if leftSeed == 3 then
			leftSeed = 1;
		end
		varLeft = varLeft + leftSeed;
		local rightSeed = Map.Rand(5, "Ozarks Shape - Great Plains Lua");
		if rightSeed == 4 then
			rightSeed = 0;
		end
		if rightSeed == 3 then
			rightSeed = 1;
		end
		varRight = varRight - rightSeed;
	end
	-- Second Loop
	varLeft = leftOzark
	varRight = rightOzark
	for y = midOzarkY, botOzark + 1, -1 do
		if varLeft > varRight then
			break
		end
		for x = varLeft, varRight do
			local i = y * iW + x + 1;
			table.insert(ozarks, i);
		end
		leftSeed = Map.Rand(5, "Ozarks Shape - Great Plains Lua");
		if leftSeed == 4 then
			leftSeed = 0;
		end
		if leftSeed == 3 then
			leftSeed = 1;
		end
		varLeft = varLeft + leftSeed;
		rightSeed = Map.Rand(5, "Ozarks Shape - Great Plains Lua");
		if rightSeed == 4 then
			rightSeed = 0;
		end
		if rightSeed == 3 then
			rightSeed = 1;
		end
		varRight = varRight - rightSeed;
	end
	-- now define the four easiest regions and append their plots to their plot lists
	print("Simulate the Rockies (Lua Great Plains) ...");
	for x  = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			local lat = x / iW;
			lat = lat + (128 - regionsFrac:GetHeight(x, y))/(255.0 * 5.0);
			if lat < 0 then
				lat = 0;
			end
			if lat > 1 then
				lat = 1;
			end
			if y >= south and lat <= plainsWest then
				table.insert(rockies, i);
			elseif y < south and lat <= plainsWest then
				table.insert(swDesert, i);
			else
				local inGulf = false;
				local inOzarks = false;
				for memberPlot, plotIndex in ipairs(gulf) do
					if i == plotIndex then
						inGulf = true;
					end
				end
				for memberPlot, plotIndex in ipairs(ozarks) do
					if i == plotIndex then
						inOzarks = true;
					end
				end
				if lat >= plainsEast then
					if not inGulf and not inOzarks then
						table.insert(grass, i);
					end
				else
					if not inGulf and not inOzarks then
						table.insert(plains, i);
					end
        		end
        	end
        end
	end

	-- Now assign plot types. Note, the plot table is already filled with flatlands.
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			-- Regional membership checked, effects chosen.
			-- Python had a simpler, less verbose method for checking table membership.
			local inGulf = false;
			local inOzarks = false;
			local inSWDesert = false;
			local inRockies = false;
			local inGrass = false;
			for memberPlot, plotIndex in ipairs(gulf) do
				if i == plotIndex then
					inGulf = true;
				end
			end
			for memberPlot, plotIndex in ipairs(ozarks) do
				if i == plotIndex then
					inOzarks = true;
				end
			end
			for memberPlot, plotIndex in ipairs(swDesert) do
				if i == plotIndex then
					inSWDesert = true;
				end
			end
			for memberPlot, plotIndex in ipairs(rockies) do
				if i == plotIndex then
					inRockies = true;
				end
			end
			for memberPlot, plotIndex in ipairs(grass) do
				if i == plotIndex then
					inGrass = true;
				end
			end
			if inGulf then
				plotTypes[i] = PlotTypes.PLOT_OCEAN;
			elseif inSWDesert then
				local hillVal = hillsFrac:GetHeight(x,y);
				if ((hillVal >= iHillsBottom1 and hillVal <= iForty) or (hillVal >= iSixty and hillVal <= iHillsTop2)) then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal <= iPeakThreshold) then
						plotTypes[i] = PlotTypes.PLOT_PEAK;
					else
						plotTypes[i] = PlotTypes.PLOT_HILLS;
					end
				end
			elseif inOzarks then
				local hillVal = hillsFrac:GetHeight(x,y);
				if ((hillVal <= iHillsTop1) or (hillVal >= iForty and hillVal <= iFifty) or (hillVal >= iSixty and hillVal <= iHillsBottom2) or (hillVal >= iHillsTop2)) then
					plotTypes[i] = PlotTypes.PLOT_HILLS;
				end
			elseif inRockies then
				local hillVal = hillsFrac:GetHeight(x,y);
				if hillVal >= iHillsTop1 then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal <= iPeakRockies) then
						plotTypes[i] = PlotTypes.PLOT_PEAK;
					else
						plotTypes[i] = PlotTypes.PLOT_HILLS;
					end
				end
			elseif inGrass then
				local hillVal = hillsFrac:GetHeight(x,y);
				if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
					plotTypes[i] = PlotTypes.PLOT_HILLS;
				end
			else -- Plot is in the plains.
				local hillVal = hillsFrac:GetHeight(x,y);
				if hillVal < iPlainsThreshold then
					plotTypes[i] = PlotTypes.PLOT_HILLS;
				end
			end
		end
	end

	SetPlotTypes(plotTypes);
	GenerateCoasts();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Great Plains uses a custom terrain generation.
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Great Plains) ...");
	local iW, iH = Map.GetGridSize();
	local terrainTypes = {};
	local iFlags = {};
	local grainvalues = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 5
		}
	local grain_amount = grainvalues[Map.GetWorldSize()];

	local iRockyDTopPercent = 100;
	local iRockyPTopPercent = 50;
	local iRockyPBottomPercent = 20;
	local iDesertTopPercent = 100;
	local iDesertBottomPercent = 92;
	local iTexDesertTopPercent = 70;
	local iTexDesertBottomPercent = 50;
	local iGrassTopPercent = 17;
	local iGrassBottomPercent = 0;
	local iTexGrassBottomPercent = 6;
	local iEastDTopPercent = 100;
	local iEastDBottomPercent = 98;
	local iEastPTopPercent = 98;
	local iEastPBottomPercent = 75;
	local iMountainTopPercent = 75;
	local iMountainBottomPercent = 60;

	local fWestLongitude = 0.15;
	local fEastLongitude = 0.65;
	local fTexLat = 0.37;
	local fTexEast = 0.55;

	local iGrassPercent = 17;
	local iDesertPercent = 8;
	local iTexDesertPercent = 20;
	local iEastDesertPercent = 2;
	local iEastPlainsPercent = 23;
	local iRockyDesertPercent = 50;
	local iRockyPlainsPercent = 30;

	local rocky = Fractal.Create(iW, iH, grain_amount, iFlags, -1, -1);
	local plains = Fractal.Create(iW, iH, grain_amount + 1, iFlags, -1, -1);
	local east = Fractal.Create(iW, iH, grain_amount, iFlags, -1, -1);
	local variation = Fractal.Create(iW, iH, grain_amount, iFlags, -1, -1);

	local iRockyDTop = rocky:GetHeight(iRockyDTopPercent)
	local iRockyDBottom = rocky:GetHeight(iRockyPTopPercent)
	local iRockyPTop = rocky:GetHeight(iRockyPTopPercent)
	local iRockyPBottom = rocky:GetHeight(iRockyPBottomPercent)

	local iDesertTop = plains:GetHeight(iDesertTopPercent)
	local iDesertBottom = plains:GetHeight(iDesertBottomPercent)
	local iTexDesertTop = plains:GetHeight(iTexDesertTopPercent)
	local iTexDesertBottom = plains:GetHeight(iTexDesertBottomPercent)
	local iGrassTop = plains:GetHeight(iGrassTopPercent)
	local iGrassBottom = plains:GetHeight(iGrassBottomPercent)
	local iTexGrassBottom = plains:GetHeight(iTexGrassBottomPercent)

	local iEastDTop = east:GetHeight(iEastDTopPercent)
	local iEastDBottom = east:GetHeight(iEastDBottomPercent)
	local iEastPTop = east:GetHeight(iEastPTopPercent)
	local iEastPBottom = east:GetHeight(iEastPBottomPercent)

	local terrainDesert	= GameInfoTypes["TERRAIN_DESERT"];
	local terrainPlains	= GameInfoTypes["TERRAIN_PLAINS"];
	local terrainGrass	= GameInfoTypes["TERRAIN_GRASS"];	

	-- Main loop, generate the terrain plot by plot.
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x; -- C++ Plot indices, starting at 0.
			local plot = Map.GetPlot(x, y);
			local terrainVal;

			-- Handle water plots
			if plot:IsWater() then
				terrainVal = plot:GetTerrainType();

			-- Handle land plots
			else
				-- Set latitude at plot
				local lat = x / iW; -- 0.0 = west
				lat = lat + (128 - variation:GetHeight(x, y))/(255.0 * 5.0);
				if lat < 0 then
					lat = 0;
				elseif lat > 1 then
					lat = 1;
				end

				if lat <= fWestLongitude then
					local val = rocky:GetHeight(x, y);
					if val >= iRockyDBottom and val <= iRockyDTop then
						terrainVal = terrainDesert;
					elseif val >= iRockyPBottom and val <= iRockyPTop then
						terrainVal = terrainPlains;
					else
						local long = y / iH;
						if long > 0.23 then
							terrainVal = terrainGrass;
						else
							terrainVal = terrainDesert;
						end
					end
				elseif lat > fEastLongitude then
					local val = east:GetHeight(x, y);
					if val >= iEastDBottom and val <= iEastDTop then
						terrainVal = terrainDesert;
					elseif val >= iEastPBottom and val <= iEastPTop then
						terrainVal = terrainPlains;
					else
						terrainVal = terrainGrass;
					end
				elseif lat > fWestLongitude and lat <= fTexEast and y / iH <= fTexLat then
					-- More desert in Texas region.
					local val = east:GetHeight(x, y);
					if val >= iDesertBottom and val <= iDesertTop then
						terrainVal = terrainDesert;
					elseif val >= iTexDesertBottom and val <= iTexDesertTop then
						terrainVal = terrainDesert;
					--elseif val >= iTexGrassBottom and val <= iGrassTop then
						--terrainVal = terrainGrass;
					else
						terrainVal = terrainPlains;
					end
				else
					local val = plains:GetHeight(x, y);
					if val >= iDesertBottom and val <= iDesertTop then
						terrainVal = terrainDesert;
					--elseif val >= iGrassBottom and val <= iGrassTop then
						--terrainVal = terrainGrass;
					else
						terrainVal = terrainPlains;
					end
				end
			end
			
			-- Input result of this plot to terrain types array
			terrainTypes[i] = terrainVal;
		end
	end
	
	SetTerrainTypes(terrainTypes);	
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Great Plains uses a custom feature generation.
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Great Plains) ...")
	local iW, iH = Map.GetGridSize();
	-- set fractal flags, no wrap, no zero row anomalies.
	local iFlags = {};
	local grainvalues = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 5,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 6,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 6,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 7
		}
	local forest_grain = grainvalues[Map.GetWorldSize()];
		
	local iMarshPercent = 50;
	local iForestPercent = 8;
	local iEastForestPercent = 70;
	local iRockyForestPercent = 55;
		
	local fracXExp = -1
	local fracYExp = -1

	local forests = Fractal.Create(iW, iH, forest_grain, iFlags, fracXExp, fracYExp);
		
	local iMarshLevel = forests:GetHeight(100 - iMarshPercent)
	local iForestLevel = forests:GetHeight(iForestPercent)
	local iEastForestLevel = forests:GetHeight(iEastForestPercent)
	local iRockyForestLevel = forests:GetHeight(iRockyForestPercent)

	local featureFloodPlains = FeatureTypes.FEATURE_FLOOD_PLAINS;
	local featureForest = FeatureTypes.FEATURE_FOREST;
	local featureOasis = FeatureTypes.FEATURE_OASIS;
	local featureMarsh = FeatureTypes.FEATURE_MARSH;
	
	-- Now the main loop.
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local long = x / iW;
			local lat = y / iH;
			local plot = Map.GetPlot(x, y);

			if plot:CanHaveFeature(featureFloodPlains) then
				plot:SetFeatureType(featureFloodPlains, -1)
			end

			if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
				if (plot:CanHaveFeature(featureOasis)) then
					if Map.Rand(100, "Add Oasis Lua") <= 5 then
						plot:SetFeatureType(featureOasis, -1);
					end
				end
			end

			if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
				-- Marsh only in Louisiana Wetlands!
				if long > 0.65 and lat < 0.45 then
					if (plot:CanHaveFeature(featureMarsh)) then
						if forests:GetHeight(x, y) >= iMarshLevel then
							plot:SetFeatureType(featureMarsh, -1);
						end
					end
				end
			end
			
			if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
				-- No Evergreens in Civ5, so... Deciduous trees everywhere.
				if (long < 0.16 and lat > 0.23) and (plot:IsFlatlands() or plot:IsHills()) then
					if forests:GetHeight(x, y) <= iRockyForestLevel then
						plot:SetFeatureType(featureForest, -1);
					end
				elseif long > 0.72 and plot:CanHaveFeature(featureForest) then
					if forests:GetHeight(x, y) <= iEastForestLevel then
						plot:SetFeatureType(featureForest, -1);
					end
				else
					if plot:CanHaveFeature(featureForest) then
						if forests:GetHeight(x, y) <= iForestLevel then
							plot:SetFeatureType(featureForest, -1);
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetMississippiRiverValueAtPlot(plot)
	local iW, iH = Map.GetGridSize()
	local x = plot:GetX()
	local y = plot:GetY()
	local center = math.floor((iW - 1) * (0.84 + (((iH - y) / iH) * 0.08)));
	local left = math.floor((iW - 1) * (0.74 + (((iH - y) / iH) * 0.08)));
	local right = math.floor((iW - 1) * (0.9 + (((iH - y) / iH) * 0.08)));
	local direction_influence_value;
	local random_factor_x = Map.Rand(6, "River direction random x factor - Great Plains LUA") - 1;
	local random_factor_y = Map.Rand(3, "River direction random y factor - Great Plains LUA");
	--print("Checking Miss River Value for plot", x, y, "- - - L/C/R ", left, center, right);
	
	if x < left then
		direction_influence_value = (9999 * (iW - x)) + (y * 25);
	elseif x > right then
		direction_influence_value = (9999 * x) + (y * 25);
	else
		direction_influence_value = (((math.abs(x - center) * 0.1) * random_factor_x) + y) * random_factor_y;
	end
	--print("-- Direction Influence Value = ", direction_influence_value);

	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = ((numPlots - plot:GetPlotType()) * 20) + direction_influence_value;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = sum + (numPlots * 10);
		end
	end
	sum = sum + Map.Rand(10, "River Rand");
	
	--print("Plot Value Sum = ", sum);

	return sum;
end
------------------------------------------------------------------------------
function GetRiverValueAtPlot(plot)
	-- Custom method to force other rivers to flow toward the Mississippi River.
	local iW, iH = Map.GetGridSize()
	local x = plot:GetX()
	local y = plot:GetY()
	local random_factor = Map.Rand(3, "River direction random factor - Great Plains LUA");
	local direction_influence_value = (math.abs(x - (iW * 0.85)) + math.abs(y - (iH / 2))) * random_factor;
	if y > iH * 0.87 then
		direction_influence_value = direction_influence_value + (400 / (iH - y));
	end

	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = ((numPlots - plot:GetPlotType()) * 20) + direction_influence_value;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = sum + (numPlots * 10);
		end
	end
	--sum = sum + Map.Rand(10, "River Rand");

	return sum;
end
------------------------------------------------------------------------------
function DoMississippiRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)
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
						--print("Non-nil River Plot!");
						local value = GetMississippiRiverValueAtPlot(adjacentPlot); -- CUSTOM
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
		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			local bestValue = math.huge;
			for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
					local adjacentPlot = getAdjacentPlot();
					if (adjacentPlot ~= nil) then
						--print("Non-nil River Plot!");
						local value = GetMississippiRiverValueAtPlot(adjacentPlot); -- CUSTOM
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
		DoMississippiRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end
end
------------------------------------------------------------------------------
function AddRivers()
	local iW, iH = Map.GetGridSize()

	-- Place the Mississippi!
	print("Charting the Mississippi (Lua Great Plains) ...")
	local startX = math.floor((iW - 1) * 0.78);
	local startY = iH - 2;
	local left = math.floor((iW - 1) * 0.74);
	local right = math.floor((iW - 1) * 0.9);
	local plot = Map.GetPlot(startX, startY);
	local inlandCorner = plot:GetInlandCorner();
	local orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTH;
	DoMississippiRiver(inlandCorner, nil, orig_direction, nil);
	
	print("Great Plains - Adding Remaining Rivers");
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
			elseif current_x >= left and current_x <= right then
				-- Plot is inside Mississippi Corridor, ignore it.
			elseif(not plot:IsWater()) then
				if(passCondition(plot)) then
					if (not Map.FindWater(plot, riverSourceRange, true)) then
						if (not Map.FindWater(plot, seaWaterRange, false)) then
							local inlandCorner = plot:GetInlandCorner();
							if(inlandCorner) then
								local start_x = inlandCorner:GetX()
								local start_y = inlandCorner:GetY()
								local orig_direction;
								if start_y < iH / 3 then -- South third of map
									if start_x <= left then -- SW Corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
									elseif start_x >= right then -- SE Corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
									end
								else -- North half of map
									if start_x < left then -- NW corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
									elseif start_x > right then -- NE corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
									end
								end
								DoRiver(inlandCorner, nil, orig_direction, nil);
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

	self.luxury_region_weights[2] = {			-- Jungle (Marsh, in Great Plains)
	{self.spices_ID,	35},
	{self.sugar_ID,		45},
	{self.dye_ID,		20},	};
	
	self.luxury_region_weights[3] = {			-- Forest
	{self.dye_ID,		35},
	{self.fur_ID,		50},
	{self.spices_ID,	15},	};
	
	self.luxury_region_weights[4] = {			-- Desert
	{self.incense_ID,	35},
	{self.gold_ID,		35},
	{self.cotton_ID,	10},
	{self.sugar_ID,		10},	};
	
	self.luxury_region_weights[5] = {			-- Hills
	{self.gold_ID,		30},
	{self.silver_ID,	30},
	{self.fur_ID,		15},
	{self.gems_ID,		25},	};
	
	self.luxury_region_weights[6] = {			-- Plains
	{self.cotton_ID,	30},
	{self.silver_ID,	10},
	{self.wine_ID,		40},
	{self.incense_ID,	20},	};
	
	self.luxury_region_weights[7] = {			-- Grass
	{self.cotton_ID,	30},
	{self.silver_ID,	20},
	{self.sugar_ID,		20},
	{self.spices_ID,	05},
	{self.gems_ID,		05},	};
	
	self.luxury_region_weights[8] = {			-- Hybrid
	{self.cotton_ID,	15},
	{self.wine_ID,		15},
	{self.silver_ID,	10},
	{self.spices_ID,	05},
	{self.sugar_ID,		05},
	{self.incense_ID,	05},
	{self.gems_ID,		05},
	{self.gold_ID,		05},	};

	self.luxury_fallback_weights = {			-- Fallbacks, in case of extreme map conditions, or
	{self.pearls_ID,	10},
	{self.gold_ID,		10},
	{self.silver_ID,	05},					-- This list is also used to assign Disabled and Random types.
	{self.gems_ID,		10},					-- So it's important that this list contain every available luxury type.
	{self.fur_ID,		10},					-- NOTE: Marble affects Wonders, so is handled as a special case, on the side.
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
	{self.gems_ID,		10},					-- NOTE: Marble affects Wonders, so is handled as a special case, on the side.
	{self.fur_ID,		15},
	{self.dye_ID,		10},
	{self.spices_ID,	15},
	{self.sugar_ID,		10},
	{self.cotton_ID,	10},
	{self.wine_ID,		10},
	{self.incense_ID,	15},	};

end	
------------------------------------------------------------------------------
function AssignStartingPlots:DetermineRegionTypes()
	for this_region, terrainCounts in ipairs(self.regionTerrainCounts) do
		-- Set each region to "Undefined Type" as default.
		-- If all efforts fail at determining what type of region this should be, region type will remain Undefined.
		--local totalPlots = terrainCounts[1];
		local areaPlots = terrainCounts[2];
		--local waterCount = terrainCounts[3];
		local flatlandsCount = terrainCounts[4];
		local hillsCount = terrainCounts[5];
		local peaksCount = terrainCounts[6];
		--local lakeCount = terrainCounts[7];
		--local coastCount = terrainCounts[8];
		--local oceanCount = terrainCounts[9];
		local iceCount = terrainCounts[10];
		local grassCount = terrainCounts[11];
		local plainsCount = terrainCounts[12];
		local desertCount = terrainCounts[13];
		local tundraCount = terrainCounts[14];
		local snowCount = terrainCounts[15];
		local forestCount = terrainCounts[16];
		--local jungleCount = terrainCounts[17];
		local marshCount = terrainCounts[18];
		local riverCount = terrainCounts[19];
		--local floodplainCount = terrainCounts[20];
		--local oasisCount = terrainCounts[21];
		--local coastalLandCount = terrainCounts[22];
		--local nextToCoastCount = terrainCounts[23];

		-- Jungle check. (Doubling as Marsh region for Great Plains)
		if (marshCount >= areaPlots * 0.08) then
			table.insert(self.regionTypes, 2);
			--print("-");
			--print("Region #", this_region, " has been defined as a Jungle(Marsh) Region.");
		
		-- Hills check. Moved up in priority to ensure that Rocky Mountains regions are not defined as forest.
		elseif (hillsCount >= areaPlots * 0.30) then
			table.insert(self.regionTypes, 5);
			--print("-");
			--print("Region #", this_region, " has been defined as a Hills Region.");

		-- Forest check.
		elseif (forestCount >= areaPlots * 0.30) then
			table.insert(self.regionTypes, 3);
			--print("-");
			--print("Region #", this_region, " has been defined as a Forest Region.");
		
		-- Desert check.
		elseif (desertCount >= areaPlots * 0.25) then
			table.insert(self.regionTypes, 4);
			--print("-");
			--print("Region #", this_region, " has been defined as a Desert Region.");

		-- Plains check.
		elseif (plainsCount >= areaPlots * 0.3) and (plainsCount * 0.7 > grassCount) then
			table.insert(self.regionTypes, 6);
			--print("-");
			--print("Region #", this_region, " has been defined as a Plains Region.");
		
		-- Grass check.
		elseif (grassCount >= areaPlots * 0.3) and (grassCount * 0.7 > plainsCount) then
			table.insert(self.regionTypes, 7);
			--print("-");
			--print("Region #", this_region, " has been defined as a Grassland Region.");
		
		-- Hybrid check.
		elseif ((grassCount + plainsCount + desertCount + tundraCount + snowCount + hillsCount + peaksCount) > areaPlots * 0.8) then
			table.insert(self.regionTypes, 8);
			--print("-");
			--print("Region #", this_region, " has been defined as a Hybrid Region.");

		else -- Undefined Region (most likely due to operating on a mod that adds new terrain types.)
			table.insert(self.regionTypes, 0);
			--print("-");
			--print("Region #", this_region, " has been defined as an Undefined Region.");
		
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeGeyser(x, y)
	-- Checks a candidate plot for eligibility to be the Geyser.
	local plot = Map.GetPlot(x, y);
	-- Checking center plot, which must be at least two plots away from any salt water, and not be in the desert or tundra.
	if plot:IsWater() then
		return
	end
	local iW, iH = Map.GetGridSize();
	local plotIndex = y * iW + x + 1;
	if self.plotDataIsCoastal[plotIndex] == true or self.plotDataIsNextToCoast[plotIndex] == true then
		return
	end
	local iNumMountains, iNumHills, iNumDeserts, iNumTundra = 0, 0, 0, 0;
	local plotType = plot:GetPlotType();
	if plotType == PlotTypes.PLOT_MOUNTAIN then
		iNumMountains = iNumMountains + 1;
	elseif plotType == PlotTypes.PLOT_HILLS then
		iNumHills = iNumHills + 1;
	end
	-- Now process the surrounding plots.
	for loop, direction in ipairs(self.direction_types) do
		local adjPlot = Map.PlotDirection(x, y, direction)
		plotType = adjPlot:GetPlotType();
		if plotType == PlotTypes.PLOT_MOUNTAIN then
			iNumMountains = iNumMountains + 1;
		elseif plotType == PlotTypes.PLOT_HILLS then
			iNumHills = iNumHills + 1;
		end
	end
	-- If not enough hills or mountains, reject this site.
	if iNumMountains < 1 and iNumHills < 4 then
		return
	end
	-- This site is inland, has hills or mountains, so it's good.
	table.insert(self.geyser_list, plotIndex);
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeGibraltar(x, y)
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeFuji(x, y)
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeReef(x, y)
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeKrakatoa(x, y)
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeRareMystical(x, y)
end
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
		
		-- CUSTOMIZING THIS LINE FOR GREAT PLAINS, changing maximum civs assigned the same type from 3 to 4!
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
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 1,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 2,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 2,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 3
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
function AssignStartingPlots:PlaceStrategicAndBonusResources()
	local iW, iH = Map.GetGridSize()
	local uran_amt, horse_amt, oil_amt, iron_amt, coal_amt, alum_amt = self:GetMajorStrategicResourceQuantityValues()

	-- Place Strategic resources.
	print("Map Generation - Placing Strategics");
	local resources_to_place = {
	{self.oil_ID, oil_amt, 65, 1, 1},
	{self.uranium_ID, uran_amt, 35, 0, 1} };
	self:ProcessResourceList(9, 1, self.marsh_list, resources_to_place)

	local resources_to_place = {
	{self.oil_ID, oil_amt, 65, 0, 1},
	{self.iron_ID, iron_amt, 35, 1, 1} };
	self:ProcessResourceList(13, 1, self.desert_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.iron_ID, iron_amt, 26, 0, 2},
	{self.coal_ID, coal_amt, 35, 1, 3},
	{self.aluminum_ID, alum_amt, 39, 2, 3} };
	self:ProcessResourceList(22, 1, self.hills_list, resources_to_place)

	local resources_to_place = {
	{self.coal_ID, coal_amt, 30, 1, 2},
	{self.uranium_ID, uran_amt, 70, 1, 1} };
	self:ProcessResourceList(39, 1, self.forest_flat_list, resources_to_place)

	local resources_to_place = {
	{self.horse_ID, horse_amt, 100, 2, 5} };
	self:ProcessResourceList(40, 1, self.dry_grass_flat_no_feature, resources_to_place)
	local resources_to_place = {
	{self.horse_ID, horse_amt, 100, 1, 4} };
	self:ProcessResourceList(67, 1, self.plains_flat_no_feature, resources_to_place)
	
	self:AddModernMinorStrategicsToCityStates()
	
	self:PlaceSmallQuantitiesOfStrategics(32, self.land_list);
	
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
	if self.amounts_of_resources_placed[self.horse_ID + 1] < 4 * self.iNumCivs then
		--print("Map has very low horse, adding another.");
		local resources_to_place = { {self.horse_ID, horse_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.plains_flat_no_feature, resources_to_place)
	end
	if self.amounts_of_resources_placed[self.horse_ID + 1] < 4 * self.iNumCivs then
		--print("Map has very low horse, adding another.");
		local resources_to_place = { {self.horse_ID, horse_amt, 100, 0, 0} };
		self:ProcessResourceList(99999, 1, self.dry_grass_flat_no_feature, resources_to_place)
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

	-- Great Plains, Buffalo Herds
	print("Placing Buffalo Herds (Cows - Lua Great Plains) ...")
	local herds = Fractal.Create(iW, iH, 7, {}, -1, -1)
	local iHerdsClumps = herds:GetHeight(3)
	local iHerdsBottom1 = herds:GetHeight(24)
	local iHerdsTop1 = herds:GetHeight(27)
	local iHerdsBottom2 = herds:GetHeight(73)
	local iHerdsTop2 = herds:GetHeight(76)
	-- More herds in the northern 5/8ths of the map.
	local herdNorth = iH - 1;
	local herdSouth = math.floor(iH * 0.37);
	local herdWest = math.floor(iW / 5);
	local herdEast = math.floor((2 * iW) / 3);
	local herdSlideRange = math.floor((herdEast - herdWest) / 6);
	for y = herdSouth, herdNorth do
		local herdLeft = herdWest + Map.Rand(herdSlideRange, "Herds, West Boundary - Great Plains Lua")
		local herdRight = herdEast - Map.Rand(herdSlideRange, "Herds, East Boundary - Great Plains Lua")
		for x = herdLeft, herdRight do
			-- Fractalized placement of herds
			local plot = Map.GetPlot(x, y)
			if plot:IsWater() or plot:IsMountain() or plot:GetFeatureType() == FeatureTypes.FEATURE_OASIS then
				-- No buffalo at the water hole, sorry!
			elseif plot:GetResourceType(-1) == -1 then
				local herdVal = herds:GetHeight(x, y)
				if ((herdVal <= iHerdsClumps) or (herdVal >= iHerdsBottom1 and herdVal <= iHerdsTop1) or (herdVal >= iHerdsBottom2 and herdVal <= iHerdsTop2)) then
					plot:SetResourceType(self.cow_ID, 1);
					self.amounts_of_resources_placed[self.cow_ID + 1] = self.amounts_of_resources_placed[self.cow_ID + 1] + 1;
				end
			end
		end
	end
	-- Fewer herds in the southern 3/8ths of the map.
	herdNorth = math.floor(iH * 0.37);
	herdSouth = math.floor(iH * 0.15);
	herdWest = math.floor(iW * 0.32);
	herdEast = math.floor(iW * 0.59);
	herdSlideRange = math.floor((herdEast - herdWest) / 5);
	for y = herdSouth, herdNorth do
		local herdLeft = herdWest + Map.Rand(herdSlideRange, "Herds, West Boundary - Great Plains Lua")
		local herdRight = herdEast - Map.Rand(herdSlideRange, "Herds, East Boundary - Great Plains Lua")
		for x = herdLeft, herdRight do
			-- Fractalized placement of herds
			local plot = Map.GetPlot(x, y)
			if plot:IsWater() or plot:IsMountain() or plot:GetFeatureType() == FeatureTypes.FEATURE_OASIS then
				-- No buffalo at the water hole, sorry!
			elseif plot:GetResourceType(-1) == -1 then
				local herdVal = herds:GetHeight(x, y)
				if ((herdVal >= iHerdsBottom1 and herdVal <= iHerdsTop1) or (herdVal >= iHerdsBottom2 and herdVal <= iHerdsTop2)) then
					plot:SetResourceType(self.cow_ID, 1);
				end
			end
		end
	end
	-- Extra Cows are all done now. Mooooooooo!
	-- Can you say "Holy Cow"? =)

	local resources_to_place = {
	{self.cow_ID, 1, 100, 1, 2} };
	self:ProcessResourceList(39, 3, self.plains_flat_no_feature, resources_to_place)

	local resources_to_place = {
	{self.wheat_ID, 1, 100, 0, 2} };
	self:ProcessResourceList(13, 3, self.desert_wheat_list, resources_to_place)

	local resources_to_place = {
	{self.wheat_ID, 1, 100, 0, 2} };
	self:ProcessResourceList(37, 3, self.plains_flat_no_feature, resources_to_place)

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
	print("Creating start plot database (MapGenerator.Lua)");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions (Lua Inland Sea)");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = 1,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations (MapGenerator.Lua)");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players (MapGenerator.Lua)");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders (MapGenerator.Lua)");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States (MapGenerator.Lua)");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function DetermineContinents()
	-- Setting all continental art to America style.
	for i, plot in Plots() do
		if plot:IsWater() then
			plot:SetContinentArtType(0);
		else
			plot:SetContinentArtType(1);
		end
	end
end
-------------------------------------------------------------------------------
