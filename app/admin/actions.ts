"use server";

import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

async function requireAdmin() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/admin/login");
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  if (!profile || !["admin", "organizer"].includes(profile.role)) throw new Error("Not authorized.");
  return supabase;
}

export async function updateAllotment(formData: FormData) {
  const supabase = await requireAdmin();
  const id = String(formData.get("allotment_id") ?? "");
  const status = String(formData.get("status") ?? "");
  if (!id || !["vacant", "allotted", "reserved"].includes(status)) throw new Error("Invalid allotment update.");
  const { error } = await supabase.from("country_allotments").update({ status }).eq("id", id);
  if (error) throw new Error("Could not update country status.");
  revalidatePath("/");
  revalidatePath("/admin");
}

export async function signInAdmin(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) redirect("/admin/login?error=Unable%20to%20sign%20in.");
  const { data: { user } } = await supabase.auth.getUser();
  const { data: profile } = user ? await supabase.from("profiles").select("role").eq("id", user.id).single() : { data: null };
  if (!profile || !["admin", "organizer"].includes(profile.role)) {
    await supabase.auth.signOut();
    redirect("/admin/login?error=This%20account%20does%20not%20have%20organizer%20access.");
  }
  redirect("/admin");
}

export async function signOutAdmin() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/admin/login");
}
