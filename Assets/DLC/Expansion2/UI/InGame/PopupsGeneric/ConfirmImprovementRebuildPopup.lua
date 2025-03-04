
-- CONFIRM IMPROVEMENT REBUILD POPUP
-- This popup occurs when the player is trying to construct an Improvement over the top of another one.
PopupLayouts[ButtonPopupTypes.BUTTONPOPUP_CONFIRM_IMPROVEMENT_REBUILD] = function(popupInfo)

	local iAction		= popupInfo.Data1;
	local iBuild		= popupInfo.Data2;
	local bAlt		= popupInfo.Option1;

	local pAction = GameInfoActions[iAction];
	local pBuild = GameInfo.Builds[iBuild];
	if (pAction.Type == "MISSION_FOUND") then
		popupText = Locale.ConvertTextKey("TXT_KEY_POPUP_ARE_YOU_SURE_FOUND_ON_DIG_SITE", pAction.TextKey);
		SetPopupText(popupText);
	else
		popupText = Locale.ConvertTextKey("TXT_KEY_POPUP_ARE_YOU_SURE_IMPROVEMENT_REBUILD", pAction.TextKey);
		SetPopupText(popupText);
	end	
		
	-- Initialize 'yes' button.
	local OnYesClicked = function()
		
		-- Confirm action
		local gameMessagePushMission = GameMessageTypes.GAMEMESSAGE_PUSH_MISSION;
		Game.SelectionListGameNetMessage(gameMessagePushMission, pAction.MissionType, pAction.MissionData, -1, 0, bAlt);
	end
	
	local buttonText = Locale.ConvertTextKey("TXT_KEY_POPUP_YES");
	AddButton(buttonText, OnYesClicked)
		
	-- Initialize 'no' button.
	local buttonText = Locale.ConvertTextKey("TXT_KEY_POPUP_NO");
	AddButton(buttonText, nil);

end
