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

## 2026-08-07 (третья итерация: нативный формат)

### Decisions
- Причина «выцветания» кастомных стилей в длинных сессиях — не размер файлов: харнесс подкрепляет свои built-in стили каждый ход, кастомные — нет. Формат тела тоже имел значение: файлы читались как документация, а не как директивы.
- Все 19 стилей переведены на формат, в котором Claude Code держит собственные стили: identity-строка («You are an interactive agent that helps users with software engineering tasks. In addition to completing those tasks, you must …») + маркер `# <Name> Style Active` + процедурные правила («In every response: …»). В этом виде харнесс воспринимает стиль как родной.
- Из тел стилей удалено всё human-facing: credits-футеры со ссылками, мета-комментарии, «Before:»-блоки примеров (негативный пример = инъекция нежелательного текста в системный промпт каждой сессии). Тело стиля уходит в системный промпт дословно — каждый лишний байт разбавляет инструкции. Атрибуция переехала в docs/CREDITS.md; README-таблицы уже кредитовали всех.
- Новый enforcement-механизм: hooks/style-reminder.sh (UserPromptSubmit) даёт активному кастомному стилю то же per-turn подкрепление, что имеют built-ins; молчит для default и built-in стилей (не дублируем). install.sh получил флаг `--enforce` (идемпотентная регистрация в settings.json через python3, sed-fallback).
- format-guide: секция «Why the format below works», конвенции #1 (структура built-in), #7 (positive example only), #9 (zero human-facing content). Убрано неточное «Claude Code keeps reminding the model to follow them» — само по себе это верно только для built-ins; с `--enforce` становится верно и для наших.
- style-maker синхронизирован: identity line + Style Active header в шаблоне, positive example only, Step 4 предлагает enforcement-хук.

### Deviations
- Конвенция «before/after examples in the body» (была #6) отменена: противоречила собственной доктрине positive framing. Before/after остаётся в README для людей.

### Gotchas
- install.sh: `set -- "${args[@]}"` на пустом массиве падает под bash 3.2 + set -u; используем `${args[@]+"${args[@]}"}`.
- Тело стиля инжектится дословно, frontmatter — нет. HTML-комментарии в теле тоже уходят в промпт.

### Open questions (решены за пользователя)
- Хук ставится опционально (`--enforce`), не по умолчанию: молча писать hooks в чужой settings.json при установке «просто стиля» — слишком инвазивно.
