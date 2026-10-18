<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Chat Pete</title>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Poppins', sans-serif; }
    
    body { 
      background-color: #0f172a; 
      color: white; 
      height: 100dvh; 
      display: flex; 
      flex-direction: column; 
    }

    /* Encabezado */
    header { 
      background: rgba(30, 41, 59, 0.8);
      backdrop-filter: blur(10px);
      padding: 15px 20px; 
      display: flex;
      align-items: center;
      justify-content: space-between; /* Para separar el título del botón mute */
      box-shadow: 0 4px 6px rgba(0,0,0,0.3);
      z-index: 10;
    }
    .header-left {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .avatar {
      width: 42px;
      height: 42px;
      background: linear-gradient(135deg, #3b82f6, #8b5cf6);
      border-radius: 50%;
      display: flex;
      justify-content: center;
      align-items: center;
      font-size: 1.2rem;
      font-weight: bold;
    }
    .header-info h1 { font-size: 1.1rem; font-weight: 600; }
    .header-info p { font-size: 0.8rem; color: #10b981; }

    /* Botón de Mute */
    .mute-btn {
      background: #1e293b;
      border: 1px solid #334155;
      color: white;
      font-size: 1.2rem;
      padding: 8px 12px;
      border-radius: 50%;
      cursor: pointer;
      transition: all 0.2s;
    }
    .mute-btn.muted {
      background: #ef4444; /* Rojo si está silenciado */
      border-color: #ef4444;
    }

    /* Área del chat */
    #chat { 
      flex: 1; 
      padding: 20px; 
      overflow-y: auto; 
      display: flex; 
      flex-direction: column; 
      gap: 15px; 
    }

    /* Burbujas de mensaje */
    .msg { 
      padding: 12px 18px; 
      border-radius: 20px; 
      max-width: 85%; 
      line-height: 1.5; 
      font-size: 0.95rem;
      animation: fadeIn 0.3s ease-out forwards;
      word-wrap: break-word;
    }
    
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }

    .user { 
      background: linear-gradient(135deg, #3b82f6, #8b5cf6); 
      align-self: flex-end; 
      border-bottom-right-radius: 4px; 
      box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
    }

    .bot { 
      background: #1e293b; 
      align-self: flex-start; 
      border-bottom-left-radius: 4px; 
      border: 1px solid #334155;
    }

    /* Formulario de entrada */
    form { 
      display: flex; 
      padding: 15px 20px; 
      background: rgba(30, 41, 59, 0.8); 
      gap: 12px;
      backdrop-filter: blur(10px);
    }

    input { 
      flex: 1; 
      padding: 15px 20px; 
      border-radius: 30px; 
      border: 1px solid #334155; 
      outline: none; 
      background: #0f172a; 
      color: white; 
      font-size: 1rem;
      transition: all 0.3s;
    }
    input:focus {
      border-color: #8b5cf6;
      box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.2);
    }

    button[type="submit"] { 
      padding: 0 20px; 
      border-radius: 30px; 
      border: none; 
      background: linear-gradient(135deg, #3b82f6, #8b5cf6); 
      color: white; 
      font-weight: 600; 
      cursor: pointer;
      transition: transform 0.2s;
    }
    button[type="submit"]:active { transform: scale(0.95); }
    button[type="submit"]:disabled { opacity: 0.5; cursor: not-allowed; }

    /* Indicador de escritura */
    .typing-dots { display: flex; gap: 4px; padding: 5px 0; }
    .typing-dots span {
      width: 6px; height: 6px; background-color: #94a3b8;
      border-radius: 50%; animation: bounce 1.4s infinite ease-in-out both;
    }
    .typing-dots span:nth-child(1) { animation-delay: -0.32s; }
    .typing-dots span:nth-child(2) { animation-delay: -0.16s; }
    @keyframes bounce {
      0%, 80%, 100% { transform: scale(0); }
      40% { transform: scale(1); }
    }
  </style>
</head>
<body>

  <header>
    <div class="header-left">
      <div class="avatar">🤖</div>
      <div class="header-info">
        <h1>Chat Pete</h1>
        <p>En línea</p>
      </div>
    </div>
    <!-- Botón para silenciar/activar voz -->
    <button id="muteBtn" class="mute-btn" title="Silenciar/Activar voz">🔊</button>
  </header>

  <div id="chat">
    <div class="msg bot">¡Hola! Soy Chat Pete. ¿En qué te puedo ayudar hoy?</div>
  </div>

  <form id="form">
    <input id="input" placeholder="Escribe un mensaje..." autocomplete="off" required />
    <button type="submit" id="btn">Enviar</button>
  </form>

  <script>
    const chat = document.getElementById('chat');
    const form = document.getElementById('form');
    const input = document.getElementById('input');
    const btn = document.getElementById('btn');
    const muteBtn = document.getElementById('muteBtn');

    // Variable para saber si la voz está silenciada
    let isMuted = false;

    // Función para activar/desactivar el mute
    muteBtn.addEventListener('click', () => {
      isMuted = !isMuted;
      if (isMuted) {
        muteBtn.textContent = '🔇';
        muteBtn.classList.add('muted');
        window.speechSynthesis.cancel(); // Detiene cualquier voz en curso
      } else {
        muteBtn.textContent = '🔊';
        muteBtn.classList.remove('muted');
      }
    });

    // Función para que la IA hable
    function hablar(texto) {
      if (isMuted) return; // Si está muteado, no hace nada
      
      // Cancelamos cualquier voz anterior
      window.speechSynthesis.cancel();

      const utterance = new SpeechSynthesisUtterance(texto);
      utterance.lang = 'es-ES'; // Voz en español
      utterance.rate = 1; // Velocidad normal
      utterance.pitch = 1; // Tono normal
      window.speechSynthesis.speak(utterance);
    }

    function addMsg(text, type, isTyping = false) {
      const div = document.createElement('div');
      div.className = `msg ${type}`;
      
      if (isTyping) {
        div.innerHTML = '<div class="typing-dots"><span></span><span></span><span></span></div>';
      } else {
        div.textContent = text;
      }
      
      chat.appendChild(div);
      chat.scrollTop = chat.scrollHeight;
      return div;
    }

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const msg = input.value.trim();
      if (!msg) return;

      addMsg(msg, 'user');
      input.value = '';
      btn.disabled = true;

      const loading = addMsg('', 'bot', true);

      try {
        const res = await fetch('/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ mensaje: msg })
        });
        const data = await res.json();
        
        loading.remove(); 
        
        if (data.error) {
          addMsg('⚠️ Error: ' + data.error, 'bot');
        } else {
          addMsg(data.respuesta, 'bot');
          // ¡AQUÍ HACEMOS QUE HABLE!
          hablar(data.respuesta); 
        }
      } catch (err) {
        loading.remove();
        addMsg('⚠️ Error de conexión. Revisa que el servidor esté encendido.', 'bot');
      }
      
      btn.disabled = false;
      input.focus();
    });
  </script>
</body>
</html>
