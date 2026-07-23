// AUTO-GENERATED template blocks (_rp0.._rp7) from recipe-sample.html; do not hand-edit those.
// The parchment-and-summit-marks shareable recipe page, self-contained for Safari.
import Foundation

extension RecipeShare {
    /// A self-contained "pretty page" HTML for one recipe: parchment/topo wash,
    /// gold summit marks (three types) that turn in 3D around the vertical axis, a
    /// Web-Audio kitchen timer, check-off steps and a table of contents. Opens
    /// standalone in Safari from a text; every recipe field is HTML-escaped.
    public static func html(name: String, serves: String, time: String,
                            ingredients: [String], steps: [String],
                            notes: String, sourceUrl: String) -> String {
        let t = trimmed(name).isEmpty ? "Recipe" : trimmed(name)
        let title = htmlEscape(t)
        let titleTag = title + " \u{00B7} a recipe"
        let shapes = ["compass", "peak", "pine"]   // three summit marks, cycled
        var metaParts: [String] = []
        if !trimmed(serves).isEmpty { metaParts.append("<span>Serves <b>" + htmlEscape(trimmed(serves)) + "</b></span>") }
        if !trimmed(time).isEmpty { metaParts.append("<span><b>" + htmlEscape(trimmed(time)) + "</b></span>") }
        let meta = metaParts.isEmpty ? "<span>A recipe to make and share</span>" : metaParts.joined(separator: "<span class=\"dot\"></span>")
        var source = ""
        if let safe = safeURL(sourceUrl), let h = host(of: sourceUrl) {
            source = "<a class=\"source\" href=\"" + htmlEscape(safe) + "\" target=\"_blank\" rel=\"noopener\"><svg width=\"13\" height=\"13\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\"><path d=\"M10 13a5 5 0 007 0l2-2a5 5 0 00-7-7l-1 1M14 11a5 5 0 00-7 0l-2 2a5 5 0 007 7l1-1\" stroke-linecap=\"round\"/></svg><u>" + htmlEscape(h) + "</u></a>"
        }
        let ingHTML = cleanLines(ingredients).enumerated().map { (i, s) in
            "<li class=\"check-row\"><label class=\"check\"><input type=\"checkbox\"><span class=\"box\"></span><svg class=\"gem-ic\" viewBox=\"0 0 100 100\" style=\"--i:\(i)\"><use href=\"#\(shapes[(i + 1) % 3])\"/></svg></label><span class=\"label\">" + htmlEscape(s) + "</span></li>"
        }.joined(separator: "\n")
        let stepHTML = cleanLines(steps).enumerated().map { (i, s) in
            let sh = shapes[i % 3]
            return "<li class=\"step\"><label class=\"badge\"><input type=\"checkbox\"><span class=\"num\"></span><span class=\"diamond\" style=\"--i:\(i)\"><span class=\"d3i\"><svg viewBox=\"0 0 100 100\"><use href=\"#\(sh)\"/></svg><svg class=\"s2\" viewBox=\"0 0 100 100\"><use href=\"#\(sh)\"/></svg></span></span></label><div class=\"body\"><p><span class=\"line\">" + htmlEscape(flatten(s)) + "</span></p></div></li>"
        }.joined(separator: "\n")
        var notesHTML = ""
        let nt = trimmed(notes)
        if !nt.isEmpty {
            let body = htmlEscape(nt).replacingOccurrences(of: "\n", with: "<br>")
            notesHTML = "<section class=\"section\" id=\"notes\"><div class=\"section-head\"><span class=\"gem d3\"><span class=\"d3i\"><svg viewBox=\"0 0 100 100\"><use href=\"#compass\"/></svg><svg class=\"s2\" viewBox=\"0 0 100 100\"><use href=\"#compass\"/></svg></span></span><h2>Notes</h2></div><div class=\"card\"><p style=\"margin:0;color:var(--ink-soft)\">" + body + "</p></div></section>"
        }
        return _rp0 + titleTag + _rp1 + title + _rp2 + meta + _rp3 + source + _rp4 + ingHTML + _rp5 + stepHTML + _rp6 + notesHTML + _rp7
    }
}

