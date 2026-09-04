#!/usr/bin/env python3
"""Generate notation_table.tex from the symbols actually used in the body.

    python make_notation.py            # regenerate; exit 1 if a symbol is undocumented
    python make_notation.py --check    # report only, write nothing
    python make_notation.py --stubs    # print notation.tsv lines for undocumented symbols

Why this exists
---------------
glossaries and nomencl are "push" systems: a symbol reaches the table only if
you remember to wrap it in \\gls{} or \\nomenclature{}. A raw $\\zeta$ typed into
an equation is invisible to them and silently absent from the table -- exactly
the failure this is meant to prevent. So this reads the raw source instead.

You write ordinary math in the body. Categories and descriptions live in
notation.tsv, because no script can know that zeta is a parameter meaning
"damping ratio". What the script guarantees is COVERAGE: a symbol you used and
never described stops the build.

Conditional enforcement
-----------------------
The check only bites if the table actually reaches the PDF. If \\input{appendix}
is commented out of apa_template.tex, or \\input{notation_table} out of
appendix.tex, the document compiles unimpeded. See table_is_included().

Matching
--------
Symbols are matched on their BASE form: sub- and superscripts are stripped, so
x_{it|t-1} and x_{it} both reduce to "x" and share one row. Letter runs are
kept whole, so $TAC(t)$ yields "TAC" rather than T, A and C. Both the body and
notation.tsv go through the same normalisation, so the two sides cannot
disagree about what a symbol is called.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# This script lives in dissemination/appendix/ alongside the appendix sources
# it feeds; the manuscript and its section files sit one level up in
# dissemination/. Paths are resolved from __file__ so the script can be run
# from anywhere -- latexmk invokes it as appendix/make_notation.py from
# dissemination/, but running it directly from appendix/ works too.
HERE = Path(__file__).resolve().parent
DOC = HERE.parent
MAIN = DOC / "apa_template.tex"
APPENDIX = HERE / "appendix.tex"
TSV = HERE / "notation.tsv"
OUT = HERE / "notation_table.tex"

GROUPS = [("index", "Indices"), ("variable", "Variables"), ("parameter", "Parameters")]

# LaTeX machinery and bound variables that are not notation. Edit freely: this
# is the list you tune when the checker flags something that is not a symbol.
IGNORE = {
    # structure, spacing, formatting
    "begin", "end", "left", "right", "frac", "quad", "qquad", "label",
    "nonumber", "text", "textit", "texttt", "mathrm", "mathbf", "bm",
    "ensuremath", "displaystyle", "limits", "big", "Big", "bigg", "Bigg",
    "cdots", "ldots", "dots", "vdots", "matrix", "pmatrix", "bmatrix",
    # operators and relations
    "times", "cdot", "sum", "prod", "int", "leq", "geq", "neq", "approx",
    "sim", "propto", "in", "to", "rightarrow", "leftarrow", "pm", "mp",
    "log", "exp", "sqrt", "min", "max", "argmin", "argmax", "mathcal",
    # differentials and constants that are not notation in this manuscript
    "d", "dt", "e",
    # reported test statistics rather than model notation
    "p", "df", "SD", "SE", "CI",
}

COMMENT = re.compile(r"(?<!\\)%.*$", re.MULTILINE)
MATH_ENVS = ("equation", "align", "gather", "multline", "eqnarray")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def strip_comments(tex: str) -> str:
    return COMMENT.sub("", tex)


def extract_math(tex: str) -> list[str]:
    """Every stretch of math in the source, in document order."""
    flat = tex.replace("\n", " ")
    spans: list[tuple[int, str]] = []
    for env in MATH_ENVS:
        pat = re.compile(rf"\\begin\{{{env}\*?\}}(.*?)\\end\{{{env}\*?\}}", re.DOTALL)
        spans += [(m.start(), m.group(1)) for m in pat.finditer(flat)]
    for pat in (r"\\\[(.*?)\\\]", r"\\\((.*?)\\\)", r"(?<!\$)\$([^$]+)\$"):
        spans += [(m.start(), m.group(1)) for m in re.finditer(pat, flat, re.DOTALL)]
    spans.sort(key=lambda s: s[0])
    return [s[1] for s in spans]


SUBSCRIPT = re.compile(r"[_^]\{([^{}]*)\}|[_^](\\?[A-Za-z0-9]+)")


def normalise(math: str) -> str:
    """Drop text runs and sub/superscripts, leaving base symbols."""
    math = re.sub(r"\\(?:text|texttt|textit|mathrm|mbox)\{[^}]*\}", " ", math)
    # Environment and label names are not notation: \begin{bmatrix} must not
    # contribute b, m, a, t, r, i, x.
    math = re.sub(r"\\(?:begin|end|label|tag|ref|eqref)\{[^}]*\}", " ", math)
    return SUBSCRIPT.sub(" ", math)


def segment(run: str, vocab: set[str]) -> list[str]:
    """Split a run of letters into symbols, longest declared match first.

    Regex cannot tell that TAC is one symbol while Hx is two -- both are just
    letters. The declared vocabulary settles it: TAC is in notation.tsv, Hx is
    not but H and x are. Anything unmatched falls back to single letters, which
    is what makes the bootstrap case (nothing declared yet) still report
    something usable.
    """
    out, i = [], 0
    while i < len(run):
        for size in range(len(run) - i, 0, -1):
            if run[i:i + size] in vocab:
                out.append(run[i:i + size])
                i += size
                break
        else:
            # A leading d before a symbol is a differential, not a symbol.
            if run[i] == "d" and i + 1 < len(run) and run[i + 1].isupper():
                i += 1
                continue
            out.append(run[i])
            i += 1
    return out


def tokenize(math: str, vocab: set[str] | None = None) -> list[str]:
    """Base symbols in a stretch of math, in order, duplicates removed."""
    vocab = vocab or set()
    s = normalise(math)
    out: list[str] = []
    # A control sequence, or a run of letters. Ordered scan so first use wins.
    for m in re.finditer(r"\\([A-Za-z]+)|([A-Za-z]+)", s):
        if m.group(1):
            toks = [m.group(1)]
            # \Delta t is one symbol; the bare \Delta is not used alone here.
            if m.group(1) == "Delta" and s[m.end():].strip()[:1] == "t":
                toks = ["Delta t"]
        else:
            toks = segment(m.group(2), vocab)
        for tok in toks:
            if tok not in IGNORE and tok not in out:
                out.append(tok)
    return out


def subscript_symbols(math: str, indices: set[str]) -> list[str]:
    """Declared index symbols appearing in sub/superscripts.

    i and t are written only as subscripts, so the base-symbol scan never sees
    them. Restricted to symbols already declared as indices, because subscript
    contents are otherwise full of noise (0, 1, t-1, ...).
    """
    out: list[str] = []
    for m in SUBSCRIPT.finditer(math):
        content = m.group(1) or m.group(2) or ""
        # Indices arrive concatenated (x_{it}) as often as separated (x_{i,t}),
        # so segment each letter run rather than matching names directly.
        for run in re.findall(r"[A-Za-z]+", content):
            for tok in segment(run, indices):
                if tok in indices and tok not in out:
                    out.append(tok)
    return out


def key(symbol: str, vocab: set[str] | None = None) -> str:
    """notation.tsv's `symbol` column reduced to the same base form as the body."""
    toks = tokenize(symbol, vocab)
    return toks[0] if toks else symbol


