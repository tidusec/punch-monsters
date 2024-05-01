--!native
--!strict
local module = {
	-- Map1
	
	Nerd = {
		Wins = 1,
		Strength = 100,
		Boss = false
	},
	Businessman = {
		Wins = 25,
		Strength = 1200,
		Boss = false
	},
	Bodybuilder = {
		Wins = 75,
		Strength = 8700,
		Boss = false
	},
	Hitman = {
		Wins = 150,
		Strength = 18000,
		Boss = false
	},
	Powerlifter = {
		Wins = 300,
		Strength = 45000,
		Boss = true,
		Map = 1,
	},
	
	-- Map2
	
	Mummy = {
		Wins = 2000,
		Strength = 380000,
		Boss = false
	},
	DesertExplorer = {
		Wins = 10000,
		Strength = 640000,
		Boss = false
	},
	DesertScout = {
		Wins = 22000,
		Strength = 11000000,
		Boss = false
	},
	Soldier = {
		Wins = 50000,
		Strength = 45000000,
		Boss = false
	},
	Pharaoh = {
		Wins = 225000,
		Strength = 120000000,
		Boss = true,
		Map = 2,
	},
	
	-- Map3
	
	Zombie = {
		Wins = 4500000,
		Strength = 400000000,
		Boss = false
	},
	Golem = {
		Wins = 35000000,
		Strength = 1200000000,
		Boss = false
	},
	Skeleton = {
		Wins = 115000000,
		Strength = 8100000000,
		Boss = false
	},
	Reaper = {
		Wins = 375000000,
		Strength = 25000000000,
		Boss = false
	},
	Demon = {
		Wins = 1800000000,
		Strength = 92000000000,
		Boss = false,
		Map = 3,
	},
}

return module
