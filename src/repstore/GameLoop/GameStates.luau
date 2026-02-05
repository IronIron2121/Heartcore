local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 0.3 * 60, 
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 1 * 60, 
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 0.1 * 60, 
        next = "Dressing" 
    },
}

return GameStates