#!/bin/bash

# Variables
DEFAULT_EXTENSION="md"
DEFAULT_NOTE_NAME_FORMAT=$(date +"%Y-%m-%d")
EDITOR=${EDITOR:-vim}
NOTES_DIR=${NOTES_DIR:-".zettl"}
DEFAULT_NOTEBOOK_NAME=${DEFAULT_NOTEBOOK_NAME:-"default"}

# Function to get the currently active notebook
get_current_notebook() {
    local current_notebook=$(cat "$NOTES_DIR/.current_notebook")
    # Check if the directory for the current notebook exists, if not create it
    if [ ! -d "$NOTES_DIR/$current_notebook" ]; then
        mkdir -p "$NOTES_DIR/$current_notebook"
    fi
    echo "$current_notebook"
}

# Function to create a new notebook
create_notebook() {
    notebook_name=$1
    if [ -d "$NOTES_DIR/$notebook_name" ]; then
        echo "Notebook $notebook_name already exists."
    else
        mkdir -p "$NOTES_DIR/$notebook_name"
        echo "Notebook $notebook_name created."
    fi
}

# Opens a notebook
open_notebook() {
    local notebook_name="$1"
    if [ -d "$NOTES_DIR/$notebook_name" ]; then
        echo "Opening notebook $notebook_name"
        echo "$notebook_name" >"$NOTES_DIR/.current_notebook"
    else
        echo "Notebook $notebook_name does not exist. Use 'z notebooks' to see the existing notebooks"
    fi
}

