--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundService = Knit.CreateService {
  Name = "SoundService";
  Client = {
    SoundPlayed = Knit.CreateSignal()
  };
}

function SoundService:PlayFor(player: Player, soundName: string): nil
	return self.Client.SoundPlayed:Fire(player, soundName)
end

function SoundService.Client:Play(player: Player, soundName: string): nil
	return self.Server:PlayFor(player, soundName)
end

return SoundService