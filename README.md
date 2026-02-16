# Inscribe

Turn a YouTube video into a **cleaned transcript**, then pipe it into **Fabric** (local LLM + prompt “patterns”) to extract summaries, insights, wisdom, etc.

This script supports **two transcription methods**:

1. **YouTube auto-subtitles** (fast, lower accuracy)
2. **OpenAI Whisper (local)** in **chunked mode**, with simple GPU-awareness (better accuracy, slower)

---

## Features

- ✅ Accepts a **YouTube URL** as input
- ✅ Interactive choice:
  - **Auto-subtitles** via `yt-dlp` (fast)
  - **Whisper local transcription** (more accurate)
- ✅ Whisper mode:
  - Downloads best audio
  - Detects **CUDA vs CPU**
  - If CUDA is available, checks **GPU VRAM** and adjusts **chunk length**
  - Transcribes audio in chunks (more stable for long videos)
- ✅ Cleans transcript with common term fixes (e.g., “avl tree” → “AVL tree”, “dfs” → “DFS”)
- ✅ Lists Fabric **patterns** and **local models** and runs:
  ```bash
  cat transcript_cleaned.txt | fabric --model <model> -sp <pattern>
