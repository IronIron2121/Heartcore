local GameStates = {
    Dressing = { 
        name = "Dressing", 
--        duration = 1/2 * 60, -- FINAL: 5 - 7 mins
        duration = 1 * 60, -- FINAL: 5 - 7 mins
        next = "Voting" 
    },
    Voting = { 
        name = "Voting", 
        --duration = 1 * 60, -- FINAL: 2 mins
        duration = 30,
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        duration = 0.1 * 60, -- Final: 90 secs
        next = "Dressing" 
    }, 
} 

return GameStates