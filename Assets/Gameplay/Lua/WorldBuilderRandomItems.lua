------------------------------------------------------------------------------
--	FILE:	 MapGenerator.lua
--	AUTHORS: Shaun Seckman
--	         Bob Thomas
--	PURPOSE: Base logic for map generation.
------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator.lua");

function ResourceIgnoresLatitudes(resource)
	return false;
end

function CaclulateNumResourcesToAdd(resource)

	-- Calculate resourceCount, the amount of this resource to be placed:
	local rand1 = Map.Rand(resource.RandApp1, "MapGenerator CalculateNumResourcesToAdd-1");
	local rand2 = Map.Rand(resource.RandApp2, "MapGenerator CalculateNumResourcesToAdd-2");
	local rand3 = Map.Rand(resource.RandApp3, "MapGenerator CalculateNumResourcesToAdd-3");
	local rand4 = Map.Rand(resource.RandApp4, "MapGenerator CalculateNumResourcesToAdd-4");
	local baseCount = resource.ConstAppearance + rand1 + rand2 + rand3 + rand4;

	local ignoreLatitude = ResourceIgnoresLatitudes(resource);

	-- Calculate numPossible, the number of plots that are eligible to have this resource:
	local landTiles = 0;
	if (resource.TilesPer > 0) then
	
		local numPossible = 0;
		for index, plot in Plots() do
			if (plot:CanHaveResource(resource.ID, ignoreLatitude)) then
				numPossible = numPossible + 1;
			end
		end
		
		landTiles = landTiles + math.floor(numPossible / resource.TilesPer);
	
	end

	local players = math.floor((Game.CountCivPlayersAlive() * resource.Player) / 100);
	local resourceCount = math.floor((baseCount * (landTiles + players)) / 100);
	resourceCount = math.max(1, resourceCount);
	return resourceCount;
end

function CanPlaceResourceAt(resource, plot, ignoreLatitude)

	local resourceID = resource.ID;
	local area = plot:Area();

	local plotX = plot:GetX();
	local plotY = plot:GetY();

	if (not plot:CanHaveResource(resourceID, ignoreLatitude)) then
		return false;
	end

	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local otherPlot = Map.PlotDirection(plotX, plotY, direction);

		if (otherPlot ~= nil) then
			if ((otherPlot:GetResourceType() ~= -1) and (otherPlot:GetResourceType() ~= resourceID)) then
				return false;
			end
		end
	end

	if (plot:IsWater()) then
		if (((Map.GetNumResourcesOnLand(resourceID) * 100) / (Map.GetNumResources(resourceID) + 1)) < resource.MinLandPercent) then
			return false;
		end
	end

	-- Make sure there are no resources of the same class (but a different type) nearby:
	local resourceClass = GameInfo.ResourceClasses[resource.ResourceClassType];
	local uniqueRange = resourceClass.UniqueRange;
	for dx = -uniqueRange, uniqueRange - 1, 1 do
	
		for dy = -uniqueRange, uniqueRange - 1, 1 do
		
			local otherPlot	= Map.GetPlotXY(plotX, plotY, dx, dy);

			if (otherPlot ~= nil) then
			
				local otherArea = otherPlot:Area();
				if (otherArea:GetID() == area:GetID()) then
				
					if (Map.PlotDistance(plotX, plotY, otherPlot:GetX(), otherPlot:GetY()) <= uniqueRange) then
					
						local otherResource = GameInfo.Resources[otherPlot:GetResourceType()];
						if (otherResource ~= nil) then
						
							if (otherResource.ResourceClassType == resource.ResourceClassType) then
							
								return false;
							end
						end
					end
				end
			end
		end
	end
	
	-- Make sure there are none of the same resource nearby:
	uniqueRange = resource.Unique;
	for dx = -uniqueRange, uniqueRange - 1, 1 do
		for dy = -uniqueRange, uniqueRange - 1, 1 do
			local otherPlot	= Map.GetPlotXY(plotX, plotY, dx, dy);

			if (otherPlot ~= nil) then
				local otherArea = otherPlot:Area();
				if (otherArea:GetID() == area:GetID()) then
				
					if (Map.PlotDistance(plotX, plotY, otherPlot:GetX(), otherPlot:GetY()) <= uniqueRange) then
						if (otherPlot:GetResourceType() == resourceID) then
							return false;
						end
					end
				end
			end
		end
	end
	
	return true;
end

