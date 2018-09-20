--CoreLib is responsible for defining player hooks, interface functions, and other aggregate functions
--assign self to MD3CoreLib
MD3CoreLib = {};
self = MD3CoreLib;

self.MD3ClassColors = RAID_CLASS_COLORS;

self.MD3ResourceValueConfig = {
	["health"] = {
		maxValue = function(unit) return UnitHealthMax(unit) end,
		currentValue = function(unit) return UnitHealth(unit) end
	},
	["power"] = {
		--there are tons and tons and tons and tons and tons of powers, so we'll get to that later
	}
}

self.MD3SetFrameUnitHooks = {
	["target"] = function(orb)
		orb:RegisterEvent("PLAYER_TARGET_CHANGED");
		orb:SetScript("OnEvent", function(self, event)
			if(UnitExists(orb.unit)) then
				print("firing");
				MD3Utils:SetTextureRGBOpaqueFloat(orb.fill, MD3CoreLib:GetClassRGBColors(MD3CoreLib:UnitClassWrapper(false,true,false,orb.unit)));
			end
		end);
	end,
	["targettarget"] = function(orb)
		orb:RegisterEvent("PLAYER_TARGET_CHANGED");
		orb:SetScript("OnEvent", function(self, event)
			if(UnitExists(orb.unit)) then
				MD3Utils:SetTextureRGBOpaqueFloata(orb.fill, MD3CoreLib:GetClassRGBColors(MD3CoreLib:UnitClassWrapper(false,true,false,orb.unit)), 1);
			end
		end);
	end,
	["player"] = function(orb)

	end,
	["pet"] = function(orb)

	end,
}

--Unit hooks, etc.
function self:SetUnit(orb, unit)
	orb.unit = unit;
	orb:SetAttribute("unit", unit);
	RegisterUnitWatch(orb);
end

function self:SetUnitFunctions(orb, unit)
	if not orb.unit then orb.unit = unit end;
	orb:RegisterForClicks("RightButtonUp");
	orb:SetAttribute("type1", "target");
	orb:SetAttribute("type2", "togglemenu");
	orb:SetAttribute("OnEnter", function()
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
		GameTooltip:SetUnit(orb.unit);
	end);
end

function self:SetUnitAndUnitFunctions(orb, unit)
	self:SetUnit(orb, unit);
	self:SetUnitFunctions(orb);
	self.MD3SetFrameUnitHooks[unit](orb);
end

function self:SetResourceType(orb, resourceType)
	orb.resourceType = resourceType;
	orb.resourceMaxValueFunction = self.MD3ResourceValueConfig[resourceType].maxValue;
	orb.resourceCurrentValueFunction = self.MD3ResourceValueConfig[resourceType].currentValue;
end

--unit color functions
function self:GetClassRGBColors(className)
	print(className);
	print(MD3CoreLib.MD3ClassColors[className].r .. " " .. MD3CoreLib.MD3ClassColors[className].g .. " " .. MD3CoreLib.MD3ClassColors[className].b);
	return
		MD3CoreLib.MD3ClassColors[className].r,
		MD3CoreLib.MD3ClassColors[className].g,
		MD3CoreLib.MD3ClassColors[className].b
end

function self:UnitClassWrapper(returnFirst, returnSecond, returnThird, unit)
	local first, second, third = UnitClass(unit)

	if(returnFirst and not returnSecond and not returnThird) then
		return first;
	end
	if(returnSecond and not returnFirst and not returnThird) then
		return second;
	end
	if(returnThird and not returnSecond and not returnThird) then
		return third;
	end
	if(returnFirst and returnSecond and not returnThird) then
		return first, second;
	end
	if(returnFirst and returnThird and not returnSecond) then
		return first, third;
	end
	if(returnSecond and returnThird and not returnFirst) then
		return second, third;
	end
end

self.PlayerClass = self:UnitClassWrapper(false, true, false, "player");
