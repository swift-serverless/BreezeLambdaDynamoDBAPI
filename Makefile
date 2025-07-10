SWIFT_BIN_PATH = $(shell swift build --show-bin-path)
TEST_PACKAGE= $(SWIFT_BIN_PATH)/BreezeLambdaDynamoDBAPIPackageTests.xctest
BUILD_TEMP = .build/temp

linux_test:
	docker-compose -f docker/docker-compose.yml run --rm test

linux_shell:
	docker-compose -f docker/docker-compose.yml run --rm shell

build_no_cache:
	docker-compose -f docker/docker-compose.yml build --no-cache

composer_up:
	docker-compose -f docker/docker-compose.yml up

composer_down:
	docker-compose -f docker/docker-compose.yml down

localstack:
	docker run -it --rm -p "4566:4566" localstack/localstack

local_setup_dynamo_db:
	aws --endpoint-url=http://localhost:4566 dynamodb create-table \
		--table-name Breeze \
		--attribute-definitions AttributeName=itemKey,AttributeType=S \
		--key-schema AttributeName=itemKey,KeyType=HASH \
		--billing-mode PAY_PER_REQUEST
		--region us-east-1

local_invoke_demo_app:
	curl -X POST 127.0.0.1:7000/invoke -H "Content-Type: application/json" -d @Tests/BreezeLambdaAPITests/Fixtures/post_products_api_gtw.json

test:
	swift test --sanitize=thread --enable-code-coverage

coverage:
	llvm-cov export $(TEST_PACKAGE) \
		--instr-profile=$(SWIFT_BIN_PATH)/codecov/default.profdata \
		--format=lcov > $(GITHUB_WORKSPACE)/lcov.info
