# CLI Testing Patterns Reference

> Patterns for functional testing of CLI tools across technology stacks.

---

## Three Tiers of CLI Testing

### Tier 1: In-Process Testing (Fast, No Subprocess)

Test framework commands directly without spawning a process.

**Node.js / Commander.js:**
```typescript
import { Command } from 'commander';

function createTestProgram(): Command {
  const program = new Command();
  program.exitOverride();               // Throw instead of process.exit()
  program.configureOutput({
    writeOut: () => {},                  // Suppress stdout
    writeErr: () => {},                  // Suppress stderr
  });
  return program;
}

// Verify command registration
it('should register all commands', () => {
  const program = createTestProgram();
  registerAllCommands(program);
  const names = program.commands.map(c => c.name());
  expect(names).toContain('start');
  expect(names).toContain('status');
});

// Verify option parsing
it('should parse --once flag', () => {
  const program = createTestProgram();
  registerStartCommand(program);
  program.parse(['node', 'cli', 'start', '--once']);
  expect(program.commands[0].opts().once).toBe(true);
});
```

**Python / Click:**
```python
from click.testing import CliRunner

def test_help():
    runner = CliRunner()
    result = runner.invoke(cli, ['--help'])
    assert result.exit_code == 0
    assert 'Usage' in result.output
```

**Go / Cobra:**
```go
func TestRootCommand(t *testing.T) {
    cmd := NewRootCmd()
    buf := new(bytes.Buffer)
    cmd.SetOut(buf)
    cmd.SetArgs([]string{"--help"})
    err := cmd.Execute()
    assert.NoError(t, err)
    assert.Contains(t, buf.String(), "Usage")
}
```

### Tier 2: Subprocess Testing (Real Process Invocation)

Spawn the CLI as a child process. Gold standard for functional tests.

**Node.js Pattern (execa + builder):**
```typescript
import { execaSync } from 'execa';
import stripAnsi from 'strip-ansi';

function cli(args: string[], opts?: { cwd?: string }) {
  try {
    const result = execaSync('npx', ['tsx', 'src/cli.ts', ...args], {
      cwd: opts?.cwd ?? process.cwd(),
      env: { ...process.env, NO_COLOR: '1' },
    });
    return {
      exitCode: result.exitCode,
      stdout: stripAnsi(result.stdout),
      stderr: stripAnsi(result.stderr),
    };
  } catch (error: unknown) {
    const e = error as any;
    return {
      exitCode: e.exitCode ?? 1,
      stdout: stripAnsi(e.stdout ?? ''),
      stderr: stripAnsi(e.stderr ?? ''),
    };
  }
}

// Usage
it('should display version', () => {
  const { exitCode, stdout } = cli(['--version']);
  expect(exitCode).toBe(0);
  expect(stdout).toMatch(/\d+\.\d+\.\d+/);
});
```

**Python Pattern (subprocess):**
```python
import subprocess

def cli(args):
    result = subprocess.run(
        ['python', '-m', 'mypackage', *args],
        capture_output=True, text=True
    )
    return result.returncode, result.stdout, result.stderr

def test_version():
    code, stdout, _ = cli(['--version'])
    assert code == 0
    assert '0.1.0' in stdout
```

**Shell Pattern (direct invocation):**
```bash
#!/bin/bash
# Functional test: CLI help output
output=$(./dist/cli.js --help 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "FAIL: --help returned exit code $exit_code"
  exit 1
fi

if ! echo "$output" | grep -q "start"; then
  echo "FAIL: --help missing 'start' command"
  exit 1
fi

echo "PASS: CLI help output correct"
```

### Tier 3: Smoke Testing (Post-Build Binary)

Test the compiled/built output to verify the build pipeline.

```typescript
import fs from 'fs';
import { execaSync } from 'execa';

const DIST_CLI = 'dist/cli.js';

describe('Smoke Tests', () => {
  it('built binary exists', () => {
    expect(fs.existsSync(DIST_CLI)).toBe(true);
  });

  it('executes with node', () => {
    const { exitCode } = execaSync('node', [DIST_CLI, '--version']);
    expect(exitCode).toBe(0);
  });

  it('has shebang line', () => {
    const content = fs.readFileSync(DIST_CLI, 'utf-8');
    expect(content.startsWith('#!/usr/bin/env node')).toBe(true);
  });
});
```

---

## Feature Existence Testing

Verify planned files exist and export expected symbols.

```typescript
const EXPECTED_SERVICES = [
  'agent-orchestrator',
  'build-executor',
  'config',
  'logger',
  'state',
];

describe('Feature Existence', () => {
  it.each(EXPECTED_SERVICES)('service file exists: %s', (name) => {
    expect(fs.existsSync(`src/services/${name}.ts`)).toBe(true);
  });
});
```

---

## Export Wiring Testing

Verify barrel files re-export expected symbols.

```typescript
describe('Export Wiring', () => {
  it('index exports all public APIs', async () => {
    const mod = await import('../../src/index.js');
    const keys = Object.keys(mod);
    expect(keys).toContain('configService');
    expect(keys).toContain('logger');
  });

  it('all services importable without errors', async () => {
    const imports = EXPECTED_SERVICES.map(s =>
      import(`../../src/services/${s}.js`)
    );
    const results = await Promise.allSettled(imports);
    results.forEach(r => expect(r.status).toBe('fulfilled'));
  });
});
```

---

## Stack-Specific Test Commands

| Stack | Unit | Integration | E2E | Smoke |
|---|---|---|---|---|
| Node/TS (Vitest) | `vitest run` | `vitest run --project integration` | `playwright test` | `node dist/cli.js --help` |
| Node/TS (Jest) | `jest` | `jest --testPathPattern=integration` | `playwright test` | `node dist/cli.js --help` |
| Python | `pytest tests/unit` | `pytest tests/integration` | `pytest tests/e2e` | `python -m mypackage --help` |
| Go | `go test ./...` | `go test -tags=integration ./...` | `go test -tags=e2e ./...` | `./bin/mytool --help` |
| Rust | `cargo test --lib` | `cargo test --test integration` | `cargo test --test e2e` | `./target/release/mytool --help` |

---

## Test Isolation Patterns

### Temporary Directories

```typescript
import { mkdtempSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import path from 'path';

let tempDir: string;

beforeEach(() => {
  tempDir = mkdtempSync(path.join(tmpdir(), 'superval-test-'));
});

afterEach(() => {
  rmSync(tempDir, { recursive: true, force: true });
});
```

### Environment Variable Isolation

```typescript
const originalEnv = process.env;

beforeEach(() => {
  process.env = { ...originalEnv, NO_COLOR: '1' };
});

afterEach(() => {
  process.env = originalEnv;
});
```

---

## The Five Exit Doors

Every integration test should verify one of:

1. **Response**: stdout/stderr content and exit code
2. **State Changes**: Files created, config modified, git branches
3. **External Calls**: HTTP requests made (mock with nock/msw)
4. **Events/Messages**: Events emitted, logs written
5. **Observability**: Error handling, logging output

Pick ONE door per test. Multiple doors = test doing too much.
