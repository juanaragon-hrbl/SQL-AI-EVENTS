---
name: events-qualification
description: Write SQL for events, sub-events, registrations, tickets and qualifier logic (events/promotions/AWT/ASQ). Use when work involves Event*, SubEvent*, *Qualifier*, *Registration*, AWT_*, Promotion*, or ufn_Qual*.
---

# Events & qualification domain

Core objects in `ddl\` (verify columns in the DDL before use):

- **Events**: `Event`, `EventExtn`, `EventType`, `EventSubTypes`, `EventSchedule`, `EventGroups`, `EventTickets`, `EventSKU`, `EventHotel`.
- **Sub-events**: `SubEvent`, `SubEventExtn`, `SubEventQualification`, `SubEventQualificationFormula`, `SubEventQualGroups`, `SubEventAttendance`, `SubEventGiveAway*`.
- **Qualifiers / registration**: `EventQualifier`, `SubEventQualifier`, `EventsRegistration`, `SubEventRegistration`, `QualificationDistributor`, `QualificationType`, `QualificationFrequencyType`.
- **Promotions**: `PromotionAccelerator*`, `AWT_*` (+ `v_AWT_*`), `ASQQualification` (+ views), `Events_Promotions_DRS_*` views (per region).
- **Distributor views**: `v_Distributor*`, `v_dimDSLngDownline`, `v_*Lineage` (see `lineage-hierarchy`).
- **Qualification functions**: `ufn_Qual*`, `ufn_GetQualifier_*`, `ufn_GetQualPoints_*`, `ufn_GetPoints*`, `ufn_GetPeriods`.

Conventions observed:
- Table variants: `_IN` / `_OUT` (data exchange), `_Archive`, `_Extract`; `WRK_*`/`wrk*` are working/promo-specific tables and `Temp*` are temporary — not canonical; avoid building on them unless the task targets them.
- Locale text lives in `*Locale*` / `*LocaleDesc` tables.
- Before writing, look at similar existing `usp_*` (e.g. `usp_AWT_*`) and reuse their qualifier-calculation pattern.
- Status/business meaning of codes is not documented yet; ask rather than assume.
