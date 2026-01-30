local GameStates = {
    Dressing = { 
        name = "Dressing", 
        duration = 7 * 1, 
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        duration = 1 * 7, 
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 1 * 3, 
        next = "Dressing" 
    },
}

return GameStates