# LLM stations

Two self-hosted `llama.cpp` boxes that serve **Claude Code** from local weights,
with no translation proxy in between. A Windows machine runs `llama-server`, a
macOS laptop runs the client pointed at it, and a launcher script loads the right
model over SSH before handing over.

Each station is its own repository. They are included here as submodules.

| Station | GPU | Backend | Models |
|---|---|---|---|
| [llm-station-cuda](https://github.com/gputier/llm-station-cuda) | RTX 5090, 32 GB | CUDA, three builds | Muse Glimmer 30B, Qwen3.8-27B NVFP4, an abliterated variant, an embedder |
| [llm-station-vulkan](https://github.com/gputier/llm-station-vulkan) | RX 5700 XT, 8 GB | Vulkan, prebuilt | Qwen3-VL-4B, plus four measured candidates |

```bash
git clone --recurse-submodules https://github.com/gputier/LLM.git
```

## Why two, and why the contrast matters

Same `llama.cpp`, same Windows host, same client pattern, but 32 GB of VRAM
against 8, CUDA against Vulkan, three custom builds against a prebuilt binary,
and an open server against one locked behind an API key. What survives that
change is the part worth copying.

## What these repositories actually contain

Not scripts. **Measurements attached to every flag.** Each setting carries the
number that justifies it, the hardware it was measured on, and where it applies,
the hypothesis that the measurement disproved.

A few of the findings, each documented in full in its repository:

- `--ctx-size` sizes buffers on what you request, not on the window you get.
  Asking for a window the GGUF cannot give still costs the memory: 23% of decode
  and 72% of prefill lost for nothing.
- Forcing speculative depth to the drafter's block size collapses the acceptance
  rate. It looks like the obvious setting. It is a trap.
- A speculation sweep without a fixed seed measures noise. Our first sweep
  concluded the opposite of the re-run.
- `-ub` carries failures that look unrelated to it, including a drafter silently
  disabled past a certain context length, with no error anywhere.
- A dead end is only dead under the assumptions you tested it with. A build was
  measured, found to gain nothing, written off, and became three weeks later the
  only one able to serve the model.
- A prefix cache is destroyed by one changed character at the top of a prompt.
  Ninety-fold difference, entirely from prompt ordering.

Negative results are kept on purpose. Half the comments exist to stop the next
person re-testing something already found to gain nothing.

## License

MIT, in both repositories. `llama.cpp` is MIT; model weights carry their own
licenses.
