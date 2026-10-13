import type { Metadata } from "next";
import "./globals.css";


export const metadata: Metadata = {
  title: "NITAMUN 4.0 | Model United Nations",
  description: "The official website for NITAMUN 4.0."
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body><Navbar />{children}<Footer /></body></html>;
}
