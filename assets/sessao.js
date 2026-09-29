// Sessão e perfil de acesso, compartilhados por todas as páginas do site.
(function(){
  "use strict";
  const cfg = window.CONFIG || {};
  const configurado = cfg.SUPABASE_URL && !/COLE_AQUI/.test(cfg.SUPABASE_URL) && cfg.SUPABASE_CHAVE_PUBLICA && !/COLE_AQUI/.test(cfg.SUPABASE_CHAVE_PUBLICA);
  const sb = (configurado && window.supabase) ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_CHAVE_PUBLICA) : null;

  const PAPEIS = { admin:"Administração", lanca:"Lança fechamentos", consulta:"Só consulta" };

  async function perfilAtual(){
    const { data:{ session } } = await sb.auth.getSession();
    if(!session) return null;
    const { data, error } = await sb.from("perfis").select("id,email,nome,papel").eq("id", session.user.id).maybeSingle();
    if(error || !data) return { session, perfil:null };
    return { session, perfil:data };
  }

  // Para páginas internas: sem login volta ao portal; sem perfil mostra aviso.
  async function exigirLogin(){
    if(!sb){ location.replace("index.html"); return new Promise(()=>{}); }
    const r = await perfilAtual();
    if(!r){ location.replace("index.html?voltar=" + encodeURIComponent(location.pathname.split("/").pop())); return new Promise(()=>{}); }
    return r;
  }

  async function sair(){ if(sb) await sb.auth.signOut(); location.replace("index.html"); }

  // Barra do topo com nome, papel e botão Sair
  function barraUsuario(el, r){
    const nome = r.perfil?.nome || r.session.user.email;
    el.innerHTML = "";
    const quem = document.createElement("span"); quem.className = "quem"; quem.textContent = nome;
    const papel = document.createElement("span"); papel.className = "papel"; papel.textContent = PAPEIS[r.perfil?.papel] || "Sem perfil";
    const b = document.createElement("button"); b.type = "button"; b.textContent = "Sair"; b.addEventListener("click", sair);
    el.append(quem, papel, b);
  }

  window.Sessao = { sb, configurado, perfilAtual, exigirLogin, sair, barraUsuario, PAPEIS };
})();