def body_files() -> list[Path]:
    """Section files, in the order apa_template.tex inputs them.

    The appendix is excluded: it holds the table, so counting it would make
    every documented symbol look "used" purely by being documented.
    """
    main = strip_comments(read(MAIN))
    names = re.findall(r"\\input\{([^}]+)\}", main)
    return [DOC / f"{n}.tex" for n in names if re.match(r"^\d{2}_", n)]


def table_is_included() -> bool:
    """True only if the generated table actually reaches the compiled PDF."""
    main = strip_comments(read(MAIN))
    if not re.search(r"\\input\{appendix(?:/appendix)?\}", main):
        return False
    if not APPENDIX.exists():
        return False
    return bool(re.search(r"\\input\{(?:appendix/)?notation_table\}", strip_comments(read(APPENDIX))))


def used_symbols(vocab: set[str], indices: set[str]) -> tuple[list[str], dict[str, list[str]]]:
    """Base symbols in order of first use, with the literal forms they appeared in."""
    order: list[str] = []
    forms: dict[str, list[str]] = {}
    for path in body_files():
        if not path.exists():
            continue
        for math in extract_math(strip_comments(read(path))):
            snippet = re.sub(r"\s+", " ", math).strip()[:60]
            for tok in tokenize(math, vocab) + subscript_symbols(math, indices):
                if tok not in order:
                    order.append(tok)
                    forms[tok] = []
                if snippet not in forms[tok] and len(forms[tok]) < 3:
                    forms[tok].append(snippet)
    return order, forms


