-- Civilization 5 Engine Database Schema
-- The following tables are required by the Civ5 engine.
-- Modifying these tables is not recommended.

-- ScannedFiles table used for caching database.
CREATE TABLE ScannedFiles("Path" TEXT NOT NULL PRIMARY KEY, "DateTime" INTEGER NOT NULL);

CREATE TABLE ArtDefine_UnitInfos(	"Type" TEXT NOT NULL PRIMARY KEY,
									"DamageStates" INT,
									"Formation" TEXT,
									"UnitFlagAtlas" TEXT,
									"UnitFlagIconOffset" INT,
									"IconAtlas" TEXT,
									"PortraitIndex" INT
									);

CREATE TABLE ArtDefine_UnitInfoMemberInfos(	"UnitInfoType" TEXT,
											"UnitMemberInfoType" TEXT,
											"NumMembers" INT,
											FOREIGN KEY("UnitInfoType") REFERENCES ArtDefine_UnitInfos("Type")
											FOREIGN KEY("UnitMemberInfoType") REFERENCES ArtDefine_UnitMemberInfos("Type"));
									

-- Art define tables used by cvUnitLibrary
CREATE TABLE ArtDefine_UnitMemberInfos(	"Type" TEXT NOT NULL PRIMARY KEY, 
										"Scale" FLOAT, 
										"ZOffset" FLOAT,
										"Domain" TEXT,										
										"Model" TEXT NOT NULL,
										"MaterialTypeTag" TEXT,
										"MaterialTypeSoundOverrideTag" TEXT);

CREATE TABLE ArtDefine_UnitMemberCombats(
										"UnitMemberType" TEXT NOT NULL PRIMARY KEY, 
										"EnableActions" TEXT,
										"DisableActions" TEXT,
										"MoveRadius" FLOAT,
										"ShortMoveRadius" FLOAT, 
										"ChargeRadius" FLOAT,
										"AttackRadius" FLOAT,
										"RangedAttackRadius" FLOAT,
										"MoveRate" FLOAT,
										"ShortMoveRate" FLOAT,
										"TurnRateMin" FLOAT,
										"TurnRateMax" FLOAT,
										"TurnFacingRateMin" FLOAT,
										"TurnFacingRateMax" FLOAT,
										"RollRateMin" FLOAT,
										"RollRateMax" FLOAT,
										"PitchRateMin" FLOAT,
										"PitchRateMax" FLOAT,
										"LOSRadiusScale" FLOAT,
										"TargetRadius" FLOAT,
										"TargetHeight" FLOAT,
										"HasShortRangedAttack" INTEGER,
										"HasLongRangedAttack" INTEGER,
										"HasLeftRightAttack" INTEGER,
										"HasStationaryMelee" INTEGER,
										"HasStationaryRangedAttack" INTEGER,
										"HasRefaceAfterCombat" INTEGER,
										"ReformBeforeCombat" INTEGER,
										"HasIndependentWeaponFacing" INTEGER,
										"HasOpponentTracking" INTEGER,
										"HasCollisionAttack" INTEGER,
										"AttackAltitude" FLOAT,
										"AltitudeDecelerationDistance" FLOAT,
										"OnlyTurnInMovementActions" INTEGER,
										"RushAttackFormation" TEXT,
										"LastToDie" INTEGER,
										FOREIGN KEY("UnitMemberType") REFERENCES ArtDefine_UnitMemberInfos("Type"));
										
CREATE TABLE ArtDefine_UnitMemberCombatWeapons(	"UnitMemberType" TEXT NOT NULL,
												"Index" INTEGER NOT NULL,
												"SubIndex" INTEGER NOT NULL,
												"ID" TEXT,
												"VisKillStrengthMin" FLOAT,
												"VisKillStrengthMax" FLOAT,
												"ProjectileSpeed" FLOAT,
												"ProjectileTurnRateMin" FLOAT,
												"ProjectileTurnRateMax" FLOAT,
												"HitEffect" TEXT,
												"HitEffectScale" FLOAT,
												"HitRadius" FLOAT,
												"ProjectileChildEffectScale" FLOAT,
												"AreaDamageDelay" FLOAT,
												"ContinuousFire" INTEGER,
												"WaitForEffectCompletion" INTEGER,
												"TargetGround" INTEGER,
												"IsDropped" INTEGER,
												"WeaponTypeTag" TEXT,
												"WeaponTypeSoundOverrideTag" TEXT,
												"MissTargetSlopRadius" FLOAT,												
												PRIMARY KEY("UnitMemberType", "Index" ASC, "SubIndex" ASC));
												
