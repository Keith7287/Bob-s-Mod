-- MapUtilities.lua
-- Set of common map info methods used by multiple UI's and scripts.
------------------------------------------------------------------------------
--	Copyright (c) 2009-2013 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------
MapUtilities = {};

-----------------------------------------------------
-- Returns the name, description, icon info, folder info
-- and, if exists, wb map info of a given filename.
-----------------------------------------------------
function MapUtilities.GetBasicInfo(fileName)

	
	local fileNameWithoutExt = Path.GetFileNameWithoutExtension(fileName);
	local mapName = fileNameWithoutExt 
	local mapDescription;
	local mapIconIndex = 4;
	local mapIconAtlas = "WORLDTYPE_ATLAS";
	local mapType;
	local mapFolder;

	if(Locale.IsNilOrWhitespace(mapName)) then
		mapName = "TXT_KEY_MISC_UNKNOWN";
	else
		local mapInfo = UI.GetMapPreview(fileName);
		if(mapInfo ~= nil) then	
		
			for row in GameInfo.Map_Sizes() do
				if(fileNameWithoutExt == Path.GetFileNameWithoutExtension(row.FileName)) then
					local mapEntry = GameInfo.Maps[row.MapType];
					if(mapEntry ~= nil) then
						mapType = row.MapType;
						mapName = mapEntry.Name;
						mapDescription = mapEntry.Description;	
						mapIconIndex = mapEntry.IconIndex;
						mapIconAtlas = mapEntry.IconAtlas;  
						mapFolder = mapEntry.FolderType
						break;
					end
				end
			end
			
			if(mapType == nil) then
				-- Set Map Type Slot
				if(not Locale.IsNilOrWhitespace(mapInfo.Name)) then
					mapName = mapInfo.Name;
				end
				
				if(not Locale.IsNilOrWhitespace(mapInfo.Description)) then
					mapDescription = mapInfo.Description;
				end
			end
		else
		
			--First check if it's a map script
			local bFound = false;
			for row in GameInfo.MapScripts{FileName = fileName} do
			
				mapName = row.Name;
				mapDescription = row.Description;
				mapIconIndex = row.IconIndex;
				mapIconAtlas = row.IconAtlas;
				mapFolder = row.FolderType;
				bFound = true;
				break;
			end	
		end
	end
	
	
	return {
		Name = mapName,
		Description = mapDescription,
		IconIndex = mapIconIndex,
		IconAtlas = mapIconAtlas,
		WBMapInfo = mapInfo,
		WBMapType = mapType	
	};
end