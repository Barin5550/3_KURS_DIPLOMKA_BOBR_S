"""Сборка памяток к защите (DOCX и PDF) из Markdown-файлов в docs/:
«Как устроено приложение» и «Путеводитель по коду».

Оформление то же, что у курсовой (tool/coursework/build_coursework.py).

Запуск:
    python3 tool/coursework/build_guide.py [--pdf] [имя]
где имя — файл в docs/ без расширения (по умолчанию все памятки).
"""

import argparse
import os
import re
import subprocess
import sys

from docx import Document
from docx.shared import Cm

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_coursework as bc  # noqa: E402

NAMES = ["Как_устроено_приложение", "Путеводитель_по_коду"]


def postprocess(raw, out):
    doc = Document(raw)
    bc.setup_styles(doc)
    bc.setup_page(doc)
    bc.format_paragraphs(doc)
    # Подписи таблиц в памятке вида «Таблица 1 — …».
    for p in doc.paragraphs:
        if re.match(r"^Таблица \d+ — ", p.text):
            bc.para_format(p.paragraph_format, bc.WD_ALIGN_PARAGRAPH.LEFT, Cm(0), before=6)
            p.paragraph_format.keep_with_next = True
    bc.format_tables(doc)
    doc.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", action="store_true", help="сохранить также PDF")
    ap.add_argument("names", nargs="*", default=NAMES, help="файлы в docs/ без расширения")
    args = ap.parse_args()

    os.makedirs(bc.BUILD, exist_ok=True)
    for name in args.names:
        source = os.path.join(bc.ROOT, "docs", name + ".md")
        out_docx = os.path.join(bc.ROOT, "docs", name + ".docx")
        out_pdf = os.path.join(bc.ROOT, "docs", name + ".pdf")
        raw = os.path.join(bc.BUILD, "guide_raw.docx")
        subprocess.run(
            ["pandoc", source, "-f", "markdown", "-t", "docx", "--no-highlight",
             "--reference-doc", bc.reference_doc(), "-o", raw],
            check=True,
        )
        postprocess(raw, out_docx)
        print("DOCX:", os.path.relpath(out_docx, bc.ROOT))
        if args.pdf:
            bc.export_pdf(out_docx, out_pdf)
            print("PDF:", os.path.relpath(out_pdf, bc.ROOT))


if __name__ == "__main__":
    main()
