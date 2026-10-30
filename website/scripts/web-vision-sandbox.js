// Browser-Only Web Hand Vision Engine for "Test It Out?" Sample Computer Screen
(function () {
  const HAND_CONNECTIONS = [
    [0,1],[1,2],[2,3],[3,4],
    [0,5],[5,6],[6,7],[7,8],
    [5,9],[9,10],[10,11],[11,12],
    [9,13],[13,14],[14,15],[15,16],
    [13,17],[17,18],[18,19],[19,20],
    [0,17]
  ];

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      const s = document.createElement('script');
      s.src = src;
      s.crossOrigin = 'anonymous';
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  function initWebVisionSandbox() {
    const screen = document.getElementById('sandbox-screen');
    const stageCanvas = document.getElementById('sandbox-stage-canvas');
    const reticle = document.getElementById('sandbox-reticle');
    const reticleLabel = document.getElementById('sandbox-reticle-label');
    const gestureBadge = document.getElementById('sandbox-gesture-badge');
    const spaceIndicator = document.getElementById('sandbox-space-indicator');
    const dockHint = document.getElementById('sandbox-dock-hint');
    const camToggleBtn = document.getElementById('sandbox-camera-toggle');
    const camBtnText = document.getElementById('sandbox-camera-btn-text');
    const pipBox = document.getElementById('sandbox-webcam-pip');
    const pipStatus = document.getElementById('sandbox-pip-status');
    const videoEl = document.getElementById('sandbox-webcam-video');
    const canvasEl = document.getElementById('sandbox-webcam-canvas');
    const cards = Array.from(document.querySelectorAll('.sandbox-draggable-card'));
    const actionBtns = document.querySelectorAll('[data-sandbox-action]');
    if (!screen || !stageCanvas) return;

    const SPACES = [
      'SPACE 01 // MACOS WORKSPACE',
      'SPACE 02 // CODE & TERMINAL',
      'SPACE 03 // POINTER STUDIO'
    ];
    let currentSpaceIndex = 0;
    let activeCard = null;
    let offsetX = 0;
    let offsetY = 0;
    let cursorX = 360;
    let cursorY = 200;
    let isCameraActive = false;
    let mediaStream = null;
    let handsInstance = null;
    let rafId = null;
    let lastSwipeTime = 0;
    let prevPalmX = null;

    const initialPositions = cards.map(function (card) {
      return { el: card, left: card.style.left, top: card.style.top };
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

      const slideDir = delta > 0 ? -42 : 42;
      stageCanvas.style.transform = 'translateX(' + slideDir + 'px)';
      setTimeout(function () {
        stageCanvas.style.transform = 'translateX(0)';
      }, 220);
    }

    function findCardAtPoint(x, y) {
      const stageRect = stageCanvas.getBoundingClientRect();
      const clientX = stageRect.left + x;
      const clientY = stageRect.top + y;
      for (let i = cards.length - 1; i >= 0; i--) {
        const r = cards[i].getBoundingClientRect();
        if (clientX >= r.left && clientX <= r.right && clientY >= r.top && clientY <= r.bottom) {
          return cards[i];
        }
      }
      return null;
    }

    function updateVirtualCursor(targetX, targetY, isPinching) {
      const rect = stageCanvas.getBoundingClientRect();
      cursorX += (targetX - cursorX) * 0.32;
      cursorY += (targetY - cursorY) * 0.32;
      const clampedX = Math.max(16, Math.min(rect.width - 16, cursorX));
      const clampedY = Math.max(16, Math.min(rect.height - 16, cursorY));

      if (reticle) {
        reticle.style.left = clampedX + 'px';
        reticle.style.top = clampedY + 'px';
        reticle.classList.toggle('is-pinching', isPinching);
      }

      const hovered = findCardAtPoint(clampedX, clampedY);
      cards.forEach(function (c) { c.classList.toggle('is-hovered', c === hovered && !activeCard); });

      if (isPinching) {
        if (!activeCard && hovered) {
          activeCard = hovered;
          activeCard.classList.add('is-pinched');
          const cRect = activeCard.getBoundingClientRect();
          offsetX = (rect.left + clampedX) - cRect.left;
          offsetY = (rect.top + clampedY) - cRect.top;
        }
        if (activeCard) {
          const nextLeft = Math.max(8, Math.min(rect.width - activeCard.offsetWidth - 8, clampedX - offsetX));
          const nextTop = Math.max(8, Math.min(rect.height - activeCard.offsetHeight - 8, clampedY - offsetY));
          activeCard.style.left = nextLeft + 'px';
          activeCard.style.top = nextTop + 'px';
          if (reticleLabel) reticleLabel.textContent = 'PINCH & DRAG';
          if (gestureBadge) gestureBadge.textContent = 'PINCH & DRAG // MOVING WINDOW';
        } else {
          if (reticleLabel) reticleLabel.textContent = 'PINCH CLICK';
          if (gestureBadge) gestureBadge.textContent = 'THUMB-INDEX PINCH // CLICK';
        }
      } else {
        if (activeCard) {
          activeCard.classList.remove('is-pinched');
          activeCard = null;
        }
        if (reticleLabel) reticleLabel.textContent = 'INDEX POINT';
        if (gestureBadge) gestureBadge.textContent = 'INDEX POINT // GLIDING CURSOR';
      }
    }

    // Fallback Pointer / Mouse Dragging on Sample Screen
    cards.forEach(function (card) {
      card.addEventListener('pointerdown', function (e) {
        if (isCameraActive) return;
        e.stopPropagation();
        activeCard = card;
        card.classList.add('is-pinched');
        if (reticle) reticle.classList.add('is-pinching');
        if (reticleLabel) reticleLabel.textContent = 'PINCH & DRAG';
        if (gestureBadge) gestureBadge.textContent = 'PINCH & DRAG // LOCKED ON WINDOW';
        const cRect = card.getBoundingClientRect();
        offsetX = e.clientX - cRect.left;
        offsetY = e.clientY - cRect.top;
        card.setPointerCapture(e.pointerId);
      });
    });

    screen.addEventListener('pointermove', function (e) {
      if (isCameraActive) return;
      const rect = stageCanvas.getBoundingClientRect();
      const relX = e.clientX - rect.left;
      const relY = e.clientY - rect.top;
      if (reticle) {
        reticle.style.left = Math.max(16, Math.min(rect.width - 16, relX)) + 'px';
        reticle.style.top = Math.max(16, Math.min(rect.height - 16, relY)) + 'px';
      }
      if (activeCard) {
        activeCard.style.left = Math.max(8, Math.min(rect.width - activeCard.offsetWidth - 8, relX - offsetX)) + 'px';
        activeCard.style.top = Math.max(8, Math.min(rect.height - activeCard.offsetHeight - 8, relY - offsetY)) + 'px';
      }
    });

    window.addEventListener('pointerup', function () {
      if (isCameraActive) return;
      if (activeCard) {
        activeCard.classList.remove('is-pinched');
        activeCard = null;
      }
      if (reticle) reticle.classList.remove('is-pinching');
      if (reticleLabel) reticleLabel.textContent = 'POINT';
      if (gestureBadge) gestureBadge.textContent = 'INDEX POINT // GLIDING';
    });

    // Live Web Camera + 21-Point Hand Vision Processing
    function onHandResults(results) {
      if (!canvasEl) return;
      const ctx = canvasEl.getContext('2d');
      const w = canvasEl.width;
      const h = canvasEl.height;
      ctx.clearRect(0, 0, w, h);

      if (!results.multiHandLandmarks || results.multiHandLandmarks.length === 0) {
        if (pipStatus) pipStatus.textContent = 'LOOKING FOR HAND...';
        return;
      }

      const lm = results.multiHandLandmarks[0];
      if (pipStatus) pipStatus.textContent = 'HAND LOCKED // 21 JOINTS';

      // Draw 21-Point Skeleton Overlay in PiP
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      HAND_CONNECTIONS.forEach(function (pair) {
        const a = lm[pair[0]];
        const b = lm[pair[1]];
        ctx.beginPath();
        ctx.moveTo(a.x * w, a.y * h);
        ctx.lineTo(b.x * w, b.y * h);
        ctx.stroke();
      });

      lm.forEach(function (pt, idx) {
        ctx.fillStyle = (idx === 4 || idx === 8) ? '#FFFFFF' : '#111111';
        ctx.strokeStyle = '#FFFFFF';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(pt.x * w, pt.y * h, idx === 8 ? 5 : 3.2, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
      });

      // Map mirrored index fingertip (landmark 8) to Sample Mac Screen coordinates
      const rect = stageCanvas.getBoundingClientRect();
      const mirroredX = (1 - lm[8].x) * rect.width;
      const mappedY = lm[8].y * rect.height;

      // Thumb tip (4) to Index tip (8) distance for Pinch & Drag
      const pinchDist = Math.hypot(lm[4].x - lm[8].x, lm[4].y - lm[8].y);
      const isPinching = pinchDist < 0.065;

      // Detect 4-Finger Open Palm Horizontal Swipe
      const fingersExtended =
        lm[8].y < lm[6].y &&
        lm[12].y < lm[10].y &&
        lm[16].y < lm[14].y &&
        lm[20].y < lm[18].y;

      const now = performance.now();
      const palmX = 1 - lm[9].x;
      if (fingersExtended && !isPinching && prevPalmX !== null && now - lastSwipeTime > 750) {
        const deltaX = palmX - prevPalmX;
        if (Math.abs(deltaX) > 0.085) {
          lastSwipeTime = now;
          switchSpace(deltaX < 0 ? 1 : -1);
        }
      }
      prevPalmX = palmX;

      updateVirtualCursor(mirroredX, mappedY, isPinching);
    }

    async function toggleWebCamera() {
      if (isCameraActive) {
        isCameraActive = false;
        if (rafId) cancelAnimationFrame(rafId);
        if (mediaStream) {
          mediaStream.getTracks().forEach(function (t) { t.stop(); });
          mediaStream = null;
        }
        if (pipBox) pipBox.hidden = true;
        if (camToggleBtn) camToggleBtn.setAttribute('aria-pressed', 'false');
        if (camBtnText) camBtnText.textContent = 'TURN ON CAMERA (WEB VISION)';
        if (dockHint) dockHint.textContent = 'TURN ON CAMERA TO CONTROL THIS MAC SCREEN WITH YOUR HAND, OR DRAG WITH CURSOR';
        return;
      }

      try {
        if (camBtnText) camBtnText.textContent = 'STARTING WEB VISION...';
        mediaStream = await navigator.mediaDevices.getUserMedia({
          video: { width: 640, height: 480, facingMode: 'user' },
          audio: false
        });
        videoEl.srcObject = mediaStream;
        await videoEl.play();

        if (!window.Hands) {
          await loadScript('https://cdn.jsdelivr.net/npm/@mediapipe/hands/hands.js');
        }

        if (!handsInstance && window.Hands) {
          handsInstance = new window.Hands({
            locateFile: function (file) {
              return 'https://cdn.jsdelivr.net/npm/@mediapipe/hands/' + file;
            }
          });
          handsInstance.setOptions({
            maxNumHands: 1,
            modelComplexity: 1,
            minDetectionConfidence: 0.6,
            minTrackingConfidence: 0.6
          });
          handsInstance.onResults(onHandResults);
        }

        isCameraActive = true;
        if (pipBox) pipBox.hidden = false;
        if (camToggleBtn) camToggleBtn.setAttribute('aria-pressed', 'true');
        if (camBtnText) camBtnText.textContent = 'STOP CAMERA (WEB VISION ACTIVE)';
        if (dockHint) dockHint.textContent = 'POINT INDEX FINGER TO MOVE CURSOR • PINCH THUMB + INDEX TO GRAB & DRAG WINDOWS • FLICK 4 FINGERS TO SWITCH SPACES';

        const pumpFrame = async function () {
          if (!isCameraActive) return;
          if (handsInstance && videoEl.readyState >= 2) {
            await handsInstance.send({ image: videoEl });
          }
          rafId = requestAnimationFrame(pumpFrame);
        };
        pumpFrame();
      } catch (err) {
        isCameraActive = false;
        if (camBtnText) camBtnText.textContent = 'CAMERA BLOCKED — TRY AGAIN';
        if (gestureBadge) gestureBadge.textContent = 'ALLOW CAMERA PERMISSION IN BROWSER';
      }
    }

    if (camToggleBtn) {
      camToggleBtn.addEventListener('click', toggleWebCamera);
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

  document.addEventListener('DOMContentLoaded', initWebVisionSandbox);
})();
