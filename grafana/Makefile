# Details from https://grafana.com/grafana/download
GRAFANA_INSTALL = true
GRAFANA_VERSION = 7.5.11
GRAFANA_MACOS_SHA256 = efd1f27e1f66508ea7bef228786fae3629a32b50e565d0fc5dac616c4e0d9c20
GRAFANA_LINUX_SHA256 = 3244d0ced48d2de9726c9a3bd6d5f08c1b6a081d42665401e033fc4a31c57d5d

# Determine host operating system
ifeq ($(shell uname -s), Darwin)
	OS = darwin
	GRAFANA_SHA256 = ${GRAFANA_MACOS_SHA256}
else ifeq ($(shell uname -s), Linux)
	OS = linux
	GRAFANA_SHA256 = ${GRAFANA_LINUX_SHA256}
else
	GRAFANA_INSTALL = false
endif

.PHONY: all
all: grafana grafana-dashboards

ifeq ($(GRAFANA_INSTALL),true)
grafana:
	@curl -L --fail https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz -o grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
	@echo "${GRAFANA_SHA256}  grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz" | shasum -a 256 -c -
	@tar -zxf grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
	@mv grafana-${GRAFANA_VERSION} grafana
else
grafana:
	@echo "ERROR: Unsupported platform."
endif

ifeq ($(GRAFANA_INSTALL),true)
grafana-dashboards:
	@git clone https://github.com/khulnasoft/grafana-dashboards.git
else
grafana-dashboards:
	@echo "ERROR: Unsupported platform."
endif

.PHONY: test
test:
	@true

.PHONY: clean
clean:
	@rm -rf grafana grafana-dashboards grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
