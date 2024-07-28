--!native
--!strict
local module = {	
	-- Map1Egg 1
	
	["Dog"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 1.2,
	},
	["Cat"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 1.2,
	},
	["Bunny"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 1.3,
	},
	["Pink Bunny"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 1.5,
	},
	["Fox"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 1.6,
	},
	
	-- Map1 Egg 2
	
	["Bull"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 2.2,
	},
	["Cow"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 2.5,
	},
	["Chicken"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 3.2,
	},
	["Pig"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 4,
	},
	["Monkey"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 7,
	},
	["Lucky Cat"] = {
		ID = nil,
		Rarity = "Legendary",
		StrengthMultiplier = 15,
	},
	
	-- Map1 Egg 3 Robux
	
	["Crowned Dog"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 15,
	},
	["Crowned Cat"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 22,
	},
	["Crowned Bunny"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 28,
	},
	["Crowned Pink Bunny"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 40,
	},
	["Crowned Fox"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 75,
	},
	["Huge Dragon"] = {
		ID = nil,
		Rarity = "Legendary Huge",
		StrengthMultiplier = 450,
	},
	
	-- Map2 Egg 1
	
	["Capybara"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 5,
	},
	["Bear"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 8,
	},
	["Tiger"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 16,
	},
	["Elephant"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 28,
	},
	["Lion"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 40,
	},
	
	-- Map2 Egg 2
	
	["Walrus"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 45,
	},
	["Ram"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 55,
	},
	["Deer"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 68,
	},
	["Bee"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 82,
	},
	["Unicorn"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 175,
	},
	["Dragon"] = {
		ID = nil,
		Rarity = "Legendary",
		StrengthMultiplier = 300,
	},
	["Hydra"] = {
		ID = nil,
		Rarity = "Legendary Huge",
		StrengthMultiplier = 4575,
	},
	
	-- Map3 Egg 1
	
	["Crystal Dog"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 85,
	},
	["Crystal Cat"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 100,
	},
	["Crystal Bunny"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 118,
	},
	["Spider"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 125,
	},
	["Golem"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 140,
	},
	
	-- Map3 Egg 2
	
	["Flaming Dog"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 150,
	},
	["Flaming Cat"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 185,
	},
	["Flaming Rock"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 225,
	},
	["Bat"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 226,
	},
	["Flaming Scorpion"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 425,
	},	
	["Flaming Dragon"] = {
		ID = nil,
		Rarity = "Legendary",
		StrengthMultiplier = 1100,
	},	
	["Flaming Hydra"] = {
		ID = nil,
		Rarity = "Legendary Huge",
		StrengthMultiplier = 12000,
	},	

	-- Ice/Frostbite Robux Egg --
	["Panda"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 50,
	},

	["Lamb"] = {
		ID = nil,
		Rarity = "Uncommon",
		StrengthMultiplier = 80,
	},

	["Yeti"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 100,
	},

	["Icy Hedgehog"] = {
		ID = nil,
		Rarity = "Legendary",
		StrengthMultiplier = 150,
	},

	["Huge Snowman"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 12_000,
	},

	-- Store Pets --
	["Heart and Soul"] = {
		ID = nil,
		Rarity = "Common",
		StrengthMultiplier = 199,
	},

	["Mystic Golden Pot"] = {
		ID = nil,
		Rarity = "Rare",
		StrengthMultiplier = 850,
	},

	["Mystic Shattered Shard"] = {
		ID = nil,
		Rarity = "Epic",
		StrengthMultiplier = 1_700,
	},

	["Mystic Crystal Demon"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 6_500,
	},
	
	-- Robux Pets --
	["Mystical Pyra"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 1500,
	},
	
	["Mystic Reaper Heart"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 7000,
	},

	-- Robux Pets on Screen --
	["Mystic Lunar Guard"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 4000,
	},

	["Mystic Void Phoenix"] = {
		ID = nil,
		Rarity = "Huge",
		Limited = true,
		StrengthMultiplier = 499,
	},

	-- Mega Quest --
	["Magical Winged Wyvern"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 2000,
	},

	-- Reward from crates --
	["Mystic Blackhole Phoenix"] = {
		ID = nil,
		Rarity = "Huge",
		StrengthMultiplier = 350,
	},
}

local meta = {
    __index = function(self, key)
        local multiplier = 1
        local petname = key

        if string.find(petname, "Golden ") then 
            multiplier = multiplier * 2 
            petname = string.gsub(petname, "Golden ", "")
        end

        if string.find(petname, "Mythic ") then
            multiplier = multiplier * 3
            petname = string.gsub(petname, "Mythic ", "")
        end

        -- Avoid infinite recursion by checking if petname has been modified
        if petname == key or not self[petname] then
            return nil -- Base case: petname is not modified or doesn't exist
        end

        local pet = self[petname]
        
        if pet then
            local newPet = {
                ID = nil,
                Rarity = pet.Rarity,
                StrengthMultiplier = pet.StrengthMultiplier * multiplier,
            }
            self[key] = newPet
            return newPet
        end
    end
}
setmetatable(module, meta)

return module