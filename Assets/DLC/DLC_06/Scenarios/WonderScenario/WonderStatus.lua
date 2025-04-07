----------------------------------------------------------------
----------------------------------------------------------------
-- WonderStatus.lua
-- Script for the gameplay, UI, and some setup
-- for the Wonders of the Ancient World scenario
----------------------------------------------------------------
----------------------------------------------------------------

include( "IconSupport" );
include( "FLuaVector" );

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------
-------------------------------------------------
-- SetVictoryTypes
-------------------------------------------------
function SetVictoryTypes()
	Game.SetVictoryValid(0,false);
	Game.SetVictoryValid(1,false);
	Game.SetVictoryValid(2,true);
	Game.SetVictoryValid(3,false);
	Game.SetVictoryValid(4,false);
end

----------------------------------------------------------------
-- Constant Values
----------------------------------------------------------------
ACHIEVEMENT_WONDER_CITY = 3; -- Number of wonders in a single city needed to unlock Wonder City achievement
ACHIEVEMENT_WONDER_CONQUEST = 3; -- Number of wonders to conquer to unlock Wonder Conquest achievement
ACHIEVEMENT_ORACLE_CONSULTS = 2; -- Number of visits to the Oracle needed to unlock Oracle Consult achievement

ORACLE_CONSULT_DIST = 2; -- Distance needed for a unit to consult the Oracle, in hexes
ORACLE_CONSULT_DURATION = 5; -- Number of turns the Oracle, once consulted, gives the player information about other civs

UNITDATA_ORACLE_VISITED = 101; -- For use with unit-specific scenario data

COLOR_GREYED_OUT = Vector4(0.2, 0.2, 0.2, 1);
COLOR_NORMAL = Vector4(1, 1, 1, 1);
COLOR_UNDER_CONSTRUCTION = Vector4(0.9, 0.5, 0.1, 1.0);

local oracleTextColor = GameInfo.Colors["COLOR_FONT_GREEN"];
COLOR_ORACLE_TEXT = Vector4(oracleTextColor.Red, oracleTextColor.Green, oracleTextColor.Blue, oracleTextColor.Alpha);

----------------------------------------------------------------
-- Global Variables
----------------------------------------------------------------
OracleConsulter = nil;
ValidConsulters = {};

