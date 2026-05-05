import json
import os
import glob

def to_upper_tr(word):
    # Turkish uppercase conversion
    translation_table = str.maketrans("abcçdefgğhıijklmnoöprsştuüvyz", "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ")
    return word.translate(translation_table)

input_dir = r'c:\Users\alikl\OneDrive\Desktop\Yazlab2-3\Turkce-Kelime-Listesi-master'
output_file = r'c:\Users\alikl\OneDrive\Desktop\Yazlab2-3\word_crush\assets\words.json'

valid_words = set()

# Find all .list files in the directory
list_files = glob.glob(os.path.join(input_dir, '*.list'))

for file_path in list_files:
    print(f"Processing {os.path.basename(file_path)}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            word = line.strip()
            # Ignore short words and words with spaces, hyphens, or apostrophes
            if len(word) >= 3 and " " not in word and "-" not in word and "'" not in word:
                upper_word = to_upper_tr(word.lower())
                valid_words.add(upper_word)

# Convert to list and sort
word_list = sorted(list(valid_words))

# Create json structure
data = {
    "words": word_list
}

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Successfully processed {len(list_files)} files.")
print(f"Total valid words added to dictionary: {len(word_list)}")
