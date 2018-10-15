-- Author      : John Rubin - "Mistra50"
-- Create Date : 8/8/2012 9:03:35 PM
-- Mistra's D3Orbs - rewrite of the previous oUF_D3Orbs_LightWeight
-- The orbs originally appeared in the RothUI by "Zork" and permissive use of all assets and code was given by the original author.
-- The code in this addon has small chunks of the original still within, but the majority has been rewritten to be free of any external API by John Rubin, aka "Mistra"

--Copyright (C) 2012 John Rubin

--Standard DBAD License.  A mix of MIT and please get my permission before you copy this code license.

--Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

--The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--The above copyright holder is notified of the intent of redistribution prior to the release of said redistribution.

--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--VERSION: 1.8.4r3

--register the addon message prefix
--RegisterAddonMessagePrefix("D32")

--variable setup
D32localizedDisplayName, D32className, D32classNumber = UnitClass("player")
local charClassNumber = 0
local playerInVehicle --bool for detecting whether or not a player is in a vehicle
local defaultOrbSize = 150
local orbFillingTexture = "MDO_orb_filling8.tga"
local fillRotationTexture = "orb_fillRotation"
local images = "Interface\\AddOns\\MistrasDiabloOrbs\\images\\"
local fonts = "Interface\\Addons\\MistrasDiabloOrbs\\fonts\\"
healthOrb = nil
manaOrb = nil
local vehicleInUse

--smooth animation variables
local lastHealthValue, newHealthValue

