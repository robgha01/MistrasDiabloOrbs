--Utils contains convenience functions for textures, scaling, moving things, etc

--assign to self
MD3Utils = {};
self = MD3Utils;

function self:SetTextureRGBOpaqueFloat(texture, r, g, b)
	texture:SetVertexColor(r, g, b, 1);
end

function self:SetTextureRGBAFloat(texture, r, g, b, a)
	texture:SetVertexColor(r, g, b, a);
end

function self:ConvertByteRGBToFloatRGB(r, g, b)
	return r / 255, g / 255, b / 255;
end

function self:SetFrameScale(frame, scale)
	frame:SetScale(scale);
end

function self:SetTextureVerticalFill(texture, texHeight, fillLevel)
	if not type(fillLevel) == "number" or fillLevel == math.huge then fillLevel = 0 end;
	local verticalTexHeight = math.min(1, math.abs(fillLevel - 1));
	texture:SetHeight(texHeight * fillLevel);
	texture:SetTexCoord(0, 1, verticalTexHeight, 1);
end

function self:SetTextureTexture(texture, textureFilePath)
	texture:SetTexture(textureFilePath);
end

function self:SetFrameMovableWithCustomLogic(frame, mouseButton, logicFunc)
	frame:SetClampedToScreen(true);
	frame:SetMovable(true);
	frame:EnableMouse(true);
	frame:RegisterForDrag(mouseButton);
	frame:SetScript("OnDragStart", function(self)
		if (logicFunc ~= nil and logicFunc()) then
			self:StartMoving();
		else
			self:StartMoving();
		end
	 end);
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
	end)
end
