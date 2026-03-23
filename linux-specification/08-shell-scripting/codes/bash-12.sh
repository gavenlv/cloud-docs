function process() {
    echo "Args: $@"
    echo "Count: $#"
    for arg in "$@"; do
        echo "Arg: $arg"
    done
}