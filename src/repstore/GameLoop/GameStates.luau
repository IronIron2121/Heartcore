local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 5 * 60, -- FINAL: 5 - 7 mins
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 3 * 60, -- FINAL: 2 mins
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 0.5 * 60, -- Final: 90 secs
        next = "Dressing" 
    },
}

return GameStates