// Horizontal-to-Vertical Scroll Twist & Keeby Hardware Showcase Engine
(function () {
  function initScrollTwistEngine() {
    const stage = document.getElementById('horizontal-stage');
    const track = document.getElementById('horizontal-track');
    const axisReadout = document.getElementById('nav-axis-mode');
    const coordReadout = document.getElementById('nav-coord-readout');
    const keebyScreenImg = document.getElementById('keeby-active-screen');
    const keebySteps = document.querySelectorAll('[data-screen-src]');
    const revealBlocks = document.querySelectorAll('.reveal-block');

    let currentX = 0;
    let targetX = 0;

    function onScrollFrame() {
      const scrollY = window.scrollY || window.pageYOffset;
      const vw = window.innerWidth;
      const vh = window.innerHeight;

      if (stage && track && vw > 960) {
        const rect = stage.getBoundingClientRect();
        const scrollableDistance = Math.max(1, stage.offsetHeight - vh);
        const rawProgress = -rect.top / scrollableDistance;
        const clamped = Math.max(0, Math.min(1, rawProgress));

        const maxTranslatePx = track.scrollWidth - vw;
        targetX = clamped * maxTranslatePx;
        currentX += (targetX - currentX) * 0.14;

        const velocitySkew = Math.max(-1.8, Math.min(1.8, (targetX - currentX) * 0.015));
        track.style.transform = 'translate3d(' + (-currentX.toFixed(1)) + 'px, 0, 0) skewX(' + velocitySkew.toFixed(2) + 'deg)';

        if (axisReadout) {
          axisReadout.textContent = clamped < 0.96
            ? 'AXIS // HORIZONTAL GLIDE'
            : 'AXIS // VERTICAL PIVOT';
        }
        if (coordReadout) {
          coordReadout.textContent = 'X:' + String(Math.round(currentX)).padStart(4, '0') + ' Y:' + String(Math.round(scrollY)).padStart(4, '0');
        }
      }

      requestAnimationFrame(onScrollFrame);
    }

    if ('IntersectionObserver' in window) {
      const revealObserver = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
          }
        });
      }, { threshold: 0.14 });

      revealBlocks.forEach(function (el) {
        revealObserver.observe(el);
      });

      const stepObserver = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting && keebyScreenImg) {
            const nextSrc = entry.target.getAttribute('data-screen-src');
            const nextAlt = entry.target.getAttribute('data-screen-alt');
            if (nextSrc && keebyScreenImg.getAttribute('src') !== nextSrc) {
              keebyScreenImg.src = nextSrc;
              if (nextAlt) keebyScreenImg.alt = nextAlt;
            }
          }
        });
      }, { threshold: 0.45 });

      keebySteps.forEach(function (step) {
        stepObserver.observe(step);
      });
    } else {
      revealBlocks.forEach(function (el) {
        el.classList.add('is-visible');
      });
    }

    requestAnimationFrame(onScrollFrame);
  }

  document.addEventListener('DOMContentLoaded', initScrollTwistEngine);
})();
