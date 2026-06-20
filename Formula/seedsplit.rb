class Seedsplit < Formula
  desc "Split a secret into Shamir shares (pure Bash, GF(256))"
  homepage "https://github.com/Di-kairos/seedsplit"
  url "https://github.com/Di-kairos/seedsplit/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "e13ed87173dacde99a1ba7d7b13d4011ba8dfdf1b0ea6b8f92531116759935cd"
  license "MIT"

  def install
    bin.install "seedsplit"
  end

  test do
    assert_match "seedsplit", shell_output("#{bin}/seedsplit version")
  end
end
