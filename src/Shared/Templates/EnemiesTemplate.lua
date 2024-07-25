--!native
--!strict
local module = {
	-- Map1
	
	Nerd = {
		Wins = 5,
		Strength = 500,
		Boss = false
	},
	Businessman = {
		Wins = 25,
		Strength = 4_500,
		Boss = false
	},
	Bodybuilder = {
		Wins = 80,
		Strength = 30_000,
		Boss = false
	},
	Hitman = {
		Wins = 200,
		Strength = 160_000,
		Boss = false
	},
	Powerlifter = {
		Wins = 550,
		Strength = 1_200_000,
		Boss = true,
		Map = 1,
	},
	
	-- Map2
	
	Mummy = {
		Wins = 1_000,
		Strength = 1_500_000,
		Boss = false
	},
	DesertExplorer = {
		Wins = 4_000,
		Strength = 5_000_000,
		Boss = false
	},
	DesertScout = {
		Wins = 15_000,
		Strength = 30_000_000,
		Boss = false
	},
	Soldier = {
		Wins = 45_000,
		Strength = 150_000_000,
		Boss = false
	},
	Pharaoh = {
		Wins = 300_000,
		Strength = 900_000_000,
		Boss = true,
		Map = 2,
	},
	
	-- Map3
	
	Zombie = {
		Wins = 450_000,
		Strength = 1_000_000_000,
		Boss = false
	},
	Golem = {
		Wins = 1_500_000,
		Strength = 5_000_000_000,
		Boss = false
	},
	Skeleton = {
		Wins = 5_000_000,
		Strength = 30_000_000_000,
		Boss = false
	},
	Reaper = {
		Wins = 25_000_000,
		Strength = 150_000_000_000,
		Boss = false
	},
	Demon = {
		Wins = 250_000_000,
		Strength = 1_000_000_000_000,
		Boss = true,
		Map = 3,
	},
}

return module
