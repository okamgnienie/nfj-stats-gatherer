#!/bin/bash

# Logging colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Script parameters
remote=false # true | false
job_type="frontend" # frontend | backend | devops | fullstack | big-data | ai | testing
first_step=0 # number 1 = 1000 PLN
last_step=50 # number 1 = 1000 PLN

while getopts rj:f:t: flag
do
  case "${flag}" in
    r) remote=true;;
    j) job_type=${OPTARG};;
    f) first_step=${OPTARG};;
    t) last_step=${OPTARG};;
  esac
done

# Stats config
step_size=1
current_step=$first_step

# Filename config
report_dir='reports'
report_filename_date=$(date +%m-%d-%Y_%H-%M-%S) # to easily distinguish the reports
report_filename="${report_dir}/${job_type}_salary_report_${report_filename_date}.csv"

# Temp data
all_trainee_rates=()
all_junior_rates=()
all_mid_rates=()
all_senior_rates=()
all_expert_rates=()

# Welcome block
clear
printf "\n${cyn}NO\nFLUFF\nJOBS${end}\n\n"
printf "Job type: ${blu}${job_type}${end}\n"
printf "Salary range: ${yel}$(( current_step * 1000 )) PLN${end} - ${yel}$(( last_step * 1000 )) PLN${end}\n"
printf "Remote only: ${grn}${remote}${end}\n\n"
printf "Report will be stored in ${red}${report_filename}${end}\n\n"

# Helper functions
get_job_type_stats_header() {
  echo ",\"${1} average\",\"${1} lower quartile\",\"${1} median\",\"${1} upper quartile\",\"${1} min\",\"${1} max\""
}

get_job_type_stats_markers() {
  echo ",@${1}_average@,@${1}_lower_quartile@,@${1}_median@,@${1}_upper_quartile@,@${1}_min@,@${1}_max@"
}

get_number_of_offers() {
  if $remote; then
    remote_chunk="/praca-zdalna"
  else
    remote_chunk=""
  fi

  url="https://nofluffjobs.com/pl/praca-it${remote_chunk}/${job_type}?page=1&criteria=seniority%3D${3}%20salary%3Epln${1}m%20salary%3Cpln${2}m"
  content=$(curl -L -s $url)
  total_count=$(echo "${content}" | tr '\n' ' ' | sed -e 's/.*totalCount&q;:\(.*\)}}.*/\1/')

  [ "$total_count" -eq "$total_count" ] 2>/dev/null && echo $total_count || echo 0
}

print_num() {
  if [[ $1 -gt 0 ]]; then
    echo -n "${grn}${1}${end}"
  else
    echo -n "$1"
  fi
}

get_percentyle() {
  array_name=$1[@]
  array=("${!array_name}")
  percentile=$2

  echo $(printf '%s\n' "${array[@]}" | sort -n | perl -e '$d='$percentile';@l=<>;print $l[int($d*$#l)]')
}

get_average() {
  array_name=$1[@]
  array=("${!array_name}")
  array_length="${#array[@]}"
  total=0

  for var in "${array[@]}"
  do
    total=$((total + var))
  done

  average=$(( total / $array_length ))
  echo $average
}

