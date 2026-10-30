// Exact 18-Gesture Library Engine Matching Native Swipy macOS App
(function () {
  const ICONS = {
    'hand.point.up.left': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M10 11V4a2 2 0 0 1 4 0v7m0-3a2 2 0 0 1 4 0v2m0-1a2 2 0 0 1 4 0v5a6 6 0 0 1-6 6h-3a6 6 0 0 1-5.2-3L5.4 13a1.8 1.8 0 0 1 2.5-2.3L10 12"/></svg>',
    'hand.pinch': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 9c2.5 0 4.5 1.5 4.5 3.5S10.5 16 8 16m6-11a4 4 0 0 1 0 8M5 5l3 3m0-3L5 8m12 6c0 3-2.5 5.5-5.5 5.5S6 17 6 14"/></svg>',
    'hand.draw': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v12m0 0-3-3m3 3 3-3M4 19h16M7 15h.01M17 15h.01"/></svg>',
    'hand.tap.fill': '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="5" r="3"/><path d="M10 9a2 2 0 0 1 4 0v5h3a3 3 0 0 1 3 3v3a2 2 0 0 1-2 2H9a4 4 0 0 1-3.5-2l-2-3.5a1.5 1.5 0 0 1 2.2-1.8L10 16V9z"/></svg>',
    'hand.tap': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5a4 4 0 0 1 8 0M10 9a2 2 0 0 1 4 0v5h3a3 3 0 0 1 3 3v3a2 2 0 0 1-2 2H9a4 4 0 0 1-3.5-2l-2-3.5a1.5 1.5 0 0 1 2.2-1.8L10 16V9z"/></svg>',
    'hand.tap.2': '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="9" cy="4" r="2.5"/><circle cx="15" cy="4" r="2.5"/><path d="M8 9v7l-2-2a1.5 1.5 0 0 0-2.1 2.1l4.1 4.1A5 5 0 0 0 11.5 22h4a5 5 0 0 0 5-5v-6a2 2 0 0 0-2-2v-1a2 2 0 0 0-2-2v1a2 2 0 0 0-2-2v1a2 2 0 0 0-2-2H8z"/></svg>',
    'arrow.up.and.down': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v18m0-18-4 4m4-4 4 4m-4 14-4-4m4 4 4-4"/></svg>',
    'arrow.up': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 19V5m0 0-6 6m6-6 6 6"/></svg>',
    'arrow.down': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v14m0 0-6-6m6 6 6-6"/></svg>',
    'arrow.left': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M19 12H5m0 0 6-6m-6 6 6 6"/></svg>',
    'arrow.right': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14m0 0-6-6m6 6-6 6"/></svg>',
    'square.grid.2x2': '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>',
    'square.grid.2x2.fill': '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="3" width="7" height="7" fill="currentColor"/><rect x="14" y="3" width="7" height="7" fill="currentColor"/><rect x="3" y="14" width="7" height="7" fill="currentColor"/><rect x="14" y="14" width="7" height="7" fill="currentColor"/></svg>',
    'v.circle': '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m8 8 4 8 4-8"/></svg>',
    'plus.magnifyingglass': '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5M11 8v6m-3-3h6"/></svg>',
    'arrow.up.left.and.arrow.down.right': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 10V4h6M4 4l7 7m9 3v6h-6m6 0-7-7"/></svg>',
    'hand.raised': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 13V5a1.5 1.5 0 0 1 3 0v6m0-7a1.5 1.5 0 0 1 3 0v7m0-6a1.5 1.5 0 0 1 3 0v7m0-4.5a1.5 1.5 0 0 1 3 0V15a6 6 0 0 1-6 6h-2a6 6 0 0 1-5-2.7L4.3 14a1.5 1.5 0 0 1 2.4-1.8L8 13z"/></svg>',
    'lock.fill': '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2" fill="currentColor"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>'
  };

  const GESTURES = [
    { name: 'Index Pointing', action: 'Point & Glide Cursor', category: 'Cursor & Clicks', symbol: 'hand.point.up.left', enabled: true },
    { name: 'Thumb-Index Pinch', action: 'Left Click', category: 'Cursor & Clicks', symbol: 'hand.pinch', enabled: true },
    { name: 'Pinch & Drag', action: 'Drag and Drop', category: 'Cursor & Clicks', symbol: 'hand.draw', enabled: true },
    { name: 'Double Pinch', action: 'Double Click', category: 'Cursor & Clicks', symbol: 'hand.tap.fill', enabled: true },
    { name: 'Thumb-Middle Pinch', action: 'Right Click', category: 'Cursor & Clicks', symbol: 'hand.tap', enabled: true },
    { name: 'Two-Finger Tap', action: 'Right Click', category: 'Cursor & Clicks', symbol: 'hand.tap.2', enabled: true },
    { name: 'Two-Finger Scroll', action: 'Scroll', category: 'Scrolling', symbol: 'arrow.up.and.down', enabled: true },
    { name: 'Three-Finger Swipe Up', action: 'Mission Control', category: 'Space Navigation', symbol: 'arrow.up', enabled: true },
    { name: 'Three-Finger Swipe Down', action: 'Show Desktop', category: 'Space Navigation', symbol: 'arrow.down', enabled: true },
    { name: 'Three-Finger Swipe Left', action: 'Next Space', category: 'Space Navigation', symbol: 'arrow.left', enabled: true },
    { name: 'Three-Finger Swipe Right', action: 'Previous Space', category: 'Space Navigation', symbol: 'arrow.right', enabled: true },
    { name: 'Four-Finger Swipe Left', action: 'Next Space', category: 'App Switching', symbol: 'square.grid.2x2', enabled: true },
    { name: 'Four-Finger Swipe Right', action: 'Previous Space', category: 'App Switching', symbol: 'square.grid.2x2.fill', enabled: true },
    { name: 'Peace / V-Sign', action: 'Toggle App Switcher', category: 'App Switching', symbol: 'v.circle', enabled: true },
    { name: 'Thumb-Middle Zoom', action: 'Zoom In / Out', category: 'Two-Hand Controls', symbol: 'plus.magnifyingglass', enabled: true },
    { name: 'Two-Hand Zoom', action: 'Zoom In / Out', category: 'Two-Hand Controls', symbol: 'arrow.up.left.and.arrow.down.right', enabled: true },
    { name: 'Open Palms Hold', action: 'Pause / Resume', category: 'Safety Controls', symbol: 'hand.raised', enabled: true },
    { name: 'Closed Fist Freeze', action: 'Pause / Resume', category: 'Safety Controls', symbol: 'lock.fill', enabled: true }
  ];

  const CATEGORIES = [
    'All',
    'Cursor & Clicks',
    'Scrolling',
    'Space Navigation',
    'App Switching',
    'Two-Hand Controls',
    'Safety Controls'
  ];

  function initGestureLibrary() {
    const filterContainer = document.getElementById('gesture-filter-bar');
    const cardsContainer = document.getElementById('gesture-cards-grid');
    if (!filterContainer || !cardsContainer) return;

    let selectedCategory = 'All';

    function updateWithTransition(fn) {
      if (document.startViewTransition) {
        document.startViewTransition(fn);
      } else {
        fn();
      }
    }

    function renderFilters() {
      filterContainer.innerHTML = '';
      CATEGORIES.forEach(function (cat) {
        const count = cat === 'All'
          ? GESTURES.length
          : GESTURES.filter(function (g) { return g.category === cat; }).length;
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'library-filter-pill';
        btn.setAttribute('aria-pressed', String(selectedCategory === cat));
        btn.textContent = cat + ' (' + count + ')';
        btn.addEventListener('click', function () {
          selectedCategory = cat;
          updateWithTransition(function () {
            renderFilters();
            renderCards();
          });
        });
        filterContainer.appendChild(btn);
      });
    }

    function renderCards() {
      cardsContainer.innerHTML = '';
      const filtered = selectedCategory === 'All'
        ? GESTURES
        : GESTURES.filter(function (g) { return g.category === selectedCategory; });

      filtered.forEach(function (item) {
        const card = document.createElement('article');
        card.className = 'native-gesture-card tilt-card';
        const svgMarkup = ICONS[item.symbol] || ICONS['hand.point.up.left'];
        card.innerHTML =
          '<div class="native-gesture-top">' +
            '<div class="native-gesture-icon">' + svgMarkup + '</div>' +
            '<button type="button" class="native-gesture-switch" role="switch" aria-checked="' + String(item.enabled) + '" aria-label="Toggle ' + item.name + '"></button>' +
          '</div>' +
          '<div>' +
            '<h3 class="native-gesture-title">' + item.name + '</h3>' +
            '<p class="native-gesture-action">' + item.action + '</p>' +
          '</div>' +
          '<div class="native-gesture-footer">' +
            '<span class="native-category-badge">' + item.category + '</span>' +
            '<span class="native-status-label' + (item.enabled ? '' : ' is-paused') + '">' + (item.enabled ? 'Active' : 'Paused') + '</span>' +
          '</div>';

        const switchBtn = card.querySelector('.native-gesture-switch');
        const statusEl = card.querySelector('.native-status-label');
        if (switchBtn && statusEl) {
          switchBtn.addEventListener('click', function () {
            item.enabled = !item.enabled;
            switchBtn.setAttribute('aria-checked', String(item.enabled));
            statusEl.textContent = item.enabled ? 'Active' : 'Paused';
            statusEl.classList.toggle('is-paused', !item.enabled);
          });
        }

        cardsContainer.appendChild(card);
      });
    }

    renderFilters();
    renderCards();
  }

  document.addEventListener('DOMContentLoaded', initGestureLibrary);
})();
