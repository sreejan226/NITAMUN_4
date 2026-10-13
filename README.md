# NITAMUN 4

A Next.js project for the NITAMUN 4 conference website, featuring public pages, committee information, registration flow, admin views, and Supabase integration.

## Project Structure

```text
nitamun-4/
├── app/
│   ├── page.tsx                 # Home + country availability
│   ├── committees/
│   │   └── page.tsx
│   ├── blogs/
│   │   ├── page.tsx
│   │   └── [slug]/page.tsx
│   ├── register/
│   │   └── page.tsx
│   ├── previous-editions/
│   │   └── page.tsx
│   ├── resources/
│   │   └── page.tsx
│   ├── admin/
│   │   ├── page.tsx
│   │   ├── allotments/page.tsx
│   │   └── registrations/page.tsx
│   └── api/
│       └── registrations/route.ts
├── components/
│   ├── Navbar.tsx
│   ├── Footer.tsx
│   ├── CountryTable.tsx
│   ├── CommitteeCard.tsx
│   └── RegistrationForm.tsx
├── lib/
│   └── supabase/
└── public/
    ├── images/
    └── resources/
```

## Features

- Public home page with country availability and filters
- Committee showcase pages
- Blog/news pages with dynamic article routing
- Registration flow
- Previous editions section
- Resource hub
- Admin dashboard with allotments and registrations
- API route for registration submissions

## Tech Stack

- Next.js
- React
- TypeScript
- Tailwind CSS
- Supabase

## Getting Started

1. Install dependencies:

   ```bash
   npm install
   ```

2. Add your environment variables for Supabase:

   ```bash
   NEXT_PUBLIC_SUPABASE_URL=
   NEXT_PUBLIC_SUPABASE_ANON_KEY=
   ```

3. Run the development server:

   ```bash
   npm run dev
   ```

4. Open the app in your browser:

   ```text
   http://localhost:3000
   ```

## Useful Scripts

```bash
npm run dev
npm run build
npm run start
npm run lint
```

## Notes

This project is structured as a starter website for the NITAMUN 4 event and can be extended with dynamic content, data models, and admin functionality as the event grows.
