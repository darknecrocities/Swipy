// Interactive Circular Dot-Matrix Hand Glyph & Ballistic Curve Engine
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
      label: 'TETRIS MATRIX',
      cells: [
        [2,2],[3,2],[4,2],[3,3],
        [9,2],[10,2],[10,3],[11,3],
        [5,5],[6,5],[7,5],[8,5],
        [3,8],[3,9],[4,9],[5,9],
        [9,7],[9,8],[10,8],[9,9],
        [6,11],[7,11],[6,12],[7,12]
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
      activePoseIndex = (activePoseIndex + 1) % POSES.length;
      if (captionEl) {
        captionEl.textContent = POSES[activePoseIndex].label;
      }
    }

    if (orbShell) {
      orbShell.addEventListener('click', cyclePose);
    }
    setInterval(cyclePose, 3200);
    render();
  }

  function initBallisticCurveCanvas() {
    const canvas = document.getElementById('ballistic-curve-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let t = 0;

    function drawCurve() {
      const w = canvas.width;
      const h = canvas.height;
      ctx.clearRect(0, 0, w, h);

      ctx.strokeStyle = '#333333';
      ctx.lineWidth = 1;
      for (let gx = 0; gx <= w; gx += 32) {
        ctx.beginPath();
        ctx.moveTo(gx, 0);
        ctx.lineTo(gx, h);
        ctx.stroke();
      }
      for (let gy = 0; gy <= h; gy += 32) {
        ctx.beginPath();
        ctx.moveTo(0, gy);
        ctx.lineTo(w, gy);
        ctx.stroke();
      }

      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 3;
      ctx.beginPath();
      for (let px = 0; px <= w; px += 4) {
        const norm = px / w;
        let gain;
        if (norm < 0.25) {
          gain = 0.12 * (norm / 0.25);
        } else if (norm < 0.65) {
          gain = 0.12 + 0.38 * ((norm - 0.25) / 0.4);
        } else {
          gain = 0.50 + 0.45 * Math.pow((norm - 0.65) / 0.35, 1.35);
        }
        const py = h - 14 - gain * (h - 28);
        if (px === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.stroke();

      const progress = (Math.sin(t * 0.035) + 1) * 0.5;
      const dotX = progress * w;
      let dotGain;
      if (progress < 0.25) dotGain = 0.12 * (progress / 0.25);
      else if (progress < 0.65) dotGain = 0.12 + 0.38 * ((progress - 0.25) / 0.4);
      else dotGain = 0.50 + 0.45 * Math.pow((progress - 0.65) / 0.35, 1.35);
      const dotY = h - 14 - dotGain * (h - 28);

      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(dotX - 6, dotY - 6, 12, 12);

      t++;
      requestAnimationFrame(drawCurve);
    }

    drawCurve();
  }

  document.addEventListener('DOMContentLoaded', function () {
    initDotMatrixOrb();
    initBallisticCurveCanvas();
  });
})();
