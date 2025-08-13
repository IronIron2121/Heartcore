local Serialisation = {}

function Serialisation.serialiseVector(thisVector: Vector3)
	return {
		X = thisVector.X,
		Y = thisVector.Y,
		Z = thisVector.Z
	}
end

function Serialisation.unserialiseVector(thisTable: {X: number, Y: number, Z: number})
	return Vector3.new(thisTable.X, thisTable.Y, thisTable.Z)
end

function Serialisation.serialiseCFrame(thisCFrame: CFrame)
	return {thisCFrame:GetComponents()}
end

function Serialisation.unserialiseCFrame(serialisedCFrame: {number})
	return CFrame.new(unpack(serialisedCFrame))
end

function Serialisation.serialiseColor3 (thisVector: Color3)
	return {
		R = thisVector.R,
		G = thisVector.G,
		B = thisVector.B
	}
end

function Serialisation.serialiseAttributes(attributes: {})
	for attributeName, attributeValue in attributes do
		local attributeType = typeof(attributeValue)
		if attributeType == Vector3 then
			attributes[attributeName] = Serialisation.serialiseCFrame(attributeValue)			
		elseif  attributeType == Color3 then
			attributes[attributeName] = Serialisation.serialiseColor3(attributeValue)
		else
			attributes[attributeName] = attributeValue
		end
	end
	
	return attributes
end

function Serialisation.serialiseHumanoidDescription(Description:HumanoidDescription)
	local Result = {
		Properties = {
			Shirt = Description.Shirt,
			Pants = Description.Pants,
			Face = Description.Head,
			Torso = Description.Torso,
			RightLeg = Description.RightLeg,
			LeftLeg = Description.LeftLeg,
			LeftArm = Description.LeftArm,
			RightArm = Description.RightArm,
			Head = Description.Head,
			GraphicTShirt = Description.GraphicTShirt,
			BodyTypeScale = Description.BodyTypeScale,
			DepthScale = Description.DepthScale,
			HeadScale = Description.HeadScale,
			HeightScale = Description.HeightScale,
			ProportionScale = Description.ProportionScale,
			WidthScale = Description.WidthScale,
			BackAccessory = Description.BackAccessory,
			FaceAccessory = Description.FaceAccessory,
			FrontAccessory = Description.FrontAccessory,
			HairAccessory = Description.HairAccessory,
			HatAccessory = Description.HatAccessory,
			NeckAccessory = Description.NeckAccessory,
			ShouldersAccessory = Description.ShouldersAccessory,
			WaistAccessory = Description.WaistAccessory,
			-- ANIMATIONS --
			ClimbAnimation = Description.ClimbAnimation,
			FallAnimation = Description.FallAnimation,
			IdleAnimation = Description.IdleAnimation,
			JumpAnimation = Description.JumpAnimation,
			MoodAnimation = Description.MoodAnimation,
			RunAnimation = Description.RunAnimation,
			SwimAnimation = Description.SwimAnimation,
			WalkAnimation = Description.WalkAnimation,
		},
		Colors = {
			HeadColor = {Description.HeadColor.R,Description.HeadColor.G,Description.HeadColor.B},
			LeftArmColor = {Description.LeftArmColor.R,Description.LeftArmColor.G,Description.LeftArmColor.B},
			RightArmColor = {Description.RightArmColor.R,Description.RightArmColor.G,Description.RightArmColor.B},
			LeftLegColor = {Description.LeftLegColor.R,Description.LeftLegColor.G,Description.LeftLegColor.B},
			RightLegColor = {Description.RightLegColor.R,Description.RightLegColor.G,Description.RightLegColor.B},
			TorsoColor = {Description.TorsoColor.R,Description.TorsoColor.G,Description.TorsoColor.B},
		}
	}
	return Result
end

function Serialisation.deSerialiseHumanoidDescription(Serialized)
	local HumanoidDescription = Instance.new("HumanoidDescription")
	-- First Properties --
	for i,v in Serialized.Properties do
		if v ~= 0 then
			HumanoidDescription[i] = v
		end
	end
	-- Then Colors --
	for p,c in Serialized.Colors do
		HumanoidDescription[p] = Color3.new(c[1],c[2],c[3])
	end
	return HumanoidDescription
end

return Serialisation

