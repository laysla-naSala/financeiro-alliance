// Endereço e chave PÚBLICA do projeto Supabase (Project Settings → API).
// A chave pública ("anon" / "publishable") pode ficar no site: quem protege os dados são as regras do banco (RLS).
// NUNCA coloque aqui a chave "service_role" / "secret".
window.CONFIG = {
  SUPABASE_URL: "https://dvjeipnkxlvhfeuimacf.supabase.co",
  SUPABASE_CHAVE_PUBLICA: "sb_publishable_VODrG7M2CupdnXbsb66hkw_Ef2YUlLh",
  // Fluxo do n8n que envia o e-mail à contabilidade. Não é segredo: o fluxo confere o login de quem pede.
  N8N_ENVIO_CONTABILIDADE: "https://n8n-k5ro.srv1844289.hstgr.cloud/webhook/alliance-envio-contabilidade"
};
