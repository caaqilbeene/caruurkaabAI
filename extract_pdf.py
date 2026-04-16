import sys
from PyPDF2 import PdfReader

def extract(pdf_path):
    reader = PdfReader(pdf_path)
    total_pages = len(reader.pages)
    print(f"Total pages: {total_pages}")
    
    # Extract first 30 pages to see the table of contents and first chapter
    for i in range(min(30, total_pages)):
        text = reader.pages[i].extract_text()
        if text.strip():
            print(f"--- Page {i+1} ---")
            print(text.strip())

if __name__ == "__main__":
    extract(sys.argv[1])
