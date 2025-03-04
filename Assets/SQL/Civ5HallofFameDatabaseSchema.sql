-- Civilization 5 Hall of Fame data
-- Currently only one table is stored for Hall of Fame data.
-- In the future replay data and other information could be stored here.
--------------------------------------------------------------------------
CREATE TABLE Victories( VictoryType TEXT,
						Score INTEGER,
						WinningTurn INTEGER,
						IsMultiplayer INTEGER,
						PlayerTeamWon INTEGER,
						PlayerCivilizationType TEXT,
						PlayerHandicapType TEXT,
						GameEndTime INTEGER,
						PlayerLeaderName TEXT,
						PlayerCivilizationName TEXT,
						WinningTeamLeaderCivilizationType TEXT,
						StartEraType TEXT,
						MapName TEXT,
						WorldSizeType TEXT,
						GameSpeedType TEXT,
						WinningTeamPrimaryColor TEXT,
						WinningTeamSecondaryColor TEXT);
						
CREATE TABLE IF NOT EXISTS VictoryDLC(	VictoryRow INTEGER,
										PackageGUID TEXT,
										PackageName TEXT,
										PackageVersion INTEGER);
						
CREATE TABLE IF NOT EXISTS VictoryMods(	VictoryRow INTEGER,
										ModId TEXT,
										ModName TEXT,
										ModVersion INTEGER);
										
pragma user_version = 1;