private let _rp0 = #"""
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light">
<meta name="theme-color" content="#E2D3B4">
<title>
"""#

private let _rp1 = #"""
</title>
<style>
:root{
  /* parchment / topo wash */
  --paper:#FDFBF4; --parch-50:#F7F2E7; --parch-100:#EFE6D2; --parch-200:#E2D3B4;
  --surface:#FDFBF4; --surface-2:#F3ECDC;
  /* gold */
  --gold:#C9A24E; --gold-deep:#A9823C; --gold-line:rgba(169,130,60,.42);
  /* pine pop */
  --pine:#2E5D46; --pine-soft:#4E7D64;
  /* ink — darkened so muted/tertiary text clears WCAG AA across the whole parchment gradient */
  --ink:#2E2A22; --ink-soft:#4A4335; --ink-faint:#5F5842;
  --gold-text:#6E4F1C; /* AA-safe gold for small text (icons/borders may use --gold-deep) */
  /* glint used on the summit marks */
  --ice:#EAF4EE;
  --wash:linear-gradient(180deg,#F7F2E7 0%,#EFE6D2 52%,#E2D3B4 100%);
  --gold-sheen:linear-gradient(100deg,#A9823C 0%,#D8B25E 24%,#F6EBC2 50%,#D8B25E 76%,#A9823C 100%);
  --radius:20px;
  --font-display:"Baskerville","Hoefler Text",Georgia,"Times New Roman",serif;
  --font-body:"Avenir Next","Segoe UI",system-ui,-apple-system,sans-serif;
  /* z-index scale */
  --z-sparkle:0; --z-content:1; --z-topbar:8; --z-diamond:12; --z-dialog:60; --z-burst:70;
}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
html{overscroll-behavior:none;scroll-behavior:smooth}
body{
  font-family:var(--font-body);color:var(--ink);line-height:1.6;
  background:var(--wash);background-attachment:fixed;
  -webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;
  overflow-x:hidden;overscroll-behavior:none;
  -webkit-tap-highlight-color:transparent;
  min-height:100svh;
}
/* soft light pooling on top of the wash — cheap depth, no animation */
body::before{
  content:"";position:fixed;inset:0;z-index:-2;pointer-events:none;
  background:
    radial-gradient(60% 40% at 50% 8%,rgba(253,251,244,.75),transparent 70%),
    radial-gradient(40% 30% at 88% 24%,rgba(239,230,210,.55),transparent 70%),
    radial-gradient(45% 30% at 10% 62%,rgba(247,242,231,.4),transparent 70%);
}
body::after{
  content:"";position:fixed;inset:0;z-index:-1;pointer-events:none;
  background:linear-gradient(180deg,rgba(247,242,231,.15),rgba(226,211,180,.14));
}
#sparkles{position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:var(--z-sparkle)}
body.no-sparkle #sparkles{display:none}

/* ---------- topbar ---------- */
.topbar{
  position:fixed;top:0;left:0;right:0;z-index:var(--z-topbar);
  display:flex;align-items:center;justify-content:space-between;gap:.5rem;
  padding:calc(env(safe-area-inset-top) + .5rem) clamp(.75rem,4vw,1.4rem) .5rem;
  background:transparent;pointer-events:none;
}
/* only the buttons/brand catch taps — the bar itself sits behind the diamonds
   and lets the page show through (no covering band). */
.topbar > *{pointer-events:auto}
.progress{position:absolute;left:0;bottom:0;height:2px;width:100%;background:transparent;pointer-events:none}
.progress > i{display:block;height:100%;width:0;background:var(--gold-sheen);
  box-shadow:0 0 8px rgba(201,162,78,.7);transition:width .5s cubic-bezier(.22,1,.36,1)}
.icon-btn{
  -webkit-appearance:none;appearance:none;border:1px solid var(--gold-line);
  background:rgba(255,253,246,.7);color:var(--gold-deep);
  width:44px;height:44px;border-radius:50%;display:grid;place-items:center;
  cursor:pointer;transition:transform .18s ease,box-shadow .18s ease,background .18s ease;
  -webkit-user-select:none;user-select:none;
}
.icon-btn:active{transform:scale(.92)}
.icon-btn:focus-visible{outline:2px solid var(--pine);outline-offset:2px}
.icon-btn svg{width:20px;height:20px;display:block}
.brand{display:flex;align-items:center;gap:.4rem;color:var(--gold-deep)}
.brand .brand-mark{width:22px;height:22px}
.brand span{font-family:var(--font-display);font-size:.98rem;line-height:1;color:var(--gold-deep);
  text-transform:uppercase;letter-spacing:.14em;font-weight:600;transform:translateY(1px)}

/* ---------- layout ---------- */
main{position:relative;z-index:var(--z-content);max-width:40rem;margin:0 auto;
  padding:0 clamp(1.1rem,5vw,2rem) 5rem}
.hero{padding:calc(env(safe-area-inset-top) + 5.2rem) 0 1.4rem;text-align:center;position:relative}
.eyebrow{font-family:var(--font-body);font-size:.72rem;letter-spacing:.32em;text-transform:uppercase;
  color:var(--pine);margin:0 0 .7rem;font-weight:600}
.title{
  font-family:var(--font-display);font-weight:400;
  font-size:clamp(2.3rem,8.5vw,3.7rem);line-height:1.04;letter-spacing:-.01em;
  margin:0 auto;max-width:14ch;color:var(--ink);text-wrap:balance;
}
.flourish{font-family:var(--font-body);font-size:.8rem;text-transform:uppercase;letter-spacing:.28em;
  color:transparent;background:var(--gold-sheen);-webkit-background-clip:text;background-clip:text;
  margin:.6rem 0 0;line-height:1;font-weight:600}
.meta{display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:.35rem .95rem;
  margin:1.15rem 0 .2rem;color:var(--ink-soft);font-size:.95rem}
.meta b{color:var(--ink);font-weight:600}
.meta .dot{width:5px;height:5px;border-radius:50%;background:var(--gold);opacity:.7}
.source{display:inline-flex;align-items:center;gap:.35em;margin-top:.5rem;font-size:.82rem;
  color:var(--ink-faint);text-decoration:none}
.source u{text-decoration:none;border-bottom:1px solid var(--gold-line)}

/* rule with gem */
.rule{display:flex;align-items:center;justify-content:center;gap:.9rem;margin:1.8rem auto;color:var(--pine)}
.rule::before,.rule::after{content:"";height:1px;width:min(28vw,7rem);
  background:linear-gradient(90deg,transparent,var(--gold-line),transparent)}
.rule .star{font-size:.8rem;color:var(--pine)}

/* section */
.section{margin:2.4rem 0;scroll-margin-top:5.5rem}
.step{scroll-margin-top:5.5rem}
.section-head{display:flex;align-items:center;gap:.6rem;margin:0 0 .7rem}
.section-head h2{font-family:var(--font-display);font-weight:600;font-size:clamp(1.5rem,5.5vw,2.1rem);
  line-height:1.1;margin:0;color:var(--pine);letter-spacing:.06em;text-transform:uppercase;padding-right:.08em}
.section-head .gem{width:30px;height:30px;flex:0 0 auto;cursor:pointer}
.section-note{font-size:.86rem;color:var(--ink-faint);margin:-.1rem 0 1rem;font-style:italic}
.done-count{margin-left:auto;font-size:.78rem;color:var(--gold-text);white-space:nowrap;align-self:center}
.reset-steps{-webkit-appearance:none;appearance:none;background:rgba(255,253,246,.7);cursor:pointer;
  font-family:var(--font-body);font-size:.85rem;color:var(--gold-text);margin:1rem auto 0;display:block;
  padding:.5rem 1.1rem;border-radius:999px;border:1px solid var(--gold-line);transition:transform .16s ease}
.reset-steps:active{transform:scale(.95)}
.reset-steps:focus-visible{outline:2px solid var(--pine);outline-offset:2px}

/* card surface */
.card{background:linear-gradient(180deg,rgba(255,253,246,.92),rgba(251,241,220,.88));
  border:1px solid var(--gold-line);border-radius:var(--radius);
  box-shadow:0 10px 30px -18px rgba(46,93,70,.28),0 2px 0 rgba(255,255,255,.5) inset;
  padding:clamp(1rem,4vw,1.4rem)}

/* ---------- checklist (ingredients) ---------- */
.checklist{list-style:none;margin:0;padding:0}
.check-row{display:flex;align-items:flex-start;gap:.8rem;padding:.55rem 0;
  border-bottom:1px solid rgba(169,130,60,.16)}
.check-row:last-child{border-bottom:0}
.check{position:relative;flex:0 0 auto;width:1.5rem;height:1.5rem;margin-top:.05rem;cursor:pointer;
  -webkit-user-select:none;user-select:none}
.check input{position:absolute;inset:0;opacity:0;margin:0;cursor:pointer;width:100%;height:100%}
.check .box,.check .gem-ic{position:absolute;inset:0;transition:opacity .28s ease,transform .4s cubic-bezier(.34,1.56,.64,1)}
.check .box{border:1.6px solid var(--gold);border-radius:6px;background:rgba(255,255,255,.5);opacity:1;transform:scale(1)}
.check .gem-ic{opacity:0;transform:scale(.3) rotate(-22deg)}
.check input:checked ~ .box{opacity:0;transform:scale(.5)}
.check input:checked ~ .gem-ic{opacity:1;transform:scale(1) rotate(0)}
.check input:focus-visible ~ .box{outline:2px solid var(--pine);outline-offset:2px;border-radius:6px}
.check-row .label{flex:1;font-size:1.02rem;color:var(--ink);transition:color .3s ease}
.check-row.done .label{color:var(--ink-faint)}
.amount{color:var(--gold-deep);font-weight:600}

/* ---------- steps ---------- */
.steps{list-style:none;margin:0;padding:0;counter-reset:step}
.step{position:relative;display:flex;gap:1rem;padding:1rem 0;
  border-bottom:1px solid rgba(169,130,60,.16)}
.step:last-child{border-bottom:0}
.step .badge{position:relative;flex:0 0 auto;width:2.6rem;height:2.6rem;cursor:pointer;
  -webkit-user-select:none;user-select:none}
.step .badge input{position:absolute;inset:0;opacity:0;margin:0;cursor:pointer;width:100%;height:100%;z-index:2}
.step .num,.step .diamond{position:absolute;inset:0;display:grid;place-items:center;
  transition:opacity .3s ease,transform .45s cubic-bezier(.34,1.56,.64,1)}
.step .num{border:1.6px solid var(--gold);border-radius:50%;
  background:radial-gradient(circle at 50% 35%,#fff,rgba(255,253,246,.7));
  color:var(--gold-deep);font-family:var(--font-display);font-size:1.15rem;opacity:1;transform:scale(1)}
.step .num::before{counter-increment:step;content:counter(step)}
.step .diamond{opacity:0;transform:scale(.35) rotate(-20deg)}
.step .diamond svg{width:100%;height:100%}
.step .badge input:checked ~ .num{opacity:0;transform:scale(.4)}
.step .badge input:checked ~ .diamond{opacity:1;transform:scale(1) rotate(0)}
.step .badge input:focus-visible ~ .num{outline:2px solid var(--pine);outline-offset:2px}
.step .body{flex:1;padding-top:.25rem}
.step .body p{margin:0;font-size:1.06rem;line-height:1.62;color:var(--ink);transition:color .35s ease}
.step.done .body p{color:var(--ink-soft)}
.step.done .body p .line{background-image:linear-gradient(var(--gold-line),var(--gold-line));
  background-repeat:no-repeat;background-size:100% 1px;background-position:0 88%}

/* twinkle for checked diamonds — pure CSS, drift-free, staggered per --i */
.twinkle{transform-origin:center}
body:not(.no-twinkle) .step .badge input:checked ~ .diamond .twinkle{
  animation:twinkle 20s ease-in-out infinite;
  animation-delay:calc(var(--i,0) * -3.3s);
}
body:not(.no-twinkle) .check input:checked ~ .gem-ic .twinkle{
  animation:twinkle 20s ease-in-out infinite;
  animation-delay:calc(var(--i,0) * -2.1s);
}
@keyframes twinkle{
  0%,90%,100%{filter:brightness(1) drop-shadow(0 1px 2px rgba(46,93,70,.18))}
  94%{filter:brightness(1.7) drop-shadow(0 0 7px rgba(255,247,214,.95))}
  97%{filter:brightness(1.25) drop-shadow(0 0 3px rgba(255,247,214,.6))}
}

/* ---------- gem clusters (rock candy) — brought to the front, and they spin ---------- */
/* Real 3D spin around the VERTICAL axis. .d3 holds the perspective; .d3i turns;
   two crossed faces (.s2 pre-rotated 90deg) keep the gem solid so it never
   flattens to an invisible edge. White glow is baked into the SVG (#wglow), so
   nothing on this 3D chain carries a CSS filter (which would flatten it). */
.d3{perspective:320px;perspective-origin:50% 44%;display:block}
.d3i{position:relative;width:100%;height:100%;transform-style:preserve-3d}
.d3i > svg{position:absolute;inset:0;width:100%;height:100%}
.d3i > svg.s2{transform:rotateY(90deg)}
@keyframes spin3d{to{transform:rotateY(360deg)}}
body:not(.no-twinkle) .d3i{animation:spin3d 9s linear infinite}

.cluster{position:absolute;pointer-events:none;z-index:var(--z-diamond);width:150px;height:130px}
.cluster .gem{position:absolute;aspect-ratio:1}
body:not(.no-twinkle) .cluster .g1 .d3i{animation-duration:8s}
body:not(.no-twinkle) .cluster .g2 .d3i{animation-duration:11s;animation-direction:reverse}
body:not(.no-twinkle) .cluster .g3 .d3i{animation-duration:7s}
body:not(.no-twinkle) .cluster .g4 .d3i{animation-duration:13s;animation-direction:reverse}
body:not(.no-twinkle) .cluster .g5 .d3i{animation-duration:9.5s}
.cluster .g1{width:66px;top:0;left:42px}
.cluster .g2{width:42px;top:34px;left:2px;opacity:.92}
.cluster .g3{width:50px;top:60px;left:78px;opacity:.85}
.cluster .g4{width:28px;top:12px;left:104px;opacity:.8}
.cluster .g5{width:24px;top:82px;left:34px;opacity:.74}
.cluster.top-right{top:-14px;right:-16px;transform:scale(.85)}
.cluster.foot{position:relative;margin:1rem auto 0;transform:scale(.9)}

/* single showcase diamond (divider) — spins, tappable */
.showcase{display:flex;align-items:center;justify-content:center;gap:1rem;margin:2.6rem 0;position:relative;z-index:var(--z-diamond)}
.showcase .big{width:80px;aspect-ratio:1;cursor:pointer}
body:not(.no-twinkle) .showcase .big .d3i{animation-duration:7s}
body:not(.no-twinkle) .showcase .big .twinkle{animation:twinkle 8s ease-in-out infinite}
.showcase .side{height:1px;flex:1;max-width:6rem;background:linear-gradient(90deg,transparent,var(--gold-line))}
.showcase .side.r{background:linear-gradient(90deg,var(--gold-line),transparent)}
/* section gems + header mark turn a touch slower; step diamonds get their own perspective */
body:not(.no-twinkle) .section-head .gem .d3i{animation-duration:12s}
body:not(.no-twinkle) .brand .brand-mark .d3i{animation-duration:16s}
.step .diamond{perspective:260px}

/* ---------- timer ---------- */
.timer{position:relative;overflow:hidden}
.timer .cluster{opacity:.55}
.timer .section-head{margin-bottom:.4rem}
.timer .hint{font-size:.8rem;color:var(--ink-faint);margin:.15rem 0 1rem;display:flex;align-items:center;gap:.4em}
.clock{font-family:var(--font-display);font-variant-numeric:tabular-nums;
  font-size:clamp(3rem,17vw,4.6rem);line-height:1;text-align:center;color:var(--ink);
  letter-spacing:.01em;margin:.3rem 0 .2rem;transition:color .3s ease}
.timer.done .clock{color:var(--pine)}
.presets{display:flex;flex-wrap:wrap;gap:.5rem;justify-content:center;margin:.6rem 0 .6rem}
.custom-row{display:flex;gap:.5rem;justify-content:center;align-items:center;margin:0 0 1rem}
.custom-row[hidden]{display:none}
.custom-input{width:5.5rem;font-family:var(--font-body);font-size:16px;text-align:center;
  padding:.45rem .5rem;border:1px solid var(--gold-line);border-radius:12px;background:var(--surface);color:var(--ink)}
.custom-input:focus-visible{outline:2px solid var(--pine);outline-offset:2px}
.chip{-webkit-appearance:none;appearance:none;border:1px solid var(--gold-line);
  background:rgba(255,253,246,.7);color:var(--gold-text);font-family:var(--font-body);
  font-size:.92rem;padding:.42rem .8rem;border-radius:999px;cursor:pointer;
  transition:transform .16s ease,background .2s ease,color .2s ease,border-color .2s ease}
.chip:active{transform:scale(.94)}
.chip.sel{background:#6E4F1C;color:#fff;border-color:#6E4F1C}
.chip:focus-visible{outline:2px solid var(--pine);outline-offset:2px}
.timer-controls{display:flex;gap:.6rem;justify-content:center}
.btn{-webkit-appearance:none;appearance:none;cursor:pointer;font-family:var(--font-body);
  font-size:1rem;font-weight:600;padding:.7rem 1.5rem;border-radius:999px;border:1px solid transparent;
  transition:transform .16s ease,box-shadow .2s ease,background .2s ease;min-width:7.5rem}
.btn:active{transform:scale(.95)}
.btn:focus-visible{outline:2px solid var(--pine);outline-offset:2px}
.btn.primary{background:linear-gradient(180deg,#3F7057,#2E5D46);color:#fff;
  box-shadow:0 8px 20px -10px rgba(46,93,70,.7)}
.btn.ghost{background:rgba(255,253,246,.7);border-color:var(--gold-line);color:var(--gold-text)}

/* ---------- dialogs ---------- */
/* inset:0 + margin:auto centers for BOTH showModal() and the [open] fallback */
dialog{border:none;padding:0;background:transparent;color:var(--ink);
  width:min(92vw,26rem);height:max-content;max-height:min(84svh,42rem);
  inset:0;margin:auto;position:fixed;z-index:var(--z-dialog)}
dialog::backdrop{background:rgba(70,40,20,.42);-webkit-backdrop-filter:blur(3px);backdrop-filter:blur(3px)}
.sheet{background:linear-gradient(180deg,var(--surface),var(--surface-2));
  border:1px solid var(--gold-line);border-radius:22px;
  box-shadow:0 30px 70px -30px rgba(70,30,20,.6);padding:1.3rem 1.3rem 1.5rem;
  max-height:min(80svh,40rem);overflow:auto;-webkit-overflow-scrolling:touch}
.sheet-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:.7rem}
.sheet-head h3{font-family:var(--font-display);font-weight:400;font-size:1.4rem;margin:0;color:var(--ink)}
/* TOC anchors */
.toc{list-style:none;margin:0;padding:0}
.toc a{display:flex;align-items:center;gap:.7rem;padding:.7rem .3rem;text-decoration:none;color:var(--ink);
  border-bottom:1px solid rgba(169,130,60,.16);font-size:1rem}
.toc a:last-child{border-bottom:0}
.toc a .idx{font-family:var(--font-display);color:var(--gold-deep);width:1.6rem;text-align:center;flex:0 0 auto}
.toc a .idx.g svg{width:18px;height:18px;vertical-align:middle}
.toc a.section-link{color:var(--pine);font-family:var(--font-display);font-size:1.15rem}
.toc a .tick{margin-left:auto;color:var(--gold);opacity:0;transition:opacity .2s}
.toc a.checked .tick{opacity:1}
/* settings */
.setting{display:flex;align-items:center;justify-content:space-between;gap:1rem;padding:.85rem .2rem;
  border-bottom:1px solid rgba(169,130,60,.16)}
.setting:last-child{border-bottom:0}
.setting .t{font-size:1rem;color:var(--ink)}
.setting .s{font-size:.78rem;color:var(--ink-faint);margin-top:.1rem}
.switch{position:relative;flex:0 0 auto;width:52px;height:30px;cursor:pointer}
.switch input{position:absolute;inset:0;opacity:0;margin:0;cursor:pointer}
.switch .track{position:absolute;inset:0;border-radius:999px;background:rgba(169,130,60,.3);
  transition:background .25s ease}
.switch .knob{position:absolute;top:3px;left:3px;width:24px;height:24px;border-radius:50%;background:#fff;
  box-shadow:0 1px 3px rgba(0,0,0,.3);transition:transform .25s cubic-bezier(.34,1.4,.64,1)}
.switch input:checked ~ .track{background:linear-gradient(90deg,var(--gold-deep),var(--gold))}
.switch input:checked ~ .knob{transform:translateX(22px)}
.switch input:focus-visible ~ .track{outline:2px solid var(--pine);outline-offset:2px}

/* text-size setting */
body.large-text{font-size:1.12rem}

/* celebration burst layer */
#burst{position:fixed;inset:0;pointer-events:none;z-index:var(--z-burst)}

footer{position:relative;z-index:var(--z-content);text-align:center;padding:1rem 0 2rem;color:var(--ink-faint)}
footer .made{font-family:var(--font-display);font-weight:600;font-size:1.05rem;text-transform:uppercase;
  letter-spacing:.2em;color:transparent;background:var(--gold-sheen);-webkit-background-clip:text;
  background-clip:text;line-height:1.2}
footer small{display:block;margin-top:.4rem;font-size:.74rem;letter-spacing:.04em}

.toast{position:fixed;left:50%;bottom:calc(env(safe-area-inset-bottom) + 1.2rem);transform:translateX(-50%) translateY(20px);
  background:linear-gradient(180deg,#3F7057,#2E5D46);color:#fff;padding:.7rem 1.2rem;border-radius:999px;
  font-size:.95rem;box-shadow:0 12px 30px -12px rgba(46,93,70,.7);opacity:0;pointer-events:none;
  transition:opacity .3s ease,transform .35s cubic-bezier(.22,1,.36,1);z-index:var(--z-burst);
  display:flex;align-items:center;gap:.5em;max-width:88vw}
.toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
.toast .gm{width:18px;height:18px;flex:0 0 auto}

@media (prefers-reduced-motion: reduce){
  *{scroll-behavior:auto !important}
  .check .box,.check .gem-ic,.step .num,.step .diamond{transition:opacity .01s linear !important;transform:none !important}
  body .step .diamond .twinkle,body .check .gem-ic .twinkle,body .showcase .big .twinkle{animation:none !important;
    filter:brightness(1.12) drop-shadow(0 1px 3px rgba(46,93,70,.2)) !important}
  body .d3i{animation:none !important;transform:rotateY(20deg) !important}
  .btn:active,.chip:active,.icon-btn:active{transform:none}
}
</style>
</head>
<body>
<canvas id="sparkles" aria-hidden="true"></canvas>

<!-- summit mark symbols: gold compass, snowcapped peak, pine tree (reused everywhere via <use>) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <!-- gold / pine gradients shared by every mark -->
    <linearGradient id="gGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#F6EBC2"/><stop offset="0.5" stop-color="#D8B25E"/><stop offset="1" stop-color="#A9823C"/></linearGradient>
    <linearGradient id="gPine" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4E7D64"/><stop offset="1" stop-color="#2E5D46"/></linearGradient>
    <radialGradient id="gGlint" cx="0.42" cy="0.35" r="0.6">
      <stop offset="0" stop-color="#fff" stop-opacity="1"/><stop offset="0.5" stop-color="#F6EBC2" stop-opacity="0.85"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
    <!-- soft white glow baked into every mark (so no CSS filter is needed on the 3D wrapper) -->
    <filter id="wglow" x="-45%" y="-45%" width="190%" height="190%">
      <feDropShadow dx="0" dy="0" stdDeviation="2.6" flood-color="#ffffff" flood-opacity="0.95"/></filter>
    <!-- 1) compass rose — gold ring, gold/pine needle -->
    <symbol id="compass" viewBox="0 0 100 100">
      <g filter="url(#wglow)">
        <circle cx="50" cy="50" r="38" fill="url(#gGold)" opacity="0.16"/>
        <circle cx="50" cy="50" r="38" fill="none" stroke="url(#gGold)" stroke-width="4"/>
        <g stroke="url(#gGold)" stroke-width="2.6" stroke-linecap="round">
          <line x1="50" y1="6" x2="50" y2="17"/>
          <line x1="50" y1="83" x2="50" y2="94"/>
          <line x1="6" y1="50" x2="17" y2="50"/>
          <line x1="83" y1="50" x2="94" y2="50"/>
        </g>
        <polygon points="50,15 58,50 50,50" fill="url(#gGold)"/>
        <polygon points="50,15 42,50 50,50" fill="url(#gGold)" opacity="0.55"/>
        <polygon points="50,85 58,50 50,50" fill="url(#gPine)"/>
        <polygon points="50,85 42,50 50,50" fill="url(#gPine)" opacity="0.6"/>
        <circle cx="50" cy="50" r="5.5" fill="url(#gGold)"/>
      </g>
      <g class="twinkle">
        <circle cx="66" cy="28" r="8" fill="url(#gGlint)"/>
        <path d="M40 40 L42.5 48 L50 50.5 L42.5 53 L40 61 L37.5 53 L30 50.5 L37.5 48 Z" fill="#F6EBC2"/>
      </g>
    </symbol>
    <!-- 2) triangular peak with a snowcap -->
    <symbol id="peak" viewBox="0 0 100 100">
      <g filter="url(#wglow)">
        <polygon points="50,8 92,88 8,88" fill="url(#gPine)"/>
        <polygon points="50,8 78,58 22,58" fill="#FFFFFF"/>
        <polygon points="50,8 66,36 50,44 34,36" fill="#FFFFFF" opacity="0.9"/>
        <polygon points="66,36 78,58 50,58 50,44" fill="url(#gPine)" opacity="0.5"/>
        <polygon points="8,88 50,88 22,58" fill="url(#gGold)" opacity="0.3"/>
      </g>
      <g class="twinkle">
        <circle cx="66" cy="34" r="7" fill="url(#gGlint)"/>
        <path d="M42 58 L44 64 L50 66 L44 68 L42 74 L40 68 L34 66 L40 64 Z" fill="#F6EBC2" opacity="0.9"/>
      </g>
    </symbol>
    <!-- 3) pine tree -->
    <symbol id="pine" viewBox="0 0 100 100">
      <g filter="url(#wglow)">
        <polygon points="50,8 72,38 60,38 80,64 64,64 86,92 14,92 36,64 20,64 40,38 28,38" fill="url(#gPine)"/>
        <rect x="44" y="92" width="12" height="6" fill="url(#gGold)"/>
      </g>
      <g class="twinkle">
        <circle cx="62" cy="30" r="7" fill="url(#gGlint)"/>
        <path d="M62 44 L64 50 L70 52 L64 54 L62 60 L60 54 L54 52 L60 50 Z" fill="#F6EBC2" opacity="0.9"/>
      </g>
    </symbol>
    <!-- tiny 4-point sparkle used as an inline accent -->
    <symbol id="spark" viewBox="0 0 24 24">
      <path d="M12 0 L14 10 L24 12 L14 14 L12 24 L10 14 L0 12 L10 10 Z" fill="currentColor"/>
    </symbol>
  </defs>
</svg>

<header class="topbar">
  <button class="icon-btn" id="tocBtn" aria-label="Recipe steps menu" aria-haspopup="dialog">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
  </button>
  <div class="brand"><span class="brand-mark d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#compass"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#compass"/></svg></span></span><span>Summit Kitchen</span></div>
  <button class="icon-btn" id="setBtn" aria-label="Settings" aria-haspopup="dialog">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="3.2"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5 5l2.1 2.1M16.9 16.9L19 19M19 5l-2.1 2.1M7.1 16.9L5 19" stroke-linecap="round"/></svg>
  </button>
  <div class="progress"><i id="progressBar"></i></div>
</header>

<main>
  <section class="hero">
    <div class="cluster top-right" aria-hidden="true">
      <span class="gem g1 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#compass"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#compass"/></svg></span></span>
      <span class="gem g2 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#peak"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#peak"/></svg></span></span>
      <span class="gem g3 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#pine"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#pine"/></svg></span></span>
      <span class="gem g4 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#pine"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#pine"/></svg></span></span>
      <span class="gem g5 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#peak"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#peak"/></svg></span></span>
    </div>
    <p class="eyebrow">a recipe worth the climb &#9650;</p>
    <h1 class="title">
"""#

private let _rp2 = #"""
</h1>
    <p class="flourish">made at base camp</p>
    <div class="meta">
"""#

private let _rp3 = #"""
</div>
    
"""#

private let _rp4 = #"""

    <div class="rule"><span class="star">&#10022;</span></div>
  </section>

  <!-- ingredients -->
  <section class="section" id="ingredients">
    <div class="section-head"><span class="gem d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#compass"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#compass"/></svg></span></span><h2>Ingredients</h2></div>
    <p class="section-note">Tap each one as you gather it and watch it turn into a trail mark &#9650;</p>
    <div class="card">
      <ul class="checklist" id="ingredientList">
"""#

private let _rp5 = #"""
</ul>
    </div>
  </section>

  <div class="showcase" aria-hidden="true">
    <span class="side"></span>
    <span class="big d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#pine"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#pine"/></svg></span></span>
    <span class="side r"></span>
  </div>

  <!-- method -->
  <section class="section" id="method">
    <div class="section-head"><span class="gem d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#compass"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#compass"/></svg></span></span><h2>Method</h2><span class="done-count" id="doneCount"></span></div>
    <p class="section-note">Check off each step &mdash; each one earns its own summit mark &#10022;</p>
    <ol class="steps" id="stepList">
"""#

private let _rp6 = #"""
</ol>
    <button class="reset-steps" id="resetSteps">Start over &#8635;</button>
  </section>

  <!-- notes -->
  
"""#

private let _rp7 = #"""


  <!-- kitchen timer, right where you need it before baking -->
  <section class="section timer card" id="timerCard">
    <div class="cluster foot" aria-hidden="true" style="position:absolute;top:-30px;right:-18px;opacity:.4;pointer-events:none">
      <span class="gem g4 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#pine"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#pine"/></svg></span></span>
      <span class="gem g5 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#peak"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#peak"/></svg></span></span>
    </div>
    <div class="section-head"><span class="gem d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#compass"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#compass"/></svg></span></span><h2>Kitchen timer</h2></div>
    <p class="hint"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2M9 2h6" stroke-linecap="round"/></svg>
      This little timer only rings while the page is open &mdash; keep it up front. &#9650;</p>
    <div class="clock" id="clock" aria-live="polite">10:00</div>
    <div class="presets" id="presets">
      <button class="chip" data-min="5">5 min</button>
      <button class="chip sel" data-min="10">10 min</button>
      <button class="chip" data-min="15">15 min</button>
      <button class="chip" data-min="20">20 min</button>
      <button class="chip" data-min="30">30 min</button>
      <button class="chip" id="customChip">Custom</button>
    </div>
    <div class="custom-row" id="customRow" hidden>
      <input class="custom-input" id="customInput" type="number" inputmode="numeric" min="1" max="600" step="1" placeholder="min" aria-label="Custom minutes">
      <button class="chip" id="customSet">Set timer</button>
    </div>
    <div class="timer-controls">
      <button class="btn primary" id="startBtn">Start</button>
      <button class="btn ghost" id="resetBtn">Reset</button>
    </div>
  </section>

  <div class="cluster foot" aria-hidden="true">
    <span class="gem g1 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#compass"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#compass"/></svg></span></span>
    <span class="gem g2 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#peak"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#peak"/></svg></span></span>
    <span class="gem g3 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#pine"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#pine"/></svg></span></span>
    <span class="gem g4 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#pine"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#pine"/></svg></span></span>
    <span class="gem g5 d3"><span class="d3i"><svg viewBox="0 0 100 100"><use href="#peak"/></svg><svg class="s2" viewBox="0 0 100 100"><use href="#peak"/></svg></span></span>
  </div>
</main>

<footer>
  <div class="made">Summit Kitchen</div>
  <small>&mdash; logged at base camp &bull; Summit Kitchen &#9650;</small>
</footer>

<!-- TOC dialog -->
<dialog id="tocPanel" aria-label="Recipe steps">
  <div class="sheet">
    <div class="sheet-head"><h3>Jump to&hellip;</h3><button class="icon-btn" data-close aria-label="Close">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></button></div>
    <ul class="toc" id="tocList"></ul>
  </div>
</dialog>

<!-- Settings dialog -->
<dialog id="setPanel" aria-label="Settings">
  <div class="sheet">
    <div class="sheet-head"><h3>Settings</h3><button class="icon-btn" data-close aria-label="Close">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></button></div>
    <div class="setting"><div><div class="t">Sparkles</div><div class="s">The drifting glitter behind the page</div></div>
      <label class="switch"><input type="checkbox" id="setSparkle" checked><span class="track"></span><span class="knob"></span></label></div>
    <div class="setting"><div><div class="t">Mark twinkle</div><div class="s">Checked steps twinkle every 20 seconds</div></div>
      <label class="switch"><input type="checkbox" id="setTwinkle" checked><span class="track"></span><span class="knob"></span></label></div>
    <div class="setting"><div><div class="t">Timer chime</div><div class="s">The bell when the timer finishes</div></div>
      <label class="switch"><input type="checkbox" id="setChime" checked><span class="track"></span><span class="knob"></span></label></div>
    <div class="setting"><div><div class="t">Larger text</div><div class="s">Easier to read across the kitchen</div></div>
      <label class="switch"><input type="checkbox" id="setLarge"><span class="track"></span><span class="knob"></span></label></div>
  </div>
</dialog>

<div id="burst"></div>
<div class="toast" id="toast"><svg class="gm" viewBox="0 0 100 100"><use href="#compass"/></svg><span id="toastMsg"></span></div>

<script>
(function(){
  "use strict";
  var reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------------- settings (persisted, degrades if storage blocked) ---------------- */
  var store = {
    get: function(k,d){ try{ var v=localStorage.getItem('hk_'+k); return v===null?d:v==='1'; }catch(e){ return d; } },
    set: function(k,v){ try{ localStorage.setItem('hk_'+k, v?'1':'0'); }catch(e){} }
  };
  var settings = {
    sparkle: store.get('sparkle', true),
    twinkle: store.get('twinkle', true),
    chime:   store.get('chime', true),
    large:   store.get('large', false)
  };
  function applySettings(){
    document.body.classList.toggle('no-sparkle', !settings.sparkle);
    document.body.classList.toggle('no-twinkle', !settings.twinkle);
    document.body.classList.toggle('large-text', settings.large);
    byId('setSparkle').checked = settings.sparkle;
    byId('setTwinkle').checked = settings.twinkle;
    byId('setChime').checked   = settings.chime;
    byId('setLarge').checked    = settings.large;
  }
  function byId(id){ return document.getElementById(id); }

  /* ---------------- sparkle field (canvas, cached sprite, DPR<=2) ---------------- */
  (function sparkleField(){
    var canvas = byId('sparkles');
    var ctx = canvas.getContext('2d', { alpha:true });
    // three warm gold tints so it reads as drifting embers, not plain white dots
    var TINTS = [[246,231,199],[201,162,78],[255,224,158]];
    var sprites = TINTS.map(function(rgb){
      var s=document.createElement('canvas'); s.width=s.height=24;
      var c=s.getContext('2d'); var g=c.createRadialGradient(12,12,0,12,12,12);
      g.addColorStop(0,'rgba('+rgb[0]+','+rgb[1]+','+rgb[2]+',1)');
      g.addColorStop(.4,'rgba('+rgb[0]+','+rgb[1]+','+rgb[2]+',.75)');
      g.addColorStop(1,'rgba('+rgb[0]+','+rgb[1]+','+rgb[2]+',0)');
      c.fillStyle=g; c.fillRect(0,0,24,24); return s;
    });
    var W,H,DPR,parts=[],raf=null,resizeT=0;
    function resize(){
      DPR=Math.min(window.devicePixelRatio||1,2);
      W=window.innerWidth; H=window.innerHeight;
      canvas.width=W*DPR; canvas.height=H*DPR;
      canvas.style.width=W+'px'; canvas.style.height=H+'px';
      ctx.setTransform(DPR,0,0,DPR,0,0);
      var count=Math.min(85,Math.round(W*H/9500));
      parts=Array.from({length:count},function(){
        return { x:Math.random()*W, y:Math.random()*H, r:3+Math.random()*9,
          base:.12+Math.random()*.5, speed:.35+Math.random()*1.0,
          phase:Math.random()*Math.PI*2, drift:(Math.random()-.5)*.05,
          rise:-(.05+Math.random()*.14), s:sprites[(Math.random()*sprites.length)|0] };
      });
    }
    function frame(t){
      ctx.clearRect(0,0,W,H);
      for(var i=0;i<parts.length;i++){ var p=parts[i];
        var a=p.base*(.45+.55*Math.sin(t*.001*p.speed+p.phase));
        p.x+=p.drift; p.y+=p.rise;
        if(p.y<-14) p.y=H+14; if(p.x<-14)p.x=W+14; if(p.x>W+14)p.x=-14;
        ctx.globalAlpha=a<0?0:a;
        ctx.drawImage(p.s,p.x-p.r,p.y-p.r,p.r*2,p.r*2);
      }
      raf=requestAnimationFrame(frame);
    }
    window.addEventListener('resize',function(){ clearTimeout(resizeT); resizeT=setTimeout(resize,150); });
    resize();
    function start(){ if(raf==null && !document.body.classList.contains('no-sparkle') && !reduceMotion) raf=requestAnimationFrame(frame); }
    function stop(){ if(raf!=null){ cancelAnimationFrame(raf); raf=null; } }
    if(reduceMotion){ frame(0); } else { start(); }
    document.addEventListener('visibilitychange',function(){ if(document.hidden) stop(); else start(); });
    // expose so the settings toggle can start/stop
    window.__sparkle={ start:start, stop:stop, redraw:function(){ if(reduceMotion) frame(0); } };
  })();

  /* ---------------- audio: elegant bell chime (Web Audio, Safari-safe unlock) ---------------- */
  var audioCtx=null, unlocked=false;
  function getCtx(){ if(!audioCtx){ var AC=window.AudioContext||window.webkitAudioContext; if(AC) audioCtx=new AC(); } return audioCtx; }
  function unlockAudio(){
    if(unlocked) return; var ctx=getCtx(); if(!ctx) return;
    try{ var b=ctx.createBuffer(1,1,22050); var s=ctx.createBufferSource(); s.buffer=b; s.connect(ctx.destination); s.start(0); }catch(e){}
    if(ctx.resume) ctx.resume().then(function(){ unlocked=true; }); else unlocked=true;
  }
  ['touchend','mousedown','click'].forEach(function(ev){ document.addEventListener(ev,unlockAudio,{once:true,passive:true}); });
  document.addEventListener('visibilitychange',function(){ if(!document.hidden && audioCtx && audioCtx.state!=='running' && audioCtx.resume) audioCtx.resume(); });
  function playChime(){
    if(!settings.chime) return; var ctx=getCtx(); if(!ctx) return;
    if(ctx.state!=='running' && ctx.resume) ctx.resume();
    var now=ctx.currentTime;
    function bell(delay,root){
      var t=now+delay; var master=ctx.createGain(); master.gain.value=.0001; master.connect(ctx.destination);
      master.gain.exponentialRampToValueAtTime(.3,t+.012); master.gain.exponentialRampToValueAtTime(.0001,t+2.4);
      [[root,1,1.6],[root*2.4,.34,1.1],[root*3.9,.16,.75],[root*5.3,.08,.5]].forEach(function(v){
        var osc=ctx.createOscillator(); osc.type='sine'; osc.frequency.value=v[0];
        var g=ctx.createGain(); g.gain.value=v[1]; g.gain.exponentialRampToValueAtTime(.0001,t+v[2]);
        osc.connect(g).connect(master); osc.start(t); osc.stop(t+v[2]+.1);
      });
    }
    // a gentle three-note fall, like a dinner bell
    bell(0,880); bell(.42,1174.66); bell(.9,987.77);
  }

  /* ---------------- confetti / sparkle burst (celebration) ---------------- */
  function burst(x,y,n){
    if(reduceMotion) return; var layer=byId('burst');
    for(var i=0;i<(n||18);i++){
      var el=document.createElement('span'); el.className='burst-p';
      var ang=Math.random()*Math.PI*2, dist=40+Math.random()*90, size=6+Math.random()*10;
      el.style.cssText='position:absolute;left:'+x+'px;top:'+y+'px;width:'+size+'px;height:'+size+'px;'+
        'margin:'+(-size/2)+'px 0 0 '+(-size/2)+'px;pointer-events:none;';
      el.innerHTML='<svg viewBox="0 0 24 24" width="100%" height="100%" style="color:'+(Math.random()<.5?'#C9A24E':'#2E5D46')+'"><use href="#spark"/></svg>';
      layer.appendChild(el);
      var dx=Math.cos(ang)*dist, dy=Math.sin(ang)*dist+30;
      el.animate([
        {transform:'translate(0,0) scale(.2) rotate(0deg)',opacity:1},
        {transform:'translate('+dx+'px,'+dy+'px) scale(1) rotate('+(Math.random()*220-110)+'deg)',opacity:0}
      ],{duration:900+Math.random()*500,easing:'cubic-bezier(.22,1,.36,1)'}).onfinish=function(){ this.effect.target.remove(); };
    }
  }

  /* ---------------- checkboxes: progress, twinkle, celebration ---------------- */
  var steps=[].slice.call(document.querySelectorAll('#stepList .step'));
  var ingredients=[].slice.call(document.querySelectorAll('#ingredientList .check-row'));
  var progressBar=byId('progressBar');
  function updateProgress(){
    var done=0; steps.forEach(function(s){ if(s.querySelector('input').checked) done++; });
    progressBar.style.width=(steps.length? (done/steps.length*100):0)+'%';
    var dc=byId('doneCount'); if(dc) dc.textContent=done+' of '+steps.length+' done';
    // reflect in TOC ticks
    steps.forEach(function(s,i){ var a=document.querySelector('#tocList a[data-step="'+i+'"]'); if(a) a.classList.toggle('checked', s.querySelector('input').checked); });
    return done;
  }
  function wire(row, isStep){
    var input=row.querySelector('input');
    input.addEventListener('change',function(){
      row.classList.toggle('done', input.checked);
      if(isStep){
        var done=updateProgress();
        if(done<steps.length) celebrated=false;   // re-arm so completing again re-celebrates
        if(input.checked){
          var badge=row.querySelector('.badge'); var r=badge.getBoundingClientRect();
          burst(r.left+r.width/2, r.top+r.height/2, 14);
          if(done===steps.length){ celebrate(); }
        }
      } else if(input.checked){
        var b=row.querySelector('.check').getBoundingClientRect(); burst(b.left+b.width/2,b.top+b.height/2,8);
      }
    });
  }
  steps.forEach(function(s,i){
    var t=s.querySelector('.body p').textContent.trim();
    s.querySelector('input').setAttribute('aria-label','Step '+(i+1)+': '+(t.length>60?t.slice(0,60)+'…':t));
    wire(s,true);
  });
  ingredients.forEach(function(r){
    r.querySelector('input').setAttribute('aria-label', r.querySelector('.label').textContent.trim());
    wire(r,false);
  });

  /* ---------------- extra interactivity ---------------- */
  // tap anywhere on a step's words to check it off (but not while selecting text)
  steps.forEach(function(s){
    s.querySelector('.body').addEventListener('click', function(){
      if(window.getSelection && String(window.getSelection())) return;
      var i=s.querySelector('input'); i.checked=!i.checked; i.dispatchEvent(new Event('change',{bubbles:true}));
    });
  });
  // tappable decorative diamonds — a sparkle and a happy little spin
  [].slice.call(document.querySelectorAll('.showcase .big, .section-head .gem, .brand .brand-mark')).forEach(function(g){
    g.style.cursor='pointer';
    g.addEventListener('click', function(e){
      e.stopPropagation();
      var r=g.getBoundingClientRect(); burst(r.left+r.width/2, r.top+r.height/2, 12);
      if(!reduceMotion){ try{ g.animate([{transform:'scale(1)'},{transform:'scale(1.35)'},{transform:'scale(1)'}],{duration:520,easing:'cubic-bezier(.34,1.56,.64,1)'}); }catch(_){ } }
    });
  });
  // start over — uncheck every step with a little poof
  (function(){ var rs=byId('resetSteps'); if(!rs) return;
    rs.addEventListener('click', function(){
      celebrated=false;
      steps.forEach(function(s){ var i=s.querySelector('input'); if(i.checked){ i.checked=false; s.classList.remove('done'); } });
      updateProgress();
      var r=rs.getBoundingClientRect(); burst(r.left+r.width/2, r.top, 10);
      showToast('Fresh start ✦');
    });
  })();

  var celebrated=false;
  function celebrate(){
    if(celebrated) return; celebrated=true;
    playChime();
    var cx=window.innerWidth/2, cy=window.innerHeight*.4;
    burst(cx,cy,30); setTimeout(function(){ burst(cx-60,cy+20,18); burst(cx+60,cy+10,18); },160);
    showToast('Every step done — summit reached! ▲');
  }

  /* ---------------- toast ---------------- */
  var toastT=0;
  function showToast(msg){ var t=byId('toast'); byId('toastMsg').textContent=msg; t.classList.add('show');
    clearTimeout(toastT); toastT=setTimeout(function(){ t.classList.remove('show'); },2600); }

  /* ---------------- timer ---------------- */
  var clockEl=byId('clock'), startBtn=byId('startBtn'), resetBtn=byId('resetBtn'),
      timerCard=byId('timerCard');
  var totalMs=10*60*1000, endAt=0, remaining=totalMs, running=false, tick=null;
  function fmt(ms){ ms=Math.max(0,ms); var s=Math.round(ms/1000); var m=(s/60)|0; s=s%60;
    return m+':'+(s<10?'0':'')+s; }
  function renderClock(){ clockEl.textContent=fmt(remaining); }
  function setDuration(min){ stopTimer(); totalMs=Math.round(min*60*1000); remaining=totalMs; timerCard.classList.remove('done'); renderClock(); }
  function startTimer(){
    if(running) return; if(remaining<=0){ remaining=totalMs; }
    unlockAudio(); running=true; timerCard.classList.remove('done');
    endAt=Date.now()+remaining; startBtn.textContent='Pause';
    tick=setInterval(function(){
      remaining=endAt-Date.now();
      if(remaining<=0){ remaining=0; renderClock(); finishTimer(); return; }
      renderClock();
    },250);
  }
  function pauseTimer(){ if(!running) return; running=false; clearInterval(tick); tick=null;
    remaining=endAt-Date.now(); startBtn.textContent='Start'; renderClock(); }
  function stopTimer(){ running=false; if(tick){ clearInterval(tick); tick=null; } startBtn.textContent='Start'; }
  function resetTimer(){ stopTimer(); remaining=totalMs; timerCard.classList.remove('done'); renderClock(); }
  function finishTimer(){ stopTimer(); timerCard.classList.add('done'); startBtn.textContent='Start';
    playChime(); var r=timerCard.getBoundingClientRect(); burst(window.innerWidth/2, r.top+70, 26);
    showToast("Ding! Your timer's up. ▲"); }
  startBtn.addEventListener('click',function(){ running?pauseTimer():startTimer(); });
  resetBtn.addEventListener('click',resetTimer);
  // presets
  var presetWrap=byId('presets'), customRow=byId('customRow'), customInput=byId('customInput'),
      customSet=byId('customSet'), customChip=byId('customChip');
  presetWrap.addEventListener('click',function(e){
    var chip=e.target.closest('.chip'); if(!chip) return;
    if(chip.id==='customChip'){
      // Inline input, not prompt() — prompt() is unreliable in the Messages in-app browser.
      if(customRow.hasAttribute('hidden')){
        customRow.removeAttribute('hidden'); customInput.value=String(Math.round(totalMs/60000));
        customInput.focus(); customChip.classList.add('sel');
      } else { customRow.setAttribute('hidden',''); }
      return;
    }
    customRow.setAttribute('hidden','');
    setSel(chip); setDuration(parseFloat(chip.getAttribute('data-min')));
  });
  function applyCustom(){
    var m=parseFloat(customInput.value);
    if(!isNaN(m)&&m>0&&m<=600){ setSel(null); customChip.classList.add('sel'); setDuration(m); customRow.setAttribute('hidden',''); }
    else { customInput.focus(); }
  }
  customSet.addEventListener('click',applyCustom);
  customInput.addEventListener('keydown',function(e){ if(e.key==='Enter'){ e.preventDefault(); applyCustom(); } });
  function setSel(chip){ [].slice.call(presetWrap.querySelectorAll('.chip')).forEach(function(c){ c.classList.remove('sel'); }); if(chip) chip.classList.add('sel'); }
  renderClock();

  /* ---------------- TOC ---------------- */
  var tocList=byId('tocList');
  (function buildTOC(){
    function add(label,href,cls,idxHTML,stepIdx){
      var li=document.createElement('li'); var a=document.createElement('a');
      a.href=href; if(cls) a.className=cls; if(stepIdx!=null) a.setAttribute('data-step',stepIdx);
      a.innerHTML=(idxHTML||'')+'<span class="lbl">'+label+'</span><span class="tick"><svg width="16" height="16" viewBox="0 0 100 100"><use href="#compass"/></svg></span>';
      li.appendChild(a); tocList.appendChild(li);
    }
    add('Ingredients','#ingredients','section-link','<span class="idx">&#10022;</span>');
    add('Method','#method','section-link','<span class="idx">&#10022;</span>');
    steps.forEach(function(s,i){
      var txt=s.querySelector('.body p').textContent.trim(); if(txt.length>52) txt=txt.slice(0,52).replace(/\s+\S*$/,'')+'…';
      add(txt,'#step-'+i,'','<span class="idx">'+(i+1)+'</span>',i);
      s.id='step-'+i;
    });
    if(document.getElementById('notes')) add('Notes','#notes','section-link','<span class="idx">&#10022;</span>');
    if(document.getElementById('timerCard')) add('Kitchen timer','#timerCard','section-link','<span class="idx">&#10022;</span>');
  })();
  tocList.addEventListener('click',function(e){ var a=e.target.closest('a'); if(!a) return; closeDialog(byId('tocPanel')); });

  /* ---------------- dialogs ---------------- */
  function openDialog(d){ if(typeof d.showModal==='function'){ d.showModal(); } else { d.setAttribute('open',''); } }
  function closeDialog(d){ if(typeof d.close==='function'){ try{ d.close(); }catch(e){ d.removeAttribute('open'); } } else { d.removeAttribute('open'); } }
  byId('tocBtn').addEventListener('click',function(){ openDialog(byId('tocPanel')); });
  byId('setBtn').addEventListener('click',function(){ openDialog(byId('setPanel')); });
  document.querySelectorAll('[data-close]').forEach(function(b){ b.addEventListener('click',function(){ closeDialog(b.closest('dialog')); }); });
  // click on backdrop closes
  document.querySelectorAll('dialog').forEach(function(d){
    d.addEventListener('click',function(e){ if(e.target===d) closeDialog(d); });
  });

  /* ---------------- settings wiring ---------------- */
  byId('setSparkle').addEventListener('change',function(){ settings.sparkle=this.checked; store.set('sparkle',this.checked);
    document.body.classList.toggle('no-sparkle',!this.checked); if(this.checked){ window.__sparkle.start(); window.__sparkle.redraw(); } else window.__sparkle.stop(); });
  byId('setTwinkle').addEventListener('change',function(){ settings.twinkle=this.checked; store.set('twinkle',this.checked);
    document.body.classList.toggle('no-twinkle',!this.checked); });
  byId('setChime').addEventListener('change',function(){ settings.chime=this.checked; store.set('chime',this.checked); if(this.checked){ unlockAudio(); playChime(); } });
  byId('setLarge').addEventListener('change',function(){ settings.large=this.checked; store.set('large',this.checked);
    document.body.classList.toggle('large-text',this.checked); });

  applySettings();
  updateProgress();

  // live reduced-motion change: simplest correct behavior is a reload
  try{ matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',function(){ location.reload(); }); }catch(e){}
})();
</script>
</body>
</html>

"""#
