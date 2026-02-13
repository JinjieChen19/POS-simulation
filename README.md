# POS-simulation

This repository contains Quarto documents for Predictive Probability of Success (PoS) presentations and a professional resume template.

## Files

### Presentation Documents
- `PoS_virtual_ICB_demo_v4.qmd` - Virtual ICB case study presentation with multiple output formats (Beamer PDF, RevealJS HTML, standard HTML)
- `PPOS or POS.qmd` - PoS presentation with PowerPoint and HTML output formats

### Resume Document
- `resume.qmd` - Professional resume/CV template in Quarto format
- `resume.css` - Custom CSS styling for the resume

## Rendering Documents

To render any of the Quarto documents, use the `quarto render` command:

```bash
# Render presentations
quarto render "PoS_virtual_ICB_demo_v4.qmd"
quarto render "PPOS or POS.qmd"

# Render resume
quarto render resume.qmd --to html    # HTML version
quarto render resume.qmd --to pdf     # PDF version
```

## Resume Format

The resume format includes:
- Clean, professional layout with custom CSS
- Sections for Professional Summary, Experience, Education, Skills, Publications, and Memberships
- Support for both HTML and PDF output formats
- Customizable styling via `resume.css`

### Customizing the Resume

Edit `resume.qmd` to add your personal information:
1. Replace placeholder text ([Email], [Organization], etc.) with your details
2. Add or remove sections as needed
3. Customize styling in `resume.css` if desired

## About PoS Simulations

The presentation documents cover:
- Bayesian PoS methodology for clinical trials
- Using PFS as a surrogate for OS prediction
- Bivariate random-effects models
- Sensitivity analyses for correlation and event counts
