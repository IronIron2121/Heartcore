local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 1 * 45, 
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 1 * 60, 
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 1 * 10, 
        next = "Dressing" 
    },
}

return GameStates