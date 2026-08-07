# implementation-notes — awesome-claude-output-styles

## 2026-08-06

### Decisions
- Один install.sh с аргументом стиля вместо 17 отдельных скриптов: per-style curl достигается через `bash -s -- <style>`, меньше дублирования. Локальный запуск из чекаута копирует файлы вместо curl (для тестов до пуша).
- Активация: outputStyle берётся из `name:` frontmatter установленного файла (sed), а не из захардкоженной мапы — один источник истины.
- Блоклист 2026 Claudisms живёт в docs/claudisms-2026.md (для людей), сам стиль no-slop сформулирован позитивно: Anthropic и Pocock оба фиксируют, что негация призывает паттерн.
- style-maker при нескольких аргументах не активирует ничего (активация только при ровно одном стиле).

### Deviations
- (пока нет)

### Gotchas
- `/output-style` удалён в CC v2.1.91 — во всех текстах только `/config` и settings.json.
- Стиль применяется только после рестарта/нового /clear — везде напоминаем.

### Open questions (решены за пользователя)
- Активация пишется в глобальный ~/.claude/settings.json (паттерн pohuy), не в project-local settings.local.json: curl-инсталлятор — пользовательский, не проектный сценарий.

## 2026-08-06 (вторая итерация: виральное оформление)
- Баннер: Magnific GPT-2 (2:1, 2k, high) со style-reference от Сергея (riso/стипплинг, крем+пыльно-голубой+коралл). Выбран вариант A (изящнее типографика), B лежит рядом как banner-alt.jpg. PNG 4.3MB пережаты в JPEG 1600w ~540KB.
- README пересобран по чек-листу viral-репо (эталон caveman): центрированный hero → тэглайн «same brain. seventeen mouths.» → 4 flat-бейджа (каждый — ссылка) → dot-nav → позиционирование → эпиграф Gruhn → HTML-таблица before/after → ASCII stat box → install с [!TIP] → таблицы стилей с колонкой «Method · author».
- Авторы с проверенными X-хэндлами: @mattpocockuk, @julius_brussee, @blader, @ConorBronsdon, @hvpandya, @jcotellese, @petergyang, @joshtriedcoding. Без X (не найдено — не гадаем): Ghriss, Boulegroun, Duplar Mello, Konidala, Nims, Reddy, Gruhn.
- petergyang/no-ai-slop добавлен в каталог (кредит на репо, НЕ на платную рассылку).
- Gotcha: social preview картинку GitHub через API не ставит — только руками в Settings → Social preview (положить banner.jpg).

## 2026-08-07 (третья итерация: паритет с built-in стилями Anthropic)

### Decisions
- Реверс бинаря CC v2.1.223: built-in стили (Proactive/Explanatory/Learning) получают **per-turn system reminder** «<Name> output style is active. Remember to follow the specific guidelines for this style.» — кастомные НЕ получают ничего (мапа `The` в коде содержит только built-ins). Это главная причина «выцветания» кастомных стилей в длинных сессиях, а не размер файлов (Learning — 4.3KB и работает).
- Все 19 стилей переведены на структуру built-in промптов: identity-строка («You are an interactive agent that helps users with software engineering tasks. In addition to completing those tasks, you must …») + маркер `# <Name> Style Active` + процедурные правила («In every response: …»).
- Из тел стилей удалено всё human-facing: credits-футеры со ссылками, мета-комментарии («this style is written in positives on purpose», origin stories wait-what/no-ai-slop, honesty note gen-z), «Before:»-блоки примеров (негативный пример = инъекция slop-текста в системный промпт каждой сессии). Атрибуция переехала в docs/CREDITS.md; README-таблицы уже кредитовали всех.
- Новый enforcement-механизм: hooks/style-reminder.sh (UserPromptSubmit) эмитит ту же самую строку-напоминание, что харнесс даёт built-ins; молчит для default/Proactive/Explanatory/Learning (не дублируем). install.sh получил флаг `--enforce` (идемпотентная регистрация в settings.json через python3, sed-fallback).
- format-guide: новая секция «How the harness actually treats your style» (факты из бинаря), конвенции #1 (структура built-in), #7 (positive example only), #9 (zero human-facing content). Исправлен пиздёж «Claude Code keeps reminding the model to follow them» — это было верно только для built-ins.
- style-maker синхронизирован: identity line + Style Active header в шаблоне, positive example only, Step 4 предлагает enforcement-хук.

### Deviations
- Конвенция «before/after examples in the body» (была #6) отменена: противоречила собственной доктрине positive framing. Before/after остаётся в README для людей.

### Gotchas
- Кастомный стиль, названный «Explanatory»/«Learning»/«Proactive», шэдовит built-in и получает harness-reminder бесплатно — грязный хак, в репо не используем.
- install.sh: `set -- "${args[@]}"` на пустом массиве падает под bash 3.2 + set -u; используем `${args[@]+"${args[@]}"}`.
- Loader стилей: `prompt: i.trim()` — тело файла уходит в системный промпт байт-в-байт, frontmatter не уходит. HTML-комментарии в теле ТОЖЕ уходят.

### Open questions (решены за пользователя)
- Хук ставится опционально (`--enforce`), не по умолчанию: молча писать hooks в чужой settings.json при установке «просто стиля» — слишком инвазивно.
- Локальный ~/.claude Сергея не трогал (его Pohuy-стиль страдает тем же выцветанием — предложено отдельно).
