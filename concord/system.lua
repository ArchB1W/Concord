--- Iterates over Entities. From these Entities its get Components and modify them.
-- A System contains 1 or more Pools.
-- A System is contained by 1 World.
-- @classmod System

local PATH = (...):gsub('%.[^%.]+$', '')

local Filter     = require(PATH..".filter")
local Utils      = require(PATH..".utils")

---@class ConcordSystem
local System = {
   ENABLE_OPTIMIZATION = true,
}

System.mt = {
   __index = System,
   __call  = function(systemClass, world)
      local system = setmetatable({
         __enabled = true,

         __filters = {},
         __world = world,

         __isSystem = true,
         __isSystemClass = false, -- Overwrite value from systemClass
      }, systemClass)

      -- Optimization: We deep copy the System class into our instance of a system.
      -- This grants slightly faster access times at the cost of memory.
      -- Since there (generally) won't be many instances of worlds this is a worthwhile tradeoff
      if (System.ENABLE_OPTIMIZATION) then
         Utils.shallowCopy(systemClass, system)
      end

      for name, def in pairs(systemClass.__definition) do
         local filter, pool = Filter(name, Utils.shallowCopy(def, {}))

         system[name] = pool
         table.insert(system.__filters, filter)
      end

      system:init(world)

      return system
   end,
}
--- Creates a new SystemClass.
---@param definition {string: string[]} A table containing filters like (name = {components...})
---@return ConcordSystem inst A new ConcordSystem
function System.new(definition)
   definition = definition or {}

   for name, def in pairs(definition) do
      if type(name) ~= 'string' then
         Utils.error(2, "invalid name for filter (string key expected, got %s)", type(name))
      end

      Filter.validate(0, name, def)
   end

   local systemClass = setmetatable({
      __definition = definition,
      __isSystemClass = true,
   }, System.mt)
   ---@diagnostic disable-next-line: inject-field
   systemClass.__index = systemClass


   -- Optimization: We deep copy the World class into our instance of a world.
   -- This grants slightly faster access times at the cost of memory.
   -- Since there (generally) won't be many instances of worlds this is a worthwhile tradeoff
   if (System.ENABLE_OPTIMIZATION) then
      Utils.shallowCopy(System, systemClass)
   end

   return systemClass
end

-- Internal: Evaluates an Entity for all the System's Pools.
---@param e ConcordEntity The Entity to check
---@return self self
function System:__evaluate(e)
   for _, filter in ipairs(self.__filters) do
      filter:evaluate(e)
   end

   return self
end

-- Internal: Removes an Entity from the System.
---@param e ConcordEntity The Entity to remove
---@return self self
function System:__remove(e)
   for _, filter in ipairs(self.__filters) do
      if filter:has(e) then
         filter:remove(e)
      end
   end

   return self
end

-- Internal: Clears all Entities from the System.
---@return self self
function System:__clear()
   for _, filter in ipairs(self.__filters) do
      filter:clear()
   end

   return self
end

--- Sets if the System is enabled
---@param enable boolean
---@return self self
function System:setEnabled(enable)
   if (not self.__enabled and enable) then
      self.__enabled = true
      self:onEnabled()
   elseif (self.__enabled and not enable) then
      self.__enabled = false
      self:onDisabled()
   end

   return self
end

---@return boolean # Whether the System is enabled
function System:isEnabled()
   return self.__enabled
end

---@return ConcordWorld # The World the System is in.
function System:getWorld()
   return self.__world
end

--- Callbacks
-- @section Callbacks

--- Callback for system initialization.
---@param world ConcordWorld The World the System was added to
---@return nil
---@diagnostic disable-next-line: unused-local
function System:init(world) -- luacheck: ignore
end

--- Callback for when a System is enabled.
---@return nil
function System:onEnabled() -- luacheck: ignore
end

--- Callback for when a System is disabled.
---@return nil
function System:onDisabled() -- luacheck: ignore
end

return setmetatable(System, {
   __call = function(_, ...)
      return System.new(...)
   end,
})
