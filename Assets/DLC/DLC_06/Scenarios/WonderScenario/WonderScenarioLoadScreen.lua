----------------------------------------------------------------
include( "IconSupport" );
include( "UniqueBonuses" );

----------------------------------------------------------------
-- Global Constants
----------------------------------------------------------------
MOD_ID = "2968ab37-29a3-4de7-8b84-ece688231e40";
MOD_VERSION = 1;

ScenarioCivilizations = {
	[0] = "CIVILIZATION_EGYPT",
	[1] = "CIVILIZATION_GREECE",
	[2] = "CIVILIZATION_ARABIA",
	[3] = "CIVILIZATION_PERSIA",
	[4] = "CIVILIZATION_OTTOMAN",
}

----------------------------------------------------------------
-- Global Variables
----------------------------------------------------------------
g_CurrentPlayerIndex = nil; --default to random
g_CurrentMap = nil;

----------------------------------------------------------------
function OnBack()
	if(not Controls.SelectCivScrollPanel:IsHidden()) then
		ToggleCivSelection();
	else
		UIManager:DequeuePopup( ContextPtr );
	end
end
----------------------------------------------------------------       
Controls.BackButton:RegisterCallback(Mouse.eLClick, OnBack);
----------------------------------------------------------------
ContextPtr:SetInputHandler( function(uiMsg, wParam, lParam)
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
			OnBack();
        end
    end
    return true;
end);
----------------------------------------------------------------
-- Handle Start Button
Controls.StartButton:RegisterCallback(Mouse.eLClick, function()
	
	-- Shared settings
	PreGame.Reset(); -- just in case.
		
	if (g_CurrentMap ~= nil) then
		PreGame.SetMapScript(g_CurrentMap);
		PreGame.SetLoadWBScenario(true);
		UI.ResetScenarioPlayerSlots(true);
		PreGame.SetOverrideScenarioHandicap(true);
		PreGame.SetHandicap(0, g_CurrentDifficulty);
		for row in GameInfo.Victories() do
			if (row.ID == GameInfo.Victories["VICTORY_CULTURAL"].ID) then
				PreGame.SetVictory(row.ID, true);
			else
				PreGame.SetVictory(row.ID, false);
			end
		end

		local playerIndex = g_CurrentPlayerIndex;
		if(playerIndex == nil) then
			playerIndex = math.random(0, table.count(ScenarioCivilizations) - 1);
		end
	
		-- Swap Civilization to make active player the new index.
		if(playerIndex ~= nil) then
			UI.MoveScenarioPlayerToSlot( playerIndex, 0 );
		end
		
	else

		PreGame.SetLoadWBScenario(false);
		PreGame.SetNumMinorCivs(13);
	
		-- MAP SCRIPT SPECIFIC SETTINGS
		PreGame.SetWorldSize(GameInfo.Worlds.WORLDSIZE_STANDARD.ID);
		PreGame.ResetSlots();

		for i = 0, 4, 1 do
			PreGame.SetCivilization(i, GameInfo.Civilizations[ScenarioCivilizations[i]].ID);
		end
		for i = 1, 4, 1 do
			PreGame.SetSlotStatus(i, SlotStatus.SS_COMPUTER);
			PreGame.SetSlotClaim(i, SlotClaim.SLOTCLAIM_ASSIGNED);
		end
		for i = 5, 9, 1 do
			PreGame.SetSlotStatus(i, SlotStatus.SS_CLOSED);
		end
	
		local playerIndex = g_CurrentPlayerIndex;
		if(playerIndex == nil) then
			playerIndex = math.random(0, table.count(ScenarioCivilizations) - 1);
		end
	
		-- Swap Civilization to make active player the new index.
		if(playerIndex ~= nil) then
			PreGame.SetCivilization(0, GameInfo.Civilizations[ScenarioCivilizations[playerIndex]].ID);
			PreGame.SetCivilization(playerIndex, GameInfo.Civilizations[ScenarioCivilizations[0]].ID);
		end
	
		PreGame.SetHandicap(0, g_CurrentDifficulty);
		PreGame.RandomizeMapSeed();
		local randomMap = Modding.GetEvaluatedFilePath(MOD_ID, MOD_VERSION, "WonderScenarioInlandSeaMapScript.lua");
		PreGame.SetMapScript(randomMap.EvaluatedPath);
		
		PreGame.SetGameOption("GAMEOPTION_NO_TUTORIAL", true);
	end

	Events.SerialEventStartGame();
	UIManager:SetUICursor( 1 );
--	UIManager:DequeuePopup( ContextPtr );
end);
----------------------------------------------------------------

