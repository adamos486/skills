#!/usr/bin/env bash
# detect-stack.sh — evidence-oriented stack detection for leanplan
#
# Emits one JSON claim per (component, technology). Never emits a global
# confidence value: mixed certainty across a repo is the normal case.
#
# Usage:
#   detect-stack.sh [--repo DIR] [--plan FILE]
#
# Exit codes: 0 always (an empty claim list is a valid answer, not an error).

set -uo pipefail

REPO=""
PLAN=""
NOREPO=0

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --no-repo) NOREPO=1; shift ;;
    --plan) PLAN="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 0 ;;
  esac
done

# Never scan an implicit working directory: a standalone plan reviewed from an unrelated
# directory would otherwise emit a confident, fully-formed, completely wrong stack.
if [ "$NOREPO" -eq 1 ]; then
  REPO="/nonexistent/leanplan-no-repo"   # all find calls suppress stderr; yields zero repo claims
elif [ -z "$REPO" ]; then
  echo '{"claims":[],"error":"no --repo given. Pass --repo DIR for the plan'"'"'s repository, or --no-repo when the plan has none. Refusing to scan the current directory."}' >&2
  printf '{"claims":[],"error":"no-repo-not-specified"}\n'
  exit 0
elif [ ! -d "$REPO" ]; then
  printf '{"claims":[],"error":"repo path not found: %s"}\n' "$REPO"
  exit 0
fi

PRUNE='-name node_modules -o -name vendor -o -name dist -o -name build -o -name target
       -o -name .venv -o -name venv -o -name __pycache__ -o -name .git -o -name testdata
       -o -name fixtures -o -name examples -o -name .next -o -name coverage'

CLAIMS=""

emit() { # component claim status version evidence...
  local component="$1" claim="$2" status="$3" version="$4"; shift 4
  local ev="" e
  for e in "$@"; do
    [ -n "$e" ] || continue
    [ -n "$ev" ] && ev="$ev,"
    ev="$ev$(printf '"%s"' "$e")"
  done
  CLAIMS="$CLAIMS$(cat <<EOF
{"component":"$component","claim":"$claim","status":"$status","version":"$version","evidence":[$ev]},
EOF
)"
}

# Does a manifest declare this dependency name?
declares() { grep -qE "[\"']?$2[\"']?[[:space:]]*[:=><~^\"',]" "$1" 2>/dev/null; }

# Is there structural usage under this component?
uses() { # dir pattern glob
  find "$1" \( $PRUNE \) -prune -o -type f -name "$3" -print 2>/dev/null \
    | head -400 | xargs grep -lE "$2" 2>/dev/null | head -1
}

# Pull a version string next to a dependency name.
version_of() {
  grep -oE "[\"']?$2[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[~^>=< ]*[0-9][0-9A-Za-z.\-]*" "$1" 2>/dev/null \
    | head -1 | grep -oE '[0-9][0-9A-Za-z.\-]*' | head -1
}

# status: "used" beats "declared". A dependency in a manifest is a declaration;
# only structural evidence establishes that the framework is actually adopted.
classify() { [ -n "$1" ] && echo "used" || echo "declared"; }

