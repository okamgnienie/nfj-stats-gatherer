#!/bin/bash

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Script parameters
JOB_TYPE=$1 # frontend | backend | devops | fullstack | big-data | ai | testing

# Stats config
STEP=1
CURRENT=1
FINISH=50 # in thousands
FILENAME_DATE=$(date +%m-%d-%Y_%H-%M-%S)
FILENAME="${JOB_TYPE}_salary_report_${FILENAME_DATE}.csv"

# Temp data
includedTraineeOffers=0
includedJuniorOffers=0
includedMidOffers=0
includedSeniorOffers=0
includedExpertOffers=0

allTraineeRates=()
allJuniorRates=()
allMidRates=()
allSeniorRates=()
allExpertRates=()

# Welcome block
clear
printf "\n${cyn}NO\nFLUFF\nJOBS${end}\n\n"
printf "Report will be stored in ${red}${FILENAME}${end}\n\n"

getJobTypeStatsHeader () {
  echo "\"${1} average\",\"${1} median\",\"${1} min\",\"${1} max\""
}

getJobTypeStatsMarkers () {
  echo "@${1}_average@,@${1}_median@,@${1}_min@,@${1}_max@"
}

# Report file setup
offer_counts='"salary","total offers","trainee offers","junior offers","mid offers","senior offers","expert offers"'
echo "${offer_counts},$(getJobTypeStatsHeader 'trainee'),$(getJobTypeStatsHeader 'junior'),$(getJobTypeStatsHeader 'mid'),$(getJobTypeStatsHeader 'senior'),$(getJobTypeStatsHeader 'expert')" > $FILENAME

getNumberOfOffers () {
  url="https://nofluffjobs.com/pl/praca-it/praca-zdalna/${JOB_TYPE}?page=1&criteria=seniority%3D${2}%20salary%3Cpln${1}m"
  content=$(curl -L -s $url)
  total_count=$(echo "${content}" | tr '\n' ' ' | sed -e 's/.*totalCount&q;:\(.*\)}}.*/\1/')
  echo "${total_count}"
}

prNum () {
  if [[ $1 -gt 0 ]]; then
    echo -n "${grn}${1}${end}"
  else
    echo -n "$1"
  fi
}

getMedian () {
  arrName=$1[@]
  array=("${!arrName}")

  IFS=$'\n'
  median=$(awk '{arr[NR]=$1} END {if (NR%2==1) print arr[(NR+1)/2]; else print (arr[NR/2]+arr[NR/2+1])/2}' <<< sort <<< "${array[*]}")
  unset IFS

  echo $median
}

getAverage() {
  arrName=$1[@]
  array=("${!arrName}")
  arrayLength="${#array[@]}"
  total=0

  for var in "${array[@]}"
  do
    total=$((total + var))
  done

  average=$(( total / $arrayLength ))
  echo $average
}

printSummmary () {
  arrName=$1[@]
  arr=("${!arrName}")
  arrLength="${#arr[@]}"
  seniority=$2

  if [[ $arrLength -gt 0 ]]; then
    average=$(getAverage arr)
    median=$(getMedian arr)
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
  sed -i '.bak' "s/@${seniority}_average@/${average}/" $FILENAME
  sed -i '.bak' "s/@${seniority}_median@/${median}/" $FILENAME
  sed -i '.bak' "s/@${seniority}_min@/${min}/" $FILENAME
  sed -i '.bak' "s/@${seniority}_max@/${max}/" $FILENAME
}

for i in $(seq $FINISH); do
  salary=$(( $CURRENT*1000 ))

  traineeOffers=$(( $(getNumberOfOffers $salary "trainee") - $includedTraineeOffers ))
  juniorOffers=$(( $(getNumberOfOffers $salary "junior") - $includedJuniorOffers ))
  midOffers=$(( $(getNumberOfOffers $salary "mid") - $includedMidOffers ))
  seniorOffers=$(( $(getNumberOfOffers $salary "senior") - $includedSeniorOffers ))
  expertOffers=$(( $(getNumberOfOffers $salary "expert") - $includedExpertOffers ))
  total=$(( $traineeOffers + $juniorOffers + $midOffers + $seniorOffers + $expertOffers ))

  printf "%s%s%s%s%s%s%s%s%s%s%s%s%s\n" "Total offers with salary ${yel}${salary} PLN${end}: " "$(prNum $total)" " (trainee: " "$(prNum $traineeOffers)" ", junior: " "$(prNum $juniorOffers)" ", mid: " "$(prNum $midOffers)" ", senior: " "$(prNum $seniorOffers)" ", expert: " "$(prNum $expertOffers)" ")"

  line="${salary},${total},${traineeOffers},${juniorOffers},${midOffers},${seniorOffers},${expertOffers}"
  if [[ $CURRENT -eq 1 ]]; then
    line+=",$(getJobTypeStatsMarkers 'trainee'),$(getJobTypeStatsMarkers 'junior'),$(getJobTypeStatsMarkers 'mid'),$(getJobTypeStatsMarkers 'senior'),$(getJobTypeStatsMarkers 'expert')"
  else
    line+=",,,,,,,,,,,,,,,,,,,,,"
  fi

  echo $line >> $FILENAME

  includedTraineeOffers=$(( includedTraineeOffers + traineeOffers ))
  includedJuniorOffers=$(( includedJuniorOffers + juniorOffers ))
  includedMidOffers=$(( includedMidOffers + midOffers ))
  includedSeniorOffers=$(( includedSeniorOffers + seniorOffers ))
  includedExpertOffers=$(( includedExpertOffers + expertOffers ))

  if [[ $traineeOffers -gt 0 ]]; then
    for i in $(seq $traineeOffers); do allTraineeRates+=($salary); done
  fi

  if [[ $juniorOffers -gt 0 ]]; then
    for i in $(seq $juniorOffers); do allJuniorRates+=($salary); done
  fi

  if [[ $midOffers -gt 0 ]]; then
    for i in $(seq $midOffers); do allMidRates+=($salary); done
  fi

  if [[ $seniorOffers -gt 0 ]]; then
    for i in $(seq $seniorOffers); do allSeniorRates+=($salary); done
  fi

  if [[ $expertOffers -gt 0 ]]; then
    for i in $(seq $expertOffers); do allExpertRates+=($salary); done
  fi

  # Display & store analysys summary
  if [[ $CURRENT -eq $FINISH ]]; then
    printf "\n"
    printSummmary allTraineeRates "trainee"
    printSummmary allJuniorRates "junior"
    printSummmary allMidRates "mid"
    printSummmary allSeniorRates "senior"
    printSummmary allExpertRates "expert"
  fi

  CURRENT=$(( $CURRENT+$STEP ))
done