function DifficultySelected(button, difficulty)
	g_CurrentDifficulty = difficulty;
	g_CurrentDifficultyButton.SelectionAnim:SetHide(true);

	button.SelectionAnim:SetHide(false);
	g_CurrentDifficultyButton = button;
end

function MapSelected(selectionAnim, map)
	g_CurrentMap = map;
	g_CurrentMapSelectionAnim:SetHide(true);
	
	selectionAnim:SetHide(false);
	g_CurrentMapSelectionAnim = selectionAnim;
end

function Initialize()
	
	local defaultDifficulty = GameInfo.HandicapInfos["HANDICAP_PRINCE"];
	if(defaultDifficulty == nil) then
		defaultDifficulty = GameInfo.HandicapInfos()();	-- Get first handicap found.
	end

	g_CurrentDifficulty = defaultDifficulty.ID;
	
	----------------------------------------------------------------        
	-- build the buttons
	----------------------------------------------------------------        
	for info in GameInfo.HandicapInfos() do
		local controlTable = {};
		ContextPtr:BuildInstanceForControl( "ItemInstance", controlTable, Controls.DifficultyStack );

		if(info.ID == g_CurrentDifficulty) then
			g_CurrentDifficultyButton = controlTable;
			controlTable.SelectionAnim:SetHide(false);
		end

		IconHookup( info.PortraitIndex, 64, info.IconAtlas, controlTable.Icon );
		controlTable.Help:LocalizeAndSetText(info.Help);
		controlTable.Name:LocalizeAndSetText(info.Description);
		controlTable.Button:SetToolTipString(Locale.ConvertTextKey( info.Help ) );
		controlTable.Button:RegisterCallback(Mouse.eLClick, function() DifficultySelected(controlTable, info.ID); end);
	end
	
	Controls.CivilizationButton:RegisterCallback(Mouse.eLClick, function() ToggleCivSelection() end);

	Controls.DifficultyStack:CalculateSize();
	Controls.DifficultyStack:ReprocessAnchoring();
	Controls.DifficultyScrollPanel:CalculateInternalSize();
	
	Controls.RandomMapButton:RegisterCallback(Mouse.eLClick, function() MapSelected(Controls.RandomMapSelectionAnim, nil); end);
	
	local historicalMap = Modding.GetEvaluatedFilePath(MOD_ID, MOD_VERSION, "WonderScenario.Civ5Map");
	Controls.FixedMapButton:RegisterCallback(Mouse.eLClick, function() MapSelected(Controls.FixedMapSelectionAnim, historicalMap.EvaluatedPath); end);
	
	Controls.RandomMapSelectionAnim:SetHide(false);
	g_CurrentMapSelectionAnim = Controls.RandomMapSelectionAnim;	
		
	BuildCivSelectList();
	
	SetPlayerIndex(g_CurrentPlayerIndex);
end

function ToggleCivSelection()
	if(not Controls.SelectCivScrollPanel:IsHidden()) then
		Controls.SelectCivScrollPanel:SetHide(true);
		Controls.DifficultySelectionBox:SetHide(false);
		Controls.MapSelectionBox:SetHide(false);
		Controls.DoMBox:SetHide(false);
		Controls.StartButton:SetHide(false);
	else
		BuildCivSelectList();
		Controls.SelectCivScrollPanel:SetHide(false);
		Controls.DifficultySelectionBox:SetHide(true);
		Controls.MapSelectionBox:SetHide(true);
		Controls.DoMBox:SetHide(true);
		Controls.StartButton:SetHide(true);
	end
end

