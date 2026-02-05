#!/usr/bin/env bash
# viib-etch 실행 스크립트 — UI 웹 서버를 띄웁니다.
#
# 사용법:
#   ./run.sh          — 서버 실행 (인증서 없으면 HTTP, 있으면 HTTPS)
#   ./run.sh [포트]   — 지정 포트로 서버 실행
#   ./run.sh dev [포트] — 변경 시 자동 재시작 (코드/설정 수정 후 서버만 다시 뜸)
#   ./run.sh cert     — HTTPS용 셀프사인 인증서 생성 (zdte_cert.crt, zdte_key.key)
#   ./run.sh token    — UI 로그인용 랜덤 토큰 생성 후 .viib-etch-tokens 에 추가
#
# 환경변수: VIIB_ETCH_UI_TOKEN (또는 .viib-etch-tokens), VIIB_ETCH_UI_HTTP=1 (HTTP 강제)
#
# 인증서 만드는 방법 (HTTPS 사용 시):
#   ./run.sh cert
#   또는 수동:
#   openssl req -x509 -newkey rsa:4096 -keyout zdte_key.key -out zdte_cert.crt -days 365 -nodes -subj "/CN=localhost"

set -e
cd "$(dirname "$0")"

# 서브커맨드: dev — 파일 변경 시 자동 재시작 (Node 18.11+ --watch)
DEV_MODE=
if [ "${1:-}" = "dev" ]; then
  DEV_MODE=1
  shift
fi

# 서브커맨드: cert — 셀프사인 인증서 생성
if [ "${1:-}" = "cert" ]; then
  CERT="${VIIB_ETCH_UI_CERT:-zdte_cert.crt}"
  KEY="${VIIB_ETCH_UI_KEY:-zdte_key.key}"
  if [ -f "$CERT" ] && [ -f "$KEY" ]; then
    echo "이미 인증서가 있습니다: $CERT, $KEY"
    echo "덮어쓰려면 기존 파일을 삭제한 뒤 다시 실행하세요."
    exit 0
  fi
  echo "HTTPS용 셀프사인 인증서 생성 중..."
  openssl req -x509 -newkey rsa:4096 -keyout "$KEY" -out "$CERT" -days 365 -nodes -subj "/CN=localhost"
  echo "생성됨: $CERT, $KEY"
  echo "다음에 ./run.sh 실행 시 HTTPS로 동작합니다."
  exit 0
fi

# 서브커맨드: token — UI 로그인용 랜덤 토큰 생성 후 .viib-etch-tokens 에 추가
if [ "${1:-}" = "token" ]; then
  TOKENS_FILE="${VIIB_ETCH_TOKENS_FILE:-.viib-etch-tokens}"
  NEW_TOKEN=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
  echo "$NEW_TOKEN" >> "$TOKENS_FILE"
  echo "토큰을 생성해 $TOKENS_FILE 에 추가했습니다."
  echo ""
  echo "생성된 토큰 (복사해서 UI 로그인에 사용):"
  echo "  $NEW_TOKEN"
  echo ""
  echo "이 토큰으로 UI 접속 후 설정(⚙)에서 입력하면 됩니다."
  exit 0
fi

# Node 확인
if ! command -v node &>/dev/null; then
  echo "오류: Node.js가 설치되어 있지 않습니다." >&2
  exit 1
fi

# 포트 인자 (dev 모드면 $1, 아니면 $1)
PORT="${1:-}"

# 토큰이 없으면 안내 (실행은 시도하고, viib-etch-ui.js가 exit 2로 알려줌)
if [ -z "$VIIB_ETCH_UI_TOKEN" ] && [ ! -f ".viib-etch-tokens" ]; then
  echo "안내: VIIB_ETCH_UI_TOKEN을 설정하거나 .viib-etch-tokens 파일을 만드세요."
  echo "  예: export VIIB_ETCH_UI_TOKEN=your-secret-token"
  echo "  또는: echo 'your-secret-token' > .viib-etch-tokens"
  echo ""
fi

# 인증서 없으면 HTTP 모드로 실행 (HTTPS용: 아래 주석 참고)
CERT="${VIIB_ETCH_UI_CERT:-zdte_cert.crt}"
KEY="${VIIB_ETCH_UI_KEY:-zdte_key.key}"
if [ -z "$VIIB_ETCH_UI_HTTP" ] && { [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; }; then
  export VIIB_ETCH_UI_HTTP=1
  echo "인증서 없음 — HTTP 모드로 실행 (https:// 대신 http:// 로 접속)"
  echo "  HTTPS 사용: ./run.sh cert 로 인증서 생성 후 ./run.sh 실행"
  echo ""
fi

if [ -n "$PORT" ]; then
  export VIIB_ETCH_UI_PORT="$PORT"
fi

if [ -n "$DEV_MODE" ]; then
  echo "개발 모드: 파일 변경 시 자동 재시작 (종료: Ctrl+C)"
  echo ""
  exec node --watch viib-etch-ui.js web ${PORT:+"$PORT"}
fi

exec node viib-etch-ui.js web ${PORT:+"$PORT"}
