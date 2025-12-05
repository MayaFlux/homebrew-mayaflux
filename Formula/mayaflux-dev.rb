class MayafluxDev < Formula
  desc "Development version of MayaFlux - high-performance audio-visual computation library"
  homepage "https://github.com/MayaFlux/MayaFlux"
  
  livecheck do
    url "https://api.github.com/repos/MayaFlux/MayaFlux/releases"
    strategy :json do |json|
      json.map do |release|
        release["tag_name"]&.gsub(/^v/, "")
      end.compact.first
    end
  end
  
  version do
    url "https://api.github.com/repos/MayaFlux/MayaFlux/releases"
    regex(/^v?(\d+(?:\.\d+)+(?:-dev)?)/i)
  end
  
  def asset_url
    api_url = "https://api.github.com/repos/MayaFlux/MayaFlux/releases"
    response = `curl -s -H "Accept: application/vnd.github.v3+json" "#{api_url}"`
    
    tag = response[/"tag_name":\s*"([^"]+)"/, 1]
    return nil unless tag
    
    asset_urls = response.scan(/"browser_download_url":\s*"([^"]+)"/).flatten
    asset = asset_urls.find { |url| url.include?("macos-arm64") && url.end_with?(".tar.gz") }
    
    unless asset
      clean_tag = tag.start_with?("v") ? tag[1..] : tag
      patterns = [
        "MayaFlux-#{clean_tag}-macos-arm64.tar.gz",
        "MayaFlux-#{tag}-macos-arm64.tar.gz",
        "#{clean_tag}-macos-arm64.tar.gz",
        "#{tag}-macos-arm64.tar.gz"
      ]
      
      patterns.each do |pattern|
        test_url = "https://github.com/MayaFlux/MayaFlux/releases/download/#{tag}/#{pattern}"
        if system("curl -s -I \"#{test_url}\" 2>&1 | grep -q \"200 OK\"")
          asset = test_url
          break
        end
      end
    end
    
    asset
  end
  
  url do
    puts "Determining latest MayaFlux release..." if ARGV.verbose?
    url = asset_url
    odie "Could not find a suitable MayaFlux release for macOS ARM64" unless url
    puts "Downloading from: #{url}" if ARGV.verbose?
    url
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
    ohai "Installing STB headers..."
    stb_install_dir = prefix/"include"/"stb"
    
    stb_headers = [
      "stb_image.h",
      "stb_image_write.h",
      "stb_image_resize.h",
      "stb_truetype.h",
      "stb_rect_pack.h"
    ]
    
    stb_headers.each do |header|
      url = "https://raw.githubusercontent.com/nothings/stb/master/#{header}"
      curl_download url, to: stb_install_dir/header
    end
    
    prefix.install Dir["*"]
    
    (prefix/".version").write(version.to_s)
  end
  
  def caveats
    <<~EOS
      MayaFlux development version has been installed!
      
      Next steps:
        1. Source the environment setup:
           source #{opt_prefix}/env.sh
           
        2. Add this to your ~/.zshenv or ~/.bash_profile:
           export MAYAFLUX_ROOT="#{opt_prefix}"
           source "$MAYAFLUX_ROOT/env.sh"
           
      Environment variables set by MayaFlux:
        • MAYAFLUX_ROOT: #{opt_prefix}
        • PATH: #{opt_prefix}/bin added
        • CMAKE_PREFIX_PATH: #{opt_prefix} added
        • CPATH: #{opt_prefix}/include/stb added
        • STB_ROOT: #{opt_prefix}/include/stb
        • VK_ICD_FILENAMES: Vulkan ICD for MoltenVK
        • LLVM_DIR, Clang_DIR: Homebrew LLVM paths
      
      Documentation: https://github.com/MayaFlux/MayaFlux
    EOS
  end
  
  test do
    assert_predicate bin/"lila_server", :exist?
    
    assert_predicate prefix/"include"/"stb"/"stb_image.h", :exist?
    
    assert_predicate prefix/".version", :exist?
  end
end