-- Art defines used by cvLandmarkLibrary
CREATE TABLE ArtDefine_LandmarkTypes( "Type" TEXT NOT NULL,
									  "LandmarkType" TEXT NOT NULL,
									  "FriendlyName" TEXT);
									  
CREATE TABLE ArtDefine_Landmarks(	"Era" TEXT DEFAULT "Any",
									"State" TEXT DEFAULT "Any",
									"Scale" FLOAT DEFAULT 1,
									"ImprovementType" TEXT NOT NULL,
									"LayoutHandler" TEXT NOT NULL,
									"ResourceType" TEXT NOT NULL,
									"Model" TEXT,
									"TerrainContour" INTEGER DEFAULT 0,
									"Tech" TEXT,
									FOREIGN KEY("ImprovementType") REFERENCES ArtDefine_LandmarkTypes("Type"),
									FOREIGN KEY("ResourceType") REFERENCES ArtDefine_LandmarkTypes("Type"),
									FOREIGN KEY("LayoutHandler") REFERENCES ArtDefine_LandmarkTypes("Type"));
									
-- Art defines used by Strategic View
CREATE TABLE ArtDefine_StrategicView("StrategicViewType" TEXT,
									 "TileType" TEXT NOT NULL,
									 "Asset" TEXT NOT NULL,
									 PRIMARY KEY("StrategicViewType", "TileType"));	  

-- DLC Definitions
CREATE TABLE DownloadableContent(	"PackageID" TEXT NOT NULL,
									"FriendlyNameKey" TEXT,
									"DescriptionKey" TEXT,
									"Version" INTEGER DEFAULT 1,
									"IsFiraxisContent" INTEGER DEFAULT 0,
									"IsActive" INTEGER DEFAULT 0,
									"IsBaseContentUpgrade" INTEGER DEFAULT 0);

CREATE TABLE Map_Folders(	'Type' TEXT NOT NULL, 
							'ParentType' TEXT, 
							'Title' TEXT NOT NULL, 
							'Description' TEXT NOT NULL,
							'IconIndex' INTEGER DEFAULT 0,
							'IconAtlas' TEXT DEFAULT 'WORLDTYPE_ATLAS',
							PRIMARY KEY('Type'));
								
CREATE TABLE Map_Sizes(	'MapType' TEXT NOT NULL,
						'WorldSizeType' TEXT NOT NULL,
						'FileName' TEXT NOT NULL,
						PRIMARY KEY('MapType', 'WorldSizeType'),
						FOREIGN KEY('MapType') REFERENCES Maps('Type'));


-- Map Script data used by Modding Framework
CREATE TABLE Maps('Type' TEXT PRIMARY KEY,
				  'Name' TEXT NOT NULL,
				  'Description' TEXT NOT NULL,
				  'FolderType' TEXT DEFAULT NULL,
				  'IconIndex' INTEGER DEFAULT 0,
				  'IconAtlas' TEXT DEFAULT 'WORLDTYPE_ATLAS',
				  FOREIGN KEY('FolderType') REFERENCES Map_Folders('Type'));


CREATE TABLE MapScripts('FileName' TEXT PRIMARY KEY COLLATE NOCASE, 
						'Name' TEXT NOT NULL, 
						'Description' TEXT, 
						'IsAdvancedMap' INTEGER DEFAULT 0, 
						'SupportsSinglePlayer' INTEGER DEFAULT 1, 
						'SupportsMultiplayer' INTEGER DEFAULT 1, 
						'DefaultCityStates' INTEGER, 
						'Hidden' INTEGER DEFAULT 0, 
						'IconIndex' INTEGER DEFAULT 0, 
						'IconAtlas' TEXT DEFAULT 'WORLDTYPE_ATLAS',
						'FolderType' TEXT DEFAULT NULL,
						FOREIGN KEY('FolderType') REFERENCES Map_Folders('Type'));

