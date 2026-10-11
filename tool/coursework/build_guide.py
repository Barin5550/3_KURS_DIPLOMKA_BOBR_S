"""Сборка памятки «Как устроено приложение» (DOCX и PDF) для подготовки
к защите из docs/Как_устроено_приложение.md.

Оформление то же, что у курсовой (tool/coursework/build_coursework.py).

Запуск:
    python3 tool/coursework/build_guide.py [--pdf]
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

NAME = "Как_устроено_приложение"
SOURCE = os.path.join(bc.ROOT, "docs", NAME + ".md")
OUT_DOCX = os.path.join(bc.ROOT, "docs", NAME + ".docx")
OUT_PDF = os.path.join(bc.ROOT, "docs", NAME + ".pdf")


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
    args = ap.parse_args()

    os.makedirs(bc.BUILD, exist_ok=True)
    raw = os.path.join(bc.BUILD, "guide_raw.docx")
    subprocess.run(
        ["pandoc", SOURCE, "-f", "markdown", "-t", "docx", "--no-highlight",
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
