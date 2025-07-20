#!/bin/bash

# Setup script for remote repository and auto-push

echo "🚀 Setting up remote repository for auto-push..."

# Check if remote already exists
if git remote -v | grep -q origin; then
    echo "✅ Remote 'origin' already configured:"
    git remote -v
    echo ""
    echo "💡 To change the remote URL, use:"
    echo "   git remote set-url origin <new-repository-url>"
    exit 0
fi

# Get repository URL from user
echo "📝 Please enter your remote repository URL (e.g., https://github.com/username/repo.git):"
read -r REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "❌ No repository URL provided"
    exit 1
fi

# Add remote
echo "🔗 Adding remote repository..."
git remote add origin "$REPO_URL"

# Verify remote was added
if git remote -v | grep -q origin; then
    echo "✅ Remote 'origin' added successfully:"
    git remote -v
    echo ""
    echo "🚀 Now you can push your code:"
    echo "   git push -u origin main"
    echo ""
    echo "💡 After the first push, all future commits will automatically push to remote!"
else
    echo "❌ Failed to add remote repository"
    exit 1
fi 