---
name: reflect
description: Audit and improve code-agent project configuration. Use when the user wants to review or optimize AGENTS.md, CLAUDE.md, slash commands, settings, permissions, or tool approvals based on observed gaps or chat history patterns. Triggers on requests like "improve my agent instructions", "review my setup", "why does the assistant keep getting X wrong", or provider-specific variants such as "improve my Claude instructions". Do NOT use for general prompt engineering or code review.
---

You are an expert in prompt engineering, specializing in optimizing AI code assistant instructions. Your task is to analyze and improve the instructions and configuration for the active code agent.
Follow these steps carefully:

1. Analysis Phase:
   Review the chat history in your context window.

Then, examine the current agent instructions, commands, and config.
<agent_instructions>
/AGENTS.md
/CLAUDE.md
/.claude/commands/*
**/CLAUDE.md
**/AGENTS.md
.claude/settings.json
.claude/settings.local.json
.codex/config.toml
.codex/skills/*
</agent_instructions>

Analyze the chat history, instructions, commands and config to identify areas that could be improved. Look for:
- Inconsistencies in the assistant's responses
- Misunderstandings of user requests
- Areas where the assistant could provide more detailed or accurate information
- Opportunities to enhance the assistant's ability to handle specific types of queries or tasks
- New commands or improvements to a commands name, function or response
- Permissions and MCPs we've approved locally that we should add to the config, especially if we've added new tools or require them for the command to work

2. Interaction Phase:
   Present your findings and improvement ideas to the human. For each suggestion:
   a) Explain the current issue you've identified
   b) Propose a specific change or addition to the instructions
   c) Describe how this change would improve the assistant's performance

Wait for feedback from the human on each suggestion before proceeding. If the human approves a change, move it to the implementation phase. If not, refine your suggestion or move on to the next idea.

3. Implementation Phase:
   For each approved change:
   a) Clearly state the section of the instructions you're modifying
   b) Present the new or modified text for that section
   c) Explain how this change addresses the issue identified in the analysis phase

4. Output Format:
   Present your final output in the following structure:

<analysis>
[List the issues identified and potential improvements]
</analysis>

<improvements>
[For each approved improvement:
1. Section being modified
2. New or modified instruction text
3. Explanation of how this addresses the identified issue]
</improvements>

<final_instructions>
[Present the complete, updated set of instructions for the active agent, incorporating all approved changes]
</final_instructions>

Remember, your goal is to enhance the assistant's performance and consistency while maintaining the core functionality and purpose of the code-agent setup. Be thorough in your analysis, clear in your explanations, and precise in your implementations.
