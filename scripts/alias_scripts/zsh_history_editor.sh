#!/bin/bash

# A script to interactively view and edit the Zsh history file.

# Check if the HISTFILE variable is set.
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

echo "Found Zsh history file at: $HISTFILE"
echo "---"

# Create a temporary file to store the modified history.
temp_file=$(mktemp)

# Display the history file with line numbers for the user to review.
echo "Current history entries (with line numbers):"
nl -w 3 "$HISTFILE"

# Start the interactive loop.
while true; do
    echo "---"
    read -p "Enter the line number to delete, 'd' to delete the last entry, a negative number to delete from the end (e.g., -5), or 'q' to quit and save changes: " user_input
    
    # Check if the user wants to quit.
    if [[ "$user_input" == "q" ]]; then
        break
    # Check if the user wants to delete the last entry.
    elif [[ "$user_input" == "d" ]]; then
        # Use sed to delete the last line.
        sed '$d' "$HISTFILE" > "$temp_file"
        
        # Move the temporary file back to the original history file.
        mv "$temp_file" "$HISTFILE"

        echo "Last entry deleted. Remaining entries:"
        nl -w 3 "$HISTFILE"

    # Handle deleting a specific number of lines from the end.
    elif [[ "$user_input" =~ ^-[0-9]+$ ]]; then
        # Get the number of lines to delete (remove the leading '-').
        num_lines_to_delete=${user_input:1}
        
        # Check if the number of lines is valid.
        if [ "$num_lines_to_delete" -eq 0 ]; then
            echo "Invalid input. Please enter a number greater than 0."
            continue
        fi

        # Use sed to delete a range of lines from the end.
        head -n "-${num_lines_to_delete}" "$HISTFILE" > "$temp_file"
        
        # Move the temporary file back to the original history file.
        mv "$temp_file" "$HISTFILE"
        
        echo "$num_lines_to_delete entries deleted from the end. Remaining entries:"
        nl -w 3 "$HISTFILE"

    # Handle a specific line number deletion.
    elif [[ "$user_input" =~ ^[0-9]+$ ]]; then
        # Use sed to delete the specified line.
        sed "${user_input}d" "$HISTFILE" > "$temp_file"

        # Move the temporary file back to the original history file.
        mv "$temp_file" "$HISTFILE"

        echo "Line $user_input deleted. Remaining entries:"
        nl -w 3 "$HISTFILE"
    
    # Handle invalid input.
    else
        echo "Invalid input. Please enter a line number, 'd', a negative number, or 'q'."
        continue
    fi
done

# Cleanup the temporary file.
rm "$temp_file"

echo "---"
echo "History file saved successfully. Your changes are permanent."
