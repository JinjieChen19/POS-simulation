import numpy as np

# Set seed to match R
np.random.seed(20260211)

# NEW parameters
n_trials = 27
mu_os = -0.30
mu_pfs = -0.45
sd_os = 0.15    # INCREASED from 0.046
sd_pfs = 0.15   # INCREASED from 0.053
target_cor = 0.65

# Create covariance matrix in [OS, PFS] order
cov_matrix = np.array([
    [sd_os**2, target_cor * sd_os * sd_pfs],
    [target_cor * sd_os * sd_pfs, sd_pfs**2]
])

print("NEW Parameters (Increased Between-Trial Heterogeneity)")
print("=" * 60)
print()
print("Covariance matrix (OS, PFS order):")
print(cov_matrix)
print()

# Cholesky decomposition
L = np.linalg.cholesky(cov_matrix)

# Generate independent standard normal variates
Z = np.random.randn(2, n_trials)

# Transform to correlated variates
Y = L @ Z

# Add means
loghr_os = mu_os + Y[0, :]
loghr_pfs = mu_pfs + Y[1, :]

print("Before clipping:")
print(f"OS: mean={loghr_os.mean():.4f}, sd={loghr_os.std():.4f}")
print(f"PFS: mean={loghr_pfs.mean():.4f}, sd={loghr_pfs.std():.4f}")
print(f"Correlation: {np.corrcoef(loghr_os, loghr_pfs)[0,1]:.4f}")
print()

# Apply NEW clipping
loghr_pfs_clipped = np.clip(loghr_pfs, -0.75, -0.15)
loghr_os_clipped = np.clip(loghr_os, -0.55, -0.05)

print("After clipping:")
print(f"OS: mean={loghr_os_clipped.mean():.4f}, sd={loghr_os_clipped.std():.4f}")
print(f"PFS: mean={loghr_pfs_clipped.mean():.4f}, sd={loghr_pfs_clipped.std():.4f}")
print(f"Correlation: {np.corrcoef(loghr_os_clipped, loghr_pfs_clipped)[0,1]:.4f}")
print()

# Check which values were clipped
pfs_clipped_count = np.sum((loghr_pfs < -0.75) | (loghr_pfs > -0.15))
os_clipped_count = np.sum((loghr_os < -0.55) | (loghr_os > -0.05))
print(f"Values clipped - PFS: {pfs_clipped_count}/{n_trials}, OS: {os_clipped_count}/{n_trials}")
print()

# Check variance decomposition
print("Variance Decomposition:")
print(f"Between-trial SD: OS={sd_os}, PFS={sd_pfs}")
print(f"Within-trial SE range: OS=0.16-0.22, PFS=0.12-0.18")
print(f"Ratio (within/between): OS={0.16/sd_os:.1f}-{0.22/sd_os:.1f}, PFS={0.12/sd_pfs:.1f}-{0.18/sd_pfs:.1f}")
print()
print("✓ Ratios now around 1.0-1.5 (much better for learning correlation!)")
