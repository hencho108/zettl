# zettl
zettl is a simple and efficient note-taking application designed for the command line. It provides users with an alternative to traditional UI-based note taking apps like Notion, OneNote, Evernote, etc. The notes are stored in markdown format, making them highly flexible and easily accessible. This application provides users with maximum control over their notes and the ability to use Vim or other efficient text editors. The keyboard-only interface makes taking notes extremely fast, without the need for a mouse. This app is ideal for people who want to take notes quickly and efficiently, without any distractions.

## Main Features
- Create different notebooks to organize notes on a high level
- Quickly create new notes from the command line
- View all existing notes with title, date of creation, and date of last modification
- Edit existing notes by title
- Delete existing notes by title
- Search existing notes by keyword
- Take screenshots and easily paste them into notes

## Getting Started
To install zettl you just need to place it in your PATH. In order to do this, you can follow these steps:

1. Clone the repository: `git clone https://github.com/hencho108/zettl.git`
2. Change into the repository directory: `cd <repository>`
3. Make the script executable: `chmod +x z.sh`
4. If you want to run the script from anywhere on your system, you can add it to your PATH. You can do this by creating a symbolic link in a directory that is in your PATH, such as /usr/local/bin. You can create the symbolic link using the following command: `ln -s $(pwd)/z.sh /usr/local/bin/z`
5. Verify that it worked by running: `z version`
If the last command shows the version number, you are all set.

## Why Another Note-taking Application?
The main motivation behind this project is to provide a simple, efficient and flexible note-taking solution that is not tied to any proprietary format or application. The traditional UI-based note-taking apps often come with a lot of features and complexity, which can slow down the note-taking process. 

## Markdown as Note-taking Format
By default, zettl stores notes in markdown format and I highly recommend keeping it this way. Markdown is a popular format for writing and formatting text in a readable way. It provides a simple syntax for formatting text, including headings, bold, italic, lists, links, and more. The use of markdown as the note-taking format provides several benefits, including:
- Easy to Read: The notes are written in plain text, which makes them easy to read and understand. The markdown syntax provides a simple way to format the text, making it readable and organized.
- Portable: The notes are stored in plain text format, which makes them portable and easy to access on any platform. They can be stored in a cloud-based service, like Dropbox, and accessed from anywhere.
- Versatile: The markdown format is widely used and supported by many different applications, making it versatile and easy to use. The notes can be opened with a markdown editor like Obsidian if the user wants to have a UI.

## Usage on Mobile
While this application was designed for the command line interface, the notes can also be accessed on mobile devices. The folder where the notes are stored can be a Dropbox folder, which makes it easy to access the notes from a mobile device. If a UI-based note taking app is necessary, the notes can be easily opened with a markdown editor like Obsidian, which provides a clean and simple interface for viewing and editing the notes.

## Command Reference
### Create Notebook
The `create notebook` command allows you to create a new notebook in your notes directory.

#### Usage
To create a new notebook, use the following syntax:

```bash
z create notebook <notebook_name>
```
where <notebook_name> is the name you would like to give to the notebook.

#### Example
Here is an example of how to create a new notebook called "daily-notes":

```bash
z create notebook daily_notes
```
This will create a new notebook named "daily-notes" in the notes directory specified by the `NOTES_DIR` environment variable.

#### Environment Variables
The following environment variables can be set to configure the behavior of the command:

- NOTES_DIR: This variable specifies the directory where all notebooks will be stored. If this variable is not set, the default value is $HOME/notes.

### Open 
The open command allows you to open an existing notebook in your notes directory.

#### Usage
To open a notebook, use the following syntax:

```bash
z open notebook <notebook_name>
```
where <notebook_name> is the name of the notebook you would like to open.

#### Example
Here is an example of how to open a notebook called "daily-notes":

```bash
z open notebook daily-notes
```

This will open the notebook named "daily-notes" in the notes directory specified by the `NOTES_DIR` environment variable.

