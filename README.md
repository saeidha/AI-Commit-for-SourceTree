# AI Commit for SourceTree

A simple macOS script that integrates with SourceTree as a Custom Action. It uses the OpenRouter API to generate a Conventional Commit message based on your staged files and automatically copies it to your clipboard.

## Features

- **SourceTree Integration**: Adds a "Generate AI Commit" button directly to your SourceTree Custom Actions menu
- **Intelligent Commits**: Generates commit messages following the Conventional Commits standard (e.g., `feat:`, `fix:`, `refactor:`)
- **Powered by OpenRouter**: Easily customizable to use any model available on OpenRouter (like GPT-4o, Llama 3, Claude 3, etc.)
- **Auto-Copy**: The final commit message is automatically copied to your clipboard
- **System Notifications**: Provides macOS system notifications on success or failure

## Prerequisites

Before you begin, ensure you have the following:

- **macOS**: This script relies on `pbcopy` and `osascript`
- **SourceTree**: SourceTree for Mac
- **OpenRouter.ai API Key**: You'll need an API key from [OpenRouter.ai](https://openrouter.ai/)
- **Python 3**: Check if it's installed by running `python3 --version`
  - If not, we recommend installing it via Homebrew: `brew install python`
- **pip3**: This is Python's package installer, which typically comes with Python 3

## 🚀 Installation & Setup

Follow these steps to set up the action.

### Step 1: Get the Script

First, get the `generate_commit.sh` script onto your computer.

#### Method 1: Clone (Recommended)
Clone this repository to a permanent location on your machine (e.g., in a scripts folder)

Your script path will be: `/Users/your-name/scripts/AI-Commit-for-SourceTree//generate_commit.sh`

#### Method 2: Manual Copy
Download or copy the `generate_commit.sh` file and save it to a permanent location, for example:
`/Users/your-name/scripts/generate_commit.sh`

Remember the full path you choose for the next steps.

### Step 2: Install Python Dependency

This script uses the `requests` library to communicate with the API. Install it using `pip3`:

```bash
pip3 install requests
```

### Step 3: Make the Script Executable

**(Critical)** You must give the script permission to be executed. Open your terminal and run `chmod` on the file (replace the path with your own):

```bash
chmod +x /Users/your-name/scripts/generate_commit.sh
```

### Step 4: Configure the Python Path

1. Find the exact path to your `python3` installation. In your terminal, run:

```bash
which python3
```

You'll get an output like `/Library/Frameworks/Python.framework/Versions/3.12/bin/python3` or `/usr/local/bin/python3`. Copy this path.

2. Open the `generate_commit.sh` script in a text editor

3. Find the `PYTHON_PATH` variable (around line 10) and replace its value with the path you just copied

**Before:**
```bash
PYTHON_PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
```

**After (Example):**
```bash
PYTHON_PATH="/usr/local/bin/python3"
```

### Step 5: Configure SourceTree

1. Open SourceTree and go to **Preferences > Custom Actions**
2. Click **Add** to create a new action
3. Fill out the form as follows:
   - **Menu Caption**: `🤖 Generate AI Commit` (or any name you like)
   - **Script to run**: `/Users/your-name/scripts/generate_commit.sh` (or click `...` and select the file)
   - **Parameters**: Paste **ONLY** your OpenRouter API key here
4. Check the following boxes:
   - **Show Full Output**: This is very useful for debugging if something goes wrong
5. **(Optional) Keyboard Shortcut**: Set a convenient shortcut (e.g., `⌘ + ⇧ + C`)
6. Click **OK** to save the Custom Action

## 💡 How to Use

1. In your SourceTree repository, stage the files you want to commit
2. Run the Custom Action using your keyboard shortcut or by going to the **Actions > Custom Actions** menu
3. Wait a few seconds. A log window will appear, and you'll get a system notification when it's done
4. The AI-generated commit message is now on your clipboard
5. Click inside the commit message box in SourceTree and press `Cmd + V` to paste

## ⚠️ Troubleshooting

If you encounter an error, check the **Show Full Output** log in SourceTree.

### Error: "Couldn't posix_spawn: error 1"

This is a macOS security error ("Operation not permitted") that can happen with downloaded scripts.

**Solution 1**: Double-check that you ran `chmod +x` from Step 3.

**Solution 2**: If it still fails, run this command to remove the file's "quarantine" attribute (replace the path with your own):

```bash
xattr -c /Users/your-name/scripts/generate_commit.sh
```

### Error: "No such file or directory" (for python3)

This means the `PYTHON_PATH` in your `generate_commit.sh` script is wrong.

**Solution**: Run `which python3` in your terminal. Copy the exact output and paste it as the value for the `PYTHON_PATH` variable in the script, then save the file.

### Error: "No module named 'requests'"

This means the Python library was not installed correctly.

**Solution**: Run `pip3 install requests` in your terminal again.

## 🔧 Customization (Optional)

You can easily change the AI model used for generation.

1. Open `generate_commit.sh` in your text editor
2. Find the `MODEL_NAME` variable inside the Python script block (around line 36)
3. Replace the default model with any other model name from OpenRouter

**Example: Change from GPT-4o to Claude 3 Haiku**
```python
MODEL_NAME = "anthropic/claude-3-haiku-20240307"
```

## 📜 License

This project is licensed under the MIT License.
