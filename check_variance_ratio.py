# Check the variance decomposition

# Between-trial SDs (population heterogeneity)
sd_os_between = 0.046
sd_pfs_between = 0.053

# Within-trial SEs (measurement uncertainty)
se_os_within_min = 0.16
se_os_within_max = 0.22
se_pfs_within_min = 0.12
se_pfs_within_max = 0.18

print("Variance Decomposition Analysis")
print("=" * 60)
print()
print("Between-trial (population heterogeneity):")
print(f"  SD_OS: {sd_os_between}")
print(f"  SD_PFS: {sd_pfs_between}")
print()
print("Within-trial (measurement uncertainty):")
print(f"  SE_OS: {se_os_within_min} to {se_os_within_max}")
print(f"  SE_PFS: {se_pfs_within_min} to {se_pfs_within_max}")
print()
print("Ratio of within/between (higher = harder to learn between-trial correlation):")
print(f"  OS: {se_os_within_min/sd_os_between:.1f} to {se_os_within_max/sd_os_between:.1f}")
print(f"  PFS: {se_pfs_within_min/sd_pfs_between:.1f} to {se_pfs_within_max/sd_pfs_between:.1f}")
print()
print("Interpretation:")
print("  Ratio > 1: Within-trial noise larger than between-trial signal")
print("  Ratio 3-4: Very difficult to estimate between-trial correlation")
print("  Ratio > 5: Nearly impossible to distinguish correlation from noise")
print()
print("The high within-trial SEs are drowning out the between-trial signal!")
print("This explains why rho ≈ 0.14 despite data correlation ≈ 0.60")
