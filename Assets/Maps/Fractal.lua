--
--	FILE:	 Fractal.py
--	AUTHOR:  Shaun Seckman
--	PURPOSE: Global map script - Civ5's default map script
------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("FeatureGenerator");
include("TerrainGenerator");

function GetMapScriptInfo()
	return {
		Name = "TXT_KEY_MAP_FRACTAL",
		Description = "TXT_KEY_MAP_FRACTAL_HELP",
		IconIndex = 5,
	}
end
----------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Fractal) ...");

	local fractal_world = FractalWorld.Create();
	fractal_world:InitFractal{
		rift_grain = -1, 
		has_center_rift = false, 
		polar = true};

	local args = {
		has_center_rift = false
		}
	local plotTypes = fractal_world:GeneratePlotTypes(args);
	
	SetPlotTypes(plotTypes);
	GenerateCoasts();

end
----------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Fractal) ...");
	
	local terraingen = TerrainGenerator.Create();
	local terrainTypes = terraingen:GenerateTerrain()
		
	SetTerrainTypes(terrainTypes);
end
----------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Fractal) ...");
	
	local featuregen = FeatureGenerator.Create();
	featuregen:AddFeatures();
end
