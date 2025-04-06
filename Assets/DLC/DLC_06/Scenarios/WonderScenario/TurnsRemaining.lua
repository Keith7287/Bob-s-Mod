-- TurnsRemaining
-- Author: ebeach
-- DateCreated: 1/20/2011 9:35:24 AM
--------------------------------------------------------------
ContextPtr:SetUpdate(function()	
	if (Game.GetGameState() == GameplayGameStateTypes.GAMESTATE_ON) then
		if (Controls.WonderStatus:IsHidden()) then
			Controls.Grid:DoAutoSize();	
			Controls.WonderStatus:CallShowHideHandler(true);
		end
	else
		-- Game Over?  Then hide this.
		ContextPtr:ClearUpdate(); 
		ContextPtr:SetHide( true );
	end	
end);

---------------------------------------------------------------------
function TestVictory()

	local iWondersBuilt = 0;
	local iTopScore = 0;
	local iTopScoreTeam = -1;

	-- Loop through all the Majors checking for victory
	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local player = Players[iPlayerLoop];
		if (player:IsEverAlive()) then

			local iScore = player:GetScore();
			if (iScore > iTopScore) then
				iTopScore = iScore;
				iTopScoreTeam = player:GetTeam();
			end
			
			iWondersBuilt = iWondersBuilt + player:GetNumWorldWonders();
		end
	end

	if (Game.GetGameState() == GameplayGameStateTypes.GAMESTATE_ON and iWondersBuilt >= 9) then
		PreGame.SetGameOption("GAMEOPTION_NO_EXTENDED_PLAY", true);	-- No extended play allowed
       	Game.SetWinner(iTopScoreTeam , GameInfo.Victories["VICTORY_TIME"].ID);
		GameEvents.GameCoreTestVictory.Remove(TestVictory);
	else
		if (Game.GetGameState() == GameplayGameStateTypes.GAMESTATE_EXTENDED) then
			PreGame.SetGameOption("GAMEOPTION_NO_EXTENDED_PLAY", true);	-- No extended play allowed
			Game.SetGameState(GameplayGameStateTypes.GAMESTATE_OVER);
			GameEvents.GameCoreTestVictory.Remove(TestVictory);
		end
	end
end
GameEvents.GameCoreTestVictory.Add(TestVictory);

---------------------------------------------------------------------
function OnBriefingButton()
    UI.AddPopup( { Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
                   Data1 = 800,
                   Option1 = true,
                   Text = "TXT_KEY_WONDER_SCENARIO_CIV5_DAWN_TEXT" } );
end
Controls.BriefingButton:RegisterCallback( Mouse.eLClick, OnBriefingButton );

function OnWonderStatusButton()
	UIManager:QueuePopup(Controls.WonderStatus, PopupPriority.eUtmost);
end
Controls.WonderStatusButton:RegisterCallback(Mouse.eLClick, OnWonderStatusButton)

---------------------------------------------------------------------
function OnEnterCityScreen()
    ContextPtr:SetHide( true );
end
Events.SerialEventEnterCityScreen.Add( OnEnterCityScreen );

---------------------------------------------------------------------
function OnExitCityScreen()

	if (Game:GetGameState() ~= GameplayGameStateTypes.GAMESTATE_EXTENDED) then 
    		ContextPtr:SetHide( false );
	end
end
Events.SerialEventExitCityScreen.Add( OnExitCityScreen );