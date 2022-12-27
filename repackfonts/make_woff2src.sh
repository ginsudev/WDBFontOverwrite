#!/bin/bash
set -e
rm -rf PreviewFonts XmlFonts XmlFontsRenamed RecompiledFonts RepackedFonts || true
mkdir -p PreviewFonts XmlFonts XmlFontsRenamed RecompiledFonts RepackedFonts || true

IFS="
"
fonts="
OriginalFonts/dejavu-fonts-ttf-2.37/ttf/DejaVuSansCondensed.ttf:DejaVuSansCondensed
OriginalFonts/dejavu-fonts-ttf-2.37/ttf/DejaVuSansMono.ttf:DejaVuSansMono
OriginalFonts/dejavu-fonts-ttf-2.37/ttf/DejaVuSerif.ttf:DejaVuSerif
OriginalFonts/ChocoCooky/assets/fonts/Chococooky.ttf:Chococooky
OriginalFonts/image/font/gofont/ttfs/Go-Regular.ttf:GoRegular
OriginalFonts/image/font/gofont/ttfs/Go-Mono.ttf:GoMono
OriginalFonts/Comic Sans MS.ttf:ComicSansMS
OriginalFonts/segoeui.ttf:SegoeUI"
for fontandname in $fonts
do
	font="$(echo "$fontandname" | cut -d ":" -f 1)"
	fontpsname="$(echo "$fontandname" | cut -d ":" -f 2)"
	fontname="$(basename -s .otf "$(basename -s .ttf "$font")")"

	cp "$font" PreviewFonts/

	ttx -d XmlFonts "$font"
	sed -e "s/$fontpsname/.SFUI-Regular/g" "XmlFonts/$fontname.ttx" > "XmlFontsRenamed/$fontname.ttx"
	ttx -d RecompiledFonts --flavor woff2 "XmlFontsRenamed/$fontname.ttx"

	./BrotliPadding "RecompiledFonts/$fontname.woff2" "RepackedFonts/$fontname.woff2"
done
