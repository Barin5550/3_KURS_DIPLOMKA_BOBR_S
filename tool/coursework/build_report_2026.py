"""Сборка пояснительной записки по методическим указаниям колледжа 2026 года.

Структура (методические указания, п. 1.5 и 2.1, модуль «Разработка мобильных
приложений»): введение, раздел 1 «Теоретическая часть», раздел 2
«Проектирование программного продукта», раздел 3 «Практическая часть
(внедрение и испытание)», заключение, список литературы, приложения.

Оформление (п. 3): Times New Roman 14, интервал 1,5, выравнивание по ширине,
абзацный отступ 1,25 см, поля: левое 30 мм, верхнее 20 мм, правое 10 мм,
нижнее 20 мм; без полужирного шрифта и подчёркивания; номер страницы внизу
по центру, на титульном листе и содержании не проставляется; подписи
«Рисунок 2.1. …» под рисунком по центру, «Таблица 1.1. …» над таблицей;
текст таблиц — 12 пт; литература — в порядке упоминания в тексте.

Текст берётся из файлов docs/coursework/*.md и раскладывается по новой
структуре. Pandoc не нужен, только python-docx и Pillow.

Запуск из корня репозитория:
    python3 tool/coursework/build_report_2026.py [папка_для_результата]
"""

import os
import re
import sys

from PIL import Image
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "docs", "coursework")
OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "coursework")
OUT_NAME = "Курсовой_проект_Баринов_Н.В._ПО2410.docx"

FONT = "Times New Roman"
STUDENT_FULL = "Баринов Николай Владимирович"
GROUP = "ПО2410"
SUPERVISOR = "Синтиков Е. К."
TOPIC = "Создание приложения для автоматического формирования персонального плана обучения"


def read(name):
    with open(os.path.join(SRC, name), encoding="utf-8") as f:
        return f.read()


def section(md, heading):
    """Текст под заголовком heading (без самого заголовка) до следующего
    заголовка того же или более высокого уровня."""
    lines = md.split("\n")
    start = None
    level = 0
    for i, line in enumerate(lines):
        m = re.match(r"^(#+) (.*)$", line)
        if m and m.group(2).strip().startswith(heading):
            start, level = i + 1, len(m.group(1))
            break
    if start is None:
        raise SystemExit(f"Не найден раздел: {heading}")
    out = []
    in_code = False
    for line in lines[start:]:
        if line.startswith("```"):
            in_code = not in_code
        m = re.match(r"^(#+) ", line)
        if not in_code and m and len(m.group(1)) <= level:
            break
        out.append(line)
    return "\n".join(out).strip("\n")


def drop_code(md, keep_mermaid_as=None):
    """Убирает блоки кода из основной части. Диаграммы Mermaid заменяются
    готовыми рисунками из docs/coursework/diagrams по очереди."""
    out, in_code, buf_kind = [], False, None
    for line in md.split("\n"):
        if line.startswith("```"):
            if not in_code:
                in_code, buf_kind = True, line[3:].strip()
                if buf_kind == "mermaid" and keep_mermaid_as:
                    out.append(f"![]({keep_mermaid_as.pop(0)})")
            else:
                in_code = False
            continue
        if not in_code:
            out.append(line)
    return "\n".join(out)


def sub(md, pairs):
    for a, b in pairs:
        if a not in md:
            raise SystemExit(f"Не найден фрагмент для замены: {a[:60]}")
        md = md.replace(a, b)
    return md