Wonders = {

	-- Pyramids
	{
		Building = GameInfo.Buildings["BUILDING_PYRAMID"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_PYRAMID"],
		IconAtlas = "BW_ATLAS_2",
		PortraitIndex = 0,
		ProgressBarColor = "COLOR_CULTURE_STORED",
		NeededProgress = 600,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Mausoleum
	{
		Building = GameInfo.Buildings["BUILDING_MAUSOLEUM_HALICARNASSUS"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_MAUSOLEUM_HALICARNASSUS"],
		IconAtlas = "WONDERS_DLC_ATLAS",
		PortraitIndex = 1,
		ProgressBarColor = "COLOR_CULTURE_STORED",
		NeededProgress = 1500,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Artemis
	{
		Building = GameInfo.Buildings["BUILDING_TEMPLE_ARTEMIS"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_TEMPLE_ARTEMIS"],
		IconAtlas = "WONDERS_DLC_ATLAS",
		PortraitIndex = 0,
		ProgressBarColor = "COLOR_YIELD_GOLD",
		NeededProgress = 1500,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Colossus
	{
		Building = GameInfo.Buildings["BUILDING_COLOSSUS"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_COLOSSUS"],
		IconAtlas = "BW_ATLAS_2",
		PortraitIndex = 4,
		ProgressBarColor = "COLOR_YIELD_GOLD",
		NeededProgress = 3000,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Hanging Gardens
	{
		Building = GameInfo.Buildings["BUILDING_HANGING_GARDEN"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_HANGING_GARDEN"],
		IconAtlas = "BW_ATLAS_2",
		PortraitIndex = 3,
		ProgressBarColor = "COLOR_RESEARCH_STORED",
		NeededProgress = 15,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Great Library
	{
		Building = GameInfo.Buildings["BUILDING_GREAT_LIBRARY"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_GREAT_LIBRARY"],
		IconAtlas = "BW_ATLAS_2",
		PortraitIndex = 1,
		ProgressBarColor = "COLOR_RESEARCH_STORED",
		NeededProgress = 20,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Zeus
	{
		Building = GameInfo.Buildings["BUILDING_STATUE_ZEUS"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_STATUE_ZEUS"],
		IconAtlas = "WONDERS_DLC_ATLAS",
		PortraitIndex = 2,
		ProgressBarColor = "COLOR_RED",
		NeededProgress = 150,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Lighthouse
	{
		Building = GameInfo.Buildings["BUILDING_GREAT_LIGHTHOUSE"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_GREAT_LIGHTHOUSE"],
		IconAtlas = "BW_ATLAS_2",
		PortraitIndex = 5,
		ProgressBarColor = "COLOR_RED",
		NeededProgress = 300,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
	
	-- Oracle
	{
		Building = GameInfo.Buildings["BUILDING_ORACLE"],
		BuildingClass = GameInfo.BuildingClasses["BUILDINGCLASS_ORACLE"],
		IconAtlas = "BW_ATLAS_2",
		ProgressBarColor = "COLOR_GREEN",
		PortraitIndex = 6,
		NeededProgress = 0,
		BuiltBy = nil,
		OwnedBy = nil,
		CityIn = nil,
		UIControls = nil,
	},
}

-----------------------------------------------------------------
-- Saving and Loading
-----------------------------------------------------------------
-------------------------------------------------
-- LoadWonderData
-------------------------------------------------
function LoadWonderData()
	local savedData = Modding.OpenSaveData();
	for i, w in ipairs(Wonders) do
		local iBuilder = savedData.GetValue(string.format("Wonder%iBuilder", i-1));
		local iOwner = savedData.GetValue(string.format("Wonder%iOwner", i-1));
		local iCity = savedData.GetValue(string.format("Wonder%iCity", i-1));
		w.BuiltBy = iBuilder;
		w.OwnedBy = iOwner;
		w.CityIn = iCity;
	end
end

-------------------------------------------------
-- SaveWonderData
-------------------------------------------------
function SaveWonderData()
	local savedData = Modding.OpenSaveData();
	for i, w in ipairs(Wonders) do
		local iBuilder = w.BuiltBy;
		local iOwner = w.OwnedBy;
		local iCity = w.CityIn;
		savedData.SetValue(string.format("Wonder%iBuilder", i-1), iBuilder);
		savedData.SetValue(string.format("Wonder%iOwner", i-1), iOwner);
		savedData.SetValue(string.format("Wonder%iCity", i-1), iCity);
	end
end

-----------------------------------------------------------------
-- Gameplay Event Handlers
-----------------------------------------------------------------
-------------------------------------------------
-- CityCanConstruct
-------------------------------------------------
GameEvents.CityCanConstruct.Add(function(iPlayer, iCity, iBuildingType) 
	
    UpdateUnlockProgress(iPlayer);

	for i,v in ipairs(Wonders) do
		if(iBuildingType == v.Building.ID) then
			return IsUnlocked(iPlayer, i);
		end
	end
	
    return true;

end);

-------------------------------------------------
-- PlayerDoTurn
-------------------------------------------------
GameEvents.PlayerDoTurn.Add(function(iPlayer) 
	if (iPlayer == 0) then
		UpdateAllProgress();
	end
end);

-------------------------------------------------
-- CityCaptureComplete
-------------------------------------------------
GameEvents.CityCaptureComplete.Add(function(iOldOwner, bIsCapital, iX, iY, iNewOwner)
	local plot = Map.GetPlot(iX, iY);
	local cCity = plot:GetPlotCity();
	if (cCity ~= nil) then
		for i, w in ipairs(Wonders) do
			if (cCity:IsHasBuilding(w.Building.ID)) then
				w.OwnedBy = iNewOwner;
				w.CityIn = cCity:GetID();
				SaveWonderData();
				UpdateScoring();
			end
		end
	end
	if (iNewOwner == 0) then
		CheckConquestAchievement();
	end
end);

-------------------------------------------------
-- UnitSetXY
-------------------------------------------------
GameEvents.UnitSetXY.Add(function(iPlayer, iUnitID, iX, iY)

	local player = Players[iPlayer];
	local unit = player:GetUnitByID(iUnitID);
	if (unit == nil or unit:IsDelayedDeath()) then
		return false;
	end
	
	if (MayConsultOracle(iPlayer, unit)) then
		table.insert(ValidConsulters, unit);
	end
end);

-----------------------------------------------------------------
-- Gameplay Functions
-----------------------------------------------------------------
-------------------------------------------------
-- UpdateScoring
-------------------------------------------------
function UpdateScoring()
	-- Reset wonder-related scores to 0
	for iPlayer = 0, 4 do
		local pPlayer = Players[iPlayer];
		pPlayer:ChangeNumWorldWonders(-1 * (pPlayer:GetScoreFromWonders() / GameDefines["SCORE_WONDER_MULTIPLIER"]));
		pPlayer:ChangeScoreFromFutureTech(-1 * pPlayer:GetScoreFromFutureTech()); -- Wonders owned (inc. captured wonders)
	end
	
	for iW, wW in ipairs(Wonders) do
		local iBuilder = wW.BuiltBy;
		if (iBuilder ~= nil) then
			local pBuilder = Players[iBuilder];
			pBuilder:ChangeNumWorldWonders(1);
		end
		
		local iOwner = wW.OwnedBy;
		if (iOwner ~= nil) then
			local pOwner = Players[iOwner];
			pOwner:ChangeScoreFromFutureTech(1 * GameDefines["SCORE_FUTURE_TECH_MULTIPLIER"]);
		end
	end
end

-------------------------------------------------
-- UpdateAllProgress
-------------------------------------------------
function UpdateAllProgress()
	for i = 0, 4 do
		UpdateUnlockProgress(i);
		UpdateBuildProgress(i);
	end
end

-------------------------------------------------
-- UpdateUnlockProgress
-------------------------------------------------
function UpdateUnlockProgress(iPlayer)
    local pPlayer = Players[iPlayer];
    local pTeam = Teams[pPlayer:GetTeam()];
	
    local iCulture = pPlayer:GetJONSCultureEverGenerated();
    SetUnlockProgress(iPlayer, 1, iCulture);
	SetUnlockProgress(iPlayer, 2, iCulture);

    local iGrossGold = pPlayer:GetLifetimeGrossGold();
	SetUnlockProgress(iPlayer, 3, iGrossGold);
	SetUnlockProgress(iPlayer, 4, iGrossGold);

    local iTechsResearched = pTeam:GetTeamTechs():GetNumTechsKnown();
	SetUnlockProgress(iPlayer, 5, iTechsResearched);
	SetUnlockProgress(iPlayer, 6, iTechsResearched);

    local iExperience = pPlayer:GetLifetimeCombatExperience();
	SetUnlockProgress(iPlayer, 7, iExperience);
	SetUnlockProgress(iPlayer, 8, iExperience);
	
	-- Don't update progress on the Oracle, since it is unlocked by default
end

-------------------------------------------------
-- UpdateBuildProgress
-------------------------------------------------
function UpdateBuildProgress(iPlayer)
	for i,w in ipairs(Wonders) do
		local buildingClassID = w.BuildingClass.ID;
		local buildingID = w.Building.ID;
		
		if (Game.IsBuildingClassMaxedOut(buildingClassID)) then -- Case 1: The wonder is already built
			if (w.BuiltBy == nil) then -- Case 1a: The wonder was just built, so update who built it
				OnWonderCompleted(i);
			end
		else -- Case 2: The wonder is not built yet, so update build progress
			local pPlayer = Players[iPlayer];
			SetBuildCity(iPlayer, i, nil);
			SetBuildProgress(iPlayer, i, 0);
			for pCity in pPlayer:Cities() do
				if (pCity:GetFirstBuildingOrder(buildingID) ~= -1) then
					SetBuildCity(iPlayer, i, pCity);
					SetBuildProgress(iPlayer, i, pCity:GetProduction());
					break;
				end
			end
		end
	end
end

-------------------------------------------------
-- OnWonderCompleted
-------------------------------------------------
function OnWonderCompleted(iWonder)
	local wonder = Wonders[iWonder];
	-- Find who built it
	local iBuilder = nil;
	for i = 0, 4 do
		local p = Players[i];
		if (p:GetBuildingClassCount(wonder.BuildingClass.ID) > 0) then
			iBuilder = i;
			break;
		end
	end
	if (iBuilder == nil) then
		print("Scripting Error: Could not find player that built wonder " .. wonder.Building.Type);
	end
	-- Update info based on who built it
	wonder.BuiltBy = iBuilder;
	wonder.OwnedBy = iBuilder;
	local pBuilder = Players[iBuilder];
	for pCity in pBuilder:Cities() do
		if (pCity:IsHasBuilding(wonder.Building.ID)) then
			wonder.CityIn = pCity:GetID();
			break;
		end
	end
	SaveWonderData();
	-- Update score
	UpdateScoring();
	-- Update diplomacy for rival civs
	for j = 0, 4 do
		if (j ~= iBuilder) then
			local pOtherPlayer = Players[j];
			local iWondersBeatenTo = pOtherPlayer:GetNumWondersBeatenTo(iBuilder);
			iWondersBeatenTo = iWondersBeatenTo + 1;
			pOtherPlayer:SetNumWondersBeatenTo(iBuilder, iWondersBeatenTo);
		end
	end
	-- Check achievement
	if (iBuilder == 0) then
		CheckCityAchievement();
	end
	-- If it is the Oracle that was just built, notify the player of the consult rules
	if (iWonder == 9) then
		NotifyOracleBuilt();
	end
end

-------------------------------------------------
-- MayConsultOracle
-------------------------------------------------
function MayConsultOracle(iPlayer, unit)
	
	if (unit:IsGreatPerson()) then
		if (unit:GetScenarioData() ~= UNITDATA_ORACLE_VISITED) then
			local iOracleOwner = Wonders[9].OwnedBy;
			if (iOracleOwner ~= nil) then
				local iOracleCityID = Wonders[9].CityIn;
				local oracleCity = Players[iOracleOwner]:GetCityByID(iOracleCityID);
				local iDist = Map.PlotDistance(unit:GetX(), unit:GetY(), oracleCity:GetX(), oracleCity:GetY());
				if (iDist <= ORACLE_CONSULT_DIST) then
					if (not IsOracleConsultationActive(iPlayer)) then
						return true;
					end
				end
			end
		end
	end
	
	return false;
end

-------------------------------------------------
-- IsOracleConsultationActive
-------------------------------------------------
function IsOracleConsultationActive(iPlayer)
	local savedData = Modding.OpenSaveData();
	local iOracleLastConsulted = savedData.GetValue(string.format("Player%iOracleLastConsultedTurn", iPlayer));
	if (iOracleLastConsulted == nil) then
		return false;
	end

	return ( iOracleLastConsulted + ORACLE_CONSULT_DURATION > Game.GetGameTurn() );
end

-----------------------------------------------------------------
-- Achievements
-----------------------------------------------------------------
-------------------------------------------------
-- CheckCityAchievement
-------------------------------------------------
function CheckCityAchievement()
	local iPlayer = 0; -- Human player
	for c in Players[iPlayer]:Cities() do
		local numWonders = c:GetNumWorldWonders();
		if (numWonders >= ACHIEVEMENT_WONDER_CITY) then
			UI.UnlockAchievement("ACHIEVEMENT_SCENARIO_06_WONDER_CITY");
			break;
		end
	end
end

-------------------------------------------------
-- CheckConquestAchievement
-------------------------------------------------
function CheckConquestAchievement()
	local iPlayer = 0; -- Human player
	local iWondersConquered = 0;
	for i, w in ipairs(Wonders) do
		if (w.OwnedBy == iPlayer and w.BuiltBy ~= iPlayer) then
			iWondersConquered = iWondersConquered + 1;
		end
	end
	if (iWondersConquered >= ACHIEVEMENT_WONDER_CONQUEST) then
		UI.UnlockAchievement("ACHIEVEMENT_SCENARIO_06_WONDER_CONQUEST");
	end
end

-------------------------------------------------
-- CheckConsultAchievement
-------------------------------------------------
function CheckConsultAchievement()
	local iPlayer = 0; -- Human player
	local savedData = Modding.OpenSaveData();
	local iOracleConsults = savedData.GetValue(string.format("Player%iOracleConsults", iPlayer));
	if (iOracleConsults ~= nil) then
		if (iOracleConsults >= ACHIEVEMENT_ORACLE_CONSULTS) then
			UI.UnlockAchievement("ACHIEVEMENT_SCENARIO_06_ORACLE_CONSULT");
		end
	end
end

-----------------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------------
-------------------------------------------------
-- SetProgressBar
-------------------------------------------------
local originalProgressBarWidths = {};
function SetProgressBar(control, pct)
	local originalWidth = originalProgressBarWidths[control];
	if (originalWidth == nil) then
		originalWidth = control:GetSizeX();
		originalProgressBarWidths[control] = originalWidth;
	end
	
	control:SetSizeX(pct * originalWidth);
end

-----------------------------------------------------------------
-- Progress Data Wrapper Functions
-----------------------------------------------------------------
local wonderProgress = {};
-------------------------------------------------
-- IsUnlocked
-------------------------------------------------
function IsUnlocked(iPlayer, iWonder)
	CheckHasPlayerData(iPlayer, iWonder);
	return (GetUnlockProgress(iPlayer, iWonder) >= Wonders[iWonder].NeededProgress);
end

-------------------------------------------------
-- IsBuilding
-------------------------------------------------
function IsBuilding(iPlayer, iWonder)
	CheckHasPlayerData(iPlayer, iWonder);
	return (wonderProgress[iPlayer][iWonder].BuildCityID ~= nil);
end

-------------------------------------------------
-- CheckHasPlayerData
-------------------------------------------------
function CheckHasPlayerData(iPlayer, iWonder)
	if (wonderProgress[iPlayer] == nil) then
		wonderProgress[iPlayer] = {};
	end
	if (wonderProgress[iPlayer][iWonder] == nil) then
		wonderProgress[iPlayer][iWonder] = {
			UnlockProgress = 0;
			BuildProgress = 0;
			BuildCityID = nil;
		};
	end
end

-------------------------------------------------
-- GetUnlockProgress
-------------------------------------------------
function GetUnlockProgress(iPlayer, iWonder)
	CheckHasPlayerData(iPlayer, iWonder);
	return wonderProgress[iPlayer][iWonder].UnlockProgress;
end

-------------------------------------------------
-- SetUnlockProgress
-------------------------------------------------
function SetUnlockProgress(iPlayer, iWonder, iProgress)
	CheckHasPlayerData(iPlayer, iWonder);
	wonderProgress[iPlayer][iWonder].UnlockProgress = iProgress;
end

-------------------------------------------------
-- GetBuildProgress
-------------------------------------------------
function GetBuildProgress(iPlayer, iWonder)
	CheckHasPlayerData(iPlayer, iWonder);
	return wonderProgress[iPlayer][iWonder].BuildProgress;
end

-------------------------------------------------
-- GetBuildProgressNeeded
-------------------------------------------------
-- Since the production needed to build a wonder can be altered by the handicap setting
function GetBuildProgressNeeded(iPlayer, iWonder)
	local pPlayer = Players[iPlayer];
	local wWonder = Wonders[iWonder];
	return pPlayer:GetBuildingProductionNeeded(wWonder.Building.ID);
end

-------------------------------------------------
-- SetBuildProgress
-------------------------------------------------
function SetBuildProgress(iPlayer, iWonder, iProgress)
	CheckHasPlayerData(iPlayer, iWonder);
	wonderProgress[iPlayer][iWonder].BuildProgress = iProgress;
end

-------------------------------------------------
-- GetBuildCity
-------------------------------------------------
function GetBuildCity(iPlayer, iWonder)
	CheckHasPlayerData(iPlayer, iWonder);
	local pPlayer = Players[iPlayer];
	local iCityID = wonderProgress[iPlayer][iWonder].BuildCityID;
	if (iCityID ~= nil) then
		return pPlayer:GetCityByID(iCityID);
	else
		return nil
	end
end

-------------------------------------------------
-- SetBuildCity
-------------------------------------------------
function SetBuildCity(iPlayer, iWonder, cCity)
	CheckHasPlayerData(iPlayer, iWonder);
	if (cCity ~= nil) then
		wonderProgress[iPlayer][iWonder].BuildCityID = cCity:GetID();
	else
		wonderProgress[iPlayer][iWonder].BuildCityID = nil;
	end
end

-------------------------------------------------
-- IsCaptured
-------------------------------------------------
function IsCaptured(iWonder)
	local iOwner = Wonders[iWonder].OwnedBy;
	local iBuilder = Wonders[iWonder].BuiltBy;
	if (iOwner ~= nil and iBuilder ~= nil) then
		return (iOwner ~= iBuilder);
	end
	return false;
end

----------------------------------------------------------------
-- UI Event Handlers
----------------------------------------------------------------
-------------------------------------------------
-- RefreshLayout
-------------------------------------------------
function RefreshLayout()
	UpdateAllProgress();
	UpdateOracleHelp(0);
	for i,v in ipairs(Wonders) do
		UpdateWonderUIState(0, i); -- For first player, the one seeing the UI
	end
end

-------------------------------------------------
-- Back Button Handler
-------------------------------------------------
function OnClose()
    UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseStatusButton:RegisterCallback(Mouse.eLClick, OnClose);

-------------------------------------------------
-- Input processing
-------------------------------------------------
ContextPtr:SetInputHandler( function(uiMsg, wParam, lParam)
    if(uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE) then
		OnClose();
		return true;
    end
end);

-------------------------------------------------
-- Show/Hide Handler
-------------------------------------------------
-- NOTE:  This is hacked in TurnsRemaining.lua so that it is called regularly, like an update loop, regardless of whether it is hidden or not.
m_bUpdated = false; -- flag to prevent executing redundant code in this hacked update loop
m_iPlayerCulture = 0;
m_iPlayerGrossGold = 0;
m_iPlayerTechs = 0;
m_iPlayerXP = 0;
ContextPtr:SetShowHideHandler(function(bHiding)
	-- Handle Oracle consultations
	if (OracleConsulter == nil) then -- There is no Great Person currently being considered for a consult (ie. no dialog open)
		if (next(ValidConsulters) ~= nil) then -- There is a Great Person candidate
			OracleConsulter = table.remove(ValidConsulters); -- Pop the Great Person and consider him for consulting the Oracle
			AskToConsultOracle();
		end
	end
	
	-- Handle unlock notifications
	local bUnlockProgressUpdated = true;
	local iCurCulture = Players[0]:GetJONSCultureEverGenerated();
	if (iCurCulture ~= m_iPlayerCulture) then
		m_iPlayerCulture = iCurCulture;
		bUnlockProgressUpdated = false;
	end
	
	local iCurGrossGold = Players[0]:GetLifetimeGrossGold();
	if (iCurGrossGold ~= m_iPlayerGrossGold) then
		m_iPlayerGrossGold = iCurGrossGold;
		bUnlockProgressUpdated = false;
	end

	local iCurTechs = Teams[Players[0]:GetTeam()]:GetTeamTechs():GetNumTechsKnown();
	if (iCurTechs ~= m_iPlayerTechs) then
		m_iPlayerTechs = iCurTechs;
		bUnlockProgressUpdated = false;
	end
	
	local iCurXP = Players[0]:GetLifetimeCombatExperience();
	if (iCurXP ~= m_iPlayerXP) then
		m_iPlayerXP = iCurXP;
		bUnlockProgressUpdated = false;
	end
	
	if (not bUnlockProgressUpdated) then
		UpdateUnlockProgress(0);
		local savedData = Modding.OpenSaveData();
		for iWonder, wWonder in ipairs(Wonders) do
			if (IsUnlocked(0, iWonder)) then -- The wonder is unlocked...
				if (savedData.GetValue(string.format("Wonder%iUnlocked", iWonder-1)) == nil) then -- ...but the player has not been notified yet
					if (iWonder ~= 9) then -- We don't notify for the Oracle unlock, since it is unlocked by default
						if (Wonders[iWonder].BuiltBy == nil) then -- We don't notify if the wonder has already been built by someone
							NotifyWonderUnlocked(iWonder);
						end
					end
					savedData.SetValue(string.format("Wonder%iUnlocked", iWonder-1), 1);
				end	
			end
		end
	end
	
	-- Update the Wonder Status screen when it is opened
	if(not bHiding and not m_bUpdated) then
		RefreshLayout();
		m_bUpdated = true;
	elseif (bHiding and m_bUpdated) then
		m_bUpdated = false;
	end
end);
	
---------------------------------------------
-- OnConsultOracle
---------------------------------------------
function OnConsultOracle()
	-- Consult candidates are no longer valid, since the Oracle has been consulted
	ValidConsulters = {};
	
	local savedData = Modding.OpenSaveData();
	local iPlayer = OracleConsulter:GetOwner();
	
	local iNumConsults = savedData.GetValue(string.format("Player%iOracleConsults", iPlayer));
	if (iNumConsults == nil) then
		iNumConsults = 1;
	else
		iNumConsults = iNumConsults + 1;
	end
	savedData.SetValue(string.format("Player%iOracleConsults", iPlayer), iNumConsults);
	if (iPlayer == 0) then
		CheckConsultAchievement();
	end
	
	savedData.SetValue(string.format("Player%iOracleLastConsultedTurn", iPlayer), Game.GetGameTurn());
	OracleConsulter:SetScenarioData(UNITDATA_ORACLE_VISITED);
	OracleConsulter = nil;
	
	if (UIManager:IsModal(Controls.ConsultPopup)) then 
		-- The consult dialog is open (the consulter is the human player), so close it and show the Wonder Status screen
		UIManager:PopModal(Controls.ConsultPopup);
		UIManager:QueuePopup(ContextPtr, PopupPriority.eUtmost);
	end
end
Controls.YesConsultButton:RegisterCallback(Mouse.eLClick, OnConsultOracle);

---------------------------------------------
-- OnRefuseOracle
---------------------------------------------
function OnRefuseOracle()
	UIManager:PopModal(Controls.ConsultPopup);
	OracleConsulter = nil;
end
Controls.NoConsultButton:RegisterCallback(Mouse.eLClick, OnRefuseOracle);


-----------------------------------------------------------------
-- UI Functions (ConsultPopup)
-----------------------------------------------------------------
---------------------------------------------
-- AskToConsultOracle
---------------------------------------------
function AskToConsultOracle()
	local iPlayer = OracleConsulter:GetOwner();
	if (iPlayer == 0) then -- Player is human, so show dialog UI
		if (ContextPtr:IsHidden() == false) then
			UIManager:DequeuePopup(ContextPtr);
		end
		local unitName = OracleConsulter:GetName(); -- Already localised when it is initially set within CvUnit class
		local message = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_POPUP_ASK_CONSULT_ORACLE", unitName, ORACLE_CONSULT_DURATION);
		Controls.PromptText:SetText(message);
		UIManager:PushModal(Controls.ConsultPopup, false);
	else -- Player is not human, so just consult by default
		OnConsultOracle();
		NotifyOracleConsulted(iPlayer);
	end
end

-----------------------------------------------------------------
-- UI Functions (StatusPopup)
-----------------------------------------------------------------
-------------------------------------------------
-- BuildLayout
-- Should only be called once!!
-------------------------------------------------
function BuildLayout()

	CivIconHookup(0, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true); -- Set the icon for player's civ

	AddWonderCategoryHeader(Controls.TopLeftColumn, "TXT_KEY_WONDER_SCENARIO_MYSTICAL_WONDER_HEADING");
	AddWonderEntry(Controls.TopLeftColumn, 9);

	AddWonderCategoryHeader(Controls.LeftColumn, "TXT_KEY_WONDER_SCENARIO_CULTURAL_WONDER_HEADING");
	AddWonderEntry(Controls.LeftColumn, 1);
	AddWonderEntry(Controls.LeftColumn, 2);

	AddWonderCategoryHeader(Controls.LeftColumn, "TXT_KEY_WONDER_SCENARIO_ECONOMIC_WONDER_HEADING");
	AddWonderEntry(Controls.LeftColumn, 3);
	AddWonderEntry(Controls.LeftColumn, 4);

	AddWonderCategoryHeader(Controls.RightColumn, "TXT_KEY_WONDER_SCENARIO_SCIENTIFIC_WONDER_HEADING");
	AddWonderEntry(Controls.RightColumn, 5);
	AddWonderEntry(Controls.RightColumn, 6);

	AddWonderCategoryHeader(Controls.RightColumn, "TXT_KEY_WONDER_SCENARIO_MILITARY_WONDER_HEADING");
	AddWonderEntry(Controls.RightColumn, 7);
	AddWonderEntry(Controls.RightColumn, 8);
	
	Controls.LeftColumn:CalculateSize();
	Controls.LeftColumn:ReprocessAnchoring();
	Controls.RightColumn:CalculateSize();
	Controls.RightColumn:ReprocessAnchoring();
	Controls.TopLeftColumn:CalculateSize();
	Controls.TopLeftColumn:ReprocessAnchoring();
	
end

-------------------------------------------------
-- AddWonderCategoryHeader
-------------------------------------------------
function AddWonderCategoryHeader(columnStack, label)
	local controlTable = {};
	ContextPtr:BuildInstanceForControl("WonderCategoryHeaderLInstance", controlTable, columnStack);
	controlTable.CategoryText:LocalizeAndSetText(label);
	return controlTable;
end

-------------------------------------------------
-- AddWonderEntry
-------------------------------------------------
function AddWonderEntry(columnStack, iWonder)
	local wonder = Wonders[iWonder];
	local wonderInstance = {};
	
	ContextPtr:BuildInstanceForControl("WonderEntryInstance", wonderInstance, columnStack);
	
	wonder.UIControls = {
		WonderEntryInstance = wonderInstance,
	};
	
	IconHookup(wonder.PortraitIndex, 64, wonder.IconAtlas, wonderInstance.WonderIcon);
	
	UpdateWonderUIState(0, iWonder); -- For first player, the one seeing the UI
end

-------------------------------------------------
-- UpdateOracleHelp
-------------------------------------------------
function UpdateOracleHelp(iActivePlayer)
	local oracle = Wonders[9];
	if (oracle.BuiltBy == nil) then
		-- Case 1: Oracle has not been built yet
		Controls.WonderHelpText:SetHide(true);
	else
		local message = "";
		local color = COLOR_NORMAL;
		if (IsOracleConsultationActive(iActivePlayer)) then
			-- Case 2A: Oracle is built, and player can see information from it
			color = COLOR_ORACLE_TEXT;
			local savedData = Modding.OpenSaveData();
			local iOracleLastConsulted = savedData.GetValue(string.format("Player%iOracleLastConsultedTurn", iActivePlayer));
			local iTurnsUsed = Game.GetGameTurn() - iOracleLastConsulted;
			local iTurnsLeft = ORACLE_CONSULT_DURATION - iTurnsUsed;
			message = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_CONSULT_ORACLE_ACTIVE", iTurnsLeft);
		else
			-- Case 2B: Oracle is built, but consultation is not active
			local iOracleCity = oracle.CityIn;
			local pOracleOwner = Players[oracle.OwnedBy];
			local cOracleCity = pOracleOwner:GetCityByID(iOracleCity);
			local cityNameKey = cOracleCity:GetNameKey();
			message = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_CONSULT_ORACLE_HELP", cityNameKey);
		end
		Controls.WonderHelpText:SetHide(false);
		Controls.WonderHelpText:SetColor(color, 0);
		Controls.WonderHelpText:SetText(message);
	end
end

-------------------------------------------------
-- UpdateWonderUIState
-------------------------------------------------
function UpdateWonderUIState(iPlayer, iWonder)
	local wonder = Wonders[iWonder];
	
	-- Determine wonder state
	if (wonder.BuiltBy ~= nil) then
		-- Case 1: Wonder is already built, so show it's status regardless of player's progress towards it
		if (IsCaptured(iWonder)) then
			SetWonderUIState(iPlayer, iWonder, "captured");
		else
			SetWonderUIState(iPlayer, iWonder, "built");
		end
	else
		-- Case 2: Wonder is not built yet, so show the player's individual progress
		if (IsUnlocked(iPlayer, iWonder)) then
			local cBuildCity = GetBuildCity(iPlayer, iWonder);
			if (cBuildCity ~= nil) then
				SetWonderUIState(iPlayer, iWonder, "building");
			else
				SetWonderUIState(iPlayer, iWonder, "unlocked");
			end
		else
			SetWonderUIState(iPlayer, iWonder, "locked");
		end
	end
end

-------------------------------------------------
-- SetWonderUIState
-------------------------------------------------
function SetWonderUIState(iPlayer, iWonder, sState)
	local wonder = Wonders[iWonder];
	local instanceControl = wonder.UIControls.WonderEntryInstance;
	
	if (sState == "locked" or sState == "unlocked" or sState == "building") then
		instanceControl.NotBuilt_InfoGroup:SetHide(false);
		instanceControl.Built_InfoGroup:SetHide(true);
	else
		instanceControl.NotBuilt_InfoGroup:SetHide(true);
		instanceControl.Built_InfoGroup:SetHide(false);
	end
	
	-- Wonder Icon
	local vIconColor = COLOR_NORMAL;
	if (sState == "locked") then
		vIconColor = COLOR_GREYED_OUT;
	end
	instanceControl.WonderIcon:SetColor(vIconColor);
	
	-- Wonder Owner Icon
	if (sState == "built" or sState == "captured") then
		instanceControl.OwnerCivIcon:SetHide(false);
		CivIconHookup(wonder.OwnedBy, 32, instanceControl.OwnerIcon, instanceControl.OwnerIconBG, instanceControl.OwnerIconShadow, false, true);
	else
		instanceControl.OwnerCivIcon:SetHide(true);
	end
	
	-- Text for the Wonder and its primary info
	local mainText = "";
	local statusText = "";
	local statusPlayer;
	if (sState == "locked" or sState == "unlocked" or sState == "building") then
		-- Case 1: Wonder is not built yet, so use the NotBuilt elements of the UI
		if (sState == "locked") then
			mainText = string.format("%s (%i/%i)", Locale.Lookup(wonder.Building.Description), GetUnlockProgress(iPlayer, iWonder), wonder.NeededProgress);
			statusText = string.format ("%s", Locale.Lookup("TXT_KEY_WONDER_SCENARIO_LOCKED"));
			statusPlayer = iPlayer;
		elseif (sState == "unlocked") then
			mainText = string.format("%s (%i/%i [ICON_PRODUCTION])", Locale.Lookup(wonder.Building.Description), 0, GetBuildProgressNeeded(iPlayer, iWonder));
			statusText = string.format ("%s", Locale.Lookup("TXT_KEY_WONDER_SCENARIO_UNLOCKED"));
			statusPlayer = iPlayer;
		elseif (sState == "building") then
			local city = GetBuildCity(iPlayer, iWonder);
			local cityNameKey = city:GetNameKey();
			mainText = string.format("%s (%i/%i [ICON_PRODUCTION])", Locale.Lookup(wonder.Building.Description), GetBuildProgress(iPlayer, iWonder), GetBuildProgressNeeded(iPlayer, iWonder));
			statusText = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_UNDER_CONSTRUCTION", cityNameKey);
			statusPlayer = iPlayer;
		end
		instanceControl.NotBuilt_Text1:SetText(statusText);
		CivIconHookup(statusPlayer, 32, instanceControl.NotBuilt_Icon1, instanceControl.NotBuilt_IconBG1, instanceControl.NotBuilt_IconShadow1, false, true);
	else
		-- Case 2: Wonder is built, so use the Built elements of the UI
		if (sState == "built") then
			local builtByPlayer = Players[wonder.BuiltBy];
			local playerDescriptionKey = builtByPlayer:GetCivilizationDescriptionKey();
			local city = Players[wonder.OwnedBy]:GetCityByID(wonder.CityIn); -- Look up the city by the owner player, to ensure we always get the name
			local cityNameKey = city:GetNameKey();
			mainText = Locale.Lookup(wonder.Building.Description);
			statusText = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_BUILT_BY", playerDescriptionKey, cityNameKey);
			statusPlayer = wonder.BuiltBy;
		else
			local capturerPlayer = Players[wonder.OwnedBy];
			local playerDescriptionKey = capturerPlayer:GetCivilizationDescriptionKey();
			mainText = Locale.Lookup(wonder.Building.Description);
			statusText = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_CAPTURED_BY", playerDescriptionKey);
			statusPlayer = wonder.OwnedBy;
		end
		instanceControl.Built_Text1:SetText(statusText);
		CivIconHookup(statusPlayer, 32, instanceControl.Built_Icon1, instanceControl.Built_IconBG1, instanceControl.Built_IconShadow1, false, true);
	end
	instanceControl.WonderText:SetText(mainText);
	
	-- Secondary info (Oracle message or original owner)
	if (sState == "locked" or sState == "unlocked" or sState == "building") then
		-- Case 1: Secondary Status is the Oracle message, if active
		local bShow = (IsOracleConsultationActive(iPlayer) and iWonder ~= 9);
		ShowOracleMessage(bShow, iPlayer, iWonder, instanceControl);
	else
		-- Case 2: Secondary Status is the original builder of the Wonder, if it has been captured
		if (sState == "captured") then
			instanceControl.Built_Info2:SetHide(false);
			local builtByPlayer = Players[wonder.BuiltBy];
			local playerDescriptionKey = builtByPlayer:GetCivilizationDescriptionKey();
			local city = Players[wonder.OwnedBy]:GetCityByID(wonder.CityIn); -- Look up the city by the owner player, to ensure we always get the name
			local cityNameKey = city:GetNameKey();
			local builderText = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_BUILT_BY", playerDescriptionKey, cityNameKey);
			instanceControl.Built_Text2:SetText(builderText);
			CivIconHookup(wonder.BuiltBy, 32, instanceControl.Built_Icon2, instanceControl.Built_IconBG2, instanceControl.Built_IconShadow2);
		else
			instanceControl.Built_Info2:SetHide(true);
		end
	end
	
	-- Progress Bar
	if (sState == "built" or sState == "captured") then
		instanceControl.ProgressBarControl:SetHide(true);
	else
		instanceControl.ProgressBarControl:SetHide(false);
		local vBarColor;
		local iNeededProgress;
		local iProgress;
		if (sState == "locked") then
			local cColor = GameInfo.Colors[wonder.ProgressBarColor];
			vBarColor = Vector4(cColor.Red, cColor.Green, cColor.Blue, cColor.Alpha);
			iNeededProgress = wonder.NeededProgress;
			iProgress = GetUnlockProgress(iPlayer, iWonder);
		else 
			vBarColor = COLOR_UNDER_CONSTRUCTION;
			iNeededProgress = GetBuildProgressNeeded(iPlayer, iWonder);
			if (sState == "unlocked") then
				iProgress = 0;
			else
				iProgress = GetBuildProgress(iPlayer, iWonder);
			end
		end
		instanceControl.ProgressBar:SetColor(vBarColor);
		SetProgressBar(instanceControl.ProgressBar, iProgress / iNeededProgress);
	end
	
end

-------------------------------------------------
-- ShowOracleMessage
-------------------------------------------------
function ShowOracleMessage(bShow, iActivePlayer, iWonder, control)
	
	local wonder = Wonders[iWonder];
	
	if (not bShow or wonder.BuiltBy ~= nil) then
		control.NotBuilt_Info2:SetHide(true);
		return;
	end
	
	control.NotBuilt_Info2:SetHide(false);
	control.NotBuilt_Text2:SetColor(COLOR_ORACLE_TEXT, 0);
	
	local iFarthestPlayer = iActivePlayer;
	local iMaxProgress = 0;
	local bMaxUnlocked = false;
	
	for iPlayer = 0, 4 do
		if (iPlayer ~= iActivePlayer) then
			if (IsUnlocked(iPlayer, iWonder)) then
				if (not bMaxUnlocked) then
					bMaxUnlocked = true;
					iMaxProgress = 0;
				end
				local iBuildProgress = GetBuildProgress(iPlayer, iWonder);
				if (iBuildProgress >= iMaxProgress) then
					iMaxProgress = iBuildProgress;
					iFarthestPlayer = iPlayer;
				end
			else
				if (not bMaxUnlocked) then
					local iUnlockProgress = GetUnlockProgress(iPlayer, iWonder);
					if (iUnlockProgress >= iMaxProgress) then
						iMaxProgress = iUnlockProgress;
						iFarthestPlayer = iPlayer;
					end
				end
			end
		end
	end
	
	local message;
	local playerDescriptionKey = Players[iFarthestPlayer]:GetCivilizationDescriptionKey();
	if (bMaxUnlocked) then
		if (IsBuilding(iFarthestPlayer, iWonder)) then
			local cBuildCity = GetBuildCity(iFarthestPlayer, iWonder);
			local cityNameKey = cBuildCity:GetNameKey();
			local cityMessage = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_UNDER_CONSTRUCTION_BY", playerDescriptionKey, cityNameKey);
			message = string.format("%s (%i/%i [ICON_PRODUCTION])", cityMessage, GetBuildProgress(iFarthestPlayer, iWonder), GetBuildProgressNeeded(iFarthestPlayer, iWonder));
		else
			message = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_UNLOCKED_BY", playerDescriptionKey);
		end
	else
		local civMessage = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_LOCKED_BY", playerDescriptionKey);
		message = string.format("%s (%i/%i)", civMessage, GetUnlockProgress(iFarthestPlayer, iWonder), wonder.NeededProgress);
	end
	
	control.NotBuilt_Text2:SetText(message);
	CivIconHookup(iFarthestPlayer, 32, control.NotBuilt_Icon2, control.NotBuilt_IconBG2, control.NotBuilt_IconShadow2, false, true);
	
end

-----------------------------------------------------------------
-- UI Functions (miscellaneous popups)
-----------------------------------------------------------------
-------------------------------------------------
-- NotifyWonderUnlocked
-------------------------------------------------
function NotifyWonderUnlocked(iWonder)

	local wonderDescription = Wonders[iWonder].Building.Description;
	local popupInfo = {
		Data1 = 500,
		Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		Text = Locale.Lookup("TXT_KEY_WONDER_SCENARIO_POPUP_WONDER_UNLOCKED", wonderDescription);
	}
	UI.AddPopup(popupInfo);
end

-------------------------------------------------
-- NotifyOracleBuilt
-------------------------------------------------
function NotifyOracleBuilt()
	local iOraclePlayer = Wonders[9].BuiltBy;
	local pOraclePlayer = Players[iOraclePlayer];
	local sOraclePlayerKey = pOraclePlayer:GetCivilizationDescriptionKey();
	
	local iOracleCity = Wonders[9].CityIn;
	local cOracleCity = pOraclePlayer:GetCityByID(iOracleCity);
	local sOracleCityKey = cOracleCity:GetNameKey();
	
	local popupInfo = {
		Data1 = 500,
		Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		Text =  Locale.Lookup("TXT_KEY_WONDER_SCENARIO_POPUP_ORACLE_BUILT", sOraclePlayerKey, ORACLE_CONSULT_DIST, sOracleCityKey);
	}
	UI.AddPopup(popupInfo);
end

-------------------------------------------------
-- NotifyOracleConsulted
-------------------------------------------------
function NotifyOracleConsulted(iConsulter)
	local pConsulter = Players[iConsulter];
	local strConsulterKey = pConsulter:GetCivilizationDescriptionKey();
	local popupInfo = {
		Data1 = 500,
		Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		Text =  Locale.Lookup("TXT_KEY_WONDER_SCENARIO_POPUP_ORACLE_CONSULTED_BY", strConsulterKey);
	}
	UI.AddPopup(popupInfo);
end

-------------------------------------------------
-- NotifyOracleExpired
-------------------------------------------------
function NotifyOracleExpired()
	local popupInfo = {
		Data1 = 500,
		Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		Text =  Locale.Lookup("TXT_KEY_WONDER_SCENARIO_POPUP_ORACLE_EXPIRED");
	}	
	UI.AddPopup(popupInfo);
end


-- Call Initialization functions
SetVictoryTypes();
Game.SetOption(GameOptionTypes.GAMEOPTION_NO_CITY_RAZING, true);
Game.SetOption(GameOptionTypes.GAMEOPTION_NO_TUTORIAL, true);
Game.SetEstimateEndTurn(300); -- For final score on victory screen not to be crazy inflated
BuildLayout();
LoadWonderData();
UpdateAllProgress();
UpdateScoring();