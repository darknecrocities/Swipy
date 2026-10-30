// Horizontal Carousel, Quick-Jump AppBar & Keeby Screen Morph Engine
(function () {
  function initScrollTwistEngine() {
    const stage = document.getElementById('horizontal-stage');
    const track = document.getElementById('horizontal-track');
    const testItOutStage = document.getElementById('test-it-out');
    const verticalStage = document.getElementById('vertical-stage');
    const gestureLibrary = document.getElementById('gesture-library');
    const keebyScreenImg = document.getElementById('keeby-active-screen');
    const keebySteps = document.querySelectorAll('.keeby-step-card[data-screen-src]');
    const revealBlocks = document.querySelectorAll('.reveal-block');
    const navButtons = document.querySelectorAll('[data-nav-target]');
    const prevBtn = document.getElementById('carousel-prev-btn');
    const nextBtn = document.getElementById('carousel-next-btn');

    const HORIZ_STATIONS = ['station-01', 'station-02', 'station-03'];
    let currentX = 0;
    let targetX = 0;
    let activeStationIdx = 0;

    function getHorizontalScrollableDistance() {
      if (!stage) return 1;
      return Math.max(1, stage.offsetHeight - window.innerHeight);
    }

    function setActiveNav(targetKey) {
      navButtons.forEach(function (btn) {
        if (!btn.classList.contains('nav-pill-btn') && !btn.classList.contains('carousel-dot-pill')) return;
        const isMatch = btn.getAttribute('data-nav-target') === targetKey;
        btn.setAttribute('aria-current', isMatch ? 'true' : 'false');
      });
    }

    function scrollToSection(targetKey) {
      const vw = window.innerWidth;
      const horizDistance = getHorizontalScrollableDistance();

      if (vw > 960 && stage && track) {
        const maxTranslate = Math.max(1, track.scrollWidth - vw);
        if (targetKey === 'station-01') {
          window.scrollTo({ top: 0, behavior: 'smooth' });
          return;
        }
        if (targetKey === 'station-02') {
          const st2 = document.getElementById('station-02');
          const ratio = st2 ? Math.min(1, st2.offsetLeft / maxTranslate) : 0.5;
          window.scrollTo({ top: ratio * horizDistance, behavior: 'smooth' });
          return;
        }
        if (targetKey === 'station-03') {
          const st3 = document.getElementById('station-03');
          const ratio = st3 ? Math.min(1, st3.offsetLeft / maxTranslate) : 0.98;
          window.scrollTo({ top: ratio * horizDistance, behavior: 'smooth' });
          return;
        }
      }

      const targetEl = document.getElementById(targetKey);
      if (targetEl) {
        const y = targetEl.getBoundingClientRect().top + (window.scrollY || window.pageYOffset) - 68;
        window.scrollTo({ top: Math.max(0, y), behavior: 'smooth' });
      }
    }

    navButtons.forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        const key = btn.getAttribute('data-nav-target');
        if (key) {
          e.preventDefault();
          scrollToSection(key);
        }
      });
    });

    if (prevBtn) {
      prevBtn.addEventListener('click', function () {
        const nextIdx = Math.max(0, activeStationIdx - 1);
        scrollToSection(HORIZ_STATIONS[nextIdx]);
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener('click', function () {
        if (activeStationIdx < HORIZ_STATIONS.length - 1) {
          scrollToSection(HORIZ_STATIONS[activeStationIdx + 1]);
        } else {
          scrollToSection('test-it-out');
        }
      });
    }

    window.addEventListener('wheel', function (e) {
      if (window.innerWidth <= 960 || !stage) return;
      const scrollY = window.scrollY || window.pageYOffset;
      const horizDistance = getHorizontalScrollableDistance();
      if (scrollY <= horizDistance + 40 && Math.abs(e.deltaX) > Math.abs(e.deltaY)) {
        window.scrollBy(0, e.deltaX);
        e.preventDefault();
      }
    }, { passive: false });

    function morphKeebyScreen(stepEl) {
      keebySteps.forEach(function (card) {
        card.setAttribute('data-active', card === stepEl ? 'true' : 'false');
      });
      if (!keebyScreenImg) return;
      const nextSrc = stepEl.getAttribute('data-screen-src');
      const nextAlt = stepEl.getAttribute('data-screen-alt');
      if (!nextSrc || keebyScreenImg.getAttribute('src') === nextSrc) return;

      const applySwap = function () {
        keebyScreenImg.classList.add('is-morphing');
        setTimeout(function () {
          keebyScreenImg.src = nextSrc;
          if (nextAlt) keebyScreenImg.alt = nextAlt;
          keebyScreenImg.classList.remove('is-morphing');
        }, 150);
      };

      if (document.startViewTransition) {
        document.startViewTransition(applySwap);
      } else {
        applySwap();
      }
    }

    keebySteps.forEach(function (stepEl) {
      stepEl.addEventListener('click', function () {
        morphKeebyScreen(stepEl);
      });
    });

    function onScrollFrame() {
      const vw = window.innerWidth;
      const vh = window.innerHeight;

      if (stage && track && vw > 960) {
        const rect = stage.getBoundingClientRect();
        const scrollableDistance = getHorizontalScrollableDistance();
        const rawProgress = -rect.top / scrollableDistance;
        const clamped = Math.max(0, Math.min(1, rawProgress));

        const maxTranslatePx = Math.max(0, track.scrollWidth - vw);
        targetX = clamped * maxTranslatePx;
        currentX += (targetX - currentX) * 0.16;

        const velocitySkew = Math.max(-1.4, Math.min(1.4, (targetX - currentX) * 0.012));
        track.style.transform =
          'translate3d(' + (-currentX.toFixed(1)) + 'px, 0, 0) skewX(' + velocitySkew.toFixed(2) + 'deg)';

        if (clamped >= 0.72) activeStationIdx = 2;
        else if (clamped >= 0.32) activeStationIdx = 1;
        else activeStationIdx = 0;

        if (gestureLibrary && gestureLibrary.getBoundingClientRect().top <= vh * 0.45) {
          setActiveNav('gesture-library');
        } else if (verticalStage && verticalStage.getBoundingClientRect().top <= vh * 0.45) {
          setActiveNav('vertical-stage');
        } else if (testItOutStage && testItOutStage.getBoundingClientRect().top <= vh * 0.48) {
          setActiveNav('test-it-out');
        } else {
          setActiveNav(HORIZ_STATIONS[activeStationIdx]);
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
      }, { threshold: 0.12 });

      revealBlocks.forEach(function (el) {
        revealObserver.observe(el);
      });

      const stepObserver = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            morphKeebyScreen(entry.target);
          }
        });
      }, { threshold: 0.52 });

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