# Требование к объёму (п. 3.6): основная часть 15–25 страниц. Подробности,
# которые повторяются в других подразделах или в приложениях, в записку не входят.
DROP_LINES = [
    "**Целевая аудитория:**", "- студенты колледжей и вузов", "- самоучки, изучающие",
    "- люди, которые меняют профессию", "Общее у этих пользователей одно",
    "**Методы разработки:**",
    "**Ограниченные ресурсы.**", "**Несколько платформ.**",
    "**2. Однонаправленный поток", "**3. Декларативный интерфейс.**",
    "**6. Обработка ошибок и пустых", "**8. Тестирование.**",
    "**Provider** прост", "Данные передаются в формате **JSON**",
    "Сервер написан на Dart с библиотекой **shelf**",
    "**Управление состоянием и внедрение зависимостей.**",
    "Чтобы экраны обновлялись сами", "Корректность реализации PBKDF2",
    "Сервис уведомлений скрыт", "Вход занимает около половины секунды",
    "Текст ключевых частей сервера", "Альтернатива — писать логику прямо в виджетах",
    "Каталог читает сервер при запуске", "Таблица `api_tokens` появилась",
    "Также существует Kotlin Multiplatform",
]
# Блоки: от строки, начинающейся с первого текста, до строки со вторым (не включая).
DROP_BLOCKS = [
    ("**Основной функционал приложения:**", "**Практическая значимость работы.**"),
    ("Меры защиты на сервере:", "### 2.2.3"),
    ("### 2.3.6 Пример работы алгоритма", "### 2.3.7 Перепланирование"),
    ("### 1.4.6 Навигация: go_router", "### 1.4.8 Дополнительные пакеты"),
    ("- **fl_chart**", "Таблица 1.6"),
]


def trim(md):
    for a, b in DROP_BLOCKS:
        s = md.index("\n" + a) + 1
        e = md.index("\n" + b, s) + 1
        md = md[:s] + md[e:]
    lines = [l for l in md.split("\n") if not any(l.startswith(p) for p in DROP_LINES)]
    md = "\n".join(lines)
    md = md.replace("### 2.3.7 Перепланирование", "### 2.3.6 Перепланирование")
    md = md.replace("### 1.4.8 Дополнительные пакеты", "### 1.4.6 Итоговый стек технологий")
    # Перенумеровать оставшиеся принципы разработки в п. 1.3.
    s = md.index("## 1.3 ")
    e = md.index("## 1.4 ")
    n = iter(range(1, 20))
    part = re.sub(r"^\*\*\d+\. ", lambda m: f"**{next(n)}. ", md[s:e], flags=re.M)
    return md[:s] + part + md[e:]


