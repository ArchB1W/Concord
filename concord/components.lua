--- Container for registered ComponentClasses
-- @module Components

---@class ConcordComponents
local Components = {}

Components.__REJECT_PREFIX = "!"
Components.__REJECT_MATCH = "^(%"..Components.__REJECT_PREFIX.."?)(.+)"

--- Returns true if the containter has the ComponentClass with the specified name
-- @string name Name of the ComponentClass to check
-- @treturn boolean
function Components.has(name)
   return rawget(Components, name) and true or false
end

--- Prefix a component's name with the currently set Reject Prefix
-- @string name Name of the ComponentClass to reject
-- @treturn string
function Components.reject(name)
   local ok, err = Components.try(name)

   if not ok then error(err, 2) end

   return Components.__REJECT_PREFIX..name
end

--- Returns true and the ComponentClass if one was registered with the specified name
-- or false and an error otherwise
---@param name string Name of the ComponentClass to check
---@param acceptRejected boolean? Whether to accept names prefixed with the Reject Prefix.
---@return boolean
---@return ConcordComponent | string # Component or error string
---@return boolean? # If acceptRejected was true and the name had the Reject Prefix, false otherwise.
function Components.try(name, acceptRejected)
   if type(name) ~= "string" then
      return false, "ComponentsClass name is expected to be a string, got "..type(name)..")"
   end

   local rejected = false
   if acceptRejected then
      local prefix
      prefix, name = string.match(name, Components.__REJECT_MATCH)

      rejected = prefix ~= "" and name
   end

   local value = rawget(Components, name)
   if not value then
      return false, "ComponentClass '"..name.."' does not exist / was not registered"
   end

   return true, value, rejected
end

--- Returns the component with the specified name
---@param name string Name of the ComponentClass to get
---@return ConcordComponent
function Components.get(name)
   local ok, value = Components.try(name)

   if not ok then error(value, 2) end

   -- If the try call is `not ok` the second return is always an error string so we can ignore this diagnostic
   ---@diagnostic disable-next-line: return-type-mismatch
   return value
end

return setmetatable(Components, {
    --- Returns the component with the specified name
    ---@param name string Name of the ComponentClass to get
    ---@return ConcordComponent
    __index = function(_, name)
        Components.get(name)
    end
})
