AreaIQ stored per-state static files here (e.g. `indiana-tax-info.json`).

HomeAccessIQ doesn't need that pattern — geography-keyed data (income limits,
purchase price caps, occupation taxonomy) lives in Supabase (`geo_lookup_values`,
`occupation_taxonomy`) instead, precisely because it's multi-state and needs to
be queryable/updatable without a code deploy. This folder is kept for any
genuinely static, non-geography assets if they come up later (e.g. a state
boundary GeoJSON, if a future feature needs one).
