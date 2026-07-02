---
type: dashboard
title: Active Projects
---

# Active Projects

## Domains with Linked Repos

```dataview
TABLE domain AS "Domain", status AS "Status", updated AS "Last Updated"
FROM "domains"
WHERE contains(tags, "professional")
SORT updated DESC
```

## Recent Activity Across Projects

```dataview
LIST
FROM "domains"
WHERE contains(tags, "professional")
SORT updated DESC
```
