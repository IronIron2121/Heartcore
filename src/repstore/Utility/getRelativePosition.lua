function getRelativePosition(referenceCFrame: CFrame, relativeCFrame: CFrame): CFrame
	return referenceCFrame:ToObjectSpace(relativeCFrame)
end

return getRelativePosition