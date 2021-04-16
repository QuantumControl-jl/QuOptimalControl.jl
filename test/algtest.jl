
prob = StateTransferProblem(
    B = [SSx, SSy],
    A = SSz,
    X_init = ρinit,
    X_target = ρfin,
    duration = 1.0,
    n_timeslices = 10,
    n_controls = 2,
    initial_guess = rand(2, 10)
)

sol = GRAPE(prob, inplace=false)
