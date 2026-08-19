# .latexmkrc
# The paper's build recipe:
#
#     latexmk apa_template.tex
#
# Everything lands in .build/ -- aux files, the PDF, and the .synctex.gz --
# and only the finished PDF is copied back beside apa_template.tex.
#
# The PDF has to be built in .build/ too: pdflatex writes the SyncTeX file
# next to its output PDF, and latexmk moves the pair together to $out_dir.
# Keeping $out_dir at the root is what drags the .synctex.gz out here.

$pdf_mode = 1;
$synctex  = 1;             # so `latexmk -c` cleans the .synctex.gz

$aux_dir  = '.build';
$out_dir  = '.build';
$out2dir  = '.';           # the committed copy of the PDF

# Trims latexmk's out2 copy list (default: pdf, ps, synctex, synctex.gz)
# down to the PDF, so the SyncTeX file stays with the PDF it pairs with.
@out2_exts = ('pdf');

$bibtex_use = 2;           # biblatex + biber, as apa_template.tex loads them

# -synctex=1 is spelled out because setting $synctex alone does not survive
# set_tex_cmds(): the build then succeeds while silently shipping no
# .synctex.gz, and forward/inverse search stops working with nothing to show.
set_tex_cmds('-synctex=1 -interaction=nonstopmode -file-line-error %O %S');

$clean_ext = 'bbl fff ttt run.xml synctex.gz';
