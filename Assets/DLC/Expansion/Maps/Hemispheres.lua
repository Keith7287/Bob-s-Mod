------------------------------------------------------------------------------
--	FILE:	 Hemispheres.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Global map script - Two evenly matched continental hemispheres.
------------------------------------------------------------------------------
--	Copyright (c) 2012 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("FeatureGenerator");
include("TerrainGenerator");
include("IslandMaker");
include("MapmakerUtilities");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_MAP_HEMISPHERES",
		Description = "TXT_KEY_MAP_HEMISPHERES_HELP",
		IsAdvancedMap = false,
		IconIndex = 1,
		SortIndex = 2,
		CustomOptions = {world_age, temperature, rainfall, 
			{
				Name = "TXT_KEY_MAP_OPTION_RESOURCES",	-- Customizing the Resource setting to Default to Strategic Balance.
				Values = {
					{"TXT_KEY_MAP_OPTION_SPARSE"},
					{"TXT_KEY_MAP_OPTION_STANDARD"},
					{"TXT_KEY_MAP_OPTION_ABUNDANT"},
					{"TXT_KEY_MAP_OPTION_LEGENDARY_START"},
					{"TXT_KEY_MAP_OPTION_STRATEGIC_BALANCE"},
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 5,
				SortPriority = -95,
			},
			{
				Name = "TXT_KEY_MAP_OPTION_TINY_ISLANDS",
				Values = {
					{"TXT_KEY_MAP_OPTION_NO_TINY_ISLANDS"},
					{"TXT_KEY_MAP_OPTION_FEW_TINY_ISLANDS"},
					{"TXT_KEY_MAP_OPTION_VARIOUS_TINY_ISLANDS"},
					{"TXT_KEY_MAP_OPTION_MANY_TINY_ISLANDS"},
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 3,
				SortPriority = 1,
			},
			{
				Name = "TXT_KEY_MAP_OPTION_TEAM_SETTING",
				Values = {
					{"TXT_KEY_MAP_OPTION_START_TOGETHER"},
					{"TXT_KEY_MAP_OPTION_START_ANYWHERE"},
				},
				DefaultValue = 1,
				SortPriority = 2,
			},
		},
	}
end
------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {30, 24},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {50, 40},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {60, 48},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {80, 56},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {100, 64},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {120, 80}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if (world ~= nil) then
		return {
			Width = grid_size[1],
			Height = grid_size[2],
			WrapX = true,
		}; 
	end     
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Hemispheres uses the MultilayeredFractal for plot generation.
------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- The following regions are specific to Hemispheres.
	local wWestLon = 0.05;
	local wEastLon = 0.45;
	local eWestLon = 0.55;
	local eEastLon = 0.95;
	local NorthLat = 0.9;
	local SouthLat = 0.1;

	-- Set up variables that depend on world size.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 5
		}
	local archGrain = worldsizes[Map.GetWorldSize()];
	local water = 61;
	
	-- Western Hemisphere
	local wWestX = math.floor(self.iW * wWestLon);
	local wEastX = math.floor(self.iW * wEastLon);
	local NorthY = math.floor(self.iH * NorthLat);
	local SouthY = math.floor(self.iH * SouthLat);
	local cWidth = wEastX - wWestX + 1;
	local cHeight = NorthY - SouthY + 1;
	-- Eastern
	local eWestX = math.floor(self.iW * eWestLon);
	local eEastX = math.floor(self.iW * eEastLon);
			
	-- Region's parameters. Any lines commented out are running defaults.
	local args = {};
	args.iWaterPercent = water;
	args.iRegionWidth = cWidth;
	args.iRegionHeight = cHeight;
	args.iRegionWestX = wWestX;
	args.iRegionSouthY = SouthY;
	--args.iRegionGrain
	args.iRegionHillsGrain = archGrain;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 6;
	--args.iRiftGrain
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)

	local args = {};
	args.iWaterPercent = water;
	args.iRegionWidth = cWidth;
	args.iRegionHeight = cHeight;
	args.iRegionWestX = eWestX;
	args.iRegionSouthY = SouthY;
	--args.iRegionGrain
	args.iRegionHillsGrain = archGrain;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 6;
	--args.iRiftGrain
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)

	-- All regions have been processed. Now apply hills and mountains.
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local args = {
		world_age = world_age,
		adjust_plates = 1.35,
		tectonic_islands = true,
	};
	self:ApplyTectonics(args)


	-- Add randomly generated island groups, if called for
	local island_setting = Map.GetCustomOption(5)
	if island_setting == 5 then
		island_setting = 1 + Map.Rand(4, "Random Temperature - Lua");
	end
	if island_setting == 1 then -- No tiny islands!
		return self.wholeworldPlotTypes
	end
	local ratio_table = {0, 0.25, 0.5, 0.75};
	local fCellTargetRatio = ratio_table[island_setting];

	-- Now we begin to add the island chains.
	-- A cell system will be used to combine fractal land chunks with randomly generated island groups.
	-- Define the cell traits. (These need to fit correctly with the map grid width and height.)
	local iW, iH = Map.GetGridSize();
	local iCellWidth = 10;
	local iCellHeight = 8;
	local iNumCellColumns = math.floor(iW / iCellWidth);
	local iNumCellRows = math.floor(iH / iCellHeight);
	local iNumTotalCells = iNumCellColumns * iNumCellRows;
	local cell_data = table.fill(false, iNumTotalCells) -- Stores data on map cells in use. All cells begin as empty.
	local iNumCellsInUse = 0;
	local iNumCellTarget = math.floor(iNumTotalCells * fCellTargetRatio);
	local island_chain_PlotTypes = table.fill(PlotTypes.PLOT_OCEAN, iW * iH);
	local iNumGroups = iNumCellTarget; -- Should virtually never use all the groups.
	for group = 1, iNumGroups do
		if iNumCellsInUse >= iNumCellTarget then -- Map has reeached desired island population.
			print("-"); print("** Number of Island Groups produced:", group - 1); print("-");
			break
		end
		--[[ Formation Chart
		1. Single Cell, Axis Only
		2. Double Cell, Horizontal, Axis Only
		3. Single Cell With Dots
		4. Double Cell, Horizontal, With Shifted Dots
		5. Double Cell, Vertical, Axis Only
		6. Double Cell, Vertical, With Shifted Dots
		7. Triple Cell, Vertical, With Double Dots
		8. Square of Cells 2x2 With Double Dots
		9. Rectangle 3x2 With Double Dots
		10. Rectangle 2x3 With Double Dots ]]--
		--
		-- Choose a formation
		local rate_threshold = {};
		local total_appearance_rate, iNumFormations = 0, 0;
		local appearance_rates = { -- These numbers are relative to one another. No specific target total is necessary.
			7, -- #1
			3, -- #2
			15, --#3
			8, -- #4
			3, -- #5
			6, -- #6
			4, -- #7
			6, -- #8
			4, -- #9
			3, -- #10
		};
		for i, rate in ipairs(appearance_rates) do
			total_appearance_rate = total_appearance_rate + rate;
			iNumFormations = iNumFormations + 1;
		end
		local accumulated_rate = 0;
		for index = 1, iNumFormations do
			local threshold = (appearance_rates[index] + accumulated_rate) * 10000 / total_appearance_rate;
			table.insert(rate_threshold, threshold);
			accumulated_rate = accumulated_rate + appearance_rates[index];
		end
		local formation_type;
		local diceroll = Map.Rand(10000, "Choose formation type - Island Making - Lua");
		for index, threshold in ipairs(rate_threshold) do
			if diceroll <= threshold then -- Choose this formation type.
				formation_type = index;
				break
			end
		end
		-- Choose cell(s) not in use;
		local iNumAttemptsToFindOpenCells = 0;
		local found_unoccupied_cell = false;
		local anchor_cell, cell_x, cell_y, foo;
		while found_unoccupied_cell == false do
			if iNumAttemptsToFindOpenCells > 100 then -- Too many attempts on this pass. Might not be any valid locations for this formation.
				print("-"); print("*-* ALERT! Formation type of", formation_type, "for island group#", group, "unable to find an open space. Switching to single-cell.");
				formation_type = 3; -- Reset formation type.
				iNumAttemptsToFindOpenCells = 0;
			end
			local diceroll = 1 + Map.Rand(iNumTotalCells, "Choosing a cell for an island group - Polynesia LUA");
			if cell_data[diceroll] == false then -- Anchor cell is unoccupied.
				-- If formation type is multiple-cell, all secondary cells must also be unoccupied.
				if formation_type == 1 or formation_type == 3 then -- single cell, proceed.
					anchor_cell = diceroll;
					found_unoccupied_cell = true;
				elseif formation_type == 2 or formation_type == 4 then -- double cell, horizontal.
					-- Check to see if anchor cell is in the final column. If so, reject.
					cell_x = math.fmod(diceroll, iNumCellColumns);
					if cell_x ~= 0 then -- Anchor cell is valid, but still have to check adjacent cell.
						if cell_data[diceroll + 1] == false then -- Adjacent cell is unoccupied.
							anchor_cell = diceroll;
							found_unoccupied_cell = true;
						end
					end
				elseif formation_type == 5 or formation_type == 6 then -- double cell, vertical.
					-- Check to see if anchor cell is in the final row. If so, reject.
					cell_y, foo = math.modf(diceroll / iNumCellColumns);
					cell_y = cell_y + 1;
					if cell_y < iNumCellRows then -- Anchor cell is valid, but still have to check cell above it.
						if cell_data[diceroll + iNumCellColumns] == false then -- Adjacent cell is unoccupied.
							anchor_cell = diceroll;
							found_unoccupied_cell = true;
						end
					end
				elseif formation_type == 7 then -- triple cell, vertical.
					-- Check to see if anchor cell is in the northern two rows. If so, reject.
					cell_y, foo = math.modf(diceroll / iNumCellColumns);
					cell_y = cell_y + 1;
					if cell_y < iNumCellRows - 1 then -- Anchor cell is valid, but still have to check cells above it.
						if cell_data[diceroll + iNumCellColumns] == false then -- Cell directly above is unoccupied.
							if cell_data[diceroll + (iNumCellColumns * 2)] == false then -- Cell two rows above is unoccupied.
								anchor_cell = diceroll;
								found_unoccupied_cell = true;
							end
						end
					end
				elseif formation_type == 8 then -- square, 2x2.
					-- Check to see if anchor cell is in the final row or column. If so, reject.
					cell_x = math.fmod(diceroll, iNumCellColumns);
					if cell_x ~= 0 then
						cell_y, foo = math.modf(diceroll / iNumCellColumns);
						cell_y = cell_y + 1;
						if cell_y < iNumCellRows then -- Anchor cell is valid. Still have to check the other three cells.
							if cell_data[diceroll + iNumCellColumns] == false then
								if cell_data[diceroll + 1] == false then
									if cell_data[diceroll + iNumCellColumns + 1] == false then -- All cells are open.
										anchor_cell = diceroll;
										found_unoccupied_cell = true;
									end
								end
							end
						end
					end
				elseif formation_type == 9 then -- horizontal, 3x2.
					-- Check to see if anchor cell is too near to an edge. If so, reject.
					cell_x = math.fmod(diceroll, iNumCellColumns);
					if cell_x ~= 0 and cell_x ~= iNumCellColumns - 1 then
						cell_y, foo = math.modf(diceroll / iNumCellColumns);
						cell_y = cell_y + 1;
						if cell_y < iNumCellRows then -- Anchor cell is valid. Still have to check the other cells.
							if cell_data[diceroll + iNumCellColumns] == false then
								if cell_data[diceroll + 1] == false and cell_data[diceroll + 2] == false then
									if cell_data[diceroll + iNumCellColumns + 1] == false then
										if cell_data[diceroll + iNumCellColumns + 2] == false then -- All cells are open.
											anchor_cell = diceroll;
											found_unoccupied_cell = true;
										end
									end
								end
							end
						end
					end
				elseif formation_type == 10 then -- vertical, 2x3.
					-- Check to see if anchor cell is too near to an edge. If so, reject.
					cell_x = math.fmod(diceroll, iNumCellColumns);
					if cell_x ~= 0 then
						cell_y, foo = math.modf(diceroll / iNumCellColumns);
						cell_y = cell_y + 1;
						if cell_y < iNumCellRows - 1 then -- Anchor cell is valid. Still have to check the other cells.
							if cell_data[diceroll + iNumCellColumns] == false then
								if cell_data[diceroll + 1] == false then
									if cell_data[diceroll + iNumCellColumns + 1] == false then
										if cell_data[diceroll + (iNumCellColumns * 2)] == false then
											if cell_data[diceroll + (iNumCellColumns * 2) + 1] == false then -- All cells are open.
												anchor_cell = diceroll;
												found_unoccupied_cell = true;
											end
										end
									end
								end
							end
						end
					end
				end
			end
			iNumAttemptsToFindOpenCells = iNumAttemptsToFindOpenCells + 1;
		end
		-- Find Cell X and Y
		cell_x = math.fmod(anchor_cell, iNumCellColumns);
		if cell_x == 0 then
			cell_x = iNumCellColumns;
		end
		cell_y, foo = math.modf(anchor_cell / iNumCellColumns);
		cell_y = cell_y + 1;
		
		-- Debug
		print("-"); print("-"); print("* Group# " .. group, "Formation Type: " .. formation_type, "Cell X, Y: " .. cell_x .. ", " .. cell_y);

		-- Create this island group.
		local iWidth, iHeight, fTilt; -- Scope the variables needed for island group creation.
		local plot_data = {};
		local x_shift, y_shift;
		if formation_type == 1 then -- single cell
			local x_shrinkage = Map.Rand(4, "Cell Width adjustment - Lua");
			if x_shrinkage > 2 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(5, "Cell Height adjustment - Lua");
			if y_shrinkage > 2 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth - x_shrinkage;
			iHeight = iCellHeight - y_shrinkage;
			fTilt = Map.Rand(181, "Angle for island chain axis - LUA");
			plot_data = CreateSingleAxisIslandChain(iWidth, iHeight, fTilt)

		elseif formation_type == 2 then -- two cells, horizontal
			local x_shrinkage = Map.Rand(8, "Cell Width adjustment - Lua");
			if x_shrinkage > 5 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(5, "Cell Height adjustment - Lua");
			if y_shrinkage > 2 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth * 2 - x_shrinkage;
			iHeight = iCellHeight - y_shrinkage;
			-- Limit angles to mostly horizontal ones.
			fTilt = 145 + Map.Rand(90, "Angle for island chain axis - LUA");
			if fTilt > 180 then
				fTilt = fTilt - 180;
			end
			plot_data = CreateSingleAxisIslandChain(iWidth, iHeight, fTilt)
			
		elseif formation_type == 3 then -- single cell, with dots
			local x_shrinkage = Map.Rand(4, "Cell Width adjustment - Lua");
			if x_shrinkage > 2 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(5, "Cell Height adjustment - Lua");
			if y_shrinkage > 2 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth - x_shrinkage;
			iHeight = iCellHeight - y_shrinkage;
			fTilt = Map.Rand(181, "Angle for island chain axis - LUA");
			-- Determine "dot box"
			local iInnerWidth, iInnerHeight = iWidth - 2, iHeight - 2;
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(8, "Diceroll - Lua");
			local iNumDots = 4;
			if die_1 + die_2 > 1 then
				iNumDots = iNumDots + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots = iNumDots + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithDots(iWidth, iHeight, fTilt, iInnerWidth, iInnerHeight, iNumDots)

		elseif formation_type == 4 then -- two cells, horizontal, with dots
			local x_shrinkage = Map.Rand(8, "Cell Width adjustment - Lua");
			if x_shrinkage > 5 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(5, "Cell Height adjustment - Lua");
			if y_shrinkage > 2 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth * 2 - x_shrinkage;
			iHeight = iCellHeight - y_shrinkage;
			-- Limit angles to mostly horizontal ones.
			fTilt = 145 + Map.Rand(90, "Angle for island chain axis - LUA");
			if fTilt > 180 then
				fTilt = fTilt - 180;
			end
			-- Determine "dot box"
			local iInnerWidth = math.floor(iWidth / 2);
			local iInnerHeight = iHeight - 2;
			local iInnerWest = 2 + Map.Rand((iWidth - 1) - iInnerWidth, "Shift for sub island group - Lua");
			local iInnerSouth = 2;
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(10, "Diceroll - Lua");
			local iNumDots = 5;
			if die_1 + die_2 > 1 then
				iNumDots = iNumDots + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots = iNumDots + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithShiftedDots(iWidth, iHeight, fTilt, iInnerWidth, iInnerHeight, iInnerWest, iInnerSouth, iNumDots)
			
		elseif formation_type == 5 then -- Double Cell, Vertical, Axis Only
			local x_shrinkage = Map.Rand(5, "Cell Width adjustment - Lua");
			if x_shrinkage > 2 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(7, "Cell Height adjustment - Lua");
			if y_shrinkage > 4 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth - x_shrinkage;
			iHeight = iCellHeight * 2 - y_shrinkage;
			-- Limit angles to mostly vertical ones.
			fTilt = 55 + Map.Rand(71, "Angle for island chain axis - LUA");
			plot_data = CreateSingleAxisIslandChain(iWidth, iHeight, fTilt)
		
		elseif formation_type == 6 then -- Double Cell, Vertical With Dots
			local x_shrinkage = Map.Rand(5, "Cell Width adjustment - Lua");
			if x_shrinkage > 2 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(7, "Cell Height adjustment - Lua");
			if y_shrinkage > 4 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth - x_shrinkage;
			iHeight = iCellHeight * 2 - y_shrinkage;
			-- Limit angles to mostly vertical ones.
			fTilt = 55 + Map.Rand(71, "Angle for island chain axis - LUA");
			-- Determine "dot box"
			local iInnerWidth = iWidth - 2;
			local iInnerHeight = math.floor(iHeight / 2);
			local iInnerWest = 2;
			local iInnerSouth = 2 + Map.Rand((iHeight - 1) - iInnerHeight, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(10, "Diceroll - Lua");
			local iNumDots = 5;
			if die_1 + die_2 > 1 then
				iNumDots = iNumDots + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots = iNumDots + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithShiftedDots(iWidth, iHeight, fTilt, iInnerWidth, iInnerHeight, iInnerWest, iInnerSouth, iNumDots)
		
		elseif formation_type == 7 then -- Triple Cell, Vertical With Double Dots
			local x_shrinkage = Map.Rand(4, "Cell Width adjustment - Lua");
			if x_shrinkage > 1 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(9, "Cell Height adjustment - Lua");
			if y_shrinkage > 5 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth - x_shrinkage;
			iHeight = iCellHeight * 3 - y_shrinkage;
			-- Limit angles to steep ones.
			fTilt = 70 + Map.Rand(41, "Angle for island chain axis - LUA");
			-- Handle Dots Group 1.
			local iInnerWidth1 = iWidth - 3;
			local iInnerHeight1 = iCellHeight - 1;
			local iInnerWest1 = 2 + Map.Rand(2, "Shift for sub island group - Lua");
			local iInnerSouth1 = 2 + Map.Rand(iCellHeight - 3, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(8, "Diceroll - Lua");
			local iNumDots1 = 4;
			if die_1 + die_2 > 1 then
				iNumDots1 = iNumDots1 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots1 = iNumDots1 + die_1 + die_2;
			end
			-- Handle Dots Group 2.
			local iInnerWidth2 = iWidth - 3;
			local iInnerHeight2 = iCellHeight - 1;
			local iInnerWest2 = 2 + Map.Rand(2, "Shift for sub island group - Lua");
			local iInnerSouth2 = iCellHeight + 2 + Map.Rand(iCellHeight - 3, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(8, "Diceroll - Lua");
			local iNumDots2 = 4;
			if die_1 + die_2 > 1 then
				iNumDots2 = iNumDots2 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots2 = iNumDots2 + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithDoubleDots(iWidth, iHeight, fTilt, iInnerWidth1, iInnerHeight1, iInnerWest1, iInnerSouth1,
                                                      iNumDots1, iInnerWidth2, iInnerHeight2, iInnerWest2, iInnerSouth2, iNumDots2)
		elseif formation_type == 8 then -- Square Block 2x2 With Double Dots
			local x_shrinkage = Map.Rand(6, "Cell Width adjustment - Lua");
			if x_shrinkage > 4 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(5, "Cell Height adjustment - Lua");
			if y_shrinkage > 3 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth * 2 - x_shrinkage;
			iHeight = iCellHeight * 2 - y_shrinkage;
			-- Full range of angles
			fTilt = Map.Rand(181, "Angle for island chain axis - LUA");
			-- Handle Dots Group 1.
			local iInnerWidth1 = iCellWidth - 2;
			local iInnerHeight1 = iCellHeight - 2;
			local iInnerWest1 = 3 + Map.Rand(iCellWidth - 2, "Shift for sub island group - Lua");
			local iInnerSouth1 = 3 + Map.Rand(iCellHeight - 2, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(6, "Diceroll - Lua");
			local die_2 = Map.Rand(10, "Diceroll - Lua");
			local iNumDots1 = 5;
			if die_1 + die_2 > 1 then
				iNumDots1 = iNumDots1 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots1 = iNumDots1 + die_1 + die_2;
			end
			-- Handle Dots Group 2.
			local iInnerWidth2 = iCellWidth - 2;
			local iInnerHeight2 = iCellHeight - 2;
			local iInnerWest2 = 3 + Map.Rand(iCellWidth - 2, "Shift for sub island group - Lua");
			local iInnerSouth2 = 3 + Map.Rand(iCellHeight - 2, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(8, "Diceroll - Lua");
			local iNumDots2 = 5;
			if die_1 + die_2 > 1 then
				iNumDots2 = iNumDots2 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots2 = iNumDots2 + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithDoubleDots(iWidth, iHeight, fTilt, iInnerWidth1, iInnerHeight1, iInnerWest1, iInnerSouth1,
                                                      iNumDots1, iInnerWidth2, iInnerHeight2, iInnerWest2, iInnerSouth2, iNumDots2)

		elseif formation_type == 9 then -- Horizontal Block 3x2 With Double Dots
			local x_shrinkage = Map.Rand(8, "Cell Width adjustment - Lua");
			if x_shrinkage > 5 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(5, "Cell Height adjustment - Lua");
			if y_shrinkage > 3 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth * 3 - x_shrinkage;
			iHeight = iCellHeight * 2 - y_shrinkage;
			-- Limit angles to mostly horizontal ones.
			fTilt = 145 + Map.Rand(90, "Angle for island chain axis - LUA");
			if fTilt > 180 then
				fTilt = fTilt - 180;
			end
			-- Handle Dots Group 1.
			local iInnerWidth1 = iCellWidth;
			local iInnerHeight1 = iCellHeight - 2;
			local iInnerWest1 = 4 + Map.Rand(iCellWidth + 2, "Shift for sub island group - Lua");
			local iInnerSouth1 = 3 + Map.Rand(iCellHeight - 2, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(8, "Diceroll - Lua");
			local iNumDots1 = 9;
			if die_1 + die_2 > 1 then
				iNumDots1 = iNumDots1 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots1 = iNumDots1 + die_1 + die_2;
			end
			-- Handle Dots Group 2.
			local iInnerWidth2 = iCellWidth;
			local iInnerHeight2 = iCellHeight - 2;
			local iInnerWest2 = 4 + Map.Rand(iCellWidth + 2, "Shift for sub island group - Lua");
			local iInnerSouth2 = 3 + Map.Rand(iCellHeight - 2, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(5, "Diceroll - Lua");
			local die_2 = Map.Rand(7, "Diceroll - Lua");
			local iNumDots2 = 8;
			if die_1 + die_2 > 1 then
				iNumDots2 = iNumDots2 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots2 = iNumDots2 + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithDoubleDots(iWidth, iHeight, fTilt, iInnerWidth1, iInnerHeight1, iInnerWest1, iInnerSouth1,
                                                      iNumDots1, iInnerWidth2, iInnerHeight2, iInnerWest2, iInnerSouth2, iNumDots2)

		elseif formation_type == 10 then -- Vertical Block 2x3 With Double Dots
			local x_shrinkage = Map.Rand(6, "Cell Width adjustment - Lua");
			if x_shrinkage > 4 then
				x_shrinkage = 0;
			end
			local y_shrinkage = Map.Rand(8, "Cell Height adjustment - Lua");
			if y_shrinkage > 5 then
				y_shrinkage = 0;
			end
			x_shift, y_shift = 0, 0;
			if x_shrinkage > 0 then
				x_shift = Map.Rand(x_shrinkage, "Cell Width offset - Lua");
			end
			if y_shrinkage > 0 then
				y_shift = Map.Rand(y_shrinkage, "Cell Height offset - Lua");
			end
			iWidth = iCellWidth * 2 - x_shrinkage;
			iHeight = iCellHeight * 3 - y_shrinkage;
			-- Mostly vertical
			fTilt = 55 + Map.Rand(71, "Angle for island chain axis - LUA");
			-- Handle Dots Group 1.
			local iInnerWidth1 = iCellWidth - 2;
			local iInnerHeight1 = iCellHeight;
			local iInnerWest1 = 3 + Map.Rand(iCellWidth - 2, "Shift for sub island group - Lua");
			local iInnerSouth1 = 4 + Map.Rand(iCellHeight + 2, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(10, "Diceroll - Lua");
			local iNumDots1 = 8;
			if die_1 + die_2 > 1 then
				iNumDots1 = iNumDots1 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots1 = iNumDots1 + die_1 + die_2;
			end
			-- Handle Dots Group 2.
			local iInnerWidth2 = iCellWidth - 2;
			local iInnerHeight2 = iCellHeight;
			local iInnerWest2 = 3 + Map.Rand(iCellWidth - 2, "Shift for sub island group - Lua");
			local iInnerSouth2 = 4 + Map.Rand(iCellHeight + 2, "Shift for sub island group - Lua");
			-- Determine number of dots
			local die_1 = Map.Rand(4, "Diceroll - Lua");
			local die_2 = Map.Rand(8, "Diceroll - Lua");
			local iNumDots2 = 7;
			if die_1 + die_2 > 1 then
				iNumDots2 = iNumDots2 + Map.Rand(die_1 + die_2, "Number of dots to add to island chain - Lua");
			else
				iNumDots2 = iNumDots2 + die_1 + die_2;
			end
			plot_data = CreateAxisChainWithDoubleDots(iWidth, iHeight, fTilt, iInnerWidth1, iInnerHeight1, iInnerWest1, iInnerSouth1,
                                                      iNumDots1, iInnerWidth2, iInnerHeight2, iInnerWest2, iInnerSouth2, iNumDots2)
		end

		-- Obtain land plots from the plot data
		local x_adjust = (cell_x - 1) * iCellWidth + x_shift;
		local y_adjust = (cell_y - 1) * iCellHeight + y_shift;
		for y = 1, iHeight do
			for x = 1, iWidth do
				local data_index = (y - 1) * iWidth + x;
				if plot_data[data_index] == true then -- This plot is land.
					local real_x, real_y = x + x_adjust - 1, y + y_adjust - 1;
					local plot_index = real_y * iW + real_x + 1;
					island_chain_PlotTypes[plot_index] = PlotTypes.PLOT_LAND;
				end
			end
		end
		
		-- Record cells in use
		if formation_type == 1 then -- single cell
			cell_data[anchor_cell] = true;
			iNumCellsInUse = iNumCellsInUse + 1;
		elseif formation_type == 2 then
			cell_data[anchor_cell], cell_data[anchor_cell + 1] = true, true;
			iNumCellsInUse = iNumCellsInUse + 2;
		elseif formation_type == 3 then
			cell_data[anchor_cell] = true;
			iNumCellsInUse = iNumCellsInUse + 1;
		elseif formation_type == 4 then
			cell_data[anchor_cell], cell_data[anchor_cell + 1] = true, true;
			iNumCellsInUse = iNumCellsInUse + 2;
		elseif formation_type == 5 then
			cell_data[anchor_cell], cell_data[anchor_cell + iNumCellColumns] = true, true;
			iNumCellsInUse = iNumCellsInUse + 2;
		elseif formation_type == 6 then
			cell_data[anchor_cell], cell_data[anchor_cell + iNumCellColumns] = true, true;
			iNumCellsInUse = iNumCellsInUse + 2;
		elseif formation_type == 7 then
			cell_data[anchor_cell], cell_data[anchor_cell + iNumCellColumns] = true, true;
			cell_data[anchor_cell + (iNumCellColumns * 2)] = true;
			iNumCellsInUse = iNumCellsInUse + 3;
		elseif formation_type == 8 then
			cell_data[anchor_cell], cell_data[anchor_cell + 1] = true, true;
			cell_data[anchor_cell + iNumCellColumns], cell_data[anchor_cell + iNumCellColumns + 1] = true, true;
			iNumCellsInUse = iNumCellsInUse + 4;
		elseif formation_type == 9 then
			cell_data[anchor_cell], cell_data[anchor_cell + 1] = true, true;
			cell_data[anchor_cell + iNumCellColumns], cell_data[anchor_cell + iNumCellColumns + 1] = true, true;
			cell_data[anchor_cell + 2], cell_data[anchor_cell + iNumCellColumns + 2] = true, true;
			iNumCellsInUse = iNumCellsInUse + 6;
		elseif formation_type == 10 then
			cell_data[anchor_cell], cell_data[anchor_cell + 1] = true, true;
			cell_data[anchor_cell + iNumCellColumns], cell_data[anchor_cell + iNumCellColumns + 1] = true, true;
			cell_data[anchor_cell + (iNumCellColumns * 2)], cell_data[anchor_cell + (iNumCellColumns * 2) + 1] = true, true;
			iNumCellsInUse = iNumCellsInUse + 6;
		end
	end
	
	-- Debug check of cell occupation.
	print("- - -");
	for loop = iNumCellRows, 1, -1 do
		local c = (loop - 1) * iNumCellColumns;
		local stringdata = {};
		for innerloop = 1, iNumCellColumns do
			if cell_data[c + innerloop] == false then
				stringdata[innerloop] = "false";
			else
				stringdata[innerloop] = "true ";
			end
		end
		print("Row: ", table.concat(stringdata));
	end
	--
	
	-- Add Hills and Peaks to randomly generated islands.
	local regionHillsFrac = Fractal.Create(iW, iH, 5, {}, 7, 7);
	local regionPeaksFrac = Fractal.Create(iW, iH, 6, {}, 7, 7);
	local iHillsBottom1 = regionHillsFrac:GetHeight(20);
	local iHillsTop1 = regionHillsFrac:GetHeight(35);
	local iHillsBottom2 = regionHillsFrac:GetHeight(65);
	local iHillsTop2 = regionHillsFrac:GetHeight(80);
	local iPeakThreshold = regionPeaksFrac:GetHeight(80);
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			if island_chain_PlotTypes[i] ~= PlotTypes.PLOT_OCEAN then
				local hillVal = regionHillsFrac:GetHeight(x,y);
				if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
					local peakVal = regionPeaksFrac:GetHeight(x,y);
					if (peakVal >= iPeakThreshold) then
						island_chain_PlotTypes[i] = PlotTypes.PLOT_MOUNTAIN
					else
						island_chain_PlotTypes[i] = PlotTypes.PLOT_HILLS
					end
				end
			end
		end
	end
	
	-- Apply island data to the map.
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			if island_chain_PlotTypes[i] ~= PlotTypes.PLOT_OCEAN then
				self.wholeworldPlotTypes[i] = island_chain_PlotTypes[i];
			end
		end
	end

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------

--[[ ----------------------------------------------
Regional Variables Key:

iWaterPercent,				DEFAULT: 55
iRegionWidth,				MANDATORY (no default)
iRegionHeight,				MANDATORY (no default)
iRegionWestX,				MANDATORY (no default)
iRegionSouthY,				MANDATORY (no default)
iRegionGrain,				DEFAULT: 1
iRegionHillsGrain,			DEFAULT: 3
iRegionPlotFlags,			DEFAULT: iRoundFlags
iRegionFracXExp,			DEFAULT: 6
iRegionFracYExp,			DEFAULT: 5
iRiftGrain,					DEFAULT: -1 (no rifts)
bShift,						DEFAULT: true
---------------------------------------------- ]]--

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Hemispheres) ...");

	local layered_world = MultilayeredFractal.Create();
	local plotsHemi = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(plotsHemi);
	GenerateCoasts()
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Hemispheres) ...");
	
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
	print("Adding Features (Lua Hemispheres) ...");

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

------------------------------------------------------------------------------
function AssignStartingPlots:GenerateRegions(args)
	print("Map Generation - Dividing the map in to Regions");
	-- This is a customized version for West vs East - Reused for Hemispheres.
	-- This version is tailored for handling two-teams play.
	local args = args or {};
	local iW, iH = Map.GetGridSize();
	self.method = 3; -- Flag the map as using a Rectangular division method.

	-- Determine number of civilizations and city states present in this game.
	self.iNumCivs, self.iNumCityStates, self.player_ID_list, self.bTeamGame, self.teams_with_major_civs, self.number_civs_per_team = GetPlayerAndTeamInfo()
	self.iNumCityStatesUnassigned = self.iNumCityStates;
	print("-"); print("Civs:", self.iNumCivs); print("City States:", self.iNumCityStates);

	-- Determine number of teams (of Major Civs only, not City States) present in this game.
	iNumTeams = table.maxn(self.teams_with_major_civs);				-- GLOBAL
	print("-"); print("Teams:", iNumTeams);

	-- Fetch team setting.
	local team_setting = Map.GetCustomOption(6)
	print("Team Setting: ", team_setting);

	-- If two teams are present, use team-oriented handling of start points, one team west, one east.
	if iNumTeams == 2 and team_setting == 1 then
		print("-"); print("Number of Teams present is two! Using custom team start placement for West vs East."); print("-");
		
		-- ToDo: Correctly identify team IDs and how many Civs are on each team.
		-- Also need to shuffle the teams so its random who starts on which half.
		local shuffled_team_list = GetShuffledCopyOfTable(self.teams_with_major_civs)
		teamWestID = shuffled_team_list[1];							-- GLOBAL
		teamEastID = shuffled_team_list[2]; 						-- GLOBAL
		iNumCivsInWest = self.number_civs_per_team[teamWestID];		-- GLOBAL
		iNumCivsInEast = self.number_civs_per_team[teamEastID];		-- GLOBAL
		print("West Team #: ", teamWestID);
		print("East Team #: ", teamEastID);
		print("Player Count for West: ", iNumCivsInWest);
		print("Player Count for East: ", iNumCivsInEast);

		-- Process the team in the west.
		self.inhabited_WestX = 0;
		self.inhabited_SouthY = 0;
		self.inhabited_Width = math.floor(iW / 2) - 1;
		self.inhabited_Height = iH;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumCivsInWest, fert_table, rect_table)

		-- Process the team in the east.
		self.inhabited_WestX = math.floor(iW / 2) + 1;
		self.inhabited_SouthY = 0;
		self.inhabited_Width = math.floor(iW / 2) - 1;
		self.inhabited_Height = iH;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumCivsInEast, fert_table, rect_table)
		-- The regions have been defined.

	-- If number of teams is any number other than two, use standard division.
	else	
		print("-"); print("Dividing the map at random."); print("-");
		self.method = 2;	
		local best_areas = {};
		local globalFertilityOfLands = {};

		-- Obtain info on all landmasses for comparision purposes.
		local iGlobalFertilityOfLands = 0;
		local iNumLandPlots = 0;
		local iNumLandAreas = 0;
		local land_area_IDs = {};
		local land_area_plots = {};
		local land_area_fert = {};
		-- Cycle through all plots in the world, checking their Start Placement Fertility and AreaID.
		for x = 0, iW - 1 do
			for y = 0, iH - 1 do
				local i = y * iW + x + 1;
				local plot = Map.GetPlot(x, y);
				if not plot:IsWater() then -- Land plot, process it.
					iNumLandPlots = iNumLandPlots + 1;
					local iArea = plot:GetArea();
					local plotFertility = self:MeasureStartPlacementFertilityOfPlot(x, y, true); -- Check for coastal land is enabled.
					iGlobalFertilityOfLands = iGlobalFertilityOfLands + plotFertility;
					--
					if TestMembership(land_area_IDs, iArea) == false then -- This plot is the first detected in its AreaID.
						iNumLandAreas = iNumLandAreas + 1;
						table.insert(land_area_IDs, iArea);
						land_area_plots[iArea] = 1;
						land_area_fert[iArea] = plotFertility;
					else -- This AreaID already known.
						land_area_plots[iArea] = land_area_plots[iArea] + 1;
						land_area_fert[iArea] = land_area_fert[iArea] + plotFertility;
					end
				end
			end
		end
		
		-- Sort areas, achieving a list of AreaIDs with best areas first.
		--
		-- Fertility data in land_area_fert is stored with areaID index keys.
		-- Need to generate a version of this table with indices of 1 to n, where n is number of land areas.
		local interim_table = {};
		for loop_index, data_entry in pairs(land_area_fert) do
			table.insert(interim_table, data_entry);
		end
		-- Sort the fertility values stored in the interim table. Sort order in Lua is lowest to highest.
		table.sort(interim_table);
		-- If less players than landmasses, we will ignore the extra landmasses.
		local iNumRelevantLandAreas = math.min(iNumLandAreas, self.iNumCivs);
		-- Now re-match the AreaID numbers with their corresponding fertility values
		-- by comparing the original fertility table with the sorted interim table.
		-- During this comparison, best_areas will be constructed from sorted AreaIDs, richest stored first.
		local best_areas = {};
		-- Currently, the best yields are at the end of the interim table. We need to step backward from there.
		local end_of_interim_table = table.maxn(interim_table);
		-- We may not need all entries in the table. Process only iNumRelevantLandAreas worth of table entries.
		for areaTestLoop = end_of_interim_table, (end_of_interim_table - iNumRelevantLandAreas + 1), -1 do
			for loop_index, AreaID in ipairs(land_area_IDs) do
				if interim_table[areaTestLoop] == land_area_fert[land_area_IDs[loop_index]] then
					table.insert(best_areas, AreaID);
					table.remove(land_area_IDs, landLoop);
					break
				end
			end
		end

		-- Assign continents to receive start plots. Record number of civs assigned to each landmass.
		local inhabitedAreaIDs = {};
		local numberOfCivsPerArea = table.fill(0, iNumRelevantLandAreas); -- Indexed in synch with best_areas. Use same index to match values from each table.
		for civToAssign = 1, self.iNumCivs do
			local bestRemainingArea;
			local bestRemainingFertility = 0;
			local bestAreaTableIndex;
			-- Loop through areas, find the one with the best remaining fertility (civs added 
			-- to a landmass reduces its fertility rating for subsequent civs).
			for area_loop, AreaID in ipairs(best_areas) do
				local thisLandmassCurrentFertility = land_area_fert[AreaID] / (1 + numberOfCivsPerArea[area_loop]);
				if thisLandmassCurrentFertility > bestRemainingFertility then
					bestRemainingArea = AreaID;
					bestRemainingFertility = thisLandmassCurrentFertility;
					bestAreaTableIndex = area_loop;
				end
			end
			-- Record results for this pass. (A landmass has been assigned to receive one more start point than it previously had).
			numberOfCivsPerArea[bestAreaTableIndex] = numberOfCivsPerArea[bestAreaTableIndex] + 1;
			if TestMembership(inhabitedAreaIDs, bestRemainingArea) == false then
				table.insert(inhabitedAreaIDs, bestRemainingArea);
			end
		end
				
		-- Loop through the list of inhabited landmasses, dividing each landmass in to regions.
		-- Note that it is OK to divide a continent with one civ on it: this will assign the whole
		-- of the landmass to a single region, and is the easiest method of recording such a region.
		local iNumInhabitedLandmasses = table.maxn(inhabitedAreaIDs);
		for loop, currentLandmassID in ipairs(inhabitedAreaIDs) do
			-- Obtain the boundaries of and data for this landmass.
			local landmass_data = ObtainLandmassBoundaries(currentLandmassID);
			local iWestX = landmass_data[1];
			local iSouthY = landmass_data[2];
			local iEastX = landmass_data[3];
			local iNorthY = landmass_data[4];
			local iWidth = landmass_data[5];
			local iHeight = landmass_data[6];
			local wrapsX = landmass_data[7];
			local wrapsY = landmass_data[8];
			-- Obtain "Start Placement Fertility" of the current landmass. (Necessary to do this
			-- again because the fert_table can't be built prior to finding boundaries, and we had
			-- to ID the proper landmasses via fertility to be able to figure out their boundaries.
			local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityOfLandmass(currentLandmassID, 
		  	                                         iWestX, iEastX, iSouthY, iNorthY, wrapsX, wrapsY);
			-- Assemble the rectangle data for this landmass.
			local rect_table = {iWestX, iSouthY, iWidth, iHeight, currentLandmassID, fertCount, plotCount};
			-- Divide this landmass in to number of regions equal to civs assigned here.
			iNumCivsOnThisLandmass = numberOfCivsPerArea[loop];
			if iNumCivsOnThisLandmass > 0 and iNumCivsOnThisLandmass <= 22 then -- valid number of civs.
				self:DivideIntoRegions(iNumCivsOnThisLandmass, fert_table, rect_table)
			else
				print("Invalid number of civs assigned to a landmass: ", iNumCivsOnThisLandmass);
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:BalanceAndAssign()
	-- This function determines what level of Bonus Resource support a location
	-- may need, identifies compatibility with civ-specific biases, and places starts.

	-- Normalize each start plot location.
	local iNumStarts = table.maxn(self.startingPlots);
	for region_number = 1, iNumStarts do
		self:NormalizeStartLocation(region_number)
	end

	-- Assign Civs to start plots.
	local team_setting = Map.GetCustomOption(6)
	if iNumTeams == 2 and team_setting == 1 then
		-- Two teams, place one in the west half, other in east -- even if team membership totals are uneven.
		print("-"); print("This is a team game with two teams! Place one team in West, other in East."); print("-");
		local playerList, westList, eastList = {}, {}, {};
		for loop = 1, self.iNumCivs do
			local player_ID = self.player_ID_list[loop];
			table.insert(playerList, player_ID);
			local player = Players[player_ID];
			local team_ID = player:GetTeam()
			if team_ID == teamWestID then
				print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the West.");
				table.insert(westList, player_ID);
			elseif team_ID == teamEastID then
				print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the East.");
				table.insert(eastList, player_ID);
			else
				print("* ERROR * - Player #", player_ID, "belongs to Team #", team_ID, "which is neither West nor East!");
			end
		end
		
		-- Debug
		if table.maxn(westList) ~= iNumCivsInWest then
			print("-"); print("*** ERROR! *** . . . Mismatch between number of Civs on West team and number of civs assigned to west locations.");
		end
		if table.maxn(eastList) ~= iNumCivsInEast then
			print("-"); print("*** ERROR! *** . . . Mismatch between number of Civs on East team and number of civs assigned to east locations.");
		end
		
		local westListShuffled = GetShuffledCopyOfTable(westList)
		local eastListShuffled = GetShuffledCopyOfTable(eastList)
		for region_number, player_ID in ipairs(westListShuffled) do
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
		for loop, player_ID in ipairs(eastListShuffled) do
			local x = self.startingPlots[loop + iNumCivsInWest][1];
			local y = self.startingPlots[loop + iNumCivsInWest][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
	else
		print("-"); print("This game does not have specific start zone assignments."); print("-");
		local playerList = {};
		for loop = 1, self.iNumCivs do
			local player_ID = self.player_ID_list[loop];
			table.insert(playerList, player_ID);
		end
		local playerListShuffled = GetShuffledCopyOfTable(playerList)
		for region_number, player_ID in ipairs(playerListShuffled) do
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
		-- If this is a team game (any team has more than one Civ in it) then make 
		-- sure team members start near each other if possible. (This may scramble 
		-- Civ biases in some cases, but there is no cure).
		if self.bTeamGame == true and team_setting ~= 2 then
			print("However, this IS a team game, so we will try to group team members together."); print("-");
			self:NormalizeTeamLocations()
		end
	end
end
------------------------------------------------------------------------------
function StartPlotSystem()
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(4)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	local args = {
		resources = res,
		};
	start_plot_database:GenerateRegions()

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
