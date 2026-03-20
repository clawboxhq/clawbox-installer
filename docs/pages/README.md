# GitHub Pages Deployment

This directory contains files for deploying ClawBox to GitHub Pages.

## Files

| File | Purpose |
|------|---------|
| `index.html` | Landing page for GitHub Pages |
| `CNAME` | Custom domain configuration (optional) |
| `docs.html` | Redirect to GitHub documentation |
| `robots.txt` | SEO configuration |
| `package.json` | Project metadata |

## Deployment

### Automatic Deployment

Push to `main` branch triggers automatic deployment via GitHub Actions.

### Manual Setup (One-time)

1. **Enable GitHub Pages**
   - Go to repo Settings → Pages
   - Set Source to "GitHub Actions"

## URLs

| URL | Description |
|-----|-------------|
| `https://clawboxhq.github.io/clawbox-installer` | Landing page |
| `https://clawboxhq.github.io/clawbox-installer/install.sh` | Install script |
| `https://clawboxhq.github.io/clawbox-installer/docs.html` | Documentation redirect |

## Install Commands

### GitHub Pages:
```bash
curl -fsSL https://clawboxhq.github.io/clawbox-installer/install.sh | bash
```

### Direct from GitHub:
```bash
curl -fsSL https://raw.githubusercontent.com/clawboxhq/clawbox-installer/main/install.sh | bash
```
