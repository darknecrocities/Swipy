// Swipy Interactive Hand Pose Matrix Engine
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

  document.addEventListener('DOMContentLoaded', initDotMatrixOrb);
})();
