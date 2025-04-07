-- WonderScenarioInlandSeaMapScript
-- Author: astrenger
-- DateCreated: 7/18/2011 1:25:56 PM
--------------------------------------------------------------
-- Overwrites InlandSea.lua map script to give
-- civs contact with each other in the DLC 6
-- Wonder Scenario
----------------------------------------------------------------

include("InlandSea");

local fnInlandSea_StartPlotSystem = StartPlotSystem;

function StartPlotSystem()
	-- Call the StartPlotSystem function from the InlandSea script
	fnInlandSea_StartPlotSystem();
	
	-- Enable contact with other major civs
	for iPlayer = 0, 4 do
		local pPlayer = Players[iPlayer];
		local pTeam = Teams[pPlayer:GetTeam()];
		for iOtherPlayer = 0, 4 do
			if (iOtherPlayer ~= iPlayer) then
				local pOtherPlayer = Players[iOtherPlayer];
				local pOtherTeam = Teams[pOtherPlayer:GetTeam()];
				local iOtherTeam = pOtherTeam:GetID()
				if (not pTeam:IsHasMet(iOtherTeam)) then
					pTeam:Meet(iOtherTeam);
				end
			end
		end
	end

end