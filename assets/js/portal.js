// Bokomoko Portal — vanilla JS, no frameworks.
// Loads site config from content/site.json and renders the shared
// header/nav/footer into any page that includes <div data-portal-header>
// and <div data-portal-footer>.

(function () {
  "use strict";

  // Resolve content path relative to the page depth (pages/ is one level deep).
  function basePrefix() {
    return window.location.pathname.includes("/pages/") ? "../" : "";
  }

  async function loadConfig() {
    const res = await fetch(basePrefix() + "content/site.json", {
      cache: "no-store",
    });
    if (!res.ok) throw new Error("Failed to load site.json: " + res.status);
    return res.json();
  }

  function el(tag, attrs, children) {
    const node = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach((k) => {
        if (k === "text") node.textContent = attrs[k];
        else node.setAttribute(k, attrs[k]);
      });
    }
    (children || []).forEach((c) => node.appendChild(c));
    return node;
  }

  function renderHeader(mount, cfg) {
    const prefix = basePrefix();
    const current = document.body.getAttribute("data-page-id");

    const brand = el("a", { class: "site-brand", href: prefix + "index.html" }, [
      document.createTextNode(cfg.site.name),
    ]);
    brand.appendChild(el("small", { text: cfg.site.tagline }));

    const nav = el("nav", { class: "site-nav", "aria-label": "Principal" });
    cfg.nav.forEach((item) => {
      const a = el("a", { href: prefix + item.href, text: item.label });
      if (item.id === current) a.setAttribute("aria-current", "page");
      nav.appendChild(a);
    });

    const inner = el("div", { class: "inner" }, [brand, nav]);
    mount.appendChild(el("header", { class: "site-header" }, [inner]));
  }

  function renderFooter(mount, cfg) {
    const year = new Date().getFullYear();
    const footer = el("footer", { class: "site-footer" });
    footer.innerHTML =
      "© " +
      year +
      " " +
      cfg.site.name +
      " · servido pela torrent cloud (BTFS) + IPFS · <code>" +
      cfg.site.ens +
      "</code>";
    mount.appendChild(footer);
  }

  async function init() {
    try {
      const cfg = await loadConfig();
      document.querySelectorAll("[data-portal-header]").forEach((m) =>
        renderHeader(m, cfg)
      );
      document.querySelectorAll("[data-portal-footer]").forEach((m) =>
        renderFooter(m, cfg)
      );
    } catch (err) {
      // Fail loud in console, but never block the page content.
      console.error("[portal]", err);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