def assemble():
    intro = read("01_introduction.md")
    ch1 = read("02_chapter1_theory.md")
    ch2 = read("04_chapter2_practice.md")
    concl = read("05_conclusion.md")
    refs = read("03_references.md")
    apps = read("06_appendices.md")

    d = "diagrams/04_chapter2_practice_"
    diag = {k: f"{d}{n}.png" for k, n in (("arch", 1), ("er", 2), ("algo", 3), ("nav", 4))}

    parts = []
    # ---------------- Введение
    intro = section(intro, "ВВЕДЕНИЕ")
    intro = re.sub(
        r"\*\*Структура работы\.\*\*.*",
        "Структура работы. Курсовой проект состоит из введения, трёх разделов, заключения, "
        "списка использованной литературы и приложений. В первом разделе рассмотрены общие "
        "сведения о мобильных приложениях и предметной области, проведён обзор существующих "
        "решений, описаны этапы и принципы разработки и обоснован выбор программных средств. "
        "Во втором разделе описаны структура приложения и навигация, база данных и API "
        "сервера, алгоритм формирования плана. В третьем разделе представлены реализованные "
        "функции и экраны приложения, результаты тестирования и правила эксплуатации.",
        intro, flags=re.S)
    intro = intro.replace("приведён в п. 1.4.", "приведён в п. 1.2.")
    parts.append("# ВВЕДЕНИЕ\n\n" + intro)

    # ---------------- Раздел 1
    s11 = section(ch1, "1.1 Анализ предметной области")
    s12 = section(ch1, "1.2 Особенности мобильных приложений")
    s13 = section(ch1, "1.3 Принципы разработки")
    s14 = section(ch1, "1.4 Анализ аналогичных решений")
    s15 = section(ch1, "1.5 Обоснование выбора технологий")
    c1 = section(ch1, "Выводы по главе 1")
    s12 = s12.replace("(п. 1.5.1)", "(п. 1.4.1)")
    s15 = s15.replace("(п. 2.8)", "(п. 3.3)").replace("(п. 2.6.1)", "(п. 3.1)") \
        .replace("(п. 1.5.5)", "(п. 1.4.5)").replace("(п. 1.3)", "(п. 1.3)")
    s15 = re.sub(r"^### 1\.5\.", "### 1.4.", s15, flags=re.M)
    s11 = s11.replace("### 1.1.5 Требования к приложению", "### 1.1.5 Требования к приложению")
    stages = (
        "Разработка мобильного приложения проходит несколько этапов. На этапе анализа "
        "изучается предметная область, формулируются цель и требования, рассматриваются "
        "аналоги. На этапе проектирования определяются архитектура, структура данных, "
        "алгоритмы, экраны и переходы между ними. Затем выполняется реализация: пишется код "
        "приложения и сервера, подключаются библиотеки. Параллельно и после реализации "
        "проводится тестирование: модульное, виджет- и интеграционное. Завершают работу "
        "сборка релизной версии, установка на устройства пользователей и сопровождение, "
        "то есть исправление ошибок и развитие по замечаниям.\n\n"
        "Приложение «Маршрут» разрабатывалось в два этапа. В первом семестре была создана "
        "версия с локальной базой данных на устройстве: каталог тем, алгоритм плана, экраны "
        "авторизации, онбординга, главной страницы, плана и профиля. Во втором семестре по "
        "итогам анализа первой версии добавлены перепланирование, несколько планов, свои "
        "темы, заметки, статистика, Pomodoro, усилена защита паролей и разработан сервер "
        "REST API, через который приложение работает с данными.\n\n"
        "С учётом особенностей мобильных приложений (п. 1.1.6) на всех этапах применяются "
        "следующие принципы.")
    s13 = re.sub(r"^С учётом перечисленных особенностей при разработке используются следующие принципы\.",
                 "", s13, flags=re.M).strip()
    c1 = c1.replace("Сформулированы принципы разработки", "Описаны этапы и принципы разработки")
    r1 = (
        "# 1 ТЕОРЕТИЧЕСКАЯ ЧАСТЬ\n\n"
        "## 1.1 Общие сведения о мобильных приложениях\n\n"
        "Разрабатываемое мобильное приложение «Маршрут» автоматически формирует персональный "
        "план обучения. Ниже описаны предметная область приложения, требования к нему и "
        "особенности мобильных приложений, которые учитывались при разработке.\n\n"
        + s11 + "\n\n### 1.1.6 Особенности мобильных приложений\n\n" + s12
        + "\n\n## 1.2 Обзор существующих программных решений\n\n" + s14
        + "\n\n## 1.3 Основные этапы разработки мобильных приложений\n\n" + stages + "\n\n" + s13
        + "\n\n## 1.4 Анализ программных средств, используемых при разработке\n\n" + s15
        + "\n\n## Выводы по разделу 1\n\n" + c1)
    parts.append(r1)

    # ---------------- Раздел 2
    req = section(ch2, "2.1 Требования к приложению").replace("(глава 1)", "(раздел 1)")
    arch = section(ch2, "2.2 Архитектура приложения")
    db = section(ch2, "2.3 Проектирование базы данных")
    alg = section(ch2, "2.4 Алгоритм формирования плана")
    nav = section(ch2, "2.5.1 Навигация")
    style = section(ch2, "2.5.2 Оформление")
    adapt = section(ch2, "2.5.3 Адаптивность")
    c2 = section(ch2, "Выводы по главе 2")

    # Рисунки раздела 2: 2.1 архитектура, 2.2 карта экранов, 2.3 ER, 2.4 алгоритм.
    arch = drop_code(arch, [diag["arch"]])
    arch = arch.replace("(п. 2.3.2)", "(п. 2.2.2)").replace("(п. 2.3.3)", "(п. 2.2.3)")
    nav = drop_code(nav, [diag["nav"]])
    nav = sub(nav, [("Карта экранов показана на рисунке 2.4", "Карта экранов показана на рисунке 2.2"),
                    ("Рисунок 2.4 — Карта экранов", "Рисунок 2.2 — Карта экранов"),
                    ("Доступ к экранам проверяет одна функция `authRedirect`, которую go_router вызывает перед каждым переходом:",
                     "Доступ к экранам проверяет одна функция `authRedirect`, которую go_router вызывает "
                     "перед каждым переходом (полный текст — в приложении Ж).")])
    adapt = adapt.replace("(раздел 2.7)", "(подраздел 3.2)")
    db = drop_code(db, [diag["er"]])
    db = sub(db, [("Структура базы показана на рисунке 2.2", "Структура базы показана на рисунке 2.3"),
                  ("Рисунок 2.2 — ER-диаграмма", "Рисунок 2.3 — ER-диаграмма"),
                  ("Это проверено тестами (раздел 2.7).", "Это проверено тестами (подраздел 3.2)."),
                  ("(п. 2.3.2)", "(п. 2.2.2)"), ("(п. 2.6.1)", "(п. 3.1)"),
                  ("Пример запроса на создание заметки и ответа сервера:",
                   "Например, на запрос `POST /api/notes` с токеном и телом "
                   "`{\"title\": \"Списки в Python\", \"body\": \"append добавляет элемент в конец\"}` "
                   "сервер отвечает `201 Created` и номером новой заметки `{\"id\": 1}`."),
                  ("Ниже приведён фрагмент журнала сервера при работе с заметками: ошибочный вход, вход, получение активного плана, создание, изменение и удаление заметки, а также ответы на запрос без обязательного поля, запрос без токена и запрос к удалённой заметке.",
                   "По журналу сервера при работе с заметками ошибочный вход завершается ответом `400`, "
                   "успешный — `200`, создание заметки — `201`, изменение и удаление — `204`, "
                   "запрос без обязательного поля — `400`, без токена — `401`, к удалённой заметке — `404`."),
                  ("(рисунок 2.30)", "(рисунок 3.4)")])
    db = re.sub(r"^### 2\.3\.", "### 2.2.", db, flags=re.M)
    db = db.replace("(п. 2.2.3)", "(п. 2.2.3)")
    alg = drop_code(alg, [diag["algo"]])
    alg = sub(alg, [("(рисунок 2.3)", "(рисунок 2.4)"), ("Рисунок 2.3 — Схема", "Рисунок 2.4 — Схема"),
                    ("Для каталога из 20 тем это мгновенно. Фрагмент реализации:",
                     "Для каталога из 20 тем это мгновенно.")])
    alg = re.sub(r"^### 2\.4\.", "### 2.3.", alg, flags=re.M)
    c2a = [l for l in c2.split("\n") if re.match(r"^[1-5]\. ", l)]
    c2a = "\n".join(c2a).replace("Реализованы экраны", "Спроектированы экраны")
    r2 = (
        "# 2 ПРОЕКТИРОВАНИЕ ПРОГРАММНОГО ПРОДУКТА\n\n"
        "## 2.1 Разработка структуры мобильного приложения\n\n"
        "### 2.1.1 Требования к приложению\n\n" + req
        + "\n\n### 2.1.2 Архитектура приложения\n\n" + arch
        + "\n\n### 2.1.3 Навигация\n\n" + nav
        + "\n\n### 2.1.4 Оформление и адаптивность\n\n" + style + "\n\n" + adapt
        + "\n\n## 2.2 Проектирование базы данных и API сервера\n\n" + db
        + "\n\n## 2.3 Алгоритм формирования плана\n\n" + alg
        + "\n\n## Выводы по разделу 2\n\n" + c2a)
    parts.append(r2)

    # ---------------- Раздел 3
    mods = section(ch2, "2.6 Реализация основных модулей")
    mods = re.sub(r"^### 2\.6\.\d+ ", "### ", mods, flags=re.M)
    mods = mods.replace("(п. 2.3.2)", "(п. 2.2.2)").replace("(п. 2.3.3)", "(п. 2.2.3)")
    num = iter(range(1, 100))
    renum = {}

    def rename_h3(m):
        n = next(num)
        return f"### 3.1.{n + 1} {m.group(1)}"
    mods = re.sub(r"^### (.*)$", rename_h3, mods, flags=re.M)
    tests = section(ch2, "2.7 Тестирование")
    tests = sub(tests, [("Тестирование подробно описано в отдельном разделе (`docs/coursework/testing.md`): тест-кейсы, состав тестов и журнал найденных ошибок. Итоги приведены в таблице 2.7.",
                         "Приложение проверялось автоматическими тестами разных уровней, ручными "
                         "проверками и снимками экранов. Итоги приведены в таблице 3.1."),
                        ("Таблица 2.7 — Итоги тестирования", "Таблица 3.1 — Итоги тестирования"),
                        ("| См. `testing.md` |", "| Пройдены |")])
    build = section(ch2, "2.8 Сборка и развёртывание")
    screens = [
        ("02_login.png", "Экран входа"), ("03_register_validation.png", "Регистрация: сообщения об ошибках под полями"),
        ("26_server_address.png", "Окно адреса сервера API"), ("16_direction.png", "Онбординг: выбор направления"),
        ("17_diagnostic.png", "Онбординг: диагностический тест"), ("18_schedule.png", "Онбординг: расписание"),
        ("05_home.png", "Главная страница"), ("06_plan.png", "План по дням"),
        ("07_topics.png", "Вкладка «Темы»"), ("09_stats.png", "Статистика"),
        ("12_pomodoro.png", "Таймер Pomodoro"), ("10_profile.png", "Профиль"),
    ]
    # Окно адреса сервера — рисунок 3.3; в тексте 2.2.3 ссылка исправлена ниже.
    pairs = []
    for i in range(0, len(screens), 2):
        a, b = screens[i], screens[i + 1]
        pairs.append(f"!!PAIR screenshots/{a[0]}|Рисунок 3.{i + 1} — {a[1]}|"
                     f"screenshots/{b[0]}|Рисунок 3.{i + 2} — {b[1]}")
    screens_text = (
        "### 3.1.1 Экраны приложения\n\n"
        "Приложение реализовано полностью в соответствии с проектом раздела 2. После запуска "
        "заставка проверяет сохранённую сессию и открывает экран входа или главную страницу. "
        "Вход, регистрация и окно адреса сервера API показаны на рисунках 3.1–3.3. При первом "
        "входе пользователь проходит онбординг: выбирает направление, отвечает на вопросы "
        "диагностического теста и задаёт расписание (рисунки 3.4–3.6), после чего видит "
        "предпросмотр плана и сохраняет его.\n\n"
        "Главная страница показывает прогресс, часы, серию дней, число дней до дедлайна и "
        "задачи на сегодня; вкладка «План» — занятия по дням с фильтрами и поиском (рисунки "
        "3.7 и 3.8). Вкладка «Темы» содержит каталог направления с поиском, категориями, "
        "избранным и своими темами, вкладка «Статистика» — итоги, график часов по неделям, "
        "распределение по категориям и историю (рисунки 3.9 и 3.10). Таймер Pomodoro "
        "работает в режимах 25/5 и 50/10 минут, в профиле редактируются данные, меняется "
        "пароль, выбираются тема оформления и адрес сервера, выполняется выход (рисунки 3.11 и "
        "3.12). Кроме того, реализованы экраны «Мои планы», «Заметки», карточка занятия, "
        "настройки плана и удаление аккаунта с подтверждением паролем.\n\n"
        "Скриншоты получены программой `tool/screenshots/screenshots_test.dart` на тестовых "
        "данных: пользователь Алия, план «Flutter-разработчик».\n\n" + "\n\n".join(pairs))
    c3 = (
        "1. Реализованы все функции, заданные требованиями раздела 2: регистрация и вход, "
        "онбординг с диагностическим тестом, построение и перестройка плана, темы, заметки, "
        "статистика, Pomodoro, напоминания, профиль и удаление аккаунта.\n"
        "2. Пароли хранятся как хэш PBKDF2 с солью, доступ к данным выполняется по токену, "
        "ошибки сервера и связи показываются пользователю понятным текстом.\n"
        "3. Приложение проверено автоматическими тестами всех уровней, ручными проверками и "
        "матрицей снимков экранов; найденные ошибки исправлены.\n"
        "4. Подготовлены релизные сборки для Android, Windows и iPhone и программа-сервер API, "
        "описан порядок установки и эксплуатации.")
    r3 = (
        "# 3 ПРАКТИЧЕСКАЯ ЧАСТЬ (ВНЕДРЕНИЕ И ИСПЫТАНИЕ)\n\n"
        "## 3.1 Развитие функциональности мобильного приложения\n\n" + screens_text + "\n\n" + mods
        + "\n\n## 3.2 Результаты тестирования\n\n" + tests
        + "\n\n## 3.3 Правила эксплуатации разработанного мобильного приложения\n\n" + build
        + "\n\n## Выводы по разделу 3\n\n" + c3)
    parts.append(r3)

    # Ссылка на окно адреса сервера в п. 2.2.3.
    parts[2] = parts[2].replace("(рисунок 3.4)", "(рисунок 3.3)")

    concl = section(concl, "ЗАКЛЮЧЕНИЕ")
    parts.append("# ЗАКЛЮЧЕНИЕ\n\n" + concl)

    body = trim("\n\n".join(parts))

    # ---------------- Литература в порядке первого упоминания
    entries = {}
    for line in refs.split("\n"):
        m = re.match(r"^(\d+)\. (.*)$", line)
        if m:
            entries[int(m.group(1))] = m.group(2)
    order = []
    for m in re.finditer(r"\[(\d+(?:\s*[;,]\s*\d+)*)\]", body):
        for n in re.split(r"\s*[;,]\s*", m.group(1)):
            n = int(n)
            if n in entries and n not in order:
                order.append(n)
    mapping = {old: new for new, old in enumerate(order, 1)}

    def remap(m):
        nums = [mapping[int(n)] for n in re.split(r"\s*[;,]\s*", m.group(1)) if int(n) in mapping]
        return "[" + "; ".join(str(n) for n in sorted(nums)) + "]"
    body = re.sub(r"\[(\d+(?:\s*[;,]\s*\d+)*)\]", remap, body)
    ref_md = "# СПИСОК ИСПОЛЬЗОВАННОЙ ЛИТЕРАТУРЫ\n\n" + "\n".join(
        f"{mapping[o]}. {entries[o]}" for o in order)
    ref_md += ("\n\n!!SIGN")
    apps = "\n".join(l for l in apps.split("\n") if not l.startswith("<!--"))
    return body + "\n\n" + ref_md + "\n\n" + apps, len(order), len(entries)


