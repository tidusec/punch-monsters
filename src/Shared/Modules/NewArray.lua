local Array = {}
Array.CheckableTypes = {
    "string",
    "number",
    "boolean",
    "table",
    "function",
    "userdata",
    "thread",
    "vector",
    "any",
    "unknown",
}


function Array.new(Type, Values)
    if not Values then
        Values = {}
    end
    if type(Values) ~= "table" then
        Values = {Values}
    end
    if not table.find(Array.CheckableTypes, Type) then
        Type = nil
    end
    local self = setmetatable({
        Type = Type,
        Values = Values,
    }, {
        __index = Array,
    })
    return self
end

function Array:CheckType(value)
    if self.Type == nil then
        return true
    end
    for _, checkType in ipairs(Array.CheckableTypes) do
        if self.Type == checkType then
            return typeof(value) == checkType
        end
    end
    return value:IsA(self.Type)
end

function Array:First()
    return self.Values[1]
end

function Array:Last()
    return self.Values[#self.Values]
end

function Array:Index(index)
    return self.Values[index]
end

function Array:Filter(callback)
    local newValues = {}
    for _, value in ipairs(self.Values) do
        if callback(value) then
            table.insert(newValues, value)
        end
    end
    self.Values = newValues
    return self
end

function Array:GetValues()
    return self.Values
end

function Array:AddValues(values)
    for _, value in ipairs(values) do
        if self.Type and value:IsA(self.Type) == false then
            warn("Value is not of type " .. self.Type .. ": " .. tostring(value))
            continue
        end
        table.insert(self.Values, value)
    end
    return self
end

function Array:Add(value)
    table.insert(self.Values, value)
    return self
end

function Array:Remove(index)
    table.remove(self.Values, index)
    return self
end

function Array:Has(value)
    for _, v in ipairs(self.Values) do
        if v == value then
            return true
        end
    end
    return false
end

function Array:Find(callback)
    for _, value in ipairs(self.Values) do
        if callback(value) then
            return value
        end
    end
    return nil
end

function Array:Combine(array)
    for _, value in ipairs(array:GetValues()) do
        table.insert(self.Values, value)
    end
    return self
end

function Array:Amount()
    return #self.Values
end

function Array:Sum()
    local sum = 0
    for _, value in ipairs(self.Values) do
        sum += value
    end
    return sum
end

function Array:Average()
    return self:Sum() / self:Amount()
end

function Array:GeometricMean()
    local product = 1
    for _, value in ipairs(self.Values) do
        product *= value
    end
    return product ^ (1 / self:Amount())
end

function Array:Max()
    local max = 0
    for _, value in ipairs(self.Values) do
        if value > max then
            max = value
        end
    end
    return max
end

function Array:Min()
    local min = math.huge
    for _, value in ipairs(self.Values) do
        if value < min then
            min = value
        end
    end
    return min
end

function Array:Sort(sortfunction)
    local newValues = self.Values
    table.sort(newValues, sortfunction)
    self.Values = newValues
    return self
end

function Array:Push(value)
    self:Add(value)
    return self
end

function Array:Pop()
    return table.remove(self.Values)
end

function Array:Shift()
    return table.remove(self.Values, 1)
end

function Array:Unshift(value)
    table.insert(self.Values, 1, value)
    return self
end

function Array:Truncate(amount)
    for i = 1, amount do
        table.remove(self.Values)
    end
    return self
end

function Array:Some(callback)
    for _, value in ipairs(self.Values) do
        if callback(value) then
            return true
        end
    end
    return false
end

function Array:ForEach(callback)
    for _, value in ipairs(self.Values) do
        callback(value)
    end
    return self
end

function Array:FindAndRemove(callback)
    for i, value in ipairs(self.Values) do
        if callback(value) then
            table.remove(self.Values, i)
            return value
        end
    end
    return nil
end

function Array:RemoveValue(value)
    for i, v in ipairs(self.Values) do
        if v == value then
            table.remove(self.Values, i)
        end
    end
    return self
end

return Array