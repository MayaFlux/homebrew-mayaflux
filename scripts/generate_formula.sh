#!/usr/bin/env bash

set -euo pipefail

REPO="MayaFlux/MayaFlux"
API_URL="https://api.github.com/repos/$REPO/releases"
TEMP_DIR=$(mktemp -d)

echo "Fetching latest release from GitHub..."
RELEASE_JSON=$(curl -s -H "Accept: application/vnd.github.v3+json" "$API_URL")

TAG=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name":\s*"\([^"]*\)".*/\1/')

if [ -z "$TAG" ]; then
    echo "ERROR: Could not fetch release tag"
    exit 1
fi

echo "Latest tag: $TAG"

ASSET_URL=$(echo "$RELEASE_JSON" |
    grep -o '"browser_download_url":\s*"[^"]*"' |
    sed 's/"browser_download_url":\s*"\([^"]*\)"/\1/' |
    grep -i "macos.*arm64.*\.tar\.gz" |
    head -1)

if [ -z "$ASSET_URL" ]; then
    echo "WARNING: Could not find macOS ARM64 asset, trying to construct URL..."

    CLEAN_TAG=${TAG#v}
    PATTERNS=(
        "MayaFlux-${CLEAN_TAG}-macos-arm64.tar.gz"
        "MayaFlux-${TAG}-macos-arm64.tar.gz"
        "${CLEAN_TAG}-macos-arm64.tar.gz"
        "${TAG}-macos-arm64.tar.gz"
    )

    for PATTERN in "${PATTERNS[@]}"; do
        TEST_URL="https://github.com/$REPO/releases/download/${TAG}/${PATTERN}"
        if curl -s -I "$TEST_URL" 2>/dev/null | grep -q "200 OK"; then
            ASSET_URL="$TEST_URL"
            break
        fi
    done

    if [ -z "$ASSET_URL" ]; then
        echo "ERROR: Could not find or construct download URL"
        exit 1
    fi
fi

echo "Asset URL: $ASSET_URL"

echo "Downloading asset to calculate SHA256..."
curl -fL --progress-bar "$ASSET_URL" -o "$TEMP_DIR/release.tar.gz"

SHA256=$(shasum -a 256 "$TEMP_DIR/release.tar.gz" | awk '{print $1}')
FILE_SIZE=$(stat -f%z "$TEMP_DIR/release.tar.gz" 2>/dev/null || echo "unknown")

echo "SHA256: $SHA256"
echo "File size: $FILE_SIZE bytes"

VERSION=${TAG#v}

cat >Formula/mayaflux-dev.rb <<RUBY
# Formula/mayaflux-dev.rb
class MayafluxDev < Formula
  desc "Development version of MayaFlux - high-performance audio-visual computation library"
  homepage "https://github.com/MayaFlux/MayaFlux"
  
  version "$VERSION"
  url "$ASSET_URL"
  sha256 "$SHA256"
  
  # Declare all required dependencies
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
    stb_install_dir.mkpath
    
    stb_headers = [
      "stb_image.h",
      "stb_image_write.h",
      "stb_image_resize.h",
      "stb_truetype.h",
      "stb_rect_pack.h"
    ]
    
    stb_headers.each do |header|
      system "curl", "-fL", 
             "https://raw.githubusercontent.com/nothings/stb/master/\#{header}",
             "-o", stb_install_dir/header
    end
    
    # Install MayaFlux
    prefix.install Dir["*"]
    
    (prefix/"env.sh").write <<~SHELL
      # MayaFlux Environment Setup
      export MAYAFLUX_ROOT="#{opt_prefix}"
      export PATH="\\$MAYAFLUX_ROOT/bin:\\$PATH"
      export CMAKE_PREFIX_PATH="\\$MAYAFLUX_ROOT:\\$CMAKE_PREFIX_PATH"
      export STB_ROOT="\\$MAYAFLUX_ROOT/include/stb"
      export CPATH="\\$STB_ROOT:\\$CPATH"
      
      LLVM_PREFIX="#{Formula["llvm"].opt_prefix}"
      export PATH="\\$LLVM_PREFIX/bin:\\$PATH"
      export LLVM_DIR="\\$LLVM_PREFIX/lib/cmake/llvm"
      export Clang_DIR="\\$LLVM_PREFIX/lib/cmake/clang"
      export CMAKE_PREFIX_PATH="\\$LLVM_PREFIX/lib/cmake:\\$CMAKE_PREFIX_PATH"
      
      if [ -f "#{Formula["molten-vk"].opt_prefix}/share/vulkan/icd.d/MoltenVK_icd.json" ]; then
        export VK_ICD_FILENAMES="#{Formula["molten-vk"].opt_prefix}/share/vulkan/icd.d/MoltenVK_icd.json"
      fi
    SHELL
    
    (prefix/".version").write(version.to_s)
  end
  
  def caveats
    <<~EOS
      MayaFlux #{version} has been installed!
      
      To set up your environment, add this to your ~/.zshenv:
        export MAYAFLUX_ROOT="#{opt_prefix}"
        source "\\$MAYAFLUX_ROOT/env.sh"
      
      Or run manually:
        source #{opt_prefix}/env.sh
    EOS
  end
  
  test do
    assert_predicate prefix/".version", :exist?
    assert_match version.to_s, (prefix/".version").read if (prefix/".version").exist?
    
    if (bin/"lila_server").exist?
      system bin/"lila_server", "--version"
    end
    
    assert_predicate prefix/"include"/"stb"/"stb_image.h", :exist?
  end
end
RUBY

echo "✅ Formula generated for MayaFlux version $VERSION"
echo "📦 SHA256: $SHA256"
echo ""
echo "To use:"
echo "  brew install --build-from-source ./Formula/mayaflux-dev.rb"
echo ""

rm -rf "$TEMP_DIR"
