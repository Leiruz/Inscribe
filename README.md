# Inscribe

<img width="1231" height="668" alt="image" src="https://github.com/user-attachments/assets/eff572b1-2948-4b73-92c1-fdfcc7e88396" />


Turn any YouTube video into a clean transcript, then run an AI “pattern” over it (e.g., **extract key ideas / wisdom**) using **Fabric**.

  

`inscribe.sh` is an interactive Bash script that:

  

1. Takes a YouTube URL

2. Transcribes it via either:

   - **YouTube auto-subtitles** (fast, lower accuracy), or

   - **Local Whisper** (slower, higher accuracy; can use GPU)

3. Cleans up common CS/DS terms in the transcript (e.g., “avl tree” → “AVL tree”)

4. Pipes the cleaned transcript into **Fabric** using a selected **pattern** and **model**

  

Fabric is an open-source framework for “augmenting humans using AI,” centered around reusable prompts called *patterns*. ([Fabric By Daniel Miessler](https://github.com/danielmiessler/Fabric))

  

---

  

## Table of contents

  

- [Features](#features)

- [How it works](#how-it-works)

- [Requirements](#requirements)

  - [Software dependencies](#software-dependencies)

  - [Hardware dependencies](#hardware-dependencies)

- [Installation](#installation)

  - [Ubuntu/Debian](#ubuntudebian)

  - [macOS](#macos)

  - [Windows](#windows)

- [Usage](#usage)

- [Sample output](#sample-output)

- [Outputs](#outputs)

- [Configuration](#configuration)

- [Troubleshooting](#troubleshooting)

- [Security & legal notes](#security--legal-notes)

- [Contributing](#contributing)

- [License](#license)

  

---

  

## Features

  

- **Two transcription modes**

  - YouTube auto-subtitles (quick)

  - Local Whisper (better quality; GPU-aware)

- **GPU-aware chunking for Whisper**

  - Detects CUDA availability via PyTorch

  - If NVIDIA GPU is present, estimates VRAM using `nvidia-smi` and adjusts chunk size

- **Transcript cleanup**

  - Normalizes common algorithm/data-structure terms (AVL, BST, BFS/DFS, Dijkstra, etc.)

- **Fabric integration**

  - Lists available patterns and models

  - Runs Fabric with `--stream` + selected pattern/model (via `-sp` and `--model`)

  

Fabric’s CLI supports listing patterns/models and selecting patterns/models from the command line. ([Fabric Usage Guide](https://github.gg/wiki/danielmiessler/Fabric/cli-usage-guide))

  

---

  

## How it works

  

High-level pipeline:

  

1. **Download transcript source**

   - *Method 1:* Download English auto-subs via `yt-dlp`, convert `.vtt → .srt` using `ffmpeg`, extract text

   - *Method 2:* Download best audio via `yt-dlp`, transcribe locally with Whisper in Python

2. **Clean transcript**

   - `awk` replaces common mis-hearings / formatting

3. **Run Fabric**

   - `cat transcript_cleaned.txt | fabric --model "<model>" -sp "<pattern>"`

  

Default Fabric settings in the script:

- Whisper model: `medium`

- Fabric model: `llama3.1:8b-instruct-q4_K_M`

- Fabric pattern: `extract_wisdom`

  

The `extract_wisdom` pattern is a common Fabric example pattern and is designed for extracting key ideas from input content.

  

---

  

## Requirements

  

### Software dependencies

  

**Core CLI tools**

- Bash (Linux/macOS; Windows via WSL)

- `yt-dlp` (download audio/subtitles) ([Installation guide](https://github.com/yt-dlp/yt-dlp/wiki/Installation?utm_source=chatgpt.com))

- `ffmpeg` (subtitle conversion; also required by Whisper and often needed by audio tooling) ([Installation guide](https://github.com/openai/whisper))

  

**Python (for Whisper mode)**

- Python 3

- Python packages:

  - `openai-whisper`

  - `torch`

  - `pydub`

  - `tqdm`

  

Whisper installation is via `pip install -U openai-whisper`, and it requires `ffmpeg` installed. ([Whisper](https://github.com/openai/whisper))

  

**Fabric**

- Daniel Miessler’s **Fabric** CLI (Go-based)

  - Install via `go install …/cmd/fabric@latest`

  - Run `fabric --setup` after install 

  

> ⚠️ Note: Some package managers install Fabric as `fabric-ai` (not `fabric`). If your command isn’t `fabric`, create an alias/symlink (see Troubleshooting). 
  

**Local LLM backend (recommended)**

- If you want the default local model (`llama3.1:8b-instruct-q4_K_M`), you’ll typically use **Ollama** and pull that model locally:

  - `ollama run llama3.1:8b-instruct-q4_K_M` ([Ollama](https://ollama.com/library/llama3.1%3A8b-instruct-q4_K_M?))

  

---

  

### Hardware dependencies

  

#### For transcription (Whisper)

  

Whisper can run on CPU or GPU. If using GPU, model VRAM needs scale by model size. The Whisper repo provides approximate **required VRAM** by model: tiny/base (~1GB), small (~2GB), medium (~5GB), large (~10GB), turbo (~6GB).

  

Practical guidance:

- **CPU-only:** works, but slower (especially for `medium`/`large`)

- **NVIDIA GPU (CUDA):** strongly recommended for speed

  - If CUDA is available, the script will try to use it (`torch.cuda.is_available()`)

  

#### For Fabric local models (Ollama)

  

The default Fabric model in the script is `llama3.1:8b-instruct-q4_K_M`. The model blob is about **4.9GB** on Ollama.

  

Practical guidance:

- **RAM:** expect at least ~8–16GB system RAM for comfortable local inference on 8B-class models (more is better)

- **GPU (optional):** Ollama supports GPU acceleration and uses VRAM sizing internally ([Ollama Documentation](https://docs.ollama.com/gpu))

  

---

  

## Installation

  

### Ubuntu/Debian

  

1) Install system packages:

  

```bash

sudo apt update

sudo apt install -y ffmpeg python3 python3-venv python3-pip

```

  

2) Install `yt-dlp`:

  

```bash

python3 -m pip install -U "yt-dlp[default]"

```

  

(That’s the official pip install method from the yt-dlp installation docs.) ([yt-dlp Installation guide](https://github.com/yt-dlp/yt-dlp/wiki/Installation))

  

3) (Recommended) Create a virtual environment for Python deps:

  

```bash

python3 -m venv .venv

source .venv/bin/activate

pip install -U pip

pip install openai-whisper torch pydub tqdm

```

  

Whisper itself is installed via `pip install -U openai-whisper`, and `ffmpeg` must be installed on the system. 

  

4) Install Fabric (Go):

  

```bash

go install github.com/danielmiessler/fabric/cmd/fabric@latest

fabric --setup

```

  
  

5) (Optional) Install Ollama + pull the default local model:

  

```bash

ollama run llama3.1:8b-instruct-q4_K_M

```

  


  

6) Make the script executable:

  

```bash

chmod +x inscribe.sh

```

  

---

  

### macOS

  

- Install `ffmpeg` (Homebrew):

  

```bash

brew install ffmpeg

```

  

Whisper’s docs list Homebrew as a supported way to install `ffmpeg`. 

  

- Install `yt-dlp`, Python deps, Fabric similarly (Homebrew / pip / Go).  

If you install Fabric via Homebrew and it’s named `fabric-ai`, alias it to `fabric`. ([fabric](https://formulae.brew.sh/formula/fabric-ai))

  

---

  

### Windows

  

Use **WSL2 (Ubuntu)** and follow the Ubuntu instructions. This script assumes a Bash environment and common Unix tooling.

  

---

  

## Usage

  

Basic:

  

```bash

./inscribe.sh "https://www.youtube.com/watch?v=VIDEO_ID"

```

  

You will be prompted to:

  

1. Pick transcription method:

   - `1` YouTube auto-subtitles

   - `2` Whisper (default)

2. If Whisper:

   - choose Whisper model (default: `medium`)

   - script auto-detects GPU vs CPU

3. Select Fabric pattern (default: `extract_wisdom`)

4. Select Fabric model (default: `llama3.1:8b-instruct-q4_K_M`)

5. Confirm and run Fabric

  

Fabric supports:

- `--listpatterns` / `--listmodels`

- `--pattern` selection

- `--model` selection

- `--stream` mode ([Fabric Stream Mode](https://github.gg/wiki/danielmiessler/Fabric/cli-usage-guide))

  

---

  

## Sample output

  

Below is a real sample run using auto-subtitles (method `1`) and Fabric pattern `extract_wisdom` with model `llama3.1:8b-instruct-q4_K_M`:

  

```text

$ ./inscribe.sh https://www.youtube.com/watch?v=rNxC16mlO60

Working dir: /home/zuriel/.local/tmp/inscribe

  

Choose transcription method:

  1) YouTube auto-subtitles (fast, may have errors)

  2) Whisper (higher accuracy, uses local model; may use GPU)

Enter 1 or 2 [default: 2]: 1

  

Downloading YouTube auto-subtitles...

WARNING: Your yt-dlp version (2025.10.22) is older than 90 days!

         It is strongly recommended to always use the latest version.

...

Auto-subtitles transcript saved to /home/zuriel/.local/tmp/inscribe/transcript_raw.txt

Cleaned transcript ready: /home/zuriel/.local/tmp/inscribe/transcript_cleaned.txt

  

Available Fabric patterns:

...

Enter Fabric pattern to use [default: extract_wisdom]: extract_wisdom

  

Available local Fabric models:

...

Enter local Fabric model to use [default: llama3.1:8b-instruct-q4_K_M]: llama3.1:8b-instruct-q4_K_M

  

Run Fabric with pattern 'extract_wisdom' and model 'llama3.1:8b-instruct-q4_K_M'? (Y/n): y

**SUMMARY**

Dr. Hilário discusses grit, BDNF, and mental toughness with George Hood's record-breaking plank as an example.

  

**IDEAS**

• Grit is not just about willpower but rooted in biology, specifically Brain-Derived Neurotrophic Factor (BDNF).

• Exercise increases BDNF the most, with sunshine and blueberries also being beneficial.

...

Done. Clean transcript: /home/zuriel/.local/tmp/inscribe/transcript_cleaned.txt

Whisper SRT files (if any) are in: /home/zuriel/.local/tmp/inscribe

```

  

---

  

## Outputs

  

Work directory (auto-created):

  

- `~/.local/tmp/inscribe/`

  

Generated files:

  

- `transcript_raw.txt` — raw transcript text

- `transcript_cleaned.txt` — cleaned transcript (this is what gets fed into Fabric)

- Temporary audio/chunks (during Whisper mode)

  

At the end, Fabric output is printed to your terminal (stdout).

  

---

  

## Configuration

  

Edit these defaults at the top of `inscribe.sh`:

  

- `WHISPER_MODEL_DEFAULT="medium"`

- `FABRIC_MODEL_DEFAULT="llama3.1:8b-instruct-q4_K_M"`

- `FABRIC_PATTERN_DEFAULT="extract_wisdom"`

- `WORKDIR="${HOME}/.local/tmp/inscribe"`

  

Notes:

- Whisper transcription is hard-coded to `language="English"` in the embedded Python. If you need multilingual, change that line.

  

---

  

## Troubleshooting

  

### 1) `yt-dlp: command not found`

Install via:

  

```bash

python3 -m pip install -U "yt-dlp[default]"

```

  



  

### 2) `ffmpeg: command not found` (or Whisper fails)

Install `ffmpeg`:

  

```bash

sudo apt update && sudo apt install ffmpeg

```

  

Whisper explicitly requires `ffmpeg`. 

  

### 3) Whisper install errors (Rust / tiktoken)

If `pip install openai-whisper` fails due to Rust/tiktoken, Whisper’s docs note you may need Rust and may need to install `setuptools-rust`. 

  

### 4) `ModuleNotFoundError: No module named 'whisper'` / `'torch'` / `'pydub'`

Make sure you installed Python dependencies in the environment you’re using:

  

```bash

pip install openai-whisper torch pydub tqdm

python3 -c "import whisper, torch; print('ok')"

```

  

### 5) `pydub` can’t decode audio / ffmpeg not found by pydub

Even if `ffmpeg` exists, ensure it’s on PATH:

  

```bash

which ffmpeg

ffmpeg -version

```

  

(Installing `ffmpeg` system-wide is the normal fix.) 

  

### 6) CUDA expected but Whisper runs on CPU

Check PyTorch CUDA detection:

  

```bash

python3 -c "import torch; print(torch.cuda.is_available())"

```

  

If `False`, you likely installed CPU-only PyTorch. Install a CUDA-enabled PyTorch build from PyTorch’s official selector (varies by OS/CUDA version).

  

### 7) `nvidia-smi` errors while on GPU

Your system may have CUDA-capable PyTorch, but NVIDIA drivers / `nvidia-smi` aren’t available. Install NVIDIA drivers (and ensure `nvidia-smi` works), or force CPU by making CUDA unavailable.

  

### 8) No subtitles found (auto-subtitles mode)

Some videos don’t have auto-captions available, or they’re not accessible in your region/account context.

  

Try:

- A different video

- Whisper mode instead (method 2)

- Using cookies with yt-dlp (advanced)

  

### 9) `fabric: command not found`

Install Fabric:

  

```bash

go install github.com/danielmiessler/fabric/cmd/fabric@latest

fabric --setup

```

  



  

### 10) Fabric is installed as `fabric-ai`, not `fabric`

This happens with some package managers. If your binary is `fabric-ai`, alias it:

  

```bash

echo 'alias fabric="fabric-ai"' >> ~/.bashrc

source ~/.bashrc

```

  

(Homebrew installs Fabric as `fabric-ai` in at least some setups.) 

  

### 11) Fabric model not found / `--listmodels` is empty

Run:

  

```bash

fabric --listmodels

fabric --setup

```

  

Fabric’s CLI supports listing models and running setup. 

  

If you’re using Ollama, make sure the model exists locally:

  

```bash

ollama run llama3.1:8b-instruct-q4_K_M

```

  


  

---

  

## Security & legal notes

  

- This script downloads audio/subtitles from YouTube. Make sure your usage complies with applicable laws and platform terms.

- Whisper runs locally, but Fabric can be configured to use local or cloud models depending on your vendor/settings.

- If you use local models through Ollama, keep services bound to localhost unless you intentionally want remote access.

  

---

  

## Contributing

  

PRs welcome. Ideas:

- Non-English transcription support

- Optional timestamped output

- Non-interactive flags (CI-friendly)

- Better error handling around `nvidia-smi` and missing dependencies

  

---

  

## License

  

  

### Dependency licenses

- **Fabric** is MIT-licensed. ([Fabric](https://github.com/danielmiessler/Fabric/blob/main/LICENSE))

- **Whisper** code and model weights are MIT-licensed. ([Whisper](https://github.com/openai/whisper))

- **yt-dlp** is licensed under the Unlicense, with notes that some distributed builds may include other licensed components. ([yt-dlp](https://github.com/yt-dlp/yt-dlp))

  

### MIT License

  

```text

MIT License

  

Copyright (c) [2026] [Zuriel Shanley Tanyory]

  

Permission is hereby granted, free of charge, to any person obtaining a copy

of this software and associated documentation files (the "Software"), to deal

in the Software without restriction, including without limitation the rights

to use, copy, modify, merge, publish, distribute, sublicense, and/or sell

copies of the Software, and to permit persons to whom the Software is

furnished to do so, subject to the following conditions:

  

The above copyright notice and this permission notice shall be included in all

copies or substantial portions of the Software.

  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR

IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,

FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE

AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER

LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,

OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

SOFTWARE.

```
