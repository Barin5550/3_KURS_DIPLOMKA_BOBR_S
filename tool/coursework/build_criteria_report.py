"""Сборка отчёта о выполнении критериев оценивания (DOCX и PDF).

Отчёт собирается из таблиц docs/criteria_semester1.md и
docs/criteria_semester2.md: для каждого критерия — где он реализован
и как его показать на защите. Оформление то же, что у курсовой
(tool/coursework/build_coursework.py), страницы альбомные, чтобы
таблицы из четырёх столбцов читались без лишних переносов.

Запуск:
    python3 tool/coursework/build_criteria_report.py [--pdf]

Нужны: pandoc, python-docx; для --pdf — LibreOffice (модуль uno).
"""

import argparse
import os
import re
import subprocess
import sys

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.shared import Cm

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_coursework as bc  # noqa: E402

DOCS = os.path.join(bc.ROOT, "docs")
OUT_DOCX = os.path.join(DOCS, "Отчёт_по_критериям.docx")
OUT_PDF = os.path.join(DOCS, "Отчёт_по_критериям.pdf")
SOURCES = [
    ("1 семестр", "criteria_semester1.md"),
    ("2 семестр", "criteria_semester2.md"),
]
PAGE_WIDTH, PAGE_HEIGHT, MARGIN = 29.7, 21.0, 2.0


def criteria_table(name):
    """Таблица критериев из файла: без заголовка, пояснений и списка
    «Что проверить перед сдачей» (это заметки для самого студента)."""
    with open(os.path.join(DOCS, name), encoding="utf-8") as f:
        text = f.read()
    rows = [line for line in text.split("\n") if line.startswith("|")]
    return "\n".join(rows)


def assemble():
    parts = [
        "# ОТЧЁТ О ВЫПОЛНЕНИИ КРИТЕРИЕВ ОЦЕНИВАНИЯ",
        "",
        "Дисциплина: ПМ.07 «Разработка мобильных приложений».",
        "",
        "Тема курсового проекта: «Создание приложения для автоматического "
        "формирования персонального плана обучения» (приложение «Маршрут»).",
        "",
        f"Выполнил: студент 3 курса, группа {bc.GROUP}, {bc.STUDENT}",
        "",
        f"Руководитель: {bc.SUPERVISOR}",
        "",
        "Для каждого критерия указано, где он реализован в приложении или в "
        "курсовой работе и как показать его на защите. Пути к файлам указаны "
        "от корня репозитория, скриншоты экранов приведены в курсовой работе "
        "(раздел 2.5).",
    ]
    for number, (title, name) in enumerate(SOURCES, start=1):
        parts += [
            "",
            f"## Критерии: {title}",
            "",
            f"Таблица {number} — Критерии {title.replace('семестр', 'семестра')}: "
            "где реализовано и как показать",
            "",
            criteria_table(name),
        ]
    path = os.path.join(bc.BUILD, "criteria_report.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(parts) + "\n")
    return path


def landscape(doc):
    for section in doc.sections:
        section.orientation = WD_ORIENT.LANDSCAPE
        section.page_width = Cm(PAGE_WIDTH)
        section.page_height = Cm(PAGE_HEIGHT)
        for side in ("left", "right", "top", "bottom"):
            setattr(section, f"{side}_margin", Cm(MARGIN))


def postprocess(raw, out):
    # Ширина столбцов считается от ширины текста альбомной страницы.
    bc.TEXT_WIDTH_CM = PAGE_WIDTH - 2 * MARGIN
    doc = Document(raw)
    bc.setup_styles(doc)
    bc.setup_page(doc)
    landscape(doc)
    bc.format_paragraphs(doc)
    # Подписи таблиц в этом отчёте вида «Таблица 1 — …».
    for p in doc.paragraphs:
        if re.match(r"^Таблица \d+ — ", p.text):
            bc.para_format(p.paragraph_format, bc.WD_ALIGN_PARAGRAPH.LEFT, Cm(0), before=6)
            p.paragraph_format.keep_with_next = True
    bc.format_tables(doc)
    doc.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", action="store_true", help="сохранить также PDF")
    args = ap.parse_args()

    os.makedirs(bc.BUILD, exist_ok=True)
    source = assemble()
    raw = os.path.join(bc.BUILD, "criteria_raw.docx")
    subprocess.run(
        ["pandoc", source, "-f", "markdown", "-t", "docx", "--no-highlight",
         "--reference-doc", bc.reference_doc(), "-o", raw],
        check=True,
    )
    postprocess(raw, OUT_DOCX)
    print("DOCX:", os.path.relpath(OUT_DOCX, bc.ROOT))
    if args.pdf:
        bc.export_pdf(OUT_DOCX, OUT_PDF)
        print("PDF:", os.path.relpath(OUT_PDF, bc.ROOT))


if __name__ == "__main__":
    main()
