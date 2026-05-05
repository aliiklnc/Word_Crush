import fitz

doc = fitz.open(r'c:\Users\alikl\OneDrive\Desktop\Yazlab2-3\Yazlab 2- Proje 2.pdf')
text = '\n'.join([page.get_text() for page in doc])
with open(r'c:\Users\alikl\OneDrive\Desktop\Yazlab2-3\pdf_text.txt', 'w', encoding='utf-8') as f:
    f.write(text)
print("Done")
