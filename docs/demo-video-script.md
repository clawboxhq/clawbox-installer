# ClawBox Demo Video Script
**Duration:** 2 minutes
**Platform:** YouTube, embedded in README
**Audience:** Security-focused developers

---

## Scene 1: The Problem (15 seconds)

**Visual:** Terminal window showing cloud AI tool

**Narrator:**
"Cloud AI tools send your code to external servers. And when AI generates code, you don't know if it's safe to run."

**Action:**
- Show GitHub Copilot or ChatGPT sending code to cloud
- Show warning message about data privacy
- Show concern about running unknown code

**Text Overlay:**
"Your code. Their servers. Their control."

---

## Scene 2: The Solution (10 seconds)

**Visual:** ClawBox logo animation

**Narrator:**
"ClawBox runs 100% locally. And executes code in a secure sandbox."

**Action:**
- ClawBox logo appears
- Shield icon animates around it
- Show "100% Local" badge

**Text Overlay:**
"ClawBox - Run AI Locally. Execute Code Safely."

---

## Scene 3: Installation (25 seconds)

**Visual:** Terminal window, macOS/Linux

**Narrator:**
"One command installs everything."

**Action:**
- Type: `curl -fsSL https://clawbox.ai/install | bash`
- Show installation progress:
  ```
  🦞 ClawBox Installer v0.1.0
  
  Platform: darwin
  Architecture: arm64
  
  Downloading ClawBox...
  ✓ Installed to: /usr/local/bin/clawbox
  
  Detecting LLM providers...
  ✓ Detected ollama
  ✓ Created configuration
  
  🎉 Installation Complete!
  ```

**Text Overlay:**
"One command. Ready to use."

---

## Scene 4: Quick Verification (15 seconds)

**Visual:** Terminal window

**Narrator:**
"Verify everything works with built-in diagnostics."

**Action:**
- Type: `clawbox version`
- Show output: `clawbox version 0.1.0`
- Type: `clawbox doctor`
- Show output with all checkmarks:
  ```
  ✓ clawbox binary found
  ✓ Configuration valid
  ✓ Ollama detected
  ✓ Docker available
  ✓ All checks passed
  ```

**Text Overlay:**
"Health checks built-in."

---

## Scene 5: Using ClawBox (30 seconds)

**Visual:** Terminal window

**Narrator:**
"Create a sandbox and start coding securely."

**Action:**
- Type: `clawbox sandbox create dev --provider ollama --model llama3.2`
- Show: `✓ Created sandbox: dev`
- Type: `clawbox sandbox start dev`
- Show:
  ```
  ✓ Started sandbox: dev
  ✓ Model: llama3.2
  ✓ Port: 18789
  
  Ready! Connect with: clawbox sandbox connect dev
  ```
- Type: `clawbox sandbox connect dev`
- Show AI generating code

**Text Overlay:**
"Isolated execution. Your system protected."

---

## Scene 6: Network Security (15 seconds)

**Visual:** Terminal window

**Narrator:**
"Control what endpoints your AI can access."

**Action:**
- Type: `clawbox policy presets`
- Show list of presets
- Type: `clawbox policy add dev github`
- Show: `✓ Added policy 'github' to sandbox 'dev'`

**Text Overlay:**
"Block by default. Allow explicitly."

---

## Scene 7: Comparison (10 seconds)

**Visual:** Comparison table graphic

**Narrator:**
"Unlike other local AI tools, ClawBox provides sandboxed execution and network policies."

**Action:**
- Show comparison table:
  | Feature | ClawBox | Ollama | LM Studio |
  |---------|---------|--------|-----------|
  | Sandboxed execution | ✅ | ❌ | ❌ |
  | Network policies | ✅ | ❌ | ❌ |

**Text Overlay:**
"Security other tools don't have."

---

## Scene 8: Wrap-up (10 seconds)

**Visual:** ClawBox logo, download buttons

**Narrator:**
"ClawBox. Run AI locally. Execute code safely."

**Action:**
- Show ClawBox logo
- Show download links:
  - macOS: clawbox.ai/install
  - Windows: clawbox.ai/install.ps1
  - GitHub: github.com/clawboxhq/clawbox-installer

**Text Overlay:**
"Get started: clawbox.ai"

---

## Production Notes

### Technical Setup
- **Screen Recording:** Use native macOS screen recording or OBS Studio
- **Resolution:** 1920x1080 (16:9) or 2560x1440 for YouTube
- **Frame Rate:** 30fps minimum, 60fps preferred
- **Font:** Terminal should use clear, readable font (SF Mono, JetBrains Mono)

### Audio
- **Microphone:** Use USB microphone for clean voice-over
- **Environment:** Record in quiet space
- **Background Music:** Optional, subtle ambient track

### Export
- **Format:** MP4 (H.264)
- **Quality:** 1080p minimum
- **File Size Target:** Under 50MB for easy embedding

### Distribution
- **YouTube:** Upload as unlisted, embed in README
- **Thumbnail:** ClawBox logo + "Secure Local AI" text
- **Title:** "ClawBox - Secure Sandbox for AI-Generated Code (2 min demo)"

---

## Alternative Short Version (30 seconds)

For social media (Twitter, LinkedIn):

```
[0-5s]  Problem: Cloud AI sends your code to servers
[5-10s] Solution: ClawBox runs 100% locally
[10-20s] Demo: One command install
[20-25s] Feature: Sandboxed code execution
[25-30s] CTA: clawbox.ai
```
