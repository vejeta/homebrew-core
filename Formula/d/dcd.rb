class Dcd < Formula
  desc "Auto-complete program for the D programming language"
  homepage "https://github.com/dlang-community/DCD"
  url "https://github.com/dlang-community/DCD.git",
      tag:      "v0.18.8",
      revision: "48dbb94b4c7cfa9e24ea2de405a9c721bdd10750"
  license "GPL-3.0-or-later"
  head "https://github.com/dlang-community/dcd.git", branch: "master"

  bottle do
    sha256               arm64_golden_gate: "2bc4fcdd140936c1780a00f7d79efa45e4f17c7eecb334cb934dd6d0c068f2a0"
    sha256               arm64_tahoe:       "def9ae718fd56434aa61e338bd136ea87969ad7d0882dd6d77e8638d5e71a5a8"
    sha256               arm64_sequoia:     "a83999ecff188e405b7678439ef3b56ec70e301a7cf3a6be97ddd6644576a4d0"
    sha256 cellar: :any, arm64_linux:       "b944200f3819d9c58316de234dca817d9c8cb7167385d470fd40da7c17f8b979"
    sha256 cellar: :any, x86_64_linux:      "d0a03c980a417cef92a99257081e9179d9712f74a70fab9dff0538bff3c94e76"
  end

  depends_on "ldc" => :build

  def install
    system "make", "ldc"
    bin.install "bin/dcd-client", "bin/dcd-server"
  end

  test do
    port = free_port

    # spawn a server, using a non-default port to avoid
    # clashes with pre-existing dcd-server instances
    server = spawn bin/"dcd-server", "-p", port.to_s
    # Give it generous time to load
    sleep 0.5
    # query the server from a client
    system bin/"dcd-client", "-q", "-p", port.to_s
  ensure
    Process.kill "TERM", server
    Process.wait server
  end
end
