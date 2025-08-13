local highlight = script.Highlight
local defaultWait = 5

function HighlightPart(part: BasePart, duration: number?)
	duration = duration or defaultWait
	highlight.Adornee = part
	task.wait(duration)
	highlight.Adornee = nil
end

return HighlightPart