CREATE TABLE MapScriptOptions('FileName' TEXT NOT NULL COLLATE NOCASE, 'OptionID' TEXT NOT NULL, 'Name' TEXT NOT NULL, 'Description' TEXT, 'ReadOnly' INTEGER DEFAULT 0, 'Hidden' INTEGER DEFAULT 0, 'DefaultValue' INTEGER NOT NULL, 'SortPriority' INTEGER NOT NULL);

CREATE TABLE MapScriptOptionPossibleValues('FileName' TEXT NOT NULL COLLATE NOCASE, 'OptionID' TEXT NOT NULL, 'Name' TEXT NOT NULL, 'Description' TEXT, 'Value' INTEGER NOT NULL, 'SortIndex' INTEGER NOT NULL);

CREATE TABLE MapScriptRequiredDLC('FileName' TEXT NOT NULL COLLATE NOCASE, 'PackageID' TEXT NOT NULL);
-- Application
CREATE TABLE ApplicationInfo( "Version" TEXT NOT NULL );

CREATE TRIGGER OnDeleteMapScript AFTER DELETE ON MapScripts BEGIN 
	DELETE FROM MapScriptOptionPossibleValues WHERE FileName = old.FileName;
	DELETE FROM MapScriptOptions WHERE FileName = old.FileName;
	DELETE FROM MApScriptRequiredDLC WHERE FileName = old.FileName;
END; 

CREATE TABLE Audio_SpeakerChannels('SpeakerChannel' TEXT PRIMARY KEY, 'Value' INTEGER NOT NULL);
CREATE TABLE Audio_SoundTypes('SoundType' TEXT PRIMARY KEY);
CREATE TABLE Audio_SoundLoadTypes('SoundLoadType' TEXT PRIMARY KEY, 'Value' INTEGER NOT NULL);
CREATE TABLE Audio_ScriptTypes('ScriptType' TEXT PRIMARY KEY, 'Value' INTEGER NOT NULL);

CREATE TABLE Audio_Sounds('SoundID' TEXT PRIMARY KEY,
						  'FileName' TEXT NOT NULL,
						  'LoadType' TEXT DEFAULT 'DynamicResident',
						  'OnlyLoadOneVariationEachTime' INTEGER DEFAULT 0,
						  'DontCache' INTEGER DEFAULT 0,
						  FOREIGN KEY('LoadType') REFERENCES Audio_SoundLoadTypes('SoundLoadType'));
						  
CREATE TABLE Audio_3DSounds('ScriptID' TEXT PRIMARY KEY, 
							'SoundID' TEXT NOT NULL, 
							'SoundType' TEXT DEFAULT 'GAME_SFX', 
							'MaxVolume' INTEGER DEFAULT 100, 
							'MinVolume' INTEGER DEFAULT 100, 
							'Looping' INTEGER DEFAULT 0,
							'DryLevel' REAL DEFAULT 1.0,
							'WetLevel' REAL DEFAULT 0.0,
							'StartFromRandomPosition' INTEGER DEFAULT 0,
							'DontPlayMoreThan' INTEGER DEFAULT -1,
							'OnlyTriggerOnUnitRuns' INTEGER DEFAULT 0,
							'PercentChanceOfPlaying' INTEGER DEFAULT 100,
							'DontPlay' INTEGER DEFAULT 0,
							'DontTriggerDuplicates' INTEGER DEFAULT 0,
							'DontTriggerDuplicatesOnUnits' INTEGER DEFAULT 0,
							'MinTimeMustNotPlayAgain' INTEGER DEFAULT 0,
							'MaxTimeMustNotPlayAgain' INTEGER DEFAULT 0,
							'IsMusic' INTEGER DEFAULT 0,
							'MinTimeDelay' INTEGER DEFAULT 0,
							'MaxTimeDelay' INTEGER DEFAULT 0,
							'TaperSoundtrackVolume' REAL DEFAULT -1.0,								
							'PitchChangeDown' INTEGER DEFAULT 0,
							'PitchChangeUp' INTEGER DEFAULT 0,
							'Priority' INTEGER DEFAULT 1,											
							'StartPosition' TEXT DEFAULT 'None',
							'EndPosition' TEXT DEFAULT 'None',
							'Channel' TEXT DEFAULT 'None',
							'MinVelocity' INTEGER DEFAULT 0,
							'MaxVelocity' INTEGER DEFAULT 0,
							'DistanceFromListener' REAL DEFAULT 1.0,
							'MinDistance' REAL DEFAULT 64.0,
							'CutoffDistance' REAL DEFAULT 256.0,
							FOREIGN KEY('SoundType') REFERENCES Audio_SoundTypes('SoundType'),
							FOREIGN KEY('Channel') REFERENCES Audio_SpeakerChannels('SpeakerChannel'));
							
							
