# 🍺 Brewfile

macOS 환경을 한 번에 세팅하기 위한 Homebrew Bundle 저장소입니다.
프로필(base / dev / personal)별로 Brewfile을 나눠 관리하고, `install.sh` 스크립트로 선택 설치할 수 있습니다.

## 구조

```
.
├── install.sh              # 설치 스크립트
└── brewfiles/
    ├── base.Brewfile       # 공통 - 항상 설치됨
    ├── dev.Brewfile        # 개발 도구
    └── personal.Brewfile   # 개인용 앱
```

## 사용법

```bash
./install.sh              # base만 설치
./install.sh dev          # base + dev
./install.sh personal     # base + personal
./install.sh dev personal # 여러 프로필 동시 설치
./install.sh all          # 전부 설치
```

- Homebrew가 없으면 자동으로 설치합니다 (Apple Silicon 경로 설정 포함).
- `base.Brewfile`은 어떤 프로필을 선택해도 항상 먼저 설치됩니다.
- `dev`, `personal`, `all` 프로필은 **인터랙티브 모드**로 동작합니다 — 패키지를 하나씩 보여주고 설치 여부를 `[Y/n]`으로 물어봅니다. 선택한 항목만 모아서 `brew bundle`로 설치합니다.
- 일부 패키지 설치가 실패해도 중단하지 않고 계속 진행합니다.
