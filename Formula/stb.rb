class Stb < Formula
  desc "Single-file public domain libraries for C/C++"
  homepage "https://github.com/nothings/stb"
  # Pulls the absolute latest from master every time it's installed
  url "https://github.com/nothings/stb.git", branch: "master"
  version "latest" 

  def install
    (include/"stb").install Dir["*.h"]
  end

test do
    # Check if a few core headers exist
    assert_predicate include/"stb/stb_image.h", :exist?
    assert_predicate include/"stb/stb_truetype.h", :exist?
  end

  def caveats
    <<~EOS
      stb headers are installed to #{opt_include}/stb.
      You can include them as <stb/stb_image.h> etc.
    EOS
  end
end
