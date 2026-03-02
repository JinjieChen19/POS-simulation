# Precompiled Stan Model

## About This File

This directory should contain `stan_model_compiled.rds` - a precompiled version of the Stan model that eliminates compilation wait times for users.

## How to Generate

Run from the package root:

```bash
Rscript tools/precompile_stan_model.R
```

This will:
1. Compile `stan_universal_model_optimized.stan`
2. Save the compiled model as `stan_model_compiled.rds`
3. Take 1-2 minutes (one time only)

## Benefits

- **Instant startup:** Loading .rds takes < 1 second vs 60-120 second compilation
- **Better UX:** Users don't wait for compilation
- **Same functionality:** Model still accepts all priors and parameters as data

## File Not Included in Git

The `stan_model_compiled.rds` file may be excluded from git due to its size (~1-3 MB) and platform-specific nature. Package maintainers should:

1. Generate it before building/releasing the package
2. Include it in package builds
3. Document how to regenerate if needed

## When to Regenerate

Only when the Stan model code changes:
- `stan_universal_model_optimized.stan` is modified
- Stan version is significantly updated

You do NOT need to regenerate when:
- Priors change (passed as data)
- UI/app logic changes
- Sampling parameters change
