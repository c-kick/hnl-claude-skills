---
name: browser-eyeballs
description: Browse and visually inspect webpages using an available browser automation tool, preferably headless Chromium via Puppeteer MCP. Use when you need to see a page, interact with a web UI, extract information that a plain fetch cannot get (JS-rendered content, SPAs, authenticated pages), or when the user wants to show you something in a browser.
---

# Browser Eyeballs

Visually browse webpages using the active agent's available browser automation tools. Prefer a headless Chromium instance via the Puppeteer MCP server when available.

## When to Use

- The user says "look at this page", "check this UI", "show you something"
- You need to see JS-rendered or SPA content that a plain fetch returns as empty/useless
- You need to interact with a page (click, fill forms, scroll) to reach content
- You need to inspect visual layout, styling, or rendering
- You need to navigate an authenticated web app
- You need a screenshot of a page for reference or debugging

## Prerequisites

Use whichever browser automation is available in the current agent session. In Claude Code, this may be a Puppeteer MCP server. In Codex, this may be Playwright or another browser/screenshot tool exposed by the environment.

For Claude Code, the Puppeteer MCP server can be configured in `~/.claude.json` under `mcpServers.puppeteer`. It runs headless Chromium inside Docker (`mcp/puppeteer-remote` image).

The recommended MCP config uses `bash -c` to automatically kill stale containers from previous sessions before starting a new one. Without this, a leftover container holding port 9222 will silently prevent MCP connection on the next session (and this cannot be fixed mid-session).

```json
"puppeteer": {
  "type": "stdio",
  "command": "bash",
  "args": [
    "-c",
    "docker rm -f $(docker ps -aq --filter ancestor=mcp/puppeteer-remote) 2>/dev/null; exec docker run -i --rm --init -p 9222:9223 -e DOCKER_CONTAINER=true -e 'PUPPETEER_LAUNCH_OPTIONS={\"headless\":true,\"args\":[\"--remote-debugging-port=9222\",\"--remote-allow-origins=*\"]}' mcp/puppeteer-remote"
  ],
  "env": {}
}
```

If no browser automation tools are available, tell the user that browser inspection is not configured in this agent session and explain which capability is missing.

## Workflow

### Step 1: Navigate

With Puppeteer MCP, the **first call in every session** must include `launchOptions`. Subsequent calls don't need them. If using a different browser tool, use that tool's normal navigation/open-page flow.

```
mcp__puppeteer__puppeteer_navigate({
  url: "<target URL>",
  allowDangerous: true,
  launchOptions: {
    headless: true,
    args: ["--no-sandbox", "--remote-debugging-port=9222", "--remote-allow-origins=*"]
  }
})
```

- `allowDangerous: true` is required for local/private network URLs (192.168.x.x, localhost, .local, etc.)
- For public HTTPS URLs, `allowDangerous` can be omitted but doesn't hurt

### Step 2: Wait and Screenshot

After navigation, take a screenshot to see the page:

```
mcp__puppeteer__puppeteer_screenshot()
```

The browser tool should return a screenshot inline or save one where the agent can inspect it.

### Step 3: Interact (if needed)

Use the available browser tools to interact with the page. With Puppeteer MCP, the common tools are:

- **`puppeteer_click`** — click an element by CSS selector
- **`puppeteer_fill`** — type into an input field (selector + value)
- **`puppeteer_evaluate`** — run arbitrary JavaScript in the page context (for complex interactions, shadow DOM traversal, extracting data, scrolling, waiting)

After each interaction, take another screenshot to verify the result.

### Step 4: Extract Information

Two approaches depending on what's needed:

**Visual inspection** — just read the screenshot. Describe what you see.

**Data extraction** — use `puppeteer_evaluate` to pull structured data:
```js
// Example: extract all table rows
puppeteer_evaluate({
  script: `JSON.stringify([...document.querySelectorAll('table tr')].map(r => [...r.cells].map(c => c.textContent.trim())))`
})
```

### Step 5: Save Screenshots (if needed)

The Puppeteer MCP screenshot tool shows images inline but doesn't save to disk. If the user needs a persistent screenshot, use the active tool's screenshot-save option. With Puppeteer MCP, you can capture via CDP and save to `~/screenshots/`:

```js
puppeteer_evaluate({
  script: `
    const cdp = await page.target().createCDPSession();
    const {data} = await cdp.send('Page.captureScreenshot', {format: 'png'});
    require('fs').writeFileSync('/tmp/screenshot.png', Buffer.from(data, 'base64'));
  `
})
```
Then copy from the container, or just rely on the inline screenshot for most use cases.

## Tips and Patterns

### Shadow DOM
Many web components (Home Assistant, Salesforce, etc.) use shadow DOM. Regular selectors won't reach inside. Use `puppeteer_evaluate` with manual traversal:
```js
document.querySelector('my-component').shadowRoot.querySelector('.inner-element')
```

### Waiting for Content
SPAs often load content asynchronously. If the screenshot shows a loading spinner, wait:
```js
puppeteer_evaluate({
  script: `await new Promise(r => setTimeout(r, 2000))`
})
```
Or wait for a specific selector:
```js
puppeteer_evaluate({
  script: `await document.querySelector('.content') || await new Promise(r => { const o = new MutationObserver(() => { if (document.querySelector('.content')) { o.disconnect(); r(); } }); o.observe(document.body, {childList: true, subtree: true}); setTimeout(r, 5000); })`
})
```

### Viewport Size
Default viewport is typically 1280x720. To change it:
```js
puppeteer_evaluate({ script: `await page.setViewport({width: 1920, height: 1080})` })
```

### Multiple Pages / Navigation
Just call `puppeteer_navigate` again with a new URL. No need to re-pass `launchOptions` after the first call.

### Network Considerations
The Chromium instance runs inside a Docker container on **bridge networking**. This means:
- `localhost` inside the container is the container itself, not the host
- To reach services on the host machine, use the host's LAN IP (e.g., `192.168.1.199`)
- Public URLs work normally

## Troubleshooting

### Browser tools not available
Some agents only expose browser tools at session startup. If no browser automation or screenshot tools are available, the browser integration failed to start or is not configured. This often cannot be fixed mid-session.

If you're using the recommended MCP config (with `bash -c` cleanup), stale containers are cleaned up automatically. If tools are still missing after a fresh session start:

1. Check for stale containers manually: `docker ps -a --filter "ancestor=mcp/puppeteer-remote"`
2. For Claude Code, verify `~/.claude.json` has the `mcpServers.puppeteer` entry (see Prerequisites for the recommended config)
3. For Codex, verify the session/environment exposes a browser automation tool such as Playwright
4. Check Docker is running if using the Docker-based Puppeteer MCP server: `docker ps`

### Container starts but tools still missing
For Claude Code, check `~/.claude.json` has `mcpServers.puppeteer` configured. The server must be defined at user level, not project level.

## What This is NOT

- Not a replacement for plain fetch/read tools — if you just need to read page content or an API response, those are faster and simpler
- Not a testing framework — this is for ad-hoc visual inspection and interaction
- Not persistent — the browser state (cookies, sessions) lives only as long as the MCP container runs
