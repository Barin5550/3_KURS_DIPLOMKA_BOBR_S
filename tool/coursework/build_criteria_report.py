"""Сборка отчёта о выполнении критериев оценивания (DOCX и PDF).

Текст отчёта — docs/Отчёт_по_критериям.md: для каждого критерия простыми
словами объяснено, как он выполнен (без путей к файлам, указаний «где
находится» и названий классов; технические таблицы с путями остаются в
docs/criteria_semester1.md и docs/criteria_semester2.md). Сборщик
добавляет шапку с данными студента и оформляет документ так же, как
курсовую (tool/coursework/build_coursework.py); страницы альбомные, чтобы
длинные ответы в таблицах читались без лишних переносов.

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
SOURCE = os.path.join(DOCS, "Отчёт_по_критериям.md")
PAGE_WIDTH, PAGE_HEIGHT, MARGIN = 29.7, 21.0, 2.0


def assemble():
    parts = [
        "# ОТЧЁТ О ВЫПОЛНЕНИИ КРИТЕРИЕВ ОЦЕНИВАНИЯ",
        "",
        f"{bc.COLLEGE}, {bc.CITY_YEAR.replace(' ', ', ')}.",
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
    ]
    with open(SOURCE, encoding="utf-8") as f:
        parts.append(f.read())
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
