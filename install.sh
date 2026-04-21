#!/bin/bash

set -e

VERSION="$1"

if [[ -n "$VERSION" ]] && [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "用法: $0 [版本号]" >&2
    echo "示例: $0 1.0.0" >&2
    exit 1
fi

# 配置项
BASE_URL="https://github.com/shansongtech/iss-ai-open/releases/download"
LATEST_VERSION_URL="https://raw.githubusercontent.com/shansongtech/iss-ai-open/refs/heads/main/latest"
DOWNLOAD_DIR="$HOME/.iss-open-cli/downloads"
INSTALL_DIR="$HOME/.iss-open-cli"
BINARY_NAME="iss-open-cli"

DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
else
    echo "错误: 需要安装 curl" >&2
    exit 1
fi

download_file() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOADER" = "curl" ]; then
        if [ -n "$output" ]; then
            # 下载文件到指定路径，显示进度条
            curl -#L -f -o "$output" "$url"
        else
            # 下载内容到标准输出，静默模式（用于获取版本号）
            curl -sL -f "$url"
        fi
    else
        return 1
    fi
}

case "$(uname -s)" in
    Darwin) os="macos" ;;
    Linux) os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *) echo "不支持的操作系统: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac

if [ "$os" = "macos" ] && [ "$arch" = "amd64" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
        arch="arm64"
    fi
fi

platform="${os}-${arch}"

if [ "$os" = "windows" ]; then
    BINARY_FILE="${BINARY_NAME}-windows-${arch}.exe"
else
    BINARY_FILE="${BINARY_NAME}-${os}-${arch}"
fi

echo "检测到平台: $platform"
echo ""

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$INSTALL_DIR"

# 如果未指定版本，从静态服务器获取最新版本
if [ -z "$VERSION" ]; then
    echo "正在获取最新版本..."
    VERSION=$(download_file "$LATEST_VERSION_URL" 2>/dev/null)
    if [ -z "$VERSION" ]; then
        echo "[错误] 获取最新版本失败" >&2
        echo "请检查:" >&2
        echo "  - 网络连接是否正常" >&2
        echo "  - 服务器 $LATEST_VERSION_URL 是否可访问" >&2
        exit 1
    fi
    # 去除版本号前后可能的空白字符和换行符
    VERSION=$(echo "$VERSION" | tr -d '[:space:]')
    # 验证版本号格式
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[错误] 获取的版本号格式无效: '$VERSION'" >&2
        echo "期望格式: X.Y.Z (例如: 1.0.0)" >&2
        exit 1
    fi
    echo "最新版本: $VERSION"
fi

echo ""
echo "正在安装 iss-open-cli 版本: $VERSION"
echo ""

DOWNLOAD_URL="${BASE_URL}/${VERSION}/${BINARY_NAME}-${VERSION}-${platform}.tar.gz"

echo "下载地址: $DOWNLOAD_URL"

ARCHIVE_PATH="$DOWNLOAD_DIR/${BINARY_NAME}-${VERSION}-${platform}.tar.gz"
echo "正在下载..."
if ! download_file "$DOWNLOAD_URL" "$ARCHIVE_PATH"; then
    echo "" >&2
    echo "[错误] 下载失败！" >&2
    echo "" >&2
    echo "下载地址: $DOWNLOAD_URL" >&2
    echo "" >&2
    echo "可能的原因:" >&2
    echo "  1. 版本 '$VERSION' 不存在" >&2
    echo "  2. 平台 '$platform' 不受支持" >&2
    echo "  3. 网络连接问题或服务器不可达" >&2
    echo "  4. 文件权限不足" >&2
    echo "" >&2
    echo "建议:" >&2
    echo "  - 检查版本号是否正确: $0 <版本号>" >&2
    echo "  - 检查网络连接" >&2
    echo "  - 查看上方 curl/wget 的详细错误信息" >&2
    rm -f "$ARCHIVE_PATH"
    exit 1
fi
echo ""

echo "[OK] 下载完成"

TEMP_DIR="$DOWNLOAD_DIR/temp-extract-$$"
mkdir -p "$TEMP_DIR"

if ! tar -xzf "$ARCHIVE_PATH" -C "$TEMP_DIR" 2>/dev/null; then
    echo "解压归档文件失败" >&2
    rm -rf "$TEMP_DIR" "$ARCHIVE_PATH"
    exit 1
fi

echo "[OK] 归档文件已解压"

# 查找解压后的目录
EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d ! -path "$TEMP_DIR" | head -n 1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo "解压后的目录结构异常" >&2
    rm -rf "$TEMP_DIR" "$ARCHIVE_PATH"
    exit 1
fi

echo "正在安装文件到: $INSTALL_DIR"

# 检测是否存在旧版本
IS_UPGRADE=false
if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/$BINARY_NAME" -o -f "$INSTALL_DIR/${BINARY_NAME}.exe" ]; then
    IS_UPGRADE=true
    echo "[检测] 发现已安装的旧版本，将执行升级安装"
    
    # 获取旧版本信息
    OLD_EXECUTABLE=""
    if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        OLD_EXECUTABLE="$INSTALL_DIR/$BINARY_NAME"
    elif [ -f "$INSTALL_DIR/${BINARY_NAME}.exe" ]; then
        OLD_EXECUTABLE="$INSTALL_DIR/${BINARY_NAME}.exe"
    fi
    
    if [ -n "$OLD_EXECUTABLE" ]; then
        OLD_VERSION=$("$OLD_EXECUTABLE" --version 2>&1 | head -n 1 || echo "未知版本")
        echo "  当前版本: $OLD_VERSION"
        echo "  新版本: $VERSION"
    fi
    
    echo ""
fi

# 升级安装：只替换二进制文件，保留配置和日志
if [ "$IS_UPGRADE" = true ]; then
    echo "[升级] 正在替换二进制文件..."
    
    # 从解压目录中查找二进制文件
    NEW_BINARY=""
    if [ -f "$EXTRACTED_DIR/$BINARY_NAME" ]; then
        NEW_BINARY="$EXTRACTED_DIR/$BINARY_NAME"
    elif [ -f "$EXTRACTED_DIR/${BINARY_NAME}.exe" ]; then
        NEW_BINARY="$EXTRACTED_DIR/${BINARY_NAME}.exe"
    fi
    
    if [ -z "$NEW_BINARY" ]; then
        echo "错误: 压缩包中未找到二进制文件" >&2
        rm -rf "$TEMP_DIR" "$ARCHIVE_PATH"
        exit 1
    fi
    
    # 直接替换二进制文件
    if cp -f "$NEW_BINARY" "$INSTALL_DIR/"; then
        echo "  [OK] 二进制文件已更新"
    else
        echo "  错误: 替换二进制文件失败" >&2
        rm -rf "$TEMP_DIR" "$ARCHIVE_PATH"
        exit 1
    fi
else
    # 全新安装：复制所有文件
    echo "[安装] 正在复制文件..."
    
    if cp -r "$EXTRACTED_DIR"/* "$INSTALL_DIR/" 2>/dev/null || cp -r "$EXTRACTED_DIR"/. "$INSTALL_DIR/" 2>/dev/null; then
        echo "  [OK] 文件已复制到安装目录"
    else
        echo "  错误: 复制文件失败" >&2
        rm -rf "$TEMP_DIR" "$ARCHIVE_PATH"
        exit 1
    fi
fi

# 确保可执行文件有执行权限
if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
elif [ -f "$INSTALL_DIR/${BINARY_NAME}.exe" ]; then
    chmod +x "$INSTALL_DIR/${BINARY_NAME}.exe"
fi

echo "[OK] 安装完成到: $INSTALL_DIR"

# 自动配置 PATH 的函数
configure_path() {
    local install_dir="$1"
    local export_line='export PATH="$PATH:'"$install_dir"'"'
    
    # 检测当前 shell
    local current_shell=$(basename "$SHELL")
    local config_file=""
    
    case "$current_shell" in
        bash)
            # 优先使用 .bashrc，如果不存在则使用 .bash_profile
            if [ -f "$HOME/.bashrc" ]; then
                config_file="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                config_file="$HOME/.bash_profile"
            else
                config_file="$HOME/.bashrc"
            fi
            ;;
        zsh)
            config_file="$HOME/.zshrc"
            ;;
        fish)
            # fish shell 使用不同的语法
            export_line='set -gx PATH $PATH '"$install_dir"
            config_file="$HOME/.config/fish/config.fish"
            mkdir -p "$(dirname "$config_file")"
            ;;
        *)
            return 1
            ;;
    esac
    
    # 检查配置文件中是否已存在该路径
    if [ -f "$config_file" ] && grep -q "$install_dir" "$config_file" 2>/dev/null; then
        return 0
    fi
    
    echo "[配置] 检测到您使用 $current_shell shell"
    echo "正在自动将 $install_dir 添加到 PATH..."
    
    echo "" >> "$config_file"
    echo "# iss-open-cli installation" >> "$config_file"
    echo "$export_line" >> "$config_file"
    echo "[OK] 已将 PATH 配置添加到 $config_file"
    echo ""
    echo "[提示] 配置已写入配置文件，但需要手动生效："
    echo "  方式1: 重新打开终端窗口"
    echo "  方式2: 运行命令: source $config_file"
    return 0
}

rm -rf "$TEMP_DIR" "$ARCHIVE_PATH"

echo ""
echo "正在验证安装..."
# 查找可执行文件
EXECUTABLE=""
if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    EXECUTABLE="$INSTALL_DIR/$BINARY_NAME"
elif [ -f "$INSTALL_DIR/${BINARY_NAME}.exe" ]; then
    EXECUTABLE="$INSTALL_DIR/${BINARY_NAME}.exe"
fi

if [ -n "$EXECUTABLE" ] && "$EXECUTABLE" --version >/dev/null 2>&1; then
    INSTALLED_VERSION=$("$EXECUTABLE" --version 2>&1 | head -n 1)
    echo "[OK] 安装成功!"
    echo "  版本: $INSTALLED_VERSION"
    echo "  位置: $INSTALL_DIR"
else
    echo "[警告] 文件已安装，但无法验证版本"
    echo "  位置: $INSTALL_DIR"
    echo "  请手动运行: $INSTALL_DIR/$BINARY_NAME --help"
fi

echo ""
echo "[完成] 安装成功!"
echo ""
echo "开始使用 iss-open-cli，请运行:"
echo "  $BINARY_NAME --help"
echo ""

# 检查并配置 PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:*" ]]; then
    configure_path "$INSTALL_DIR"
else
    echo "[OK] $INSTALL_DIR 已在 PATH 中"
fi