print_job_type_summary() {
  array_name=$1[@]
  arr=("${!array_name}")
  array_length="${#arr[@]}"
  seniority=$2

  if [[ $array_length -gt 0 ]]; then
    average=$(get_average arr)
    lower_quartile=$(get_percentyle arr 0.25)
    median=$(get_percentyle arr 0.5)
    upper_quartile=$(get_percentyle arr 0.75)
    min=$(echo ${arr[0]})
    max=$(echo ${arr[${#arr[@]} - 1]})

    printf "${cyn}${seniority}${end}:\n"
    printf "%s%s\n" "average: " "${yel}${average} PLN${end}"
    printf "%s%s\n" "lower quartile: " "${yel}${lower_quartile} PLN${end}"
    printf "%s%s\n" "median: " "${yel}${median} PLN${end}"
    printf "%s%s\n" "upper quartile: " "${yel}${upper_quartile} PLN${end}"
    printf "%s%s\n" "min salary: " "${yel}${min} PLN${end}"
    printf "%s%s\n\n" "max salary: " "${yel}${max} PLN${end}"
  else
    average='-'
    lower_quartile='-'
    median='-'
    upper_quartile='-'
    min='-'
    max='-'
  fi

  # Store overall stats in the report
  sed -i '.bak' "s/@${seniority}_average@/${average}/" $report_filename
  sed -i '.bak' "s/@${seniority}_lower_quartile@/${lower_quartile}/" $report_filename
  sed -i '.bak' "s/@${seniority}_median@/${median}/" $report_filename
  sed -i '.bak' "s/@${seniority}_upper_quartile@/${upper_quartile}/" $report_filename
  sed -i '.bak' "s/@${seniority}_min@/${min}/" $report_filename
  sed -i '.bak' "s/@${seniority}_max@/${max}/" $report_filename
}

# Prepare directory
mkdir -p "${report_dir}"

# Report file setup
offer_counts='"salary from","salary to","total offers","trainee offers","junior offers","mid offers","senior offers","expert offers"'
echo "${offer_counts},$(get_job_type_stats_header 'trainee'),$(get_job_type_stats_header 'junior'),$(get_job_type_stats_header 'mid'),$(get_job_type_stats_header 'senior'),$(get_job_type_stats_header 'expert')" > $report_filename

for i in $(seq $current_step $(( last_step - 1 ))); do
  salary_from=$(( $current_step * 1000 ))
  salary_to=$(( ( $current_step + 1 ) * 1000 ))

  trainee_offers=$(get_number_of_offers $salary_from $salary_to "trainee")
  junior_offers=$(get_number_of_offers $salary_from $salary_to "junior")
  mid_offers=$(get_number_of_offers $salary_from $salary_to "mid")
  senior_offers=$(get_number_of_offers $salary_from $salary_to "senior")
  expert_offers=$(get_number_of_offers $salary_from $salary_to "expert")
  total=$(( $trainee_offers + $junior_offers + $mid_offers + $senior_offers + $expert_offers ))

  printf "%s%s%s%s%s%s%s%s%s%s%s%s%s\n" "Total offers with salary in range ${yel}${salary_from} PLN${end} - ${yel}${salary_to} PLN${end}: " "$(print_num $total)" " (trainee: " "$(print_num $trainee_offers)" ", junior: " "$(print_num $junior_offers)" ", mid: " "$(print_num $mid_offers)" ", senior: " "$(print_num $senior_offers)" ", expert: " "$(print_num $expert_offers)" ")"

  line="${salary_from},${salary_to},${total},${trainee_offers},${junior_offers},${mid_offers},${senior_offers},${expert_offers}"
  if [[ $current_step -eq $first_step ]]; then
    line+=",$(get_job_type_stats_markers 'trainee'),$(get_job_type_stats_markers 'junior'),$(get_job_type_stats_markers 'mid'),$(get_job_type_stats_markers 'senior'),$(get_job_type_stats_markers 'expert')"
  else
    line+=",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"
  fi

  echo $line >> $report_filename

  # Append new offers to arrays
  if [[ $trainee_offers -gt 0 ]]; then
    for i in $(seq $trainee_offers); do all_trainee_rates+=($salary_from); done
  fi

  if [[ $junior_offers -gt 0 ]]; then
    for i in $(seq $junior_offers); do all_junior_rates+=($salary_from); done
  fi

  if [[ $mid_offers -gt 0 ]]; then
    for i in $(seq $mid_offers); do all_mid_rates+=($salary_from); done
  fi

  if [[ $senior_offers -gt 0 ]]; then
    for i in $(seq $senior_offers); do all_senior_rates+=($salary_from); done
  fi

  if [[ $expert_offers -gt 0 ]]; then
    for i in $(seq $expert_offers); do all_expert_rates+=($salary_from); done
  fi

  # Display & store analysys summary
  if [[ $current_step -eq $(( last_step - 1 )) ]]; then
    printf "\n"
    print_job_type_summary all_trainee_rates "trainee"
    print_job_type_summary all_junior_rates "junior"
    print_job_type_summary all_mid_rates "mid"
    print_job_type_summary all_senior_rates "senior"
    print_job_type_summary all_expert_rates "expert"
  fi

  current_step=$(( $current_step + $step_size ))
done

rm "${report_filename}.bak"
