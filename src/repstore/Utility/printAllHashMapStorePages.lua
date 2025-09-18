local function printAllHashMapPages(hashPages: MemoryStoreHashMapPages)
	local currentPageNumber = 1

	while not hashPages.IsFinished do
		local page = hashPages:GetCurrentPage()
		print(#page)
		if #page > 0 then
			print(page)
		end
		hashPages:AdvanceToNextPageAsync()
		currentPageNumber += 1
	end

    print("End of pages!", hashPages.IsFinished)
end

return printAllHashMapPages