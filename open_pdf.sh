#!/bin/bash

# Path to the PDF file with instructions
PDF_PATH="/path/to/your/instructions.pdf"

# Check if the PDF file exists
if [ -f "$PDF_PATH" ]; then
  # Open the PDF using the default PDF viewer
  open "$PDF_PATH"
else
  echo "PDF file not found at: $PDF_PATH"
fi