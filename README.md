Proof-of-concept app to overwrite fonts on iOS using [CVE-2022-46689](https://support.apple.com/en-us/HT213530).

Works on iOS 16.1.2 and below (tested on iOS 16.1) on unjailbroken devices.

IPA available in the [Releases](https://github.com/zhuowei/WDBFontOverwrite/releases) section.

I'm probably not going to work on this further. If anyone else wants to take over, feel free.

Fonts included:

- DejaVu Sans Condensed
- DejaVu Serif
- DejaVu Sans Mono
- Go Regular
- Go Mono
- Fira Sans
- Segoe UI
- Comic Sans MS
- Choco Cooky

You can also import custom fonts that were ported for iOS.

## Screenshots

DejaVu Sans Condensed | DejaVu Serif | DejaVu Sans Mono | Choco Cooky

![Screenshot](https://user-images.githubusercontent.com/704768/209511898-a1477b66-28e4-471a-87d9-36c1c2eb25ca.png)

Go Regular | Go Mono | Segoe UI | Comic Sans MS

![Another screenshot](https://user-images.githubusercontent.com/704768/209606970-a382c273-bdcb-425c-bca1-1b6f9b31862f.png)

Hanna Soft + JoyPixels | Bronkoh | Noto Serif SC | Fira Sans

![Another screenshot](https://user-images.githubusercontent.com/704768/209753262-b8204c92-b873-41a7-8127-38bf86096470.png)

Screenshot credit: [@ev_ynw](https://twitter.com/ev_ynw) for the ported [Hanna Soft](https://app.box.com/s/g4uk1yyqxm36sl9ovbwkpbbpn9isol8h/file/997004671334) and [Bronkoh](https://app.box.com/s/g4uk1yyqxm36sl9ovbwkpbbpn9isol8h/file/915757902297) fonts, [JoyPixels](https://joypixels.com/download) for the emoji font

## Where to find ported fonts

- [@ev_ynw](https://twitter.com/ev_ynw)
- [@PoomSmart](https://github.com/PoomSmart/EmojiFonts/releases)

## Known issues

 - The built-in fonts are not properly ported (I don't know how to port fonts). For best results, use a custom font.
   - with the built-in fonts:
   - Only regular text uses the changed font: thin/medium/bold text falls back to Helvetica instead.
   - If the font doesn't show up at all, [disable "Bold Text"](https://twitter.com/m7mdabu7assan/status/1607609484901289985) in accessibility settings.
 - File pickers in apps will fail to open with the error "Something went wrong while displaying documents."
   - This happens if you replace the emoji font, or install fonts with [multiple weights](https://twitter.com/Gu3hi/status/1607986473198026752)
   - These fonts use the .ttc format, which breaks the files picker.
   - No workaround yet - you'll need to remove the custom font by rebooting.
   - It may be possible to convert a .ttc font to a .ttf font with tools such as https://github.com/DavidBarts/getfonts: I have not tested if this would fix the issue.
 - Custom font imports may not work: tapping on a font to import it [doesn't do anything](https://twitter.com/linshijin111/status/1607993438997446657)
   - No workaround yet. The built-in fonts should still work.
 - Importing a custom font from some cloud storage apps' file storage providers, such as Google Drive's file provider, crashes the app with a "The file doesn't exist" error.
   - Workaround: use the Files app to copy the font to your Downloads folder first.
 - iOS 14.x devices which are jailbroken / were jailbroken before will not be able to revert to the original font.
   - Workaround: do not use this app if you're on iOS 14.x and have previously jailbroken. Instead, just jailbreak and replace fonts normally.

## Font conversion

The CVE-2022-46689 issue - as far as I know - only lets you overwrite 16383 bytes out of every 16384 bytes: the last byte of the page can't be written.

(I could be wrong)

To work around this, I package the font using the [WOFF2](https://www.w3.org/TR/WOFF2/) webfont format, which is [supported on iOS](https://twitter.com/myunderpants/status/1503745380365877252). WOFF2 uses [Brotli](https://datatracker.ietf.org/doc/html/rfc7932) for compression, which lets me insert padding to skip over the last byte.

See `repackfonts/make_woff2src.sh` for details: this script:

- renames the font to .SFUI-Regular with [TTX](https://github.com/fonttools/fonttools) following [this answer](https://superuser.com/a/694452)
- rebuilds the font to .woff2
- runs `repackfonts/BrotliPadding.swift` to decompress the WOFF2 file and insert padding to skip past the 16384th byte


## Credits

- Ian Beer of [Project Zero](https://googleprojectzero.blogspot.com) for finding CVE-2022-46689.
- Apple for the [test case](https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.61.2/tests/vm/vm_unaligned_copy_switch_race.c) and [patch](https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.61.2/osfmk/vm/vm_map.c#L10150). (I didn't change anything: I only wrapped the test case in a library.)
- Everyone on Twitter who helped out and experimented with CVE-2022-46689, especially [@dedbeddedbed](https://twitter.com/dedbeddedbed), [@AppleDry05](https://twitter.com/AppleDry05), and [@haxi0sm](https://twitter.com/haxi0sm) for exploring what can be done with this issue..
- [WOFF2 compressor](https://twitter.com/ev_ynw) by Google
- The [DejaVu fonts](https://dejavu-fonts.github.io) are distributed according to their [license](https://dejavu-fonts.github.io/License.html).
- The [Go fonts](https://go.dev/blog/go-fonts) are distributed according to their license.
- The [Fira Sans](https://mozilla.github.io/Fira/) font is converted by [@jonpalmisc](https://twitter.com/jonpalmisc/status/1607570871421468678) - thanks!
- Segoe UI and Comic Sans MS are the property of Microsoft.
- Choco Cooky is the property of Samsung.
- I don't have any rights to redistribute these, but I'm posting them anyways because #yolo.
