# ============================================================================
# XMRigCC C&C 源文件集合
#   - CC Server (xmrigServer) + Daemon (xmrigDaemon)：受 WITH_CC_SERVER 控制
#   - CC Client（嵌入矿工）：受 WITH_CC_CLIENT 控制
# 实际的 target 定义与编译宏见 CMakeLists.txt。
# ============================================================================

# --- CC 公共数据模型（Client / Server 共享）---
if (WITH_CC_SERVER OR WITH_CC_CLIENT)
    set(SOURCES_CC_COMMON
        src/cc/ControlCommand.cpp
        src/cc/ClientStatus.cpp
        src/cc/GPUInfo.cpp
        )
endif()

# --- CC Client（编译进矿工，向 server 上报并受控）---
if (WITH_CC_CLIENT)
    set(SOURCES_CC_CLIENT
        ${SOURCES_CC_COMMON}
        src/cc/CCClient.cpp
        src/cc/CCClientConfig.cpp
        src/base/io/log/backends/RemoteLog.cpp
        )
endif()

# --- CC Server 源码 + 其复用的 base 工具层 ---
if (WITH_CC_SERVER)
    set(SOURCES_CC_SERVER
        src/3rdparty/fmt/format.cc
        src/base/io/log/backends/ConsoleLog.cpp
        src/base/io/log/backends/FileLog.cpp
        src/base/io/log/FileLogWriter.cpp
        src/base/io/log/Log.cpp
        src/base/io/log/Tags.cpp
        src/base/io/json/Json.cpp
        src/base/io/json/JsonChain.cpp
        src/base/io/Console.cpp
        src/base/io/Env.cpp
        src/base/io/Signals.cpp
        src/base/kernel/config/Title.cpp
        src/base/kernel/Process.cpp
        src/base/tools/Arguments.cpp
        src/base/tools/String.cpp
        src/cc/CCCServerConfig.cpp
        src/cc/CCServer.cpp
        src/cc/Summary.cpp
        src/cc/Service.cpp
        src/cc/Httpd.cpp
        src/cc/XMRigCC.cpp
        )

    if (WIN32)
        list(APPEND SOURCES_CC_SERVER src/base/io/json/Json_win.cpp)
    else()
        list(APPEND SOURCES_CC_SERVER src/base/io/json/Json_unix.cpp)
    endif()

    # CC Server 的 TLS（HTTPS）依赖自动生成的自签证书
    if (WITH_TLS AND OPENSSL_FOUND)
        list(APPEND SOURCES_CC_SERVER src/base/net/tls/TlsGen.cpp)
    endif()
endif()