# Shows existing notebooks and activate selected notebook
list_notebooks() {
    local notebook_name=$(get_current_notebook)
    echo "Existing notebooks:"
    local i=1
    for notebook in "$NOTES_DIR"/*/; do
        if [ "$notebook" == "$NOTES_DIR/$notebook_name/" ]; then
            echo " [$i] $(basename "$notebook") (active)"
        else
            echo " [$i] $(basename "$notebook")"
        fi
        i=$((i + 1))
    done
    echo -e "\nSelect a notebook to activate by entering a number or hit enter to stay in the current notebook: "
    local input
    read input
    if [[ $input =~ ^[0-9]+$ ]]; then
        if [[ $input -le $i ]]; then
            local selected_notebook=$(ls "$NOTES_DIR" | sed -n "$input"p)
            echo "$selected_notebook" >"$NOTES_DIR/.current_notebook"
            echo "Successfully switched to notebook $selected_notebook"
        else
            echo "Invalid input. Please enter a valid number corresponding to an existing notebook."
        fi
    elif [ -z "$input" ]; then
        echo "No change made, staying in notebook: $notebook_name"
    else
        echo "Invalid input. Please enter a number."
    fi
}

# Function to create a new note
create_note() {
    local notebook_name=$(get_current_notebook)
    local filepath="$1"
    if [[ -z "$filepath" ]]; then
        local note_folder="."
        local note_name="$(date +"$DEFAULT_NOTE_NAME_FORMAT")"
        local file_ext="$DEFAULT_EXTENSION"
    else
        IFS=$'\n' read -rd '' note_folder note_name file_ext <<<"$(split_file_path "$filepath")"
    fi
    if [ ! -d "$NOTES_DIR/$notebook_name/$note_folder" ]; then
        mkdir -p "$NOTES_DIR/$notebook_name/$note_folder"
    fi
    if [ -z "$note_name" ]; then
        note_name="$(date +"$DEFAULT_NOTE_NAME_FORMAT")"
    fi
    local note_path="$NOTES_DIR/$notebook_name/$note_folder/$note_name.$file_ext"
    touch "$note_path"
    $EDITOR "$note_path"
}

append_note() {
    local notebook_name=$(get_current_notebook)
    local filepath="$1"
    IFS=$'\n' read -rd '' note_folder note_name file_ext <<<"$(split_file_path "$filepath")"
    local note_path="$NOTES_DIR/$notebook_name/$note_folder/$note_name.$file_ext"
    local message="$2"
    # Check if message is passed in as an argument or via stdin
    if [ -z "$message" ]; then
        message=$(</dev/stdin)
    fi
    if [ -z "$note_name" ]; then
        echo "Error: No note name provided. Please specify a note name."
        exit 1
    elif [ ! -f "$note_path" ]; then
        echo "Error: Note $note_name not found. Please make sure the path $note_path exists."
        exit 1
    else
        echo "$message" >>"$note_path"
        echo "Successfully appended message to $note_name"
    fi
}

list_notes() {
    local current_notebook=$(get_current_notebook)
    local subfolder="$1"
    local notes_dir="$NOTES_DIR/$current_notebook"
    if [ ! -d "$notes_dir" ]; then
        echo "Error: No notes found in $current_notebook"
        return 1
    fi
    echo "Notes in $current_notebook:"
    local notes=()
    local i=1
    for note in $(find "$notes_dir/$subfolder" -type f 2>/dev/null); do
        local note_display="$(echo "$note" | sed "s|$notes_dir/||;s|^/||") - $(head -n 1 "$note" | cut -c -50)"
        notes+=("$note_display")
        echo " [$i] $note_display"
        i=$((i + 1))
    done
    if [ ${#notes[@]} -eq 0 ]; then
        echo "Error: No notes found in $current_notebook"
        return 1
    fi
    echo -e "\nEnter the number of the note to open (or hit enter to do nothing):"
    read -r selected_note
    if [[ $selected_note =~ ^[0-9]+$ ]] && [ $selected_note -le ${#notes[@]} ]; then
        local selected_note_path=$(echo "${notes[$((selected_note - 1))]}" | awk '{print $1}')
        selected_note_path="$notes_dir/$selected_note_path"
        $EDITOR "$selected_note_path"
    elif [ -n "$selected_note" ]; then
        echo "Invalid selection"
    fi
}

# Utility functions

# Function to check if .current_notebook file exists, if not create it with DEFAULT_NOTEBOOK_NAME
init() {
    if [ ! -f "$NOTES_DIR/.current_notebook" ]; then
        echo "No notebook is currently active. Activating default notebook: $DEFAULT_NOTEBOOK_NAME"
        if [ ! -d "$NOTES_DIR" ]; then
            mkdir -p "$NOTES_DIR"
        fi
        echo "$DEFAULT_NOTEBOOK_NAME" >"$NOTES_DIR/.current_notebook"
    fi
}

# Splits a filepath in directory, filename, and file extensions
split_file_path() {
    local filepath="$1"
    local directory=$(dirname "$filepath")
    local filename=$(basename "$filepath")
    if [[ "$filename" == *.* ]]; then
        # if no file extension was proivded, use default
        local file_extension="${filename##*.}"
        filename="${filename%.*}"
    else
        local file_extension="$DEFAULT_EXTENSION"
    fi
    echo "$directory"
    echo "$filename"
    echo "$file_extension"
}

test() {
    # local filepath="/folder1/folder2/file.txt"
    local filepath="$1"
    IFS=$'\n' read -rd '' directory filename file_extension <<<"$(split_file_path "$filepath")"
    echo "directory: $directory"
    echo "filename: $filename"
    echo "file_extension: $file_extension"
}

# Main program
init
case "$1" in
"create")
    if [ "$2" == "notebook" ]; then
        create_notebook "$3"
    else
        echo "Invalid option $2. Use 'create notebook <name>' to create a new notebook."
    fi
    ;;
"open")
    if [ "$2" == "notebook" ]; then
        open_notebook "$3"
    else
        echo "Invalid option $2. Use 'open notebook <name>' to open a notebook."
    fi
    ;;
"notebook" | "nb")
    if [ -f "$NOTES_DIR/.current_notebook" ]; then
        cat "$NOTES_DIR/.current_notebook"
    else
        echo "No notebook is currently active. Use 'z open notebook <name>' to open a notebook."
    fi
    ;;
"notebooks" | "nbs")
    list_notebooks
    ;;
"new" | "n")
    create_note "$2"
    ;;
"append")
    shift            # shift the positional parameters to the left (i.e. discard the first argument)
    append_note "$@" # Pass all the remaining arguments
    ;;
"notes" | "ls")
    list_notes "$2"
    ;;
"test")
    test "$2"
    ;;
esac
