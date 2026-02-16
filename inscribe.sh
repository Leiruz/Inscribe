#!/usr/bin/env bash
# inscribe.sh
# Usage: ./inscribe.sh "YOUTUBE_URL"

set -euo pipefail

YOUTUBE_URL="${1:-}"
if [[ -z "$YOUTUBE_URL" ]]; then
  echo "Usage: $0 <youtube_url>"
  exit 1
fi

# Defaults
WHISPER_MODEL_DEFAULT="medium"
FABRIC_MODEL_DEFAULT="llama3.1:8b-instruct-q4_K_M"
FABRIC_PATTERN_DEFAULT="extract_wisdom"
WORKDIR="${HOME}/.local/tmp/inscribe"
mkdir -p "$WORKDIR"
rm -f "$WORKDIR"/*

TRANSCRIPT_RAW="$WORKDIR/transcript_raw.txt"
TRANSCRIPT_CLEAN="$WORKDIR/transcript_cleaned.txt"
WHISPER_LOG="$WORKDIR/whisper.log"

echo "Working dir: $WORKDIR"
rm -f "$TRANSCRIPT_RAW" "$TRANSCRIPT_CLEAN" "$WHISPER_LOG"

# Choose transcription method
echo
echo "Choose transcription method:"
echo "  1) YouTube auto-subtitles (fast, may have errors)"
echo "  2) Whisper (higher accuracy, uses local model; may use GPU)"
read -rp "Enter 1 or 2 [default: 2]: " METHOD
METHOD=${METHOD:-2}

# helper: detect GPU via torch
detect_gpu() {
  python3 - <<'PY' 2>/dev/null
import sys
try:
    import torch
    sys.stdout.write("cuda" if torch.cuda.is_available() else "cpu")
except Exception:
    sys.stdout.write("cpu")
PY
}

if [[ "$METHOD" == "2" ]]; then
  echo
  echo "Downloading audio (bestaudio) from YouTube..."
  yt-dlp -f bestaudio -o "$WORKDIR/audio.%(ext)s" "$YOUTUBE_URL"
  AUDIO_FILE_PATH=$(ls "$WORKDIR"/audio.* 2>/dev/null | head -n 1 || true)
  if [[ -z "$AUDIO_FILE_PATH" ]]; then
    echo "❌ Failed to download audio. Exiting."
    exit 1
  fi
  echo "Downloaded audio: $AUDIO_FILE_PATH"

  read -rp "Enter Whisper model to use [default: $WHISPER_MODEL_DEFAULT]: " WHISPER_MODEL
  WHISPER_MODEL=${WHISPER_MODEL:-$WHISPER_MODEL_DEFAULT}

  DEVICE="$(detect_gpu)"
  echo "Whisper device: $DEVICE"

  echo "Running Whisper in GPU-aware chunked mode..."
  python3 - <<PYTHON
import os, torch, whisper
from pydub import AudioSegment
from tqdm import tqdm

workdir = "${WORKDIR}"
audio_path = "${AUDIO_FILE_PATH}"
model_name = "${WHISPER_MODEL}"
device = "${DEVICE}"
transcript_file = "${TRANSCRIPT_RAW}"

model = whisper.load_model(model_name, device=device)

# Detect GPU VRAM
if device == "cuda":
    import subprocess
    result = subprocess.run(["nvidia-smi", "--query-gpu=memory.total", "--format=csv,nounits,noheader"], capture_output=True, text=True)
    total_vram = int(result.stdout.strip().split("\n")[0])
else:
    total_vram = 0

# Decide chunk length (ms) based on model size and VRAM
model_chunk_map = {"small": 20*60*1000, "medium": 15*60*1000, "large": 8*60*1000}
base_chunk = model_chunk_map.get(model_name.lower(), 10*60*1000)
if device == "cuda" and total_vram < 8000:
    base_chunk = int(base_chunk * total_vram / 8000)

print(f"Detected GPU VRAM: {total_vram} MB, chunk length: {base_chunk/1000/60:.1f} minutes")

audio = AudioSegment.from_file(audio_path)
chunks = [audio[i:i+base_chunk] for i in range(0, len(audio), base_chunk)]

with open(transcript_file, "w", encoding="utf-8") as f:
    for i, chunk in enumerate(tqdm(chunks, desc="Transcribing chunks")):
        chunk_path = os.path.join(workdir, f"chunk_{i}.wav")
        chunk.export(chunk_path, format="wav")
        result = model.transcribe(chunk_path, language="English")
        f.write(result["text"] + "\n")
        os.remove(chunk_path)
PYTHON

  rm -f "$AUDIO_FILE_PATH"

else
  echo
  echo "Downloading YouTube auto-subtitles..."
  yt-dlp --write-auto-sub --sub-lang en --skip-download -o "$WORKDIR/video.%(ext)s" "$YOUTUBE_URL"

  VTT_FILE=$(ls "$WORKDIR"/*.vtt 2>/dev/null | head -n 1 || true)
  if [[ -n "$VTT_FILE" ]]; then
    ffmpeg -i "$VTT_FILE" "$WORKDIR/$(basename "$VTT_FILE" .vtt).srt" -y >/dev/null 2>&1 || true
    rm -f "$VTT_FILE"
  fi

  SRT_FILE=$(ls "$WORKDIR"/*.srt 2>/dev/null | head -n 1 || true)
  if [[ -z "$SRT_FILE" ]]; then
    echo "❌ No subtitles found in $WORKDIR. Exiting."
    exit 1
  fi

  awk 'BEGIN{ORS="\n\n"} /^[0-9]+$/{getline; getline; print $0}' "$SRT_FILE" | sed '/^[[:space:]]*$/d' > "$TRANSCRIPT_RAW"
  echo "Auto-subtitles transcript saved to $TRANSCRIPT_RAW"
fi

# Clean transcript
awk '
{
  gsub(/avl[[:space:]]?tree/i, "AVL tree")
  gsub(/\bbst\b/i, "BST")
  gsub(/\bbsp\b/i, "BSP tree")
  gsub(/hash[[:space:]]?table/i, "hash table")
  gsub(/linked[[:space:]]?list/i, "linked list")
  gsub(/binary[[:space:]]?search[[:space:]]?tree/i, "binary search tree")
  gsub(/\bheap\b/i, "heap")
  gsub(/\bgraph\b/i, "graph")
  gsub(/\bqueue\b/i, "queue")
  gsub(/\bstack\b/i, "stack")
  gsub(/\bdijkstra\b/i, "Dijkstra")
  gsub(/\bbellman-?ford\b/i, "Bellman-Ford")
  gsub(/\bdfs\b/i, "DFS")
  gsub(/\bbfs\b/i, "BFS")
  print
}' "$TRANSCRIPT_RAW" > "$TRANSCRIPT_CLEAN"

echo "Cleaned transcript ready: $TRANSCRIPT_CLEAN"

# Fabric
echo
echo "Available Fabric patterns:"
fabric --listpatterns
read -rp "Enter Fabric pattern to use [default: $FABRIC_PATTERN_DEFAULT]: " FABRIC_PATTERN
FABRIC_PATTERN=${FABRIC_PATTERN:-$FABRIC_PATTERN_DEFAULT}

echo
echo "Available local Fabric models:"
fabric --listmodels
read -rp "Enter local Fabric model to use [default: $FABRIC_MODEL_DEFAULT]: " FABRIC_MODEL
FABRIC_MODEL=${FABRIC_MODEL:-$FABRIC_MODEL_DEFAULT}

echo
read -rp "Run Fabric with pattern '$FABRIC_PATTERN' and model '$FABRIC_MODEL'? (Y/n): " CONF
CONF=${CONF:-Y}
if [[ ! "$CONF" =~ ^[Yy] ]]; then
  echo "Aborted by user."
  exit 0
fi

cat "$TRANSCRIPT_CLEAN" | fabric --model "$FABRIC_MODEL" -sp "$FABRIC_PATTERN"

echo "Done. Clean transcript: $TRANSCRIPT_CLEAN"
if ls "$WORKDIR"/*.srt >/dev/null 2>&1; then
  echo "Whisper SRT files (if any) are in: $WORKDIR"
fi

