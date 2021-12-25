# NO FLUFF JOBS stats gatherer

Run the command to gather and save job offer stats in a CSV report:
```sh
./gather_job_offer_stats.sh [-jftr] [-j job_type] [-f from_salary] [-t to_salary] [-r remote]
```

Use flags to customize:
- `-j` job type `frontend | backend | devops | fullstack | big-data | ai | testing`
- `-f` start from salary (in thousands)
- `-t` up to salary (in thousands)
- `-r` remote only

## Examples:

Search remote frontend jobs with default salary range (0 - 50K PLN / month):
```sh
./gather_job_offer_stats.sh -j frontend -r
```

Search backend jobs with salary range 10 - 30K PLN / month:
```sh
./gather_job_offer_stats.sh -j backend -f 10 -t 30
```

## Assumptions

Given there is a job offer found in range between 0 and 1000 PLN, script round it up to the upper value,
1000 PLN in this case, then all the calculations are performed on taking into account this value.
