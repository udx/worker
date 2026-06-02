## Summary

Updates Dockerfile dependency pins using an unpinned probe build and Copilot CLI.

## Evidence

- Probe report artifact: `docker-dependency-report.json`
- Copilot session artifact: `copilot-docker-dependency-session.md`
- Validation: `docker build --progress=plain -t dependency-update-validation .`

## Diff

```diff
diff --git a/Dockerfile b/Dockerfile
index 6f47365..aed3e0b 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -4,10 +4,10 @@ FROM ubuntu:25.10
 # Set the maintainer of the image
 LABEL maintainer="UDX CAG Team"
 
-ARG AZURE_CLI_VERSION=2.85.0
-ARG PIP_VERSION=26.0.1
+ARG AZURE_CLI_VERSION=2.87.0
+ARG PIP_VERSION=26.1.2
 ARG YQ_VERSION=4.53.2
-ARG GCLOUD_VERSION=565.0.0
+ARG GCLOUD_VERSION=570.0.0
 
 # Set base environment variables
 ENV DEBIAN_FRONTEND=noninteractive \
@@ -43,18 +43,18 @@ USER root
 RUN apt-get update && \
     apt-get install -y --no-install-recommends \
     tzdata=2026a-0ubuntu0.25.10.1  \
-    curl=8.14.1-2ubuntu1.2  \
+    curl=8.14.1-2ubuntu1.3  \
     bash=5.2.37-2ubuntu5  \
     apt-utils=3.1.6ubuntu2 \
     gettext=0.23.1-2build2 \
     gnupg2=2.4.8-2ubuntu2.1 \
     ca-certificates=20250419 \
     lsb-release=12.1-1 \
-    jq=1.8.1-3ubuntu1 \
+    jq=1.8.1-3ubuntu1.1 \
     zip=3.0-15ubuntu2 \
     unzip=6.0-28ubuntu7 \
     nano=8.4-1 \
-    vim=2:9.1.0967-1ubuntu6.2 \
+    vim=2:9.1.0967-1ubuntu6.5 \
     python3.13=3.13.7-1ubuntu0.4 \
     python3.13-venv=3.13.7-1ubuntu0.4 \
     supervisor=4.2.5-3 && \
```
