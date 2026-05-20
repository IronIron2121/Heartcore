local GameStates = {
    Dressing = { 
        name = "Dressing", 
--        duration = 1/2 * 60, -- FINAL: 5 - 7 mins
        duration = 5, -- FINAL: 5 - 7 mins
        next = "Time to vote!" 
    },
    Voting = { 
        name = "Voting", 
        --duration = 1 * 60, -- FINAL: 2 mins
        duration = 20,
        next = "Intermission" 
    },
    Intermission = { 
        name = "Intermission", 
        --duration = 1/2 * 60, -- Final: 90 secs
        duration = 10,
        next = "Time to dress!" 
    }, 
} 

return GameStates