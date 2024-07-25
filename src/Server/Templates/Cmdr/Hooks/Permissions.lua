local Groups = game:GetService("GroupService")

local function IsHighRankInGroup(userId)
	local UserGroups = Groups:GetGroupsAsync(userId)
	if not UserGroups then
		return false
	end

	for _, group in ipairs(UserGroups) do
		if group.Id == 34648035 then
			if group.Rank >= 254 then
				return true
			end
		end
	end
	return false
end

return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		if not IsHighRankInGroup(context.Executor.UserId) then
			return "You don't have permission to run this command"
		end
	end)
end