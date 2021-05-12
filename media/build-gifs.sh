#!/bin/bash
set -eo pipefail

# build gifs using (in-line) generated palettes
ffmpeg -y -i exact-grab-scroll.mp4 -filter_complex "[0:v] fps=12,split [a][b];[a] palettegen [p];[b][p] paletteuse" exact-grab-scroll.gif
#  (note: 'typing' AND 'recall' demo built from exact-grab-typing.mp4)
ffmpeg -y -ss 2.4 -t 3.2 -i exact-grab-typing.mp4 -filter_complex "[0:v] fps=6,split [a][b];[a] palettegen [p];[b][p] paletteuse" exact-grab-typing.gif
ffmpeg -y -ss 7.0 -t 3.0 -i exact-grab-typing.mp4 -filter_complex "[0:v] fps=4,split [a][b];[a] palettegen [p];[b][p] paletteuse" exact-grab-recall.gif
