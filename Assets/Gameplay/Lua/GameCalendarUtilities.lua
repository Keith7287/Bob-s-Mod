-----------------------------------------------------------------------------------------
-- GameCalendarUtilities.lua
-- This lua script contains some utility methods for formatting a game turn into a 
-- date string based on the current game calendar, game speed, and starting year.
-----------------------------------------------------------------------------------------
DateFormats = {};
ShortDateFormats = {};

-- This is just a utility function to create the standard year string for a given year.
function GetDefaultYearString(year)
	local yearString;
	
	if(year < 0) then
		yearString = Locale.Lookup("TXT_KEY_TIME_BC", -(year));
	elseif(year > 0) then
		yearString = Locale.Lookup("TXT_KEY_TIME_AD", year);
	else
		yearString = Locale.Lookup("TXT_KEY_TIME_AD", 1);
	end
	
	return yearString;
end

-- This function returns a string which represents the date for a given turn.
function GetDateString(gameTurn, calendarType, gameSpeedType, startYear)
	return DateFormats[calendarType](gameTurn, gameSpeedType, startYear);
end

function GetShortDateString(gameTurn, calendarType, gameSpeedType, startYear)
	return ShortDateFormats[calendarType](gameTurn, gameSpeedType, startYear);
end

-----------------------------------------------------------------------------------------
-- Standard Formats
-----------------------------------------------------------------------------------------
DateFormats["CALENDAR_DEFAULT"] = function(gameTurn, gameSpeedType, startYear)

	local turnCount = 0;
	local turnMonth = 0;
	
	local lastMonthIncrement = 1;
	for row in DB.Query([[SELECT MonthIncrement, TurnsPerIncrement FROM GameSpeed_Turns WHERE GameSpeedType = ? ORDER BY rowid ASC]], gameSpeedType) do
		lastMonthIncrement = row.MonthIncrement;
		
		if (gameTurn > (turnCount + row.TurnsPerIncrement)) then
		
			turnMonth = turnMonth + (row.MonthIncrement * row.TurnsPerIncrement);
			turnCount = turnCount + row.TurnsPerIncrement;
		else
			turnMonth = turnMonth + row.MonthIncrement * (gameTurn - turnCount);
			turnCount = turnCount + (gameTurn - turnCount);
			break;
		end
	end

	if (gameTurn > turnCount) then
		turnMonth = turnMonth + lastMonthIncrement * (gameTurn - turnCount);
	end
	
	local numMonths = #GameInfo.Months;
		
	local turnYear = startYear + math.floor(turnMonth / numMonths);
	local yearString = GetDefaultYearString(turnYear);
	
	local idx = gameTurn % (numMonths);
	local month = GameInfo.Months[idx];
	
	return Locale.Lookup(month.Description) .. ", " .. yearString;
end

DateFormats["CALENDAR_YEARS"] = function(gameTurn, gameSpeedType, startYear)
	local turnYear = startYear + gameTurn;
	return GetDefaultYearString(turnYear);
end

DateFormats["CALENDAR_BI_YEARLY"] = function(gameTurn, gameSpeedType, startYear)
	local turnYear = startYear + math.floor(gameTurn / 2);
	return GetDefaultYearString(turnYear);
end

DateFormats["CALENDAR_TURNS"] = function(gameTurn, gameSpeedType, startYear)
	return Locale.Lookup("TXT_KEY_TIME_TURN", gameTurn + 1);
end

DateFormats["CALENDAR_SEASONS"] = function(gameTurn, gameSpeedType, startYear)
	local numSeasons = #GameInfo.Seasons;
	local idx = gameTurn % (numSeasons);
	local season = GameInfo.Seasons[idx];
	
	local turnYear = startYear + math.floor(gameTurn / numSeasons);
	
	local yearString = GetDefaultYearString(turnYear);
	
	return Locale.Lookup(season.Description) .. ", " .. yearString;
end

DateFormats["CALENDAR_MONTHS"] = function(gameTurn, gameSpeedType, startYear)
	local numMonths = #GameInfo.Months;
	local idx = gameTurn % (numMonths);
	local month = GameInfo.Months[idx];
	
	local yearString;
	local turnYear = startYear + math.floor(gameTurn / numMonths);
	
	local yearString = GetDefaultYearString(turnYear);
	
	return Locale.Lookup(month.Description) .. ", " .. yearString;
end