def load_entries() -> dict[str, dict[str, str]]:
    """Parse notation.tsv, keyed by the same base form the body scan produces.

    Read in two passes: the raw symbol column supplies the vocabulary that
    segment() needs, so it has to be collected before anything is tokenized.
    """
    rows: list[tuple[int, str, str, str, str]] = []
    for lineno, line in enumerate(read(TSV).splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if parts[0].strip() == "symbol":
            continue
        if len(parts) < 4:
            sys.exit(f"notation.tsv:{lineno}: expected 4 tab-separated columns, got {len(parts)}")
        sym, group, shape, desc = (p.strip() for p in parts[:4])
        valid = {g for g, _ in GROUPS}
        if group not in valid:
            sys.exit(f"notation.tsv:{lineno}: group must be one of {sorted(valid)}, got {group!r}")
        rows.append((lineno, sym, group, shape, desc))

    vocab = {run for _, sym, *_ in rows if "\\" not in sym
             for run in re.findall(r"[A-Za-z]+", sym)}

    entries: dict[str, dict[str, str]] = {}
    for _, sym, group, shape, desc in rows:
        entries[key(sym, vocab)] = {
            "raw": sym, "group": group, "shape": shape, "description": desc
        }
    return entries


BANNER = """% notation_table.tex -- GENERATED FILE, DO NOT EDIT BY HAND.
%
% Written by make_notation.py from notation.tsv, with the rows restricted to
% the symbols actually used in the body and ordered by first use within each
% group. To change a description or a category, edit notation.tsv and rebuild.
% Hand edits here are overwritten on the next compile.
"""


def render(order: list[str], entries: dict[str, dict[str, str]]) -> str:
    rows: list[str] = []
    for group, heading in GROUPS:
        in_group = [s for s in order if s in entries and entries[s]["group"] == group]
        if not in_group:
            continue
        if rows:
            rows.append(r"\addlinespace")
        rows.append(rf"\multicolumn{{2}}{{l}}{{\textit{{{heading}}}}} \\")
        for sym in in_group:
            e = entries[sym]
            rows.append(rf"${e['raw']}$ & {e['description']} \\")

    body = "\n".join(rows)
    return f"""{BANNER}
\\begin{{table}}[htbp]
\\centering
\\caption{{Notation}}
\\label{{tab:notation}}
\\begin{{threeparttable}}
\\begin{{tabular}}{{ll}}
\\toprule
Symbol & Description \\\\
\\midrule
{body}
\\bottomrule
\\end{{tabular}}
\\end{{threeparttable}}
\\end{{table}}
"""


def guard(missing: list[str]) -> str:
    """A LaTeX-side failure, so a bare pdflatex run fails too, not just latexmk.

    Only reached when this file is \\input, which is what makes enforcement
    conditional on the table being part of the document.
    """
    names = ", ".join(missing)
    return (
        f"\\PackageError{{notation}}{{Undocumented symbols: {names}}}\n"
        f"{{Add a row for each to notation.tsv, then rebuild.}}\n"
    )


def main() -> int:
    check_only = "--check" in sys.argv
    stubs = "--stubs" in sys.argv

    entries = load_entries()
    vocab = {e["raw"] for e in entries.values() if "\\" not in e["raw"]} | set(entries)
    indices = {s for s, e in entries.items() if e["group"] == "index"}
    order, forms = used_symbols(vocab, indices)

    missing = [s for s in order if s not in entries]
    unused = [s for s in entries if s not in order]

    if stubs:
        print("# Add to notation.tsv (tab separated), in first-use order:")
        for s in missing:
            raw = f"\\{s}" if len(s) > 1 and not s.isupper() else s
            seen = " ; ".join(forms.get(s, []))
            print(f"{raw}\tvariable\tscalar\tTODO -- seen as: {seen}")
        return 0

    included = table_is_included()

    if missing:
        where = "" if included else " (not enforced: the table is not in the document)"
        print(f"notation: {len(missing)} symbol(s) used but not in notation.tsv{where}", file=sys.stderr)
        for s in missing:
            print(f"  {s:<12} seen as: {' ; '.join(forms.get(s, []))}", file=sys.stderr)
        print("  run  python make_notation.py --stubs  for rows to paste", file=sys.stderr)
    if unused:
        print(f"notation: {len(unused)} row(s) in notation.tsv never used, omitted from the table: "
              f"{', '.join(sorted(unused))}", file=sys.stderr)

    if not check_only:
        text = render(order, entries)
        if missing and included:
            text += guard(missing)
        OUT.write_text(text, encoding="utf-8", newline="\n")

    if missing and included:
        return 1
    if not missing:
        print(f"notation: OK, {len(order)} symbols documented")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