function BuildCivSelectList()

	Controls.SelectCivStack:DestroyAllChildren(); 
	
	--Create Random Selection Entry if it's not already selected
	if(g_CurrentPlayerIndex ~= nil) then

		local controlTable = {};
		ContextPtr:BuildInstanceForControl( "SelectCivInstance", controlTable, Controls.SelectCivStack );
		
		controlTable.Button:SetVoid1( -1 );
		controlTable.Button:RegisterCallback( Mouse.eLClick, function() SetPlayerIndex(nil); ToggleCivSelection(); end );

		controlTable.Title:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER");
		controlTable.Description:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER_HELP");
		IconHookup( 22, 128, "LEADER_ATLAS", controlTable.Portrait );
		
		if(questionOffset ~= nil) then       
			controlTable.Icon:SetTexture( questionTextureSheet );
			controlTable.Icon:SetTextureOffset( questionOffset );
			controlTable.IconShadow:SetTexture( questionTextureSheet );
			controlTable.IconShadow:SetTextureOffset( questionOffset );
		end
		
		local primaryColor       = GameInfo.Colors.COLOR_DARK_GREY;
		local primaryColorVector = Vector4( primaryColor.Red, primaryColor.Green, primaryColor.Blue, primaryColor.Alpha );
		controlTable.Icon:SetColor( primaryColorVector );
		
		local secondaryColor       = GameInfo.Colors.COLOR_LIGHT_GREY;
		local secondaryColorVector = Vector4( secondaryColor.Red, secondaryColor.Green, secondaryColor.Blue, secondaryColor.Alpha );
		controlTable.TeamColor:SetColor( secondaryColorVector );
	
		-- Sets Trait bonus Text
		controlTable.BonusTitle:LocalizeAndSetText("TXT_KEY_MISC_RANDOMIZE");
		controlTable.BonusDescription:SetText( "" );
	
		 -- Sets Bonus Icons
		local maxSmallButtons = 2;
		for buttonNum = 1, maxSmallButtons, 1 do
			local buttonName = "B"..tostring(buttonNum);
			controlTable[buttonName]:SetTexture( questionTextureSheet );
			controlTable[buttonName]:SetTextureOffset( questionOffset );
			controlTable[buttonName]:SetToolTipString( unknownString );
			controlTable[buttonName]:SetHide(false);
			local buttonFrameName = "BF"..tostring(buttonNum);
			controlTable[buttonFrameName]:SetHide(false);
		end
	end 
		 
	for playerIndex, civType in pairs(ScenarioCivilizations) do
		if(playerIndex ~= g_CurrentPlayerIndex) then
		
			local civ = GameInfo.Civilizations[civType];
			
			-- Use the Civilization_Leaders table to cross reference from this civ to the Leaders table
			local leader = GameInfo.Leaders[GameInfo.Civilization_Leaders( "CivilizationType = '" .. civ.Type .. "'" )().LeaderheadType];
			local leaderDescription = leader.Description;
		    
			local colorSet = GameInfo.PlayerColors[civ.DefaultPlayerColor];
		    
			local primaryColor       = GameInfo.Colors[colorSet.PrimaryColor];
			local primaryColorVector = Vector4( primaryColor.Red, primaryColor.Green, primaryColor.Blue, primaryColor.Alpha );
		    
			local secondaryColor       = GameInfo.Colors[colorSet.SecondaryColor];
			local secondaryColorVector = Vector4( secondaryColor.Red, secondaryColor.Green, secondaryColor.Blue, secondaryColor.Alpha );
		        
			local controlTable = {};
			ContextPtr:BuildInstanceForControl( "SelectCivInstance", controlTable, Controls.SelectCivStack );
		    
			controlTable.Button:SetVoid1( civ.ID );
			controlTable.Button:RegisterCallback( Mouse.eLClick, function() SetPlayerIndex(playerIndex); ToggleCivSelection(); end);
		    
			controlTable.Title:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER_CIV", leaderDescription, civ.ShortDescription);
			controlTable.Description:SetText( Locale.ConvertTextKey( civ.Description ) );

			IconHookup( leader.PortraitIndex, 128, leader.IconAtlas, controlTable.Portrait );
			local textureOffset, textureAtlas = IconLookup( civ.PortraitIndex, 64, civ.IconAtlas );
			if textureOffset ~= nil then       
				controlTable.Icon:SetTexture( textureAtlas );
				controlTable.Icon:SetTextureOffset( textureOffset );
				controlTable.IconShadow:SetTexture( textureAtlas );
				controlTable.IconShadow:SetTextureOffset( textureOffset );
			end

			controlTable.Icon:SetColor( primaryColorVector );
			controlTable.TeamColor:SetColor( secondaryColorVector );
		    
			-- Sets Trait bonus Text
			local leaderTrait = GameInfo.Leader_Traits("LeaderType ='" .. leader.Type .. "'")();
			local trait = leaderTrait.TraitType;
			local gameTrait = GameInfo.Traits[trait];
			controlTable.BonusTitle:SetText( Locale.ConvertTextKey( gameTrait.ShortDescription ));
			controlTable.BonusDescription:SetText( Locale.ConvertTextKey( gameTrait.Description ));
		 
			PopulateUniqueBonuses( controlTable, civ, leader );
		end
	end
	
	Controls.SelectCivStack:CalculateSize();
	Controls.SelectCivStack:ReprocessAnchoring();
	Controls.SelectCivScrollPanel:CalculateInternalSize();
