# Documentation Rules

## Security and Sensitive Information

### NEVER Include Sensitive Data in Documentation

When creating or updating documentation, guides, or README files:

**❌ DO NOT include:**
- Passwords (database, API, admin, etc.)
- API keys or tokens
- Secret keys or encryption keys
- Private credentials of any kind
- Email addresses (unless generic examples)
- Personal information
- Internal URLs or endpoints that expose sensitive data

**✅ DO use instead:**
- Placeholders: `your_password_here`, `your_api_key_here`
- Environment variable references: `${DATABASE_PASSWORD}`, `$OPENAI_API_KEY`
- Generic examples: `admin@example.com`, `user@domain.com`
- Instructions to reference `.env` file: "use password from your .env file"
- Descriptive labels: `[your-database-password]`, `<API_KEY>`

### Examples

**BAD:**
```yaml
POSTGRES_PASSWORD=IFarted88!!
OPENAI_API_KEY=sk-proj-abc123xyz...
```

**GOOD:**
```yaml
POSTGRES_PASSWORD=${DATABASE_PASSWORD}
OPENAI_API_KEY=${OPENAI_API_KEY}
```

**GOOD:**
```yaml
POSTGRES_PASSWORD=your_secure_password_here
OPENAI_API_KEY=your_openai_key_here
```

**GOOD:**
```markdown
Use the database password from your `.env` file.
```

## Documentation Best Practices

### Structure

1. **Start with clear purpose** - What is this guide for?
2. **Prerequisites section** - What needs to be installed/configured first?
3. **Step-by-step instructions** - Numbered, clear, actionable
4. **Troubleshooting section** - Common issues and solutions
5. **Quick reference** - Command cheatsheet at the end

### Writing Style

- Use clear, concise language
- Break down complex tasks into small steps
- Include expected output for verification
- Provide context for why commands are needed
- Add warnings for destructive operations
- Include links to related documentation

### Code Examples

- Always test commands before documenting
- Show full command with all necessary flags
- Include expected output when helpful
- Comment complex or non-obvious parts
- Use syntax highlighting with language tags

### Maintenance

- Keep documentation up to date with code changes
- Review documentation when dependencies change
- Archive outdated guides rather than deleting
- Add "Last updated" dates for time-sensitive content
- Link to official docs for external tools/libraries

## File Organization

```
documentation/
├── README.md                    # Documentation index
├── SETUP_GUIDE.md              # Complete project setup
├── API_DOCUMENTATION_GUIDE.md  # API documentation with Rswag
├── DOCKER_SETUP_MAC.md         # Docker setup for macOS
├── DEPLOYMENT.md               # Deployment instructions
└── [feature-specific].md       # Feature documentation
```

## Checklist Before Committing Documentation

- [ ] No passwords, API keys, or secrets included
- [ ] All sensitive data replaced with placeholders
- [ ] Commands tested and working
- [ ] Links are valid and accessible
- [ ] Code examples have proper syntax highlighting
- [ ] Includes troubleshooting section
- [ ] References to `.env` or environment variables where needed
- [ ] Clear section headings and table of contents
- [ ] Proper formatting (lists, code blocks, tables)
- [ ] Spell-checked and grammar-checked

## Related Files

- `.gitignore` - Ensure sensitive files are ignored
- `.env.example` - Template for environment variables
- `README.md` - Main project documentation