# ---------------------------------------------------------------------------
# Markdown → DOCX
# ---------------------------------------------------------------------------

def set_font(run, size=14, mono=False):
    name = "Courier New" if mono else FONT
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = False
    run.font.underline = False
    rpr = run._element.get_or_add_rPr()
    fonts = rpr.find(qn("w:rFonts"))
    if fonts is None:
        fonts = OxmlElement("w:rFonts")
        rpr.append(fonts)
    for k in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        fonts.set(qn(k), name)


def fmt(p, align=WD_ALIGN_PARAGRAPH.JUSTIFY, indent=1.25, spacing=1.5, before=0, after=0, keep=False):
    pf = p.paragraph_format
    pf.alignment = align
    pf.first_line_indent = Cm(indent)
    pf.line_spacing = spacing
    pf.space_before = Pt(before)
    pf.space_after = Pt(after)
    if keep:
        pf.keep_with_next = True


def clean_inline(text):
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"\1", text)
    text = text.replace("`", "")
    text = re.sub(r"\[(ПРОВЕРИТЬ[^\]]*)\]", "", text)
    return text


def para(doc, text, **kw):
    p = doc.add_paragraph()
    fmt(p, **kw)
    r = p.add_run(clean_inline(text))
    set_font(r, kw.pop("size", 14) if False else 14)
    return p


