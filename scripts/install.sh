#!/bin/sh
# Build Rosetta Prompt, install it to ~/Applications, sign it ad hoc, and link the skill.
# Optional: SDK=/path/to/MacOSX.sdk to pin the SDK the build uses.
set -eu
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

if [ -n "${SDK:-}" ]; then
    swift build -c release --sdk "$SDK"
else
    swift build -c release
fi

APP="$HOME/Applications/RosettaPrompt.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/RosettaPrompt "$APP/Contents/MacOS/RosettaPrompt"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key><string>Rosetta Prompt</string>
	<key>CFBundleExecutable</key><string>RosettaPrompt</string>
	<key>CFBundleIdentifier</key><string>io.github.firesmasher.rosettaprompt</string>
	<key>CFBundleName</key><string>Rosetta Prompt</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.6.1</string>
	<key>CFBundleVersion</key><string>1.6.1</string>
	<key>LSMinimumSystemVersion</key><string>13.0</string>
	<key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "Installed $APP"

# The app and the skill read the same folder: ~/.claude/skills/rosetta-prompt.
SKILL="$HOME/.claude/skills/rosetta-prompt"
mkdir -p "$HOME/.claude/skills"
if [ -L "$SKILL" ] || [ ! -e "$SKILL" ]; then
    ln -sfn "$ROOT/skill" "$SKILL"
    echo "Linked $SKILL -> $ROOT/skill"
else
    echo "$SKILL already exists and is not a link. Left it alone; copy $ROOT/skill there yourself."
fi
