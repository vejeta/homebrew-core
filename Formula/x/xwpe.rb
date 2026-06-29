class Xwpe < Formula
  desc "Borland-style IDE clone with LSP/DAP support (terminal UI)"
  homepage "https://codeberg.org/mendezr/xwpe"
  url "https://codeberg.org/mendezr/xwpe/archive/v1.6.8.tar.gz"
  sha256 "45c6be86a5761c20e4a6371125521278e627154ab99cc0c49169b08f7df67f97"
  license "GPL-2.0-or-later"
  head "https://codeberg.org/mendezr/xwpe.git", branch: "main"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build
  # Required at build time: the manual is written in Texinfo and `makeinfo`
  # generates the `xwpe.info` pages that the editor opens from its own
  # Help -> Info menu (wired in via -DXWPE_INFODIR). The release tarball ships
  # only the `.texi` source, so the pages must be built here.
  depends_on "texinfo" => :build

  depends_on "json-c"
  depends_on "libvterm"
  depends_on "ncurses"
  depends_on "zlib"

  def install
    # ncurses is keg-only on macOS; teach pkg-config where ncursesw.pc lives.
    ENV.prepend_path "PKG_CONFIG_PATH", formula_opt_lib("ncurses")/"pkgconfig" if OS.mac?

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--without-x", "--without-gpm", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    require "pty"
    require "io/console" # IO#winsize=

    # xwpe is a full-screen TUI editor (vim/nano-style), not a CLI filter: it
    # never exits with an error on its argument. Drive the real editor under a
    # pseudo-terminal on three kinds of input and assert its behaviour by liveness
    # and on disk -- ground truth that does not depend on scraping the screen or
    # on any one keystroke firing, so it is robust on every platform. A hard kill
    # bounds each run, so the test can never hang.
    ENV["TERM"] = "xterm-256color"

    # Open `arg` in wpe for `secs`; return whether it was still running (i.e. it
    # opened the input without crashing), then hard-kill it.
    open_briefly = lambda do |arg, secs|
      r, _w, pid = PTY.spawn((bin/"wpe").to_s, arg.to_s)
      r.winsize = [24, 80]
      sleep secs
      alive = Process.waitpid(pid, Process::WNOHANG).nil?
      begin
        Process.kill "KILL", pid
        Process.waitpid pid
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
      r.close
      alive
    end

    # 1) A normal file: xwpe opens it and keeps running, without corrupting it.
    normal = testpath/"normal.c"
    normal.write("int main(void) { return 0; }\n")
    original = normal.read
    assert open_briefly.call(normal, 4), "xwpe crashed opening a normal file"
    assert_equal original, normal.read

    # 2) A file it cannot read/write: a read-only (0444) file opens read-only --
    #    xwpe keeps running and leaves the bytes untouched.
    readonly = testpath/"ro.c"
    readonly.write("ORIGINAL\n")
    readonly.chmod(0444)
    assert open_briefly.call(readonly, 4), "xwpe crashed opening a read-only file"
    assert_equal "ORIGINAL\n", readonly.read

    # 3) A directory: xwpe opens its built-in file manager and keeps running,
    #    rather than erroring or crashing.
    assert open_briefly.call(testpath, 4), "xwpe crashed opening a directory"
  end
end
