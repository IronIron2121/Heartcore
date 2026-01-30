local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 1 * 60, 
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 1 * 30, 
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 1 * 5, 
        next = "Dressing" 
    },
}

return GameStates