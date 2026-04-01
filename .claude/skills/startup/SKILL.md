---
name: startup
description: >
  Triggered by greetings (hello, hi, good morning, おはよう, こんにちは, etc.).
  Runs a quick environment health check: verifies key tool versions and confirms
  the container is ready for use.
triggers:
  - hello
  - hi
  - hey
  - good morning
  - おはよう
  - こんにちは
  - start
  - startup
  - status
---

# Startup Health Check

When triggered, run the following checks and report results:

## Steps

1. **Check tool versions** by running each command and capturing output:
   ```bash
   claude --version
   node --version
   gh --version
   bw --version
   code-server --version
   ```

2. **Report results** in a clean table:
   | Tool | Version | Status |
   |------|---------|--------|
   | claude | (output) | ✓ / ✗ |
   | node | (output) | ✓ / ✗ |
   | gh | (output) | ✓ / ✗ |
   | bw | (output) | ✓ / ✗ |
   | code-server | (output) | ✓ / ✗ |

3. **Final message**:
   - All tools OK → print `Environment ready.`
   - Any tool missing → print `Warning: <tool> not found. Check Dockerfile.`

## Notes

- This skill is for ai-enclave main branch only (generic, no shogunate-specific elements)
- No authentication checks (bw login state, gh auth, etc.) — version check only
- Keep output concise; do not explain each tool's purpose
