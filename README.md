# SMM Learning NK Template (MATLAB)

This project implements the 7-step SMM workflow from your screenshots, with a MATLAB pipeline.

## Files
- `main.m`
- `matlab/config.m`
- `matlab/load_data.m`
- `matlab/moments_data.m`
- `matlab/moments_var1.m`
- `matlab/simulate_model.m`
- `matlab/policy_map_default.m`
- `matlab/reduced_form_default.m`
- `matlab/expectation_default.m`
- `matlab/simulate_shocks.m`
- `matlab/taylor_rule.m`
- `matlab/objective_smm.m`
- `matlab/estimate_smm.m`
- `matlab/standard_errors.m`
- `matlab/policy_coefficients.m`
- `matlab/moments_from_theta.m`
- `matlab/pack_params.m`
- `matlab/unpack_params.m`
- `matlab/vec.m`
- `matlab/vech.m`
- `matlab/fetch_fred_data.m`

## Expected data format
Create a CSV at `data/targets.csv` with headers:
- `date`
- `pi`
- `y`
- `r`

Only `pi`, `y`, and `r` are required. The `date` column is optional.

## Quick start
1. (Optional) Run `matlab/fetch_fred_data.m` to download data and build `data/targets.csv`.
2. Edit `matlab/config.m` to match your model, data, and moment selection.
3. Run `main.m`.

Results are saved to `results/smm_results.mat`.

## Notes
- The learning update is implemented in `matlab/simulate_model.m`.
- The default reduced form in `matlab/reduced_form_default.m` implements your Equation (11) row-by-row formulas.
- Policy coefficients are computed from Equation (10) in `matlab/policy_coefficients.m`.
- Default moments are `var1_xy_var_r`: VAR(1) on `(pi, y)` plus direct `Var(pi)`, `Var(y)`, `Var(r)`, and `Cov(pi,y)` to stabilize scale and comovement.
- Default shock structure: AR(1) for `d_t` and `v_t`, i.i.d. for `m_t^y` and `m_t^π` (set by fixed `rho_my = rho_mpi = 0`).
- Eq. (10) uses unconditional variances when AR(1) shocks are enabled (`cfg.policy.use_unconditional_variances = true`).
- Baseline keeps `k0` fixed via `cfg.learning.k0` (not estimated).
- `cfg.policy.phi_min`/`phi_max` and `cfg.learning.k_bounds` are safety clamps to avoid numerical blowups.
- The objective uses common random numbers by default (`cfg.sim.fix_rng = true`) for smoother optimization.
- A moment-fit report (CSV + PNG) plus series overlay and ACF plots are saved to `results/` each run.
- If you use `matlab/fetch_fred_data.m`, your inflation is already annualized and the policy rate is already an annual rate. Set `cfg.sample.annualize = false` to avoid multiplying by 4.
