--!strict

-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Workspace
local cinema = Workspace:WaitForChild("cinema")
local ParallaxPortal = cinema:WaitForChild("ParallaxPortal")
local InstancesF = ParallaxPortal:WaitForChild("Instances")
local portal1 = InstancesF:WaitForChild("Portal")
local portal = portal1:WaitForChild("Portal")
local portalGui1 = portal.PortalGui
local portalGui = portalGui1:WaitForChild("Portal")

type LayerInfo = { position: UDim2, depth: number }

local layers: { [GuiObject]: LayerInfo } = {}

local function addLayer(layer: any)
	if not layer:IsA("GuiObject") then
		return
	end

	layers[layer] = {
		position = layer.Position,
		depth = layer:GetAttribute("ParallaxDepth") or 0,
	}
end

local function update()
	local camera = Workspace.CurrentCamera :: Camera

	local portalRatio = portal.Size.Y / portal.Size.X
	local cameraDirection = (portal.Position - camera.CFrame.Position).Unit
	local portalDirection = portal.CFrame:VectorToObjectSpace(cameraDirection)
	local correctedDirection = Vector3.new(portalDirection.X, portalDirection.Y / portalRatio, 0)

	for layer, info in layers do
		local offset = UDim2.fromScale(correctedDirection.X * info.depth, correctedDirection.Y * info.depth)
		layer.Position = info.position + offset
	end
end

local function initialize()
	portalGui.ChildAdded:Connect(addLayer)
	RunService.RenderStepped:Connect(update)

	for _, layer in portalGui:GetChildren() do
		addLayer(layer)
	end
end

initialize()
