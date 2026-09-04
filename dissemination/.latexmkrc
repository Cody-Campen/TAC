# .latexmkrc
# The paper's build recipe:
#
#     cd dissemination && latexmk apa_template.tex
#
# Aux files (.aux, .bbl, .log, .fls, .fff/.ttt, ...) land in .build/;
# the PDF and its .synctex.gz are written in dissemination/, beside
# apa_template.tex. That PDF is the canonical output -- there is no
# copy step that can go stale -- and the .synctex.gz sits next to the
# PDF it pairs with, which is what forward/inverse search needs.
#
# (pdflatex has no native -aux-directory; latexmk emulates the split by
# building in .build/ and moving the PDF+SyncTeX pair out. That's its
# default, long-supported behavior when $aux_dir != $out_dir.)

$pdf_mode = 1;
$synctex  = 1;             # so `latexmk -c` cleans the .synctex.gz

$aux_dir  = '.build';
$out_dir  = '.';

$bibtex_use = 2;           # biblatex + biber, as apa_template.tex loads them

# The notation table is generated, not hand-written: make_notation.py scans the
# section files for symbols, joins them against notation.tsv, and rewrites
# notation_table.tex. Running it inside the compile command means it fires
# before every pdflatex pass; it is idempotent, so repeat passes cost nothing.
#
# A symbol used in the body with no notation.tsv row makes the script exit 1,
# which aborts the build -- but only when the table is actually part of the
# document. Comment out \input{appendix} and the script goes quiet, so a
# draft without the appendix always compiles. make_notation.py also writes a
# \PackageError into the generated table for that case, so a bare pdflatex run
# (or Overleaf, which ignores this file) fails the same way latexmk does.
# latexmk spawns the compile command without a shell, so chaining it onto
# $pdflatex with && silently skips pdflatex. Running it here instead means it
# fires once per latexmk invocation, before any pass. (In -pvc mode that is
# once per session, not once per rebuild.)
if (system('python', 'appendix/make_notation.py') != 0) {
    die "latexmk: notation check failed -- see the messages above.
";
}

# -synctex=1 is spelled out because setting $synctex alone does not survive
# set_tex_cmds(): the build then succeeds while silently shipping no
# .synctex.gz, and forward/inverse search stops working with nothing to show.
set_tex_cmds('-synctex=1 -interaction=nonstopmode -file-line-error %O %S');

$clean_ext = 'bbl fff ttt run.xml synctex.gz';
