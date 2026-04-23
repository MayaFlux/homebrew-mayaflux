class Tinyexr < Formula
  desc "Tiny OpenEXR image loader/saver library"
  homepage "https://github.com/syoyo/tinyexr"
  head "https://github.com/syoyo/tinyexr.git", branch: "release"
  license "BSD-3-Clause"

  def install
    include.install "tinyexr.h"
    include.install "deps/miniz/miniz.h"
    include.install "deps/miniz/miniz.c"

    (lib/"pkgconfig/tinyexr.pc").write <<~EOS
      prefix=#{prefix}
      exec_prefix=${prefix}
      includedir=${prefix}/include

      Name: tinyexr
      Description: Tiny OpenEXR image loader/saver library
      Version: head
      Cflags: -I${includedir}
    EOS
  end
end
