------------------------------------------------------------------------------
--	FILE:	 Small_Continents_Plus.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Global map script - Produces small continents, plus island chains.
------------------------------------------------------------------------------
--	Copyright (c) 2013 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("FeatureGenerator");
include("TerrainGenerator");
include("IslandMaker");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_CW_MAP_PACK_SMALL_CONT_PLUS",
		Description = "TXT_KEY_CW_MAP_PACK_SMALL_CONT_PLUS_DESC",
		IsAdvancedMap = 0,
		IconIndex = 1,
		SortIndex = 1,
		Folder = "MAP_FOLDER_SP_DLC_2",
		CustomOptions = {world_age, temperature, rainfall, sea_level, resources},
	};
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FractalWorld:GeneratePlotTypes(args)
	-- Note: Unlike the other "Plus" maps, this one does not force City States to the tiny islands.
	--
	-- Sea Level and World Age map options affect only plot generation.
	-- Temperature map options affect only terrain generation.
	-- Rainfall map options affect only feature generation.
	--
	local args = args or {};
	local sea_level = args.sea_level or 2; -- Default is Medium sea level.
	local world_age = args.world_age or 2; -- Default is 4 Billion Years old.
	-- Note: World Age and Sea Level settings, if applicable, must be passed in by the map script.
	--
	local sea_level_low = args.sea_level_low or 65;
	local sea_level_normal = args.sea_level_normal or 72;
	local sea_level_high = args.sea_level_high or 78;
	local world_age_old = args.world_age_old or 2;
	local world_age_normal = args.world_age_normal or 3;
	local world_age_new = args.world_age_new or 5;
	--
	local extra_mountains = args.extra_mountains or 0;
	local grain_amount = args.grain_amount or 3;
	local adjust_plates = args.adjust_plates or 1.0;
	local shift_plot_types = args.shift_plot_types or true;
	local tectonic_islands = args.tectonic_islands or false;
	local hills_ridge_flags = args.hills_ridge_flags or self.iFlags;
	local peaks_ridge_flags = args.peaks_ridge_flags or self.iFlags;
	local has_center_rift = args.has_center_rift or false;
	
	-- Set Sea Level according to user selection. - Bob
	local water_percent = sea_level_normal;
	if sea_level == 1 then -- Low Sea Level
		water_percent = sea_level_low
	elseif sea_level == 3 then -- High Sea Level
		water_percent = sea_level_high
	else -- Normal Sea Level
	end

	-- Set values for hills and mountains according to World Age chosen by user. - Bob
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
	local hillsNearMountains = 91 - (adjustment * 2) - extra_mountains;
	local mountains = 97 - adjustment - extra_mountains;

	-- Hills and Mountains handled differently according to map size - Bob
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
	-- Add in any plate count modifications passed in from the map script. - Bob
	numPlates = numPlates * adjust_plates;

	-- Generate fractals to govern hills and mountains - Bob
	self.hillsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.mountainsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);

	-- Use Brian's tectonics method to weave ridgelines in to the fractals.
	-- Without fractal variation, the tectonics come out too regular.
	--
	--[[ "The principle of the RidgeBuilder code is a modified Voronoi diagram. I 
	added some minor randomness and the slope might be a little tricky. It was 
	intended as a 'whole world' modifier to the fractal class. You can modify 
	the number of plates, but that is about it." ]]-- Brian Wade - May 23, 2009
	--
	-- Have the hills be clumpy with a bit of ridges in them - Brian
	self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
	-- Have the mountain ranges tend to be be distinct - Brian
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);

	-- Get height values for plot types
	local iWaterThreshold = self.continentsFrac:GetHeight(water_percent);
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
	
	--[[ Activate printout for debugging only.
	print("-"); print("--- Plot Generation Readout ---");
	print("- Sea Level Setting:", sea_level);
	print("- World Age Setting:", world_age);
	print("- Water Percentage:", water_percent);
	print("- Mountain Threshold:", mountains);
	print("- Foot Hills Threshold:", hillsNearMountains);
	print("- Clumps of Hills %:", hillsClumps);
	print("- Loose Hills %:", 4 * adjustment);
	print("- Tectonic Plate Count:", numPlates);
	print("- Tectonic Islands?", tectonic_islands);
	print("- Center Rift?", has_center_rift);
	print("- - - - - - - - - - - - - - - - -");
	]]--

	-- Main loop
	for x = 0, self.iNumPlotsX - 1 do
		for y = 0, self.iNumPlotsY - 1 do
		
			local i = y * self.iNumPlotsX + x + 1;
			local val = self.continentsFrac:GetHeight(x, y);
			local mountainVal = self.mountainsFrac:GetHeight(x, y);
			local hillVal = self.hillsFrac:GetHeight(x, y);
	
			if(val <= iWaterThreshold) then
				self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				
				if tectonic_islands then -- Build islands in oceans along tectonic ridge lines - Brian
					if (mountainVal == iMountain100) then -- Isolated peak in the ocean
						self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					elseif (mountainVal == iMountain99) then
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					elseif (mountainVal == iMountain97) or (mountainVal == iMountain95) then
						self.plotTypes[i] = PlotTypes.PLOT_LAND;
					end
				end
					
			else
				if (mountainVal >= iMountainThreshold) then
					if (hillVal >= iPassThreshold) then -- Mountain Pass though the ridgeline - Brian
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					else -- Mountain
						self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					end
				elseif (mountainVal >= iHillsNearMountains) then
					self.plotTypes[i] = PlotTypes.PLOT_HILLS; -- Foot hills - Bob
				else
					if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					else
						self.plotTypes[i] = PlotTypes.PLOT_LAND;
					end
				end
			end
		end
	end

	-- Now we begin to add the island chains.

	-- A cell system will be used to combine predefined land chunks with randomly generated island groups.
	-- Define the cell traits. (These need to fit correctly with the map grid width and height.)
	local iW, iH = Map.GetGridSize();
	local iCellWidth = 10;
	local iCellHeight = 8;
	local iNumCellColumns = math.floor(iW / iCellWidth);
	local iNumCellRows = math.floor(iH / iCellHeight);
	local iNumTotalCells = iNumCellColumns * iNumCellRows;
	local cell_data = table.fill(false, iNumTotalCells) -- Stores data on map cells in use. All cells begin as empty.
	local iNumCellsInUse = 0;
	local iNumCellTarget = math.floor(iNumTotalCells * 0.72); -- Adding extra island chains compared to other Plus maps.
	if Map.GetWorldSize() == WorldSizeTypes.WORLDSIZE_HUGE then
		iNumCellTarget = math.floor(iNumTotalCells * 0.66); -- Don't add extras to huge maps, for performance reasons.
	end
	local island_chain_PlotTypes = table.fill(PlotTypes.PLOT_OCEAN, iW * iH);

	-- Add randomly generated island groups
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
	
	-- Apply island data to the main plot data.
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * self.iNumPlotsX + x;
			if island_chain_PlotTypes[i + 1] ~= PlotTypes.PLOT_OCEAN then
				self.plotTypes[i] = island_chain_PlotTypes[i + 1];
			end
		end
	end

	if(shift_plot_types) then
		self:ShiftPlotTypes();
		-- Center Rift warrants plot shifting to guarantee centered landmasses.
		if(has_center_rift) then
			self:GenerateCenterRift()
		end
	end

	return self.plotTypes;
end
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types (Lua Small Continents) ...");

	local sea_level = Map.GetCustomOption(4)
	if sea_level == 4 then
		sea_level = 1 + Map.Rand(3, "Random Sea Level - Lua");
	end
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end

	local fractal_world = FractalWorld.Create();
	fractal_world:InitFractal{
		continent_grain = 3};

	local args = {
		sea_level = sea_level,
		world_age = world_age,
		sea_level_low = 69,
		sea_level_normal = 75,
		sea_level_high = 80,
		extra_mountains = 10,
		adjust_plates = 1.5,
		tectonic_islands = true
		}
	local plotTypes = fractal_world:GeneratePlotTypes(args);
	
	SetPlotTypes(plotTypes);
	GenerateCoasts();
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Small Continents) ...");
	
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
	print("Adding Features (Lua Small Continents) ...");

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
	-- Regional Division Method 2: Continental
	local args = {
		method = 2,
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
	
	-- tell the AI that we should treat this as a offshore expansion map
	Map.ChangeAIMapHint(4);

end
------------------------------------------------------------------------------
