--!native
--!strict
local ChancesTemplate = require(script.ChanceTemplate)

local module = {
	['Server'] = {
		["Frostbite Egg"] = {
			['Robux1'] = 1887043767,
			['Robux3'] = 1887044006,
			['Robux8'] = 1887044205,
			['Chances'] = ChancesTemplate.Server["Frostbite Egg"]
		}
	},
	
	['Map1'] = {
		['Egg1'] = {
			['WinsCost'] = 5,
			['Chances'] = ChancesTemplate.Map1.Egg1
		},
		['Egg2'] = {
			['WinsCost'] = 350,
			['Chances'] = ChancesTemplate.Map1.Egg2
		},
		['Egg3Robux'] = {
			['Robux1'] = 1631383150,
			['Robux3'] = 1631383146,
			['Robux5'] = 1631383837,
			['Chances'] = ChancesTemplate.Map1.Egg3Robux
		}
	},
	['Map2'] = {
		['Egg1'] = {
			['WinsCost'] = 10_000,
			['Chances'] = ChancesTemplate.Map2.Egg1
		},
		['Egg2'] = {
			['WinsCost'] = 85_000,
			['Chances'] = ChancesTemplate.Map2.Egg2
		}
	},
	['Map3'] = {
		['Egg1'] = {
			['WinsCost'] = 1_000_000,
			['Chances'] = ChancesTemplate.Map3.Egg1
		},
		['Egg2'] = {
			['WinsCost'] = 65_000_000,
			['Chances'] = ChancesTemplate.Map3.Egg2
		}
	}
}

return module