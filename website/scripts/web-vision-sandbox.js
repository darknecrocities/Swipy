// Browser-Only Web Hand Vision Engine for "Test It Out?" Sample Computer Screen
(function () {
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
    const dockHint = document.getElementById('sandbox-dock-hint');
    const camToggleBtn = document.getElementById('sandbox-camera-toggle');
    const camBtnText = document.getElementById('sandbox-camera-btn-text');
    const pipBox = document.getElementById('sandbox-webcam-pip');
    const videoEl = document.getElementById('sandbox-webcam-video');
    const canvasEl = document.getElementById('sandbox-webcam-canvas');
    const cards = Array.from(document.querySelectorAll('.sandbox-draggable-card'));
    const actionBtns = document.querySelectorAll('[data-sandbox-action]');
    if (!screen || !stageCanvas) return;

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

    function resetCardPositions() {
      stageCanvas.classList.remove('is-mission-control');
      if (window.innerWidth <= 768) {
        cards.forEach(function (card) {
          const id = card.getAttribute('data-card-id');
          if (id === 'camera') { card.style.left = '4%'; card.style.top = '6%'; }
          else if (id === 'menubar') { card.style.left = '52%'; card.style.top = '6%'; }
          else if (id === 'gestures') { card.style.left = '26%'; card.style.top = '48%'; }
        });
      } else {
        initialPositions.forEach(function (item) {
          item.el.style.left = item.left;
          item.el.style.top = item.top;
        });
      }
    }

    if (window.innerWidth <= 768) {
      resetCardPositions();
    }

    function switchSpace(delta) {
      stageCanvas.classList.remove('is-mission-control');
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
        }
      } else {
        if (activeCard) {
          activeCard.classList.remove('is-pinched');
          activeCard = null;
        }
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
    });

    // Live Web Camera Processing (Tetris-Pixel Cursor Block Overlay, No Stick-Line Joints)
    function onHandResults(results) {
      if (!canvasEl) return;
      const ctx = canvasEl.getContext('2d');
      const w = canvasEl.width;
      const h = canvasEl.height;
      ctx.clearRect(0, 0, w, h);

      if (!results.multiHandLandmarks || results.multiHandLandmarks.length === 0) {
        return;
      }

      const lm = results.multiHandLandmarks[0];

      // Draw crisp monochrome Tetris pixel-block cursor at index tip (8) and thumb tip (4)
      const ix = lm[8].x * w;
      const iy = lm[8].y * h;
      const tx = lm[4].x * w;
      const ty = lm[4].y * h;

      ctx.fillStyle = '#FFFFFF';
      ctx.strokeStyle = '#111111';
      ctx.lineWidth = 2;
      ctx.fillRect(ix - 7, iy - 7, 14, 14);
      ctx.strokeRect(ix - 7, iy - 7, 14, 14);
      ctx.fillRect(tx - 5, ty - 5, 10, 10);
      ctx.strokeRect(tx - 5, ty - 5, 10, 10);

      // Map mirrored index fingertip (landmark 8) to Sample Mac Screen coordinates
      const rect = stageCanvas.getBoundingClientRect();
      const mirroredX = (1 - lm[8].x) * rect.width;
      const mappedY = lm[8].y * rect.height;

      const pinchDist = Math.hypot(lm[4].x - lm[8].x, lm[4].y - lm[8].y);
      const isPinching = pinchDist < 0.065;

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
        if (camBtnText) camBtnText.textContent = 'Turn On Camera (Web Vision)';
        if (dockHint) dockHint.textContent = 'Turn on camera to control this Mac screen with your hand, or drag windows with your cursor';
        return;
      }

      try {
        if (camBtnText) camBtnText.textContent = 'Starting Web Vision...';
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
        if (camBtnText) camBtnText.textContent = 'Stop Camera (Web Vision Active)';
        if (dockHint) dockHint.textContent = 'Point index finger to move cursor • Pinch thumb & index to grab and drag windows • Flick 4 fingers to switch Spaces';

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
        if (camBtnText) camBtnText.textContent = 'Camera Blocked — Try Again';
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
        }
        if (action === 'reset-cards') {
          resetCardPositions();
        }
      });
    });
  }

  document.addEventListener('DOMContentLoaded', initWebVisionSandbox);
})();
