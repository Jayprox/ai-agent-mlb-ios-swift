# Production Issues Tracker — Chalk That v1.0

**Updated:** 2026-06-24  
**Status:** Live (App in review, then live on App Store)

This document captures issues reported by users during v1.0 production usage.  
Issues are prioritized and scheduled for v1.1 or later releases.

---

## Format

| Date | Issue | Component | Severity | Reporter | Notes | Status |
|------|-------|-----------|----------|----------|-------|--------|
| YYYY-MM-DD | Short description | View/Feature | Critical/High/Medium/Low | User/Source | Additional context | Open/Investigating/Fixing/Fixed |

---

## Open Issues

*(None yet — first issues will appear as users report during v1.0 production usage)*

---

## Investigating

*(Issues under investigation)*

---

## In Progress (Fixing)

*(Issues being worked on for upcoming patch)*

---

## Fixed (v1.0.x patches)

*(Critical/High issues patched in post-launch updates)*

---

## Scheduled for v1.1

*(Medium/Low issues bundled into next release with iPad optimization)*

---

## Notes

- **Critical:** App crash, data loss, authentication failure → patch immediately
- **High:** Feature broken, major UX issue → v1.0.1 patch or v1.1
- **Medium:** Minor bug, unexpected behavior → v1.1 bundle
- **Low:** Polish, edge case, cosmetic → v1.1 or later

### Triage Process
1. User reports issue
2. Add to "Open Issues" table above with date, component, severity
3. Investigate (move to "Investigating")
4. If critical → create hotfix branch
5. If medium/low → schedule for v1.1
6. Once fixed → move to "Fixed" or "Scheduled for v1.1"

---

## Known Limitations (Not Bugs)

- **iPad support:** Deferred to v1.1 (not a bug, intentional design decision)
- **Landscape mode:** Not supported in v1.0 (portrait only)
- **Multitasking:** Not tested in split-screen (iPad v1.1+)

