# frozen_string_literal: true

module PlatformHash # rubocop:disable Metrics/ModuleLength,Style/Documentation
  PLATFORM_HASH = {
    wasm32: {
      wasip1: {
        oci: 'wasip1/wasm',
        target: 'wasm32-wasip1',
      },
      wasip2: {
        oci: 'wasi/wasm',
        target: 'wasm32-wasip2',
      },
    },
    x64: {
      linux: {
        oci: 'linux/amd64',
        target: 'x86_64-unknown-linux-musl',
      },
      macOS: {
        target: 'x86_64-apple-darwin',
      },
      win: {
        oci: 'windows/amd64',
        target: 'x86_64-pc-windows-msvc',
      },
      android: {
        target: 'x86_64-linux-android',
      },
    },
    x86: {
      linux: {
        oci: 'linux/386',
        target: 'i586-unknown-linux-musl',
      },
      win7: {
        target: 'i686-win7-windows-msvc',
      },
      win: {
        oci: 'windows/386',
        target: 'i686-pc-windows-msvc',
      },
      android: {
        target: 'i686-linux-android',
      },
    },
    arm64: {
      linux: {
        oci: 'linux/arm64',
        target: 'aarch64-unknown-linux-musl',
      },
      macOS: {
        target: 'aarch64-apple-darwin',
      },
      win: {
        oci: 'windows/arm64',
        target: 'aarch64-pc-windows-msvc',
      },
      android: {
        target: 'aarch64-linux-android',
      },
    },
    rv64gc: {
      linux: {
        oci: 'linux/riscv64',
        target: 'riscv64gc-unknown-linux-musl',
      },
    },
    loong64: {
      linux: {
        oci: 'linux/loong64',
        target: 'loongarch64-unknown-linux-musl',
      },
    },
    armv7a: {
      linux: {
        oci: 'linux/arm/v7',
        target: 'armv7-unknown-linux-musleabihf',
      },
      android: {
        target: 'thumbv7neon-linux-androideabi',
      },
    },
    armv6: {
      android: {
        target: 'arm-linux-androideabi',
      },
    },
    armv5te: {
      linux: {
        oci: 'linux/arm/v5',
        target: 'armv5te-unknown-linux-musleabi',
      },
    },
    mipsle: {
      linux: {
        oci: 'linux/mipsle',
        target: 'mipsel-unknown-linux-musl',
      },
    },
    s390x: {
      linux: {
        oci: 'linux/s390x',
        target: 's390x-unknown-linux-musl',
      },
    },
    ppc64le: {
      linux: {
        oci: 'linux/ppc64le',
        target: 'powerpc64le-unknown-linux-musl',
      },
    },
  }.freeze

  def self.platform_info(os, arch)
    PLATFORM_HASH[arch.to_sym][os.to_sym] or
      "(Maybe) unsupported: #{os}/#{arch}".log_warn
  end
end
