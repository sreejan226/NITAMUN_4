import Link from "next/link";
import { Download, FileText } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { SectionHeading } from "@/components/section-heading";

export default async function ResourcesPage() {
  let resources: { id: string; title: string; description: string | null; category: string | null; file_url: string }[] = [];
  try {
    const supabase = await createClient();
    const { data } = await supabase.from("resources").select("id,title,description,category,file_url").eq("is_published", true).order("title");
    resources = data ?? [];
  } catch {}
  return <main className="mx-auto max-w-7xl px-5 py-14 md:py-20"><SectionHeading eyebrow="Delegate toolkit" title="Resources & preparation" description="Everything delegates need to research, write and participate with confidence."/><div className="mt-10 grid gap-4 md:grid-cols-2">{resources.length ? resources.map((r) => <article key={r.id} className="flex gap-4 rounded-xl border border-slate-200 bg-white p-5"><div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-[#edf2f7] text-[#102a43]"><FileText size={21}/></div><div className="min-w-0 flex-1"><p className="text-xs font-bold uppercase tracking-wider text-[#9b7b35]">{r.category ?? "Resource"}</p><h2 className="mt-1 font-semibold text-[#102a43]">{r.title}</h2><p className="mt-2 text-sm leading-6 text-slate-600">{r.description}</p><Link href={r.file_url} target="_blank" rel="noreferrer" className="mt-4 inline-flex items-center gap-2 text-sm font-semibold text-[#102a43]">Open resource <Download size={15}/></Link></div></article>) : ["Rules of Procedure","Position Paper Guide","Delegate Handbook","Committee Background Guides"].map((title) => <article key={title} className="flex gap-4 rounded-xl border border-dashed border-slate-300 bg-white p-5"><div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-slate-500"><FileText size={21}/></div><div><h2 className="font-semibold text-[#102a43]">{title}</h2><p className="mt-2 text-sm text-slate-500">Add the approved PDF or public file URL in Supabase to publish this resource.</p></div></article>)}</div></main>;
}
