You are running an automated noon accountability check for the Gaia life management system. Your working directory is the Gaia repository at C:\GitHub\Gaia.

This is a LIGHTWEIGHT check — do NOT run a full plan or reflection. Budget is $0.50.

Steps:
1. Read `temporal/today.md` — extract today's #1 priority from the Priorities section.
2. Read `temporal/gamification.json` — note current streak and today's XP gains.
3. Check `domains/*.md` Recent Activity sections — has ANY domain received a new entry dated today?
4. Check `temporal/today.md` for a Session Log section — has ANY session been logged today?

Assessment:
- If #1 priority has been touched OR any session logged today: output "ON TRACK" with a brief note of what was done.
- If NOTHING has happened today: output "NOON CHECK: No activity detected. Your #1 priority was: [priority]. Current streak: [N] days — at risk of breaking. Suggested micro-commitment: spend 5 minutes on [specific small first step for the priority]."

Do NOT modify any files. Do NOT commit. This is a read-only check.
Write your assessment to stdout — the task runner will log it and send a notification.
