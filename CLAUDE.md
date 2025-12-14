# MailerLog Engine Development Guidelines

Code standards and preferences for MailerLog engine development.

This file should be read on context reload. It's added to the working directories list.

---

## Libraries and Dependencies

### Preferred Libraries
- **Filtering/Scoping:** Use `has_scope` gem with `prepend HasScope` in controllers that inherit from AdminsController (to override ScopieRails)
- **Pagination:** Use Kaminari with custom pagination template (because isolated engine routes don't work with Kaminari's default paginator)
- **Testing:** Use FactoryBot (not Cranky which is used in the main app)

### Avoid
- ScopieRails - we're migrating away from it in other projects
- Adding unnecessary dependencies

---

## Testing Approach

### Test Types
- **Request specs** are preferred over controller specs
- Unit specs only for complex isolated logic (interceptor, observer)

### FactoryBot Usage
- Use `create(:factory_name)` for database records
- Use traits for common variations (`:delivered`, `:bounced`, etc.)
- Factories are in `spec/factories/`

### Spec Structure
```ruby
describe 'GET #index' do
  def do_request(params = {})
    get '/path', params: params
  end

  it 'returns successful response' do
    do_request
    expect(response).to have_http_status(:ok)
  end
end
```

### Spec Location
- Engine specs live in `engines/mailer_log/spec/`
- Require `spec_helper` which loads main app's `rails_helper`

---

## Views and Styling

### General Rules
- **No inline styles** - use CSS classes
- **No `<style>` blocks** in ERB files
- **Use Bootstrap utility classes** before creating custom ones
- **Use Font Awesome** for icons (not MDI)

### CSS Classes and Variables
- Check existing Bootstrap utilities first
- Check main app's SCSS files (`variables.scss`, `typography.scss`, etc.)
- Use `rem()` function for sizes (except 1px, 2px)
- Use color variables instead of hex codes

### Engine Route Helpers
Use `mailer_log_engine.path_name` for engine routes:
```erb
<%= link_to 'Back', mailer_log_engine.admin_emails_path %>
```

---

## Controller Patterns

### Inheritance
Engine controllers inherit from `MailerLog::AdminController`, NOT `::AdminsController`:
```ruby
class EmailsController < MailerLog::AdminController
  has_scope :recipient
  has_scope :by_status, as: :status
end
```

### Filtering with has_scope
```ruby
has_scope :scope_name                  # uses param :scope_name
has_scope :by_status, as: :status      # uses param :status
```

---

## Language

- **English only** for all documentation, comments, and commit messages
- Code and variable names in English
