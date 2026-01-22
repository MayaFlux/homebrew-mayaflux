# typed: false
# frozen_string_literal: true

class Mayaflux < Formula
  desc "Modern C++23 framework for real-time graphics and audio with JIT live coding"
  homepage "https://github.com/MayaFlux/MayaFlux"
  version "0.1.2"
  license "GPL-3.0-or-later"
  conflicts_with "mayaflux-dev", because: "both install MayaFlux binaries"
  
  on_arm do
    url "https://github.com/MayaFlux/MayaFlux/releases/download/v#{version}/MayaFlux-#{version}-macos-arm64.tar.gz"
  end
  
  on_intel do
    url "https://github.com/MayaFlux/MayaFlux/releases/download/v#{version}/MayaFlux-#{version}-macos-x64.tar.gz"
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
  depends_on "mayaflux/mayaflux/stb"
  
  def install
    ohai "Verifying download integrity..."
    sha_url = "#{stable.url}.sha256"
    
    expected_sha = Utils.safe_popen_read("curl", "-fsSL", sha_url).strip
    actual_sha = Digest::SHA256.file(cached_download).hexdigest
    
    if expected_sha != actual_sha
      odie "SHA256 verification failed!\nExpected: #{expected_sha}\nActual: #{actual_sha}"
    end
    ohai "SHA256 verified: #{actual_sha}"
    
    bin.install Dir["bin/*"]
    lib.install Dir["lib/*"]
    share.install Dir["share/*"]
    (prefix/"include").install Dir["include/*"]
    
    (prefix/"env.sh").write <<~SHELL
      # MayaFlux Environment Setup

      # For CMake template MAYAFLUX_ROOT detection only
      export MAYAFLUX_ROOT="#{HOMEBREW_PREFIX}"

      # STB Pathing
      export STB_ROOT="#{Formula["stb"].opt_include}/stb"
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

      MOLTENVK_PREFIX="#{Formula["molten-vk"].opt_prefix}"
      VULKAN_LOADER_PREFIX="#{Formula["vulkan-loader"].opt_prefix}"
      VULKAN_LAYERS_PREFIX="#{Formula["vulkan-validationlayers"].opt_prefix}"
      export VK_LAYER_PATH="\$VULKAN_LAYERS_PREFIX/share/vulkan/explicit_layer.d"

      export DYLD_LIBRARY_PATH="\$MOLTENVK_PREFIX/lib:\$VULKAN_LOADER_PREFIX/lib:\$DYLD_LIBRARY_PATH"
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
      
      Documentation: https://github.com/MayaFlux/MayaFlux
    EOS
  end
  
  test do
    assert_predicate prefix/".version", :exist?
    assert_match version.to_s, (prefix/".version").read if (prefix/".version").exist?
  end
end
