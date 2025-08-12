--[[
	This function returns the highest level in a chain of models
]]

function getTopLevelModel(model: Model): Model
	if not model then return end
	if model.Parent then
		while model.Parent:IsA("Model") do
			model = model.Parent
		end
	end
	return model	
end

return getTopLevelModel