--color preset definitions per class and assignment
local orbClassColors = {
	[0] = {health = {r = 0.78, g = 0.61, b = 0.43, a= 1}, mana = {r = 0.8, g = 0, b = 0, a= 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Warrior"}, --warrior preset

	[1] = {health = {r = 0.96, b = 0.55, b = 0.73, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Paladin"}, --paladin preset

	[2] = {health = {r = 0.67, g = 0.83, b = 0.45, a = 1},mana = {r = 1.1, g = 0.5, b = 0.25, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Hunter"}, --hunter preset

	[3] = {health = {r = 1.00, g = 0.96, b = 0.41, a = 1},mana = {r = 1.00, g = 0.96, b = 0.41, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Rogue"}, --rogue preset

	[4] = {health = {r = 1.00, g = 1.00, b = 1.00, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Priest"}, --priest preset

	[5] = {health = {r = 0.77, g = 0.12, b = 0.23, a = 1},mana = {r = 0.35, g = 0.9, b = 0.9, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Death Knight"}, --death knight preset

	[6] = {health = {r = 0.0, g = 0.44, b = 0.87, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Shaman"}, -- shaman preset

	[7] = {health = {r = 0.41, g = 0.80, b = 0.94, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Mage"}, --mage preset

	[8] = {health = {r = 0.58, g = 0.51, b = 0.79, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Warlock"}, --warlock preset

	[9] = {health = {r = 0.33, g = 0.54, b = 0.52, a = 1},mana = {r = 1.00, g = 1.00, b = 1.00, a = 1},  animation = "SPELLS\\GreenRadiationFog.m2", name = "Monk"}, --monk preset

	[10] = {health = {r = 1.00, g = 0.49, b = 0.04, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Druid"}, --druid preset

	[11] = {health = {r=0.64, g=1.89, b=.79, a=1}, mana = {r = 0.5, g = 0.32, b = 0.55, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Demon Hunter"}
}

local fontChoices = {
	[0] = "Interface\\AddOns\\MistrasDiabloOrbs\\fonts\\Of Wildflowers and Wings.ttf",
	[1] = "FONTS\\FRIZQT__.ttf"
}


local function getClassColor()
	if D32classNumber then
		D32className = D32localizedDisplayName
		return D32classNumber - 1
	else
		local num = table.getn(orbClassColors)
		for i=0,num,1 do
			if orbClassColors[i].name == UnitClass("player") then
				D32className = UnitClass("player")
				return i
			end
		end
		print("Did not find the class.  "..UnitClass("player"))
		return 0
	end
end
charClassNumber = getClassColor()

--load preset D32CharacterData default in the event existing data cannot be recovered
local Hr,Hg,Hb,Ha = orbClassColors[charClassNumber].health.r, orbClassColors[charClassNumber].health.g, orbClassColors[charClassNumber].health.b, orbClassColors[charClassNumber].health.a
local Mr,Mg,Mb,Ma = orbClassColors[charClassNumber].mana.r, orbClassColors[charClassNumber].mana.g, orbClassColors[charClassNumber].mana.b, orbClassColors[charClassNumber].mana.a

local defaultsTable = {
	--health orb vars
	healthOrb = {
		scale = 1,
		textures = {
			fill = "MDO_orb_filling2.tga",
			rotation = "orb_rotation_bubbles"
		},
		orbColor = {
			r = Hr,
			g = Hg,
			b = Hb,
			a= Ha
		},
		galaxy = {
			r = Hr,
			g = Hg,
			b = Hb,
			a= Ha
		},
		font1 = {
			r=1,
			g=1,
			b=1,
			a=1,
			show = true
		},
		font2 = {
			r=1,
			g=1,
			b=1,
			a=1,
			show = true
		},
		formatting = {
			truncated = true,
			commaSeparated = false
		},
		offsetX = -250,
		offsetY = 0,
		point = "BOTTOM",
		relativePoint = "BOTTOM",
	},

	--mana orb vars
	manaOrb = {
		scale = 1,
		textures = {
			fill = "MDO_orb_filling2.tga",
			rotation = "orb_rotation_bubbles"
		},
		orbColor = 	{
			r = Mr,
			g = Mg,
			b = Mb,
			a = Ma
		},
		galaxy = {
			r = Mr,
			g = Mg,
			b = Mb,
			a = Ma
		},
		font1 = {
			r=1,
			g=1,
			b=1,
			a=1,
			show = true
		},
		font2 = {
			r=1,
			g=1,
			b=1,
			a=1,
			show = true
		},
		formatting = {
			truncated = true,
			commaSeparated = false
		},
		offsetX = 250,
		offsetY = 0,
		point = "BOTTOM",
		relativePoint = "BOTTOM",
	},

	--pet orb vars
	petOrb = {scale = 1, enabled = true, showValue = false, showPercentage = true, healthOrb = {r=Hr,g=Hg,b=Hb,a=Ha}, manaOrb={r=Mr,g=Mg,b=Mb,a=Ma}},

	--pet orb vars
	extraPowerOrb = {scale = 1, enabled = true, showValue = false, showPercentage = true, rageOrb = {r=Hr,g=Hg,b=Hb,a=Ha}, energyOrb={r=Mr,g=Mg,b=Mb,a=Ma}},

	--orb fonts
	font = fontChoices[1],

	values = {formatted=true, commaSeparated=false},

	artwork = {show = true},

	powerFrame = {show = true},

	combat = {enabled = true, orbColor = {r = 0.8, g = 0, b = 0, a = 1}, galaxy = {r = 0.8, g = 0, b = 0, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},

	druidColors = {
		cat = {orbColor = {r = 1.00, g = 0.96, b = 0.41, a = 1}, galaxy = {r = 1.00, g = 0.96, b = 0.41, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},
		bear = {orbColor = {r = 0.8, g = 0, b = 0, a= 1}, galaxy = {r = 0.8, g = 0, b = 0, a= 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},
		moonkin = {orbColor = {r = 0.0, g = 0.44, b = 0.87, a = 1}, galaxy = {r = 0.0, g = 0.44, b = 0.87, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},
		tree = {orbColor = {r = 0.0, g = 0.44, b = 0.87, a = 1}, galaxy = {r = 0.0, g = 0.44, b = 0.87, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}}
	},

	defaultPlayerFrame = {show = false},

	smoothing = true
}

local defaultTextures = {
	healthOrb = {fill = "MDO_orb_filling2.tga", rotation = "orb_rotation_bubbles"},
	manaOrb = {fill = "MDO_orb_filling2.tga", rotation = "orb_rotation_bubbles"}
}

D32FillTextureChoices = {
	[0] = images.. "MDO_orb_filling1.tga",
	[1] = images.. "MDO_orb_filling2.tga",
	[2] = images.. "MDO_orb_filling3.tga",
	[3] = images.. "MDO_orb_filling4.tga",
	[4] = images.. "MDO_orb_filling5.tga",
	[5] = images.. "MDO_orb_filling6.tga",
	[6] = images.. "MDO_orb_filling7.tga",
}

D32RotationTextureChoices = {
	[0] = images.. "orb_rotation_galaxy",
	[1] = images.. "orb_rotation_bubbles",
	[2] = images.. "orb_rotation_iris"
}

----------------------------------------------------------Main Data Table for each character -----------------------------------------------------------------
D32CharacterData = defaultsTable
D32Textures = defaultTextures
---------------------------------------------------------------------------------------------------------------------------------------------------------------

function handlePlayerFrame(show)
	if show then
		PlayerFrame:SetScript("OnEvent",PlayerFrame_OnEvent)
		PlayerFrame:Show()
	else
		PlayerFrame:SetScript("OnEvent",nil)
		PlayerFrame:Hide()
	end
end

--hide the player frame by default... we have a pet orb now, so people shouldn't be asking for it anymore.... maybe
--handlePlayerFrame(D32CharacterData.defaultPlayerFrame.show)


--function to make any frame object movable
local function makeFrameMovable(frame,button,callback)
	local btnString = "LeftButton"
	if button then
		btnString = button
	end

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag(btnString)
	frame:SetScript("OnDragStart", function(self)
		if IsShiftKeyDown() then
			self:StartMoving()
		end
	 end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if callback then
			local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
			callback(point,relativePoint,xOfs,yOfs)
		end
	end)
end

--a wrapper that allows us to filter what our resource is, based on our class or specialty
local function GetUnitPowerAndMaxPower(unit)
	if(unit == "player") then
		if D32className == "Shaman" then
			--if we're resto, we don't care, return
			if GetSpecialization() == 3 then return UnitPower(unit), UnitPowerMax(unit) end;
			return UnitPower(unit, 0), UnitPowerMax(unit, 0);
		elseif D32className == "Priest" then
			return UnitPower(unit, 0), UnitPowerMax(unit, 0);
		end

		return UnitPower(unit), UnitPowerMax(unit);
	else
		return UnitPower(unit), UnitPowerMax(unit);
	end
end

local function valueFormat(val, formatting, petOverride)
	local newVal = val
	if petOverride == true then
		if val > 10000 then
			newVal = (floor((val/1000)*10)/10).."k"
		end
		return newVal;
	elseif formatting.truncated == true then
		if val > 1000000 then
			newVal = (floor((val/1000000)*10)/10) .."m"
		elseif val > 999 then
			newVal = (floor((val/1000)*10)/10) .."k"
		end
		return newVal;
	elseif formatting.commaSeparated == true then
		--convert the value to a string, reverse the string, so we're starting at the back, find any numerical sequence of three numbers, replace the occurrence with the occurrence, plus a comma, reverse the string so the number is the proper direction again, then, capture any comma sitting by its lonesome, and remove it.  Primarily to fix the leading comma at the front of our big number
		newVal = tostring(val):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "");
		return newVal;
	else
		return newVal;
	end
end

local previousHealthValue = UnitHealth("player")
local function monitorHealth(orb)
	local unitHealthString = "player"
	if vehicleInUse == 1 then
		unitHealthString = "vehicle"
	end
	local maxHealth = UnitHealthMax(unitHealthString)
	if not tonumber(maxHealth) or maxHealth == 0 then maxHealth = 1 end
	local currentHealth = UnitHealth(unitHealthString)
	if not tonumber(currentHealth) then currentHealth = 1 end
	local healthPercentage = currentHealth/maxHealth
	local inverseHealthPercentage = math.abs(healthPercentage - 1)
	orb.maxValue = (function ()
		return UnitHealthMax(unitHealthString);
	end);

	if(D32CharacterData.smoothing) then
		local step = 0
		local onePercentHealth = maxHealth / 100

		local newValue = previousHealthValue
		if previousHealthValue < currentHealth then
			step = 1
			if previousHealthValue + (onePercentHealth * step) > currentHealth then
				newValue = currentHealth
			else
				newValue = previousHealthValue + (onePercentHealth * step)
			end
		elseif previousHealthValue > currentHealth then
			step = -1
			if previousHealthValue + (onePercentHealth * step) < currentHealth then
				newValue = currentHealth
			else
				newValue = previousHealthValue + (onePercentHealth * step)
			end
		end
		previousHealthValue = newValue
	else
		previousHealthValue = currentHealth
	end

	local targetTexHeight = (previousHealthValue/maxHealth * orb.filling:GetWidth())
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousHealthValue/maxHealth
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 1
		targetTexHeight = orb.filling:GetWidth()
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	orb.font1:SetText(string1)

	local string = valueFormat(currentHealth, D32CharacterData.healthOrb.formatting, false)
	orb.font2:SetText(string)

	if UnitIsDead(unitHealthString) then
		orb.font2:SetText("DEAD :'(")
	end

	orb.filling:SetHeight(targetTexHeight)
	orb.filling:SetTexCoord(0,1,math.abs(newDisplayPercentage - 1),1)
	orb.galaxy1:SetAlpha(newDisplayPercentage)
	orb.galaxy2:SetAlpha(newDisplayPercentage)
	orb.galaxy3:SetAlpha(newDisplayPercentage)
end

local previousPowerValue = select(1, GetUnitPowerAndMaxPower("player"))
local function monitorPower(orb)
	local unitPowerString = "player"
	if vehicleInUse == 1 then
		unitPowerString = "vehicle"
	end
	local currentPower, maxPower = GetUnitPowerAndMaxPower(unitPowerString);
	if not tonumber(maxPower) or maxPower == 0 then maxPower = 1 end
	if not tonumber(currentPower) then currentPower = 1 end
	local powerPercentage = currentPower/maxPower
	local inversePowerPercentage = math.abs(powerPercentage - 1)
	orb.maxValue = (function ()
		return select(2, GetUnitPowerAndMaxPower(unitPowerString));
	end);

	if(D32CharacterData.smoothing) then
	local step = 0
	local onePercentPower = maxPower / 100

	local newValue = previousPowerValue
		if previousPowerValue < currentPower then
			step = 1
			if previousPowerValue + (onePercentPower * step) > currentPower then
				newValue = currentPower
			else
				newValue = previousPowerValue + (onePercentPower * step)
			end
		elseif previousPowerValue > currentPower then
			step = -1
			if previousPowerValue + (onePercentPower * step) < currentPower then
				newValue = currentPower
			else
				newValue = previousPowerValue + (onePercentPower * step)
			end
		end
		previousPowerValue = newValue
	else
		previousPowerValue = currentPower
	end

	local targetTexHeight = (previousPowerValue/maxPower * orb.filling:GetWidth())
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousPowerValue / maxPower
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 1
		targetTexHeight = orb.filling:GetWidth()
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	orb.font1:SetText(string1)

	local string = valueFormat(currentPower, D32CharacterData.manaOrb.formatting, false)
	orb.font2:SetText(string)

	if UnitIsDead(unitPowerString) then
		orb.font2:SetText("DEAD :'(")
	end

	orb.filling:SetHeight(targetTexHeight)
	orb.filling:SetTexCoord(0,1,math.abs(newDisplayPercentage-1),1)
	orb.galaxy1:SetAlpha(newDisplayPercentage)
	orb.galaxy2:SetAlpha(newDisplayPercentage)
	orb.galaxy3:SetAlpha(newDisplayPercentage)
end

local previousPetHealth = UnitHealth("pet")
local function PetHealthUpdate(orb)
	local unitHealthString = "pet"
	local maxHealth = UnitHealthMax(unitHealthString)
	if not tonumber(maxHealth) or maxHealth == 0 then maxHealth = 1 end
	local currentHealth = UnitHealth(unitHealthString)
	if not tonumber(currentHealth) then currentHealth = 0 end
	local healthPercentage = currentHealth/maxHealth
	local inverseHealthPercentage = math.abs(healthPercentage - 1)

	local step = 0
	local onePercentHealth = maxHealth / 100

	local newValue = previousPetHealth
	if previousPetHealth < currentHealth then
		step = 1
		if previousPetHealth + (onePercentHealth * step) > currentHealth then
			newValue = currentHealth
		else
			newValue = previousPetHealth + (onePercentHealth * step)
		end
	elseif previousPetHealth > currentHealth then
		step = -1
		if previousPetHealth + (onePercentHealth * step) < currentHealth then
			newValue = currentHealth
		else
			newValue = previousPetHealth + (onePercentHealth * step)
		end
	end
	previousPetHealth = newValue

	local targetTexHeight = (previousPetHealth/maxHealth * (85 * orb:GetScale()))
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousPetHealth/maxHealth
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 0
		targetTexHeight = 1
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	orb.font1:SetText(string1)

	local string = valueFormat(currentHealth, nil, true)
	orb.font3:SetText(string)

	orb.filling1:SetHeight(targetTexHeight)
	orb.filling1:SetTexCoord(0,1,math.abs(newDisplayPercentage - 1),1)
	orb.galaxy1:SetAlpha(newDisplayPercentage * 0.2)
	orb.galaxy2:SetAlpha(newDisplayPercentage * 0.2)
	orb.galaxy3:SetAlpha(newDisplayPercentage * 0.2)
end

local previousPetPower = UnitPower("pet")
local function PetPowerUpdate(orb)
	local unitPowerString = "pet"
	local maxPower = UnitPowerMax(unitPowerString)
	if not tonumber(maxPower) or maxPower == 0 then maxPower = 1 end
	local currentPower = UnitPower(unitPowerString)
	if not tonumber(currentPower) then currentPower = 0 end
	local powerPercentage = currentPower/maxPower
	local inversePowerPercentage = math.abs(powerPercentage - 1)

	local step = 0
	local fillPercentage = 100
	local onePercentPower = maxPower / fillPercentage

	local newValue = previousPetPower
	if previousPetPower < currentPower then
		step = 1
		if previousPetPower + (onePercentPower * step) > currentPower then
			newValue = currentPower
		else
			newValue = previousPetPower + (onePercentPower * step)
		end
	elseif previousPetPower > currentPower then
		step = -1
		if previousPetPower + (onePercentPower * step) < currentPower then
			newValue = currentPower
		else
			newValue = previousPetPower + (onePercentPower * step)
		end
	end
	previousPetPower = newValue

	local targetTexHeight = (previousPetPower/maxPower * (85 * orb:GetScale()))
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousPetPower / maxPower
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 0
		targetTexHeight = 1
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	orb.font2:SetText(string1)

	local string = valueFormat(currentPower, nil, true)
	orb.font4:SetText(string)

	orb.filling2:SetHeight(targetTexHeight)
	orb.filling2:SetTexCoord(0,1,math.abs(newDisplayPercentage-1),1)
end

local function updatePetValues(orb)
	PetHealthUpdate(orb)
	PetPowerUpdate(orb)
end

-- Update Extra Power
local previousExtraPowerRage = UnitPower("player",1)
local function ExtraPowerRageUpdate(orb)
	local maxRage = UnitPowerMax("player",1)
	if not tonumber(maxRage) or maxRage == 0 then maxRage = 1 end
	local currentRage = UnitPower("player",1)
	if not tonumber(currentRage) then currentRage = 0 end
	local ragePercentage = currentRage/maxRage
	local inverseragePercentage = math.abs(ragePercentage - 1)

	local step = 0
	local onePercentHealth = maxRage / 100

	local newValue = previousExtraPowerRage
	if previousExtraPowerRage < currentRage then
		step = 1
		if previousExtraPowerRage + (onePercentHealth * step) > currentRage then
			newValue = currentRage
		else
			newValue = previousExtraPowerRage + (onePercentHealth * step)
		end
	elseif previousExtraPowerRage > currentRage then
		step = -1
		if previousExtraPowerRage + (onePercentHealth * step) < currentRage then
			newValue = currentRage
		else
			newValue = previousExtraPowerRage + (onePercentHealth * step)
		end
	end
	previousExtraPowerRage = newValue

	local targetTexHeight = (previousExtraPowerRage/maxRage * (85 * orb:GetScale()))
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousExtraPowerRage/maxRage
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 0
		targetTexHeight = 1
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	orb.font1:SetText(string1)

	local string = valueFormat(currentRage, nil, true)
	orb.font3:SetText(string)

	orb.filling1:SetHeight(targetTexHeight)
	orb.filling1:SetTexCoord(0,1,math.abs(newDisplayPercentage - 1),1)
	
	return newDisplayPercentage
end

local previousExtraPowerEnergy = UnitPower("player",3)
local function ExtraPowerEnergyUpdate(orb)
	local maxEnergy = UnitPowerMax("player",3)
	if not tonumber(maxEnergy) or maxEnergy == 0 then maxEnergy = 1 end
	local currentEnergy = UnitPower("player",3)
	if not tonumber(currentEnergy) then currentEnergy = 0 end
	local energyPercentage = currentEnergy/maxEnergy
	
	local step = 0
	local fillPercentage = 100
	local onePercentEnergy = maxEnergy / fillPercentage

	local newValue = previousExtraPowerEnergy
	if previousExtraPowerEnergy < currentEnergy then
		step = 1
		if previousExtraPowerEnergy + (onePercentEnergy * step) > currentEnergy then
			newValue = currentEnergy
		else
			newValue = previousExtraPowerEnergy + (onePercentEnergy * step)
		end
	elseif previousExtraPowerEnergy > currentEnergy then
		step = -1
		if previousExtraPowerEnergy + (onePercentEnergy * step) < currentEnergy then
			newValue = currentEnergy
		else
			newValue = previousExtraPowerEnergy + (onePercentEnergy * step)
		end
	end
	previousExtraPowerEnergy = newValue

	local targetTexHeight = (previousExtraPowerEnergy/maxEnergy * (85 * orb:GetScale()))
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousExtraPowerEnergy / maxEnergy
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 0
		targetTexHeight = 1
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	orb.font2:SetText(string1)

	local string = valueFormat(currentEnergy, nil, true)
	orb.font4:SetText(string)

	orb.filling2:SetHeight(targetTexHeight)
	orb.filling2:SetTexCoord(0,1,math.abs(newDisplayPercentage-1),1)

	return newDisplayPercentage
end

function updateExtraPowerValues(orb)
	local rageDisplayPercentage = ExtraPowerRageUpdate(orb)
	local energyDisplayPercentage = ExtraPowerEnergyUpdate(orb)
	local newDisplayPercentage = math.max(rageDisplayPercentage, energyDisplayPercentage)

	orb.galaxy1:SetAlpha(newDisplayPercentage * 0.2)
	orb.galaxy2:SetAlpha(newDisplayPercentage * 0.2)
	orb.galaxy3:SetAlpha(newDisplayPercentage * 0.2)
end

local function CreateGalaxy(orb, file, duration,size,x,y)
	local galaxy = CreateFrame("Frame",nil,orb)
	galaxy:SetHeight(size)
	galaxy:SetWidth(size)
	galaxy:SetPoint("Center",x,y)
	galaxy:SetFrameLevel(4)

	local galTex = galaxy:CreateTexture()
	galTex:SetAllPoints(galaxy)
	galTex:SetTexture(file)
	galTex:SetBlendMode("ADD")
	galTex:SetAlpha(1)
	galaxy.texture = galTex

	local animGroup = galaxy:CreateAnimationGroup()
	galaxy.animGroup = animGroup

	local anim1 = galaxy.animGroup:CreateAnimation("Rotation")
	anim1:SetDegrees(360)
	anim1:SetDuration(duration)
	galaxy.animGroup.anim1 = anim1

	animGroup:Play()
	animGroup:SetLooping("REPEAT")

	return galaxy
end

local function CreateGlow(orb)
	local glow = CreateFrame("PlayerModel",nil, orb)
	glow:SetFrameStrata("BACKGROUND")
	glow:SetFrameLevel(5)
	glow:SetAllPoints(orb)
	glow:SetModel(orbClassColors[charClassNumber].animation)
	glow:SetAlpha(1)
	glow:SetScript("OnShow",function()
		glow:SetModel(orbClassColors[charClassNumber].animation)
		glow:SetModelScale(1)
		glow:SetPosition(0,0,0)
	end)
	orb.glow = glow
end

local function menu()
	ToggleDropDownMenu(1, nil,"PlayerFrameDropDown", "cursor", 0, 0)
end

--orb creation experiment
local function CreateOrb(parent,name,size,fillTexture,galaxyTexture,offsetX,offsetY,relativePoint,monitorFunc)
	local orb
	orb = CreateFrame("Button",name,UIParent,"SecureActionButtonTemplate")
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("BACKGROUND")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling:SetTexture(images..fillTexture)
	orb.filling:SetPoint("BOTTOMLEFT",3,3)
	orb.filling:SetWidth(defaultOrbSize - 6)
	orb.filling:SetHeight(defaultOrbSize - 6)
	orb.filling:SetAlpha(1)
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)
	local newRand = math.random(20,50)
	orb.galaxy1 = CreateGalaxy(orb, images..galaxyTexture.."1.tga",newRand,defaultOrbSize-5,0,0)
	newRand = math.random(30,70)
	orb.galaxy2 = CreateGalaxy(orb,images..galaxyTexture.."2.tga", newRand,defaultOrbSize-5,0,0)
	newRand = math.random(18,27)
	orb.galaxy3 = CreateGalaxy(orb,images..galaxyTexture.."3.tga", newRand,defaultOrbSize-5,0,0)
	CreateGlow(orb)
	orb:SetScript("OnUpdate",monitorFunc)
	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("MEDIUM")
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
	orb.font1:SetPoint("CENTER",0,15)
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
	orb.font2:SetPoint("CENTER",0,-5)

	--position defaults
	orb:ClearAllPoints()
	orb:SetPoint(relativePoint,nil,relativePoint,offsetX,offsetY)

	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	orb.filling:SetVertexColor(1,1,1,1)

	--setup mouseover/click/rightclick events
	orb.menu = function(orb) ToggleDropDownMenu(1, 1, PlayerFrameDropDown, "cursor", 0 ,0) end
	orb:RegisterForClicks("AnyUp")
	orb:SetAttribute("type1","target")
	orb:SetAttribute("type2","menu")
	orb:SetAttribute("unit","player")
	orb.tooltip = CreateFrame("GameTooltip","PlayerTooltip",nil,"GameToolTipTemplate")
	orb:SetScript("OnEnter", function()
		GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
		GameTooltip:SetUnit("player")
		GameTooltip:Show()
	end)
	orb:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)


	--place setup the appropriate character events on the health orb
	return orb
end

local function CreatePetOrb(parent,name,size,offsetX,offsetY,monitorFunc)
	local orb
	orb = CreateFrame("Button",name,parent,"SecureActionButtonTemplate")
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("BACKGROUND")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling1 = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling1:SetTexture(images.."petFilling_health.tga")
	orb.filling1:SetPoint("BOTTOMLEFT",3,0)
	orb.filling1:SetWidth(size / 2 - 3)
	orb.filling1:SetHeight(size - 6)
	orb.filling1:SetAlpha(1)
	orb.filling2 = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling2:SetTexture(images.."petFilling_power.tga")
	orb.filling2:SetPoint("BOTTOMRIGHT",-3,0)
	orb.filling2:SetWidth(size / 2 - 3)
	orb.filling2:SetHeight(size - 6)
	orb.filling2:SetAlpha(1)
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)

	orb.divider = CreateFrame("Frame",nil,orb)
	orb.divider.texture = orb.divider:CreateTexture(nil,"OVERLAY")
	orb.divider.texture:SetTexture(images.."middleBar.tga")
	orb.divider:SetAllPoints(true)
	orb.divider.texture:SetAllPoints(true)
	orb.galaxy1 = CreateGalaxy(orb, D32RotationTextureChoices[1].."1.tga",36,size-8,0,0)
	orb.galaxy2 = CreateGalaxy(orb, D32RotationTextureChoices[1].."2.tga", 22,size-8,0,0)
	orb.galaxy3 = CreateGalaxy(orb, D32RotationTextureChoices[1].."3.tga", 29,size-8,0,0)
	orb.galaxy1:SetAlpha(0.3)
	orb.galaxy2:SetAlpha(0.3)
	orb.galaxy3:SetAlpha(0.3)
	CreateGlow(orb)

	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("MEDIUM")
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,14,"THINOUTLINE")
	orb.font1:SetPoint("CENTER",-20,5)
	orb.font1:SetText("100")
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,14,"THINOUTLINE")
	orb.font2:SetPoint("CENTER",20,5)
	orb.font2:SetText("100")
	orb.font3 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font3:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	orb.font3:SetPoint("CENTER",-20,-8)
	orb.font3:SetText("100")
	orb.font4 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font4:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	orb.font4:SetPoint("CENTER",20,-8)
	orb.font4:SetText("100")

	orb:SetScript("OnUpdate",updatePetValues)

	--position defaults
	orb:ClearAllPoints()
	orb:SetPoint("CENTER",offsetX,offsetY)

	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	orb.filling1:SetVertexColor(healthOrb.filling:GetVertexColor())
	orb.filling2:SetVertexColor(manaOrb.filling:GetVertexColor())

	orb.menu = function(orb) ToggleDropDownMenu(1, 1, PetFrameDropDown, "cursor", 0 ,0) end
	orb:RegisterForClicks("AnyUp")
	orb:SetAttribute("type1","target")
	orb:SetAttribute("type2","menu")
	orb:SetAttribute("unit","pet")
	orb.tooltip = CreateFrame("GameTooltip","PetToolTip",nil,"GameToolTipTemplate")
	orb:SetScript("OnEnter", function()
		GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
		GameTooltip:SetUnit("pet")
		GameTooltip:Show()
	end)
	orb:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)

	RegisterUnitWatch(orb)

	--place setup the appropriate character events on the health orb
	return orb
end


local function CreateExtraPowerOrb(parent,name,size,offsetX,offsetY,monitorFunc)
	local orb
	orb = CreateFrame("Button",name,parent,"SecureActionButtonTemplate")
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("BACKGROUND")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling1 = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling1:SetTexture(images.."petFilling_health.tga")
	orb.filling1:SetPoint("BOTTOMLEFT",3,0)
	orb.filling1:SetWidth(size / 2 - 3)
	orb.filling1:SetHeight(size - 6)
	orb.filling1:SetAlpha(1)
	orb.filling2 = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling2:SetTexture(images.."petFilling_power.tga")
	orb.filling2:SetPoint("BOTTOMRIGHT",-3,0)
	orb.filling2:SetWidth(size / 2 - 3)
	orb.filling2:SetHeight(size - 6)
	orb.filling2:SetAlpha(1)
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)

	orb.divider = CreateFrame("Frame",nil,orb)
	orb.divider.texture = orb.divider:CreateTexture(nil,"OVERLAY")
	orb.divider.texture:SetTexture(images.."middleBar.tga")
	orb.divider:SetAllPoints(true)
	orb.divider.texture:SetAllPoints(true)
	orb.galaxy1 = CreateGalaxy(orb, D32RotationTextureChoices[1].."1.tga",36,size-8,0,0)
	orb.galaxy2 = CreateGalaxy(orb, D32RotationTextureChoices[1].."2.tga", 22,size-8,0,0)
	orb.galaxy3 = CreateGalaxy(orb, D32RotationTextureChoices[1].."3.tga", 29,size-8,0,0)
	orb.galaxy1:SetAlpha(0.3)
	orb.galaxy2:SetAlpha(0.3)
	orb.galaxy3:SetAlpha(0.3)
	CreateGlow(orb)

	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("MEDIUM")
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,14,"THINOUTLINE")
	orb.font1:SetPoint("CENTER",-20,5)
	orb.font1:SetText("100")
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,14,"THINOUTLINE")
	orb.font2:SetPoint("CENTER",20,5)
	orb.font2:SetText("100")
	orb.font3 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font3:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	orb.font3:SetPoint("CENTER",-20,-8)
	orb.font3:SetText("100")
	orb.font4 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font4:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	orb.font4:SetPoint("CENTER",20,-8)
	orb.font4:SetText("100")

	orb:SetScript("OnUpdate",updatePetValues)

	--position defaults
	orb:ClearAllPoints()
	orb:SetPoint("CENTER",offsetX,offsetY)

	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	orb.filling1:SetVertexColor(healthOrb.filling:GetVertexColor())
	orb.filling2:SetVertexColor(manaOrb.filling:GetVertexColor())

	orb.menu = function(orb) ToggleDropDownMenu(1, 1, PlayerFrameDropDown, "cursor", 0 ,0) end
	orb:RegisterForClicks("AnyUp")
	orb:SetAttribute("type1","target")
	orb:SetAttribute("type2","menu")
	orb:SetAttribute("unit","player")
	orb.tooltip = CreateFrame("GameTooltip","PlayerTooltip",nil,"GameToolTipTemplate")
	orb:SetScript("OnEnter", function()
		GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
		GameTooltip:SetUnit("player")
		GameTooltip:Show()
	end)
	orb:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)

	--place setup the appropriate character events on the health orb
	return orb
end


local function CreateXMLOrb(parent,name,size,fillTexture,galaxyTexture)
	local orb
	orb = CreateFrame("Button",name,parent,nil)
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("HIGH")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling:SetTexture(images..fillTexture)
	orb.filling:SetPoint("BOTTOMLEFT",3,3)
	orb.filling:SetWidth(size - 6)
	orb.filling:SetHeight(size-6)
	orb.filling:SetAlpha(1)
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)
	local newRand = math.random(20,50)
	orb.galaxy1 = CreateGalaxy(orb, images..galaxyTexture.."1.tga",newRand,size-3,0,0)
	newRand = math.random(30,70)
	orb.galaxy2 = CreateGalaxy(orb,images..galaxyTexture.."2.tga", newRand,size-3,0,0)
	newRand = math.random(18,27)
	orb.galaxy3 = CreateGalaxy(orb,images..galaxyTexture.."3.tga", newRand,size-3,0,0)

	CreateGlow(orb)
	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("HIGH")
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
	orb.font1:SetText("100")
	orb.font1:SetPoint("CENTER",0,15)
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
	orb.font2:SetText("100000")
	orb.font2:SetPoint("CENTER",0,-5)

	--position defaults
	orb:ClearAllPoints()
	orb:SetAllPoints(xmlOrbDisplayFrame2)

	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	orb.filling:SetVertexColor(1,1,1,1)
	return orb
end

local function addArtwork(file,orb,name,offsetX,offsetY,height,width)
	local art = CreateFrame("Frame","D32"..name,orb)
	art:SetPoint("CENTER",offsetX,offsetY)
	art:SetHeight(height)
	art:SetWidth(width)
	art:SetFrameStrata("LOW")
	art.texture = art:CreateTexture(nil,"OVERLAY")
	art.texture:SetTexture(file)
	art.texture:SetAllPoints(art)
	return art
end

function D32SetGlobalScale(val)
	val = val/100
	healthOrb:SetScale(val)
	D32CharacterData.healthOrb.scale = val
	manaOrb:SetScale(val)
	D32CharacterData.manaOrb.scale = val
end

function D32MonitorPowers(frame)
	local powerType
	powerFrame.text:SetPoint("CENTER",-1,0)
	if D32className == "Warlock" then
		local powerType = 7;
		local powerMax = UnitPowerMax("player", 7);
		local numShards = UnitPower("player",powerType)
		if numShards > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		if numShards > 999 then
			powerFrame.text:SetFont(D32CharacterData.font,15,"THINOUTLINE")
		elseif numShards > 99 then
			powerFrame.text:SetFont(D32CharacterData.font,18,"THINOUTLINE")
		elseif numShards > 9 then
			powerFrame.text:SetFont(D32CharacterData.font,24,"THINOUTLINE")
		else
			powerFrame.text:SetFont(D32CharacterData.font,26,"THINOUTLINE")
		end
		frame.text:SetText(numShards)
		if numShards > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		else
			powerFrame.text:SetPoint("CENTER",0,0)
		end
		if numShards >= powerMax then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Paladin" then
		powerType = 9
		local numHolyPower = UnitPower("player",powerType)
		if numHolyPower > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(numHolyPower)
		if numHolyPower > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if numHolyPower >=3 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Monk" then
		powerType = 12
		local numHolyPower = UnitPower("player",powerType)
		if numHolyPower > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(numHolyPower)
		if numHolyPower > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if numHolyPower >=4 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Priest" then
		local spec = GetSpecialization();
		if spec == 3 then
			local currentInsanity = UnitPower("player", SPELL_POWER_INSANITY);
			local maxInsanity = UnitPowerMax("player", SPELL_POWER_INSANITY);
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show();
				frame.text:Show();
			end
			if currentInsanity > 99 then
				powerFrame.text:SetFont(D32CharacterData.font,18,"THINOUTLINE")
			elseif currentInsanity > 9 then
				powerFrame.text:SetFont(D32CharacterData.font,24,"THINOUTLINE")
			end
			frame.text:SetText(currentInsanity);
			if currentInsanity == maxInsanity then
				powerFrame.fontHolder.animGroup:Play();
			else
				powerFrame.fontHolder.animGroup:Stop();
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
	elseif D32className == "Rogue" or D32className == "Druid" then
		local comboPoints = GetComboPoints("player","target")
		if comboPoints > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(comboPoints)
		if comboPoints > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if comboPoints >=5 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Mage" then
		--turns out there is no way to track the ice shards for Mage.  Stubbed for now.
	elseif D32className == "Shaman" then
		local spec = GetSpecialization();
		--if we're resto, we don't want to do anything here, otherwise, we're going to track Maelstrom.
		if spec == 3 then return end;
		local maelstrom = UnitPower("player", 11);
		local maxMaelstrom = UnitPowerMax("player", 11);
		if not frame.backDrop:IsVisible() then
			frame.backDrop:Show();
			frame.text:Show();
		end
		if maelstrom > 99 then
			powerFrame.text:SetFont(D32CharacterData.font,18,"THINOUTLINE")
		elseif maelstrom > 9 then
			powerFrame.text:SetFont(D32CharacterData.font,24,"THINOUTLINE")
		end
		frame.text:SetText(maelstrom);
		if maelstrom == maxMaelstrom then
			powerFrame.fontHolder.animGroup:Play();
		else
			powerFrame.fontHolder.animGroup:Stop();
		end
	end

end

local function createPowerFrame(file,orb,name,offsetX,offsetY,height,width)
	local powerFrame = CreateFrame("Frame","D32"..name,orb)
	powerFrame:SetFrameStrata("BACKGROUND")
	powerFrame:SetPoint("CENTER",offsetX,offsetY)
	powerFrame:SetHeight(height)
	powerFrame:SetWidth(width)

	--gradient backdrop
	powerFrame.backDrop = CreateFrame("Frame","D32"..name.."Backdrop",powerFrame)
	powerFrame.backDrop:SetAllPoints(true)
	powerFrame.backDrop.backTexture = powerFrame.backDrop:CreateTexture(nil,"BACKGROUND")
	powerFrame.backDrop.backTexture:SetTexture(images.."d32_powerFrame_backdrop.tga")
	powerFrame.backDrop.backTexture:SetAllPoints(powerFrame)

	--shadowed frame, colorizable
	powerFrame.texture = powerFrame.backDrop:CreateTexture(nil,"OVERLAY")
	powerFrame.texture:SetTexture(file)
	powerFrame.texture:SetVertexColor(D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a)
	powerFrame.texture:SetAllPoints(true)

	--fontholder frame for animations
	powerFrame.fontHolder = CreateFrame("Frame",nil,powerFrame)
	powerFrame.fontHolder:SetFrameStrata("LOW")
	powerFrame.fontHolder:SetAllPoints(true)

	--text
	powerFrame.text = powerFrame.fontHolder:CreateFontString(nil,"OVERLAY")
	powerFrame.text:SetFont(D32CharacterData.font,29,"THINOUTLINE")
	powerFrame.text:SetPoint("CENTER",0,1)
	powerFrame.text:SetTextColor(D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a)
	powerFrame.text:SetText("1")

	local animGroup = powerFrame.fontHolder:CreateAnimationGroup()
	powerFrame.fontHolder.animGroup = animGroup

	local anim1 = powerFrame.fontHolder.animGroup:CreateAnimation("Alpha")
	anim1:SetFromAlpha(1);
	anim1:SetToAlpha(0);
	anim1:SetOrder(1)
	anim1:SetDuration(1.5)
	powerFrame.fontHolder.anim1 = anim1

	local anim2 = powerFrame.fontHolder.animGroup:CreateAnimation("Alpha")
	anim1:SetFromAlpha(1);
	anim1:SetToAlpha(0);
	anim2:SetOrder(2)
	anim1:SetDuration(1.5)
	powerFrame.fontHolder.anim2 = anim2

	animGroup:SetLooping("REPEAT")

	--updates and wh
	powerFrame:SetScript("OnUpdate",D32MonitorPowers)
	powerFrame:Show()

	return powerFrame
end


function checkPetFontPlacement()
	if D32CharacterData.petOrb.showValue and D32CharacterData.petOrb.showPercentage then
		petOrb.font3:SetPoint("CENTER",-20,-8)
		petOrb.font4:SetPoint("CENTER",20,-8)
		petOrb.font1:SetPoint("CENTER",-20,5)
		petOrb.font2:SetPoint("CENTER",20,5)
		petOrb.font3:SetFont(D32CharacterData.font,9,"THINOUTLINE")
		petOrb.font4:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	elseif D32CharacterData.petOrb.showValue and not D32CharacterData.petOrb.showPercentage then
		petOrb.font3:SetPoint("CENTER",-20,0)
		petOrb.font4:SetPoint("CENTER",20,0)
		petOrb.font3:SetFont(D32CharacterData.font,11 * petOrb:GetScale(),"THINOUTLINE")
		petOrb.font4:SetFont(D32CharacterData.font,11 * petOrb:GetScale(),"THINOUTLINE")
	elseif not D32CharacterData.petOrb.showValue and D32CharacterData.petOrb.showPercentage then
		petOrb.font1:SetPoint("CENTER",-20,0)
		petOrb.font2:SetPoint("CENTER",20,0)
	end
end

function checkExtraPowerFontPlacement()
	if D32CharacterData.extraPowerOrb.showValue and D32CharacterData.extraPowerOrb.showPercentage then
		extraPowerOrb.font3:SetPoint("CENTER",-20,-8)
		extraPowerOrb.font4:SetPoint("CENTER",20,-8)
		extraPowerOrb.font1:SetPoint("CENTER",-20,5)
		extraPowerOrb.font2:SetPoint("CENTER",20,5)
		extraPowerOrb.font3:SetFont(D32CharacterData.font,9,"THINOUTLINE")
		extraPowerOrb.font4:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	elseif D32CharacterData.extraPowerOrb.showValue and not D32CharacterData.extraPowerOrb.showPercentage then
		extraPowerOrb.font3:SetPoint("CENTER",-20,0)
		extraPowerOrb.font4:SetPoint("CENTER",20,0)
		extraPowerOrb.font3:SetFont(D32CharacterData.font,11 * extraPowerOrb:GetScale(),"THINOUTLINE")
		extraPowerOrb.font4:SetFont(D32CharacterData.font,11 * extraPowerOrb:GetScale(),"THINOUTLINE")
	elseif not D32CharacterData.extraPowerOrb.showValue and D32CharacterData.extraPowerOrb.showPercentage then
		extraPowerOrb.font1:SetPoint("CENTER",-20,0)
		extraPowerOrb.font2:SetPoint("CENTER",20,0)
	end
end

function setOrbFontPlacement(orb,orbData)
	orb.font1:Show()
	orb.font2:Show()
	if orbData.font1.show and orbData.font2.show then
		orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
		orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
		orb.font1:SetPoint("CENTER",0,15)
		orb.font2:SetPoint("CENTER",0,-5)
	elseif orbData.font1.show and not orbData.font2.show then
		orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
		orb.font1:SetPoint("CENTER",0,0)
		orb.font2:Hide()
	elseif orbData.font2.show and not orbData.font1.show then
		orb.font2:SetFont(D32CharacterData.font,25,"THINOUTLINE")
		orb.font2:SetPoint("CENTER",0,0)
		orb.font1:Hide()
	else
		orb.font1:Hide()
		orb.font2:Hide()
	end
end

function checkXMLOrbFontPlacement()
	xmlOrbDisplayFrame2.orb.font1:Show()
	xmlOrbDisplayFrame2.orb.font2:Show()
	if D32OrbPercentageCheckBox:GetChecked() and D32OrbValueCheckBox:GetChecked() then
		xmlOrbDisplayFrame2.orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font1:SetPoint("CENTER",0,15)
		xmlOrbDisplayFrame2.orb.font2:SetPoint("CENTER",0,-5)
	elseif D32OrbPercentageCheckBox:GetChecked() and not D32OrbValueCheckBox:GetChecked() then
		xmlOrbDisplayFrame2.orb.font1:SetFont(D32CharacterData.font,32,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font1:SetPoint("CENTER",0,0)
		xmlOrbDisplayFrame2.orb.font2:Hide()
	elseif D32OrbValueCheckBox:GetChecked() and not D32OrbPercentageCheckBox:GetChecked() then
		xmlOrbDisplayFrame2.orb.font2:SetFont(D32CharacterData.font,32,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font2:SetPoint("CENTER",0,0)
		xmlOrbDisplayFrame2.orb.font1:Hide()
	else
		xmlOrbDisplayFrame2.orb.font1:Hide()
		xmlOrbDisplayFrame2.orb.font2:Hide()
	end
end

function resetXMLTextBoxes()
	D32OrbPercentageCheckBox:SetChecked(CommitButton.orbData.font1.show)
	D32OrbValueCheckBox:SetChecked(CommitButton.orbData.font2.show)
end

local function checkDefaultsFromMemory()
	if not D32CharacterData.healthOrb then D32CharacterData.healthOrb = defaultsTable.healthOrb end
	if not D32CharacterData.healthOrb.textures then D32CharacterData.healthOrb.textures = defaultTextures.healthOrb end
	if D32CharacterData.healthOrb.font1.show == nil then D32CharacterData.healthOrb.font1.show = defaultsTable.healthOrb.font1.show end
	if D32CharacterData.healthOrb.font2.show == nil then D32CharacterData.healthOrb.font2.show = defaultsTable.healthOrb.font2.show end
	if D32CharacterData.healthOrb.offsetX == nil then D32CharacterData.healthOrb.offsetX = defaultsTable.healthOrb.offsetX end
	if D32CharacterData.healthOrb.offsetY == nil then D32CharacterData.healthOrb.offsetY = defaultsTable.healthOrb.offsetY end
	if D32CharacterData.healthOrb.point == nil then D32CharacterData.healthOrb.point = defaultsTable.healthOrb.point end
	if D32CharacterData.healthOrb.relativePoint == nil then D32CharacterData.healthOrb.relativePoint = defaultsTable.healthOrb.relativePoint end
	if not D32CharacterData.manaOrb then D32CharacterData.manaOrb = defaultsTable.manaOrb end
	if not D32CharacterData.manaOrb.textures then D32CharacterData.manaOrb.textures = defaultTextures.manaOrb end
	if D32CharacterData.manaOrb.font1.show == nil then D32CharacterData.manaOrb.font1.show = defaultsTable.manaOrb.font1.show end
	if D32CharacterData.manaOrb.font2.show == nil then D32CharacterData.manaOrb.font2.show = defaultsTable.manaOrb.font2.show end
	if D32CharacterData.manaOrb.offsetX == nil then D32CharacterData.manaOrb.offsetX = defaultsTable.manaOrb.offsetX end
	if D32CharacterData.manaOrb.offsetY == nil then D32CharacterData.manaOrb.offsetY = defaultsTable.manaOrb.offsetY end
	if D32CharacterData.manaOrb.point == nil then D32CharacterData.manaOrb.point = defaultsTable.manaOrb.point end
	if D32CharacterData.manaOrb.relativePoint == nil then D32CharacterData.manaOrb.relativePoint = defaultsTable.manaOrb.relativePoint end
	if not D32CharacterData.druidColors then D32CharacterData.druidColors = defaultsTable.druidColors end
	if not D32CharacterData.combat then D32CharacterData.combat = defaultsTable.combat end
	if not D32CharacterData.combat.galaxy then D32CharacterData.combat.galaxy = defaultsTable.combat.galaxy end
	if not D32CharacterData.values then D32CharacterData.values = defaultsTable.values  end
	if not D32CharacterData.artwork then D32CharacterData.artwork = defaultsTable.artwork end
	if not D32CharacterData.font then D32CharacterData.font = defaultsTable.font end
	if not D32CharacterData.petOrb then D32CharacterData.petOrb = defaultsTable.petOrb end
	if not D32CharacterData.petOrb.scale then D32CharacterData.petOrb.scale = defaultsTable.petOrb.scale end
	if not D32CharacterData.extraPowerOrb then D32CharacterData.extraPowerOrb = defaultsTable.extraPowerOrb end
	if not D32CharacterData.extraPowerOrb.scale then D32CharacterData.extraPowerOrb.scale = defaultsTable.extraPowerOrb.scale end
	if not D32CharacterData.powerFrame then D32CharacterData.powerFrame = defaultsTable.powerFrame end
	if not D32CharacterData.defaultPlayerFrame then D32CharacterData.defaultPlayerFrame = defaultsTable.defaultPlayerFrame end
	if not D32CharacterData.smoothing then D32CharacterData.smoothing = defaultsTable.defaultSmoothing end
	if not D32CharacterData.healthOrb.formatting then D32CharacterData.healthOrb.formatting = defaultsTable.healthOrb.formatting end
	if not D32CharacterData.manaOrb.formatting then D32CharacterData.manaOrb.formatting = defaultsTable.manaOrb.formatting end

	AnimateOrbValuesCheckButton:SetChecked(D32CharacterData.smoothing)
	ShowArtworkCheckButton:SetChecked(D32CharacterData.artwork.show)
	UsePetOrbCheckButton:SetChecked(D32CharacterData.petOrb.enabled)
	TrackCombatCheckButton:SetChecked(D32CharacterData.combat.enabled)
	ShowPetOrbPercentagesCheckButton:SetChecked(D32CharacterData.petOrb.showPercentage)
	ShowPetOrbValuesCheckButton:SetChecked(D32CharacterData.petOrb.showValue)
	UseExtraPowerOrbCheckButton:SetChecked(D32CharacterData.extraPowerOrb.enabled)
	ShowExtraPowerOrbPercentagesCheckButton:SetChecked(D32CharacterData.extraPowerOrb.showPercentage)
	ShowExtraPowerOrbValuesCheckButton:SetChecked(D32CharacterData.extraPowerOrb.showValue)
	UsePowerTrackerCheckButton:SetChecked(D32CharacterData.powerFrame.show)
	ShowBlizzPlayerFrameCheckButton:SetChecked(D32CharacterData.defaultPlayerFrame.show)

	if not D32CharacterData.petOrb.showValue then
		petOrb.font3:Hide()
		petOrb.font4:Hide()
	end
	if not D32CharacterData.petOrb.showPercentage then
		petOrb.font1:Hide()
		petOrb.font2:Hide()
	end
	checkPetFontPlacement()

	if not D32CharacterData.petOrb.enabled then
	 UnregisterUnitWatch(petOrb)
	 petOrb:Hide()
	end

	if not D32CharacterData.extraPowerOrb.showValue then
		extraPowerOrb.font3:Hide()
		extraPowerOrb.font4:Hide()
	end
	
	if not D32CharacterData.extraPowerOrb.showPercentage then
		extraPowerOrb.font1:Hide()
		extraPowerOrb.font2:Hide()
	end
	checkExtraPowerFontPlacement()

	if not D32CharacterData.extraPowerOrb.enabled then
		extraPowerOrb:SetScript("OnUpdate",nil)
		extraPowerOrb:Hide()
	end

	if not D32CharacterData.artwork.show then
		angelFrame:Hide()
		demonFrame:Hide()
	end

	if powerFrame then
		if not D32CharacterData.powerFrame.show then
			powerFrame:SetScript("OnUpdate",nil)
			powerFrame:Hide()
		end
	end
end

local function updateColorsFromMemory()
	--health orb fill, galaxy and font colors
	local r,g,b,a = D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a
	healthOrb.filling:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.healthOrb.galaxy.r,D32CharacterData.healthOrb.galaxy.g,D32CharacterData.healthOrb.galaxy.b,D32CharacterData.healthOrb.galaxy.a
	healthOrb.galaxy1.texture:SetVertexColor(r,g,b,a)
	healthOrb.galaxy2.texture:SetVertexColor(r,g,b,a)
	healthOrb.galaxy3.texture:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.healthOrb.font1.r,D32CharacterData.healthOrb.font1.g,D32CharacterData.healthOrb.font1.b,D32CharacterData.healthOrb.font1.a
	healthOrb.font1:SetTextColor(r,g,b,a)
	r,g,b,a = D32CharacterData.healthOrb.font2.r,D32CharacterData.healthOrb.font2.g,D32CharacterData.healthOrb.font2.b,D32CharacterData.healthOrb.font2.a
	healthOrb.font2:SetTextColor(r,g,b,a)
	healthOrb:SetScale(D32CharacterData.healthOrb.scale)

	--mana orb fill, galaxy and font colors
	r,g,b,a = D32CharacterData.manaOrb.orbColor.r,D32CharacterData.manaOrb.orbColor.g,D32CharacterData.manaOrb.orbColor.b,D32CharacterData.manaOrb.orbColor.a
	manaOrb.filling:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.manaOrb.galaxy.r,D32CharacterData.manaOrb.galaxy.g,D32CharacterData.manaOrb.galaxy.b,D32CharacterData.manaOrb.galaxy.a
	manaOrb.galaxy1.texture:SetVertexColor(r,g,b,a)
	manaOrb.galaxy2.texture:SetVertexColor(r,g,b,a)
	manaOrb.galaxy3.texture:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.manaOrb.font1.r,D32CharacterData.manaOrb.font1.g,D32CharacterData.manaOrb.font1.b,D32CharacterData.manaOrb.font1.a
	manaOrb.font1:SetTextColor(r,g,b,a)
	r,g,b,a = D32CharacterData.manaOrb.font2.r,D32CharacterData.manaOrb.font2.g,D32CharacterData.manaOrb.font2.b,D32CharacterData.manaOrb.font2.a
	manaOrb.font2:SetTextColor(r,g,b,a)
	manaOrb:SetScale(D32CharacterData.manaOrb.scale)

	petOrb.filling1:SetVertexColor(healthOrb.filling:GetVertexColor())
	petOrb.filling2:SetVertexColor(manaOrb.filling:GetVertexColor())
	petOrb.font1:SetTextColor(healthOrb.font1:GetTextColor())
	petOrb.font2:SetTextColor(manaOrb.font1:GetTextColor())
	petOrb.font3:SetTextColor(healthOrb.font2:GetTextColor())
	petOrb.font4:SetTextColor(manaOrb.font2:GetTextColor())

	extraPowerOrb.filling1:SetVertexColor(1,0,0)
	extraPowerOrb.filling2:SetVertexColor(1,1,0)
	extraPowerOrb.font1:SetTextColor(healthOrb.font1:GetTextColor())
	extraPowerOrb.font2:SetTextColor(manaOrb.font1:GetTextColor())
	extraPowerOrb.font3:SetTextColor(healthOrb.font2:GetTextColor())
	extraPowerOrb.font4:SetTextColor(manaOrb.font2:GetTextColor())

	D32ScaleSlider:SetValue((D32CharacterData.healthOrb.scale) * 100)

	setOrbFontPlacement(healthOrb,D32CharacterData.healthOrb)
	setOrbFontPlacement(manaOrb,D32CharacterData.manaOrb)
end

function D32UpdateOrbColor(orb,orbColor,galaxyColor,font1Color,font2Color)
	orb.filling:SetVertexColor(orbColor.r,orbColor.g,orbColor.b,orbColor.a)
	orb.galaxy1.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	orb.galaxy2.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	orb.galaxy3.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	orb.font1:SetTextColor(font1Color.r,font1Color.g,font1Color.b,font1Color.a)
	orb.font2:SetTextColor(font2Color.r,font2Color.g,font2Color.b,font2Color.a)
end

local function TryNewColors(restore)
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()

	if restore then
		r,g,b,a = unpack(restore)
	end

	if ColorPickerFrame.elementToChange == "Filling" then
		xmlOrbDisplayFrame2.orb.filling:SetVertexColor(r,g,b,a)
	elseif ColorPickerFrame.elementToChange == "Swirl" then
		xmlOrbDisplayFrame2.orb.galaxy1.texture:SetVertexColor(r,g,b,a)
		xmlOrbDisplayFrame2.orb.galaxy2.texture:SetVertexColor(r,g,b,a)
		xmlOrbDisplayFrame2.orb.galaxy3.texture:SetVertexColor(r,g,b,a)
	elseif ColorPickerFrame.elementToChange == "Font1" then
		xmlOrbDisplayFrame2.orb.font1:SetTextColor(r,g,b,a)
	elseif ColorPickerFrame.elementToChange == "Font2" then
		xmlOrbDisplayFrame2.orb.font2:SetTextColor(r,g,b,a)
	end
end

function TryNewTextures(fillTexture,swirlTexture)
	xmlOrbDisplayFrame2.orb.filling:SetTexture(fillTexture)
	if swirlTexture then
		xmlOrbDisplayFrame2.orb.galaxy1.texture:SetTexture(swirlTexture.."1.tga")
		xmlOrbDisplayFrame2.orb.galaxy2.texture:SetTexture(swirlTexture.."2.tga")
		xmlOrbDisplayFrame2.orb.galaxy3.texture:SetTexture(swirlTexture.."3.tga")
	end
end

local function checkShapeShiftInfo()
	--we can use the number of shapeshift forms to figure out if we're in bear form, or cat form, at lower levels
	local numShapeshiftForms = GetNumShapeshiftForms()
	local form = GetShapeshiftForm()
	local druidFormTable = D32CharacterData.manaOrb
	local changeOcurred = true
	if form == 1 and numShapeshiftForms >=2 then
		druidFormTable = D32CharacterData.druidColors.bear
		previousPowerValue = UnitPower("player","RAGE")
	elseif form == 2 or (numShapeshiftForms == 1 and form == 1) then
		druidFormTable = D32CharacterData.druidColors.cat
		previousPowerValue = UnitPower("player","ENERGY")
	else
		druidFormTable = D32CharacterData.manaOrb
		previousPowerValue = UnitPower("player","MANA")
	end
	D32UpdateOrbColor(manaOrb,druidFormTable.orbColor,druidFormTable.galaxy,druidFormTable.font1,druidFormTable.font2)
end

local function UpdateOrbTextures()
	healthOrb.filling:SetTexture(images..D32CharacterData.healthOrb.textures.fill)
	healthOrb.galaxy1.texture:SetTexture(images..D32CharacterData.healthOrb.textures.rotation.."1.tga")
	healthOrb.galaxy2.texture:SetTexture(images..D32CharacterData.healthOrb.textures.rotation.."2.tga")
	healthOrb.galaxy3.texture:SetTexture(images..D32CharacterData.healthOrb.textures.rotation.."3.tga")

	manaOrb.filling:SetTexture(images..D32CharacterData.manaOrb.textures.fill)
	manaOrb.galaxy1.texture:SetTexture(images..D32CharacterData.manaOrb.textures.rotation.."1.tga")
	manaOrb.galaxy2.texture:SetTexture(images..D32CharacterData.manaOrb.textures.rotation.."2.tga")
	manaOrb.galaxy3.texture:SetTexture(images..D32CharacterData.manaOrb.textures.rotation.."3.tga")
end

function D32ApplyChanges()
	local activeElement = CommitButton.activeElement
	local r,g,b,a = xmlOrbDisplayFrame2.orb.filling:GetVertexColor()
	local fillColors = {r=0,g=0,b=0,a=0}
	fillColors.r, fillColors.g, fillColors.b, fillColors.a = r,g,b,a
	activeElement.orbColor.r, activeElement.orbColor.g, activeElement.orbColor.b, activeElement.orbColor.a = r,g,b,a

	local galaxyColors = {r=0,g=0,b=0,a=0}
	r,g,b,a = xmlOrbDisplayFrame2.orb.galaxy1.texture:GetVertexColor()
	galaxyColors.r, galaxyColors.g, galaxyColors.b, galaxyColors.a = r,g,b,a
	activeElement.galaxy.r, activeElement.galaxy.g, activeElement.galaxy.b, activeElement.galaxy.a = r,g,b,a

	local font1Color = {r=0,g=0,b=0,a=0}
	r,g,b,a = xmlOrbDisplayFrame2.orb.font1:GetTextColor()
	font1Color.r,font1Color.g,font1Color.b,font1Color.a = r,g,b,a
	activeElement.font1.r, activeElement.font1.g, activeElement.font1.b, activeElement.font1.a = r,g,b,a

	local font2Color = {r=0,g=0,b=0,a=0}
	r,g,b,a = xmlOrbDisplayFrame2.orb.font2:GetTextColor()
	font2Color.r,font2Color.g,font2Color.b,font2Color.a = r,g,b,a
	activeElement.font2.r, activeElement.font2.g, activeElement.font2.b, activeElement.font2.a = r,g,b,a

	D32UpdateOrbColor(healthOrb,D32CharacterData.healthOrb.orbColor,D32CharacterData.healthOrb.galaxy,D32CharacterData.healthOrb.font1,D32CharacterData.healthOrb.font2)

	local hPrefix = strmatch(xmlOrbDisplayFrame2.orb.filling:GetTexture(),"(MDO_orb_filling%d+)")
	CommitButton.textureElement.fill = hPrefix
	local mPrefix,mNum = strmatch(xmlOrbDisplayFrame2.orb.galaxy1.texture:GetTexture(),"(orb_rotation_%a+)(%d)")
	CommitButton.textureElement.rotation = mPrefix
	UpdateOrbTextures()

	if D32OrbPercentageCheckBox:GetChecked() then
		CommitButton.orbData.font1.show = true
	else
		CommitButton.orbData.font1.show = false
	end

	if D32OrbValueCheckBox:GetChecked() then
		CommitButton.orbData.font2.show = true
	else
		CommitButton.orbData.font2.show = false
	end

	setOrbFontPlacement(CommitButton.orb,CommitButton.orbData)


	if D32className == "Druid" then
		checkShapeShiftInfo()
	else
		D32UpdateOrbColor(manaOrb,D32CharacterData.manaOrb.orbColor,D32CharacterData.manaOrb.galaxy,D32CharacterData.manaOrb.font1,D32CharacterData.manaOrb.font2)
	end

	--set pet fill colors to that of the fill colors of the health/mana orbs
	petOrb.filling1:SetVertexColor(healthOrb.filling:GetVertexColor())
	petOrb.filling2:SetVertexColor(manaOrb.filling:GetVertexColor())
	petOrb.font1:SetTextColor(healthOrb.font1:GetTextColor())
	petOrb.font2:SetTextColor(manaOrb.font1:GetTextColor())
	petOrb.font3:SetTextColor(healthOrb.font2:GetTextColor())
	petOrb.font4:SetTextColor(manaOrb.font2:GetTextColor())

	-- ToDo: add seperate configurations for the extra power bar
	extraPowerOrb.filling1:SetVertexColor(1,0,0)
	extraPowerOrb.filling2:SetVertexColor(1,1,0)
	extraPowerOrb.font1:SetTextColor(healthOrb.font1:GetTextColor())
	extraPowerOrb.font2:SetTextColor(manaOrb.font1:GetTextColor())
	extraPowerOrb.font3:SetTextColor(healthOrb.font2:GetTextColor())
	extraPowerOrb.font4:SetTextColor(manaOrb.font2:GetTextColor())
end

function D32ColorPicker(xmlElement)
	local r,g,b,a
	if xmlElement == "Filling" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.filling:GetVertexColor()
	elseif xmlElement == "Swirl" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.galaxy1.texture:GetVertexColor()
	elseif xmlElement == "Font1" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.font1:GetTextColor()
	elseif xmlElement == "Font2" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.font2:GetTextColor()
	end

	ColorPickerFrame.elementToChange = xmlElement
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = TryNewColors,TryNewColors,TryNewColors
	ColorPickerFrame:SetColorRGB(r,g,b,a)
	ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
	ColorPickerFrame.previousValues = {r,g,b,a}
	makeFrameMovable(ColorPickerFrame,"RightButton")
	ColorPickerFrame:EnableKeyboard(false)
	ColorPickerFrame:Show()
end

function UpdateXMLTextures(orb)
	xmlOrbDisplayFrame2.orb.filling:SetTexture(orb.filling:GetTexture())
	xmlOrbDisplayFrame2.orb.galaxy1.texture:SetTexture(orb.galaxy1.texture:GetTexture())
	xmlOrbDisplayFrame2.orb.galaxy2.texture:SetTexture(orb.galaxy2.texture:GetTexture())
	xmlOrbDisplayFrame2.orb.galaxy3.texture:SetTexture(orb.galaxy3.texture:GetTexture())

	--we'll come back to this one later...
	--local num = table.getn(D32FillTextureChoices)
	--for i=0,num,1 do
	--	local fillPrefix = strmatch(D32FillTextureChoices[i],"(MDO_orb_filling%d+)")
	--	if tostring(CommitButton.textureElement.fill) == fillPrefix then

	--	end
	--endd

	--num = table.getn(D32RotationTextureChoices)
	--for i=0,num,1 do
	--	local rotationPrefix = strmatch(D32RotationTextureChoices[i],"(orb_rotation_%a+)")
	--	if tostring(CommitButton.textureElement.rotation) == rotationPrefix then

	--	end
	--end

	UIDropDownMenu_SetText(FillTexturesDropDown,"Choose one...")
	UIDropDownMenu_SetText(RotationTexturesDropDown,"Choose one...")
end

function UpdateXMLColors(orbColor,galaxyColor,font1,font2)
	xmlOrbDisplayFrame2.orb.filling:SetVertexColor(orbColor.r,orbColor.g,orbColor.b,orbColor.a)
	xmlOrbDisplayFrame2.orb.galaxy1.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	xmlOrbDisplayFrame2.orb.galaxy2.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	xmlOrbDisplayFrame2.orb.galaxy3.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	xmlOrbDisplayFrame2.orb.font1:SetTextColor(font1.r,font1.g,font1.b,font1.a)
	xmlOrbDisplayFrame2.orb.font2:SetTextColor(font2.r,font2.g,font2.b,font2.a)
end

function UpdateXMLText(orb, formatting)
	xmlOrbDisplayFrame2.orb.font1:SetText(orb.font1:GetText())
	if not formatting then
		xmlOrbDisplayFrame2.orb.font2:SetText(orb.font2:GetText())
	else
		xmlOrbDisplayFrame2.orb.font2:SetText(valueFormat(orb.maxValue(), formatting, false))
	end
end

function FillXMLTemplate(frame)
	frame.orb = CreateXMLOrb(xmlOrbDisplayFrame2,"D32_XMLOrb",150,defaultTextures.healthOrb.fill,defaultTextures.healthOrb.rotation)
	frame.orb.galaxy1.texture:SetAlpha(0.5)
	frame.orb.galaxy2.texture:SetAlpha(0.5)
	frame.orb.galaxy3.texture:SetAlpha(0.5)
	frame:SetScale(1.5)
end

--alloc the orbs and assign them to the health/mana orb variables, make them both movable from the get-go for testing
healthOrb = CreateOrb(nil,"D32_HealthOrb",defaultOrbSize,defaultTextures.healthOrb.fill,defaultTextures.healthOrb.rotation,-250,0,"BOTTOM",monitorHealth)
manaOrb = CreateOrb(nil,"D32_ManaOrb",defaultOrbSize,defaultTextures.manaOrb.fill,defaultTextures.manaOrb.rotation,250,0,"BOTTOM",monitorPower)
petOrb = CreatePetOrb(healthOrb,"D32_PetOrb",87,-95,70,nil)
extraPowerOrb = CreateExtraPowerOrb(manaOrb,"D32_ExtraPowerOrb",87,-95,70,nil)
powerFrame = nil
if D32className == "Paladin" or D32className == "Warlock" or D32className == "Rogue" or D32className == "Druid" or D32className == "Monk" or D32className == "Priest" or D32className == "Shaman" then powerFrame =  createPowerFrame(images.."d32_powerFrame.tga",manaOrb,"PowerFrame",95,50,50,50) end
if powerFrame then makeFrameMovable(powerFrame) end
angelFrame = addArtwork(images.."d3_angel2test.tga",manaOrb,"AngelFrame",70,5,160,160)
demonFrame = addArtwork(images.."d3_demon2test.tga",healthOrb,"DemonFrame",-90,5,160,160)
makeFrameMovable(healthOrb, nil, function(point,relativePoint,xOfs,yOfs)
	D32CharacterData.healthOrb.point = point
	D32CharacterData.healthOrb.relativePoint = relativePoint
	D32CharacterData.healthOrb.offsetX = xOfs
	D32CharacterData.healthOrb.offsetY = yOfs
end)
makeFrameMovable(manaOrb, nil, function(point,relativePoint,xOfs,yOfs)
	D32CharacterData.manaOrb.point = point
	D32CharacterData.manaOrb.relativePoint = relativePoint
	D32CharacterData.manaOrb.offsetX = xOfs
	D32CharacterData.manaOrb.offsetY = yOfs
end)
makeFrameMovable(petOrb)
makeFrameMovable(extraPowerOrb)

function healthOrb:UpdateState()
	local point, relativeTo, relativePoint = healthOrb:GetPoint()
	healthOrb:SetPoint(D32CharacterData.healthOrb.point, relativeTo, D32CharacterData.healthOrb.relativePoint, D32CharacterData.healthOrb.offsetX, D32CharacterData.healthOrb.offsetY)	
end

function manaOrb:UpdateState()
	local point, relativeTo, relativePoint = manaOrb:GetPoint()
	manaOrb:SetPoint(D32CharacterData.manaOrb.point, relativeTo, D32CharacterData.manaOrb.relativePoint, D32CharacterData.manaOrb.offsetX, D32CharacterData.manaOrb.offsetY)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("UNIT_ENERGY")
eventFrame:RegisterEvent("UNIT_RAGE")
if D32className == "Druid" then
	eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
end

local flagHide_PetFrame = false
function eventFrame:OnEvent(event,arg1)
	if event == "ADDON_LOADED" then
		checkDefaultsFromMemory()
		handlePlayerFrame(D32CharacterData.defaultPlayerFrame.show)
		updateColorsFromMemory()
		UpdateOrbTextures()
		D32UpdateOrbColor(healthOrb,D32CharacterData.healthOrb.orbColor,D32CharacterData.healthOrb.galaxy,D32CharacterData.healthOrb.font1,D32CharacterData.healthOrb.font2)
		local colorTable
		if D32className == "Druid" then
			checkShapeShiftInfo()
		else
			D32UpdateOrbColor(manaOrb,D32CharacterData.manaOrb.orbColor,D32CharacterData.manaOrb.galaxy,D32CharacterData.manaOrb.font1,D32CharacterData.manaOrb.font2)
		end
		D32GUI:Hide()
		-- Reposition based on saved data
		healthOrb:UpdateState()
		manaOrb:UpdateState()
	elseif event == "VARIABLES_LOADED" then
		D32MiniMapButtonPosition_LoadFromDefaults()	
		if D32CharacterData.extraPowerOrb.enabled then
			extraPowerOrb:SetScript("OnUpdate",updateExtraPowerValues)
		end
	elseif event == "UNIT_ENTERED_VEHICLE" then
		if arg1 == "player" and UnitControllingVehicle("player") then
			vehicleInUse = 1
			previousPowerValue = 0
			previousHealthValue = 0
		end
	elseif event == "UNIT_EXITED_VEHICLE" then
		if arg1 == "player" and vehicleInUse == 1 then
			vehicleInUse = 0
			previousHealthValue = 0
			previousPowerValue = 0
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		if D32CharacterData.combat.enabled then
			D32UpdateOrbColor(healthOrb,D32CharacterData.combat.orbColor,D32CharacterData.combat.galaxy,D32CharacterData.combat.font1,D32CharacterData.combat.font2)
			petOrb.filling1:SetVertexColor(D32CharacterData.combat.orbColor.r,D32CharacterData.combat.orbColor.g,D32CharacterData.combat.orbColor.b,D32CharacterData.combat.orbColor.a)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if D32CharacterData.combat.enabled then
			D32UpdateOrbColor(healthOrb,D32CharacterData.healthOrb.orbColor,D32CharacterData.healthOrb.galaxy, D32CharacterData.healthOrb.font1,D32CharacterData.healthOrb.font2)
			petOrb.filling1:SetVertexColor(D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a)
		end
	elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "PLAYER_LEVEL_UP" then
		checkShapeShiftInfo()
	elseif event == "UNIT_PET" then
		local name,realm = UnitName("pet")
		if not name then
			petOrb:SetScript("OnUpdate",nil)
		else
			petOrb:SetScript("OnUpdate",updatePetValues)
			previousPetHealth = UnitHealth("pet")
			previousPetPower = UnitPower("pet")
		end
	elseif event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
		previousExtraPowerOrbRage = UnitPower("player",1)
		previousExtraPowerEnergy = UnitPower("player",3)		
	end
end

eventFrame:SetScript("OnEvent",eventFrame.OnEvent)

--slash command method
local function CommandFunc(cmd)
	if cmd == "disable" then
		healthOrb:SetScript("OnUpdate",nil)
		manaOrb:SetScript("OnUpdate",nil)
		healthOrb:Hide()
		manaOrb:Hide()
	elseif cmd == "enable" then
		healthOrb:SetScript("OnUpdate",monitorHealth)
		manaOrb:SetScript("OnUpdate",monitorPower)
		healthOrb:Show()
		manaOrb:Show()
	elseif cmd == "help" then

	else
		Handle_D32GUI()
	end
end

--setup the slash command stuff, hide the GUI
SlashCmdList["MDO"] = CommandFunc;
SLASH_MDO1 = "/mdo";
