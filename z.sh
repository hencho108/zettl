#!/bin/bash

# Variables -------------------------------------------------------------------

NOTE_EXTENSIONS="md|txt"
DEFAULT_NOTE_EXTENSION=${DEFAULT_NOTE_EXTENSION:-"md"}
DEFAULT_NOTE_NAME_FORMAT=${DEFAULT_NOTE_NAME_FORMAT:-$(date +"%Y-%m-%d")}
NOTE_NAME_AS_TITLE=${NOTE_NAME_AS_TITLE:-1}
INSERT_NOTE_CREATED_HEADER=${INSERT_NOTE_CREATED_HEADER:-1}
NOTE_CREATED_HEADER=${NOTE_CREATED_HEADER:-"Created: $(date +"%Y-%m-%d")"}
Z_EDITOR=${Z_EDITOR:-vim}
NOTES_DIR=${NOTES_DIR:-"$HOME/zettl"}
DEFAULT_NOTEBOOK_NAME=${DEFAULT_NOTEBOOK_NAME:-"default"}
COPY_SCREENSHOT_PATH_TO_CLIPBOARD=${COPY_SCREENSHOT_PATH_TO_CLIPBOARD:-1}
CLIPBOARD_SCREENSHOT_PATH_WRAPPER=${CLIPBOARD_SCREENSHOT_PATH_WRAPPER:-"![](file:*)"}
DEFAULT_SCREENSHOT_NAME_FORMAT=${DEFAULT_SCREENSHOT_NAME_FORMAT:-$(date +"%Y-%m-%d")}
DEFAULT_SCREENSHOT_EXTENSION=${DEFAULT_SCREENSHOT_EXTENSION:-"png"}
Z_VERSION="0.0.1"

# Functions -------------------------------------------------------------------

# Creates a new notebook
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
    local current_notebook=$(get_current_notebook)
    local filepath="$1"
    IFS=$'\n' read -rd '' note_folder note_name file_ext <<< "$(split_file_path "$filepath")"
    if [ ! -d "$NOTES_DIR/$current_notebook/$note_folder" ]; then
        mkdir -p "$NOTES_DIR/$current_notebook/$note_folder"
    fi
    if [ -z "$note_name" ]; then
        note_name="$(date +"$DEFAULT_NOTE_NAME_FORMAT")"
    fi
    local note_path="$NOTES_DIR/$current_notebook/$note_folder/$note_name.$file_ext"
    touch "$note_path"
    # If filesize is zero, i.e. the file is empty
    if [ ! -s "$note_path" ]; then
        if [ $NOTE_NAME_AS_TITLE -eq 1 ]; then
            echo "# $note_name" >>"$note_path"
        fi
        if [ $INSERT_NOTE_CREATED_HEADER -eq 1 ]; then
            echo "$NOTE_CREATED_HEADER" >>"$note_path"
        fi
    fi
    edit_note $note_path
}

