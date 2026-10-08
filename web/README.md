# Web application source (not yet integrated)

The deployed site is `https://study-form-ryu.ryukawasaki1023.chatgpt.site`. Its ChatGPT Sites project ID from the handoff is `appgprj_6ab22c8cfe108191a6fd1bfdb364bbe4`.

This directory currently contains no web application source. The deployed URL was inaccessible from the Codex environment (HTTP 403), and the GitHub repository currently contains only the iOS app. Do not create a replacement app or guess its API/database contract here.

## Owner: export the current project

In ChatGPT, open the existing Sites project using the project ID above, then use its source/export/download option to export the project. Add the source files to this `web/` directory and push them to this GitHub repository. Include the package manifest, application routes/components, API handlers, database schema, and migrations so the existing feature set can be audited and run locally.

Exclude `.env` files, API keys, signing material, production database files, and real learning records. Include an `.env.example` with variable names and safe placeholders only. Do not publish or overwrite the deployed site as part of source import; deployment should be a separate reviewed step.

If the Sites project offers no source export, connect its source repository to GitHub or provide the exported source archive. A deployed site URL or screenshot is insufficient to verify CRUD, rewards, persistence, and timer synchronization.

## Required after import

Document the actual runtime version, install/dev/build/test commands, required environment variable names, database setup/migration commands, authentication flow, API routes, and the endpoints used for timer persistence. Verify these against the source; do not assume the historical Next.js/Cloudflare D1 note or the unverified `/api/study` comment is current.
