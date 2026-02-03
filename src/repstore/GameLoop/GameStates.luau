local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 1 * 20, 
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 1 * 10, 
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 1 * 10, 
        next = "Dressing" 
    },
}

return GameStates