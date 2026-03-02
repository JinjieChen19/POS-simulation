import numpy as np

# Set seed to match R
np.random.seed(20260211)

# Parameters from app.R
n_trials = 27
mu_os = -0.30
mu_pfs = -0.45
sd_os = 0.046
sd_pfs = 0.053
target_cor = 0.65

# Create covariance matrix in [OS, PFS] order
cov_matrix = np.array([
    [sd_os**2, target_cor * sd_os * sd_pfs],
    [target_cor * sd_os * sd_pfs, sd_pfs**2]
])

print("Covariance matrix (OS, PFS order):")
print(cov_matrix)
print()

# Cholesky decomposition
L = np.linalg.cholesky(cov_matrix)
print("Cholesky decomposition (lower triangular):")
print(L)
print()

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

# Apply clipping
loghr_pfs_clipped = np.clip(loghr_pfs, -0.60, -0.30)
loghr_os_clipped = np.clip(loghr_os, -0.45, -0.15)

print("After clipping:")
print(f"OS: mean={loghr_os_clipped.mean():.4f}, sd={loghr_os_clipped.std():.4f}")
print(f"PFS: mean={loghr_pfs_clipped.mean():.4f}, sd={loghr_pfs_clipped.std():.4f}")
print(f"Correlation: {np.corrcoef(loghr_os_clipped, loghr_pfs_clipped)[0,1]:.4f}")
print()

# Check which values were clipped
pfs_clipped_count = np.sum((loghr_pfs < -0.60) | (loghr_pfs > -0.30))
os_clipped_count = np.sum((loghr_os < -0.45) | (loghr_os > -0.15))
print(f"Values clipped - PFS: {pfs_clipped_count}/{n_trials}, OS: {os_clipped_count}/{n_trials}")
