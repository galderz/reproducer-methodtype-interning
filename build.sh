#!/usr/bin/env bash
set -eux

JAVA_HOME="${JAVA_HOME:?Set JAVA_HOME to a GraalVM/Mandrel installation}"
native_image="$JAVA_HOME/bin/native-image"

source_jar_dir=getting-started/target/getting-started-1.0.0-SNAPSHOT-native-image-source-jar
lib="${source_jar_dir}/lib"

if [ ! -d "$lib" ]; then
    echo "ERROR: Run the non-layered build first:"
    echo "  cd getting-started && ./mvnw package -Dnative -DskipTests"
    exit 1
fi

mkdir -p target

echo "=== Building base layer (netty + essential Quarkus jars) ==="
"${native_image}" \
    -H:+PrintClassInitialization \
    -H:LayerCreate=libnettybaselayer.nil,module=java.base,module=jdk.localedata,package=io.netty.* \
    --initialize-at-build-time="" \
    --initialize-at-run-time=io.netty.buffer.AbstractReferenceCountedByteBuf \
    --initialize-at-run-time=io.netty.buffer.ByteBufAllocator \
    --initialize-at-run-time=io.netty.buffer.ByteBufUtil \
    --initialize-at-run-time=io.netty.buffer.ByteBufUtil\$HexUtil \
    --initialize-at-run-time=io.netty.buffer.PooledByteBufAllocator \
    --initialize-at-run-time=io.netty.buffer.Unpooled \
    --initialize-at-run-time=io.netty.buffer.UnpooledByteBufAllocator \
    --initialize-at-run-time=io.netty.channel.DefaultChannelId \
    --initialize-at-run-time=io.netty.channel.unix.Errors \
    --initialize-at-run-time=io.netty.channel.unix.FileDescriptor \
    --initialize-at-run-time=io.netty.channel.unix.IovArray \
    --initialize-at-run-time=io.netty.channel.unix.Limits \
    --initialize-at-run-time=io.netty.handler.codec.ReplayingDecoderByteBuf \
    --initialize-at-run-time=io.netty.handler.codec.compression.BrotliDecoder \
    --initialize-at-run-time=io.netty.handler.codec.compression.BrotliOptions \
    --initialize-at-run-time=io.netty.handler.codec.compression.ZstdConstants \
    --initialize-at-run-time=io.netty.handler.codec.compression.ZstdOptions \
    --initialize-at-run-time=io.netty.handler.codec.http.HttpObjectAggregator \
    --initialize-at-run-time=io.netty.handler.codec.http.HttpObjectEncoder \
    --initialize-at-run-time=io.netty.handler.codec.http.HttpServerExpectContinueHandler \
    --initialize-at-run-time=io.netty.handler.codec.http.websocketx.WebSocket00FrameEncoder \
    --initialize-at-run-time=io.netty.handler.codec.http.websocketx.extensions.compression.DeflateDecoder \
    --initialize-at-run-time=io.netty.handler.codec.http2.CleartextHttp2ServerUpgradeHandler \
    --initialize-at-run-time=io.netty.handler.codec.http2.DefaultHttp2FrameWriter \
    --initialize-at-run-time=io.netty.handler.codec.http2.Http2ClientUpgradeCodec \
    --initialize-at-run-time=io.netty.handler.codec.http2.Http2CodecUtil \
    --initialize-at-run-time=io.netty.handler.codec.http2.Http2ConnectionHandler \
    --initialize-at-run-time=io.netty.handler.pcap.PcapWriteHandler\$WildcardAddressHolder \
    --initialize-at-run-time=io.netty.handler.ssl.BouncyCastleAlpnSslUtils \
    --initialize-at-run-time=io.netty.handler.ssl.ConscryptAlpnSslEngine \
    --initialize-at-run-time=io.netty.handler.ssl.JdkSslServerContext \
    --initialize-at-run-time=io.netty.handler.ssl.ReferenceCountedOpenSslContext \
    --initialize-at-run-time=io.netty.handler.ssl.ReferenceCountedOpenSslEngine \
    --initialize-at-run-time=io.netty.handler.ssl.util.ThreadLocalInsecureRandom \
    --initialize-at-run-time=io.netty.resolver.HostsFileEntriesResolver \
    --initialize-at-run-time=io.netty.resolver.dns.DefaultDnsServerAddressStreamProvider \
    --initialize-at-run-time=io.netty.resolver.dns.DnsNameResolver \
    --initialize-at-run-time=io.netty.resolver.dns.DnsNameResolverBuilder \
    --initialize-at-run-time=io.netty.resolver.dns.DnsServerAddressStreamProviders\$DefaultProviderHolder \
    --initialize-at-run-time=io.netty.resolver.dns.ResolvConf\$ResolvConfLazy \
    --initialize-at-run-time=io.netty.util.AbstractReferenceCounted \
    --initialize-at-run-time=io.netty.util.NetUtil \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilLocalhost4LazyHolder \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilLocalhost6LazyHolder \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilLocalhostLazyHolder \
    --initialize-at-run-time=io.quarkus.netty.runtime.EmptyByteBufStub \
    --initialize-at-run-time=io.quarkus.runtime.graal.InetRunTime \
    --initialize-at-run-time=io.smallrye.common.net.HostName \
    --initialize-at-run-time=io.smallrye.common.os.Process \
    --initialize-at-run-time=io.smallrye.common.ref.References\$ReaperThread \
    --initialize-at-run-time=org.jboss.logmanager.handlers.ConsoleHandler\$ConsoleHolder \
    --initialize-at-run-time=org.jboss.logmanager.handlers.SyslogHandler \
    --initialize-at-run-time=org.jboss.threads.JDKSpecific\$ThreadAccess \
    --initialize-at-run-time=java.rmi \
    --initialize-at-run-time=sun.rmi \
    --initialize-at-run-time=jdk.tools.jlink.internal.plugins \
    --initialize-at-run-time=jdk.jpackage.internal.LinuxPackageArch\$DebPackageArch \
    --initialize-at-run-time=jdk.jpackage.internal.LinuxPackageArch\$RpmPackageArch \
    -cp $(echo \
        ${lib}/io.netty.*.jar \
        ${lib}/modified-io.netty.*.jar \
        ${lib}/com.aayushatharva.brotli4j.*.jar \
        ${lib}/io.quarkus.quarkus-core-999-SNAPSHOT.jar \
        ${lib}/io.quarkus.quarkus-netty-999-SNAPSHOT.jar \
        ${lib}/io.quarkus.quarkus-bootstrap-runner-999-SNAPSHOT.jar \
        ${lib}/io.quarkus.quarkus-classloader-commons-999-SNAPSHOT.jar \
        ${lib}/io.smallrye.common.smallrye-common-*.jar \
        ${lib}/io.smallrye.config.smallrye-config-core-*.jar \
        ${lib}/io.smallrye.config.smallrye-config-common-*.jar \
        ${lib}/org.jboss.logmanager.jboss-logmanager-*.jar \
        ${lib}/org.jboss.logging.jboss-logging-*.jar \
        ${lib}/org.jboss.threads.jboss-threads-*.jar \
        ${lib}/org.slf4j.slf4j-api-*.jar \
        ${lib}/org.wildfly.common.wildfly-common-*.jar \
        ${lib}/org.eclipse.microprofile.config.microprofile-config-api-*.jar \
        | tr ' ' ':') \
    -o libnettybaselayer -H:Path=./target

