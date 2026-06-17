/* walkthrough route runtime — inlined into every self-contained walkthrough.html.
   No external dependencies. Handles: TOC scroll-spy, quiz feedback (non-gating),
   reveal blocks, and optional localStorage progress. */
(function () {
  "use strict";

  var KEY = "wt-progress:" + (document.body.getAttribute("data-wt-id") || location.pathname);

  /* ---- Theme toggle (light default, persisted) ---- */
  var THEME_KEY = "wt-theme";
  var themeBtn = document.querySelector(".wt-theme-toggle");
  if (themeBtn) {
    themeBtn.addEventListener("click", function () {
      var next = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
      document.documentElement.setAttribute("data-theme", next);
      try { localStorage.setItem(THEME_KEY, next); } catch (e) {}
    });
  }

  /* ---- Sidebar collapse / responsive drawer ---- */
  var shell = document.querySelector(".wt-shell");
  var navOpenBtn = document.querySelector(".wt-nav-open");
  var navCollapseBtn = document.querySelector(".wt-nav-collapse");
  var navScrim = document.querySelector(".wt-nav-scrim");
  var navMq = window.matchMedia("(max-width: 860px)");
  function setNav(open) {
    if (!shell) return;
    shell.classList.toggle("nav-collapsed", !open);
    if (navOpenBtn) navOpenBtn.setAttribute("aria-expanded", open ? "true" : "false");
    if (navCollapseBtn) navCollapseBtn.setAttribute("aria-expanded", open ? "true" : "false");
  }
  // Auto-collapse on narrow viewports; auto-open when it widens again.
  function autoNav() { setNav(!navMq.matches); }
  autoNav();
  if (navMq.addEventListener) navMq.addEventListener("change", autoNav);
  else if (navMq.addListener) navMq.addListener(autoNav);
  if (navOpenBtn) navOpenBtn.addEventListener("click", function () { setNav(true); });
  if (navCollapseBtn) navCollapseBtn.addEventListener("click", function () { setNav(false); });
  if (navScrim) navScrim.addEventListener("click", function () { setNav(false); });

  /* ---- TOC scroll-spy ---- */
  var tocLinks = Array.prototype.slice.call(document.querySelectorAll(".wt-toc a"));
  // On narrow screens, picking a TOC entry should close the overlay drawer.
  tocLinks.forEach(function (a) {
    a.addEventListener("click", function () { if (navMq.matches) setNav(false); });
  });
  var headings = tocLinks
    .map(function (a) { return document.getElementById(a.getAttribute("href").slice(1)); })
    .filter(Boolean);

  function onScroll() {
    var pos = window.scrollY + 120;
    var current = headings[0];
    for (var i = 0; i < headings.length; i++) {
      if (headings[i].offsetTop <= pos) current = headings[i];
    }
    tocLinks.forEach(function (a) {
      a.classList.toggle("active", current && a.getAttribute("href") === "#" + current.id);
    });

    /* progress bar = scroll completion */
    var doc = document.documentElement;
    var max = doc.scrollHeight - doc.clientHeight;
    var pct = max > 0 ? Math.min(100, (window.scrollY / max) * 100) : 0;
    var bar = document.getElementById("wt-progress");
    if (bar) bar.style.width = pct.toFixed(1) + "%";
    saveProgress(pct);
  }

  /* ---- Quiz (non-gating) ---- */
  document.querySelectorAll(".wt-quiz").forEach(function (quiz) {
    var explain = quiz.querySelector(".explain");
    quiz.querySelectorAll(".opt").forEach(function (opt) {
      opt.addEventListener("click", function () {
        var correct = opt.getAttribute("data-correct") === "1";
        // clear previous state but never lock the user out — fully retryable
        quiz.querySelectorAll(".opt").forEach(function (o) { o.classList.remove("correct", "wrong"); });
        opt.classList.add(correct ? "correct" : "wrong");
        if (correct) {
          quiz.querySelectorAll(".opt").forEach(function (o) {
            if (o.getAttribute("data-correct") === "1") o.classList.add("correct");
          });
        }
        if (explain) explain.classList.add("show");
      });
    });
  });

  /* ---- localStorage progress (optional, non-blocking) ---- */
  function saveProgress(pct) {
    try { localStorage.setItem(KEY, JSON.stringify({ pct: Math.round(pct), at: Date.now() })); } catch (e) {}
  }
  function loadProgress() {
    try { return JSON.parse(localStorage.getItem(KEY) || "null"); } catch (e) { return null; }
  }

  var resetBtn = document.querySelector(".wt-reset");
  if (resetBtn) {
    resetBtn.addEventListener("click", function () {
      try { localStorage.removeItem(KEY); } catch (e) {}
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  /* restore scroll hint on load */
  window.addEventListener("load", function () {
    var saved = loadProgress();
    if (saved && saved.pct > 5 && saved.pct < 95 && !location.hash) {
      var note = document.querySelector(".wt-resume");
      if (note) {
        note.textContent = "Resume where you left off (" + saved.pct + "%)";
        note.style.display = "inline";
        note.addEventListener("click", function () {
          var doc = document.documentElement;
          var max = doc.scrollHeight - doc.clientHeight;
          window.scrollTo({ top: (saved.pct / 100) * max, behavior: "smooth" });
        });
      }
    }
    onScroll();
  });

  window.addEventListener("scroll", onScroll, { passive: true });
})();
