// Moldura das páginas internas, no padrão do Alliance P.O.: menu lateral + barra com trilha.
// Para incluir um módulo novo, acrescente um item em MENU.
(function(){
  "use strict";
  const ICONES = {
    painel:  '<path d="M20 21a8 8 0 0 0-16 0"/><circle cx="12" cy="7" r="4"/>',
    boletos: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 8v8M10 8v8M13 8v8M17 8v8"/>',
    busca:   '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    menu:    '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 3v18"/>',
    sair:    '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/>',
    estrela: '<path d="m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8 5.8 21l1.2-6.8-5-4.9 6.9-1z" fill="currentColor"/>',
    seta:    '<path d="m9 18 6-6-6-6"/>',
    envio:   '<path d="m22 2-7 20-4-9-9-4z"/><path d="M22 2 11 13"/>'
  };
  const icone = (n, t) => `<svg width="${t||18}" height="${t||18}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONES[n]||""}</svg>`;

  const MENU = [
    { secao: "", itens: [
      { id: "painel",      nome: "Meu Painel",             href: "painel.html",      icone: "painel" }
    ]},
    { secao: "Financeiro", itens: [
      { id: "conciliacao", nome: "Conciliação de Boletos", href: "conciliacao.html", icone: "boletos" }
    ]},
    { secao: "Contabilidade", itens: [
      { id: "contabilidade", nome: "Envios à Contabilidade", href: "contabilidade.html", icone: "envio" }
    ]}
  ];
  const PAPEL = { admin: ["Administração", ""], lanca: ["Lança fechamentos", "lanca"], consulta: ["Só consulta", "consulta"] };
  const esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  const lerLS = k => { try { return localStorage.getItem(k); } catch(e) { return null; } };
  const gravarLS = (k, v) => { try { localStorage.setItem(k, v); } catch(e) {} };

  function iniciais(t){
    const p = String(t || "").split("@")[0].split(/[\s._-]+/).filter(Boolean);
    return ((p[0]?.[0] || "?") + (p[1]?.[0] || "")).toUpperCase();
  }

  // r = retorno de Sessao.exigirLogin(); conteudoEl = elemento com o conteúdo da página
  function montar(r, { ativo, trilha, conteudoEl }){
    const nome = r.perfil?.nome || r.session.user.email;
    const [papelTxt, papelCls] = PAPEL[r.perfil?.papel] || ["Sem perfil", "consulta"];
    const shell = document.createElement("div");
    shell.className = "shell" + (lerLS("menu-recolhido") === "1" ? " recolhido" : "");
    shell.innerHTML = `
      <aside class="lateral" aria-label="Menu">
        <div class="lat-topo"><a href="painel.html" title="Meu Painel"><img class="logo-img" src="assets/logo-alliance.png" alt="Alliance" width="64" height="46"></a></div>
        <label class="lat-busca" for="buscaMenu">${icone("busca",16)}<input id="buscaMenu" type="search" placeholder="Buscar menu..." autocomplete="off"></label>
        <nav class="lat-nav" id="latNav"></nav>
        <div class="lat-usuario">
          <span class="avatar">${esc(iniciais(nome))}</span>
          <span class="quem"><div class="nome">${esc(nome)}</div><span class="papel-selo ${papelCls}">${esc(papelTxt)}</span></span>
          <button type="button" class="lat-sair" id="btnSair" title="Sair" aria-label="Sair">${icone("sair")}</button>
        </div>
      </aside>
      <div class="conteudo">
        <div class="barra">
          <button type="button" id="btnMenu" title="Mostrar ou esconder o menu" aria-label="Mostrar ou esconder o menu">${icone("menu",20)}</button>
          <div class="trilha">${(trilha||[]).map((t,i,a)=> i===a.length-1 ? `<b>${esc(t)}</b>` : `<span>${esc(t)}</span>${icone("seta",14)}`).join("")}</div>
        </div>
      </div>
      <div class="fundo-escuro" id="fundoEscuro"></div>`;
    const conteudo = shell.querySelector(".conteudo");
    conteudoEl.classList.add("pagina");
    conteudo.appendChild(conteudoEl);
    document.body.prepend(shell);

    const nav = shell.querySelector("#latNav");
    function desenharMenu(filtro){
      const f = (filtro || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
      let html = "";
      for(const s of MENU){
        const itens = s.itens.filter(i => !f || i.nome.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().includes(f));
        if(!itens.length) continue;
        if(s.secao) html += `<div class="lat-sec">${esc(s.secao)}</div>`;
        html += itens.map(i => `<a class="lat-item${i.id===ativo?" ativo":""}" href="${i.href}"${i.id===ativo?' aria-current="page"':""}>${icone(i.icone)}<span>${esc(i.nome)}</span></a>`).join("");
      }
      nav.innerHTML = html || `<div class="lat-vazio">Nenhum item com esse nome.</div>`;
    }
    desenharMenu("");
    shell.querySelector("#buscaMenu").addEventListener("input", e => desenharMenu(e.target.value));
    shell.querySelector("#btnSair").addEventListener("click", () => window.Sessao.sair());
    const celular = () => matchMedia("(max-width:860px)").matches;
    shell.querySelector("#btnMenu").addEventListener("click", () => {
      if(celular()) shell.classList.toggle("menu-aberto");
      else { shell.classList.toggle("recolhido"); gravarLS("menu-recolhido", shell.classList.contains("recolhido") ? "1" : "0"); }
    });
    shell.querySelector("#fundoEscuro").addEventListener("click", () => shell.classList.remove("menu-aberto"));
    return shell;
  }

  window.Layout = { montar, icone, MENU };
})();
