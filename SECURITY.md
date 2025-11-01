# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.2.x   | :white_check_mark: |
| < 1.2   | :x:                |

## Reporting a Vulnerability

Please report (suspected) security vulnerabilities to **security@nandogami.com** or create a private security advisory on GitHub. You will receive a response within 48 hours. If the issue is confirmed, we will release a patch as soon as possible depending on complexity but historically within a few days.

Please include the following information:
- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- The location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue

## Security Best Practices

When reporting vulnerabilities, please:
- Do not open public issues for security vulnerabilities
- Allow time for the maintainers to respond before public disclosure
- Provide detailed information to help us understand and reproduce the issue

## Known Security Considerations

- API keys should never be committed to the repository
- User authentication is handled via Firebase Auth
- All user data is protected by Firestore Security Rules
- Images are stored securely in Firebase Storage with proper access controls

Thank you for helping keep Coment and our users safe!

