television_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$television_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <television_version> <build_version> [architecture]"
    echo "Example: $0 0.15.9 1 arm64"
    echo "Example: $0 0.15.9 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, i386, all"
    exit 1
fi

# Upstream tags have NO "v" prefix (e.g. 0.15.9).
UPSTREAM_URL="https://github.com/alexpasmantier/television/releases/download/${television_VERSION}"

# Completions are generated from the amd64 (musl) binary; they do not depend on
# the target architecture.
COMPLETIONS_RELEASE="tv-${television_VERSION}-x86_64-unknown-linux-musl"

# Function to map Debian architecture to the television release asset name.
# amd64 uses the statically linked musl build so it also runs on bookworm; the
# glibc x86_64 build needs GLIBC_2.39 which bookworm does not have.
# arm64/i386 only exist as glibc builds upstream, but they are linked against
# GLIBC_2.18 at most, so they run on every suite we target.
get_television_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "tv-${television_VERSION}-x86_64-unknown-linux-musl"
            ;;
        "arm64")
            echo "tv-${television_VERSION}-aarch64-unknown-linux-gnu"
            ;;
        "i386")
            echo "tv-${television_VERSION}-i686-unknown-linux-gnu"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Runtime dependencies per architecture (musl build is static, glibc builds are not).
get_package_depends() {
    local arch=$1
    case "$arch" in
        "amd64") echo "" ;;
        *)       echo "libc6 (>= 2.18), libgcc-s1" ;;
    esac
}

# Generate the shell completions once, from the amd64 musl binary.
generate_completions() {
    if [ -f completions/tv.bash ] && [ -f completions/tv.fish ] && [ -f completions/_tv ]; then
        echo "Using existing completions/"
        return 0
    fi

    echo "Generating shell completions from ${COMPLETIONS_RELEASE}..."
    rm -rf .completions-gen completions || true
    mkdir -p .completions-gen completions

    if ! wget -q -O ".completions-gen/src.tar.gz" "${UPSTREAM_URL}/${COMPLETIONS_RELEASE}.tar.gz"; then
        echo "❌ Failed to download ${COMPLETIONS_RELEASE} for completion generation"
        return 1
    fi
    tar -xf ".completions-gen/src.tar.gz" -C .completions-gen
    chmod +x ".completions-gen/${COMPLETIONS_RELEASE}/tv"

    ".completions-gen/${COMPLETIONS_RELEASE}/tv" completions bash > completions/tv.bash
    ".completions-gen/${COMPLETIONS_RELEASE}/tv" completions zsh  > completions/_tv
    ".completions-gen/${COMPLETIONS_RELEASE}/tv" completions fish > completions/tv.fish
    rm -rf .completions-gen

    for f in completions/tv.bash completions/_tv completions/tv.fish; do
        if [ ! -s "$f" ]; then
            echo "❌ Completion file $f is empty"
            return 1
        fi
    done
    echo "✅ Completions generated"
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local television_release
    local package_depends

    television_release=$(get_television_release "$build_arch")
    if [ -z "$television_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64, i386"
        return 1
    fi
    package_depends=$(get_package_depends "$build_arch")

    echo "Building for architecture: $build_arch using $television_release"

    # Clean up any previous builds for this architecture
    rm -rf "$television_release" || true
    rm -f "${television_release}.tar.gz" || true

    # Download and extract the television release for this architecture
    if ! wget "${UPSTREAM_URL}/${television_release}.tar.gz"; then
        echo "❌ Failed to download television binary for $build_arch"
        return 1
    fi

    # The tarballs contain a top-level directory named after the release
    if ! tar -xf "${television_release}.tar.gz"; then
        echo "❌ Failed to extract television binary for $build_arch"
        return 1
    fi

    rm -f "${television_release}.tar.gz"

    if [ ! -f "$television_release/tv" ] || [ ! -f "$television_release/doc/tv.1" ]; then
        echo "❌ Unexpected tarball layout for $build_arch (missing tv or doc/tv.1)"
        return 1
    fi

    # Upstream ships binaries for amd64/arm64/i386 only, and all of them work on
    # every Debian suite we target.
    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$television_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "television-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg television_VERSION="$television_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg PACKAGE_DEPENDS="$package_depends" \
            --build-arg TV_RELEASE="$television_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "television-$dist-$build_arch")"
        if ! docker cp "$id:/television_$FULL_VERSION.deb" - > "./television_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./television_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$television_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

if ! generate_completions; then
    exit 1
fi

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building television $television_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures
    ARCHITECTURES=("amd64" "arm64" "i386")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la television_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