def add_field(run, instr):
    for kind, val in (("begin", None), ("instr", instr), ("separate", None), ("end", None)):
        if kind == "instr":
            el = OxmlElement("w:instrText")
            el.set(qn("xml:space"), "preserve")
            el.text = instr
        else:
            el = OxmlElement("w:fldChar")
            el.set(qn("w:fldCharType"), kind)
        run._r.append(el)


def picture(doc_or_cell, path, max_w, max_h):
    w, h = Image.open(path).size
    width = max_w
    if width * h / w > max_h:
        width = max_h * w / h
    if hasattr(doc_or_cell, "add_paragraph"):
        p = doc_or_cell.add_paragraph() if not hasattr(doc_or_cell, "_tc") else doc_or_cell.paragraphs[0]
    fmt(p, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, spacing=1.0, keep=True)
    p.add_run().add_picture(path, width=Cm(width))
    return p


def caption_text(line):
    # «Рисунок 2.1 — Название» → «Рисунок 2.1. Название» (пример в п. 3.3 методических указаний).
    return re.sub(r"^(Рисунок|Таблица) ([\d.]+?)\.? — ", r"\1 \2. ", line)


def table(doc, rows):
    cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
    cells = [r for r in cells if not all(re.fullmatch(r":?-+:?", c) for c in r)]
    ncol = max(len(r) for r in cells)
    t = doc.add_table(rows=len(cells), cols=ncol)
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, r in enumerate(cells):
        for j in range(ncol):
            c = t.cell(i, j)
            p = c.paragraphs[0]
            fmt(p, align=WD_ALIGN_PARAGRAPH.CENTER if i == 0 else WD_ALIGN_PARAGRAPH.LEFT,
                indent=0, spacing=1.0)
            run = p.add_run(clean_inline(r[j] if j < len(r) else "–") or "–")
            set_font(run, 12)
    # Шапка повторяется при переносе таблицы на следующую страницу.
    trpr = t.rows[0]._tr.get_or_add_trPr()
    h = OxmlElement("w:tblHeader")
    h.set(qn("w:val"), "true")
    trpr.append(h)
    doc.add_paragraph()  # отступ после таблицы
    fmt(doc.paragraphs[-1], indent=0, spacing=1.0)


