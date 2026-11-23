#!/usr/bin/env bash
# Воспроизводит весь сценарий лабы 5 с нуля в каталоге ./tictactoe-config
# Использование:  GIT_AUTHOR_NAME="Иванов И.И." GIT_AUTHOR_EMAIL=you@example.com ./build_repo.sh
set -euo pipefail

NAME="${GIT_AUTHOR_NAME:-Student}"
EMAIL="${GIT_AUTHOR_EMAIL:-student@example.com}"
export GIT_AUTHOR_NAME="$NAME" GIT_COMMITTER_NAME="$NAME"
export GIT_AUTHOR_EMAIL="$EMAIL" GIT_COMMITTER_EMAIL="$EMAIL"

rm -rf tictactoe-config origin.git
git init -q -b main tictactoe-config
cd tictactoe-config

# ---------- 1. начальные коммиты на main ----------
cat > config.py <<'PY'
"""Конфигурация игрового поля «Крестики-нолики»."""

BOARD_SIZE = 4          # размер поля N x N
WIN_LENGTH = 4          # сколько подряд нужно для победы
START_CELLS = {}        # стартовая позиция: {(строка, столбец): "X" | "O"}
FIRST_PLAYER = "X"      # кто ходит первым
PY

cat > game.py <<'PY'
"""Минимальная логика игры. Все правила берутся из config.py."""
import config


def new_board():
    board = [["." for _ in range(config.BOARD_SIZE)] for _ in range(config.BOARD_SIZE)]
    for (r, c), mark in config.START_CELLS.items():
        board[r][c] = mark
    return board


def winner(board):
    """Возвращает 'X', 'O' или None. Ищет WIN_LENGTH одинаковых подряд."""
    n, k = config.BOARD_SIZE, config.WIN_LENGTH
    for r in range(n):
        for c in range(n):
            mark = board[r][c]
            if mark == ".":
                continue
            for dr, dc in ((0, 1), (1, 0), (1, 1), (1, -1)):
                end_r, end_c = r + dr * (k - 1), c + dc * (k - 1)
                if not (0 <= end_r < n and 0 <= end_c < n):
                    continue
                if all(board[r + dr * i][c + dc * i] == mark for i in range(k)):
                    return mark
    return None


def render(board):
    return "\n".join(" ".join(row) for row in board)


if __name__ == "__main__":
    print(render(new_board()))
PY

cat > test_game.py <<'PY'
import config
import game


def test_config_is_consistent():
    assert 1 <= config.WIN_LENGTH <= config.BOARD_SIZE
    assert config.FIRST_PLAYER in ("X", "O")
    for (r, c), mark in config.START_CELLS.items():
        assert 0 <= r < config.BOARD_SIZE and 0 <= c < config.BOARD_SIZE
        assert mark in ("X", "O")


def test_new_board_has_configured_size():
    board = game.new_board()
    assert len(board) == config.BOARD_SIZE
    assert all(len(row) == config.BOARD_SIZE for row in board)


def test_row_win_is_detected():
    board = game.new_board()
    for c in range(config.WIN_LENGTH):
        board[0][c] = "X"
    assert game.winner(board) == "X"


def test_empty_board_has_no_winner_unless_start_cells_win():
    assert game.winner(game.new_board()) is None
PY

cat > README.md <<'MD'
# Крестики-нолики: конфиг карты (черновик)

Мини-проект для лабораторной по Git. Правила игры лежат в `config.py`.
MD

printf '__pycache__/\n*.pyc\n.pytest_cache/\n' > .gitignore

git add .gitignore config.py && git commit -q -m "feat: add config.py with default 4x4 board rules"
git add game.py README.md      && git commit -q -m "feat: add game logic that reads rules from config"
git add test_game.py           && git commit -q -m "test: add config consistency and win-detection tests"

# ---------- 2. ветка variant-3x3 ----------
git switch -q -c variant-3x3
cat > config.py <<'PY'
"""Конфигурация игрового поля «Крестики-нолики»."""

BOARD_SIZE = 3          # классическое поле 3 x 3
WIN_LENGTH = 3          # три в ряд
START_CELLS = {}        # пустое поле
FIRST_PLAYER = "X"      # крестики ходят первыми
PY
git commit -q -am "feat(rules): classic 3x3 variant, 3 in a row, empty start"

# ---------- 3. ветка variant-custom (от того же main) ----------
git switch -q main
git switch -q -c variant-custom
cat > config.py <<'PY'
"""Конфигурация игрового поля «Крестики-нолики»."""

BOARD_SIZE = 5                      # большое поле 5 x 5
WIN_LENGTH = 4                      # четыре в ряд
START_CELLS = {(2, 2): "O"}         # в центре стоит нолик
FIRST_PLAYER = "O"                  # ходят ноликами
PY
git commit -q -am "feat(rules): custom 5x5 variant, 4 in a row, O in the center"

# ---------- 4. сливаем первую ветку в main (без конфликта) ----------
git switch -q main
git merge -q --no-ff variant-3x3 -m "merge: variant-3x3 into main"

# ---------- 5. сливаем вторую: КОНФЛИКТ ----------
if git merge --no-ff variant-custom -m "merge: variant-custom into main"; then
  echo "ОШИБКА: конфликт не возник" >&2; exit 1
fi
git status --short
cp config.py ../conflicted_config.py.txt       # снимок файла с маркерами для README

# ---------- 6. разрешение конфликта ----------
# Итоговые правила: классика 3x3 (из variant-3x3), но сохраняем поддержку
# стартовых клеток и выбор первого игрока из custom: значения по умолчанию безопасные.
cat > config.py <<'PY'
"""Конфигурация игрового поля «Крестики-нолики».

Итоговые правила (разрешение конфликта variant-3x3 / variant-custom):
классическое поле 3x3, три в ряд, пустой старт, первым ходит X.
Расширенный вариант (5x5, 4 в ряд, O в центре) вынесен в PRESETS["custom"].
"""

BOARD_SIZE = 3          # классическое поле 3 x 3
WIN_LENGTH = 3          # три в ряд
START_CELLS = {}        # пустое поле
FIRST_PLAYER = "X"      # крестики ходят первыми

# Пресет из ветки variant-custom: сохранён, чтобы не терять работу.
PRESETS = {
    "custom": {
        "BOARD_SIZE": 5,
        "WIN_LENGTH": 4,
        "START_CELLS": {(2, 2): "O"},
        "FIRST_PLAYER": "O",
    },
}
PY
python3 -m pytest -q test_game.py
git add config.py
git commit -q -m "merge: variant-custom into main, resolve config conflict (keep classic 3x3, preset for custom)"

# ---------- 7. «удалённый» репозиторий: локальный bare-репозиторий ----------
cd ..
git init -q --bare -b main origin.git
cd tictactoe-config
git remote add origin ../origin.git
git push -q -u origin --all

# имитация работы второго разработчика: клонируем, коммитим, делаем pull
cd ..
rm -rf peer && git clone -q origin.git peer
( cd peer && git config user.name "Peer" && git config user.email "peer@example.com" \
  && printf '\n## Правила\n\nСм. `config.py`: итоговый вариант: 3x3, три в ряд; пресет `custom` — 5x5.\n' >> README.md \
  && git commit -q -am "docs: describe final rules in README" && git push -q origin main )
rm -rf peer
cd tictactoe-config
git pull -q origin main            # fast-forward: подтягиваем чужой коммит
git remote remove origin           # в сданном репозитории origin = ваш GitHub/GitLab (см. README)
cd ..
echo "--- ГОТОВО ---"
git -C tictactoe-config log --graph --oneline --all
