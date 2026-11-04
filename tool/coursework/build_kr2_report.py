"""Сборка отчёта о выполнении задания на курсовой проект КР 2 (DOCX и PDF).

Текст отчёта — docs/Отчёт_по_критериям_КР_2.md (пары картинок «прототип —
приложение» берутся из docs/coursework/prototype_compare/).
DOCX оформляется как курсовая (tool/coursework/build_coursework.py):
книжные страницы A4 с полями по ГОСТ, Times New Roman 14, пометки
[ПРОВЕРИТЬ] жёлтым.

PDF: если установлен LibreOffice — из DOCX, как у остальных документов;
если нет — из HTML через Google Chrome (--headless --print-to-pdf).

Запуск:
    python3 tool/coursework/build_kr2_report.py [--pdf]

Нужны: pandoc, python-docx; для --pdf — LibreOffice или Google Chrome.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

from docx import Document
from docx.shared import Cm

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_coursework as bc  # noqa: E402

DOCS = os.path.join(bc.ROOT, "docs")
SOURCE = os.path.join(DOCS, "Отчёт_по_критериям_КР_2.md")
OUT_DOCX = os.path.join(DOCS, "Отчёт_по_критериям_КР_2.docx")
OUT_PDF = os.path.join(DOCS, "Отчёт_по_критериям_КР_2.pdf")
AUTHOR = "Баринов Николай"
TITLE = "Отчёт о выполнении задания на курсовой проект"


def assemble():
    parts = [
        "# ОТЧЁТ О ВЫПОЛНЕНИИ ЗАДАНИЯ НА КУРСОВОЙ ПРОЕКТ",
        "",
        f"{bc.COLLEGE}, {bc.CITY_YEAR.replace(' ', ', ')}.",
        "",
        "Дисциплина: ПМ.07 «Разработка мобильных приложений».",
        "",
        "Тема курсового проекта: «Создание приложения для автоматического "
        "формирования персонального плана обучения» (приложение «Маршрут»).",
        "",
        f"Выполнил: студент 3 курса, группа {bc.GROUP}, "
        "Баринов Николай Владимирович",
        "",
        f"Руководитель: {bc.SUPERVISOR}",
        "",
    ]
    with open(SOURCE, encoding="utf-8") as f:
        text = f.read()
    # Высота пар картинок «прототип — приложение» (в самом .md её нет,
    # чтобы файл нормально читался на GitHub).
    text = re.sub(r"^(!\[[^\]]*\]\([^)]*\))$", r"\1{height=8cm}", text, flags=re.M)
    parts.append(text)
    os.makedirs(bc.BUILD, exist_ok=True)
    path = os.path.join(bc.BUILD, "kr2_report.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(parts) + "\n")
    return path


def postprocess(raw, out):
    """Оформление как у курсовой, страницы книжные."""
    doc = Document(raw)
    bc.setup_styles(doc)
    bc.setup_page(doc)
    bc.format_paragraphs(doc)
    for p in doc.paragraphs:
        if re.match(r"^Таблица \d+ — ", p.text):
            bc.para_format(p.paragraph_format, bc.WD_ALIGN_PARAGRAPH.LEFT, Cm(0), before=6)
            p.paragraph_format.keep_with_next = True
    bc.format_tables(doc)
    bc.highlight_checks(doc)
    doc.save(out)


def set_properties(path):
    doc = Document(path)
    props = doc.core_properties
    props.author = AUTHOR
    props.last_modified_by = AUTHOR
    props.title = TITLE
    props.comments = ""
    doc.save(path)


HTML_STYLE = """
@page { size: A4; margin: 2cm 1.5cm 2cm 3cm; }
body { font-family: "Times New Roman", serif; font-size: 14pt; line-height: 1.4; }
h1 { font-size: 16pt; text-align: center; }
h2 { font-size: 15pt; page-break-after: avoid; }
h3 { font-size: 14pt; page-break-after: avoid; }
table { border-collapse: collapse; width: 100%; font-size: 11pt; margin: 6pt 0; }
th, td { border: 1px solid #000; padding: 3pt 5pt; vertical-align: top; }
tr { page-break-inside: avoid; }
code { font-size: 10.5pt; }
td code { white-space: normal; overflow-wrap: anywhere; }
pre { font-size: 10pt; white-space: pre-wrap; border: 1px solid #999; padding: 4pt; }
figure { text-align: center; page-break-inside: avoid; margin: 8pt 0; }
figure img { height: 8cm; }
figcaption { font-size: 12pt; }
mark { background: yellow; }
"""


def pdf_from_html(source, pdf):
    chrome = shutil.which("google-chrome") or "/usr/bin/google-chrome"
    with tempfile.TemporaryDirectory() as tmp:
        page = os.path.join(tmp, "report.html")
        subprocess.run(
            ["pandoc", source, "-f", "markdown", "-t", "html5", "--standalone",
             "--embed-resources", "--resource-path", DOCS,
             "--metadata", f"title={TITLE}", "--metadata", f"author={AUTHOR}",
             "--variable", "pagetitle=" + TITLE, "-o", page],
            check=True,
        )
        with open(page, encoding="utf-8") as f:
            text = f.read()
        # Заголовок, который pandoc добавляет из метаданных, не нужен:
        # заголовок уже есть в тексте отчёта.
        text = re.sub(r'<header id="title-block-header">.*?</header>', "", text, flags=re.S)
        text = text.replace("</head>", f"<style>{HTML_STYLE}</style></head>")
        text = re.sub(r"\[ПРОВЕРИТЬ[^\]]*\]", lambda m: f"<mark>{m.group(0)}</mark>", text)
        with open(page, "w", encoding="utf-8") as f:
            f.write(text)
        subprocess.run(
            [chrome, "--headless=new", "--no-sandbox", "--disable-gpu",
             f"--user-data-dir={os.path.join(tmp, 'profile')}",
             "--no-pdf-header-footer", f"--print-to-pdf={pdf}",
             "file://" + page],
            check=True, capture_output=True, timeout=180,
        )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", action="store_true", help="сохранить также PDF")
    args = ap.parse_args()

    source = assemble()
    raw = os.path.join(bc.BUILD, "kr2_raw.docx")
    subprocess.run(
        ["pandoc", source, "-f", "markdown", "-t", "docx", "--no-highlight",
         "--resource-path", DOCS, "--reference-doc", bc.reference_doc(), "-o", raw],
        check=True,
    )
    postprocess(raw, OUT_DOCX)
    set_properties(OUT_DOCX)
    print("DOCX:", os.path.relpath(OUT_DOCX, bc.ROOT))
    if args.pdf:
        if shutil.which("soffice"):
            bc.export_pdf(OUT_DOCX, OUT_PDF)
        else:
            pdf_from_html(source, OUT_PDF)
        print("PDF:", os.path.relpath(OUT_PDF, bc.ROOT))


if __name__ == "__main__":
    main()
