<!--
Sync Impact Report:
- Version change: 0.0.0 → 1.0.0 (initial creation)
- Added sections: Core Principles (5), Technical Standards, Governance
- Templates requiring updates: None (initial setup)
-->

# Weyermann Malt Product Page Constitution

## Core Principles

### I. Vanilla First
Use vanilla HTML, CSS, and JavaScript. No frameworks or build tools unless absolutely necessary. Every dependency MUST be justified.

### II. Responsive Design
All layouts MUST work on mobile (320px) to desktop (1920px). Mobile-first approach required. Test on real devices before merge.

### III. Performance
- Images MUST be optimized (WebP preferred, lazy loading required)
- Page load MUST be under 3 seconds on 3G
- No render-blocking resources

### IV. Accessibility
- WCAG 2.1 AA compliance required
- All images MUST have meaningful alt text
- Keyboard navigation MUST work
- Color contrast MUST pass automated checks

### V. Simplicity
- No premature abstractions
- Code MUST be readable without comments
- If it can be done with CSS, do not use JavaScript

## Technical Standards

**Stack**: HTML5, CSS3, Vanilla JavaScript
**Images**: WebP with JPG fallback, max 200KB per image
**Testing**: Manual browser testing (Chrome, Safari, Firefox)
**Hosting**: Static files only

## Governance

- Constitution changes require explicit user approval
- All PRs MUST pass accessibility and performance checks
- Follow safety rules in CLAUDE.md

**Version**: 1.0.0 | **Ratified**: 2025-11-30 | **Last Amended**: 2025-11-30