def heading(doc, text, level):
    text = clean_inline(text)
    if level == 1:
        p = doc.add_paragraph(style="Heading 1")
        p.paragraph_format.page_break_before = True
        fmt(p, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, after=14, keep=True)
        text = text.upper()
    elif level == 2:
        p = doc.add_paragraph(style="Heading 2")
        fmt(p, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, before=14, after=14, keep=True)
    else:
        p = doc.add_paragraph(style="Heading 3")
        fmt(p, align=WD_ALIGN_PARAGRAPH.JUSTIFY, indent=1.25, before=6, after=6, keep=True)
    r = p.add_run(text)
    set_font(r, 14)
    r.font.color.rgb = None
    r.font.italic = False


def setup(doc):
    st = doc.styles["Normal"]
    st.font.name = FONT
    st.font.size = Pt(14)
    st.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
    for name in ("Heading 1", "Heading 2", "Heading 3"):
        s = doc.styles[name]
        s.font.name = FONT
        s.font.size = Pt(14)
        s.font.bold = False
        s.font.italic = False
        s.font.color.rgb = None
        rpr = s.element.get_or_add_rPr()
        f = rpr.find(qn("w:rFonts"))
        if f is None:
            f = OxmlElement("w:rFonts")
            rpr.append(f)
        for k in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
            f.set(qn(k), FONT)
        for k in ("w:asciiTheme", "w:hAnsiTheme", "w:cstheme", "w:eastAsiaTheme"):
            if f.get(qn(k)) is not None:
                del f.attrib[qn(k)]
    sec = doc.sections[0]
    sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
    margins(sec)