CREATE TABLE Audio_2DSounds('ScriptID' TEXT PRIMARY KEY, 
							'SoundID' TEXT NOT NULL, 
							'SoundType' TEXT DEFAULT 'GAME_SFX', 
							'MaxVolume' INTEGER DEFAULT 100, 
							'MinVolume' INTEGER DEFAULT 100, 
							'Looping' INTEGER DEFAULT 0,
							'DryLevel' REAL DEFAULT 1.0,
							'WetLevel' REAL DEFAULT 0.0,
							'StartFromRandomPosition' INTEGER DEFAULT 0,
							'DontPlayMoreThan' INTEGER DEFAULT -1,
							'OnlyTriggerOnUnitRuns' INTEGER DEFAULT 0,
							'PercentChanceOfPlaying' INTEGER DEFAULT 100,
							'DontPlay' INTEGER DEFAULT 0,
							'DontTriggerDuplicates' INTEGER DEFAULT 0,
							'DontTriggerDuplicatesOnUnits' INTEGER DEFAULT 0,
							'MinTimeMustNotPlayAgain' INTEGER DEFAULT 0,
							'MaxTimeMustNotPlayAgain' INTEGER DEFAULT 0,
							'IsMusic' INTEGER DEFAULT 0,
							'MinTimeDelay' INTEGER DEFAULT 0,
							'MaxTimeDelay' INTEGER DEFAULT 0,
							'TaperSoundtrackVolume' REAL DEFAULT -1.0,								
							'PitchChangeDown' INTEGER DEFAULT 0,
							'PitchChangeUp' INTEGER DEFAULT 0,
							'Priority' INTEGER DEFAULT 1,
							'MinRightPan' INTEGER DEFAULT 0,
							'MaxRightPan' INTEGER DEFAULT 0,
							'MinLeftPan' INTEGER DEFAULT 0,
							'MaxLeftPan' INTEGER DEFAULT 0, 
							FOREIGN KEY('SoundType') REFERENCES Audio_SoundTypes('SoundType'));
						  
CREATE TABLE Audio_SoundScapes('ScriptID' TEXT PRIMARY KEY,
							   'MinVolume' INTEGER DEFAULT 100,
							   'MaxVolume' INTEGER DEFAULT 100,
							   'MinGridDistance' REAL DEFAULT 0.0,
							   'MaxGridDistance' REAL DEFAULT 0.0,
							   'Priority' REAL DEFAULT 1.0);
							   
							   
CREATE TABLE Audio_SoundScapeElements('ScriptID' TEXT NOT NULL,
									  'SoundScapeIndex' INTEGER NOT NULL,
									  'ScriptType' TEXT NOT NULL,
									  'MinTimeMustNotPlayAgain' INTEGER DEFAULT 0,
									  'MaxTimeMustNotPlayAgain' INTEGER DEFAULT 0,
									  'IsSoundBed' INTEGER,
									  PRIMARY KEY('ScriptID', 'SoundScapeIndex'),
									  FOREIGN KEY('ScriptType') REFERENCES Audio_ScriptTypes('ScriptType'));
									  
CREATE TABLE Audio_SoundScapeElementScripts('SoundScapeScriptID' TEXT NOT NULL,
											'SoundScapeIndex' INTEGER NOT NULL,
											'ScriptIndex' INTEGER NOT NULL,
											'ScriptID' TEXT NOT NULL,
											PRIMARY KEY('SoundScapeScriptID', 'SoundScapeIndex', 'ScriptIndex'));

