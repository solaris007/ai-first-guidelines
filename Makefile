# AI-First Guidelines - Build System
# Builds documentation site (MkDocs) and presentations (Marp)

.PHONY: help install serve build clean presentations docs deploy

# Default target
help:
	@echo "AI-First Guidelines Build System"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  install        Install dependencies (mkdocs, marp)"
	@echo "  serve          Start local dev server (docs + presentations)"
	@echo "  build          Build site for production"
	@echo "  deploy         Build and deploy to GitHub Pages"
	@echo "  clean          Remove build artifacts"
	@echo ""
	@echo "Individual targets:"
	@echo "  docs           Build/serve docs only"
	@echo "  presentations  Build presentations to HTML"
	@echo ""
	@echo "First time? Run: make install"

# Install dependencies
install:
	@echo "Installing MkDocs and plugins..."
	pip install mkdocs-material
	@echo ""
	@echo "Marp CLI will be downloaded automatically via npx on first build."
	@echo ""
	@echo "Done! Run 'make serve' to start the dev server."

# Start development server
serve:
	@echo "Building presentations first..."
	$(MAKE) presentations
	@echo ""
	@echo "Starting MkDocs dev server..."
	@echo "View at: http://127.0.0.1:8000"
	@echo "Presentations at: http://127.0.0.1:8000/presentations/"
	@echo ""
	mkdocs serve

# Build for production
build:
	@echo "Building documentation site..."
	mkdocs build
	@echo ""
	$(MAKE) presentations
	@echo "Site built to ./site/"

# Build presentations to HTML
presentations:
	@echo "Building presentations..."
	@mkdir -p site/presentations
	npx @marp-team/marp-cli --theme docs/presentations/theme-adobe.css docs/presentations/intro.md -o site/presentations/intro.html
	npx @marp-team/marp-cli --theme docs/presentations/theme-adobe.css docs/presentations/getting-started.md -o site/presentations/getting-started.html
	@echo "Presentations built to site/presentations/"

# Build docs only (no presentations)
docs:
	mkdocs serve

# Deploy to GitHub Pages (gh-pages branch)
deploy: build
	@echo "Deploying to GitHub Pages..."
	ghp-import -n -p -f site
	@echo "Deployed! Site will be available at:"
	@echo "https://adobe.github.io/ai-first-guidelines/"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf site/
	@echo "Done."