# ---------- JavaScript / TypeScript ----------
while IFS= read -r m; do
  [ -n "$m" ] || continue
  d="$(dirname "$m")"; rel="${d#./}"
  lock=""
  for l in package-lock.json pnpm-lock.yaml yarn.lock bun.lockb; do
    [ -f "$d/$l" ] && lock="$rel/$l" && break
  done
  emit "$rel" "javascript-typescript" "established" "" "$rel/package.json" "$lock"

  if declares "$m" "next"; then
    if find "$d" \( $PRUNE \) -prune -o -type d \( -name app -o -name src \) -print 2>/dev/null \
       | head -20 | xargs -I{} find {} -maxdepth 2 -name 'layout.*' -print 2>/dev/null | head -1 | grep -q .; then
      hit="$(find "$d" \( $PRUNE \) -prune -o -type f -name 'layout.*' -print 2>/dev/null | head -1)"
      emit "$rel" "nextjs-app-router" "used" "$(version_of "$m" next)" "$rel/package.json: next" "${hit#./}"
    elif find "$d" \( $PRUNE \) -prune -o -type d -name pages -print 2>/dev/null | head -1 | grep -q .; then
      hit="$(find "$d" \( $PRUNE \) -prune -o -type d -name pages -print 2>/dev/null | head -1)"
      emit "$rel" "nextjs-pages-router" "used" "$(version_of "$m" next)" "$rel/package.json: next" "${hit#./}"
    else
      emit "$rel" "nextjs" "declared" "$(version_of "$m" next)" "$rel/package.json: next"
    fi
  fi
  for fw in react express @nestjs/core vue svelte; do
    declares "$m" "$fw" || continue
    case "$fw" in
      react)        u="$(uses "$d" 'from .react.|require\(.react.\)' '*.[jt]s*')" ; name=react ;;
      express)      u="$(uses "$d" 'require\(.express.\)|from .express.' '*.[jt]s')" ; name=express ;;
      @nestjs/core) u="$(uses "$d" '@nestjs/common|@Module\(' '*.ts')" ; name=nestjs ;;
      vue)          u="$(uses "$d" '.' '*.vue')" ; name=vue ;;
      svelte)       u="$(uses "$d" '.' '*.svelte')" ; name=svelte ;;
    esac
    emit "$rel" "$name" "$(classify "$u")" "$(version_of "$m" "$fw")" "$rel/package.json: $fw" "${u#./}"
  done
done <<EOF
$(find "$REPO" \( $PRUNE \) -prune -o -type f -name package.json -print 2>/dev/null)
EOF

# ---------- Python ----------
while IFS= read -r m; do
  [ -n "$m" ] || continue
  d="$(dirname "$m")"; rel="${d#./}"
  emit "$rel" "python" "established" "" "${m#./}"
  if declares "$m" "fastapi"; then
    u="$(uses "$d" 'from fastapi|import fastapi' '*.py')"
    emit "$rel" "fastapi" "$(classify "$u")" "$(version_of "$m" fastapi)" "${m#./}: fastapi" "${u#./}"
  fi
  if declares "$m" "django" || declares "$m" "Django"; then
    u="$(uses "$d" 'from django|import django' '*.py')"
    emit "$rel" "django" "$(classify "$u")" "$(version_of "$m" [Dd]jango)" "${m#./}: django" "${u#./}"
    if declares "$m" "djangorestframework"; then
      r="$(uses "$d" 'from rest_framework' '*.py')"
      emit "$rel" "django-rest-framework" "$(classify "$r")" "" "${m#./}: djangorestframework" "${r#./}"
    fi
  fi
  if declares "$m" "[Ff]lask"; then
    u="$(uses "$d" 'from flask|import flask' '*.py')"
    emit "$rel" "flask" "$(classify "$u")" "$(version_of "$m" [Ff]lask)" "${m#./}: flask" "${u#./}"
  fi
  if declares "$m" "sqlalchemy" || declares "$m" "SQLAlchemy"; then
    u="$(uses "$d" 'from sqlalchemy|import sqlalchemy' '*.py')"
    emit "$rel" "sqlalchemy" "$(classify "$u")" "" "${m#./}: sqlalchemy" "${u#./}"
  fi
done <<EOF
$(find "$REPO" \( $PRUNE \) -prune -o -type f \( -name pyproject.toml -o -name requirements.txt -o -name setup.py -o -name Pipfile \) -print 2>/dev/null)
EOF

# ---------- Go ----------
while IFS= read -r m; do
  [ -n "$m" ] || continue
  d="$(dirname "$m")"; rel="${d#./}"
  gv="$(grep -oE '^go[[:space:]]+[0-9.]+' "$m" 2>/dev/null | head -1 | grep -oE '[0-9.]+')"
  emit "$rel" "go" "established" "$gv" "${m#./}"
  for fw in gin-gonic/gin labstack/echo go-chi/chi spf13/cobra; do
    grep -q "$fw" "$m" 2>/dev/null || continue
    short="$(basename "$fw")"
    u="$(uses "$d" "$fw" '*.go')"
    emit "$rel" "$short" "$(classify "$u")" "" "${m#./}: $fw" "${u#./}"
  done
done <<EOF
$(find "$REPO" \( $PRUNE \) -prune -o -type f -name go.mod -print 2>/dev/null)
EOF

