// Blocky Tetris-Pixel Cursor & Pointer Matrix Engine + Interactive Combo Builder
(function () {
  const GRID_SIZE = 17;

  // Crisp 17x17 Blocky Tetris-Pixel Icons (Zero Stick-Line Joints, Zero Text)
  const PIXEL_ICONS = [
    // 01: Classic macOS Diagonal Pixel Arrow Cursor
    [
      [4,2],
      [4,3],[5,3],
      [4,4],[5,4],[6,4],
      [4,5],[5,5],[6,5],[7,5],
      [4,6],[5,6],[6,6],[7,6],[8,6],
      [4,7],[5,7],[6,7],[7,7],[8,7],[9,7],
      [4,8],[5,8],[6,8],[7,8],[8,8],[9,8],[10,8],
      [4,9],[5,9],[6,9],[7,9],[8,9],[9,9],[10,9],[11,9],
      [4,10],[5,10],[6,10],[7,10],[8,10],
      [4,11],[5,11],[7,11],[8,11],
      [4,12],[8,12],[9,12],
      [8,13],[9,13],
      [9,14],[10,14]
    ],
    // 02: Classic Pixel Hand Pointer Cursor (Index Finger + Knuckles + Cuff)
    [
      [6,2],[7,2],
      [6,3],[7,3],
      [6,4],[7,4],
      [6,5],[7,5],[9,5],[10,5],
      [6,6],[7,6],[8,6],[9,6],[10,6],[11,6],[12,6],
      [3,7],[4,7],[6,7],[7,7],[8,7],[9,7],[10,7],[11,7],[12,7],[13,7],
      [3,8],[4,8],[5,8],[6,8],[7,8],[8,8],[9,8],[10,8],[11,8],[12,8],[13,8],
      [4,9],[5,9],[6,9],[7,9],[8,9],[9,9],[10,9],[11,9],[12,9],[13,9],
      [5,10],[6,10],[7,10],[8,10],[9,10],[10,10],[11,10],[12,10],
      [6,11],[7,11],[8,11],[9,11],[10,11],[11,11],
      [6,12],[7,12],[8,12],[9,12],[10,12],[11,12],
      [7,13],[8,13],[9,13],[10,13]
    ],
    // 03: Blocky 4-Way Space Swipe Chevrons (<< and >>)
    [
      [5,5],[11,5],
      [4,6],[5,6],[11,6],[12,6],
      [3,7],[4,7],[7,7],[9,7],[12,7],[13,7],
      [2,8],[3,8],[6,8],[7,8],[8,8],[9,8],[10,8],[13,8],[14,8],
      [3,9],[4,9],[7,9],[9,9],[12,9],[13,9],
      [4,10],[5,10],[11,10],[12,10],
      [5,11],[11,11]
    ],
    // 04: Blocky Vision Pro Target Reticle & Pinch Lock
    [
      [4,3],[5,3],[6,3],[10,3],[11,3],[12,3],
      [3,4],[4,4],[12,4],[13,4],
      [3,5],[13,5],
      [3,6],[7,6],[8,6],[9,6],[13,6],
      [6,7],[7,7],[9,7],[10,7],
      [6,8],[8,8],[10,8],
      [6,9],[7,9],[9,9],[10,9],
      [3,10],[7,10],[8,10],[9,10],[13,10],
      [3,11],[13,11],
      [3,12],[4,12],[12,12],[13,12],
      [4,13],[5,13],[6,13],[10,13],[11,13],[12,13]
    ]
  ];

  function initDotMatrixOrb() {
    const canvas = document.getElementById('dot-matrix-canvas');
    const orbShell = document.getElementById('dot-matrix-orb');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let activePoseIndex = 0;
    let tick = 0;

    function render() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const cellSize = canvas.width / GRID_SIZE;
      const cells = PIXEL_ICONS[activePoseIndex];

      // Subtle floating 1-cell cursor bob animation
      const shiftX = activePoseIndex === 2 ? Math.round(Math.sin(tick * 0.06)) : 0;
      const shiftY = activePoseIndex === 0 ? Math.round(Math.sin(tick * 0.05)) : 0;

      const activeSet = new Set(
        cells.map(function (c) {
          return (c[0] + shiftX) + ',' + (c[1] + shiftY);
        })
      );
      const center = (GRID_SIZE - 1) / 2;

      for (let y = 0; y < GRID_SIZE; y++) {
        for (let x = 0; x < GRID_SIZE; x++) {
          const dx = x - center;
          const dy = y - center;
          if (Math.sqrt(dx * dx + dy * dy) > 7.8) continue;

          const key = x + ',' + y;
          const isLit = activeSet.has(key);
          const pulse = Math.sin((tick * 0.06) + (x * 0.45) + (y * 0.35)) > 0.9;

          ctx.fillStyle = isLit ? '#FFFFFF' : (pulse ? '#2E2E2E' : '#181818');
          const pad = 1.4;
          ctx.fillRect(
            x * cellSize + pad,
            y * cellSize + pad,
            cellSize - pad * 2,
            cellSize - pad * 2
          );
        }
      }
      tick++;
      requestAnimationFrame(render);
    }

    function cyclePose() {
      activePoseIndex = (activePoseIndex + 1) % PIXEL_ICONS.length;
    }

    if (orbShell) orbShell.addEventListener('click', cyclePose);
    setInterval(cyclePose, 3400);
    render();
  }

  function initTetrisComboBuilder() {
    const pieces = document.querySelectorAll('.tetris-snap-piece');
    const outputEl = document.getElementById('tetris-combo-output');
    const statusEl = document.getElementById('tetris-combo-status');
    if (!pieces.length || !outputEl) return;

    function updateChainReadout() {
      const activeSteps = [];
      pieces.forEach(function (btn) {
        if (btn.classList.contains('is-snapped')) {
          activeSteps.push(btn.getAttribute('data-combo-step'));
        }
      });
      if (activeSteps.length === 0) {
        outputEl.innerHTML = 'CLICK ANY TETRIS BLOCK ABOVE TO ASSEMBLE A TOUCHLESS MACOS WORKFLOW';
        if (statusEl) statusEl.textContent = '0 BLOCKS SNAPPED';
      } else {
        outputEl.innerHTML = 'ACTIVE CHAIN: ' + activeSteps.join(' &bull; ');
        if (statusEl) statusEl.textContent = activeSteps.length + ' BLOCKS SNAPPED';
      }
    }

    pieces.forEach(function (btn) {
      btn.addEventListener('click', function () {
        btn.classList.toggle('is-snapped');
        updateChainReadout();
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    initDotMatrixOrb();
    initTetrisComboBuilder();
  });
})();
