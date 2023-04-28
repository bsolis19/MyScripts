#!/bin/bash

# survey: logs survey information using entered data; assuming arg1 is a file containing line-separated questions

# create variable to hold script name
declare -r PROGNAME=$(basename $0)

# create variable to hold filepath of questions src
src_filepath=$1

# create variables to hold preliminary questions/prompts
NAME_PROMPT="Name of Person (Company):"
ROLE_PROMPT="Role or Position:"

# create variables to hold metadata
date=$(date '+%Y-%m-%d')
time=$(date '+%H:%M')

# create variable to hold DEFAULT filepath of file where output is written to
target_filepath="../Research/survey.log"

# create auxilary variables
flag=0
trimmed_txt=""
tempfile=$(mktemp)

declare -A survey_data=([date]=$date [time]=$time)
declare -A prompts=([name]=$NAME_PROMPT [role]=$ROLE_PROMPT)

declare -a order=(date time name role)
declare -a input_fields=(name role)

usage () {
    echo "$PROGNAME: usage: $PROGNAME [src file] [target file]"
    return
}

debug () {
    for arg in "$@"
    do
    done
}

validate_not_empty () {
    if [[ -n $1 ]]; then
        flag=0
    else
        flag=1
    fi
}

trim () {
    trimmed_txt=$(echo $1 | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//")
}

trim_inputs () {
    for name in "${input_fields[@]}"
    do
        trim ${survey_data[$name]}
        survey_data[$name]=$trimmed_txt
    done
}

write_line () {
    if [ "$#" -eq 2 ]; then
        printf "[%s]: %s\n" $1 $2 >> $tempfile

    elif [ "$#" -eq 1 ]; then
        printf "%s\n" $1 >> $tempfile
    fi
}

read_src_file () {
    # create a counter to tag each question
    declare -i counter=0

    # read lines from src and store in questions array
    while read line; do
        counter=($counter+1)
        tag=("q$counter")
        order+=("$line")
        input_fields+=("$tag")
        prompts[$tag]+=$line
    done < "$src_filepath"

}

log_data () {
    for key in "${order[@]}";
    do
        if [[ -z ${survey_data[$key]} ]];then
            printf '\nError processing data\n'
            debug $key "${!survey_data[@]}"
            exit 1
        fi;

        write_line $key ${survey_data[$key]};
    done
    # append empty line
    write_line "";
}

get_inputs () {
    for field in "${input_fields[@]}";
    do
        if [[ "$field" == "name" || "$field" == "role" ]];then
            read -p "${prompts[$field]}" survey_data[$field];
            validate_not_empty survey_data[$field];
            while [[ $flag == 1 ]]; do
                read -p "Enter a $field!: " survey_data[$field]
                validate_not_empty survey_data[$field]
            done;
        else
            key="${prompts[${field}]}"
            read -d \~ -p "${prompts[$field]}"$'\n' survey_data[$key];
            echo $'\n'
        fi;
    done
}

touch_file () {
    # Make file as needed
    if [ ! -e $1 ]; then
        echo > $1
    fi
}

main () {

    if [[ -n $2 ]]; then
        target_filepath=$2;
    fi
    if [[ -n $1 ]]; then
        src_filepath=$1;
    fi
    OLD_IFS=$IFS
    IFS=
    read_src_file
    get_inputs

    echo "saving data ..."

    trim_inputs
    log_data
    touch_file $target_filepath
    cat "$tempfile" >> "$target_filepath"
    rm "$tempfile"

    printf 'Logged Survey Data to %s\n' $target_filepath

    IFS=$OLD_IFS
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi
main $1
