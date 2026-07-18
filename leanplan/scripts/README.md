# leanplan scripts

## detect-stack.sh

Evidence-oriented stack detection. Emits one JSON claim per (component, technology).

```bash
./detect-stack.sh --repo . --plan docs/plans/my-plan.md
```

Both flags optional. `--repo` defaults to `.`; omitting `--plan` skips the plan pass.

### Output

```json
{"claims":[
  {"component":"apps/web","claim":"nextjs-app-router","status":"used","version":"15.2.1",
   "evidence":["apps/web/package.json: next","apps/web/app/layout.tsx"]}
]}
```

### Status values

| Status | Meaning |
|---|---|
| `established` | Language confirmed by a manifest file |
| `used` | Framework declared **and** structurally used in source |
| `declared` | In a manifest, no usage found — do not treat as adopted |
| `proposed` | Named by the plan only — evidence of intent, never of adoption |
| `unknown` | Manifest for an ecosystem outside the tested five |

### Design contract

- **No global confidence value.** Mixed certainty across a repo is normal; each claim carries its own evidence.
- **Per-component.** Monorepos emit one claim set per manifest directory.
- **Precision over breadth.** Five tested ecosystems (JS/TS, Python, Go, Rust, Java). Other manifests emit `unknown-ecosystem` with the raw path rather than a guess — a wrong framework claim is worse than no claim.
- **Prunes** `node_modules`, `vendor`, `dist`, `build`, `target`, `.venv`, `__pycache__`, `testdata`, `fixtures`, `examples`, `.next`, `coverage`.
- **Always exits 0.** An empty claim list is a valid answer, not an error.

### Frameworks recognized

| Ecosystem | Claims |
|---|---|
| JS/TS | `nextjs-app-router`, `nextjs-pages-router`, `nextjs`, `react`, `express`, `nestjs`, `vue`, `svelte` |
| Python | `fastapi`, `django`, `django-rest-framework`, `flask`, `sqlalchemy` |
| Go | `gin`, `echo`, `chi`, `cobra` |
| Rust | `axum`, `actix-web`, `rocket`, `tokio` |
| Java | `spring-boot-2`, `spring-boot-3`, `spring-boot` |

Keep this list small and tested. Adding breadth without a fixture is how it regresses into a
guess-generator.

### Dependencies

POSIX shell + `find`, `grep`, `sed`. No `jq`, no network.
