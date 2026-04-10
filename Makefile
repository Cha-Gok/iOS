.PHONY: format test generate

format:
	swiftformat --config .swiftformat .

generate:
	tuist generate

test: format
	tuist test