end

function SetPlayerIndex(playerIndex)
	g_CurrentPlayerIndex = playerIndex;
		
	if(playerIndex ~= nil) then
		
		--Set up items for specified player.
		local civType = ScenarioCivilizations[playerIndex];

		-- Use the Civilization_Leaders table to cross reference from this civ to the Leaders table
		local civ = GameInfo.Civilizations[civType];
		local leader = GameInfo.Leaders[GameInfo.Civilization_Leaders( "CivilizationType = '" .. civ.Type .. "'" )().LeaderheadType];
		local leaderDescription = leader.Description;

		-- Set Leader & Civ Text
		Controls.Title:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER_CIV", leaderDescription, civ.ShortDescription);

		-- Set Civ Leader Icon
		IconHookup( leader.PortraitIndex, 128, leader.IconAtlas, Controls.Portrait );
			
		-- Set Civ Icon
		IconHookup( civ.PortraitIndex, 64, civ.IconAtlas, Controls.IconShadow );
			
		-- Sets Trait bonus Text
		local leaderTrait = GameInfo.Leader_Traits("LeaderType ='" .. leader.Type .. "'")();
		local trait = leaderTrait.TraitType;
		Controls.BonusTitle:LocalizeAndSetText(GameInfo.Traits[trait].ShortDescription);
		Controls.BonusDescription:LocalizeAndSetText(GameInfo.Traits[trait].Description);

		---- Sets Bonus Icons
		PopulateUniqueBonuses( Controls, civ, leader );

	        
		-- Sets Dawn of Man Quote
		Controls.Quote:LocalizeAndSetText(civ.DawnOfManQuote or "");
    else
		-- Setup entry for random player.

		Controls.Title:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER");
		--controlTable.Description:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER_HELP");
		IconHookup( 22, 128, "LEADER_ATLAS", Controls.Portrait  );
		
		if(questionOffset ~= nil) then       
			--controlTable.Icon:SetTexture( questionTextureSheet );
			--controlTable.Icon:SetTextureOffset( questionOffset );
			Controls.IconShadow:SetTexture( questionTextureSheet );
			Controls.IconShadow:SetTextureOffset( questionOffset );
		end
			
		-- Sets Trait bonus Text
		Controls.BonusTitle:LocalizeAndSetText("TXT_KEY_MISC_RANDOMIZE");
		Controls.BonusDescription:SetText( "" );
	
		 -- Sets Bonus Icons
		local maxSmallButtons = 2;
		for buttonNum = 1, maxSmallButtons, 1 do
			local buttonName = "B"..tostring(buttonNum);
			Controls[buttonName]:SetTexture( questionTextureSheet );
			Controls[buttonName]:SetTextureOffset( questionOffset );
			Controls[buttonName]:SetToolTipString( unknownString );
			Controls[buttonName]:SetHide(false);
			local buttonFrameName = "BF"..tostring(buttonNum);
			Controls[buttonFrameName]:SetHide(false);
		end
		
		-- Sets Dawn of Man Quote
		Controls.Quote:LocalizeAndSetText("TXT_KEY_WONDER_SCENARIO_CIV5_DAWN_TEXT");		
    end

	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();
	Controls.DoMScrollPanel:CalculateInternalSize();
end

Initialize();