(() => {
  const video = document.getElementById('camera-video');
  const startButton = document.getElementById('start-camera');
  const toggleButton = document.getElementById('camera-toggle');
  const placeholder = document.getElementById('camera-placeholder');
  const status = document.getElementById('camera-status');
  const message = document.getElementById('scan-message');
  const scanCode = document.getElementById('scan-code');
  const scanCourse = document.getElementById('scan-course');
  const scanForm = document.getElementById('scan-form');
  if (!video || !startButton) return;

  let stream = null;
  let scanning = false;
  let detector = null;
  let submitted = false;

  const selectedCourse = () => scanCourse?.value?.trim() || 'el curso seleccionado';

  async function startCamera() {
    if (!navigator.mediaDevices?.getUserMedia) {
      status.textContent = 'Cámara no disponible';
      message.textContent = 'Abre el proyecto desde localhost con Chrome o Edge.';
      return;
    }
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: 'environment' }, width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: false
      });
      video.srcObject = stream;
      await video.play();
      placeholder.style.display = 'none';
      status.textContent = 'Cámara encendida';
      message.textContent = `Buscando un código QR para ${selectedCourse()}…`;
      startButton.textContent = 'Apagar cámara';
      scanning = true;
      submitted = false;

      if ('BarcodeDetector' in window) {
        try {
          detector = new BarcodeDetector({ formats: ['qr_code'] });
          scanLoop();
        } catch (_) {
          message.textContent = 'La cámara está activa. Usa registro manual si no detecta QR.';
        }
      } else {
        message.textContent = 'Tu navegador no incluye lector QR. La cámara funciona; usa registro manual.';
      }
    } catch (error) {
      status.textContent = 'Permiso denegado';
      message.textContent = 'Permite la cámara desde el icono del candado del navegador.';
    }
  }

  function stopCamera(preserveMessage = false) {
    scanning = false;
    stream?.getTracks().forEach(track => track.stop());
    stream = null;
    video.srcObject = null;
    placeholder.style.display = '';
    status.textContent = 'Cámara apagada';
    if (!preserveMessage) message.textContent = `Esperando lectura QR para ${selectedCourse()}…`;
    startButton.textContent = 'Encender cámara';
  }

  async function scanLoop() {
    if (!scanning || !detector || submitted) return;
    try {
      const codes = await detector.detect(video);
      if (codes.length > 0) {
        const value = (codes[0].rawValue || '').trim();
        if (value) {
          submitted = true;
          status.textContent = 'Código detectado';
          message.textContent = `Registrando ${value} en ${selectedCourse()}…`;
          scanCode.value = value;
          stopCamera(true);
          scanForm.submit();
          return;
        }
      }
    } catch (_) { }
    window.setTimeout(scanLoop, 350);
  }

  startButton.addEventListener('click', () => stream ? stopCamera() : startCamera());
  toggleButton?.addEventListener('click', () => stream ? stopCamera() : startCamera());
  window.addEventListener('beforeunload', () => stopCamera(true));
})();