def margins(sec):
    sec.left_margin, sec.right_margin = Cm(3.0), Cm(1.0)
    sec.top_margin, sec.bottom_margin = Cm(2.0), Cm(2.0)


def title_page(doc):
    def line(text, align=WD_ALIGN_PARAGRAPH.CENTER, before=0, caps=False):
        p = doc.add_paragraph()
        fmt(p, align=align, indent=0, spacing=1.5, before=before)
        r = p.add_run(text.upper() if caps else text)
        set_font(r, 14)
        return p
    line("КОЛЛЕДЖ ТОО «ASTANA IT UNIVERSITY»")
    line("Специальность 06130100 – Программное обеспечение (по видам)")
    line("КУРСОВОЙ ПРОЕКТ", before=140)
    line("по модулю «Разработка мобильных приложений»")
    line("на тему:", before=12)
    line(f"«{TOPIC}»")
    line("Выполнил: студент группы " + GROUP, align=WD_ALIGN_PARAGRAPH.RIGHT, before=110)
    line(STUDENT_FULL, align=WD_ALIGN_PARAGRAPH.RIGHT)
    line("Руководитель: " + SUPERVISOR, align=WD_ALIGN_PARAGRAPH.RIGHT, before=12)
    line("Оценка: ______________", align=WD_ALIGN_PARAGRAPH.RIGHT, before=12)
    p = line("Астана, 2026", before=110)
    p.add_run().add_break(WD_BREAK.PAGE)
    h = doc.add_paragraph()
    fmt(h, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, after=14)
    set_font(h.add_run("СОДЕРЖАНИЕ"), 14)
    toc = doc.add_paragraph()
    fmt(toc, align=WD_ALIGN_PARAGRAPH.LEFT, indent=0)
    r = toc.add_run()
    add_field(r, 'TOC \\o "1-2" \\h \\z \\u')
    note = doc.add_paragraph()
    fmt(note, align=WD_ALIGN_PARAGRAPH.LEFT, indent=0)
    set_font(note.add_run("(Чтобы заполнить содержание, в Word нажмите на поле правой кнопкой → «Обновить поле».)"), 12)
    # Новый раздел: с введения номера страниц показываются внизу по центру,
    # счёт страниц продолжается (титульный лист и содержание входят в нумерацию).
    new = doc.add_section(WD_SECTION.NEW_PAGE)
    margins(new)
    new.footer.is_linked_to_previous = False
    fp = new.footer.paragraphs[0]
    fmt(fp, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, spacing=1.0)
    rr = fp.add_run()
    set_font(rr, 12)
    add_field(rr, "PAGE")
    doc.sections[0].footer.is_linked_to_previous = False
    settings = doc.settings.element
    upd = OxmlElement("w:updateFields")
    upd.set(qn("w:val"), "true")
    settings.append(upd)