# ---------- Rust ----------
while IFS= read -r m; do
  [ -n "$m" ] || continue
  d="$(dirname "$m")"; rel="${d#./}"
  emit "$rel" "rust" "established" "" "${m#./}"
  for fw in axum actix-web rocket tokio; do
    declares "$m" "$fw" || continue
    u="$(uses "$d" "use ${fw%%-*}" '*.rs')"
    emit "$rel" "$fw" "$(classify "$u")" "$(version_of "$m" "$fw")" "${m#./}: $fw" "${u#./}"
  done
done <<EOF
$(find "$REPO" \( $PRUNE \) -prune -o -type f -name Cargo.toml -print 2>/dev/null)
EOF

# ---------- Java ----------
while IFS= read -r m; do
  [ -n "$m" ] || continue
  d="$(dirname "$m")"; rel="${d#./}"
  emit "$rel" "java" "established" "" "${m#./}"
  if grep -q 'spring-boot' "$m" 2>/dev/null; then
    sv="$(grep -oE 'spring-boot[^<]*</?version>[0-9.]+' "$m" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    [ -z "$sv" ] && sv="$(grep -A2 'spring-boot' "$m" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    u="$(uses "$d" 'org.springframework.boot' '*.java')"
    case "$sv" in
      3.*) claim="spring-boot-3" ;;
      2.*) claim="spring-boot-2" ;;
      *)   claim="spring-boot" ;;
    esac
    emit "$rel" "$claim" "$(classify "$u")" "$sv" "${m#./}: spring-boot" "${u#./}"
  fi
done <<EOF
$(find "$REPO" \( $PRUNE \) -prune -o -type f \( -name pom.xml -o -name build.gradle -o -name build.gradle.kts \) -print 2>/dev/null)
EOF

# ---------- Unsupported ecosystems: raw manifest evidence only ----------
while IFS= read -r m; do
  [ -n "$m" ] || continue
  rel="${m#./}"
  emit "$(dirname "$rel")" "unknown-ecosystem" "unknown" "" "$rel"
done <<EOF
$(find "$REPO" \( $PRUNE \) -prune -o -type f \( -name Gemfile -o -name composer.json -o -name mix.exs \
   -o -name pubspec.yaml -o -name Package.swift -o -name build.sbt -o -name deps.edn -o -name '*.csproj' \) -print 2>/dev/null)
EOF

# ---------- Plan pass: intent only, never adoption ----------
if [ -n "$PLAN" ] && [ -f "$PLAN" ]; then
  # slug:regex — ambiguous English words (next, echo, chi, gin, rocket, flask) need a
  # framework-specific pattern, or plan prose like "the next 7 days" emits a false claim.
  for pair in \
    "nextjs:next[.]?js" "react:react" "express:express[.]?js|expressjs|express server|express app" \
    "nestjs:nest[.]?js" "vue:vue[.]?js|vuejs|vue component" "svelte:svelte" \
    "fastapi:fastapi|fast api" "django:django" "flask:flask app|flask server|python flask|flask[)]|flask," \
    "sqlalchemy:sqlalchemy" "gin:gin-gonic|gin framework|gin router" "echo:labstack|echo framework" \
    "chi:go-chi|chi router" "cobra:spf13|cobra cli|cobra command" "axum:axum" \
    "actix:actix" "rocket:rocket-rs|rocket framework|rocket[.]rs" "spring-boot:spring boot|springboot" \
    "postgres:postgres" "redis:redis" "kafka:kafka" "rabbitmq:rabbitmq" "mongodb:mongodb|mongo db" \
    "kubernetes:kubernetes|k8s" "docker:docker" "celery:celery" "graphql:graphql" \
    "rails:rails|activerecord|active record" "laravel:laravel" "dotnet:asp[.]net|dotnet" \
    "elixir:phoenix framework|elixir" "sidekiq:sidekiq"; do
    slug="${pair%%:*}"; pat="${pair#*:}"
    if grep -qiE "(^|[^a-z])($pat)([^a-z]|$)" "$PLAN" 2>/dev/null; then
      emit "plan" "$slug" "proposed" "" "$PLAN"
    fi
  done
fi

printf '{"claims":[%s]}\n' "$(printf '%s' "$CLAIMS" | sed 's/,$//')"
