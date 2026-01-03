# typed: false
# frozen_string_literal: true

class MayafluxDev < Formula
  desc "Development version of MayaFlux - high-performance audio-visual computation library"
  homepage "https://github.com/MayaFlux/MayaFlux"
  version "0.1.0-dev"
  license "GPL-3.0-or-later"
  conflicts_with "mayaflux", because: "both install MayaFlux binaries"

  
  on_arm do
    url "https://github.com/MayaFlux/MayaFlux/releases/download/v0.1.0-dev/MayaFlux-0.1.0-dev-macos-arm64.tar.gz"
    # SHA256 verified dynamically at install time
  end
  
  on_intel do
    url "https://github.com/MayaFlux/MayaFlux/releases/download/v0.1.0-dev/MayaFlux-0.1.0-dev-macos-x64.tar.gz"
    # SHA256 verified dynamically at install time
  end
  
  depends_on "pkg-config"
  depends_on "llvm"
  depends_on "ffmpeg"
  depends_on "rtaudio"
  depends_on "glfw"
  depends_on "glm"
  depends_on "eigen"
  depends_on "fmt"
  depends_on "magic_enum"
  depends_on "onedpl"
  depends_on "googletest"
  depends_on "vulkan-headers"
  depends_on "vulkan-loader"
  depends_on "vulkan-tools"
  depends_on "vulkan-validationlayers"
  depends_on "vulkan-utility-libraries"
  depends_on "spirv-tools"
  depends_on "spirv-cross"
  depends_on "shaderc"
  depends_on "glslang"
  depends_on "molten-vk"
  
  def install
    # Fetch and verify SHA256 dynamically from GitHub release
    ohai "Verifying download integrity..."
    sha_url = "#{stable.url}.sha256"
    
    expected_sha = Utils.safe_popen_read("curl", "-fsSL", sha_url).strip
    actual_sha = Digest::SHA256.file(cached_download).hexdigest
    
    if expected_sha != actual_sha
      odie "SHA256 verification failed!\nExpected: #{expected_sha}\nActual: #{actual_sha}"
    end
    ohai "✅ SHA256 verified: #{actual_sha}"
    
    ohai "Installing STB headers..."
    stb_install_dir = prefix/"include"/"stb"
    stb_install_dir.mkpath
    
    stb_headers = [
      "stb_image.h",
      "stb_image_write.h",
      "stb_image_resize2.h",
      "stb_truetype.h",
      "stb_rect_pack.h"
    ]
    
    stb_headers.each do |header|
      system "curl", "-fL", 
             "https://raw.githubusercontent.com/nothings/stb/master/#{header}",
             "-o", stb_install_dir/header
    end
    
    bin.install Dir["bin/*"]
    lib.install Dir["lib/*"]
    share.install Dir["share/*"]
    (prefix/"include").install Dir["include/*"]
    
    (prefix/"env.sh").write <<~SHELL
      # MayaFlux Environment Setup
      export MAYAFLUX_ROOT="#{opt_prefix}"
      export PATH="\$MAYAFLUX_ROOT/bin:\$PATH"
      export CMAKE_PREFIX_PATH="\$MAYAFLUX_ROOT:\$CMAKE_PREFIX_PATH"
      
      # MayaFlux library and include paths
      export DYLD_LIBRARY_PATH="\$MAYAFLUX_ROOT/lib:\$DYLD_LIBRARY_PATH"
      export LIBRARY_PATH="\$MAYAFLUX_ROOT/lib:\$LIBRARY_PATH"
      export CPATH="\$MAYAFLUX_ROOT/include:\$CPATH"
      export PKG_CONFIG_PATH="\$MAYAFLUX_ROOT/lib/pkgconfig:\$PKG_CONFIG_PATH"
      export STB_ROOT="\$MAYAFLUX_ROOT/include/stb"
      export CPATH="\$STB_ROOT:\$CPATH"
      
      LLVM_PREFIX="#{Formula["llvm"].opt_prefix}"
      export PATH="\$LLVM_PREFIX/bin:\$PATH"
      export LLVM_DIR="\$LLVM_PREFIX/lib/cmake/llvm"
      export Clang_DIR="\$LLVM_PREFIX/lib/cmake/clang"
      export CMAKE_PREFIX_PATH="\$LLVM_PREFIX/lib/cmake:\$CMAKE_PREFIX_PATH"
      
      if [ -f "#{Formula["molten-vk"].opt_prefix}/share/vulkan/icd.d/MoltenVK_icd.json" ]; then
        export VK_ICD_FILENAMES="#{Formula["molten-vk"].opt_prefix}/share/vulkan/icd.d/MoltenVK_icd.json"
      elif [ -f "#{Formula["molten-vk"].opt_prefix}/etc/vulkan/icd.d/MoltenVK_icd.json" ]; then
        export VK_ICD_FILENAMES="#{Formula["molten-vk"].opt_prefix}/etc/vulkan/icd.d/MoltenVK_icd.json"
      fi
    SHELL
    
    (prefix/".version").write(version.to_s)
  end
  
  def caveats
    <<~EOS
      MayaFlux #{version} has been installed!
      
      To set up your environment, add this to your ~/.zshenv:
        export MAYAFLUX_ROOT="#{opt_prefix}"
        source "\$MAYAFLUX_ROOT/env.sh"
      
      Or run manually:
        source #{opt_prefix}/env.sh
    EOS
  end
  
  test do
    assert_predicate prefix/".version", :exist?
    assert_match version.to_s, (prefix/".version").read if (prefix/".version").exist?
    
    assert_predicate prefix/"include"/"stb"/"stb_image.h", :exist?
  end
end
