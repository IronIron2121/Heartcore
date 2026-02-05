local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 1 * 60, 
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 0.5 * 60, 
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 0.1 * 60, 
        next = "Dressing" 
    },
}

return GameStates