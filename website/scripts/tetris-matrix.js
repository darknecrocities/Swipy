// Anatomically Accurate 21-Joint Hand Gesture Orb & Interactive Tetris Block Combo Engine
(function () {
  const GESTURE_MODES = [
    {
      label: '4-FINGER SPACE SWIPE',
      draw: function (ctx, w, h, t) {
        const swipeShift = Math.sin(t * 0.055) * 14;
        const cx = w * 0.5 + swipeShift;
        const cy = h * 0.62;

        // Animated directional swipe chevrons on left/right
        ctx.strokeStyle = 'rgba(255,255,255,0.42)';
        ctx.lineWidth = 2;
        const dir = Math.cos(t * 0.055) >= 0 ? 1 : -1;
        for (let i = 0; i < 2; i++) {
          const ax = w * 0.5 + dir * (58 + i * 14);
          const ay = h * 0.34;
          ctx.beginPath();
          ctx.moveTo(ax - dir * 6, ay - 7);
          ctx.lineTo(ax, ay);
          ctx.lineTo(ax - dir * 6, ay + 7);
          ctx.stroke();
        }

        // 5-Finger Open Hand Silhouette with 21 Anatomical Landmarks
        const wrist = { x: cx, y: cy + 36 };
        const fingers = [
          // Thumb (opposed left)
          [{ x: cx - 18, y: cy + 20 }, { x: cx - 34, y: cy + 6 }, { x: cx - 46, y: cy - 10 }],
          // Index
          [{ x: cx - 16, y: cy - 4 }, { x: cx - 20, y: cy - 30 }, { x: cx - 23, y: cy - 54 }],
          // Middle
          [{ x: cx - 4, y: cy - 8 }, { x: cx - 5, y: cy - 36 }, { x: cx - 5, y: cy - 62 }],
          // Ring
          [{ x: cx + 9, y: cy - 5 }, { x: cx + 11, y: cy - 31 }, { x: cx + 13, y: cy - 54 }],
          // Pinky
          [{ x: cx + 21, y: cy + 2 }, { x: cx + 26, y: cy - 18 }, { x: cx + 31, y: cy - 38 }]
        ];

        drawArticulatedHand(ctx, wrist, fingers, []);
      }
    },
    {
      label: 'THUMB-INDEX PINCH',
      draw: function (ctx, w, h, t) {
        const cx = w * 0.52;
        const cy = h * 0.62;
        const pinchCycle = (Math.sin(t * 0.08) + 1) * 0.5;
        const gap = pinchCycle * 14;

        const pinchX = cx - 24;
        const pinchY = cy - 22;

        // Pulsing pinch contact ring when thumb & index meet
        if (gap < 6) {
          const ringRadius = 10 + (1 - gap / 6) * 14;
          ctx.strokeStyle = '#FFFFFF';
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.arc(pinchX, pinchY, ringRadius, 0, Math.PI * 2);
          ctx.stroke();
        }

        const wrist = { x: cx + 4, y: cy + 38 };
        const fingers = [
          // Thumb curving up to meet index tip
          [{ x: cx - 12, y: cy + 16 }, { x: cx - 24, y: cy + 2 }, { x: pinchX, y: pinchY + gap * 0.55 }],
          // Index curving down to meet thumb tip
          [{ x: cx - 10, y: cy - 6 }, { x: cx - 20, y: cy - 28 }, { x: pinchX, y: pinchY - gap * 0.55 }],
          // Middle, Ring, Pinky fanned gracefully in "OK" pose
          [{ x: cx + 2, y: cy - 8 }, { x: cx + 6, y: cy - 34 }, { x: cx + 9, y: cy - 56 }],
          [{ x: cx + 14, y: cy - 4 }, { x: cx + 20, y: cy - 28 }, { x: cx + 25, y: cy - 48 }],
          [{ x: cx + 24, y: cy + 4 }, { x: cx + 32, y: cy - 15 }, { x: cx + 38, y: cy - 32 }]
        ];

        drawArticulatedHand(ctx, wrist, fingers, [0, 1]);
      }
    },
    {
      label: 'CURSOR GLIDE',
      draw: function (ctx, w, h, t) {
        const orbitX = Math.cos(t * 0.045) * 16;
        const orbitY = Math.sin(t * 0.045) * 10;
        const cx = w * 0.52 + orbitX * 0.45;
        const cy = h * 0.66 + orbitY * 0.45;

        const tipX = cx - 18 + orbitX * 0.55;
        const tipY = cy - 58 + orbitY * 0.55;

        // Target Vision Pro Reticle around Index Fingertip
        ctx.strokeStyle = 'rgba(255,255,255,0.75)';
        ctx.lineWidth = 1.8;
        ctx.beginPath();
        ctx.arc(tipX, tipY, 13, 0, Math.PI * 2);
        ctx.stroke();

        const wrist = { x: cx + 6, y: cy + 34 };
        const fingers = [
          // Thumb tucked smoothly on left side of palm
          [{ x: cx - 12, y: cy + 16 }, { x: cx - 22, y: cy + 2 }, { x: cx - 18, y: cy - 10 }],
          // Index extended toward target reticle
          [{ x: cx - 10, y: cy - 6 }, { x: (cx - 10 + tipX) * 0.5, y: (cy - 6 + tipY) * 0.5 }, { x: tipX, y: tipY }],
          // Middle, Ring, Pinky curled neatly into palm
          [{ x: cx + 2, y: cy - 4 }, { x: cx + 4, y: cy - 16 }, { x: cx + 2, y: cy - 6 }],
          [{ x: cx + 13, y: cy - 1 }, { x: cx + 15, y: cy - 12 }, { x: cx + 12, y: cy - 3 }],
          [{ x: cx + 23, y: cy + 4 }, { x: cx + 25, y: cy - 6 }, { x: cx + 21, y: cy + 2 }]
        ];

        drawArticulatedHand(ctx, wrist, fingers, [1]);
      }
    },
    {
      label: 'TWO-FINGER SCROLL',
      draw: function (ctx, w, h, t) {
        const bobY = Math.sin(t * 0.065) * 10;
        const cx = w * 0.5;
        const cy = h * 0.64 + bobY;

        // Vertical scroll arrows
        ctx.strokeStyle = 'rgba(255,255,255,0.45)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(w * 0.22, h * 0.36);
        ctx.lineTo(w * 0.22, h * 0.64);
        ctx.stroke();

        const wrist = { x: cx, y: cy + 34 };
        const fingers = [
          // Thumb tucked across palm
          [{ x: cx - 14, y: cy + 16 }, { x: cx - 20, y: cy + 2 }, { x: cx - 10, y: cy - 4 }],
          // Index & Middle raised in V-sign scroll pose
          [{ x: cx - 10, y: cy - 6 }, { x: cx - 18, y: cy - 32 }, { x: cx - 24, y: cy - 56 }],
          [{ x: cx + 4, y: cy - 6 }, { x: cx + 10, y: cy - 34 }, { x: cx + 16, y: cy - 58 }],
          // Ring & Pinky curled
          [{ x: cx + 14, y: cy }, { x: cx + 16, y: cy - 12 }, { x: cx + 12, y: cy - 2 }],
          [{ x: cx + 23, y: cy + 5 }, { x: cx + 25, y: cy - 5 }, { x: cx + 20, y: cy + 3 }]
        ];

        drawArticulatedHand(ctx, wrist, fingers, [1, 2]);
      }
    }
  ];

  function drawArticulatedHand(ctx, wrist, fingers, highlightIndices) {
    // Subtle LED Grid Backdrop inside Orb
    ctx.fillStyle = '#1E1E1E';
    for (let gy = 16; gy < 204; gy += 12) {
      for (let gx = 16; gx < 204; gx += 12) {
        const dx = gx - 110;
        const dy = gy - 110;
        if (dx * dx + dy * dy <= 92 * 92) {
          ctx.fillRect(gx - 2, gy - 2, 4, 4);
        }
      }
    }

    // Palm Bridge Connecting Knuckles
    ctx.strokeStyle = 'rgba(255,255,255,0.55)';
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(wrist.x, wrist.y);
    for (let i = 1; i < fingers.length; i++) {
      ctx.lineTo(fingers[i][0].x, fingers[i][0].y);
    }
    ctx.lineTo(wrist.x, wrist.y);
    ctx.stroke();

    // Articulated Finger Bones & Phalanges
    fingers.forEach(function (chain, fIdx) {
      const isHighlighted = highlightIndices.indexOf(fIdx) !== -1;
      ctx.strokeStyle = isHighlighted ? '#FFFFFF' : 'rgba(255,255,255,0.82)';
      ctx.lineWidth = isHighlighted ? 6.5 : 5;
      ctx.beginPath();
      ctx.moveTo(wrist.x, wrist.y);
      chain.forEach(function (pt) {
        ctx.lineTo(pt.x, pt.y);
      });
      ctx.stroke();

      // Joint Landmark Nodes
      chain.forEach(function (pt, jIdx) {
        const isTip = jIdx === chain.length - 1;
        ctx.fillStyle = isTip && isHighlighted ? '#FFFFFF' : '#111111';
        ctx.strokeStyle = '#FFFFFF';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(pt.x, pt.y, isTip ? 4.8 : 3.4, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
      });
    });

    // Wrist Landmark Node
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(wrist.x, wrist.y, 4.5, 0, Math.PI * 2);
    ctx.fill();
  }

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
      GESTURE_MODES[activePoseIndex].draw(ctx, canvas.width, canvas.height, tick);
      tick++;
      requestAnimationFrame(render);
    }

    function cyclePose() {
      activePoseIndex = (activePoseIndex + 1) % GESTURE_MODES.length;
      if (captionEl) captionEl.textContent = GESTURE_MODES[activePoseIndex].label;
    }

    if (orbShell) orbShell.addEventListener('click', cyclePose);
    setInterval(cyclePose, 3600);
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
