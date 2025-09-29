#!/bin/bash
# save_claude_session.sh

SESSION_DATE=$(date +%Y-%m-%d_%H-%M)
SESSION_DIR="docs/session_logs"
SESSION_FILE="${SESSION_DIR}/session_${SESSION_DATE}.md"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Claude Code Session Saver ===${NC}"
echo ""

# Create directory if it doesn't exist
mkdir -p "$SESSION_DIR"

# Prompt for session topic
read -p "Session topic (e.g., 'copy stage requirements'): " TOPIC

echo -e "${GREEN}Step 1: Ask Claude Code to generate session summary${NC}"
echo ""
echo "Copy this prompt to Claude Code:"
echo "================================================"
cat << 'EOF'
Please create a comprehensive session summary document with the following structure:

# Session Summary: [Today's Date] - [Topic]

## Session Overview
- **Focus Area**: [Main topic of discussion]
- **Duration**: [Approximate time]
- **Status**: [Planning/Implementation/Review/Testing]

## Key Questions & Answers
### Questions Asked by Claude Code:
[List your questions organized by category]

### My Answers:
[Summarize key answers and decisions]

## Architecture & Design Proposals
### Proposed Solutions:
[Detail any architectural proposals]

### Design Decisions Made:
- [Decision 1] - Rationale: [why]
- [Decision 2] - Rationale: [why]

## Code Artifacts Created
- [ ] List any files created/modified
- [ ] Configuration schemas
- [ ] Class designs

## Technical Discussions
### Challenges Identified:
[Any technical challenges discussed]

### Solutions Proposed:
[Proposed approaches]

## Action Items
- [ ] Immediate next steps
- [ ] Future considerations
- [ ] Items requiring follow-up

## Important Context for Next Session
[Information needed for continuation]

## Notes & Observations
[Additional relevant notes]

Save this as session_summary.md
EOF
echo "================================================"
echo ""

# Wait for user to get the summary from Claude Code
read -p "Press Enter after Claude Code generates the summary and you've copied it..."

# Open editor for pasting
echo -e "${GREEN}Step 2: Paste the session summary${NC}"
echo "Opening editor..."
sleep 1

# Create template if editor opens empty
cat > "$SESSION_FILE" << EOF
# Session Summary: ${SESSION_DATE}

## Topic: ${TOPIC}

[Paste Claude Code's summary here]

EOF

# Open in editor (try code, then nano, then vi)
if command -v code &> /dev/null; then
    code --wait "$SESSION_FILE"
elif command -v nano &> /dev/null; then
    nano "$SESSION_FILE"
else
    vi "$SESSION_FILE"
fi

# Verify content was added
if grep -q "Paste Claude Code's summary here" "$SESSION_FILE"; then
    echo -e "${BLUE}No content detected. Skipping commit.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Step 3: Git operations${NC}"

# Show diff
echo "Review changes:"
git diff "$SESSION_FILE"
echo ""

# Confirm commit
read -p "Commit this session log? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping commit."
    exit 0
fi

# Commit
git add "$SESSION_FILE"
git commit -m "Session log: ${TOPIC} (${SESSION_DATE})"

# Ask about push
read -p "Push to GitHub? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main
    echo -e "${GREEN}✓ Session saved and pushed to GitHub${NC}"
else
    echo -e "${BLUE}Committed locally. Push manually when ready.${NC}"
fi

# Update development log
DEV_LOG="docs/DEVELOPMENT_LOG.md"
if [ -f "$DEV_LOG" ]; then
    echo "" >> "$DEV_LOG"
    echo "## Session: ${TOPIC} (${SESSION_DATE})" >> "$DEV_LOG"
    echo "[Full details](./session_logs/session_${SESSION_DATE}.md)" >> "$DEV_LOG"
    echo "" >> "$DEV_LOG"
    git add "$DEV_LOG"
    git commit -m "Update development log with session reference"
    echo -e "${GREEN}✓ Development log updated${NC}"
fi

echo ""
echo -e "${BLUE}Session saved: ${SESSION_FILE}${NC}"
