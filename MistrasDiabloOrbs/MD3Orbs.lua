--identity
MD3Orbs = {};
self = MD3Orbs;

local defaultFill = MD3Config.MD3Textures.fills["NormalGradient"];
local defaultContainer = MD3Config.MD3Textures.containers["Bubbles"];
local defaultSize = 512;

function self:CreateOrbWithSingleFill()
	local orbFrame = CreateFrame("Button", "md3_frame_testOrb", UIParent, "SecureUnitButtonTemplate");
	orbFrame:SetHeight(defaultSize);
	orbFrame:SetWidth(defaultSize);
	orbFrame:SetFrameStrata("BACKGROUND");

	orbFrame.overlay = orbFrame:CreateTexture(nil, "OVERLAY");
	orbFrame.overlay:SetTexture(defaultContainer.filePath);
	orbFrame.overlay.size = defaultSize;
	orbFrame.overlay:SetPoint("CENTER", 0, 0);
	orbFrame.overlay:SetWidth(defaultSize);
	orbFrame.overlay:SetHeight(defaultSize);

	orbFrame.fill = orbFrame:CreateTexture(nil, "BACKGROUND");
	orbFrame.fill:SetTexture(defaultFill.filePath, false, true);
	orbFrame.fill.size = defaultSize;
	orbFrame.fill:SetVertexColor(0.41, 0.80, 0.94, 1);
	orbFrame.fill:SetPoint("BOTTOM", 0, 0);
	orbFrame.fill:SetWidth(defaultSize);
	orbFrame.fill:SetHeight(defaultSize);
	orbFrame.fill.resourceCurrentValueFunction = nil;
	orbFrame.fill.resourceMaxValueFunction = nil;
	orbFrame.fill:SetAlpha(1);
	orbFrame:ClearAllPoints();
	orbFrame:SetPoint("CENTER", nil, "CENTER", 0, 0);
	orbFrame:SetScript("OnUpdate", function(orbFrame)
		MD3Orbs:MonitorFill(orbFrame);
	end);
	return orbFrame;
end

--MonitorFill expects the orb frame to have undergone unit and resource setup in MD3CoreLib or elsewhere, prior to being able to monitor a resource
function self:MonitorFill(orbFrame)
	local fill = orbFrame.fill;
	if (orbFrame.fill ~= nil and orbFrame.resourceCurrentValueFunction ~= nil and orbFrame.resourceMaxValueFunction ~= nil) then
		MD3Utils:SetTextureVerticalFill(fill, fill.size, orbFrame.resourceCurrentValueFunction(orbFrame.unit) / orbFrame.resourceMaxValueFunction(orbFrame.unit)
			);
	end
end

-- local orb = self:CreateOrbWithSingleFill();
-- MD3CoreLib:SetUnitAndUnitFunctions(orb, "target");
-- MD3CoreLib:SetResourceType(orb, "health");
-- MD3Utils:SetFrameScale(orb, .4);
-- MD3Utils:SetTextureRGBAFloat(
-- 	orb.fill,
-- 	MD3Utils:ConvertByteRGBToFloatRGB(255, 0, 122)
-- );
-- MD3Utils:SetFrameMovableWithCustomLogic(orb, "LeftButton", IsShiftKeyDown);
