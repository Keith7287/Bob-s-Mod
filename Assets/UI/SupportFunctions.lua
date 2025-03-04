---------------------------------------------------------------------------------------------------------
-- Misc Support Functions
---------------------------------------------------------------------------------------------------------

local strEllipsis = Locale.ConvertTextKey("TXT_KEY_GENERIC_DOT_DOT_DOT");
function TruncateString(control, resultSize, longStr, trailingText)
	if(longStr == nil)then
		longStr = control:GetText();
		
		if(trailingText == nil)then
			longStr = "";
		end
	end
	
	if(control ~= nil)then
		control:SetText(longStr);
		local fullStrExtent = control:GetSizeX();
		
		if(trailingText == nil)then
			trailingText = "";
		end

		control:SetText(trailingText);
		local trailingExtent = control:GetSizeX();
		
		local sizeAfterTruncate = resultSize - trailingExtent;
		if(sizeAfterTruncate > 0)then
			local truncatedSize = fullStrExtent;
			local newString = longStr;
			
			local ellipsis = "";
			
			if( sizeAfterTruncate < truncatedSize ) then
				ellipsis = strEllipsis;
			end
			
			control:SetText(ellipsis);
			local ellipsisExtent = control:GetSizeX();
			sizeAfterTruncate = sizeAfterTruncate - ellipsisExtent;
			
			while (sizeAfterTruncate < truncatedSize and Locale.Length(newString) > 1) do
				newString = Locale.Substring(newString, 1, Locale.Length(newString) - 1);
				control:SetText(newString);
				truncatedSize = control:GetSizeX();
			end
			
			control:SetText(newString .. ellipsis .. trailingText);
		end
	end
end