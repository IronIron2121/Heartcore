function getPlayerPos(plr: Player): Vector3?
	if not plr then return nil end
	
	return plr.Character and plr.Character:GetPivot().Position
end 

return getPlayerPos