function AddUniqueResourceType(resource)

	local resourceID = resource.ID;
	local resourceCount = CaclulateNumResourcesToAdd(resource);
	local ignoreLatitude = ResourceIgnoresLatitudes(resource);

	local triedAreas = {};
	
	while (true) do
	
		local bestValue = 0;
		local bestArea;
		for id, area in Map.Areas() do
			if(triedAreas[area:GetID()] == nil) then
			
				local numUniqueResourcesOnArea = area:CountNumUniqueResourceTypes() + 1; -- number of unique resources starting on the area, plus this one
				local numTiles = area:GetNumTiles();
				local value = numTiles / numUniqueResourcesOnArea;

				if (value > bestValue) then
					bestValue = value;
					bestArea = area;
				end
			
			end
		end

		if (bestArea == nil) then
			return; -- Can't place resource on any area.
		end
		
		triedAreas[bestArea:GetID()] = true;
		
		-- Place the resources:
		for i, plot in Plots(Shuffle) do
		
			if (Map.GetNumResources(resourceID) >= resourceCount) then
				break; -- We already have enough
			end

			if (bestArea:GetID() == plot:Area():GetID() ) then
			
				if (CanPlaceResourceAt(resource, plot, ignoreLatitude)) then
				
					local resourceNum = Map.GetRandomResourceQuantity(resourceID);
					plot:SetResourceType(resourceID, resourceNum);

					local groupRange = resource.GroupRange;
					for dx = -groupRange, groupRange - 1, 1 do
						for dy = -groupRange, groupRange - 1, 1 do
							if (Map.GetNumResources(resourceID) < resourceCount) then
							
								local otherPlot	= Map.PlotXYWithRangeCheck(plot:GetX(), plot:GetY(), dx, dy, groupRange);
							
								if (otherPlot ~= nil and (otherPlot:Area():GetID() == bestArea:GetID() )) then
									if (CanPlaceResourceAt(resource, otherPlot, ignoreLatitude)) then
									
										if (Map.Rand(100, "addUniqueResourceType") < resource.GroupRand) then
									
											local resourceNum = Map.GetRandomResourceQuantity(resourceID);
											otherPlot:SetResourceType(resourceID, resourceNum);
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
end

function AddNonUniqueResourceType(resource)
	local resourceID = resource.ID;
	local resourceCount = CaclulateNumResourcesToAdd(resource);
	local ignoreLatitude = ResourceIgnoresLatitudes(resource);
	
	if (resourceCount == 0) then
		return;
	end

	for i, plot in Plots(Shuffle) do
		
		if (CanPlaceResourceAt(resource, plot, bIgnoreLatitude)) then
		
			local resourceNum = Map.GetRandomResourceQuantity(resourceID);
			plot:SetResourceType(resourceID, resourceNum);
			resourceCount = resourceCount - 1;

			local groupRange = resource.GroupRange;
			for dx = -groupRange, groupRange - 1, 1 do
				for dy = -groupRange, groupRange - 1, 1 do
				
					if (resourceCount > 0) then
					
						local otherPlot	= Map.PlotXYWithRangeCheck(plot:GetX(), plot:GetY(), dx, dy, groupRange);

						if (otherPlot ~= nil) then
							if (CanPlaceResourceAt(resource, otherPlot, ignoreLatitude)) then
								if (Map.Rand(100, "addNonUniqueResourceType") < resource.GroupRand) then
								
									local resourceNum = Map.GetRandomResourceQuantity(resourceID);
									otherPlot:SetResourceType(resourceID, resourceNum);
									resourceCount = resourceCount - 1;
								end
							end
						end
					end
				end
			end

			if (resourceCount == 0) then
				return;
			end
		end
	end
end

-- Adds resources without regard to player starting positions
-- This function is valuable because it is decoupled from the
-- start position generation.  It is used by world builder maps
-- that have the radomize resources option turned on.
function AddResourcesForWorldBuilderMap()
	print("Map Generation - Adding Resources");
	
	--Obtain a list of all resources
	local i = 1;
	local resources = {};
	for resource in GameInfo.Resources() do
		resources[i] = resource;
		i = i + 1;
	end
	
	-- Sort the resources by PlacementOrder
	local PlacementOrderSort = function(a, b)
		return a.PlacementOrder < b.PlacementOrder;
	end
	table.sort(resources, PlacementOrderSort);
	
	-- Add resources
	for i, resource in ipairs(resources) do
		if(AddResourceType == nil or AddResourceType(resource.ID) ~= true) then
			if(resource.Area) then
				AddUniqueResourceType(resource);
			else
				AddNonUniqueResourceType(resource);
			end		
		end
	end
	
end
