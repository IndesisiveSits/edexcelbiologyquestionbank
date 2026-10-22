# SNAB Vault — GitHub Pages + Supabase

This is a static HTML app with account-based cloud syncing. Supabase stores one private JSON vault row per account and keeps source PDFs/cropped question images in a **private** Storage bucket. Row-level security and Storage policies restrict access to the signed-in user's own data.

## Specification point bank

This build uses the official Pearson Edexcel Biology A (Salters-Nuffield / SNAB) A-level specification **9BN0, Issue 4 (November 2018)** as its specification-point reference:

https://qualifications.pearson.com/content/dam/pdf/A%20Level/biology-a/2015/specification-and-sample-assessment-materials/9781446930885-gce2015-a-bioa-spec.pdf

The app includes all **137 numbered content points** across Topics 1–8 (1.1–1.18, 2.1–2.16, 3.1–3.15, 4.1–4.16, 5.1–5.22, 6.1–6.15, 7.1–7.16 and 8.1–8.19). Descriptions in the dropdown are concise summaries to help identify a point; consult the official specification for the full wording and any sub-points. This build is configured for Biology A (SNAB) only, rather than displaying placeholder Biology B or IAL points.

Automatic matching uses the detected question-region text as a **suggestion**. Check it manually, especially for multi-part questions or regions with noisy PDF text extraction.

## 1. Supabase project (already created)

The connected Supabase organisation now has a project named **SNAB Vault** in the London region (`eu-west-2`). The `index.html` in this package is already configured with that project's URL and **publishable** browser key. Do not replace it with a service-role or secret key.

## 2. Database and private bucket (already configured)

The project has been configured with the `public.vault_state` table, row-level security policies, and a private Storage bucket named `snab-vault`. The bucket is limited to 50 MiB per object and accepts PDFs and JPEG images. Each authenticated user can access only their own database row and files.

The included `supabase_setup.sql` documents the setup. It is safe to use as a reference; the live project has already been configured, so you do not need to run it again.

## 3. Deploy the app on GitHub Pages

1. Create a GitHub repository (for example `snab-vault`).
2. Upload `index.html` to the repository's **root** directory. You may also include this README and SQL file.
3. Open **Settings → Pages**. Choose **Deploy from a branch**, select your default branch (usually `main`) and folder `/ (root)`, then save.
4. Wait for GitHub Pages to publish the site. Use the resulting `https://<username>.github.io/<repository>/` URL. Do not use `file://` to test cloud authentication.

## 4. Configure Supabase authentication URLs

In Supabase, open **Authentication → URL Configuration**:

- Set **Site URL** to the published GitHub Pages URL, including the repository path, e.g. `https://YOUR-USERNAME.github.io/snab-vault/`.
- Add that same URL to **Redirect URLs**. If you use a custom domain, add its HTTPS URL too.
- Keep email confirmation enabled if possible. New users may need to confirm their email before signing in. You can configure email templates and SMTP later if needed.

If sign-in redirects fail, check that the exact published URL (including the repository path and trailing slash where appropriate) is in Redirect URLs.

## 5. First use

1. Open the deployed site and create an account with an email and password of at least 8 characters.
2. Confirm the email if Supabase asks you to, then sign in.
3. Upload question papers or mark schemes. The app processes the PDFs in your browser, uploads each original PDF and region image to private Storage, and syncs the question metadata/specification classifications to your private vault row.
4. On another device, open the same GitHub Pages URL and sign in with the same account. Your library should load from Supabase.
5. Use **Original PDF** on a region to download its source PDF, and **Export backup** periodically as an extra safeguard.

## Security and operational notes

- The Supabase publishable/anon key is visible in browser code by design. Security depends on the SQL policies and the user's authenticated session. **Never expose the service-role key.**
- Storage is private; the app downloads files through the authenticated Supabase client rather than public URLs.
- This implementation stores each user's metadata in one JSON row. It is suitable for a personal/small question bank, but a very large bank may eventually benefit from normalized `papers` and `questions` tables.
- Storage upload limit in the SQL is 50 MiB per object. Adjust `file_size_limit` and your Supabase project's Storage limits if your PDFs are larger. Free-tier limits and quotas can change.
- Keep backups. Deleting a question record currently removes it from the metadata vault but does not automatically delete its old Storage object, so occasional unused files may remain and consume Storage quota.
- Automatic question/specification matching is a suggestion only; it uses selectable text extracted from each detected region. Review and correct classifications manually. The app's heading detection can miss questions in scanned PDFs because OCR is not included.
- This is a static app, so it does not require a private backend server. Authentication and authorization are enforced by Supabase, not by hiding controls in the page.

## Troubleshooting

- **“Setup required”**: the URL/key placeholders are still present or the Supabase JS CDN failed to load.
- **Sign-up works but sign-in does not**: check email confirmation and Supabase Auth URL/email settings.
- **Could not load/save cloud library**: rerun/check `supabase_setup.sql`, ensure the bucket is private and named exactly `snab-vault`, and inspect browser DevTools console for the Supabase error.
- **Storage policy violation**: check that the signed-in user's UUID is the first path segment and that the Storage policies were created.
- **No cross-device data**: sign into the same Supabase account on both devices; local browser storage is not used as the cloud source of truth.
