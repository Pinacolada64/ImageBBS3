"""Pygments lexer for Image BBS BASIC listings ("imagebasic").

CBM BASIC V2 (Pygments' "cbmbas" lexer) plus what Image BBS listings use:
& calls, $hex and %binary numbers, the st/ti/ti$ variables, and C64List's
{...} tokens outside strings ({:label}, {f6}), [28]-style line references
and ' comment lines. Without these, cbmbas marks every & as an error.

The Programmer's Reference Guide build finds it through PYTHONPATH (see the
Makefile's pdf target): imagebbs_lexer-1.0.dist-info registers it as a
Pygments plugin, so nothing has to be installed.
"""

from pygments.lexer import inherit
from pygments.lexers.basic import CbmBasicV2Lexer
from pygments.token import Comment, Keyword, Name, Number


class ImageBasicLexer(CbmBasicV2Lexer):
    name = 'Image BBS BASIC'
    aliases = ['imagebasic']
    filenames = ['*.lbl']

    tokens = {
        'root': [
            (r"'.*\n", Comment.Single),         # C64List comment line
            (r'[&?]', Keyword.Reserved),         # & call, ? (print)
            (r'\$[0-9a-f]+', Number.Hex),        # $c000
            (r'%[01]+', Number.Bin),             # %1100
            (r'(ti\$?|st)(?![\w$%])', Name.Builtin),
            (r'\{[^}\n]*\}', Name.Label),        # C64List {:label}, {f6}
            (r'\[\d+\]', Name.Label),            # [28]
            inherit,
        ]
    }
