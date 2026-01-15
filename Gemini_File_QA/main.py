import os
import google.generativeai as genai
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

def read_text_file(file_path):
    """Reads content from a text file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return None

def main():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "YOUR_API_KEY_HERE":
        print("Error: GEMINI_API_KEY not found in .env file. Please add your API key.")
        return

    genai.configure(api_key=api_key)
    
    # Select the model
    model = genai.GenerativeModel('gemini-pro')

    print("--- Gemini File Q&A Tool ---")
    file_path = input("Enter the path to the text file: ").strip().replace('"', '')

    if not os.path.exists(file_path):
        print("Error: File not found.")
        return

    file_content = read_text_file(file_path)
    if not file_content:
        return

    print("\nFile content loaded successfully. You can now ask questions about it.")
    print("Type 'exit' or 'quit' to stop.\n")

    # Start chat session
    chat = model.start_chat(history=[])
    
    # Initialize context with the file content
    # We'll send the file content as the first prompt to set the context
    initial_prompt = f"Here is the content of a file. Please answer my questions based on this content:\n\n{file_content}"
    
    try:
        response = chat.send_message(initial_prompt)
        # We don't necessarily need to print the initial response if it's just acknowledgment, 
        # but it's good to know it worked.
        # print(f"Gemini: {response.text}\n") 
    except Exception as e:
        print(f"Error initializing chat: {e}")
        return

    while True:
        user_input = input("You: ")
        if user_input.lower() in ['exit', 'quit']:
            break
        
        try:
            response = chat.send_message(user_input)
            print(f"Gemini: {response.text}\n")
        except Exception as e:
            print(f"Error getting response: {e}")

if __name__ == "__main__":
    main()
