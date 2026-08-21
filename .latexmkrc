# .latexmkrc
# The paper's build recipe:
#
#     latexmk apa_template.tex
#
# Aux files (.aux, .bbl, .log, .fls, .fff/.ttt, ...) land in .build/;
# the PDF and its .synctex.gz are written at the root, beside
# apa_template.tex. The root PDF is the canonical output -- there is no
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

# -synctex=1 is spelled out because setting $synctex alone does not survive
# set_tex_cmds(): the build then succeeds while silently shipping no
# .synctex.gz, and forward/inverse search stops working with nothing to show.
set_tex_cmds('-synctex=1 -interaction=nonstopmode -file-line-error %O %S');

$clean_ext = 'bbl fff ttt run.xml synctex.gz';
