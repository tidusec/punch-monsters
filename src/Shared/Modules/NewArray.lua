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

local function stringify(arr)
    return arr:Map(function(element)
        if type(element) == "table" and element.__type == "Array" then
            return stringify(element)
        else
            return tostring(element)
        end
    end):ToString()
end

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
        __newindex = function(array, i, v)
            if array:CheckType(v) then
                array.Values[i] = v
            end
        end,
        __len = function(array)
            return #array.Values
        end,
        __tostring = function(array)
            return stringify(array)
        end,
        __type = "Array",
    })
    return self
end

function Array:CheckType(value)
    if self.Type == nil then
        return true
    end
    for _, checkType in ipairs(Array.CheckableTypes) do
        if self.Type == checkType then
            return type(value) == checkType
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
        if not self:CheckType(value) then
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
        sum = sum + value
    end
    return sum
end

function Array:Average()
    return self:Sum() / self:Amount()
end

function Array:GeometricMean()
    local product = 1
    for _, value in ipairs(self.Values) do
        product = product * value
    end
    return product ^ (1 / self:Amount())
end

function Array:Max()
    local max = -math.huge
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
    table.sort(self.Values, sortfunction)
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

function valuesEqual(v1, v2)
    if type(v1) == "table" and type(v2) == "table" then
        return tablesEqual(v1, v2)
    else
        return v1 == v2
    end
end

function tablesEqual(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end
    local t1Keys, t2Keys = {}, {}
    for k, v in pairs(t1) do
        t1Keys[k] = true
        if not valuesEqual(v, t2[k]) then
            return false
        end
    end
    for k, v in pairs(t2) do
        t2Keys[k] = true
        if not valuesEqual(v, t1[k]) then
            return false
        end
    end
    for k in pairs(t1Keys) do
        if not t2Keys[k] then
            return false
        end
    end
    for k in pairs(t2Keys) do
        if not t1Keys[k] then
            return false
        end
    end
    return true
end

function Array:RemoveValue(value)
    local i = 1
    while i <= #self.Values do
        local v = self.Values[i]
        if valuesEqual(v, value) then
            table.remove(self.Values, i)
            return self
        else
            i = i + 1
        end
    end
    return self
end

function Array:Map(callback)
    local newValues = {}
    for _, value in ipairs(self.Values) do
        table.insert(newValues, callback(value))
    end
    self.Values = newValues
    return self
end

function Array:ToTable()
    return self.Values
end

function Array:ToString()
    return table.concat(self.Values, ", ")
end

return Array