#### Environment Variables
The following environment variables can be set to configure the behavior of the command:

- NOTES_DIR: This variable specifies the directory where all notebooks will be stored. If this variable is not set, the default value is $HOME/notes.

### Notebook
This command displays the name of the currently active notebook.

#### Usage
```bash
z notebook
```
or

```bash
z nb
```

#### Output
If there is an active notebook, the command will output its name:

```bash
notebook1
```

If there is no active notebook, the user will see the following message:

```bash
No notebook is currently active. Use 'z open notebook <name>' to open a notebook.
```

### Notebooks
This command lists all existing notebooks in the `NOTES_DIR` directory, and allows the user to select one of them to activate.

#### Usage
```bash
z notebooks
```
or
```bash
z nbs
```

#### Output
```bash
Existing notebooks:
 [1] notebook1
 [2] notebook2 (active)
 [3] notebook3
Select a notebook to activate by entering a number or hit enter to stay in the current notebook: 
```

The user can then input a number corresponding to one of the existing notebooks to switch to that notebook. If the user enters an invalid number, they will see the following error message:

```bash
Invalid input. Please enter a valid number corresponding to an existing notebook.
```

If the user inputs an empty string or something that is not a number, they will see the following message:

```bash
No change made, staying in notebook: <current_notebook>
```

### Create a New Note
This command creates a new note.

#### Usage
```bash
z create note <notepath>
```

#### Example
```bash
z new meetings/xyz-project
```
This will create a new note named "xzy-project" in the "meetings" folder of the current active notebook.

