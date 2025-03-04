-- Civilization 5 Hall of Fame data schema Update
-- Updates the Hall of Fame database to include a couple more tables 
-- for DLC/Mod tracking.
--------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS VictoryDLC(	VictoryRow INTEGER,
										PackageGUID TEXT,
										PackageName TEXT,
										PackageVersion INTEGER);
						
CREATE TABLE IF NOT EXISTS VictoryMods(	VictoryRow INTEGER,
										ModId TEXT,
										ModName TEXT,
										ModVersion INTEGER);
										
pragma user_version = 1;