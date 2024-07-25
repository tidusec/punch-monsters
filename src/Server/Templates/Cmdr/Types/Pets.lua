local PetsTemplate = require(game:GetService("ReplicatedStorage").Templates.PetsTemplate)
local PetNames = {}

for name, info in pairs(PetsTemplate) do
    table.insert(PetNames, name)
end

local petType = {
    DisplayName = "Pet",
	Transform = function (text)
		return tostring(text)
	end;

	Validate = function (value)
        if table.find(PetNames, value) then
            return true
        else
            return false, "Invalid pet name. Please choose from the template."
        end
    end;

    Autocomplete = function(text)
        local suggestions = {}
        for _, name in ipairs(PetNames) do
            if string.sub(name, 1, string.len(text)) == text then
                table.insert(suggestions, name)
            end
        end
        return suggestions
    end;

	Parse = function (value)
		return value
	end
}

return function (registry)
	registry:RegisterType("pet", petType)
end