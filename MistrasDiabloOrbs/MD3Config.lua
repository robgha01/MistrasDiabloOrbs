--MD3Config stores all tables, defaults, definitions, paths, etc, and is also responsible for iterating over the defaults table and making assignments to any serialized data on load
--define the player data global state
MD3PlayerData = {};
MD3Config = {};
self = MD3Config;

self.MD3PlayerDefaults = {

};

self.MD3FilePathConfig = {
	rootPath = "Interface\\Addons\\MistrasDiabloOrbs",
	orbFillsPath = "Interface\\Addons\\MistrasDiabloOrbs\\images\\tga\\Fills",
	orbContainersPath = "Interface\\Addons\\MistrasDiabloOrbs\\images\\tga\\Containers"
};

self.MD3Textures = {
	fills = {
		["NormalGradient"] = {
			size = 512,
			filePath = self.MD3FilePathConfig.orbFillsPath .. "\\NormalGradient.tga"
		}
	},
	containers = {
		["SharpLight"] = {
			size = 512,
			filePath = self.MD3FilePathConfig.orbContainersPath .. "\\OrbGloss2.tga"
		},
		["SoftLight"] = {
			size = 512,
			filePath = self.MD3FilePathConfig.orbContainersPath .. "\\OrbGloss3.tga"
		},
		["Bubbles"] = {
			size = 512,
			filePath = self.MD3FilePathConfig.orbContainersPath .. "\\OrbGloss4.tga"
		}
	}
};

function self:RecursiveIterateCompareAndAssignTableData(table1, table2)
	for key, value in pairs(table1) do
		--if table 2 is missing this value, set it, otherwise, iterate
		if table2[key] == nil then
			table2[key] = table1[key];
		end

		if type(value) == "table" then
			--if this is a table value, iterate through the table
			MD3Config:RecursiveIterateCompareAndAssignTableData(table1[key], table2[key]);
		end
	end
end

function self:SetMissingDefaultsInPlayerDataTable()
	MD3Config:RecursiveIterateCompareAndAssignTableData(self.MD3PlayerDefaults, MD3PlayerData);
end
