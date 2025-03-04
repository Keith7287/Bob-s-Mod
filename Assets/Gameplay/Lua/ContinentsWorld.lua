--
--	FILE:	 ContinentsWorld.lua
--	AUTHORS: Brian Wade (based on a script from Shaun Seckman which was based on a script from Soren, but then I changed it a lot)
--	PURPOSE: Continents variant of Fractal World
------------------------------------------------------------------------------
--	Copyright (c) 2009 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------
include("FractalWorld");

ContinentsWorld = {};

function ellipseCheck(x, y, centerX, centerY, majorAxisSquared, minorAxisSquared)
	local deltaX = x-centerX;
	local deltaY = y-centerY;
	local deltaXSquared = deltaX * deltaX;
	local deltaYSquared = deltaY * deltaY;
	local d = deltaXSquared/majorAxisSquared + deltaYSquared/minorAxisSquared;
	if d <= 1 then
		return true;
	else
		return false;
	end
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
function ContinentsWorld.Create(fracXExp, fracYExp)
		
	local gridWidth, gridHeight = Map.GetGridSize();
	
	local sea_level = GameInfo.SeaLevels[Map.GetSeaLevel()];
	
	local data = {
		InitFractal = FractalWorld.InitFractal,
		CheckForOverrideDefaultUserInputVariances = FractalWorld.CheckForOverrideDefaultUserInputVariances,
		ShiftPlotTypes = FractalWorld.ShiftPlotTypes,
		ShiftPlotTypesBy = FractalWorld.ShiftPlotTypesBy,
		FindBestSplitY = FractalWorld.FindBestSplitY,
		FindBestSplitX = FractalWorld.FindBestSplitX,
		CalcWeights = FractalWorld.CalcWeights,
		GeneratePlotTypes = ContinentsWorld.GeneratePlotTypes,
		
		iFlags = Map.GetFractalFlags(),
		
		fracXExp = fracXExp,
		fracYExp = fracYExp,
		
		iNumPlotsX = gridWidth,
		iNumPlotsY = gridHeight,
		plotTypes = table.fill(PlotTypes.PLOT_OCEAN, gridWidth * gridHeight),
	
		seaLevelChange = sea_level.SeaLevelChange,
		seaLevelMax = 100,
		seaLevelMin = 0,
		stripRadius = 15,
		
	};
		
	return data;
