# Appendix B: Troubleshooting Guide

---

### Comprehensive Troubleshooting for MindfulLog

This appendix covers the most common issues you might encounter while building and deploying the application, with clear symptoms, causes, and step-by-step fixes.

---

#### 1. Setup & Installation Issues

**Problem**: `npx create-next-app` fails or hangs  
**Solution**:  
- Use a clean directory
- Try `npx create-next-app@latest . --typescript --tailwind --eslint --app --yes`

**Problem**: Module not found errors after installing packages  
**Solution**:
```bash
rm -rf node_modules package-lock.json
npm install
```

---

#### 2. Authentication (Clerk) Issues

**Problem**: Redirect loop or "Unable to sign in"  
**Solution**:
- Double-check `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY`
- Ensure `middleware.ts` matcher is correct
- Check that protected routes are properly configured

**Problem**: Clerk webhook errors during deletion  
**Solution**: Add Clerk webhook endpoint in your Clerk dashboard pointing to `/api/clerk-webhooks`

---

#### 3. Database & Schema Issues

**Problem**: "relation does not exist" when running queries  
**Solution**:
- Run the full `lib/schema.sql` again in Neon SQL Editor
- Make sure you're connected to the correct branch

**Problem**: `notes_encrypted` shows as text instead of `bytea`  
**Solution**: Drop and recreate the table, or alter column type carefully.

---

#### 4. Encryption Issues

**Problem**: KMS "Permission denied" or "Key not found"  
**Solution**:
- Verify `KMS_KEY_NAME` is correct
- Grant the Vercel service account (or your local credentials) `Cloud KMS CryptoKey Encrypter/Decrypter` role
- Check Google Cloud project is correctly set

**Problem**: Decryption returns garbage or errors  
**Solution**:
- Ensure you're passing the exact same `Buffer` that was returned by `encryptField()`
- Never modify the encrypted buffer manually

---

#### 5. Consent & Policy Engine Issues

**Problem**: Consent changes don't appear  
**Solution**:
- Check that `getCurrentConsents()` uses `DISTINCT ON (purpose)` correctly
- Verify user ID is being passed properly from Clerk

**Problem**: Policy engine always returns `false`  
**Solution**:
- Make sure `context.userId` matches `resource.ownerId` exactly

---

#### 6. Deployment (Vercel) Issues

**Problem**: Environment variables not working on Vercel  
**Solution**:
- Add variables in Vercel Dashboard → Settings → Environment Variables
- Redeploy after adding secrets
- Use `NEXT_PUBLIC_` prefix only for client-side variables

**Problem**: "Failed to decrypt" after deployment  
**Solution**: KMS permissions are the most common cause — verify IAM roles.

**Problem**: Rate limiting or Redis errors  
**Solution**: Confirm Upstash Redis URL and token are correctly set in Vercel.

---

#### 7. Performance & General Debugging Tips

- Use `safeLog()` instead of `console.log()` when dealing with user data
- Run `npm run privacy:scan` before every commit
- Use Neon database branching when testing deletion flows
- Enable Vercel Analytics for performance monitoring

**Debugging Command Cheat Sheet**:
```bash
# Test database
node -e 'import("./lib/db.js").then(m => m.testDatabaseConnection())'

# Test encryption roundtrip
node -e 'import("./lib/encryption.js").then...'

# Run privacy scanner
npm run privacy:scan
```

---

**Appendix B Complete**
