# Quarkus Template Project - Setup History

This document records every step taken to create this Quarkus template project, including the exact commands, what they do, and how to verify each step succeeded.

---

## Step 1: Verify Prerequisites

### Check Quarkus CLI

```bash
quarkus --version
```

**What it does:** Confirms that the Quarkus CLI is installed and prints its version. The Quarkus CLI (`quarkus`) is a command-line tool that simplifies creating, building, and running Quarkus projects. Think of it like `mvn archetype:generate` but purpose-built for Quarkus with live-reload support.

**Output:**
```
3.34.3
```

**If not installed:** Install via Homebrew on macOS:
```bash
brew install quarkusio/tap/quarkus
```
Or via SDKMAN (cross-platform):
```bash
sdk install quarkus
```

### Check Java Version

```bash
java -version
```

**What it does:** Confirms Java is installed and the version meets the project requirement (Java 21). Quarkus requires at least Java 17, but this template targets Java 21 for access to the latest language features (record patterns, virtual threads, etc.).

**Output:**
```
openjdk version "21.0.10" 2026-01-20 LTS
OpenJDK Runtime Environment Temurin-21.0.10+7 (build 21.0.10+7-LTS)
```

---

## Step 2: Create the Quarkus Project

```bash
quarkus create app dev.tedwon:quarkus-agentic-dev-playbook \
  --java=21 \
  --extensions="resteasy-reactive,smallrye-health"
```

**What it does:** Scaffolds a new Quarkus project with the following settings:

| Parameter | Value | Purpose |
|---|---|---|
| `dev.tedwon:quarkus-agentic-dev-playbook` | GAV coordinates | Sets groupId to `dev.tedwon` and artifactId to `quarkus-agentic-dev-playbook`. These are Maven coordinates that uniquely identify your project. |
| `--java=21` | Java version | Configures the project to compile with Java 21. |
| `--extensions=...` | Quarkus extensions | Adds specific functionality to the project (see below). |

**Extensions explained:**

- **`resteasy-reactive`** (maps to `quarkus-rest`): Provides JAX-RS REST endpoint support using Quarkus's reactive REST implementation. This is the foundation for building REST APIs. It generates a sample `GreetingResource.java` with a `GET /hello` endpoint.
- **`smallrye-health`** (maps to `quarkus-smallrye-health`): Adds MicroProfile Health endpoints at `/q/health`, `/q/health/live`, and `/q/health/ready`. These are essential for Kubernetes liveness/readiness probes and monitoring.

**Output (key lines):**
```
applying codestarts...
  java
  maven
  quarkus
  config-properties
  tooling-dockerfiles
  tooling-maven-wrapper
  rest-codestart
  smallrye-health-codestart

[SUCCESS] quarkus project has been successfully generated in:
--> /path/to/quarkus-agentic-dev-playbook
```

**What got generated:**

```
quarkus-agentic-dev-playbook/
  pom.xml                                          # Maven build file with Quarkus BOM and extensions
  mvnw / mvnw.cmd                                  # Maven wrapper (no global Maven install needed)
  src/main/java/dev/tedwon/
    GreetingResource.java                           # Sample REST endpoint (GET /hello)
    MyLivenessCheck.java                            # Sample health check (liveness probe)
  src/main/resources/
    application.properties                          # Quarkus configuration (empty by default)
  src/main/docker/
    Dockerfile.jvm                                  # Dockerfile for JVM mode
    Dockerfile.native                               # Dockerfile for native compilation
    Dockerfile.native-micro                         # Dockerfile for minimal native image
    Dockerfile.legacy-jar                           # Dockerfile for legacy JAR packaging
  src/test/java/dev/tedwon/
    GreetingResourceTest.java                       # Unit test for the REST endpoint
    GreetingResourceIT.java                         # Integration test (runs against native image)
```

---

## Step 3: Build and Verify

```bash
cd quarkus-agentic-dev-playbook
./mvnw verify
```

