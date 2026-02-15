---
type: dashboard
title: Upcoming
---

# Upcoming — Next 7 Days

## Reviews Due This Week

```dataview
TABLE domain AS "Domain", next_review AS "Review Date", status AS "Status"
FROM "domains"
WHERE next_review <= date(today) + dur(7 days)
SORT next_review ASC
```

## Today's Plan

![[temporal/today#Today's Plan]]

## This Week's Journal

```dataview
LIST
FROM "journal"
WHERE date >= date(today) - dur(7 days)
SORT date DESC
```
