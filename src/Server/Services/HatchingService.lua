--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local HatchingService = Knit.CreateService {
  Name = "HatchingService";
  Client = {
    Hatched = Knit.CreateSignal()
  };
}

function HatchingService:Hatch(player: Player, times: number): nil
	return self.Client.Hatched:Fire(player, times)
end

return HatchingService