INSERT INTO Audio_SoundTypes VALUES('GAME_ADVISOR_SPEECH');
INSERT INTO Audio_SoundTypes VALUES('GAME_AMBIENCE');
INSERT INTO Audio_SoundTypes VALUES('GAME_INTERFACE');
INSERT INTO Audio_SoundTypes VALUES('GAME_MUSIC');
INSERT INTO Audio_SoundTypes VALUES('GAME_MUSIC_STINGS');
INSERT INTO Audio_SoundTypes VALUES('GAME_SFX');
INSERT INTO Audio_SoundTypes VALUES('GAME_SPEECH');
INSERT INTO Audio_SoundTypes VALUES('GAME_TEST');

INSERT INTO Audio_ScriptTypes VALUES('None', 0);
INSERT INTO Audio_ScriptTypes VALUES('2D', 1);
INSERT INTO Audio_ScriptTypes VALUES('3D', 2);
INSERT INTO Audio_ScriptTypes VALUES('SoundScape', 3);

INSERT INTO Audio_SpeakerChannels VALUES('Invalid', -1);							
INSERT INTO Audio_SpeakerChannels VALUES('None', -2);		
INSERT INTO Audio_SpeakerChannels VALUES('Random', -3);	
INSERT INTO Audio_SpeakerChannels VALUES('StereoOnly', -4);
INSERT INTO Audio_SpeakerChannels VALUES('FullFrontLowRears', -5);		
INSERT INTO Audio_SpeakerChannels VALUES('FrontLeft', 0);		
INSERT INTO Audio_SpeakerChannels VALUES('FrontRight', 1);		
INSERT INTO Audio_SpeakerChannels VALUES('Center', 2);		
INSERT INTO Audio_SpeakerChannels VALUES('Sub', 3);	
INSERT INTO Audio_SpeakerChannels VALUES('RearLeft', 4);	
INSERT INTO Audio_SpeakerChannels VALUES('RearRight', 5);		
INSERT INTO Audio_SpeakerChannels VALUES('CenterLeft', 6);		
INSERT INTO Audio_SpeakerChannels VALUES('CenterRight', 7);

INSERT INTO Audio_SoundLoadTypes VALUES('None', -1);
INSERT INTO Audio_SoundLoadTypes VALUES('Resident', 0);
INSERT INTO Audio_SoundLoadTypes VALUES('DynamicResident', 1);
INSERT INTO Audio_SoundLoadTypes VALUES('Streamed', 2);

INSERT INTO Map_Folders VALUES('MAP_FOLDER_ADDITIONAL', NULL, 'TXT_KEY_MAP_FOLDER_ADDITIONAL', 'TXT_KEY_MAP_FOLDER_ADDITIONAL_HELP', 4, 'CIV_COLOR_ATLAS');

INSERT INTO Map_Sizes VALUES('MAP_EARTH', 'WORLDSIZE_DUEL', 'Assets\Maps\Earth_Duel.Civ5Map');
INSERT INTO Map_Sizes VALUES('MAP_EARTH', 'WORLDSIZE_TINY', 'Assets\Maps\Earth_Tiny.Civ5Map');
INSERT INTO Map_Sizes VALUES('MAP_EARTH', 'WORLDSIZE_SMALL', 'Assets\Maps\Earth_Small.Civ5Map');
INSERT INTO Map_Sizes VALUES('MAP_EARTH', 'WORLDSIZE_STANDARD', 'Assets\Maps\Earth_Standard.Civ5Map');
INSERT INTO Map_Sizes VALUES('MAP_EARTH', 'WORLDSIZE_LARGE', 'Assets\Maps\Earth_Large.Civ5Map');
INSERT INTO Map_Sizes VALUES('MAP_EARTH', 'WORLDSIZE_HUGE', 'Assets\Maps\Earth_Huge.Civ5Map');

INSERT INTO Maps VALUES ('MAP_EARTH', 'TXT_KEY_MAP_EARTH_TITLE', 'TXT_KEY_MAP_EARTH_HELP', null, 3, 'WORLDTYPE_ATLAS');