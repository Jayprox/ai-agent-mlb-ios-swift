# Board View Tab Accessibility — v1.2 Improvement

## Issue
The market tabs (HR, Hits, K, Outs, Games) in the Board view are too small and closely spaced, making them difficult to tap on mobile devices.

## Target Improvements

### Current State
- Tab buttons are approximately 30pt height
- Small padding around labels
- Tight spacing between tabs
- Font size ~10-11pt

### Desired State (v1.2)
1. **Minimum Touch Target**: Increase to 44×44pt (Apple HIG standard)
2. **Button Height**: Increase from ~30pt to 44pt minimum
3. **Padding**: Add more horizontal/vertical padding around labels
4. **Font Size**: Increase from ~10pt to 12pt for better readability
5. **Spacing**: Increase gap between tabs for better visual separation

### Implementation Details

**Location**: BoardView.swift (or where board market tabs are defined)

**Changes needed:**
- Update tab button frame height to `.frame(minHeight: 44)`
- Increase padding: `.padding(.horizontal, 12)` and `.padding(.vertical, 8)`
- Use `.scaledFont(size: 12)` or larger
- Increase spacing in HStack: `spacing: 12` (from likely current `spacing: 8`)
- Consider wrapping to 2 rows if space is constrained (HR/Hits on row 1, K/Outs/Games on row 2)

### Testing
- Test on iPhone SE (smallest screen)
- Test on iPad (ensure tabs don't become too large)
- Verify no overflow or truncation
- Test with VoiceOver to ensure accessibility

## Priority
Medium — improves usability but not a blocker for v1.2 release

## Status
Ready to implement — add to v1.2 task list