**Careful**: If you end <notepath> on a `/`, zettl will assume that the last part of <notepath> is a folder instead of the name of the note. Hence,
```bash
z new meetings/xyz-project/
```
will create a new note in the "meetings/xyz-project" folder named according to $DEFAULT_NOTE_NAME_FORMAT (date of today by default".

#### Output
The function will create a new note with the default format if the file at the specified <notepath> does not exist. If the file exists, the function will not make any changes to it. After the file has been created or checked, the function will open the file in the text editor specified by the $EDITOR environment variable.

#### Environment variables
The following environment variables can be set to configure the behavior of the command:
- DEFAULT_NOTE_NAME_FORMAT: The default format to use for the note name if none is specified in the filepath.
- INSERT_NOTE_CREATED_HEADER: If set to 1, the function will insert a header with the current date and time to the newly created note.
- NOTE_NAME_AS_TITLE: If set to 1, the function will use the note name as the title in markdown format.
- NOTE_CREATED_HEADER: The header text to insert into a newly created note if $INSERT_NOTE_CREATED_HEADER is set to 1.
- NOTES_DIR: The root directory for all notebooks and notes.

### Append note
Appends a message passed to an existing note.

#### Usage
```bash
z append <notepath> <message>
```
or

```bash
z a <notepath> <message>
```

#### Example
Append message "This is a new message" to a note named note.txt in the current notebook:

```bash
z append note.txt "This is a new message"
```

Alternatively, the following syntax has the same effect:

```bash
echo "This is a new message" | z append note.txt
```
#### Output
If the message is successfully appended to the note.
```bash
Successfully appended message to <note_name> 
```
If no note name is provided.
```bash
Error: No note name provided. Please specify a note name.
```
If the specified note does not exist.
```bash
Error: Note <note_name> not found. Please make sure the path <note_path> exists.
```

#### Environment Variables
This function uses the following environment variables:

- NOTES_DIR: The base directory where all the notebooks and notes are stored.
- DEFAULT_NOTE_NAME_FORMAT: The format to use for the note name if no name is provided.

### List Notes
The list notes function lists all of the notes within the current notebook, sorted either alphabetically or by last modification time, and allows the user to select and open a note for editing.

#### Usage
```bash
z notes [-s] [-t max_results] <subfolder>
```

#### Options
-s: sort the notes alphabetically (by default, the notes are sorted by last modification time)
-t max_results: limit the number of notes to display to max_results (by default, all of the notes are displayed)
subfolder: the name of a subfolder within the current notebook to list the notes from (by default, the notes are listed from the root of the current notebook)

#### Example
```bash
z notes -s -t 10 research
```
This command will list the first 10 notes within the "research" subfolder of the current notebook, sorted alphabetically.

#### Output
```bash
Notes in 'current_notebook' --> research:
  [1] note1.md | # note1
  [2] note2.md | # note2
  [3] note3.md | # note3
  [4] note4.md | # note4
  [5] note5.md | # note5
  [6] note6.md | # note6
  [7] note7.md | # note7
  [8] note8.md | # note8
  [9] note9.md | # note9
 [10] note10.md | # note10

Enter the number of the note to open (or hit enter to do nothing):
```

#### Environment Variables
- NOTES_DIR: the root directory where the notebooks and notes are stored
- NOTE_EXTENSIONS: a list of file extensions that are considered to be notes (for example, ".md .txt")

### Reopen Last Note
This function allows you to reopen the last edited note in the current notebook.

#### Usage
```bash
z last
```
or
```bash
z l
```

#### Environment Variables
- NOTES_DIR: the root directory where all of the user's notebooks and notes are stored

#### Output
If a last edited note exists, the function opens the note for editing in the editor specified by the $EDITOR environment variable. If there is no last edited note, the function outputs an error message to the console:

```bash
Error: no last edited note found.
```

If the last edited note file exists, but the note itself does not, the function outputs an error message to the console:

```bash
Error: the last edited note '<last_edited_note_path>' does not exist.
```

#### Delete Note
The function delete_note deletes a note from the current notebook.

#### Usage
```bash
z delete <notepath>
```
or
```bash
z d <notepath>
```

#### Example
To delete a note hello.txt located in the folder "notes" in the current notebook, you would run:

```bash
z delete notes/hello.txt
```

#### Output
If the note is successfully deleted, the following message is displayed:

```bash
Note 'notes/hello' has been removed from notebook 'current_notebook'.
```

If the note does not exist in the current notebook, the following error message is displayed:

```bash
Error: Note 'notes/hello' does not exist in notebook 'current_notebook'.
```

#### Environment variables
The following environment variable is used in this function:

- NOTES_DIR: This variable stores the path to the directory where all the notebooks and notes are stored.


### Empty Bin
This function empties the contents of the ".bin" folder in the current notebook. It checks if the ".bin" folder exists and is not empty. If the conditions are met, all the contents of the. 

#### Usage
```bash
z empty bin
```

#### Output
If the action was successful:
```bash
The bin of notebook 'current_notebook' has been emptied.
```
If the folder does not exist or is empty, a message saying that there are no notes in the bin for the current notebook is displayed.
```bash
No notes in bin for notebook 'current_notebook'.
```

#### Environment Variables
This function requires the $NOTES_DIR environment variable to be set, which is the path to the directory where all the notebooks and notes are stored.


### Move Note
This command moves a note from one folder to another within the same notebook.

#### Usage
```bash
z move <old_notepath> <new_notepath>
```
or
```bash
z mv <old_notepath> <new_notepath>
```

#### Example
```bash
z move  "old_folder/old_file.txt" "new_folder/new_file.txt"
```

#### Output
If the source folder does not exist, it will display an error message:
```bash
Error: source folder '<folder_name>' does not exist."
```
If the source file does not exist, it will display an error message:
```bash
Error: source file '<file_name>.<file_extension>' does not exist.
```
If the destination folder does not exist, it will create the folder and display a message:
```bash
Destination folder '<folder_name>' does not exist. Creating it...
```
If the destination file already exists, it will display an error message:
```bash
Error: destination file '<file_name>.<file_extension>' already exists.
```
If the move operation is successful, it will display a success message:
```bash
Successfully moved '<source_folder>/<source_file>.<source_extension>' to '<destination_folder>/<destination_file>.<destination_extension>'."
```

#### Environment Variables
- NOTES_DIR: The path to the root directory where all the notebooks and notes are stored.

### Search Notes
This command allows you to search for notes within the current notebook using the grep command. The function takes in any number of arguments which are used as the search query.

#### Usage
The function can be called by typing search, s, or grep as a command followed by the search query.

```bash
z search "search query"
```
or
```bash
z s "search query"
```
or
```bash
z grep "search query"
```

#### Example
Suppose there exists a directory "notes/personal" and there are multiple notes that contain the word "hello". If you run the following command:

```bash
z search "hello"
```
the following output would be displayed:

```bash
[1] notes/personal/note1.txt: Hello World
[2] notes/personal/note2.txt: Hello friends!

Enter the number of the note you want to open or hit Enter to do nothing:
```

If the user inputs 1, the note located at /home/user/notes/personal/note1.txt would be opened in the text editor specified by the $EDITOR environment variable.

#### Environment variables
The function makes use of the following environment variable:

- NOTES_DIR: The environment variable $NOTES_DIR specifies the directory in which all the notebooks and notes are stored.
- EDITOR: The environment variable $EDITOR specifies the text editor to be used to open the selected note.

#### Output
The function outputs a list of all the notes that contain the search query, preceded by their index number in square brackets. The user is then prompted to input the index number of the note they want to open or hit Enter to do nothing. If a valid index number is entered, the selected note is opened in the text editor specified by the $EDITOR environment variable. If an invalid index number is entered or if no number is entered, an appropriate error message is displayed. If no notes are found that match the search query, a message saying "No results found for your search" is displayed. If the current notebook does not exist, a message saying "Notebook <notebook_name> does not exist." is displayed.


### Show Notebook Tree
This command is used to show a tree-like representation of the current notebook directory.

#### Usage
```bash
z tree
```

#### Example Output

```bash
show_notebook_tree
   |-Folder1
   |---Subfolder1
   |-----File1
   |-----File2
   |---File3
   |-Folder2
   |---File4
   |-File5
```

#### Environment Variables
- NOTES_DIR: The environment variable that specifies the path to the notes directory.


### Screenshot
This command captures a screenshot of a selected area and saves it to a specified directory. Optionally, it can also copy the path to the screenshot to the clipboard and wrap it inside markdown syntax in order to easily paste it into a markdown note.

#### Usage
```bash
z screencapture
```
or
```bash
z sc
```

#### Example

```bash
z screencapture screenshot.png
```

#### Output
This will capture a screenshot of a selected area and save it to the default "img" directory in the current notebook directory. The filename will be in the format of the value of $DEFAULT_SCREENSHOT_NAME_FORMAT and the extension will be in the format of the value of $DEFAULT_SCREENSHOT_EXTENSION. If a file with the same name already exists, the function will prompt the user to overwrite, dismiss, or add anyways (with a counter) and then execute the user's choice.


#### Environment variables
- NOTES_DIR: The path to the root directory where all the notebooks are stored.
- DEFAULT_SCREENSHOT_NAME_FORMAT: The default format for the filename of the screenshot.
- DEFAULT_SCREENSHOT_EXTENSION: The default extension for the screenshot.
- COPY_SCREENSHOT_PATH_TO_CLIPBOARD: A boolean value indicating whether to copy the path to the screenshot to the clipboard.
- CLIPBOARD_SCREENSHOT_PATH_WRAPPER: The wrapper for the path to the screenshot when copying to the clipboard.

## System Requirements
This note taking app was primarily designed for Mac and some features might not be compatible with Linux systems. Specifically, the screenshot function might not work as expected in Linux systems. To ensure maximum compatibility and usability, it is recommended to run the app on a Mac machine.
