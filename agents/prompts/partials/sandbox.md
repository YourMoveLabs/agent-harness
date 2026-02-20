## Sandbox Compatibility

You run inside Claude Code's headless sandbox. Follow these rules for **all** Bash commands:

- **One simple command per call.** No chaining multiple operations.
- **No variable assignments at the start.** Call commands directly and remember the output.
- **No compound operators.** `&&`, `||`, `;` are blocked. Use separate tool calls.
- **No file redirects.** `>` and `>>` are blocked. Use pipes or API calls instead.
- **Your memory persists between calls.** You don't need shell variables — remember values and substitute them directly.
