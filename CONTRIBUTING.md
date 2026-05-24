# Contributing to MbewuSmart

Thank you for your interest in contributing. This document explains how to get set up and how we prefer to work.

---

## Development environment

**Required:**
- Flutter SDK ≥ 3.10.8 — [install guide](https://docs.flutter.dev/get-started/install)
- Android Studio (Hedgehog or later) with the Flutter and Dart plugins
- A physical Android device or an AVD (API level 21+)

**Setup:**
```bash
git clone https://github.com/Zaichikuse/mbewusmart.git
cd mbewusmart
flutter pub get

# Create a .env file at the project root (never commit this file)
cp .env.example .env
# Fill in GEMINI_API_KEY and GOOGLE_API_KEY

flutter run
```

**Firebase:** The `google-services.json` file is not in the repository. Request it from the maintainer or connect your own Firebase project for development.

---

## Code style

- Follow the official [Dart style guide](https://dart.dev/effective-dart/style).
- Run `flutter analyze` before pushing — fix all errors and warnings introduced by your changes.
- Format with `dart format .` before committing.
- Architecture follows **Clean Architecture** with **BLoC** for state management. New features should fit the existing layer structure (`domain → data → presentation`).
- Keep business logic out of widgets.

---

## Branch naming

| Type | Pattern | Example |
|------|---------|---------|
| New feature | `feature/short-description` | `feature/rice-crop-support` |
| Bug fix | `fix/short-description` | `fix/offline-history-crash` |
| Documentation | `docs/short-description` | `docs/update-readme` |
| Refactor | `refactor/short-description` | `refactor/auth-bloc-cleanup` |

Branch off `main`. Keep branches focused — one concern per branch.

---

## Commit messages

Use the **Conventional Commits** format:

```
<type>(<scope>): <short summary in imperative mood>

[optional body — explain WHY, not what]
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

**Examples:**
```
feat(scan): add cassava disease detection support
fix(home): prevent banner from re-appearing after dismissal
docs(readme): add installation section for developers
```

- Keep the subject line under 72 characters.
- Use the body to explain motivation, not mechanics.

---

## Submitting a pull request

1. Create a branch from `main` using the naming convention above.
2. Make your changes. Run `flutter analyze` and `flutter test` — both must pass.
3. Push your branch and open a PR against `main`.
4. Fill in the PR template: what changed, why, and how to test it.
5. A maintainer will review within a few days. Address feedback in new commits (do not force-push after review has started).

**Keep PRs small.** A PR that touches one feature or fixes one bug is far easier to review than one that does ten things at once.

---

## Security-sensitive changes

PRs that touch any of the following require explicit sign-off from the maintainer before merge:

- `lib/core/services/` — encryption, key management, anonymisation
- `firestore.rules` — database access rules
- `lib/features/auth/` — authentication flows
- Any change that affects how NID numbers or personal data are stored or transmitted

If you find a security vulnerability, **do not open a public issue**. Email zaichikuse@gmail.com with details. We will coordinate a fix before any public disclosure.

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
