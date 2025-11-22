# VitalForge Documentation

This directory contains supplementary documentation and visual assets for the VitalForge project.

## Documentation Structure

### Root-Level Documentation
Located in the project root for easy access:

- **[README.md](../README.md)** - Project overview, setup instructions, and quick start guide
- **[DATABASE_SCHEMA.md](../DATABASE_SCHEMA.md)** - Complete database schema with ERD diagrams
- **[API_DOCUMENTATION.md](../API_DOCUMENTATION.md)** - API endpoints, request/response formats
- **[DEVELOPMENT.md](../DEVELOPMENT.md)** - Development workflow and best practices
- **[MIGRATIONS_GUIDE.md](../MIGRATIONS_GUIDE.md)** - Database migration patterns and examples
- **[STYLING_UPDATE.md](../STYLING_UPDATE.md)** - Design system and color palette
- **[DOCUMENTATION_SUMMARY.md](../DOCUMENTATION_SUMMARY.md)** - Index of all documentation

### Visual Assets

#### `/docs/diagrams/`
Visual diagrams and architectural documentation:

- **Entity Relationship Diagrams (ERD)** - Database schema visualizations
- **Architecture Diagrams** - System architecture and component relationships
- **Flow Charts** - User flows and business logic processes

**Supported Formats:**
- `.png` - For embedding in documentation
- `.svg` - Vector format for scalability
- `.pdf` - For printing or sharing

**Tools for Generating Diagrams:**
- **rails-erd** - Automatic ERD generation from Rails models
- **dbdiagram.io** - Web-based database diagram tool
- **Draw.io / Lucidchart** - Manual diagram creation
- **Mermaid** - Text-based diagrams (embedded in markdown)

## Creating Visual ERDs

### Option 1: Using rails-erd (Automatic)

```bash
# Add to Gemfile (development group)
gem 'rails-erd', group: :development

# Generate ERD
bundle exec erd --filename=docs/diagrams/erd

# This creates: docs/diagrams/erd.pdf
```

### Option 2: Using dbdiagram.io (Web-based)

1. Visit https://dbdiagram.io
2. Define schema in DBML format
3. Export as PNG/PDF/SVG
4. Save to `docs/diagrams/erd.png`

### Option 3: Manual with Draw.io

1. Visit https://app.diagrams.net
2. Create custom ERD diagram
3. Export as PNG or SVG
4. Save to `docs/diagrams/`

### Option 4: Mermaid (In Markdown)

Mermaid diagrams are already embedded in `DATABASE_SCHEMA.md` and render automatically on GitHub!

## Using Diagrams in Documentation

### In Markdown Files

```markdown
## Database Schema

![ERD Diagram](./docs/diagrams/erd.png)

*Entity Relationship Diagram showing VitalForge database structure*
```

### In README

```markdown
## Architecture

For a visual representation of the database schema:

- [View ERD Diagram](./docs/diagrams/erd.png)
- [View Full Schema Documentation](./DATABASE_SCHEMA.md)
```

## Documentation Best Practices

### Keep Documentation Updated
- Update docs when making schema changes
- Regenerate diagrams after major migrations
- Document WHY, not just WHAT

### Version Control
- Commit all documentation to git
- Use meaningful commit messages: "docs: add exercise_sets table to ERD"
- Review docs in pull requests

### Accessibility
- Use alt text for images
- Provide text descriptions alongside diagrams
- Ensure diagrams are readable (high contrast, clear labels)

### Organization
- Keep related docs together
- Use consistent naming conventions
- Link between related documentation

## Generating Documentation Files

### Database Schema
Already available in `DATABASE_SCHEMA.md` with embedded Mermaid diagrams.

### API Documentation
Use Swagger/OpenAPI (already configured with rswag):
```bash
# Generate Swagger docs
rails rswag:specs:swaggerize

# View at: http://localhost:3000/api-docs
```

### Code Documentation (Future)
Consider adding YARD for Ruby code documentation:
```bash
gem 'yard'
yard doc
yard server
```

## Future Documentation Plans

- [ ] Add architecture diagram showing Rails + React integration
- [ ] Create user flow diagrams for key features
- [ ] Add deployment architecture diagram
- [ ] Create visual style guide
- [ ] Add security architecture documentation

## Contributing to Documentation

When adding new documentation:

1. **Choose the right location:**
   - Root-level: User-facing guides, setup, API
   - `/docs/`: Visual assets, supplementary materials

2. **Follow naming conventions:**
   - Use SCREAMING_SNAKE_CASE.md for root docs
   - Use kebab-case.png for diagrams
   - Be descriptive: `user-authentication-flow.png`

3. **Update this README:**
   - Add links to new documentation
   - Explain purpose and usage

4. **Link from main README:**
   - Add prominent links to important docs
   - Keep main README as entry point

## Questions?

For questions about documentation:
- Check [DEVELOPMENT.md](../DEVELOPMENT.md) for development workflow
- See [DATABASE_SCHEMA.md](../DATABASE_SCHEMA.md) for database questions
- Refer to [API_DOCUMENTATION.md](../API_DOCUMENTATION.md) for API usage

---

**Last Updated:** 2025-10-28  
**Maintained By:** VitalForge Development Team