echo "=== Building app layer ==="
"${native_image}" \
    -H:ApplicationLayerInitializedClasses=io.quarkus.arc.Arc \
    -H:ApplicationLayerInitializedClasses=io.quarkus.smallrye.context.runtime.SmallRyeContextPropagationRecorder \
    -H:ApplicationLayerInitializedClasses=io.quarkus.arc.runtime.ArcRecorder \
    -H:+PrintClassInitialization \
    --initialize-at-run-time=io.netty.buffer.AbstractReferenceCountedByteBuf \
    --initialize-at-run-time=io.netty.buffer.ByteBufAllocator \
    --initialize-at-run-time=io.netty.buffer.ByteBufUtil \
    --initialize-at-run-time=io.netty.buffer.ByteBufUtil\$HexUtil \
    --initialize-at-run-time=io.netty.buffer.PooledByteBufAllocator \
    --initialize-at-run-time=io.netty.buffer.Unpooled \
    --initialize-at-run-time=io.netty.buffer.UnpooledByteBufAllocator \
    --initialize-at-run-time=io.netty.channel.DefaultChannelId \
    --initialize-at-run-time=io.netty.channel.unix.Errors \
    --initialize-at-run-time=io.netty.channel.unix.FileDescriptor \
    --initialize-at-run-time=io.netty.channel.unix.IovArray \
    --initialize-at-run-time=io.netty.channel.unix.Limits \
    --initialize-at-run-time=io.netty.handler.codec.ReplayingDecoderByteBuf \
    --initialize-at-run-time=io.netty.handler.codec.compression.BrotliDecoder \
    --initialize-at-run-time=io.netty.handler.codec.compression.BrotliOptions \
    --initialize-at-run-time=io.netty.handler.codec.compression.ZstdConstants \
    --initialize-at-run-time=io.netty.handler.codec.compression.ZstdOptions \
    --initialize-at-run-time=io.netty.handler.codec.http.HttpObjectAggregator \
    --initialize-at-run-time=io.netty.handler.codec.http.HttpObjectEncoder \
    --initialize-at-run-time=io.netty.handler.codec.http.HttpServerExpectContinueHandler \
    --initialize-at-run-time=io.netty.handler.codec.http.websocketx.WebSocket00FrameEncoder \
    --initialize-at-run-time=io.netty.handler.codec.http.websocketx.extensions.compression.DeflateDecoder \
    --initialize-at-run-time=io.netty.handler.codec.http2.CleartextHttp2ServerUpgradeHandler \
    --initialize-at-run-time=io.netty.handler.codec.http2.DefaultHttp2FrameWriter \
    --initialize-at-run-time=io.netty.handler.codec.http2.Http2ClientUpgradeCodec \
    --initialize-at-run-time=io.netty.handler.codec.http2.Http2CodecUtil \
    --initialize-at-run-time=io.netty.handler.codec.http2.Http2ConnectionHandler \
    --initialize-at-run-time=io.netty.handler.pcap.PcapWriteHandler\$WildcardAddressHolder \
    --initialize-at-run-time=io.netty.handler.ssl.BouncyCastleAlpnSslUtils \
    --initialize-at-run-time=io.netty.handler.ssl.ConscryptAlpnSslEngine \
    --initialize-at-run-time=io.netty.handler.ssl.JdkSslServerContext \
    --initialize-at-run-time=io.netty.handler.ssl.ReferenceCountedOpenSslContext \
    --initialize-at-run-time=io.netty.handler.ssl.ReferenceCountedOpenSslEngine \
    --initialize-at-run-time=io.netty.handler.ssl.util.ThreadLocalInsecureRandom \
    --initialize-at-run-time=io.netty.resolver.HostsFileEntriesResolver \
    --initialize-at-run-time=io.netty.resolver.dns.DefaultDnsServerAddressStreamProvider \
    --initialize-at-run-time=io.netty.resolver.dns.DnsNameResolver \
    --initialize-at-run-time=io.netty.resolver.dns.DnsNameResolverBuilder \
    --initialize-at-run-time=io.netty.resolver.dns.DnsServerAddressStreamProviders\$DefaultProviderHolder \
    --initialize-at-run-time=io.netty.resolver.dns.ResolvConf\$ResolvConfLazy \
    --initialize-at-run-time=io.netty.util.AbstractReferenceCounted \
    --initialize-at-run-time=io.netty.util.NetUtil \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilLocalhost4LazyHolder \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilLocalhost6LazyHolder \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilLocalhostLazyHolder \
    --initialize-at-run-time=io.netty.util.NetUtilSubstitutions\$NetUtilNetworkInterfacesLazyHolder \
    --initialize-at-run-time=io.netty.util.concurrent.GlobalEventExecutor \
    --initialize-at-run-time=io.netty.util.concurrent.ImmediateEventExecutor \
    --initialize-at-run-time=io.netty.util.concurrent.ScheduledFutureTask \
    --initialize-at-run-time=io.netty.util.internal.ThreadLocalRandom \
    --initialize-at-run-time=io.quarkus.netty.runtime.EmptyByteBufStub \
    --initialize-at-run-time=io.quarkus.runtime.ExecutorRecorder \
    --initialize-at-run-time=io.quarkus.runtime.configuration.RuntimeConfigBuilder\$UuidConfigSource\$Holder \
    --initialize-at-run-time=io.quarkus.runtime.graal.InetRunTime \
    --initialize-at-run-time=io.smallrye.common.net.HostName \
    --initialize-at-run-time=io.smallrye.common.os.Process \
    --initialize-at-run-time=io.smallrye.common.ref.References\$ReaperThread \
    --initialize-at-run-time=io.vertx.core.buffer.impl.PartialPooledByteBufAllocator \
    --initialize-at-run-time=io.vertx.core.buffer.impl.VertxByteBufAllocator \
    --initialize-at-run-time=io.vertx.core.eventbus.impl.clustered.ClusteredEventBus \
    --initialize-at-run-time=io.vertx.core.http.impl.Http1xServerResponse \
    --initialize-at-run-time=io.vertx.core.http.impl.VertxHttp2ClientUpgradeCodec \
    --initialize-at-run-time=io.vertx.core.parsetools.impl.RecordParserImpl \
    --initialize-at-run-time=io.vertx.ext.auth.impl.jose.JWT \
    --initialize-at-run-time=io.vertx.ext.web.handler.sockjs.impl.XhrTransport \
    --initialize-at-run-time=java.rmi \
    --initialize-at-run-time=sun.rmi \
    --initialize-at-run-time=org.jboss.threads.JDKSpecific\$ThreadAccess \
    --initialize-at-run-time=org.jboss.logmanager.handlers.ConsoleHandler\$ConsoleHolder \
    --initialize-at-run-time=org.jboss.logmanager.handlers.SyslogHandler \
    --initialize-at-run-time=jdk.jpackage.internal.LinuxPackageArch\$DebPackageArch \
    --initialize-at-run-time=jdk.jpackage.internal.LinuxPackageArch\$RpmPackageArch \
    --initialize-at-run-time=jdk.tools.jlink.internal.plugins \
    --features=io.quarkus.runner.Feature \
    -H:LayerUse=target/libnettybaselayer.nil \
    -H:LinkerRPath=. \
    -J-Djava.util.logging.manager=org.jboss.logmanager.LogManager -J-Dsun.nio.ch.maxUpdateArraySize=100 -J-Dvertx.logger-delegate-factory-class-name=io.quarkus.vertx.core.runtime.VertxLogDelegateFactory -J-Dvertx.disableDnsResolver=true -J-Dio.netty.tryReflectionSetAccessible=true -J-Dio.netty.noUnsafe=false -J-Dio.netty.leakDetection.level=DISABLED -J-Dio.netty.allocator.maxOrder=3 -J-Duser.language=en -J-Duser.country=GB -H:+UnlockExperimentalVMOptions -H:IncludeLocales=en-GB -H:-UnlockExperimentalVMOptions --enable-native-access=ALL-UNNAMED -J-Dfile.encoding=UTF-8 -J--add-exports=org.graalvm.nativeimage.builder/com.oracle.svm.core.jdk=ALL-UNNAMED --features=io.quarkus.runner.Feature,io.quarkus.runtime.graal.DisableLoggingFeature,io.quarkus.runtime.graal.JVMChecksFeature,io.quarkus.runtime.graal.SkipConsoleServiceProvidersFeature -J--add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED -J--add-exports=java.security.jgss/sun.security.jgss=ALL-UNNAMED -J--add-opens=java.base/java.text=ALL-UNNAMED -J--add-opens=java.base/java.io=ALL-UNNAMED -J--add-opens=java.base/java.lang.invoke=ALL-UNNAMED -J--add-opens=java.base/java.util=ALL-UNNAMED -H:+UnlockExperimentalVMOptions \
    -H:BuildOutputJSONFile=target/build-output-layer-app.json \
    -H:-UnlockExperimentalVMOptions -H:+UnlockExperimentalVMOptions -H:+GenerateBuildArtifactsFile -H:-UnlockExperimentalVMOptions -H:+UnlockExperimentalVMOptions -H:+AllowFoldMethods -H:-UnlockExperimentalVMOptions -J-Djava.awt.headless=true --no-fallback -H:+UnlockExperimentalVMOptions -H:+ReportExceptionStackTraces -H:-UnlockExperimentalVMOptions -J-Xmx6g -H:-AddAllCharsets --enable-url-protocols=http -H:NativeLinkerOption=-no-pie -H:+UnlockExperimentalVMOptions -H:-UseServiceLoaderFeature -H:-UnlockExperimentalVMOptions -J--add-exports=org.graalvm.nativeimage/org.graalvm.nativeimage.impl=ALL-UNNAMED --exclude-config io\.netty\.netty-codec /META-INF/native-image/io\.netty/netty-codec/generated/handlers/reflect-config\.json --exclude-config io\.netty\.netty-handler /META-INF/native-image/io\.netty/netty-handler/generated/handlers/reflect-config\.json \
    -jar ${source_jar_dir}/getting-started-1.0.0-SNAPSHOT-runner.jar \
    -o getting-started-1.0.0-SNAPSHOT-runner \
    -H:Path=./target

echo "=== Testing layered native image ==="
LD_LIBRARY_PATH=target target/getting-started-1.0.0-SNAPSHOT-runner &
APP_PID=$!
sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/hello)
BODY=$(curl -s http://localhost:8080/hello)
kill $APP_PID 2>/dev/null; wait $APP_PID 2>/dev/null || true
echo "HTTP ${HTTP_CODE}: ${BODY}"
if [ "$HTTP_CODE" = "200" ] && [ "$BODY" = "hello" ]; then
    echo "SUCCESS"
else
    echo "FAILURE"
    exit 1
fi
