local Tween = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

function Tween.new(instance: Instance, properties: { [string]: any }, duration: number, easingStyle: Enum.EasingStyle, easingDirection: Enum.EasingDirection): Tween
    local self = setmetatable({}, { __index = Tween })
    self.Instance = instance
    self.Properties = properties
    self.Duration = duration
    self.EasingStyle = easingStyle
    self.EasingDirection = easingDirection
    self._tween = TweenService:Create(self.Instance, TweenInfo.new(self.Duration, self.EasingStyle, self.EasingDirection), self.Properties)
    self._tween:Play()
    self._tween.Completed:Connect(function()
        task.wait(3)
        self._tween:Destroy()
    end)
    return self
end

return Tween