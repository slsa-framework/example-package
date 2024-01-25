module slsa-framework/example-package

// NOTE: Keep in sync with Dockerfile and WORKSPACE:go_register_toolchains
go 1.21

require github.com/pborman/uuid v1.2.1

require github.com/google/uuid v1.6.0 // indirect
