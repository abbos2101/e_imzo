format: ## Format code
	@echo "Formatting code..."
	@dart format .

fix: ## Apply automated fixes
	@echo "Applying automated fixes..."
	@dart fix --apply
	@dart format .

publish: ## Publish package to pub.dev
	@echo "Publishing package..."
	@dart pub publish