#!/usr/bin/env python3
import sys
import subprocess

def lookup(word):
    try:
        # Call dict using its absolute path
        output = subprocess.check_output(
            ["/usr/bin/dict", word],
            stderr=subprocess.STDOUT,
            timeout=10
        )
        return output.decode("utf-8")
    except subprocess.CalledProcessError:
        return f"No definition found for '{word}'."
    except Exception as e:
        return f"Error occurred: {str(e)}"

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: dict.py [word]")
    else:
        word = " ".join(sys.argv[1:])
        # Only output the first line of the definition for testing
        result = lookup(word)
        print(result.splitlines()[0] if result else "")
    sys.stdout.flush()
