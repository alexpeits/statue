main() {
    declare -r fileName="$1"

    declare -r firstLine="$(head -n 1 "$fileName")"

    if [ ! "$firstLine" = "---" ]; then
        exit 1
    fi

    declare state="0"
    output=""

    while IFS= read -r line; do
        if [ "$state" = "2" ]; then
            break
        elif [ "$line" = "---" ]; then
            if [ "$state" = "0" ]; then
                state="1"
            elif [ "$state" = "1" ]; then
                state="2"
            fi
        elif [ "$state" = "1" ]; then
            output="$output\n$line"
        fi
    done < "$fileName"

    echo -e "$output"
}

main "$@"
