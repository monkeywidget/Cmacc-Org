import os
import tiktoken

# Function to concatenate .pl files and calculate tokens
def concatenate_files():
    # Initialize a list to hold all file contents
    combined_content = []
    extension = ".php" # ".pl"
    # Iterate over all files ending in the extension in the current directory
    for filename in os.listdir():
        if filename.endswith(extension):
            with open(filename, 'r') as file:
                # Append file content with separator
                combined_content.append(file.read())
                combined_content.append("#" * 80)  # Adding separator
    
    # Combine all content into one string
    combined_text = "\n".join(combined_content)
    
    # filename = "prompt-combined.perl"
    filename = "prompt-combined.php"
    # Write the combined content
    with open(filename, "w") as combined_file:
        combined_file.write(combined_text)

    print(f"Wrote the combined content from {len(combined_content)} files to '{filename}'")

    return combined_text

def count_tokens(combined_text):
    # Load the encoding for GPT-4-32K (larger token context window)
    # used by 4o
    encoding = tiktoken.encoding_for_model("gpt-4-32k")
    
    # Tokenize the combined text and count the tokens
    num_tokens = len(encoding.encode(combined_text))
    
    # Emit the number of tokens to stdout
    print(f"Number of tokens in the concatenated file: {num_tokens}")

# Call the function
count_tokens(concatenate_files())
