# Project security rules

- Every API route, server action and resolver reads the session on the server before anything else.
  A handler that loads or changes a row by an id from the request scopes the query to the caller's
  user or tenant id from the session, or the table's row-level security does. Loading by id alone is
  an IDOR.
- Request bodies are parsed with a strict schema before use. Spreading a request body into a database
  insert or update is mass assignment.
- The database service-role key, admin tokens and any key that bypasses row-level security are used
  only in server-only modules, after the caller is authorised. Any such key in a file that a client
  component imports, or in a variable with a `NEXT_PUBLIC_` or `VITE_` prefix, is a leaked secret.
- Money is an integer in minor units. A float or a client-supplied price used for a charge is a
  finding.
- A webhook handler verifies the provider's signature over the raw body before parsing it, and
  deduplicates by event id.
- Text from a model is untrusted input: it is validated before it is stored, shown as HTML, used in a
  query or a path, or used to choose an action. A model never decides whether a person may do
  something; code does.
- Redirect targets from a request are relative paths or an allowlisted origin.
- Real personal data never appears in fixtures, seeds, tests, logs or screenshots.
