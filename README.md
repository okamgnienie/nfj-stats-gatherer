# NO FLUFF JOBS stats gatherer

Run the command to gather and save job offer stats like so:
```shell
./gather_job_offer_stats.sh [-jftr] [-j job_type] [-f from_salary] [-t to_salary] [-r remote] 
```

Use flags to customize:
- `-j` job type `frontend | backend | devops | fullstack | big-data | ai | testing`
- `-f` start from salary (in thousands)
- `-t` up to salary (in thousands)
- `-r` remote only
