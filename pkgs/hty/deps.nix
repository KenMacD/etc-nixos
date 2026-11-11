# Zig global package cache for hty, injected via ZIG_GLOBAL_CACHE_DIR.
#
# zon2nix can't parse zig 0.16 zon files yet (nix-community/zon2nix#66), so
# the dependency closure of hty's build.zig.zon is fetched here and `zig
# fetch`ed into the cache. The entry set is the empirical closure from a
# successful build; entries beyond the direct deps come from ghostty's
# nested build.zig.zon files.
#
# When bumping hty, regenerate this file the same way: build once with
# network access, unpack the resulting ZIG_GLOBAL_CACHE_DIR/p/*.tar.gz, map
# every package hash back to its source URL through the zon files, and hash
# each artifact.
{
  lib,
  fetchurl,
  fetchgit,
  runCommand,
  zig_0_16,
  name ? "hty-zig-cache",
}: let
  sources = [
    {
      hash = "N-V-__8AAAzZywE3s51XfsLbP9eyEw57ae9swYB9aGB6fCMs";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/wuffs-122037b39d577ec2db3fd7b2130e7b69ef6cc1807d68607a7c232c958315d381b5cd.tar.gz";
        hash = "sha256-nkzSCr6W5sTG7enDBXEIhgEm574uLD41UVR2wlC+HBM=";
      };
    }
    {
      hash = "N-V-__8AAB0eQwD-0MdOEBmz7intriBReIsIDNlukNVoNu6o";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/zlib-1220fed0c74e1019b3ee29edae2051788b080cd96e90d56836eea857b0b966742efb.tar.gz";
        hash = "sha256-F+iIY/NgBnKrSRgvIXKBtvxNPHYr3jYZNeQ2qVIU0Fw=";
      };
    }
    {
      hash = "N-V-__8AABzkUgISeKGgXAzgtutgJsZc0-kkeqBBscJgMkvy";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/glslang-12201278a1a05c0ce0b6eb6026c65cd3e9247aa041b1c260324bf29cee559dd23ba1.tar.gz";
        hash = "sha256-FKLtu1Ccs+UamlPj9eQ12/WXFgS0uDPmPmB26MCpl7U=";
      };
    }
    {
      hash = "N-V-__8AADYiAAB_80AWnH1AxXC0tql9thT-R-DYO1gBqTLc";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/pixels-12207ff340169c7d40c570b4b6a97db614fe47e0d83b5801a932dcd44917424c8806.tar.gz";
        hash = "sha256-Veg7FtCRCCUCvxSb9FfzH0IJLFmCZQ4/+657SIcb8Ro=";
      };
    }
    {
      hash = "N-V-__8AAEbOfQBnvcFcCX2W5z7tDaN8vaNZGamEQtNOe0UI";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/N-V-__8AAEbOfQBnvcFcCX2W5z7tDaN8vaNZGamEQtNOe0UI.tar.gz";
        hash = "sha256-yBbCDox18+Fa6Gc1DnmSVQLRpqhZOLsac7iSfl8x+cs=";
      };
    }
    {
      hash = "N-V-__8AAG02ugUcWec-Ndp-i7JTsJ0dgF8nnJRUInkGLG7G";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/harfbuzz-11.0.0.tar.xz";
        hash = "sha256-8WNRuv4hRyX+LB1bWfDZPkmQWkskeJn7kNcM/5U6K5s=";
      };
    }
    {
      hash = "N-V-__8AAG3RoQEyRC2Vw7Qoro5SYBf62IHn3HjqtNVY6aWK";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/libxml2-2.11.5.tar.gz";
        hash = "sha256-bCgFni4+60K1tLFkieORamNGwQladP7jvGXNxdiaYhU=";
      };
    }
    {
      hash = "N-V-__8AAGmZhABbsPJLfbqrh6JTHsXhY6qCaLAQyx25e0XE";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/highway-66486a10623fa0d72fe91260f96c892e41aceb06.tar.gz";
        hash = "sha256-h9T4iT704I8iSXNgj/6/lCaKgTgLp5wS6IQZaMgKohI=";
      };
    }
    {
      hash = "N-V-__8AAHjwMQDBXnLq3Q2QhaivE0kE2aD138vtX2Bq1g7c";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/oniguruma-1220c15e72eadd0d9085a8af134904d9a0f5dfcbed5f606ad60edc60ebeccd9706bb.tar.gz";
        hash = "sha256-ABqhIC54RI9MC/GkjHblVodrNvFtks4yB+zP1h2Z8qA=";
      };
    }
    {
      hash = "N-V-__8AAIC5lwAVPJJzxnCAahSvZTIlG-HhtOvnM1uh-66x";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/JetBrainsMono-2.304.tar.gz";
        hash = "sha256-xXppHouCrQmLWWPzlZAy5AOPORCHr3cViFulkEYQXMQ=";
      };
    }
    {
      hash = "N-V-__8AAIrfdwARSa-zMmxWwFuwpXf1T3asIN7s5jqi9c1v";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/fontconfig-2.14.2.tar.gz";
        hash = "sha256-O6LdkhWHGKzsXKrxpxYEO1qgVcJ7CB2RSvPMtA3OilU=";
      };
    }
    {
      hash = "N-V-__8AAJrvXQCqAT8Mg9o_tk6m0yf5Fz-gCNEOKLyTSerD";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/libpng-1220aa013f0c83da3fb64ea6d327f9173fa008d10e28bc9349eac3463457723b1c66.tar.gz";
        hash = "sha256-/syVtGzwXo4/yKQUdQ4LparQDYnp/fF16U/wQcrxoDo=";
      };
    }
    {
      hash = "N-V-__8AAKLKpwC4H27Ps_0iL3bPkQb-z6ZVSrB-x_3EEkub";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/freetype-1220b81f6ecfb3fd222f76cf9106fecfa6554ab07ec7fdc4124b9bb063ae2adf969d.tar.gz";
        hash = "sha256-QnIB9dUVFnDQXB9bRb713aHy592XHvVPD+qqf/0quQw=";
      };
    }
    {
      hash = "N-V-__8AALZGBAAS5NLVH-c8eC-6VtCdcH-9nUvVfUSkWS__";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/ghostty-themes-release-20260713-155359-c3968b3.tgz";
        hash = "sha256-FLMES+9no8uDUjlzvRbTqg+wCW3dHg7Lo5FtFNbWfyA=";
      };
    }
    {
      hash = "N-V-__8AAMVLTABmYkLqhZPLXnMl-KyN38R8UVYqGrxqO26s";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/NerdFontsSymbolsOnly-3.4.0.tar.gz";
        hash = "sha256-EWTRuVbUveJI17LwmYxDzJT1ICQxoVZKeTiVsec7DQQ=";
      };
    }
    {
      hash = "N-V-__8AANT61wB--nJ95Gj_ctmzAtcjloZ__hRqNw5lC1Kr";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/DearBindings_v0.17_ImGui_v1.92.5-docking.tar.gz";
        hash = "sha256-i/7FAOAJJvZ5hT7iPWfMOS08MYFzPKRwRzhlHT9wuqM=";
      };
    }
    {
      hash = "N-V-__8AANb6pwD7O1WG6L5nvD_rNMvnSc9Cpg1ijSlTYywv";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/spirv_cross-1220fb3b5586e8be67bc3feb34cbe749cf42a60d628d2953632c2f8141302748c8da.tar.gz";
        hash = "sha256-tStvz8Ref6abHwahNiwVVHNETizAmZVVaxVsU7pmV+M=";
      };
    }
    {
      hash = "aro-0.0.0-JSD1Qk8rOQDnuVcD4jAwMpHitA6pADRKzQ7M7hKRwxvD";
      src = fetchurl {
        url = "https://github.com/vancluever/arocc/archive/ecbc5c799574e0da2758a961b12efa586007f03c.tar.gz";
        hash = "sha256-qlRIe9cn6Po2dE/wqCTe2y9MpF9MLU2dJDfPX9PQrRo=";
      };
    }
    {
      hash = "ghostty-1.3.2-dev-5UdBCwfRJAX2W3lpOWUOrkLvsqJckxucSrjECoDjq9kL";
      src = fetchgit {
        url = "https://github.com/ghostty-org/ghostty.git";
        rev = "15484b607eb5a518dedf1548247c923b8abaae7c";
        hash = "sha256-2Cvzc6dyrsWMvgdsORT0Re9qJr8RKrRD/kY0Ta8gzTk=";
        deepClone = false;
        fetchSubmodules = false;
      };
    }
    {
      hash = "gobject-0.3.1-Skun7E1KnwBGMX5nslHYG1yWHaSevywxQO8oM7tTOgIp";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/gobject-2026-04-23-26-1.tar.zst";
        hash = "sha256-ZC4ySzZEwARkohYeSvSX9zy76M4CpMDtuSqss2V0gEc=";
      };
    }
    {
      hash = "libxev-0.0.0-86vtcwIRFADbH4hk-EjROXxlrKIRPQdA41XiTSytYO-F";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/libxev-9ce8e8e6ff89e583258a7f8e7adeeeaeae8611bf.tar.gz";
        hash = "sha256-4rmyJM14EBFWq7j0ZHmlH2zOZsSBXGMoVuIKFEDdArc=";
      };
    }
    {
      hash = "translate_c-0.0.0-Q_BUWj8_BwCr4na219OimiKKj4IVSq0aKtMXCQmIk4AB";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/translate_c-a916baf225a3cfc93a982225462db612604ae290.tar.gz";
        hash = "sha256-T9Kish28ScIr6mhUpZp1aNx3GDdgUxrOPPjaEmdpav0=";
      };
    }
    {
      hash = "uucode-0.2.0-ZZjBPlK5VADj7fdoq7G8LIHzD5o6FSkcBXXrRWr4jnrA";
      src = fetchgit {
        url = "https://github.com/jacobsandlund/uucode";
        rev = "2826a37a4562284fdacd8fa029d49509cc9bffcd";
        hash = "sha256-R5RXW5tWIaDq5JOF2+oWd5YOYOyns6WH7f687WE+b20=";
        deepClone = false;
        fetchSubmodules = false;
      };
    }
    {
      hash = "vaxis-0.6.0-BWNV_CrbCQCscGpzsAlR402rYQ_tV3aAl081c2iRRkka";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/vaxis-1dbbe575dff4586fe51e3217aa5c3fecdcbb6089.tar.gz";
        hash = "sha256-PqBQ6QWIfEa8oaLBjkHW7fV0wapuv7xc88UoRideT6g=";
      };
    }
    {
      hash = "z2d-0.11.0-j5P_HtLzDwBGyQt49DrT0v4BuVqI_SRs6CXsuj7eBVhR";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/z2d-0.11.0-j5P_HtLzDwBGyQt49DrT0v4BuVqI_SRs6CXsuj7eBVhR.tar.gz";
        hash = "sha256-1IsRcwf3Z8o3m/Mb0XGIDmbcr7ieykqPkjIiYZmS/LQ=";
      };
    }
    {
      hash = "zf-0.11.0-OIRy8X-RAAAwaRXHMYpj2uvBnuGTZWEE_3V7acqHQNtW";
      src = fetchurl {
        url = "https://deps.files.ghostty.org/zf-c35c421f84895193246db06c40683c1a30e616ef.tar.gz";
        hash = "sha256-ykvBCf2dl87a4vW9uHnMeMNG1DwUo046Kr0u6SCMhUc=";
      };
    }
    {
      hash = "zg-0.16.2-oGqU3HqftgI6rwFS90ypwfjgToH8Pz829OKuFURlm773";
      src = fetchgit {
        url = "https://codeberg.org/atman/zg.git";
        rev = "ce364b17d60b28fda1af24c6575b93c47afe043e";
        hash = "sha256-YeLHpMVSyzhe8uvh9uIiEhdSLhQuE8DEQDsHjuDycYY=";
        deepClone = false;
        fetchSubmodules = false;
      };
    }
    {
      hash = "zigimg-0.1.0-8_eo2oyaFwBZwJpmqPkCfVXWBrHcqbYwmrp1I6bTD3lI";
      src = fetchgit {
        url = "https://github.com/zigimg/zigimg";
        rev = "d695acd97c02e57bb151e8f659d1280f5cd6ca70";
        hash = "sha256-0IYATQldT6eJxRR2T/2CsIYZuzomqjvmdVyjmsjguyE=";
        deepClone = false;
        fetchSubmodules = false;
      };
    }
  ];
in
  runCommand name {
    nativeBuildInputs = [zig_0_16];
    manifest = (lib.concatStringsSep "\n" (map (e: "${e.hash}\t${e.src}") sources)) + "\n";
    passAsFile = ["manifest"];
  } ''
    mkdir -p "$out"
    export ZIG_GLOBAL_CACHE_DIR="$out"
    # workaround https://codeberg.org/ziglang/zig/issues/31866
    mkdir "$TMPDIR/src"
    touch "$TMPDIR/src/build.zig"
    cd "$TMPDIR/src"
    while IFS=$'\t' read -r expected src; do
      got="$(zig fetch --global-cache-dir "$out" "$src")"
      if [ "$got" != "$expected" ]; then
        echo "zig package hash mismatch for $src" >&2
        echo "  expected: $expected" >&2
        echo "  got:      $got" >&2
        exit 1
      fi
      echo "fetched $got"
    done < "$manifestPath"
  ''
