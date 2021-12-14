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
job_type=$1 # frontend | backend | devops | fullstack | big-data | ai | testing

# Stats config
step_size=1
current_step=1
last_step=10 # in thousands

# Filename config
report_filename_date=$(date +%m-%d-%Y_%H-%M-%S) # to easily distinguish the reports
report_filename="${job_type}_salary_report_${report_filename_date}.csv"

# Temp data
included_trainee_offers=0
included_junior_offers=0
included_mid_offers=0
included_senior_offers=0
included_expert_offers=0

all_trainee_rates=()
all_junior_rates=()
all_mid_rates=()
all_senior_rates=()
all_expert_rates=()

# Welcome block
clear
printf "\n${cyn}NO\nFLUFF\nJOBS${end}\n\n"
printf "Report will be stored in ${red}${report_filename}${end}\n\n"

# Helper functions
get_job_type_stats_header() {
  echo "\"${1} average\",\"${1} median\",\"${1} min\",\"${1} max\""
}

get_job_type_stats_markers() {
  echo "@${1}_average@,@${1}_median@,@${1}_min@,@${1}_max@"
}

get_number_of_offers() {
  url="https://nofluffjobs.com/pl/praca-it/praca-zdalna/${job_type}?page=1&criteria=seniority%3D${2}%20salary%3Cpln${1}m"
  content=$(curl -L -s $url)
  total_count=$(echo "${content}" | tr '\n' ' ' | sed -e 's/.*totalCount&q;:\(.*\)}}.*/\1/')
  echo "${total_count}"
}

print_num() {
  if [[ $1 -gt 0 ]]; then
    echo -n "${grn}${1}${end}"
  else
    echo -n "$1"
  fi
}

get_median() {
  array_name=$1[@]
  array=("${!array_name}")
  arr=($(printf '%d\n' "${array[@]}" | sort -n))
  array_length=${#arr[@]}

  if (( $array_length % 2 == 1 )); then
    val="${arr[ $(($array_length/2)) ]}"
  else
    (( j=array_length/2 ))
    (( k=j-1 ))
    (( val=(${arr[j]} + ${arr[k]})/2 ))
  fi

  echo $val
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
    median=$(get_median arr)
    min=$(echo ${arr[0]})
    max=$(echo ${arr[${#arr[@]} - 1]})

    printf "${cyn}${seniority}${end}:\n"
    printf "%s%s\n" "average: " "${yel}${average} PLN${end}"
    printf "%s%s\n" "median: " "${yel}${median} PLN${end}"
    printf "%s%s\n" "min salary: " "${yel}${min} PLN${end}"
    printf "%s%s\n\n" "max salary: " "${yel}${max} PLN${end}"
  else
    average='-'
    median='-'
    min='-'
    max='-'
  fi

  # Store overall stats in the report
  sed -i '.bak' "s/@${seniority}_average@/${average}/" $report_filename
  sed -i '.bak' "s/@${seniority}_median@/${median}/" $report_filename
  sed -i '.bak' "s/@${seniority}_min@/${min}/" $report_filename
  sed -i '.bak' "s/@${seniority}_max@/${max}/" $report_filename
}

# Report file setup
offer_counts='"salary","total offers","trainee offers","junior offers","mid offers","senior offers","expert offers"'
echo "${offer_counts},$(get_job_type_stats_header 'trainee'),$(get_job_type_stats_header 'junior'),$(get_job_type_stats_header 'mid'),$(get_job_type_stats_header 'senior'),$(get_job_type_stats_header 'expert')" > $report_filename

for i in $(seq $last_step); do
  salary=$(( $current_step*1000 ))

  trainee_offers=$(( $(get_number_of_offers $salary "trainee") - $included_trainee_offers ))
  junior_offers=$(( $(get_number_of_offers $salary "junior") - $included_junior_offers ))
  mid_offers=$(( $(get_number_of_offers $salary "mid") - $included_mid_offers ))
  senior_offers=$(( $(get_number_of_offers $salary "senior") - $included_senior_offers ))
  expert_offers=$(( $(get_number_of_offers $salary "expert") - $included_expert_offers ))
  total=$(( $trainee_offers + $junior_offers + $mid_offers + $senior_offers + $expert_offers ))

  printf "%s%s%s%s%s%s%s%s%s%s%s%s%s\n" "Total offers with salary ${yel}${salary} PLN${end}: " "$(print_num $total)" " (trainee: " "$(print_num $trainee_offers)" ", junior: " "$(print_num $junior_offers)" ", mid: " "$(print_num $mid_offers)" ", senior: " "$(print_num $senior_offers)" ", expert: " "$(print_num $expert_offers)" ")"

  line="${salary},${total},${trainee_offers},${junior_offers},${mid_offers},${senior_offers},${expert_offers}"
  if [[ $current_step -eq 1 ]]; then
    line+=",$(get_job_type_stats_markers 'trainee'),$(get_job_type_stats_markers 'junior'),$(get_job_type_stats_markers 'mid'),$(get_job_type_stats_markers 'senior'),$(get_job_type_stats_markers 'expert')"
  else
    line+=",,,,,,,,,,,,,,,,,,,,,"
  fi

  echo $line >> $report_filename

  included_trainee_offers=$(( included_trainee_offers + trainee_offers ))
  included_junior_offers=$(( included_junior_offers + junior_offers ))
  included_mid_offers=$(( included_mid_offers + mid_offers ))
  included_senior_offers=$(( included_senior_offers + senior_offers ))
  included_expert_offers=$(( included_expert_offers + expert_offers ))

  # Append new offers to arrays
  if [[ $trainee_offers -gt 0 ]]; then
    for i in $(seq $trainee_offers); do all_trainee_rates+=($salary); done
  fi

  if [[ $junior_offers -gt 0 ]]; then
    for i in $(seq $junior_offers); do all_junior_rates+=($salary); done
  fi

  if [[ $mid_offers -gt 0 ]]; then
    for i in $(seq $mid_offers); do all_mid_rates+=($salary); done
  fi

  if [[ $senior_offers -gt 0 ]]; then
    for i in $(seq $senior_offers); do all_senior_rates+=($salary); done
  fi

  if [[ $expert_offers -gt 0 ]]; then
    for i in $(seq $expert_offers); do all_expert_rates+=($salary); done
  fi

  # Display & store analysys summary
  if [[ $current_step -eq $last_step ]]; then
    printf "\n"
    print_job_type_summary all_trainee_rates "trainee"
    print_job_type_summary all_junior_rates "junior"
    print_job_type_summary all_mid_rates "mid"
    print_job_type_summary all_senior_rates "senior"
    print_job_type_summary all_expert_rates "expert"
  fi

  current_step=$(( $current_step+$step_size ))
done
