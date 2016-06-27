# vim-emotions
Motion commands so efficient, they'll make you emotional.

## Introduction

emotions provides quick, understandable key commands to quickly navigate text.
These commands mimic Vim's normal navigation: f, t, and so on. However, they
solve a fundamental problem with the built-in commands.

Vim's built in *f* (and similar commands) will not always take you to your
intended destination. Instead, they take you to the very next match - wherever
that match happens to be. This is annoying because it forces you to care about
how many matches lie between you and your destination. If you perform text
searches with */*, this problem is mitigated with 'incsearch', but that is
only a partial solution.

emotions takes a different approach. Every visible match for your current
search is assigned a label - a key or pair of keys that uniquely identifies
that location. If you enter the key combination for
your intended location, you will instantly jump to it - regardless of the text
in between.

This concept can be used for more than just searches in the tradition of *f*
and *t*. Any motion, such as *w* and *e*, can be labeled in the same way.
This allows rapid and intuitive access to anywhere on the screen, using
whatever motion is most appropriate.

This idea is entirely unoriginal. It was originally created by Bartlomiej
Podolak for his [Precise Jump script](http://www.vim.org/scripts/script.php?script_id=3437).
This was adapted by Lokaltog, to create the excellent [EasyMotion plugin](https://github.com/easymotion/vim-easymotion)
which currently maintained by haya14busa. The emotions plugin is simply a
more modern re-implementation of that core idea.

### Comparison with Easymotion

EasyMotion has more features, is more thoroughly tested, and is generally a
fantastic plugin. With all that said, there are a small number of features
that emotions has to offer that EasyMotion is unlikely to incorporate.

1. conceal-based labeling. EasyMotion creates labels by copying the text of
every line with a target, substituting the real text with
the label keys, and then restoring the original text after the motion is
complete. By default, emotions instead uses Vim's "conceal" feature to apply
custom highlighting to each label, concealing the real text visually but
leaving it unchanged. This is safer and, in many cases, faster.
emotions also supports replacement-based labeling for systems where
concealing is not available, or is being used for other purposes.
2. Speed. EasyMotion pays a performance cost for its robust feature set, and
any slowness when making quick motions can be painful. emotions has a more
compact codebase, and should be faster in practice\*.

\* Citation needed.