def render(md, out_path):
    doc = Document()
    setup(doc)
    title_page(doc)
    lines = md.split("\n")
    i = 0
    first_h1 = True
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            code = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code.append(lines[i])
                i += 1
            for c in code:
                p = doc.add_paragraph()
                fmt(p, align=WD_ALIGN_PARAGRAPH.LEFT, indent=0, spacing=1.0)
                set_font(p.add_run(c), 10, mono=True)
            i += 1
            continue
        m = re.match(r"^(#+) (.*)$", line)
        if m:
            heading(doc, m.group(2), len(m.group(1)))
            if first_h1 and len(m.group(1)) == 1:
                # Первый заголовок уже начинается с новой страницы (новый раздел документа).
                doc.paragraphs[-1].paragraph_format.page_break_before = False
                first_h1 = False
            i += 1
            continue
        if line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(lines[i])
                i += 1
            table(doc, rows)
            continue
        if line.startswith("!!PAIR "):
            a, ca, b, cb = line[7:].split("|")
            t = doc.add_table(rows=2, cols=2)
            t.alignment = WD_TABLE_ALIGNMENT.CENTER
            for j, (img, cap) in enumerate(((a, ca), (b, cb))):
                cell = t.cell(0, j)
                p = cell.paragraphs[0]
                fmt(p, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, spacing=1.0)
                p.add_run().add_picture(os.path.join(SRC, img), height=Cm(9.0))
                cp = t.cell(1, j).paragraphs[0]
                fmt(cp, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, spacing=1.0, after=10)
                set_font(cp.add_run(caption_text(cap)), 14)
            i += 1
            continue
        if line.startswith("!!SIGN"):
            p = doc.add_paragraph()
            fmt(p, align=WD_ALIGN_PARAGRAPH.LEFT, indent=0, before=24)
            set_font(p.add_run(f"Студент: {STUDENT_FULL} ______________ «___» __________ 2026 г."), 14)
            i += 1
            continue
        im = re.match(r"^!\[[^\]]*\]\(([^)]+)\)", line)
        if im:
            path = os.path.join(SRC, im.group(1))
            w, h = Image.open(path).size
            picture(doc, path, 16.0 if w > h else 12.0, 15.0)
            i += 1
            continue
        if line.startswith("Рисунок "):
            p = doc.add_paragraph()
            fmt(p, align=WD_ALIGN_PARAGRAPH.CENTER, indent=0, after=8)
            set_font(p.add_run(caption_text(line)), 14)
            i += 1
            continue
        if line.startswith("Таблица "):
            p = doc.add_paragraph()
            fmt(p, align=WD_ALIGN_PARAGRAPH.LEFT, indent=1.25, keep=True)
            set_font(p.add_run(caption_text(line)), 14)
            i += 1
            continue
        if not line.strip():
            i += 1
            continue
        text = line
        if text.startswith("> "):
            text = "Примечание – " + text[2:]
        lm = re.match(r"^\s*[-*] (.*)$", text)
        if lm:
            text = "– " + lm.group(1)
        para(doc, text)
        i += 1
    doc.save(out_path)


def main():
    md, used, total = assemble()
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "kursovaya_2026.md"), "w", encoding="utf-8") as f:
        f.write(md)
    out = os.path.join(OUT_DIR, OUT_NAME)
    render(md, out)
    print(out)
    print(f"источников в списке: {used} из {total}")


if __name__ == "__main__":
    main()
