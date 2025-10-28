#!/bin/bash

# --- 1. Read API Key from SourceTree Parameter ---
export OPENROUTER_API_KEY=$1

# --- 2. Define Python Path ---
# This is the path you found earlier
PYTHON_PATH=""

# --- 3. Get Staged Git Diff ---
STAGED_DIFF=$(git diff --staged)

if [ -z "$STAGED_DIFF" ]; then
    echo "No files are staged. Exiting." # <-- ADDED FOR DEBUGGING
    osascript -e 'display notification "No files are staged." with title "AI Commit"'
    exit 1
fi

# --- 4. Define Python Script in a Variable (DRY Principle) ---
# We define the Python script *once* to avoid duplication and bugs.
# read -r -d '' safely reads the multi-line script into the variable.
read -r -d '' PYTHON_SCRIPT <<'END_PYTHON'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# --- DEBUG: Check if script starts ---
import sys
# -----------------------------------

import os
import requests
import json

# --- Configuration ---
MODEL_NAME = "deepseek/deepseek-chat-v3.1:free"
OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"
API_KEY = os.environ.get("OPENROUTER_API_KEY")
SYSTEM_PROMPT = """
You are an expert assistant specializing in writing Git Commit Messages.
I will provide you with the output of `git diff --staged`.
Your task is to write an excellent commit message based on these changes.

Rules:
1.  The message must follow the "Conventional Commits" format. (e.g., `feat: ...`, `fix: ...`, `docs: ...`, `style: ...`, `refactor: ...`, `chore ...`)
2.  The message must be short, clear, and in English.
3.  The message should include a subject, and if necessary, a short body.
4.  Return *only* the final commit message.
5.  Do not include any extra text, explanations, preambles, or markdown formatting like ``` in your response. Just the raw commit message text.
"""
# --------------------

def get_commit_recommendation(diff_content):
    if not API_KEY:
        print("Error: OPENROUTER_API_KEY environment variable is not set.", file=sys.stderr)
        return None

    if not diff_content.strip():
        # No content to process
        return None

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    data = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Here are the staged changes:\n\n{diff_content}"}
        ],
        "temperature": 0.5,
        "max_tokens": 150
    }

    response_text = "No response" # For debugging
    try:
        response = requests.post(OPENROUTER_API_URL, headers=headers, data=json.dumps(data), timeout=15)
        response_text = response.text # Store response text for error logging
        
        # --- DEBUG PRINT ---
        print(f"DEBUG: API Status Code: {response.status_code}", file=sys.stderr)
        # --- END DEBUG ---

        response.raise_for_status() # Check for 4xx/5xx errors

        result = response.json()
        
        # --- DEBUG PRINT ---
        print(f"DEBUG: API JSON Response: {result}", file=sys.stderr)
        # --- END DEBUG ---

        message_content = result['choices'][0]['message']['content']
        
        # This is the line you correctly fixed (with standard ASCII spaces)
        cleaned_message = message_content.strip().strip("```").strip()
        
        # --- DEBUG PRINT ---
        if not cleaned_message:
            print("DEBUG: API returned a message, but it was empty after stripping.", file=sys.stderr)
        # --- END DEBUG ---
        
        return cleaned_message

    except requests.exceptions.RequestException as e:
        print(f"Error connecting to OpenRouter API: {e}", file=sys.stderr)
        print(f"DEBUG: Response text (if any): {response_text}", file=sys.stderr)
        return None
    except (KeyError, IndexError) as e:
        # --- MODIFIED FOR DEBUGGING ---
        print(f"Error: Could not parse API response (KeyError/IndexError: {e}).", file=sys.stderr)
        print(f"DEBUG: Full API Response Text: {response_text}", file=sys.stderr)
        return None
    except ImportError as e:
        print(f"Error: Missing Python module. Please install 'requests'.", file=sys.stderr)
        print(f"Details: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        print(f"DEBUG: Full API Response Text: {response_text}", file=sys.stderr)
        return None

if __name__ == "__main__":
    try:
        # --- MODIFIED: Read diff from command-line argument ---
        staged_diff = sys.argv[1]
    except IndexError:
        print("Error: No diff content provided as an argument.", file=sys.stderr)
        sys.exit(1)
        
    recommendation = get_commit_recommendation(staged_diff)
    if recommendation:
        print(recommendation)
END_PYTHON

# --- DEBUG: Check if Python script variable is loaded ---
echo "DEBUG: Bash: PYTHON_SCRIPT variable length: ${#PYTHON_SCRIPT}"
# ----------------------------------------------------

# --- 5. Run Python Script to Get Message ---
# --- MODIFIED: Pass STAGED_DIFF as a command-line argument ---
# We use a "here-string" (<<<) to pass the script, and the variable as an argument.
COMMIT_MSG=$($PYTHON_PATH - <<<"$PYTHON_SCRIPT" "$STAGED_DIFF")

# --- 6. Check Results and Notify User ---
if [ $? -eq 0 ] && [ -n "$COMMIT_MSG" ]; then
    # *** ADDED: Print the commit message to the log ***
    echo "--- AI Commit Message: ---"
    echo "$COMMIT_MSG"
    echo "--------------------------"
    
    # Success: Copy to clipboard and notify
    echo "$COMMIT_MSG" | pbcopy
    osascript -e 'display notification "AI commit message copied to clipboard!" with title "AI Commit"'
else
    # Failure: Re-run the script, but this time capture stderr (2>&1)
    # --- MODIFIED: Pass STAGED_DIFF as a command-line argument ---
    ERROR_MSG=$($PYTHON_PATH - <<<"$PYTHON_SCRIPT" "$STAGED_DIFF" 2>&1)
    
    # --- ADDED FOR DEBUGGING ---
    echo "--- ERROR ---"
    echo "An error occurred. The commit message was likely empty."
    echo "Captured Error/Output:"
    echo "$ERROR_MSG"
    echo "---------------"
    # ---------------------------
    
    if [ -z "$ERROR_MSG" ]; then
        ERROR_MSG="Unknown error generating message."
    fi
    
    # Show the error in a notification
    # We must escape quotes for osascript's -e flag
    ERROR_MSG_ESCAPED=$(echo "$ERROR_MSG" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    osascript -e "display notification \"$ERROR_MSG_ESCAPED\" with title \"AI Commit Error\""
fi

