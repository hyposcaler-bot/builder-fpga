
DEBIAN_SOURCE_DIR := debian


.PHONY: init-debian
init-debian:
	packer init $(DEBIAN_SOURCE_DIR)

.PHONY: init
init: init-debian

.PHONY: validate-debian
validate-debian:
	packer validate $(DEBIAN_SOURCE_DIR)/

.PHONY: validate
validate: validate-debian

.PHONY: build-debian-x86_64
build-debian-x86_64:
	PACKER_LOG=1 packer build -var-file=$(DEBIAN_SOURCE_DIR)/debian-12-bios-x86_64.pkrvars.hcl $(DEBIAN_SOURCE_DIR)/debian.pkr.hcl

.PHONY: build-debian
build: build-debian-x86_64

.PHONY: clean

clean:
	rm -rf build/boot-*/
	rm -rf build/output-*/
