# LLM stations

Self-hosted `llama.cpp` boxes serving local weights over HTTP, with no
translation proxy in between. A Windows machine runs `llama-server`, a macOS
laptop runs the client pointed at it, and a control script loads the right model
over SSH.

Each station is its own repository. They are included here as submodules.

| Station                                                                 | GPU                                                            | Backend                                                                                | Models                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ----------------------------------------------------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [llm-station-cuda](https://github.com/gputier/llm-station-cuda)         | RTX 5090, 32 GB, plus a second box on an RTX 4080 SUPER, 16 GB | CUDA, seven builds, two of them forks; the 16 GB box runs the BeeLlama fork on its own | Thirteen profiles: Tiel-Coder and KAT-Coder 35B-A3B, Muse Glimmer 30B, Qwen3.8-27B NVFP4 and three fine-tunes (abliterated, TurboFCFusion, Twin-Turbo 709-L, the one in daily use), Ornith 1.5 9B, Nex-N2.5-mini, Spark-X2.5-4B, both Ternary Bonsai generations, and an embedder. Two more were rejected on 2026-09-19 and left the control script on 2026-09-21, Whittle and Xing4.0, the second taking with it the only engine ever compiled here from a pull request. The 16 GB box serves two of its own, `tiel` and `qwen36`, both 35B-A3B at the full window |
| [llm-station-vulkan](https://github.com/gputier/llm-station-vulkan)     | RX 5700 XT, 8 GB                                               | Vulkan, prebuilt                                                                       | Nothing any more. Qwen3-VL-4B and four measured candidates, until 2026-09-07                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| [llm-station-embedder](https://github.com/gputier/llm-station-embedder) | RX 5700 XT, 8 GB                                               | Vulkan, prebuilt                                                                       | Qwen3-Embedding-0.6B, embeddings only                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |

The last two are the **same physical machine**, and only the second describes
what it does today. The Vulkan repository records what it took to serve a
vision-language model on an 8 GB RDNA1 card, and the measurement that ended the
attempt on 2026-09-07: those weights are off the box and its profiles are gone
from the control script. The embedder repository is what the machine runs now,
and why that job fits the hardware. Both are kept: the second one only makes
sense next to the first.

```bash
git clone --recurse-submodules https://github.com/gputier/LLM.git
cd LLM && ./scripts/install-hooks.sh
```

The second line wires the pre-push gate, here and in every submodule that
carries one. Before anything reaches a public remote it reads the commits being
sent and the tree they come from, looking for plaintext secrets, and it needs
Docker. A fresh clone has no hooks wired and nothing
warns about it, which is why the script prints what git resolved rather than
claiming success. What it blocks on, and what to do then:
[llm-station-cuda/docs/security-gate.md](llm-station-cuda/docs/security-gate.md).

## Why more than one, and why the contrast matters

Same `llama.cpp`, same Windows host, same control script, but 32 GB of VRAM
against 8, CUDA against Vulkan, eight coexisting builds against a prebuilt
binary. What survives that change is the part worth copying.

The third repository adds a different lesson: what to do when the measurements
say the hardware cannot do the job you bought it for. The 8 GB card was never
going to serve an agentic client, and no flag was going to fix a missing
instruction set. It now serves embeddings, where the same curve barely shows.

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
- The vendor's own recommended launch flag can be wrong for your card. An
  embedding model's published line uses `-ub 8192`; on RDNA1 that fails to
  allocate a pinned buffer, logs a warning rather than an error, and runs 50%
  slower than `-ub 2048`.
- Chunking beats tuning. The same 4,800-token text embeds in 13.7 s as one input
  and 0.09 s as eight, on the same server with the same flags.

Negative results are kept on purpose. Half the comments exist to stop the next
person re-testing something already found to gain nothing.

## License

MIT, in all three repositories. `llama.cpp` is MIT; model weights carry their own
licenses.
