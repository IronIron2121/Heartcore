--!strict

local accessoryDescriptionProperties = {
	"AccessoryType",
	"AssetId",
	-- "Instance",
	"IsLayered",
	"Order",
	"Position",
	"Puffiness",
	"Rotation",
	"Scale"
}


local bodyPartDescriptionProperties = {
	"AssetId",
	"BodyPart",
	"Color",
	-- "Instance"
}

local SerialisationService = {}

function SerialisationService.serialiseVector3(thisVector: Vector3): {[string] : number}
	return {
		X = thisVector.X,
		Y = thisVector.Y,
		Z = thisVector.Z
	}
end

function SerialisationService.unserialiseVector3(serialisedVector: {X: number, Y: number, Z: number})
	return Vector3.new(serialisedVector.X, serialisedVector.Y, serialisedVector.Z)
end

function SerialisationService.serialiseColor3(color3: Color3): {[string] : number}
	return {
		R = color3.R,
		G = color3.G,
		B = color3.B
	}
end

function SerialisationService.unserialiseColor3(serialisedColor3: {R: number, G: number, B: number}): Color3
	return Color3.new(serialisedColor3.R, serialisedColor3.G, serialisedColor3.B)
end

function SerialisationService.SerialiseAccessoryDescription(accessoryDescription: AccessoryDescription) : {any}
	
	local serialisedAccessoryDescription = {}

	for _, property in ipairs(accessoryDescriptionProperties) do
		local value = accessoryDescription[property]
		
		if value == nil then
			continue
		end
		
		if property == "AccessoryType" then
			serialisedAccessoryDescription[property] = value.Value
		elseif property == "Position" or property == "Vector" or property == "Scale" or property == "Rotation" then
			serialisedAccessoryDescription[property] = SerialisationService.serialiseVector3(value)
		else
			serialisedAccessoryDescription[property] = value
		end
	end
	
	return serialisedAccessoryDescription
end

function SerialisationService.UnserialiseAccessoryDescription(serialiseAccessoryDescription: {[string] : any})
	local accessoryDescription = Instance.new("AccessoryDescription")
	
	for property, value in pairs(serialiseAccessoryDescription) do
		if property == "AccessoryType" then
			accessoryDescription[property] = Enum.AccessoryType[value]
		elseif property == "Position" or property == "Vector" or property == "Scale" or property == "Rotation" then
			accessoryDescription[property] = SerialisationService.unserialiseVector3(value)
		else
			accessoryDescription[property] = value
		end
	end
	
	return accessoryDescription
end

function SerialisationService.SerialiseBodyPartDescription(bodyPartDescription: BodyPartDescription) : any
	local serialisedBodyPartDescription = {}
	
	for _, property in ipairs(bodyPartDescriptionProperties) do
		if property == "Color" then
			serialisedBodyPartDescription[property] = SerialisationService.serialiseColor3(bodyPartDescription[property])
		elseif property == "BodyPart" then
			serialisedBodyPartDescription[property] = bodyPartDescription[property].Value
		else
			serialisedBodyPartDescription[property] = bodyPartDescription[property]
		end
	end
	
	return serialisedBodyPartDescription
end

function SerialisationService.UnserialiseBodyPartDescription(serialisedBodyPartDescription: {[string] : any})
	local bodyPartDescription = Instance.new("BodyPartDescription")
	
	for property, value in pairs(serialisedBodyPartDescription) do
		if property == "BodyPart" then
			bodyPartDescription[property] = Enum.BodyPart[value]
		elseif property == "Color" then
			bodyPartDescription[property] = SerialisationService.unserialiseColor3(value)
		else
			bodyPartDescription[property] = value
		end
	end
	
	return bodyPartDescription
end

function SerialisationService.SerialiseHumanoidDescription(humanoidDescription: HumanoidDescription) : {any}
	
	local serialisedHumanoidDescription = {}
	
	for _, description in ipairs(humanoidDescription:GetChildren()) do
		
		if description:IsA("AccessoryDescription") then
			serialisedHumanoidDescription[description.AssetId] = SerialisationService.SerialiseAccessoryDescription(description)
			
		elseif description:IsA("BodyPartDescription") then
			serialisedHumanoidDescription[description.AssetId] = SerialisationService.SerialiseBodyPartDescription(description)
			
		end
	end
		
	return serialisedHumanoidDescription
end

function SerialisationService.UnserialiseHumanoidDescription(serialisedHumanoidDescription: {[string] : any}) : HumanoidDescription
	local humanoidDescription = Instance.new("HumanoidDescription")
	
	for assetId, description in pairs(serialisedHumanoidDescription) do
		-- TODO: This deserves a better variable name...unfortunately time is of the essence right now
		local newDescription = description.BodyPart and Instance.new("BodyPartDescription") or Instance.new("AccessoryDescription")

		for property, value in pairs(description) do
			if property == "Color" then
				newDescription[property] = SerialisationService.unserialiseColor3(value)
			elseif property == "Position" or property == "Vector" or property == "Scale" or property == "Rotation" then
				newDescription[property] = SerialisationService.unserialiseVector3(value)
			elseif property == "AccessoryType" then
				newDescription[property] = Enum.AccessoryType:FromValue(value)
			elseif property == "BodyPart" then
				newDescription[property] = Enum.BodyPart:FromValue(value)
			else
				newDescription[property] = value
			end
		end
		newDescription.Parent = humanoidDescription
	end
	
	return humanoidDescription
end

return SerialisationService