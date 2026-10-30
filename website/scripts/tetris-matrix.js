// Swipy Interactive Hand Pose Matrix & "Test It Out?" Pinch/Swipe Sandbox Engine
(function () {
  const GRID_SIZE = 15;
  const POSES = [
    {
      label: 'OPEN PALM',
      cells: [
        [3,1],[3,2],[3,3],[3,4],[6,0],[6,1],[6,2],[6,3],[6,4],
        [9,1],[9,2],[9,3],[9,4],[12,2],[12,3],[12,4],
        [4,5],[5,5],[6,5],[7,5],[8,5],[9,5],[10,5],[11,5],
        [4,6],[5,6],[6,6],[7,6],[8,6],[9,6],[10,6],[11,6],
        [1,6],[2,7],[3,7],[4,7],[5,7],[6,7],[7,7],[8,7],[9,7],[10,7],[11,7],
        [5,8],[6,8],[7,8],[8,8],[9,8],[10,8],
        [5,9],[6,9],[7,9],[8,9],[9,9],[6,10],[7,10],[8,10],[6,11],[7,11],[8,11]
      ]
    },
    {
      label: 'INDEX POINT',
      cells: [
        [7,0],[7,1],[7,2],[7,3],[7,4],[7,5],[7,6],
        [5,6],[6,6],[8,6],[9,6],
        [4,7],[5,7],[6,7],[7,7],[8,7],[9,7],[10,7],
        [4,8],[5,8],[6,8],[7,8],[8,8],[9,8],[10,8],
        [5,9],[6,9],[7,9],[8,9],[9,9],
        [6,10],[7,10],[8,10],[6,11],[7,11],[8,11]
      ]
    },
    {
      label: 'PINCH & DRAG',
      cells: [
        [5,2],[6,2],[7,3],[8,4],[8,5],
        [4,4],[5,5],[6,5],[7,5],
        [5,6],[6,6],[7,6],[8,6],[9,6],[10,6],
        [5,7],[6,7],[7,7],[8,7],[9,7],[10,7],
        [6,8],[7,8],[8,8],[9,8],[6,9],[7,9],[8,9],[6,10],[7,10],[8,10]
      ]
    },
    {
      label: '4-FINGER SWIPE',
      cells: [
        [2,2],[2,3],[2,4],[2,5],[5,1],[5,2],[5,3],[5,4],[5,5],
        [8,1],[8,2],[8,3],[8,4],[8,5],[11,2],[11,3],[11,4],[11,5],
        [3,6],[4,6],[5,6],[6,6],[7,6],[8,6],[9,6],[10,6],
        [4,7],[5,7],[6,7],[7,7],[8,7],[9,7],
        [5,8],[6,8],[7,8],[8,8],[6,9],[7,9]
      ]
    }
  ];

  function initDotMatrixOrb() {
    const canvas = document.getElementById('dot-matrix-canvas');
    const captionEl = document.getElementById('dot-matrix-label');
    const orbShell = document.getElementById('dot-matrix-orb');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let activePoseIndex = 0;
    let tick = 0;

    function render() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const cellSize = canvas.width / GRID_SIZE;
      const pose = POSES[activePoseIndex];
      const activeSet = new Set(pose.cells.map(function (c) { return c[0] + ',' + c[1]; }));
      const center = (GRID_SIZE - 1) / 2;

      for (let y = 0; y < GRID_SIZE; y++) {
        for (let x = 0; x < GRID_SIZE; x++) {
          const dx = x - center;
          const dy = y - center;
          if (Math.sqrt(dx * dx + dy * dy) > 7.1) continue;

          const key = x + ',' + y;
          const isLit = activeSet.has(key);
          const pulse = Math.sin((tick * 0.07) + (x * 0.4) + (y * 0.3)) > 0.88;

          ctx.fillStyle = isLit ? '#FFFFFF' : (pulse ? '#333333' : '#181818');
          const pad = 2;
          ctx.fillRect(x * cellSize + pad, y * cellSize + pad, cellSize - pad * 2, cellSize - pad * 2);
        }
      }
      tick++;
      requestAnimationFrame(render);
    }

    function cyclePose() {
      activePoseIndex = (activePoseIndex + 1) % POSES.length;
      if (captionEl) captionEl.textContent = POSES[activePoseIndex].label;
    }

    if (orbShell) orbShell.addEventListener('click', cyclePose);
    setInterval(cyclePose, 3200);
    render();
  }

  function initInteractiveSandbox() {
    const screen = document.getElementById('sandbox-screen');
    const stageCanvas = document.getElementById('sandbox-stage-canvas');
    const reticle = document.getElementById('sandbox-reticle');
    const reticleLabel = document.getElementById('sandbox-reticle-label');
    const gestureBadge = document.getElementById('sandbox-gesture-badge');
    const spaceIndicator = document.getElementById('sandbox-space-indicator');
    const cards = document.querySelectorAll('.sandbox-draggable-card');
    const actionBtns = document.querySelectorAll('[data-sandbox-action]');
    if (!screen || !stageCanvas) return;

    const SPACES = [
      'SPACE 01 // CREATIVE DESKTOP',
      'SPACE 02 // CODE & TERMINAL',
      'SPACE 03 // POINTER STUDIO'
    ];
    let currentSpaceIndex = 0;
    let activeCard = null;
    let offsetX = 0;
    let offsetY = 0;
    let initialPositions = [];

    cards.forEach(function (card) {
      initialPositions.push({
        el: card,
        left: card.style.left,
        top: card.style.top
      });

      card.addEventListener('pointerdown', function (e) {
        e.stopPropagation();
        activeCard = card;
        card.classList.add('is-pinched');
        if (reticle) reticle.classList.add('is-pinching');
        if (reticleLabel) reticleLabel.textContent = 'PINCH & DRAG';
        if (gestureBadge) gestureBadge.textContent = 'PINCH & DRAG // LOCKED ON WINDOW';

        const cardRect = card.getBoundingClientRect();
        offsetX = e.clientX - cardRect.left;
        offsetY = e.clientY - cardRect.top;
        card.setPointerCapture(e.pointerId);
      });
    });

    screen.addEventListener('pointermove', function (e) {
      const screenRect = stageCanvas.getBoundingClientRect();
      const relX = e.clientX - screenRect.left;
      const relY = e.clientY - screenRect.top;

      if (reticle) {
        reticle.style.left = Math.max(20, Math.min(screenRect.width - 20, relX)) + 'px';
        reticle.style.top = Math.max(20, Math.min(screenRect.height - 20, relY)) + 'px';
      }

      if (activeCard) {
        const nextLeft = Math.max(8, Math.min(screenRect.width - activeCard.offsetWidth - 8, relX - offsetX));
        const nextTop = Math.max(8, Math.min(screenRect.height - activeCard.offsetHeight - 8, relY - offsetY));
        activeCard.style.left = nextLeft + 'px';
        activeCard.style.top = nextTop + 'px';
      }
    });

    window.addEventListener('pointerup', function () {
      if (activeCard) {
        activeCard.classList.remove('is-pinched');
        activeCard = null;
      }
      if (reticle) reticle.classList.remove('is-pinching');
      if (reticleLabel) reticleLabel.textContent = 'POINT';
      if (gestureBadge) gestureBadge.textContent = 'INDEX POINT // GLIDING';
    });

    function switchSpace(delta) {
      stageCanvas.classList.remove('is-mission-control');
      currentSpaceIndex = (currentSpaceIndex + delta + SPACES.length) % SPACES.length;
      if (spaceIndicator) spaceIndicator.textContent = SPACES[currentSpaceIndex];
      if (gestureBadge) {
        gestureBadge.textContent = delta > 0
          ? '4-FINGER SWIPE LEFT // NEXT SPACE'
          : '4-FINGER SWIPE RIGHT // PREVIOUS SPACE';
      }
      if (reticleLabel) reticleLabel.textContent = '4-FINGER SWIPE';

      const slideDir = delta > 0 ? -36 : 36;
      stageCanvas.style.transform = 'translateX(' + slideDir + 'px)';
      setTimeout(function () {
        stageCanvas.style.transform = 'translateX(0)';
      }, 220);
    }

    actionBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        const action = btn.getAttribute('data-sandbox-action');
        if (action === 'next-space') switchSpace(1);
        if (action === 'prev-space') switchSpace(-1);
        if (action === 'mission-control') {
          stageCanvas.classList.toggle('is-mission-control');
          if (gestureBadge) gestureBadge.textContent = '3-FINGER SWIPE UP // MISSION CONTROL';
          if (reticleLabel) reticleLabel.textContent = 'MISSION CONTROL';
        }
        if (action === 'reset-cards') {
          stageCanvas.classList.remove('is-mission-control');
          initialPositions.forEach(function (item) {
            item.el.style.left = item.left;
            item.el.style.top = item.top;
          });
          if (gestureBadge) gestureBadge.textContent = 'WORKSPACE RESET // READY';
        }
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    initDotMatrixOrb();
    initInteractiveSandbox();
  });
})();