**What it does:** Compiles the project, runs unit tests, and packages it into a runnable JAR. The `verify` goal runs the full build lifecycle including the `test` phase. The `./mvnw` script is the Maven Wrapper — it downloads and uses the correct Maven version automatically, so you don't need Maven installed globally.

**Key output (success indicator):**
```
[INFO] BUILD SUCCESS
```

**What happens during the build:**
1. **Compile** — Java sources are compiled with the Java 21 compiler
2. **Test** — `GreetingResourceTest` runs (starts a Quarkus instance, calls `GET /hello`, asserts the response)
3. **Package** — Creates `target/quarkus-app/quarkus-run.jar` (the runnable application)
4. **Quarkus Augmentation** — Quarkus does build-time optimization (moves work from runtime to build time for faster startup)

---

## Step 4: Smoke Test with Dev Mode

```bash
quarkus dev
```
or equivalently:
```bash
./mvnw quarkus:dev
```

**What it does:** Starts the application in **dev mode** — a live-reload development environment. Changes to Java files, configuration, or resources are automatically detected and hot-reloaded without restarting.

**Key output:**
```
quarkus-agentic-dev-playbook 1.0.0-SNAPSHOT on JVM (powered by Quarkus 3.34.3) started in 1.300s. Listening on: http://localhost:8080
```

### Verify Endpoints

**REST endpoint:**
```bash
curl http://localhost:8080/hello
```
Response: `Hello from Quarkus REST`

**Health check (all):**
```bash
curl http://localhost:8080/q/health
```
Response:
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "alive",
      "status": "UP"
    }
  ]
}
```

**Liveness probe:**
```bash
curl http://localhost:8080/q/health/live
```
Response:
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "alive",
      "status": "UP"
    }
  ]
}
```

**Stop dev mode:** Press `Ctrl+C` in the terminal, or `q` then `Enter`.

---

## Project Summary

| Item | Value |
|---|---|
| Quarkus Version | 3.34.3 |
| Java Version | 21 |
| Build Tool | Maven (via wrapper) |
| Group ID | dev.tedwon |
| Artifact ID | quarkus-agentic-dev-playbook |
| Extensions | `quarkus-rest`, `quarkus-smallrye-health`, `quarkus-arc` |
| REST Endpoint | `GET /hello` |
| Health Endpoints | `/q/health`, `/q/health/live`, `/q/health/ready` |
| Dev UI | `http://localhost:8080/q/dev-ui` (dev mode only) |

---

## Next Steps: Copying and Extending This Template

### 1. Copy the Template

```bash
cp -r quarkus-agentic-dev-playbook my-new-service
cd my-new-service
```

Then update the `artifactId` in `pom.xml` to match your new project name:
```xml
<artifactId>my-new-service</artifactId>
```

### 2. Add New Extensions

Use the Quarkus CLI to add extensions without editing `pom.xml` manually:

```bash
# Database support (PostgreSQL + Hibernate ORM with Panache)
quarkus ext add quarkus-hibernate-orm-panache quarkus-jdbc-postgresql

# JSON serialization for REST endpoints
quarkus ext add quarkus-rest-jackson

# OpenAPI / Swagger UI
quarkus ext add quarkus-smallrye-openapi

# List all available extensions
quarkus ext list
```

### 3. Create New REST Endpoints

Add a new Java class under `src/main/java/dev/tedwon/`:

```java
package dev.tedwon;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/items")
public class ItemResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Item> listAll() {
        // your logic here
    }
}
```

### 4. Configure the Application

Edit `src/main/resources/application.properties`:

```properties
# Change the HTTP port
quarkus.http.port=8080

# Database connection (after adding JDBC extension)
quarkus.datasource.db-kind=postgresql
quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/mydb

# Enable CORS
quarkus.http.cors=true
```

### 5. Useful Dev Commands

```bash
quarkus dev                  # Start in dev mode (hot-reload)
./mvnw verify                # Build + run tests
./mvnw quarkus:test          # Run tests only
quarkus ext list --installed # Show installed extensions
quarkus build                # Build the application
```