# Quicky appends an existing note
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
    local notes_dir="$NOTES_DIR/$current_notebook"
    local sorted_notes=""

    # Parse args
    sort=false
    max_results=9223372036854775807
    # If first argument does not start with "-"
    if [[ ! "$1" =~ ^- ]]; then
        subfolder="$1"
        shift
    fi
    while getopts "st:" opt; do
        case "$opt" in
        s) sort_alphabetically=true ;;
        t) max_results="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    # Make sure that note exists
    if [ ! -d "$notes_dir/$subfolder" ]; then
        if [ -z "$subfolder" ]; then
            echo "Error: No notes found in $current_notebook"
        else
            echo "Error: Directory $notes_dir/$subfolder does not exist"
        fi
        return 1
    fi
    # Get notes
    if [ "$sort_alphabetically" == true ]; then
        # If -s is an argument sort output alphabetically
        # sorted_notes=$(find "$notes_dir/$subfolder" -mindepth 1 -type f 2>/dev/null | grep -E ".(${NOTE_EXTENSIONS})" | sort)
        sorted_notes=$(find "$notes_dir/$subfolder" -mindepth 1 -type f ! -name "." -print | grep -E "..(${NOTE_EXTENSIONS})$" | grep -v "$notes_dir/$subfolder/.bin/" | sort)
    else
        # Else sort by last modified time
        # sorted_notes=$(find "$notes_dir/$subfolder" -mindepth 1 -type f -exec stat -f "%m %N" {} \; | grep -E ".(${NOTE_EXTENSIONS})" | sort -nr | cut -d' ' -f2-)
        sorted_notes=$(find "$notes_dir/$subfolder" -mindepth 1 -type f ! -name "." -print | grep -E "..(${NOTE_EXTENSIONS})$" | grep -v "$notes_dir/$subfolder/.bin/" | xargs stat -f "%m %N" | sort -nr | cut -d' ' -f2-)
    fi
    # Print output
    if [[ -z $subfolder ]]; then
        echo "Notes in '$current_notebook':"
    else
        echo "Notes in '$current_notebook' --> $subfolder:"
    fi
    local notes=()
    local i=1
    IFS=$'\n'
    for note in $sorted_notes; do
        local color="\033[32m"
        local note_display="$(echo "$note" | sed "s|$notes_dir/||;s|$subfolder/||") | $(head -n 1 "$note" | cut -c -50)"
        notes+=("$note_display")
        if [ $i -lt 10 ]; then
            echo "  [$i] $note_display"
        else
            echo " [$i] $note_display"
        fi
        # Limit the number of notes to output
        if [ "$i" -ge "$max_results" ]; then
            break
        fi
        # Increment counter
        i=$((i + 1))
    done
    if [ ${#notes[@]} -eq 0 ]; then
        echo "Error: No notes found in $current_notebook"
        return 1
    fi
    # Open selected note
    echo -e "\nEnter the number of the note to open (or hit enter to do nothing):"
    read -r selected_note
    if [[ $selected_note =~ ^[0-9]+$ ]] && [ $selected_note -le ${#notes[@]} ]; then
        local selected_note_path=$(echo "${notes[$((selected_note - 1))]}" | awk '{print $1}')
        selected_note_path="$notes_dir/$subfolder/$selected_note_path"
        edit_note $selected_note_path
    elif [ -n "$selected_note" ]; then
        echo "Invalid selection"
    fi
}

# Reopens last edited note
reopen_last_note() {
    local current_notebook=$(get_current_notebook)
    local last_edited_file="$NOTES_DIR/$current_notebook/.last_edited"
    if [ -f "$last_edited_file" ]; then
        local last_edited_note_path=$(cat "$last_edited_file")
        if [ -f "$last_edited_note_path" ]; then
            edit_note $last_edited_note_path
        else
            echo "Error: the last edited note '$last_edited_note_path' does not exist."
        fi
    else
        echo "Error: no last edited note found."
    fi
}

# Deletes a note
delete_note() {
    local current_notebook=$(get_current_notebook)
    local filepath="$1"
    IFS=$'\n' read -rd '' note_folder note_name file_ext <<<"$(split_file_path "$filepath")"
    local note_path="$NOTES_DIR/$current_notebook/$note_folder/$note_name.$file_ext"
    if [ -f "$note_path" ]; then
        mkdir -p "$NOTES_DIR/$current_notebook/.bin"
        mv "$note_path" "$NOTES_DIR/$current_notebook/.bin/$note_name.$file_ext"
        echo "Note '$note_folder/$note_name' has been removed from notebook '$current_notebook'."
    else
        echo "Error: Note '$note_folder/$note_name' does not exist in notebook '$current_notebook'."
    fi
}

# Deletes the contents of the .bin folder
empty_bin() {
    local current_notebook=$(get_current_notebook)
    local bin_path="$NOTES_DIR/$current_notebook/.bin"
    # If .bin directory exists and is not empty
    if [ -d "$bin_path" ] && [ -n "$(ls -A "$bin_path")" ]; then
        rm -r "$bin_path"/*
        echo "The bin of notebook '$current_notebook' has been emptied."
    else
        echo "No notes in bin for notebook '$current_notebook'."
    fi
}

# Moves a note from one folder to another
move_note() {
    local current_notebook=$(get_current_notebook)
    local source_path="$1"
    local destination_path="$2"
    IFS=$'\n' read -rd '' source_folder source_name source_ext <<<"$(split_file_path "$source_path")"
    IFS=$'\n' read -rd '' dest_folder dest_name dest_ext <<<"$(split_file_path "$destination_path")"
    local source_file_path="$NOTES_DIR/$current_notebook/$source_folder/$source_name.$source_ext"
    local dest_file_path="$NOTES_DIR/$current_notebook/$dest_folder/$dest_name.$dest_ext"
    if [ ! -d "$NOTES_DIR/$current_notebook/$source_folder" ]; then
        echo "Error: source folder '$source_folder' does not exist."
    elif [ ! -f "$source_file_path" ]; then
        echo "Error: source file '$source_name.$source_ext' does not exist."
    elif [ ! -d "$NOTES_DIR/$current_notebook/$dest_folder" ]; then
        echo "Destination folder '$dest_folder' does not exist. Creating it..."
        mkdir -p "$NOTES_DIR/$current_notebook/$dest_folder"
    elif [ -f "$dest_file_path" ]; then
        echo "Error: destination file '$dest_name.$dest_ext' already exists."
    else
        mv "$source_file_path" "$dest_file_path"
        echo "Successfully moved '$source_folder/$source_name.$source_ext' to '$dest_folder/$dest_name.$dest_ext'."
    fi
}

# Searches note in the current notebook using grep
search_notebook() {
    local current_notebook=$(get_current_notebook)
    local search_path="$NOTES_DIR/$current_notebook"
    if [ -d "$search_path" ]; then
        local i=1
        IFS=$'\n'
        local results=($(grep -r "$@" "$search_path"))
        IFS=$' '
        if [ ${#results[@]} -ne 0 ]; then
            for note in "${results[@]}"; do
                local note_path=${note:${#search_path}+1}
                # note_path="${note_path%%:*}: ${note_path#*: }"
                echo "[$i] $note_path"
                i=$((i + 1))
            done
            echo -e "\nEnter the number of the note you want to open or hit Enter to do nothing: "
            local input
            read input
            if [[ $input =~ ^[0-9]+$ ]]; then
                if [[ $input -le $i ]]; then
                    local selected_note="${results[input - 1]}"
                    IFS=$'\n'
                    selected_note=($(echo "$selected_note" | awk -F: '{print $1}'))
                    IFS=$' '
                    $Z_EDITOR "$selected_note"
                else
                    echo "Invalid input. Please enter a valid number corresponding to a search result."
                fi
            elif [ -z "$input" ]; then
                echo "Nothing selected"
            else
                echo "Invalid input. Please enter a number or hit Enter to do nothing."
            fi
        else
            echo "No results found for your search"
        fi
    else
        echo "Notebook $current_notebook does not exist."
    fi
}

show_notebook_tree() {
    local current_notebook=$(get_current_notebook)
    (cd "$NOTES_DIR/$current_notebook" && ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/')
}

# Captures a screenshot of a selected area, saves it, and copies the path to clipboard
screenshot() {
    # Define the location to save the screenshot
    local current_notebook=$(get_current_notebook)
    local img_dir="$NOTES_DIR/$current_notebook/img"
    mkdir -p "$img_dir"

    # Define the default filename and file extension
    filename="$DEFAULT_SCREENSHOT_NAME_FORMAT"
    extension=".$DEFAULT_SCREENSHOT_EXTENSION"

    # Check if the user provided a filename
    if [[ ! -z "$1" ]]; then
        filename=$1
        # Check if the user provided a file extension
        if [[ $1 == *.* ]]; then
            extension=""
        fi
    else
        # Check if the default filename already exists and add a counter to the
        # name if it does. Example: screenshot.png --> screenshot (2).png
        i=1
        while [ -f "$img_dir/$filename$extension" ]; do
            i=$((i + 1))
            filename="${filename% (*)} ($i)"
        done
    fi

    # Check if file already exists
    if [ -f "$img_dir/$filename$extension" ]; then
        # Prompt the user to overwrite, dismiss or add anyways (with counter)
        echo "File already exists. What do you want to do?"
        options=("overwrite" "dismiss" "add anyways")
        for i in "${!options[@]}"; do
            echo "[$((i + 1))] ${options[i]}"
        done
        read -p "Enter your choice: " choice
        # Validate input
        while [[ ! $choice =~ ^[1-3]$ ]]; do
            echo "Invalid choice. Please enter a number between 1-3."
            read -p "Enter your choice: " choice
        done
        # Execute choice
        case $choice in
        "overwrite" | "1") ;;

        "dismiss" | "2")
            exit
            ;;
        "add" | "3")
            i=1
            while [ -f "$img_dir/$filename$extension" ]; do
                i=$((i + 1))
                filename="${filename% (*)} ($i)"
            done
            ;;
        esac
    fi
    # Capture a screenshot of a selected area
    # Notes that this command is only available on macOS. On Linux, you can use :
    # scrot -s "$screenshot_location$filename$extension"
    echo "Select the area to screenshot..."
    screencapture -i -s "$img_dir/$filename$extension"
    if [ -f "$img_dir/$filename$extension" ]; then
        echo "Screenshot saved in: $img_dir/$filename$extension"
        # Copy the path to the clipboard
        if [ $COPY_SCREENSHOT_PATH_TO_CLIPBOARD -eq 1 ]; then
            # Insert screenshot path into wrapper and copy to clipboard
            local screenshot_path="$img_dir/$filename$extension"
            # Replace spaces with %20
            local escaped_screenshot_path="${screenshot_path// /%20}"
            local clipboard=$(echo $CLIPBOARD_SCREENSHOT_PATH_WRAPPER | sed 's/*/'"${escaped_screenshot_path//\//\\/}"'/')
            echo "$clipboard" | pbcopy
            echo "Path to screenshot copied to clipboard."
        fi
    else
        echo "No screenshot taken"
    fi
}

# Utility functions -------------------------------------------------------------------

# Checks if .current_notebook file exists, if not create it with DEFAULT_NOTEBOOK_NAME
init() {
    if [ ! -f "$NOTES_DIR/.current_notebook" ]; then
        echo "No notebook is currently active. Activating default notebook: $DEFAULT_NOTEBOOK_NAME"
        if [ ! -d "$NOTES_DIR" ]; then
            mkdir -p "$NOTES_DIR"
        fi
        echo "$DEFAULT_NOTEBOOK_NAME" >"$NOTES_DIR/.current_notebook"
    fi
}

# Opens an existing note
edit_note() {
    # Open note in editor
    local note_path=$1
    $Z_EDITOR "$note_path"
    editor_return_value=$?
    if [ $editor_return_value -eq 0 ]; then
        # Update last edited note file
        echo "$note_path" >"$NOTES_DIR/$current_notebook/.last_edited"
        # Print confirmation
        if [[ $note_folder == "." ]]; then
            echo "Note '$note_name' saved in notebook '$current_notebook'."
        else
            echo "Note '$note_folder/$note_name' saved in notebook '$current_notebook'."
        fi
    fi
    # Update last edited note file
    editor_return_value=$?
    if [ $editor_return_value -eq 0 ]; then
        echo "$note_path" >"$NOTES_DIR/$current_notebook/.last_edited"
    fi
}

# Gets the currently active notebook
get_current_notebook() {
    local current_notebook=$(cat "$NOTES_DIR/.current_notebook")
    # Check if the directory for the current notebook exists, if not create it
    if [ ! -d "$NOTES_DIR/$current_notebook" ]; then
        mkdir -p "$NOTES_DIR/$current_notebook"
    fi
    echo "$current_notebook"
}

# Splits a filepath in directory, filename, and file extensions
split_file_path() {
    local filepath="$1"
    # if filepath is empty, create default note
    if [[ -z "$filepath" ]]; then
        local directory="."
        local filename="$(date +"$DEFAULT_NOTE_NAME_FORMAT")"
        local file_extension="$DEFAULT_NOTE_EXTENSION"
    # if filepath ends with '/', remove the '/' and create default note in that directory
    elif [[ "${filepath: -1}" == "/" ]]; then
        local directory="${filepath%?}"
        local filename="$(date +"$DEFAULT_NOTE_NAME_FORMAT")"
        local file_extension="$DEFAULT_NOTE_EXTENSION"
    # if filepath is a filename or directory with a filename
    else
        local directory=$(dirname "$filepath")
        local filename=$(basename "$filepath")
        # if no file extension was proivded, use default
        if [[ "$filename" == *.* ]]; then
            local file_extension="${filename##*.}"
            filename="${filename%.*}"
        else
            local file_extension="$DEFAULT_NOTE_EXTENSION"
        fi
    fi
    echo "$directory"
    echo "$filename"
    echo "$file_extension"
}

# Main Program -------------------------------------------------------------------

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
"append" | "a")
    shift            # shift the positional parameters to the left (i.e. discard the first argument)
    append_note "$@" # Pass all the remaining arguments
    ;;
"notes" | "ls")
    shift
    list_notes "$@"
    ;;
"last" | "l")
    reopen_last_note
    ;;
"delete" | "d")
    delete_note "$2"
    ;;
"empty")
    if [ "$2" == "bin" ]; then
        empty_bin
    else
        echo "Invalid option. Use 'empty bin' to empty the bin."
    fi
    ;;
"move" | "mv")
    move_note "$2" "$3"
    ;;
"search" | "s" | "grep")
    shift
    search_notebook "$@"
    ;;
"tree")
    show_notebook_tree
    ;;
"screencapture" | "sc")
    screenshot "$2"
    ;;
"version" | "v")
    echo "Zettl v${Z_VERSION}"
    ;;
esac
