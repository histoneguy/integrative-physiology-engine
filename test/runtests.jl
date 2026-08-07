using Test
using IPE

@testset "IPE walking skeleton" begin

    @testset "ledger provenance" begin
        # Every parameter must be traceable.
        @test !isempty(IPE.LedgerParams.PARAM_PROVENANCE)
        for (sym, p) in IPE.LedgerParams.PARAM_PROVENANCE
            @test !isempty(p.units)
            @test p.tier in ("A", "B", "C")
            @test p.method in ("reported", "digitized", "derived", "assumed", "calibrated")
            p.method == "assumed" && @test !isempty(p.notes)
        end
    end

    @testset "weak-basis parameters are visible" begin
        # Not a failure - a required disclosure. This list is the honest answer to
        # "how much of this model is actually known?"
        weak = IPE.LedgerParams.unledgered_check()
        @info "Parameters with weak basis (assumed or calibrated)" count=length(weak)
        for p in weak
            @info "  $(p.param_id) [$(p.method)]"
        end
        @test true
    end

    @testset "model builds and simplifies" begin
        sys = build_model()
        @test sys isa ModelingToolkit.AbstractSystem
    end

    @testset "conservation invariants" begin
        sys = build_model()
        sol = solve_individual(sys; tspan_days = 10.0, saveat = 1.0)
        @test SciMLBase.successful_retcode(sol)
        # TODO: assert mass/volume/solute balance to stated tolerance at every
        # saved point. This is a HARD assertion per validation/targets.md, not a
        # plot to eyeball.
    end

    @testset "solver agreement substitutes for external reference" begin
        sys = build_model()
        r = IPE.solver_agreement(sys; tspan_days = 10.0, saveat = 1.0)
        @test r.max_rel_deviation < 1e-4
    end

    @testset "qss reduction is cheaper and close" begin
        full = build_model(qss = false)
        red  = build_model(qss = true)
        s1 = solve_individual(full; tspan_days = 30.0)
        s2 = solve_individual(red;  tspan_days = 30.0)
        @test s2.stats.nf < s1.stats.nf   # fewer RHS evaluations
        # TODO: bound the disagreement on slow states once real subsystems land.
    end
end

@testset "coupling partition rules" begin
    couplings = [
        Coupling(:cv, :renal, Neurohumoral; tau_seconds = 3.0,
                 note = "sympathetic effector"),
        Coupling(:renal, :cv, Neurohumoral; tau_seconds = 3600.0,
                 note = "aldosterone tubular effect"),
        Coupling(:bodyfluids, :cv, Mechanical;
                 note = "blood volume -> venous return -> filling; hydraulic"),
    ]

    # Cutting a mechanical coupling must fail.
    @test_throws ErrorException validate_partition(
        couplings, Dict(:cv => :fast, :renal => :slow, :bodyfluids => :slow);
        boundary_seconds = 60.0)

    # Keeping mechanically-coupled subsystems together must pass.
    r = validate_partition(
        couplings, Dict(:cv => :fast, :bodyfluids => :fast, :renal => :slow);
        boundary_seconds = 60.0)
    @test r.ok

    # Contradictory constructions are rejected at construction time.
    @test_throws ErrorException Coupling(:a, :b, Neurohumoral)
    @test_throws ErrorException Coupling(:a, :b, Mechanical; tau_seconds = 1.0)
end
