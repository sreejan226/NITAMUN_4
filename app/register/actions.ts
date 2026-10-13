"use server";

import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export async function registerDelegate(formData: FormData) {
  const name = String(formData.get("full_name") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const phone = String(formData.get("phone") ?? "").trim();
  const institution = String(formData.get("institution") ?? "").trim();
  const year = String(formData.get("year_of_study") ?? "").trim();
  const committeeIds = formData.getAll("committee_preferences").map(String).filter(Boolean);
  const countryIds = formData.getAll("country_preferences").map(String).filter(Boolean);

  if (name.length < 2 || name.length > 120 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
      institution.length < 2 || phone.length > 30 || committeeIds.length < 1 || committeeIds.length > 3 ||
      countryIds.length > 5) {
    redirect("/register?error=Please%20complete%20the%20required%20fields%20and%20choose%20valid%20preferences.");
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("submit_registration", {
    p_full_name: name,
    p_email: email,
    p_phone: phone || null,
    p_institution: institution,
    p_year_of_study: year || null,
    p_committee_ids: committeeIds,
    p_country_ids: countryIds
  });

  if (error) {
    // Avoid returning database details to the visitor.
    redirect("/register?error=Registration%20could%20not%20be%20saved.%20Please%20check%20your%20preferences%20and%20try%20again.");
  }
  redirect("/register?success=1");
}
