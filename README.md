# WrongMethodTypeException with MethodHandle.invokeExact() in layered native images

## Summary

Building a Quarkus application as a layered native image (with `io.netty.*` in the
base layer) results in a `WrongMethodTypeException` at runtime:

```
WrongMethodTypeException: handle's method type (ConfigMappingContext)Object
but found (ConfigMappingContext)Object
  at java.lang.invoke.Invokers.checkExactType(Invokers.java:531)
  at io.smallrye.config.ConfigMappingLoader.configMappingObject(ConfigMappingLoader.java:114)
```

The two `MethodType` objects are logically equal (same parameter and return types)
but physically different (reference inequality `!=`).

The same code works correctly in a non-layered native image.

## Root Cause

`invokeExact()` requires that the `MethodHandle`'s `type()` is reference-equal
(`==`) to the expected `MethodType` at the call site. This relies on `MethodType`
interning: `MethodType.methodType()` returns interned objects so that equal types
are the same object.

In a layered native image build:

1. **Base layer build**: `ConfigMappingLoader.configMappingObject()` is compiled.
   The `invokeExact` call site embeds a `MethodType` constant `(ConfigMappingContext)Object`.
   The `MethodHandleFeature` replaces `MethodType.internTable` with a new
   `runtimeMethodTypeInternTable`, but the base layer registers **0** MethodType
   objects in this table (verified with `-J-Dsvm.traceMethodTypeInterning=true`).

2. **App layer build**: The `MethodHandleFeature` creates another new
   `runtimeMethodTypeInternTable` with app-layer MethodType objects. This table
   replaces the base layer's table.

3. **Runtime**: `ConfigMappingLoader$ConfigMappingImplementation.constructor()`
   calls `MethodType.methodType(void.class, ConfigMappingContext.class)` which
   goes through the interning table and returns `MT_app`. But the `invokeExact`
   call site's expected type is `MT_base` (from the base layer's compiled code).
   Since `MT_base != MT_app` (different objects), `checkExactType` fails.

**Note**: There is only a single classloader at runtime. `ConfigMappingContext.class`
is the same `DynamicHub` object everywhere. The issue is purely about `MethodType`
object identity — the MethodType interning table doesn't include all MethodType
constants from compiled code.

## Reproducer

### Prerequisites

- Quarkus 999-SNAPSHOT built locally (`mvnw install -DskipTests -Dquickly`)
- GraalVM CE or Mandrel with native image layer support

### Steps

```bash
# 1. Build the Quarkus getting-started app (non-layered)
cd getting-started
./mvnw package -Dnative -DskipTests
cd ..

# 2. Run the layered build (this script)
export JAVA_HOME=/path/to/graalvm
reproducer-methodtype-interning/build.sh
```

### Expected

The layered native image starts and responds to `curl http://localhost:8080/hello`
with "hello" and HTTP 200.

### Actual

The application crashes at startup:

```
ERROR: Failed to start application
java.lang.RuntimeException: Failed to start quarkus
Caused by: java.lang.invoke.WrongMethodTypeException:
  handle's method type (ConfigMappingContext)Object
  but found (ConfigMappingContext)Object
  at java.lang.invoke.Invokers.checkExactType(Invokers.java:531)
  at io.smallrye.config.ConfigMappingLoader.configMappingObject(...)
  at io.smallrye.config.ConfigMappingContext.constructGroup(...)
  at io.smallrye.config.ConfigMappingContext.constructMapping(...)
  at io.smallrye.config.SmallRyeConfig.<init>(...)
  at io.quarkus.runtime.generated.Config.runtimeConfig(...)
```

### Notes on standalone reproducer

Attempts to create a minimal standalone reproducer (without Quarkus) using the
same `MethodHandle.invokeExact()` pattern did NOT trigger the bug. The exact
mechanism that causes the MethodType interning failure appears to require the
full Quarkus infrastructure:

- SmallRye `ConfigMappingLoader` with `ClassValue` caching
- Quarkus-generated `$$CMImpl` classes (bytecode-generated config mapping
  implementations in the runner jar)
- Quarkus build-time STATIC_INIT phase that populates the config mapping cache
- The interaction between `MethodHandleFeature`'s `runtimeMethodTypeInternTable`
  and the layer infrastructure

### Workaround

Replace `invokeExact()` with `invoke()` in `ConfigMappingLoader.configMappingObject()`.
The `invoke()` method does not require exact `MethodType` reference equality, avoiding
the interning issue at a small performance cost.

## Proposed Fix

The `MethodHandleFeature` should ensure that ALL `MethodType` objects in the image
heap (including constants embedded in compiled code) are present in the runtime
`MethodType` interning table. Currently, the base layer registers 0 MethodType
objects while the compiled code contains MethodType constants that aren't tracked.