DateFormats["CALENDAR_WEEKS"] = function(gameTurn, gameSpeedType, startYear)
	local weeksPerMonths = GameDefines.WEEKS_PER_MONTHS;
	local numMonths = #GameInfo.Months;
	
	local yearString;
	local weeksPerYear = GC.getWEEKS_PER_MONTHS() * numMonths;
	local turnYear = startYear + math.floor(gameTurn / weeksPerYear);
	local yearString = GetDefaultYearString(turnYear);

	local weekBuffer = Locale.Lookup("TXT_KEY_TIME_WEEK", (gameTurn % weeksPerMonths) + 1);
	local idx = (gameTurn / weeksPerMonths) % (numMonths);
	
	local monthInfo = GameInfo.Months[idx];
	
	return weekString .. ", " .. Locale.Lookup(monthInfo.Description) .. yearString;	 
end

-----------------------------------------------------------------------------------------
-- Short Formats
-----------------------------------------------------------------------------------------
ShortDateFormats["CALENDAR_DEFAULT"] = function(gameTurn, gameSpeedType, startYear)

	local turnCount = 0;
	local turnMonth = 0;
	
	local lastMonthIncrement = 1;
	for row in DB.Query([[SELECT MonthIncrement, TurnsPerIncrement FROM GameSpeed_Turns WHERE GameSpeedType = ? ORDER BY rowid ASC]], gameSpeedType) do
		lastMonthIncrement = row.MonthIncrement;
		
		if (gameTurn > (turnCount + row.TurnsPerIncrement)) then
		
			turnMonth = turnMonth + (row.MonthIncrement * row.TurnsPerIncrement);
			turnCount = turnCount + row.TurnsPerIncrement;
		else
			turnMonth = turnMonth + row.MonthIncrement * (gameTurn - turnCount);
			turnCount = turnCount + (gameTurn - turnCount);
			break;
		end
	end

	if (gameTurn > turnCount) then
		turnMonth = turnMonth + lastMonthIncrement * (gameTurn - turnCount);
	end
	
	local numMonths = #GameInfo.Months;
		
	local turnYear = startYear + math.floor(turnMonth / numMonths);
	return GetDefaultYearString(turnYear);
end

ShortDateFormats["CALENDAR_YEARS"] = function(gameTurn, gameSpeedType, startYear)
	
	local turnYear = startYear + gameTurn;
	return GetDefaultYearString(turnYear);
end

ShortDateFormats["CALENDAR_BI_YEARLY"] = function(gameTurn, gameSpeedType, startYear)
	
	local turnYear = startYear + math.floor(gameTurn / 2);
	return GetDefaultYearString(turnYear);
end

ShortDateFormats["CALENDAR_TURNS"] = function(gameTurn, gameSpeedType, startYear)
	return Locale.Lookup("TXT_KEY_TIME_TURN", gameTurn + 1);
end

ShortDateFormats["CALENDAR_SEASONS"] = function(gameTurn, gameSpeedType, startYear)
	local numSeasons = #GameInfo.Seasons;
	local idx = gameTurn % (numSeasons);
	local season = GameInfo.Seasons[idx];
	
	local turnYear = startYear + math.floor(gameTurn / numSeasons);
	
	local yearString = GetDefaultYearString(turnYear);
	
	return Locale.Lookup(season.Description) .. ", " .. yearString;
end

ShortDateFormats["CALENDAR_MONTHS"] = function(gameTurn, gameSpeedType, startYear)
	local numMonths = #GameInfo.Months;
	local idx = gameTurn % (numMonths);
	local month = GameInfo.Months[idx];
	
	local yearString;
	local turnYear = startYear + math.floor(gameTurn / numMonths);
	
	local yearString = GetDefaultYearString(turnYear);
	
	return Locale.Lookup(month.Description) .. ", " .. yearString;
end

ShortDateFormats["CALENDAR_WEEKS"] = function(gameTurn, gameSpeedType, startYear)
	local weeksPerMonths = GameDefines.WEEKS_PER_MONTHS;
	local numMonths = #GameInfo.Months;
	
	local yearString;
	local weeksPerYear = GC.getWEEKS_PER_MONTHS() * numMonths;
	local turnYear = startYear + math.floor(gameTurn / weeksPerYear);
	
	local yearString = GetDefaultYearString(turnYear);

	local weekBuffer = Locale.Lookup("TXT_KEY_TIME_WEEK", (gameTurn % weeksPerMonths) + 1);
	local idx = (gameTurn / weeksPerMonths) % (numMonths);
	
	local monthInfo = GameInfo.Months[idx];
	
	return weekString .. ", " .. Locale.Lookup(monthInfo.Description) .. yearString;	 
end


-- MODDERS
-- If new Calendar types are added, this wildcard include can be used to implement the text formatting
-- for that calendar.
include("GameCalendarUtilities_Overrides_%w+.lua", true);