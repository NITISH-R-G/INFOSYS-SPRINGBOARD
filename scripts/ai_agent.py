import os
import json
import subprocess
from pathlib import Path

def get_git_diff():
    try:
        # Get the diff of the latest commit
        result = subprocess.run(['git', 'show', '--stat'], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout
        return "No recent git changes detected."
    except Exception as e:
        return f"Error retrieving git diff: {e}"

def generate_ai_summary(diff_text):
    """
    Attempts to use an AI API to summarize changes.
    Falls back to a basic heuristic summary if no API key is present.
    """
    openai_api_key = os.environ.get("OPENAI_API_KEY")

    if openai_api_key:
        try:
            import urllib.request
            import urllib.error
            import json

            url = "https://api.openai.com/v1/chat/completions"
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {openai_api_key}"
            }
            data = {
                "model": "gpt-3.5-turbo",
                "messages": [
                    {"role": "system", "content": "You are an AI Documentation Agent. Summarize the following git changes for a release note."},
                    {"role": "user", "content": diff_text}
                ]
            }

            req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers)
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                return result['choices'][0]['message']['content']
        except Exception as e:
            print(f"AI summarization failed (API error). Falling back to heuristics. Error: {e}")
    else:
        print("No OPENAI_API_KEY found. Using heuristic summarization.")

    # Heuristic fallback
    lines = diff_text.split('\n')
    changed_files = [line.strip() for line in lines if '|' in line]

    if not changed_files:
        return "Recent changes: Minor updates and routine maintenance."

    summary = "### Auto-Generated Change Summary\n\n"

    # Cap the number of files logged in the changelog to avoid spamming
    max_files = 10
    displayed_files = changed_files[:max_files]

    summary += "The following files were modified in the recent update:\n"
    for file in displayed_files:
        summary += f"- `{file.split('|')[0].strip()}`\n"

    if len(changed_files) > max_files:
        summary += f"- ... and {len(changed_files) - max_files} more files.\n"

    summary += "\n*Note: This summary was generated automatically by the AI Documentation Agent fallback heuristic.*"
    return summary

def update_changelog(summary):
    changelog_path = Path("CHANGELOG.md")

    existing_content = ""
    if changelog_path.exists():
        with open(changelog_path, 'r', encoding='utf-8') as f:
            existing_content = f.read()

    import datetime
    today = datetime.datetime.now().strftime("%Y-%m-%d")

    new_entry = f"## [{today}] - Automated Update\n\n{summary}\n\n---\n\n"

    with open(changelog_path, 'w', encoding='utf-8') as f:
        f.write(new_entry + existing_content)

    print(f"Updated CHANGELOG.md with recent changes.")

if __name__ == "__main__":
    print("AI Documentation Agent starting...")
    diff = get_git_diff()
    summary = generate_ai_summary(diff)
    update_changelog(summary)
    print("AI Documentation Agent finished.")
