#!/bin/bash
# Launch persistent Chrome profile for 21st.dev access

PROFILE_DIR="$HOME/.openclaw/browser/21st-dev-profile"
mkdir -p "$PROFILE_DIR"

# Launch Chrome with persistent profile
google-chrome \
  --user-data-dir="$PROFILE_DIR" \
  --remote-debugging-port=19222 \
  --no-first-run \
  --no-default-browser-check \
  https://21st.dev &

echo "Chrome launched with 21st.dev profile"
echo "Profile directory: $PROFILE_DIR"
echo "Remote debugging port: 19222"
echo ""
echo "To sign in:"
echo "1. Click 'Sign in with Google' on 21st.dev"
echo "2. Complete authentication"
echo "3. Keep this Chrome window open for persistent access"