end	
-------------------------------------------------------------------------------------------
function ContinentsWorld:GeneratePlotTypes(args)
	if(args == nil) then args = {}; end
	
	local water_percent = args.water_percent or 78;
	local shift_plot_types = args.shift_plot_types or true;
	local grain_amount = args.grain_amount or 3;
	
	-- Check for changes to User Input variances.
	--self.checkForOverrideDefaultUserInputVariances();
	
	local WorldSizeTypes = {};
	for row in GameInfo.Worlds() do
		WorldSizeTypes[row.Type] = row.ID;
	end
	
	-- Hills and Mountains handled differently according to map size.
	local sizekey = Map.GetWorldSize();
	local sizevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]     = 3,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 3,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 4,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 4,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 5,
		[WorldSizeTypes.WORLDSIZE_HUGE]		= 5
	};
	local grain = sizevalues[sizekey] or 3;
	
	local platevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]		= 6,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 9,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 12,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 18,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 24,
		[WorldSizeTypes.WORLDSIZE_HUGE]     = 30
	};
	local numPlates = platevalues[sizekey] or 5;

	self.hillsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	-- have the hills be clumpy with a bit of ridges in them
	self.hillsFrac:BuildRidges(numPlates, {FRAC_WRAP_X = true}, 1, 2);
	
	self.mountainsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, 4, self.iFlags, self.fracXExp, self.fracYExp);
	-- have the mountain ranges tend to be be distinct
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, {}, 6, 1);

	water_percent = water_percent + self.seaLevelChange;
	water_percent = math.clamp(water_percent, self.seaLevelMin, self.seaLevelMax);
		
	local iWaterThreshold = self.continentsFrac:GetHeight(water_percent);
	local iHillsBottom1 = self.hillsFrac:GetHeight(25);
	local iHillsTop1 = self.hillsFrac:GetHeight(31);
	local iHillsBottom2 = self.hillsFrac:GetHeight(69);
	local iHillsTop2 = self.hillsFrac:GetHeight(75);
	local iHillsClumps = self.mountainsFrac:GetHeight(4);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(85);
	local iMountainThreshold = self.mountainsFrac:GetHeight(94);
	local iPassThreshold = self.hillsFrac:GetHeight(85);
	local iMountain100 = self.mountainsFrac:GetHeight(100);
	local iMountain99 = self.mountainsFrac:GetHeight(99);
	local iMountain98 = self.mountainsFrac:GetHeight(98);
	local iMountain97 = self.mountainsFrac:GetHeight(97);
	local iMountain95 = self.mountainsFrac:GetHeight(95);

	local centerX0 = self.iNumPlotsX * 0.25;
	local centerY0 = self.iNumPlotsY * 0.25;
	local centerX1 = self.iNumPlotsX * 0.25;
	local centerY1 = self.iNumPlotsY * 0.75;
	local centerX2 = self.iNumPlotsX * 0.75;
	local centerY2 = self.iNumPlotsY * 0.25;
	local centerX3 = self.iNumPlotsX * 0.75;
	local centerY3 = self.iNumPlotsY * 0.75;

	-- continent major and minor axes
	local continentMajorAxis = centerX0 * 0.63;
	local continentMinorAxis = centerY0 * 0.63;
	local continentMajorAxisSquared = continentMajorAxis * continentMajorAxis;
	local continentMinorAxisSquared = continentMinorAxis * continentMinorAxis;
	
	local subcontinentMajorAxis = continentMajorAxis * 0.5;
	local subcontinentMinorAxis = continentMinorAxis * 0.5;
	local subcontinentMajorAxisSquared = subcontinentMajorAxis * subcontinentMajorAxis;
	local subcontinentMinorAxisSquared = subcontinentMinorAxis * subcontinentMinorAxis;
	
	-- place either 2 or 3 continents in the world
	local numContinents = 2;
	
	-- todo: add multiple variations of continent layout
	
	local continents = {};
	for i = 1, numContinents, 1 do
		continents[i] = {};
		continents[i].x = (((i-1) + 0.5) * self.iNumPlotsX) / numContinents;
		continents[i].y = centerY0 + Map.Rand(centerY0*2, "centerY of Continent");
		--if Map.Rand(100, "determine orientation of continents") >= 50 then
			--continents[i].majorAxisSq = continentMajorAxisSquared;
			--continents[i].minorAxisSq = continentMinorAxisSquared;
		--else -- vertical
			continents[i].majorAxisSq = continentMinorAxisSquared;
			continents[i].minorAxisSq = continentMajorAxisSquared;
		--end
	end
	
	-- then place 6 subcontinents
	
	local subcontinents = {};
	for i = 1, 6, 1 do
		subcontinents[i] = {};
		subcontinents[i].x = Map.Rand(self.iNumPlotsX, "centerX of subContinent");
		subcontinents[i].y = Map.Rand(self.iNumPlotsY, "centerY of subContinent");
		if Map.Rand(100, "determine orientation of continents") >= 50 then
			subcontinents[i].majorAxisSq = subcontinentMajorAxisSquared;
			subcontinents[i].minorAxisSq = subcontinentMinorAxisSquared;
		else
			subcontinents[i].majorAxisSq = subcontinentMinorAxisSquared;
			subcontinents[i].minorAxisSq = subcontinentMajorAxisSquared;
		end
	end
	
	for x = 0, self.iNumPlotsX - 1, 1 do
		for y = 0, self.iNumPlotsY - 1, 1 do
			local i = y * self.iNumPlotsX + x;
			local val = self.continentsFrac:GetHeight(x, y);
			
			local inContinent = false;
			
			local h = iWaterThreshold - (0.15 * iWaterThreshold);
			
			-- let's blend ellipses in to form the basic continents
			for continentIndex, thisContinent in pairs(continents) do
				if ellipseCheck(x, y, thisContinent.x, thisContinent.y, thisContinent.majorAxisSq, thisContinent.minorAxisSq) then
					inContinent = true;
					break;
				end
			end
			
			if not inContinent then
				for continentIndex, thisSubContinent in pairs(subcontinents) do
					if ellipseCheck(x, y, thisSubContinent.x, thisSubContinent.y, thisSubContinent.majorAxisSq, thisSubContinent.minorAxisSq) then
						inContinent = true;
						break;
					end
				end
			end
			
			if inContinent then
				h = iWaterThreshold + 0.15 * iWaterThreshold;
			end
						
			val = (val + h + h) / 3;
			
			local mountainVal = self.mountainsFrac:GetHeight(x, y);
			local hillVal = self.hillsFrac:GetHeight(x, y);
	
			if(val <= iWaterThreshold) then
				self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				
				-- on second thought build some islands near the ridge lines
				if (mountainVal == iMountain100) then
					self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN; -- this would be especially cool if there were a special volcano tile
				elseif (mountainVal == iMountain99) then
					self.plotTypes[i] = PlotTypes.PLOT_HILLS;
				elseif (mountainVal == iMountain97) then
					self.plotTypes[i] = PlotTypes.PLOT_LAND;
				elseif (mountainVal == iMountain95) then
					self.plotTypes[i] = PlotTypes.PLOT_LAND;
				end
					
			else
				if (mountainVal >= iMountainThreshold) then
					-- use the other ridged fractal to put passes through the ranges (sometimes, it is random after all)
					if (hillVal >= iPassThreshold) then
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					else
						self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					end
				elseif (mountainVal >= iHillsNearMountains) then
					self.plotTypes[i] = PlotTypes.PLOT_HILLS; -- foot hills
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

	if shift_plot_types then
		self:ShiftPlotTypes();
	end

	return self.plotTypes;
end
