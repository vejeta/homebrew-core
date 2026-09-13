class TreallaProlog < Formula
  desc "Compact and efficient ISO Prolog interpreter written in plain old C"
  homepage "https://github.com/trealla-prolog/trealla-prolog"
  url "https://github.com/trealla-prolog/trealla-prolog/archive/refs/tags/v3.9.75.tar.gz"
  sha256 "6cc632d5a23329ad41b54a4a76a30938976eb3e51a814afa9a3ecdc259e773e3"
  license "MIT"
  head "https://github.com/trealla-prolog/trealla-prolog.git", branch: "main"

  livecheck do
    throttle 5
  end

  bottle do
    sha256 arm64_golden_gate: "00827ca7462a4816e3a54c1a3787b25907e018b06030b1956fcd5367e687fd37"
    sha256 arm64_tahoe:       "407cede6c29ebd55606a74a11e05858cf1b7bb184e505ec2e876275d8025c45f"
    sha256 arm64_sequoia:     "f239b76004d2414078f9ee278eefe2debac449efdcc615eaaf111a7ce11f8f19"
    sha256 arm64_linux:       "9627606cf69df15952d6f48154e04bf30b5bd921478ae65ebcc7f00628e954a8"
    sha256 x86_64_linux:      "e9aefc368f70431e2d8cd402cbfd39f721fab4ae32ee5972e3b1599d804facb5"
  end

  depends_on "openssl@4"

  uses_from_macos "libedit"
  uses_from_macos "libffi"

  def install
    args = ["PREFIX=#{prefix}", "OPENSSL=openssl@4"]
    # macOS keeps ffi.h in an ffi/ subdirectory, which the build's plain
    # `#include <ffi.h>` misses. TARGET_CFLAGS is the makefile's append hook.
    args << "TARGET_CFLAGS=-I#{MacOS.sdk_path}/usr/include/ffi" if OS.mac?
    system "make", "install", *args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tpl --version")

    assert_equal "42", shell_output("#{bin}/tpl -g 'X is 6*7, write(X), halt'").chomp

    # library(assoc) is not embedded in the binary, so this also proves the
    # installed library path was baked in correctly.
    goal = "use_module(library(assoc)), list_to_assoc([a-1, b-2], A), " \
           "get_assoc(b, A, V), write(V), halt"
    assert_equal "2", shell_output("#{bin}/tpl -g '#{goal}'").chomp
  end
end
