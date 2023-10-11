#!/bin/bash

# Check if 4 arguments were provided
if [ $# -le 3 ]; then
    echo "Usage: $0 <job name> <script path> <csv path> <duration> -c <num_cpus> -m <mem in gb> -b <batch size>"
    exit 1
fi

job_name=$1
script=$2
csv_file=$3
duration=$4
shift 4
num_cpus=1
mem=16

while getopts "c:m:b:" opt; do
    case $opt in
        c)
            num_cpus="$OPTARG"
            if ! [[ $num_cpus =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: -c argument must be a positive integer."
                exit 1
            fi
            ;;
        m)
            mem="$OPTARG"
            if ! [[ $mem =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: -m argument must be a positive integer."
                exit 1
            fi
            ;;

        \?)
            echo "Invalid option: -$OPTARG"
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            ;;
    esac
done

# Check if the script file exists
if [ -e "$script" ]; then
    :
else
    echo "Script does not exist: $script"
    exit 1
fi

# Check if the CSV file exists
if [ -e "$csv_file" ]; then
    :
else
    echo "CSV does not exist: $csv_file"
    exit 1
fi

#check format of duration string
pattern="^([0-9][0-9]{0,2}):([0-5][0-9]):([0-5][0-9])$"
if [[ $duration =~ $pattern ]]; then
    :
else
    echo "Incorrect duration format: $duration"
    exit 1
fi

# make log dir
log=$(dirname "$script")
datetime=$(date +"%Y%m%d%H%M%S")
log="$log/log-$datetime"
mkdir "$log"
log_param="$log/%x-%j.out"

#build sbatch command
sbatch_command='sbatch --job-name=$job_name -N 1 -c $num_cpus -o $log_param --mem="$mem"gb --time=$duration job.sh'

while IFS= read -r line || [ -n "$line" ]; do
    add_input="$sbatch_command $line"
    eval "$add_input"
done < "$csv_file"

