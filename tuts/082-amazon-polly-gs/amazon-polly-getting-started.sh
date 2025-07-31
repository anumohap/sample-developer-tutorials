#!/bin/bash

# Amazon Polly Getting Started Script
# This script demonstrates how to use Amazon Polly with the AWS CLI

# Set up logging
LOG_FILE="polly-tutorial.log"
echo "Starting Amazon Polly tutorial at $(date)" > "$LOG_FILE"

# Function to log commands and their output
log_cmd() {
    echo "Running: $1" | tee -a "$LOG_FILE"
    eval "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check for errors
check_error() {
    if echo "$1" | grep -i "error" > /dev/null; then
        echo "ERROR detected in output. Exiting script." | tee -a "$LOG_FILE"
        echo "$1" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Function to handle errors and cleanup
handle_error() {
    echo "Error occurred. Attempting cleanup..." | tee -a "$LOG_FILE"
    cleanup
    exit 1
}

# Function to clean up resources
cleanup() {
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "CLEANUP PROCESS" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    
    # Delete lexicon if it exists
    if [ -n "$LEXICON_NAME" ]; then
        echo "Deleting lexicon: $LEXICON_NAME" | tee -a "$LOG_FILE"
        log_cmd "aws polly delete-lexicon --name $LEXICON_NAME"
    fi
    
    echo "Cleanup complete." | tee -a "$LOG_FILE"
}

# Trap errors
trap 'handle_error' ERR

# Step 1: Verify Amazon Polly is available
echo "Step 1: Verifying Amazon Polly availability" | tee -a "$LOG_FILE"
POLLY_CHECK=$(aws polly help 2>&1)
if echo "$POLLY_CHECK" | grep -i "not.*found\|invalid\|error" > /dev/null; then
    echo "Amazon Polly is not available in your AWS CLI installation." | tee -a "$LOG_FILE"
    echo "Please update your AWS CLI to the latest version." | tee -a "$LOG_FILE"
    exit 1
else
    echo "Amazon Polly is available. Proceeding with tutorial." | tee -a "$LOG_FILE"
fi

# Step 2: List available voices
echo "" | tee -a "$LOG_FILE"
echo "Step 2: Listing available voices" | tee -a "$LOG_FILE"
log_cmd "aws polly describe-voices --language-code en-US --output text --query 'Voices[0:3].[Id, LanguageCode, Gender]'"

# Step 3: Basic text-to-speech conversion
echo "" | tee -a "$LOG_FILE"
echo "Step 3: Converting text to speech" | tee -a "$LOG_FILE"
log_cmd "aws polly synthesize-speech --output-format mp3 --voice-id Joanna --text \"Hello, welcome to Amazon Polly. This is a sample text to speech conversion.\" output.mp3"

if [ -f "output.mp3" ]; then
    echo "Successfully created output.mp3 file." | tee -a "$LOG_FILE"
    echo "You can play this file with your preferred audio player." | tee -a "$LOG_FILE"
else
    echo "Failed to create output.mp3 file." | tee -a "$LOG_FILE"
    exit 1
fi

# Step 4: Using SSML for enhanced speech
echo "" | tee -a "$LOG_FILE"
echo "Step 4: Using SSML for enhanced speech" | tee -a "$LOG_FILE"
log_cmd "aws polly synthesize-speech --output-format mp3 --voice-id Matthew --text-type ssml --text \"<speak>Hello! <break time='1s'/> This is a sample of <emphasis>SSML enhanced speech</emphasis>.</speak>\" ssml-output.mp3"

if [ -f "ssml-output.mp3" ]; then
    echo "Successfully created ssml-output.mp3 file." | tee -a "$LOG_FILE"
    echo "You can play this file with your preferred audio player." | tee -a "$LOG_FILE"
else
    echo "Failed to create ssml-output.mp3 file." | tee -a "$LOG_FILE"
    exit 1
fi

# Step 5: Working with lexicons
echo "" | tee -a "$LOG_FILE"
echo "Step 5: Working with lexicons" | tee -a "$LOG_FILE"

# Generate a random identifier for the lexicon (max 20 chars, alphanumeric only)
LEXICON_NAME="example$(openssl rand -hex 6)"
echo "Using lexicon name: $LEXICON_NAME" | tee -a "$LOG_FILE"

# Create a lexicon file
echo "Creating lexicon file..." | tee -a "$LOG_FILE"
cat > example.pls << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<lexicon version="1.0" 
      xmlns="http://www.w3.org/2005/01/pronunciation-lexicon"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://www.w3.org/2005/01/pronunciation-lexicon 
        http://www.w3.org/TR/2007/CR-pronunciation-lexicon-20071212/pls.xsd"
      alphabet="ipa" 
      xml:lang="en-US">
  <lexeme>
    <grapheme>AWS</grapheme>
    <alias>Amazon Web Services</alias>
  </lexeme>
</lexicon>
EOF

# Upload the lexicon
echo "Uploading lexicon..." | tee -a "$LOG_FILE"
log_cmd "aws polly put-lexicon --name $LEXICON_NAME --content file://example.pls"

# List available lexicons
echo "Listing available lexicons..." | tee -a "$LOG_FILE"
log_cmd "aws polly list-lexicons --output text --query 'Lexicons[*].[Name]'"

# Get details about the lexicon
echo "Getting details about the lexicon..." | tee -a "$LOG_FILE"
log_cmd "aws polly get-lexicon --name $LEXICON_NAME --output text --query 'Lexicon.Name'"

# Use the lexicon when synthesizing speech
echo "Using the lexicon for speech synthesis..." | tee -a "$LOG_FILE"
log_cmd "aws polly synthesize-speech --output-format mp3 --voice-id Joanna --lexicon-names $LEXICON_NAME --text \"I work with AWS every day.\" lexicon-output.mp3"

if [ -f "lexicon-output.mp3" ]; then
    echo "Successfully created lexicon-output.mp3 file." | tee -a "$LOG_FILE"
    echo "You can play this file with your preferred audio player." | tee -a "$LOG_FILE"
else
    echo "Failed to create lexicon-output.mp3 file." | tee -a "$LOG_FILE"
    exit 1
fi

# Summary of created resources
echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "TUTORIAL SUMMARY" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "Created resources:" | tee -a "$LOG_FILE"
echo "1. Lexicon: $LEXICON_NAME" | tee -a "$LOG_FILE"
echo "2. Audio files:" | tee -a "$LOG_FILE"
echo "   - output.mp3" | tee -a "$LOG_FILE"
echo "   - ssml-output.mp3" | tee -a "$LOG_FILE"
echo "   - lexicon-output.mp3" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Prompt for cleanup
echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "CLEANUP CONFIRMATION" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "Do you want to clean up all created resources? (y/n): " | tee -a "$LOG_FILE"
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    cleanup
else
    echo "Skipping cleanup. Resources will remain in your account." | tee -a "$LOG_FILE"
    echo "To manually delete the lexicon later, run:" | tee -a "$LOG_FILE"
    echo "aws polly delete-lexicon --name $LEXICON_NAME" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Tutorial completed successfully!" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
