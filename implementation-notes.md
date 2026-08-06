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
