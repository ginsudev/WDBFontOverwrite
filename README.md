Proof-of-concept app to overwrite fonts on iOS using [CVE-2022-46689](https://support.apple.com/en-us/HT213530).

Works on iOS 16.1.2 and below (tested on iOS 16.1) on unjailbroken devices.

Fonts included:

- DejaVu Sans Condensed
- DejaVu Serif
- DejaVu Sans Mono
- Choco Cooky

![Screenshot](https://user-images.githubusercontent.com/704768/209511898-a1477b66-28e4-471a-87d9-36c1c2eb25ca.png)

## Choice of fonts

I don't know how to port fonts for iOS properly: I did look for guides, but they were too difficult.

The included fonts were the only fonts I found that worked without porting. Other fonts I tested all displayed in a really squished way.

## Font conversion

The CVE-2022-46689 issue - as far as I know - only lets you overwrite 16383 bytes out of every 16384 bytes: the last byte of the page can't be written.

(I could be wrong)

To work around this, I package the font using the [WOFF2](https://www.w3.org/TR/WOFF2/) webfont format, which is [supported on iOS](https://twitter.com/myunderpants/status/1503745380365877252). WOFF2 uses [Brotli](https://datatracker.ietf.org/doc/html/rfc7932) for compression, which lets me insert padding to skip over the last byte.

See `repackfonts/make_woff2src.sh` for details: this script:

- renames the font to .SFUI-Regular with [TTX](https://github.com/fonttools/fonttools) following [this answer]()
- rebuilds the font to .woff2
- runs `repackfonts/BrotliPadding.swift` to decompress the WOFF2 file and insert padding to skip past the 16384th byte


## Credits

- Ian Beer of [Project Zero](https://googleprojectzero.blogspot.com) for finding CVE-2022-46689.
- Apple for the [test case](https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.61.2/tests/vm/vm_unaligned_copy_switch_race.c) and [patch](https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.61.2/osfmk/vm/vm_map.c#L10150). (I didn't change anything: I only wrapped the test case in a library.)
- Everyone on Twitter who helped out and experimented with CVE-2022-46689, especially [@dedbeddedbed](https://twitter.com/dedbeddedbed), [@AppleDry05](https://twitter.com/AppleDry05), and [@haxi0sm](https://twitter.com/haxi0sm) for exploring what can be done with this issue..
- The [DejaVu fonts](https://dejavu-fonts.github.io) are distributed according to their [license](https://dejavu-fonts.github.io/License.html).
- Choco Cooky is the property of Samsung: I don't have any rights to redistribute it, but I'm posting it anyways because #yolo.
