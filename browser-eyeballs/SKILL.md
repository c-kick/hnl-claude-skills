---
name: browser-eyeballs
description: Browse and visually inspect webpages using headless Chromium via Puppeteer MCP. Use when you need to see a page, interact with a web UI, extract information that WebFetch can't get (JS-rendered content, SPAs, authenticated pages), or when the user wants to show you something in a browser.
---

# Browser Eyeballs

Visually browse webpages using a headless Chromium instance running in Docker via the Puppeteer MCP server.

## When to Use

- The user says "look at this page", "check this UI", "show you something"
- You need to see JS-rendered or SPA content that `WebFetch` returns as empty/useless
- You need to interact with a page (click, fill forms, scroll) to reach content
- You need to inspect visual layout, styling, or rendering
- You need to navigate an authenticated web app
- You need a screenshot of a page for reference or debugging

## Prerequisites

The Puppeteer MCP server must be configured in `~/.claude.json` under `mcpServers.puppeteer`. It runs headless Chromium inside Docker (`mcp/puppeteer-remote` image).

If the MCP tools (`mcp__puppeteer__puppeteer_navigate`, etc.) are not available, tell the user the Puppeteer MCP server is not configured or not running.

## Workflow

### Step 1: Navigate

The **first call in every session** must include `launchOptions`. Subsequent calls don't need them.

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

The MCP tool returns the screenshot inline as an image — you can see and analyze it directly.

### Step 3: Interact (if needed)

Use the available MCP tools to interact with the page:

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

The MCP screenshot tool shows images inline but doesn't save to disk. If the user needs a persistent screenshot, use `puppeteer_evaluate` to capture via CDP and save to `~/screenshots/`:

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

### MCP tools not available
The Puppeteer MCP server connects at **session startup only**. If the `mcp__puppeteer__*` tools are not found (ToolSearch returns nothing), the server failed to start. This cannot be fixed mid-session.

**Most common cause:** a stale Docker container from a previous session is holding port 9222. Fix:
```bash
# Find and remove the stale container
docker ps -a --filter "ancestor=mcp/puppeteer-remote" --format '{{.ID}} {{.Status}}'
docker stop <id> && docker rm <id>
```
Then ask the user to restart the Claude Code session (`/exit` + relaunch).

### Container starts but tools still missing
Check `~/.claude.json` has `mcpServers.puppeteer` configured. The server must be defined at user level, not project level.

## What This is NOT

- Not a replacement for `WebFetch` — if you just need to read page content or an API response, `WebFetch` is faster and simpler
- Not a testing framework — this is for ad-hoc visual inspection and interaction
- Not persistent — the browser state (cookies, sessions) lives only as long as the MCP container runs
