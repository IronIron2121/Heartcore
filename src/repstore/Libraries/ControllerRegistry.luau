--!strict
-- ControllerRegistry.lua

local ControllerRegistry = {}

local controllers: {[string]: any} = {}
local isInitialized = false

function ControllerRegistry.register(name: string, controller: any)
	assert(not isInitialized, "Cannot register controllers after initialization")
	assert(not controllers[name], `Controller '{name}' already registered`)
	controllers[name] = controller
end

function ControllerRegistry.get(name: string): any
	assert(isInitialized, "Controllers not yet initialized - call ControllerRegistry.setInitialized() first")
	local controller = controllers[name]
	assert(controller, `Controller '{name}' not found in registry`)
	return controller
end

function ControllerRegistry.tryGet(name: string): any?
	if not isInitialized then
		return nil
	end
	return controllers[name]
end

function ControllerRegistry.setInitialized()
	isInitialized = true
end

function ControllerRegistry.has(name: string): boolean
	return controllers[name] ~= nil
end

function ControllerRegistry.getRegisteredNames(): {string}
	local names = {}
	for name in controllers do
		table.insert(names, name)
	end
	return names
end

return ControllerRegistry