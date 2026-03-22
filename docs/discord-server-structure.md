# ClawBox Discord Server Structure

This document outlines the Discord server structure for the ClawBox community.

---

## Server Setup

**Server Name:** ClawBox Community

**Server Icon:** ClawBox logo (red lobster/crayfish)

**Invite URL:** https://discord.gg/XFpfPv9Uvx

---

## Channel Structure

### 📢 ANNOUNCEMENTS CATEGORY

**#announcements**
- Product updates and new releases
- Blog posts and articles
- Conference talks and media appearances
- Only admins can post

**#release-notes**
- GitHub release notifications (auto-posted via webhook)
- Changelog updates
- Breaking changes announcements

**#roadmap**
- Public roadmap updates
- Feature development progress
- Version milestones

---

### 💬 COMMUNITY CATEGORY

**#general**
- General discussion about ClawBox
- Introductions
- Off-topic conversations
- Community building

**#showcase**
- Share projects built with ClawBox
- Screenshots and demos
- Use case discussions

**#events**
- Community events
- Office hours
- AMAs with maintainers

---

### 🆘 SUPPORT CATEGORY

**#install-help**
- Installation problems
- Platform-specific issues
- Dependency conflicts

**#usage-questions**
- How-to questions
- Command usage
- Best practices

**#troubleshooting**
- Bug reports (for discussion before GitHub issue)
- Error messages
- Debug help

**#feature-requests**
- Discuss potential features
- User feedback
- Prioritization discussions

---

### 🔒 SECURITY CATEGORY

**#security-discussions**
- Security architecture discussions
- Threat modeling
- Best practices for secure AI usage

**#network-policies**
- Policy presets discussion
- Custom policy sharing
- Policy troubleshooting

**#security-advisories**
- Security vulnerabilities (disclosure process)
- Patch announcements
- CVE discussions

---

### 🛠️ DEVELOPMENT CATEGORY

**#contributing**
- How to contribute
- Code style guidelines
- Pull request process

**#development-chat**
- Development discussions
- Architecture decisions
- Code reviews

**#good-first-issues**
- Beginner-friendly issues
- Mentoring opportunities
- Getting started with contributions

---

### 📚 RESOURCES CATEGORY

**#tutorials**
- Community tutorials
- Video guides
- Learning resources

**#documentation**
- Documentation feedback
- Documentation contributions
- Wiki updates

**#integrations**
- Third-party integrations
- API usage
- Extensions and plugins

---

### 🌍 INTERNATIONAL CATEGORY

**#español**
- Spanish-speaking community

**#中文**
- Chinese-speaking community

**#日本語**
- Japanese-speaking community

---

## Roles

**@Admin**
- Server administrators
- Full moderation permissions

**@Maintainer**
- ClawBox maintainers
- Can manage channels and moderate

**@Contributor**
- Active code contributors
- Special badge for contributions

**@Verified**
- Users who have verified their account
- Basic access to all channels

**@New Member**
- New users (first 24 hours)
- Limited posting rate

---

## Rules Channel Content

```
# ClawBox Community Rules

Welcome to the ClawBox Discord! Please read and follow these rules.

## 1. Be Respectful
Treat everyone with respect. No harassment, discrimination, or hate speech.

## 2. Stay On-Topic
Keep discussions relevant to the channel topic. Use #general for off-topic.

## 3. No Spam
No promotional content, referral links, or repetitive messages.

## 4. Search Before Asking
Check documentation and search previous messages before asking questions.

## 5. Use Appropriate Channels
Post in the correct channel for your topic (install-help, troubleshooting, etc.)

## 6. Security Issues
Report security vulnerabilities privately to security@clawbox.ai, not in public channels.

## 7. English Preferred
English is the primary language. Use international channels for other languages.

## 8. No Illegal Content
No sharing of copyrighted material, illegal content, or malicious code.

## 9. Follow Discord TOS
Follow Discord's Terms of Service and Community Guidelines.

## 10. Have Fun!
We're here to build a great community around secure local AI.

---

By participating, you agree to follow these rules.

Questions? Contact a moderator or email community@clawbox.ai
```

---

## Welcome Bot Message

```
Welcome to ClawBox Community! 🦞

You're now part of the community building secure local AI tools.

**Quick Start:**
1. Read #rules to understand our community guidelines
2. Introduce yourself in #general
3. Get help in #install-help if you're new to ClawBox

**Useful Links:**
- GitHub: https://github.com/clawboxhq/clawbox-installer
- Documentation: https://github.com/clawboxhq/clawbox-installer#readme
- Website: https://clawbox.ai

**Need Help?**
- Installation issues: #install-help
- Usage questions: #usage-questions
- Bugs: #troubleshooting

Enjoy your stay! 🎉
```

---

## Webhooks Setup

### GitHub Release Webhook
- **Channel:** #release-notes
- **Events:** Release published
- **Format:** Embed with version, changes, download links

### GitHub Discussions Webhook
- **Channel:** #development-chat
- **Events:** New discussion
- **Format:** Link to discussion with preview

---

## Moderation Bots

### Recommended Bots:
1. **Dyno** or **MEE6** - Auto-moderation, welcome messages
2. **GitHub Bot** - GitHub integration
3. **Carl-bot** - Reaction roles, logging

### Auto-Moderation Rules:
- Block external links from new members
- Block file uploads in announcement channels
- Word filter for common spam/phishing terms
- Rate limiting for new members

---

## Launch Checklist

- [ ] Create Discord server
- [ ] Set up all channels
- [ ] Configure roles and permissions
- [ ] Add rules and welcome messages
- [ ] Invite initial moderators
- [ ] Set up GitHub webhooks
- [ ] Add moderation bots
- [ ] Test invite link
- [ ] Add invite link to README and website
- [ ] Add invite link to GitHub repo description
