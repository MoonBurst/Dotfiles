#!/usr/bin/env bash

# A script to manage Zsh history, including removing duplicates and
# interactively deleting entries.

# Check if the HISTFILE environment variable is set.
if [ -z "$HISTFILE" ]; then
    echo "Error: The HISTFILE environment variable is not set."
    echo "Please set it in your ~/.zshrc file to a valid history file path."
    echo "Example: export HISTFILE=\$HOME/.zsh_history"
    exit 1
fi

# Check if the history file exists.
if [ ! -f "$HISTFILE" ]; then
    echo "Error: History file not found at $HISTFILE."
    echo "Please verify the path or ensure you have a history file."
    exit 1
fi

# Function to remove duplicate lines from history.
function dedupe_history() {
    echo "Cleaning duplicate entries from: $HISTFILE"
    awk '!seen[$0]++' "$HISTFILE" > "$HISTFILE.tmp"
    if [ -s "$HISTFILE.tmp" ]; then
        mv "$HISTFILE.tmp" "$HISTFILE"
        echo "History file successfully cleaned of duplicate entries."
    else
        echo "Error: Could not create a temporary file. No changes were made."
        rm "$HISTFILE.tmp" 2>/dev/null
        exit 1
    fi
}

# Function for interactive history editing.
function interactive_history_editor() {
    echo "Entering interactive mode for history editing."
    echo "---"

    # Create a temporary file to store the modified history.
    temp_file=$(mktemp)

    # Display the history file with line numbers for the user to review.
    echo "Current history entries (with line numbers):"
    nl -w 3 "$HISTFILE"

    # Start the interactive loop.
    while true; do
        echo "---"
        read -p "Enter a line number to delete (from the bottom, e.g., '1' for the most recent), 'd' to delete the last entry, or 'q' to quit: " user_input
        
        # Check if the user wants to quit.
        if [[ "$user_input" == "q" ]]; then
            break
        # Check if the user wants to delete the last entry.
        elif [[ "$user_input" == "d" ]]; then
            sed '$d' "$HISTFILE" > "$temp_file"
            mv "$temp_file" "$HISTFILE"
            echo "Last entry deleted. Remaining entries:"
            nl -w 3 "$HISTFILE"
        
        # Handle a specific line number deletion from the bottom.
        elif [[ "$user_input" =~ ^[0-9]+$ ]]; then
            total_lines=$(wc -l < "$HISTFILE")
            num_to_delete=$((total_lines - user_input + 1))
            
            if [ "$num_to_delete" -le 0 ] || [ "$num_to_delete" -gt "$total_lines" ]; then
                echo "Invalid input. Please enter a valid number within the range of history entries."
                continue
            fi
            
            sed "${num_to_delete}d" "$HISTFILE" > "$temp_file"
            mv "$temp_file" "$HISTFILE"
            echo "Entry number $user_input (from the bottom) deleted. Remaining entries:"
            nl -w 3 "$HISTFILE"
        
        # Handle invalid input.
        else
            echo "Invalid input. Please enter a line number, 'd', or 'q'."
            continue
        fi
    done

    # Cleanup the temporary file.
    rm "$temp_file"
    echo "---"
    echo "History file saved successfully. Your changes are permanent."
}

# Main script logic: present a menu to the user.
echo "Zsh History Manager"
echo "---"
echo "1) Clean duplicate entries from history"
echo "2) Interactively edit/delete history entries"
echo "3) Clean (dedupe) and then Edit history"
echo "4) Quit"
echo "---"

read -p "Enter your choice: " choice

case "$choice" in
    1)
        dedupe_history
        ;;
    2)
        interactive_history_editor
        ;;
    3)
        dedupe_history
        interactive_history_editor
        ;;
    4)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Pause the terminal to prevent it from closing immediately.
read -p "Press Enter to exit..."
