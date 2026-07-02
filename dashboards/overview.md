---
type: dashboard
title: Overview
---

# Gaia Overview

## All Domains — Last Updated

```dataview
TABLE updated AS "Last Updated", status AS "Status", next_review AS "Next Review"
FROM "domains"
SORT updated DESC
```

## Overdue Reviews

```dataview
TABLE domain AS "Domain", next_review AS "Due"
FROM "domains"
WHERE next_review < date(today)
SORT next_review ASC
```
